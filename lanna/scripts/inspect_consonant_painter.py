with open(r'lib\page\lean\leaning\consonant.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_idx = content.find('class StrokePainter')
if start_idx != -1:
    with open('consonant_painter.txt', 'w', encoding='utf-8') as outf:
        outf.write(content[start_idx:start_idx+6000])
    print("Wrote consonant_painter.txt")
else:
    print("StrokePainter not found")
