"""Hybrid Thai-to-Tai-Tham inference: reviewed lexicon first, rules second."""

from __future__ import annotations

import json
import os
import re
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

MODEL_DIR = os.path.dirname(os.path.abspath(__file__))
SCRIPTS_DIR = os.path.abspath(os.path.join(MODEL_DIR, "..", "translation_model", "scripts"))
if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)
OUTPUT_DIR = os.path.join(MODEL_DIR, "output_model")
BYT5_MODEL_DIR = os.path.join(OUTPUT_DIR, "lanna-byt5-poc")
BYT5_ENABLED = os.environ.get("LANNA_DISABLE_BYT5", "0") != "1"

if BYT5_ENABLED and os.path.exists(os.path.join(BYT5_MODEL_DIR, "model.safetensors")):
    try:
        import torch
        from train_model import LannaTransliterationModel
        _TORCH_AVAILABLE = True
    except ImportError:
        torch = None
        LannaTransliterationModel = None
        _TORCH_AVAILABLE = False
else:
    torch = None
    LannaTransliterationModel = None
    _TORCH_AVAILABLE = False

from aksharamukha_lanna import thai_to_tai_tham, validate_tai_tham_text
from ln_tilok_to_unicode import convert_tai_tham_to_ln_tilok


THAI_TOKEN = re.compile(r"[\u0E00-\u0E7F]+|[^\u0E00-\u0E7F]+")
VERIFIED_SOURCES = {
    "source_image_verified": 0.99,
    "verified_alias_to_source": 0.98,
    "owner_verified": 1.0,
    "expert_verified": 1.0,
}


def load_dictionary_file(path: str) -> list[dict]:
    if not os.path.exists(path):
        return []
    with open(path, "r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, list):
        raise ValueError(f"Dictionary file must contain a JSON list: {path}")
    return value


class LannaAIInference:
    def __init__(self):
        self.dict_lookup: dict[str, dict] = {}

        # Legacy dictionary remains a fallback. Reviewed rows loaded afterward
        # replace the same Thai key and therefore always win.
        for item in load_dictionary_file(os.path.join(MODEL_DIR, "lanna_dict.json")):
            self.dict_lookup[item["thai"]] = item

        reviewed_path = os.path.join(MODEL_DIR, "reviewed_lanna_dict.json")
        for item in load_dictionary_file(reviewed_path):
            source = item.get("source_type")
            if source not in VERIFIED_SOURCES:
                raise ValueError(f"Unverified row in reviewed runtime lexicon: {item.get('thai')}")
            self.dict_lookup[item["thai"]] = item

        override_path = os.path.join(
            MODEL_DIR, "..", "translation_model", "data", "raw", "verified_overrides.json"
        )
        for item in load_dictionary_file(override_path):
            self.dict_lookup[item["thai"]] = {
                **item,
                "pronunciation": item.get("pronunciation", f"[{item['thai']}]"),
                "definition": item.get("definition", "คำที่เจ้าของโครงการยืนยัน"),
                "source_type": "owner_verified",
                "needs_review": False,
                "canonical_thai": item["thai"],
                "is_alias": False,
            }

        self.byt5_loaded = False
        byt5_path = BYT5_MODEL_DIR
        if _TORCH_AVAILABLE:
            try:
                from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
                self.byt5_tokenizer = AutoTokenizer.from_pretrained(byt5_path)
                self.byt5_model = AutoModelForSeq2SeqLM.from_pretrained(byt5_path)
                self.byt5_model.eval()
                self.byt5_loaded = True
            except Exception as error:
                print(f"Error loading ByT5 model: {error}")

    def convert_thai_to_lanna(self, thai_text: str) -> dict:
        normalized_input = thai_text.strip()
        tokens = [normalized_input] if normalized_input in self.dict_lookup else THAI_TOKEN.findall(normalized_input)
        output_parts: list[str] = []
        definitions: list[str] = []
        segments: list[dict] = []

        for token in tokens:
            if not re.search(r"[\u0E00-\u0E7F]", token):
                output_parts.append(token)
                continue

            entry = self.dict_lookup.get(token)
            if entry:
                output = entry["lanna"]
                source = entry.get("source_type", "dictionary")
                confidence = VERIFIED_SOURCES.get(source, 0.95)
                needs_review = bool(entry.get("needs_review", False))
                canonical_thai = entry.get("canonical_thai", entry["thai"])
                definitions.append(
                    f"{entry['thai']} ({entry.get('pronunciation', f'[{token}]')}): "
                    f"{entry.get('definition', '')}"
                )
            else:
                canonical_thai = token
                if self.byt5_loaded:
                    try:
                        inputs = self.byt5_tokenizer(
                            "translate Thai to Tai Tham: " + token, return_tensors="pt"
                        )
                        with torch.no_grad():
                            generated_tokens = self.byt5_model.generate(**inputs, max_length=192)
                        output = self.byt5_tokenizer.decode(generated_tokens[0], skip_special_tokens=True)
                        source = "byt5_model"
                        confidence = 0.85
                        needs_review = True
                        definitions.append(f"{token}: ผลถอดอักษรอัตโนมัติด้วย AI ByT5")
                    except Exception as error:
                        print(f"ByT5 inference error: {error}; using Aksharamukha")
                        generated = thai_to_tai_tham(token)
                        output = generated.text
                        source = "automatic_transliteration"
                        confidence = 0.55 if generated.is_valid else 0.25
                        needs_review = True
                        definitions.append(f"{token}: ผลถอดอักษรอัตโนมัติ (Aksharamukha)")
                else:
                    generated = thai_to_tai_tham(token)
                    output = generated.text
                    source = "automatic_transliteration"
                    confidence = 0.55 if generated.is_valid else 0.25
                    needs_review = True
                    definitions.append(f"{token}: ผลถอดอักษรอัตโนมัติ (Aksharamukha)")

            output_parts.append(output)
            segments.append({
                "input": token,
                "output": output,
                "source": source,
                "canonical_thai": canonical_thai,
                "is_alias": bool(entry and entry.get("is_alias", False)),
                "source_pdf_page": entry.get("source_pdf_page") if entry else None,
                "pronunciation": entry.get("pronunciation", "") if entry else "",
                "definition": entry.get("definition", "") if entry else "",
                "category": entry.get("category", "") if entry else "",
                "senses": entry.get("senses", []) if entry else [],
                "lanna_variants": entry.get("lanna_variants", []) if entry else [],
                "confidence": confidence,
                "needs_review": needs_review,
            })

        final_lanna = "".join(output_parts)
        legacy_lanna, legacy_warnings = convert_tai_tham_to_ln_tilok(final_lanna)
        is_valid, unsupported = validate_tai_tham_text(final_lanna)
        review_required = any(item["needs_review"] for item in segments)
        confidence = min((item["confidence"] for item in segments), default=0.0)
        return {
            "input_thai": thai_text,
            "lanna_script": final_lanna,
            "lanna_legacy_ln_tilok": legacy_lanna,
            "lanna_legacy_warnings": legacy_warnings,
            "is_valid_lanna_unicode": is_valid,
            "unsupported_characters": list(unsupported),
            "transliteration_engine": "dictionary+byt5" if self.byt5_loaded else "dictionary+aksharamukha",
            "details": definitions,
            "segments": segments,
            "confidence": confidence,
            "needs_review": review_required,
            "result_label": "คำแนะนำอัตโนมัติ" if review_required else "คำที่ตรวจสอบแล้ว",
        }


if __name__ == "__main__":
    engine = LannaAIInference()
    for query in ["สวัสดี", "กินเข้างาย", "ทดสอบคำใหม่"]:
        print(json.dumps(engine.convert_thai_to_lanna(query), ensure_ascii=False, indent=2))
