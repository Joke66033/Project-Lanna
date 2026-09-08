import os
import json
import time
import pandas as pd
import numpy as np
from PIL import Image

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms, models

# Set seed
torch.manual_seed(42)

BASE_DIR = r"D:\PROJECT_LANNA\lanna_ai_training"
DATASET_DIR = os.path.join(BASE_DIR, "dataset")
CSV_PATH = os.path.join(DATASET_DIR, "labels.csv")
MODEL_SAVE_PATH = os.path.join(BASE_DIR, "lanna_ai_model.pth")
META_SAVE_PATH = os.path.join(BASE_DIR, "model_metadata.json")

print("1. Loading dataset labels...")
df = pd.read_csv(CSV_PATH)
print(f"Total samples: {len(df)}")

# Create class mapping
unique_classes = sorted(df["lanna_text"].unique().tolist())
class_to_idx = {c: i for i, c in enumerate(unique_classes)}
idx_to_class = {i: c for c, i in class_to_idx.items()}

# Mapping from lanna_text to metadata (thai_translation, reading)
class_info = {}
for _, row in df.iterrows():
    l_text = row["lanna_text"]
    if l_text not in class_info:
        class_info[l_text] = {
            "thai_translation": str(row["thai_translation"]),
            "reading": str(row["reading"])
        }

df["label_idx"] = df["lanna_text"].map(class_to_idx)

# Save metadata
metadata = {
    "num_classes": len(unique_classes),
    "classes": unique_classes,
    "class_info": class_info,
    "img_size": [128, 256],  # H, W
}
with open(META_SAVE_PATH, "w", encoding="utf-8") as f:
    json.dump(metadata, f, ensure_ascii=False, indent=2)

print(f"Number of classes: {len(unique_classes)}")

# Train / Val Split
shuffled_df = df.sample(frac=1.0, random_state=42).reset_index(drop=True)
val_size = int(len(shuffled_df) * 0.15)
train_df = shuffled_df.iloc[val_size:].reset_index(drop=True)
val_df = shuffled_df.iloc[:val_size].reset_index(drop=True)

print(f"Train samples: {len(train_df)} | Val samples: {len(val_df)}")

# Dataset definition
class LannaDataset(Dataset):
    def __init__(self, dataframe, dataset_dir, transform=None):
        self.df = dataframe
        self.dataset_dir = dataset_dir
        self.transform = transform

    def __len__(self):
        return len(self.df)

    def __getitem__(self, idx):
        row = self.df.iloc[idx]
        img_full_path = os.path.join(self.dataset_dir, row["image_path"])
        image = Image.open(img_full_path).convert("RGB")
        
        if self.transform:
            image = self.transform(image)
            
        label = row["label_idx"]
        return image, label

# Transforms
train_transform = transforms.Compose([
    transforms.Resize((128, 256)),
    transforms.ColorJitter(brightness=0.2, contrast=0.2),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

val_transform = transforms.Compose([
    transforms.Resize((128, 256)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

train_dataset = LannaDataset(train_df, DATASET_DIR, transform=train_transform)
val_dataset = LannaDataset(val_df, DATASET_DIR, transform=val_transform)

train_loader = DataLoader(train_dataset, batch_size=32, shuffle=True, num_workers=0)
val_loader = DataLoader(val_dataset, batch_size=32, shuffle=False, num_workers=0)

# Build Model: MobileNetV3 (lightweight, fast, high accuracy)
print("2. Initializing MobileNetV3 Neural Network...")
model = models.mobilenet_v3_small(weights=models.MobileNet_V3_Small_Weights.DEFAULT)
in_features = model.classifier[3].in_features
model.classifier[3] = nn.Linear(in_features, len(unique_classes))

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = model.to(device)

criterion = nn.CrossEntropyLoss()
optimizer = optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=12)

# Training loop
epochs = 12
print(f"3. Starting training for {epochs} epochs on {device}...")
start_time = time.time()

best_val_acc = 0.0

for epoch in range(1, epochs + 1):
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0
    
    for images, labels in train_loader:
        images, labels = images.to(device), labels.to(device)
        
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
    train_loss = running_loss / total
    train_acc = (correct / total) * 100.0
    
    # Validation
    model.eval()
    val_loss = 0.0
    val_correct = 0
    val_total = 0
    with torch.no_grad():
        for images, labels in val_loader:
            images, labels = images.to(device), labels.to(device)
            outputs = model(images)
            loss = criterion(outputs, labels)
            val_loss += loss.item() * images.size(0)
            _, preds = torch.max(outputs, 1)
            val_correct += (preds == labels).sum().item()
            val_total += labels.size(0)
            
    val_loss = val_loss / val_total
    val_acc = (val_correct / val_total) * 100.0
    
    print(f"Epoch [{epoch:02d}/{epochs:02d}] Train Loss: {train_loss:.4f} Acc: {train_acc:.2f}% | Val Loss: {val_loss:.4f} Acc: {val_acc:.2f}%")
    
    if val_acc > best_val_acc:
        best_val_acc = val_acc
        torch.save(model.state_dict(), MODEL_SAVE_PATH)

total_duration = time.time() - start_time
print(f"Training Complete in {total_duration:.1f}s! Best Validation Accuracy: {best_val_acc:.2f}%")
print(f"Model saved to: {MODEL_SAVE_PATH}")
