"""
Inference Script for Thai to Lanna AI Transliteration & Dictionary
Inputs Thai word or sentence, outputs Lanna Unicode script, pronunciation, and grammatical breakdown.
"""

import os
import json
import sys

# Ensure UTF-8 stdout encoding for Windows console
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# torch and the neural model are optional — the service falls back to
# dictionary + Aksharamukha transliteration when PyTorch is not installed.
try:
    import torch
    from train_model import LannaTransliterationModel
    _TORCH_AVAILABLE = True
except ImportError:
    torch = None  # type: ignore[assignment]
    LannaTransliterationModel = None  # type: ignore[assignment,misc]
    _TORCH_AVAILABLE = False

from aksharamukha_lanna import thai_to_tai_tham, validate_tai_tham_text

MODEL_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(MODEL_DIR, "output_model")

class LannaAIInference:
    def __init__(self):
        # Load dictionary
        dict_path = os.path.join(MODEL_DIR, "lanna_dict.json")
        self.dict_lookup = {}
        if os.path.exists(dict_path):
            with open(dict_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                for item in data:
                    self.dict_lookup[item["thai"]] = item
                    
        # Load Vocab & Model if trained (requires PyTorch)
        vocab_path = os.path.join(OUTPUT_DIR, "vocab_info.json")
        model_path = os.path.join(OUTPUT_DIR, "lanna_ai_model.pt")
        self.model_loaded = False

        if (
            _TORCH_AVAILABLE
            and os.path.exists(vocab_path)
            and os.path.exists(model_path)
        ):
            with open(vocab_path, "r", encoding="utf-8") as f:
                vocab_info = json.load(f)
                self.input_vocab = vocab_info["input_vocab"]
                self.output_vocab = vocab_info["output_vocab"]
                self.rev_output_vocab = {int(k): v for k, v in vocab_info["rev_output_vocab"].items()}

            self.model = LannaTransliterationModel(len(self.input_vocab), len(self.output_vocab))
            self.model.load_state_dict(torch.load(model_path, map_location=torch.device("cpu")))
            self.model.eval()
            self.model_loaded = True

    def convert_thai_to_lanna(self, thai_text: str) -> dict:
        """Transliterates Thai text to Lanna script using Model + Rule Engine."""
        words = thai_text.strip().split()
        lanna_words = []
        definitions = []
        
        for w in words:
            # 1. Dictionary exact match
            if w in self.dict_lookup:
                entry = self.dict_lookup[w]
                lanna_words.append(entry["lanna"])
                definitions.append(f"{entry['thai']} ({entry['pronunciation']}): {entry['definition']}")
            else:
                # 2. Aksharamukha transliteration with Tai Tham normalization
                lanna_res = thai_to_tai_tham(w).text
                lanna_words.append(lanna_res)
                definitions.append(f"{w}: ถอดเสียงตามกฎการสะกดอักขรวิทยาล้านนา")
                
        final_lanna = " ".join(lanna_words)
        is_valid, unsupported = validate_tai_tham_text(final_lanna)
        return {
            "input_thai": thai_text,
            "lanna_script": final_lanna,
            "is_valid_lanna_unicode": is_valid,
            "unsupported_characters": list(unsupported),
            "transliteration_engine": "dictionary+aksharamukha",
            "details": definitions
        }

if __name__ == "__main__":
    ai = LannaAIInference()
    print("==================================================")
    print("   ระบบแปลงภาษาไทยเป็นอักขระล้านนา (Lanna AI Engine)")
    print("==================================================")
    
    test_queries = ["พระยา", "ผะญ่า", "ดอกมัดกล้า", "ทั้งหลาย", "ต่อคำยาวสาวคำยืด", "อาการ"]
    for q in test_queries:
        res = ai.convert_thai_to_lanna(q)
        print(f"\nคำภาษาไทย: {res['input_thai']}")
        print(f"อักขระล้านนา: {res['lanna_script']}")
        print(f"รายละเอียด: {', '.join(res['details'])}")
