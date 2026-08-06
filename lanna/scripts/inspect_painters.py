import os
import re

leaning_dir = r'lib\page\lean\leaning'
files = ['consonant.dart', 'number.dart', 'spelling.dart', 'tone.dart', 'vowel.dart']

for filename in files:
    filepath = os.path.join(leaning_dir, filename)
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extract the custom painter class definition and its paint method
    match = re.search(r'class\s+\w+Painter\s+extends\s+CustomPainter\s*\{(.*?)\n\s*@override\s+bool\s+shouldRepaint', content, re.DOTALL)
    if match:
        body = match.group(1)
        # Just print lines around TextPainter/scale to verify structure
        print(f"=== File: {filename} ===")
        for line in body.split('\n'):
            if 'TextPainter' in line or 'Offset scale' in line or 'scale(' in line or 'fontSize:' in line or 'fontFamily:' in line:
                print("  ", line.strip())
