"""
Training Script for Thai to Lanna Transliteration AI Model
Trains a PyTorch Neural Model & Rules Hybrid AI Engine on the Lanna Corpus.
Saves model checkpoints to `./output_model/`.
"""

import os
import json
import time
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
from lanna_rules import transliterate_word_rule_based, validate_lanna_unicode

MODEL_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(MODEL_DIR, "output_model")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# 1. Vocab Building (Char-level mapping for Thai input & Lanna output)
def build_vocabularies(jsonl_path):
    with open(jsonl_path, "r", encoding="utf-8") as f:
        lines = [json.loads(line) for line in f]
    
    input_chars = set()
    output_chars = set()
    for item in lines:
        for c in item["input"]:
            input_chars.add(c)
        for c in item["output"]:
            output_chars.add(c)
            
    input_vocab = {"<PAD>": 0, "<UNK>": 1, "<SOS>": 2, "<EOS>": 3}
    for c in sorted(list(input_chars)):
        input_vocab[c] = len(input_vocab)
        
    output_vocab = {"<PAD>": 0, "<UNK>": 1, "<SOS>": 2, "<EOS>": 3}
    for c in sorted(list(output_chars)):
        output_vocab[c] = len(output_vocab)
        
    rev_output_vocab = {v: k for k, v in output_vocab.items()}
    return input_vocab, output_vocab, rev_output_vocab

# 2. Dataset Class
class LannaTransliterationDataset(Dataset):
    def __init__(self, jsonl_path, input_vocab, output_vocab, max_len=64):
        with open(jsonl_path, "r", encoding="utf-8") as f:
            self.data = [json.loads(line) for line in f]
        self.input_vocab = input_vocab
        self.output_vocab = output_vocab
        self.max_len = max_len

    def __len__(self):
        return len(self.data)

    def __getitem__(self, idx):
        item = self.data[idx]
        inp_str = item["input"]
        out_str = item["output"]

        inp_ids = [self.input_vocab.get(c, self.input_vocab["<UNK>"]) for c in inp_str] + [self.input_vocab["<EOS>"]]
        out_ids = [self.output_vocab["<SOS>"]] + [self.output_vocab.get(c, self.output_vocab["<UNK>"]) for c in out_str] + [self.output_vocab["<EOS>"]]

        # Padding
        inp_padded = inp_ids + [self.input_vocab["<PAD>"]] * (self.max_len - len(inp_ids))
        out_padded = out_ids + [self.output_vocab["<PAD>"]] * (self.max_len - len(out_ids))

        return torch.tensor(inp_padded[:self.max_len]), torch.tensor(out_padded[:self.max_len])

# 3. Neural Model Architecture (Seq2Seq Transformer/GRU Architecture)
class LannaTransliterationModel(nn.Module):
    def __init__(self, input_vocab_size, output_vocab_size, embed_dim=128, hidden_dim=256):
        super(LannaTransliterationModel, self).__init__()
        self.embedding = nn.Embedding(input_vocab_size, embed_dim)
        self.encoder = nn.GRU(embed_dim, hidden_dim, batch_first=True, bidirectional=True)
        self.decoder_embedding = nn.Embedding(output_vocab_size, embed_dim)
        self.decoder = nn.GRU(embed_dim + hidden_dim * 2, hidden_dim, batch_first=True)
        self.fc_out = nn.Linear(hidden_dim, output_vocab_size)

    def forward(self, src, trg):
        # src: [batch, seq_len], trg: [batch, seq_len]
        src_emb = self.embedding(src)
        enc_out, _ = self.encoder(src_emb) # [batch, seq_len, hidden_dim*2]

        trg_emb = self.decoder_embedding(trg)
        # Context concat
        batch_size, seq_len, _ = trg_emb.shape
        context = enc_out.mean(dim=1, keepdim=True).repeat(1, seq_len, 1)
        dec_in = torch.cat((trg_emb, context), dim=2)
        
        dec_out, _ = self.decoder(dec_in)
        logits = self.fc_out(dec_out)
        return logits

def train():
    train_path = os.path.join(MODEL_DIR, "train.jsonl")
    val_path = os.path.join(MODEL_DIR, "val.jsonl")
    
    if not os.path.exists(train_path):
        print("Dataset not found! Running build_dataset.py first...")
        from build_dataset import generate_jsonl_dataset
        generate_jsonl_dataset()

    input_vocab, output_vocab, rev_output_vocab = build_vocabularies(train_path)

    # Save Vocab files for inference
    with open(os.path.join(OUTPUT_DIR, "vocab_info.json"), "w", encoding="utf-8") as f:
        json.dump({
            "input_vocab": input_vocab,
            "output_vocab": output_vocab,
            "rev_output_vocab": {str(k): v for k, v in rev_output_vocab.items()}
        }, f, ensure_ascii=False, indent=2)

    train_ds = LannaTransliterationDataset(train_path, input_vocab, output_vocab)
    val_ds = LannaTransliterationDataset(val_path, input_vocab, output_vocab)

    train_loader = DataLoader(train_ds, batch_size=8, shuffle=True)
    val_loader = DataLoader(val_ds, batch_size=8, shuffle=False)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Starting Lanna AI Training using device: {device}...")

    model = LannaTransliterationModel(len(input_vocab), len(output_vocab)).to(device)
    criterion = nn.CrossEntropyLoss(ignore_index=output_vocab["<PAD>"])
    optimizer = optim.Adam(model.parameters(), lr=0.002)

    epochs = 20
    best_loss = float("inf")

    print("=" * 60)
    print(f"| Epoch | Train Loss | Val Loss | Time Elapsed | Checkpoint Saved |")
    print("=" * 60)

    start_time = time.time()
    for epoch in range(1, epochs + 1):
        model.train()
        total_train_loss = 0

        for src, trg in train_loader:
            src, trg = src.to(device), trg.to(device)
            trg_input = trg[:, :-1]
            trg_target = trg[:, 1:]

            optimizer.zero_grad()
            logits = model(src, trg_input)
            loss = criterion(logits.reshape(-1, logits.shape[-1]), trg_target.reshape(-1))
            loss.backward()
            optimizer.step()

            total_train_loss += loss.item()

        avg_train_loss = total_train_loss / len(train_loader)

        # Validation
        model.eval()
        total_val_loss = 0
        with torch.no_grad():
            for src, trg in val_loader:
                src, trg = src.to(device), trg.to(device)
                trg_input = trg[:, :-1]
                trg_target = trg[:, 1:]

                logits = model(src, trg_input)
                loss = criterion(logits.reshape(-1, logits.shape[-1]), trg_target.reshape(-1))
                total_val_loss += loss.item()

        avg_val_loss = total_val_loss / len(val_loader) if len(val_loader) > 0 else avg_train_loss
        elapsed = time.time() - start_time

        saved = "No"
        if avg_val_loss < best_loss:
            best_loss = avg_val_loss
            torch.save(model.state_dict(), os.path.join(OUTPUT_DIR, "lanna_ai_model.pt"))
            saved = "Yes (Best)"

        print(f"|  {epoch:02d}/{epochs:02d} |   {avg_train_loss:.4f}   |  {avg_val_loss:.4f}  |   {elapsed:.2f}s     |     {saved:<11} |")

    print("=" * 60)
    print(f"Training Complete! Best Model saved to: {os.path.join(OUTPUT_DIR, 'lanna_ai_model.pt')}")

if __name__ == "__main__":
    train()
