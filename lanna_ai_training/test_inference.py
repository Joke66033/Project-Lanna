import os
import sys
import json
import torch
import torch.nn as nn
from torchvision import transforms, models
from PIL import Image

sys.stdout.reconfigure(encoding='utf-8')

BASE_DIR = r"D:\PROJECT_LANNA\lanna_ai_training"
MODEL_PATH = os.path.join(BASE_DIR, "lanna_ai_model.pth")
META_PATH = os.path.join(BASE_DIR, "model_metadata.json")

print("Checking model files...", flush=True)
if not os.path.exists(MODEL_PATH) or not os.path.exists(META_PATH):
    print("Files not found!", flush=True)
    sys.exit(1)

with open(META_PATH, "r", encoding="utf-8") as f:
    meta = json.load(f)

classes = meta["classes"]
class_info = meta["class_info"]
print(f"Loaded {len(classes)} classes from metadata.", flush=True)

device = torch.device("cpu")
model = models.mobilenet_v3_small(weights=None)
in_features = model.classifier[3].in_features
model.classifier[3] = nn.Linear(in_features, len(classes))
model.load_state_dict(torch.load(MODEL_PATH, map_location=device))
model.eval()

transform = transforms.Compose([
    transforms.Resize((128, 256)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

# Test on 5 different sample images from dataset
sample_imgs = [
    "lanna_00000_LNTilok.jpg",
    "lanna_00040_LNTilok.jpg",
    "lanna_00080_LNTilok.jpg",
    "lanna_00120_LNTilok.jpg",
    "lanna_00160_LNTilok.jpg"
]

print("\n=== INFERENCE TEST RESULTS ===", flush=True)
for img_name in sample_imgs:
    img_path = os.path.join(BASE_DIR, "dataset", "images", img_name)
    if not os.path.exists(img_path):
        continue
    image = Image.open(img_path).convert("RGB")
    tensor = transform(image).unsqueeze(0)
    
    with torch.no_grad():
        out = model(tensor)
        prob = torch.softmax(out, dim=1)[0]
    
    top_prob, top_idx = torch.topk(prob, 1)
    cls_name = classes[top_idx[0].item()]
    info = class_info.get(cls_name, {})
    thai = info.get("thai_translation", "")
    reading = info.get("reading", "")
    confidence = top_prob[0].item() * 100
    
    print(f"[{img_name}] -> Result: {thai} ({reading}) | Confidence: {confidence:.2f}%", flush=True)

print("Inference test finished successfully!", flush=True)
