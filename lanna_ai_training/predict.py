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

class LannaPredictor:
    def __init__(self, model_path=MODEL_PATH, meta_path=META_PATH):
        with open(meta_path, "r", encoding="utf-8") as f:
            self.meta = json.load(f)
            
        self.classes = self.meta["classes"]
        self.class_info = self.meta["class_info"]
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        
        self.model = models.mobilenet_v3_small(weights=None)
        in_features = self.model.classifier[3].in_features
        self.model.classifier[3] = nn.Linear(in_features, len(self.classes))
        
        if os.path.exists(model_path):
            self.model.load_state_dict(torch.load(model_path, map_location=self.device))
        self.model.to(self.device)
        self.model.eval()
        
        self.transform = transforms.Compose([
            transforms.Resize((128, 256)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])

    def predict(self, image_path_or_pil, top_k=3):
        if isinstance(image_path_or_pil, str):
            image = Image.open(image_path_or_pil).convert("RGB")
        else:
            image = image_path_or_pil.convert("RGB")
            
        img_tensor = self.transform(image).unsqueeze(0).to(self.device)
        
        with torch.no_grad():
            outputs = self.model(img_tensor)
            probabilities = torch.softmax(outputs, dim=1)[0]
            
        top_probs, top_indices = torch.topk(probabilities, top_k)
        
        results = []
        for prob, idx in zip(top_probs, top_indices):
            class_name = self.classes[idx.item()]
            info = self.class_info.get(class_name, {})
            results.append({
                "lanna_text": class_name,
                "thai_translation": info.get("thai_translation", ""),
                "reading": info.get("reading", ""),
                "confidence": float(prob.item())
            })
            
        return results

if __name__ == "__main__":
    predictor = LannaPredictor()
    
    if len(sys.argv) > 1:
        test_images = [sys.argv[1]]
    else:
        # Test 5 sample images
        test_images = [
            os.path.join(BASE_DIR, "dataset", "images", f)
            for f in ["lanna_00000_LNTilok.jpg", "lanna_00040_LNTilok.jpg", "lanna_00080_LNTilok.jpg", "lanna_00120_LNTilok.jpg"]
            if os.path.exists(os.path.join(BASE_DIR, "dataset", "images", f))
        ]
        
    print("=== LANNA AI OCR INFERENCE RESULTS ===")
    for img_path in test_images:
        print(f"\nImage: {os.path.basename(img_path)}")
        res = predictor.predict(img_path, top_k=3)
        for i, r in enumerate(res, 1):
            print(f"  [{i}] แปลว่า: {r['thai_translation']} (คำอ่าน: {r['reading']}) | ความแม่นยำ: {r['confidence']*100:.2f}%")
