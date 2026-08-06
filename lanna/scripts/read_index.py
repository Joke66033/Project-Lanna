with open(r'D:\PROJECT_LANNA\Lanna_Admin\src\views\lanna-char\index.vue', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i in range(120, min(180, len(lines))):
    print(f"{i+1}: {lines[i]}", end='')
