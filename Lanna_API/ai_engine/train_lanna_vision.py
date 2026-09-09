import os
import glob
import json
import random
import sys
import time
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
import torchvision.transforms as transforms
import torchvision.models as models

sys.stdout.reconfigure(encoding='utf-8')

print("=" * 60)
print("  🚀 LANNA VISION OCR MODEL TRAINING (Balanced Real + Synthetic)")
print("=" * 60)

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Hardware Acceleration Device: {DEVICE}")

METADATA_PATH = r"C:\Users\HP\.gemini\antigravity\brain\2dcac35c-0eb4-46dc-883e-c63bc430fffc\scratch\lanna_dataset_metadata.json"
with open(METADATA_PATH, "r", encoding="utf-8") as fp:
    base_data = json.load(fp)

classes = sorted(list(set([item["label_thai"] for item in base_data])))
class_to_idx = {cls_name: i for i, cls_name in enumerate(classes)}
idx_to_class = {i: cls_name for i, cls_name in enumerate(classes)}

FONTS = [
    r"D:\PROJECT_LANNA\lanna\assets\fonts\NotoSansTaiTham.ttf",
    r"D:\PROJECT_LANNA\lanna\assets\fonts\PayapLanna-Regular.ttf",
    r"D:\PROJECT_LANNA\lanna\assets\fonts\LN-TILOK-6.10.ttf",
]
FONTS = [f for f in FONTS if os.path.exists(f)]

TRAIN_DIR = r"D:\PROJECT\lanna_vision_train_data"
os.makedirs(TRAIN_DIR, exist_ok=True)

dataset_samples = []

# 1. Heavily Augment REAL Photos (50 variations each)
print("Augmenting Real Photo Samples (50x per class)...")
for item in base_data:
    src_path = item["filepath"]
    cls_idx = class_to_idx[item["label_thai"]]
    if not os.path.exists(src_path):
        continue
    
    orig_im = Image.open(src_path).convert("RGB")
    dataset_samples.append((src_path, cls_idx))
    
    for v in range(50):
        im = orig_im.copy()
        # Random crop / resize
        w, h = im.size
        cw = int(w * random.uniform(0.85, 1.0))
        ch = int(h * random.uniform(0.85, 1.0))
        cx = random.randint(0, w - cw)
        cy = random.randint(0, h - ch)
        im = im.crop((cx, cy, cx + cw, cy + ch))
        
        # Color & contrast jitter
        enh = ImageEnhance.Contrast(im)
        im = enh.enhance(random.uniform(0.7, 1.4))
        enh = ImageEnhance.Brightness(im)
        im = enh.enhance(random.uniform(0.75, 1.3))
        
        if random.random() > 0.5:
            im = im.filter(ImageFilter.GaussianBlur(radius=random.uniform(0.3, 0.7)))
        
        out_f = os.path.join(TRAIN_DIR, f"real_aug_{cls_idx:02d}_{v:02d}.jpg")
        im.save(out_f, quality=random.randint(80, 95))
        dataset_samples.append((out_f, cls_idx))

# 2. Add Synthetic Font Samples (20 variations each)
print("Generating Synthetic Font Variations...")
for item in base_data:
    lanna_unicode = item["lanna_unicode"]
    cls_idx = class_to_idx[item["label_thai"]]
    
    for font_path in FONTS:
        for var in range(15):
            font_size = random.randint(38, 54)
            try:
                font = ImageFont.truetype(font_path, font_size)
            except Exception:
                continue
            
            w, h = 320, 120
            bg_color = random.choice([
                (255, 255, 255), (245, 240, 230), (235, 225, 210), (220, 210, 195)
            ])
            text_color = random.choice([
                (10, 10, 10), (35, 25, 15), (20, 20, 25), (50, 35, 20)
            ])
            
            img = Image.new("RGB", (w, h), color=bg_color)
            draw = ImageDraw.Draw(img)
            bbox = draw.textbbox((0, 0), lanna_unicode, font=font)
            tw = bbox[2] - bbox[0]
            th = bbox[3] - bbox[1]
            x = (w - tw) // 2 + random.randint(-8, 8)
            y = (h - th) // 2 + random.randint(-5, 5)
            draw.text((x, y), lanna_unicode, font=font, fill=text_color)
            
            out_file = os.path.join(TRAIN_DIR, f"syn_{cls_idx:02d}_{var:02d}_{os.path.basename(font_path)}.jpg")
            img.save(out_file, quality=random.randint(85, 95))
            dataset_samples.append((out_file, cls_idx))

print(f"Total Balanced Dataset: {len(dataset_samples)} images across {len(classes)} classes.")

# PyTorch Dataset
class LannaDataset(Dataset):
    def __init__(self, samples, transform=None):
        self.samples = samples
        self.transform = transform

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        path, label = self.samples[idx]
        try:
            image = Image.open(path).convert("RGB")
        except Exception:
            image = Image.new("RGB", (224, 224), color=(255, 255, 255))
        if self.transform:
            image = self.transform(image)
        return image, label

train_transform = transforms.Compose([
    transforms.Resize((128, 256)),
    transforms.RandomRotation(degrees=6),
    transforms.ColorJitter(brightness=0.15, contrast=0.15),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

random.shuffle(dataset_samples)
split_idx = int(len(dataset_samples) * 0.9)
train_samples = dataset_samples[:split_idx]
val_samples = dataset_samples[split_idx:]

train_loader = DataLoader(LannaDataset(train_samples, train_transform), batch_size=32, shuffle=True)
val_loader = DataLoader(LannaDataset(val_samples, train_transform), batch_size=32, shuffle=False)

# Model
class LannaVisionNet(nn.Module):
    def __init__(self, num_classes):
        super(LannaVisionNet, self).__init__()
        self.backbone = models.mobilenet_v3_small(weights=models.MobileNet_V3_Small_Weights.DEFAULT)
        in_features = self.backbone.classifier[0].in_features
        self.backbone.classifier = nn.Sequential(
            nn.Linear(in_features, 256),
            nn.Hardswish(),
            nn.Dropout(p=0.2),
            nn.Linear(256, num_classes)
        )

    def forward(self, x):
        return self.backbone(x)

model = LannaVisionNet(num_classes=len(classes)).to(DEVICE)
criterion = nn.CrossEntropyLoss(label_smoothing=0.03)
optimizer = optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=15)

EPOCHS = 15
print(f"\n--- TRAINING ({EPOCHS} Epochs) ---")
best_acc = 0.0

for epoch in range(1, EPOCHS + 1):
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0
    for images, labels in train_loader:
        images, labels = images.to(DEVICE), labels.to(DEVICE)
        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()
        running_loss += loss.item() * images.size(0)
        _, preds = torch.max(outputs, 1)
        correct += (preds == labels).sum().item()
        total += labels.size(0)
        
    scheduler.step()
    train_acc = (correct / total) * 100.0
    
    # Validation
    model.eval()
    val_correct = 0
    val_total = 0
    with torch.no_grad():
        for images, labels in val_loader:
            images, labels = images.to(DEVICE), labels.to(DEVICE)
            outputs = model(images)
            _, preds = torch.max(outputs, 1)
            val_correct += (preds == labels).sum().item()
            val_total += labels.size(0)
            
    val_acc = (val_correct / val_total) * 100.0 if val_total > 0 else 0
    print(f"Epoch [{epoch:02d}/{EPOCHS:02d}] | Train Acc: {train_acc:.2f}% | Val Acc: {val_acc:.2f}%")
    if val_acc > best_acc:
        best_acc = val_acc

# Save
MODEL_SAVE_PATH = r"D:\PROJECT_LANNA\Lanna_API\ai_engine\lanna_vision_model.pth"
META_SAVE_PATH = r"D:\PROJECT_LANNA\Lanna_API\ai_engine\lanna_model_classes.json"

torch.save(model.state_dict(), MODEL_SAVE_PATH)
metadata_export = {
    "classes": classes,
    "class_to_idx": class_to_idx,
    "idx_to_class": idx_to_class,
    "lexicon": {item["label_thai"]: item for item in base_data},
    "best_val_accuracy": best_acc,
    "trained_at": time.strftime("%Y-%m-%d %H:%M:%S")
}

with open(META_SAVE_PATH, "w", encoding="utf-8") as fp:
    json.dump(metadata_export, fp, ensure_ascii=False, indent=2)

print(f"\nSaved Best Model ({best_acc:.2f}% accuracy) to {MODEL_SAVE_PATH}")
