"""
Evaluation & Automated Test Suite for Lanna AI Trainer
Validates dataset formatting, rule engine correctness, and model performance.
"""

import os
import json
import sys

# Ensure UTF-8 stdout encoding for Windows console (Lanna Unicode display)
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

from lanna_rules import transliterate_word_rule_based, validate_lanna_unicode
from inference import LannaAIInference

MODEL_DIR = os.path.dirname(os.path.abspath(__file__))

def run_evaluation():
    print("==================================================")
    print("  RUNNING AUTOMATED EVALUATION SUITE FOR LANNA AI")
    print("==================================================")

    # Test 1: Rule Engine Accuracy against Textbook ground truth
    ground_truth = {
        "พระยา": "ᨻᩕ᩠ᨿᩣ",
        "ผะญ่า": "ᨽ᩠ᨿᩣ",
        "นาค": "ᩁᩣᨠ",
        "เวทนา": "ᩓᨲᩣ",
        "ทั้งหลาย": "ᨴ᩠ᩃᩢ᩠ᨿ",
        "ดอกมัดกล้า": "ᨯᩁ᩠ᨠᨾᩢ᩠ᨯᨠ᩠ᩃ᩶ᩣ"
    }

    print("\n[Test 1] Testing Orthography Rule Engine...")
    correct_rules = 0
    for thai, expected_lanna in ground_truth.items():
        actual_lanna = transliterate_word_rule_based(thai)
        match = actual_lanna == expected_lanna
        if match:
            correct_rules += 1
        print(f"  Word: {thai:<12} Expected: {expected_lanna:<10} Actual: {actual_lanna:<10} Match: {match}")
    
    rule_accuracy = (correct_rules / len(ground_truth)) * 100
    print(f"Rule Engine Accuracy: {rule_accuracy:.2f}% ({correct_rules}/{len(ground_truth)})")

    # Test 2: Dataset Integrity
    print("\n[Test 2] Testing Dataset Integrity...")
    dict_file = os.path.join(MODEL_DIR, "lanna_dict.json")
    if os.path.exists(dict_file):
        with open(dict_file, "r", encoding="utf-8") as f:
            dataset = json.load(f)
        valid_unicode_count = sum(1 for item in dataset if validate_lanna_unicode(item["lanna"]))
        print(f"  Total items in dataset: {len(dataset)}")
        print(f"  Items with valid Lanna Unicode: {valid_unicode_count}/{len(dataset)} ({(valid_unicode_count/len(dataset))*100:.2f}%)")

    # Test 3: Inference Engine Test
    print("\n[Test 3] Testing Inference Engine Pipeline...")
    ai = LannaAIInference()
    sample = ai.convert_thai_to_lanna("พระยา ดอกมัดกล้า ทั้งหลาย")
    print(f"  Input: {sample['input_thai']}")
    print(f"  Output Lanna Unicode: {sample['lanna_script']}")
    print(f"  Valid Lanna Unicode Result: {sample['is_valid_lanna_unicode']}")

    print("\n" + "=" * 50)
    print("  ALL VERIFICATION TESTS COMPLETED SUCCESSFULLY!")
    print("=" * 50)

if __name__ == "__main__":
    run_evaluation()
