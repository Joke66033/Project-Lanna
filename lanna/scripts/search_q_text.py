import os

for root, dirs, files in os.walk(r'D:\PROJECT_LANNA\Lanna_Admin\src'):
    for file in files:
        path = os.path.join(root, file)
        try:
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
                if 'ม' in content or 'มะ' in content:
                    print(f"File: {path}")
                    # print lines containing 'ม' or 'มะ'
                    lines = content.split('\n')
                    for idx, line in enumerate(lines):
                        if 'ม' in line or 'มะ' in line:
                            print(f"  {idx+1}: {line}")
        except Exception as e:
            pass
