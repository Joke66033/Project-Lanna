with open(r'lib\services\lanna_transliterator.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# print lines around 'ฝ'
for idx, line in enumerate(content.split('\n')):
    if 'ฝ' in line:
        # print character codes of characters in line
        codes = [ord(c) for c in line]
        print(f"Line {idx+1}: {[chr(c) if c < 128 else f'U+{c:04X}' for c in codes]}")
