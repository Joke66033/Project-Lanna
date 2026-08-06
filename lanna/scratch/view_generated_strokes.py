import sys

sys.stdout.reconfigure(encoding='utf-8')
try:
    with open('lib/page/lean/train/generated_consonant_strokes.dart', 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    def print_char_strokes(char):
        found = False
        brace_count = 0
        for i, line in enumerate(lines):
            if f"'{char}':" in line or f'"{char}":' in line:
                found = True
                start = i
                break
        if found:
            for i in range(start, len(lines)):
                print(lines[i].rstrip())
                brace_count += lines[i].count('[')
                brace_count -= lines[i].count(']')
                if brace_count == 0 and i > start:
                    break
        else:
            print(f"Character {char} not found in generated_consonant_strokes.dart")

    print("--- Generated strokes for ᨿ (U+1A3F) ---")
    print_char_strokes('ᨿ')
    print("\n--- Generated strokes for ᩀ (U+1A40) ---")
    print_char_strokes('ᩀ')
except Exception as e:
    print(f"Error: {e}")
