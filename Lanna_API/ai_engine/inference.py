"""Hybrid Thai-to-Tai-Tham inference: verified data first, rules second."""

from __future__ import annotations

import json
import os
import re
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

try:
    import torch
    from train_model import LannaTransliterationModel
    _TORCH_AVAILABLE = True
except ImportError:
    torch = None
    LannaTransliterationModel = None
    _TORCH_AVAILABLE = False

from aksharamukha_lanna import thai_to_tai_tham, validate_tai_tham_text


MODEL_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(MODEL_DIR, "output_model")
THAI_TOKEN = re.compile(r"[\u0E00-\u0E7F]+|[^\u0E00-\u0E7F]+")


class LannaAIInference:
    def __init__(self):
        self.dict_lookup: dict[str, dict] = {}
        dict_path = os.path.join(MODEL_DIR, "lanna_dict.json")
        if os.path.exists(dict_path):
            with open(dict_path, "r", encoding="utf-8") as handle:
                for item in json.load(handle):
                    self.dict_lookup[item["thai"]] = item

        override_path = os.path.join(
            MODEL_DIR,
            "..",
            "translation_model",
            "data",
            "raw",
            "verified_overrides.json",
        )
        if os.path.exists(override_path):
            with open(override_path, "r", encoding="utf-8") as handle:
                for item in json.load(handle):
                    self.dict_lookup[item["thai"]] = {
                        **item,
                        "pronunciation": item.get("pronunciation", f"[{item['thai']}]"),
                        "definition": item.get("definition", "คำที่เจ้าของโครงการยืนยัน"),
                        "source_type": "owner_verified",
                    }

        # Load ByT5 model if available
        self.byt5_loaded = False
        byt5_path = os.path.join(OUTPUT_DIR, "lanna-byt5-poc")
        if _TORCH_AVAILABLE and os.path.exists(os.path.join(byt5_path, "model.safetensors")):
            try:
                from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
                print(f"Loading ByT5 model from {byt5_path}...")
                self.byt5_tokenizer = AutoTokenizer.from_pretrained(byt5_path)
                self.byt5_model = AutoModelForSeq2SeqLM.from_pretrained(byt5_path)
                self.byt5_model.eval()
                self.byt5_loaded = True
                print("ByT5 model loaded successfully on CPU.")
            except Exception as e:
                print(f"Error loading ByT5 model: {e}")

    def convert_thai_to_lanna(self, thai_text: str) -> dict:
        normalized_input = thai_text.strip()
        tokens = (
            [normalized_input]
            if normalized_input in self.dict_lookup
            else THAI_TOKEN.findall(normalized_input)
        )
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
                confidence = 1.0 if source == "owner_verified" else 0.95
                needs_review = False
                definitions.append(
                    f"{entry['thai']} ({entry.get('pronunciation', f'[{token}]')}): "
                    f"{entry.get('definition', '')}"
                )
            else:
                if self.byt5_loaded:
                    try:
                        prefix = "translate Thai to Tai Tham: "
                        inputs = self.byt5_tokenizer(prefix + token, return_tensors="pt")
                        with torch.no_grad():
                            outputs = self.byt5_model.generate(**inputs, max_length=192)
                        output = self.byt5_tokenizer.decode(outputs[0], skip_special_tokens=True)
                        source = "byt5_model"
                        confidence = 0.85
                        needs_review = True
                        definitions.append(f"{token}: ถอดอักษรอัตโนมัติด้วย AI ByT5")
                    except Exception as e:
                        print(f"ByT5 inference error: {e}, falling back to Aksharamukha")
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
            segments.append(
                {
                    "input": token,
                    "output": output,
                    "source": source,
                    "confidence": confidence,
                    "needs_review": needs_review,
                }
            )

        final_lanna = "".join(output_parts)
        is_valid, unsupported = validate_tai_tham_text(final_lanna)
        review_required = any(item["needs_review"] for item in segments)
        confidence = min((item["confidence"] for item in segments), default=0.0)
        return {
            "input_thai": thai_text,
            "lanna_script": final_lanna,
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
    for query in ["สวัสดี", "ทดสอบคำใหม่"]:
        print(json.dumps(engine.convert_thai_to_lanna(query), ensure_ascii=False, indent=2))
