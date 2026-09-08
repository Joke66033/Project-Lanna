import os
import sys
import glob
from predict import LannaPredictor

sys.stdout.reconfigure(encoding='utf-8')
predictor = LannaPredictor()
images = glob.glob(r"D:\PROJECT_LANNA\lanna_ai_training\dataset\images\*.jpg")

test_picks = images[::320][:9]
print("=== DIVERSE SAMPLE INFERENCE RESULTS ===")
for img in test_picks:
    res = predictor.predict(img, top_k=1)[0]
    print(f"[{os.path.basename(img)}] -> แปลว่า: {res['thai_translation']} (อ่านว่า: {res['reading']}) | ความแม่นยำ: {res['confidence']*100:.2f}%")
