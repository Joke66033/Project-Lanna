with open(r'lib\page\lean\leaning\consonant.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if 'TextPainter' in line or 'CustomPaint' in line:
        print(f"Line {i+1}: {line.strip()}")
