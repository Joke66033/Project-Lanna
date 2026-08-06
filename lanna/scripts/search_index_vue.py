import os

for root, dirs, files in os.walk(r'D:\PROJECT_LANNA'):
    # prune node_modules and .git
    if 'node_modules' in root or '.git' in root or '.venv' in root:
        continue
    for file in files:
        if 'index.vue' in file:
            print(os.path.join(root, file))
