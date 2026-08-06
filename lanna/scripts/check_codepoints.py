import json

with open('categories_out.txt', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for line in lines:
    if 'CharID:' in line:
        # Extract CharID, Lanna and Thai
        parts = line.strip().split(' | ')
        char_id = parts[0].split(': ')[1]
        lanna_str = parts[1].split(': ')[1].strip("'")
        thai_str = parts[2].split(': ')[1].strip("'")
        
        codepoints = " ".join(f"U+{ord(c):04X}" for c in lanna_str)
        print(f"ID: {char_id} | Lanna: {repr(lanna_str)} ({codepoints}) | Thai: {thai_str}")
