import json

with open('api_response.txt', 'r', encoding='utf-8') as f:
    data = json.load(f)

for item in data['data']:
    lanna_char = item.get('lanna_char', '')
    if any(ord(c) == 3613 for c in lanna_char):
        print(f"FOUND THAI ฝ IN DATABASE! ID: {item.get('char_id')} | Lanna: {lanna_char} | Thai: {item.get('thai_equivalent')}")
