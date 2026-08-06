import os

path = r'D:\PROJECT_LANNA\Lanna_Admin\src\views\lanna-char'
if os.path.exists(path):
    print("Directory exists! Contents:")
    print(os.listdir(path))
else:
    print("Directory does NOT exist!")
