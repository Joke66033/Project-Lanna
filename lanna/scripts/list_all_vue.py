import os

for root, dirs, files in os.walk(r'D:\PROJECT_LANNA'):
    for file in files:
        if file.endswith('.vue') or 'index' in file:
            print(os.path.join(root, file))
