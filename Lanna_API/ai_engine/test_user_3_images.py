import sys
from predict_vision import predict_image

sys.stdout.reconfigure(encoding='utf-8')

test_images = [
    (r"C:\Users\HP\.gemini\antigravity\brain\2dcac35c-0eb4-46dc-883e-c63bc430fffc\.user_uploaded\media_1788944718443.jpg", "ภาพที่ 1 (ชอล์ก): เมืองอินทร์"),
    (r"C:\Users\HP\.gemini\antigravity\brain\2dcac35c-0eb4-46dc-883e-c63bc430fffc\.user_uploaded\media_1788944718443.png", "ภาพที่ 2 (กราฟิก): ฉลาด"),
    (r"C:\Users\HP\.gemini\antigravity\brain\2dcac35c-0eb4-46dc-883e-c63bc430fffc\.user_uploaded\media_1788944718449.jpg", "ภาพที่ 3 (ชอล์ก): ผองจาย")
]

print("=== TESTING TRAINED VISION MODEL ON USER UPLOADED IMAGES ===")
for path, label in test_images:
    res = predict_image(path)
    print(f"[{label}]")
    print(f" -> ผลการทำนาย: {res['text']} (ความมั่นใจ: {res['confidence']*100:.1f}%)")
    print(f" -> Tai Tham Unicode: {res['lanna_text']}")
    print(f" -> คำอ่าน: {res['reading']}")
    print(f" -> ความหมาย: {res['meaning']}\n")
