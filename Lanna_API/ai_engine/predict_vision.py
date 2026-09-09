import os
import json
import sys
import torch
import torch.nn as nn
import torchvision.transforms as transforms
import torchvision.models as models
from PIL import Image

sys.stdout.reconfigure(encoding='utf-8')

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

MODEL_PATH = r"D:\PROJECT_LANNA\Lanna_API\ai_engine\lanna_vision_model.pth"
META_PATH = r"D:\PROJECT_LANNA\Lanna_API\ai_engine\lanna_model_classes.json"

with open(META_PATH, "r", encoding="utf-8") as fp:
    metadata = json.load(fp)

classes = metadata["classes"]
lexicon = metadata["lexicon"]

class LannaVisionNet(nn.Module):
    def __init__(self, num_classes):
        super(LannaVisionNet, self).__init__()
        self.backbone = models.mobilenet_v3_small(weights=None)
        in_features = self.backbone.classifier[0].in_features
        self.backbone.classifier = nn.Sequential(
            nn.Linear(in_features, 256),
            nn.Hardswish(),
            nn.Dropout(p=0.2),
            nn.Linear(256, num_classes)
        )

    def forward(self, x):
        return self.backbone(x)

# Load model
model = LannaVisionNet(num_classes=len(classes)).to(DEVICE)
model.load_state_dict(torch.load(MODEL_PATH, map_location=DEVICE, weights_only=True))
model.eval()

transform = transforms.Compose([
    transforms.Resize((128, 256)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

def predict_image(image_path_or_bytes):
    if isinstance(image_path_or_bytes, str):
        image = Image.open(image_path_or_bytes).convert("RGB")
    else:
        import io
        image = Image.open(io.BytesIO(image_path_or_bytes)).convert("RGB")

    tensor = transform(image).unsqueeze(0).to(DEVICE)
    with torch.no_grad():
        outputs = model(tensor)
        probs = torch.softmax(outputs, dim=1)
        conf, pred_idx = torch.max(probs, dim=1)
        
    cls_name = classes[pred_idx.item()]
    confidence = conf.item()
    
    lex = lexicon.get(cls_name, {})
    return {
        "text": cls_name,
        "lanna_text": lex.get("lanna_unicode", ""),
        "reading": lex.get("reading", ""),
        "meaning": lex.get("meaning", ""),
        "confidence": round(confidence, 4),
        "direction": "ภาษาล้านนา → ภาษาไทย (Trained AI Vision)"
    }

if __name__ == "__main__":
    if len(sys.argv) > 1:
        img_arg = sys.argv[1]
        res = predict_image(img_arg)
        print(json.dumps(res, ensure_ascii=False))
        sys.exit(0)

    test_files = [
        (r"D:\PROJECT\ตัวล้านนา\เชียงใหม่.jpg", "เชียงใหม่ (Original)"),
        (r"C:\Users\HP\.gemini\antigravity\brain\2dcac35c-0eb4-46dc-883e-c63bc430fffc\scratch\user_test_crop.png", "User Crop (เชียงใหม่)"),
        (r"D:\PROJECT\ตัวล้านนา\แพร่.jpg", "แพร่"),
        (r"D:\PROJECT\ตัวล้านนา\เชียงราย.jpg", "เชียงราย"),
        (r"D:\PROJECT\ตัวล้านนา\ลำปาง.jpg", "ลำปาง"),
        (r"D:\PROJECT\ตัวล้านนา\ลาบ.jpg", "ลาบ"),
        (r"D:\PROJECT\ตัวล้านนา\ส้าดิบ.jpg", "ส้าดิบ"),
    ]
    
    print("--- EVALUATING TRAINED LANNA VISION MODEL ---")
    for path, label in test_files:
        if os.path.exists(path):
            res = predict_image(path)
            print(f"[{label}] -> Predicted: '{res['text']}' (Conf: {res['confidence']*100:.1f}%) | Lanna: '{res['lanna_text']}' | Reading: '{res['reading']}'")
