import json

with open('api_response.txt', 'r', encoding='utf-8') as f:
    data = json.load(f)

with open('fha_results.txt', 'w', encoding='utf-8') as out:
    for item in data['data']:
        lanna_char = item.get('lanna_char', '')
        thai = item.get('thai_equivalent', '')
        if 'ฝ' in lanna_char or 'ฝ' in thai:
            out.write(f"ID: {item.get('char_id')} | Lanna: {lanna_char} ({[ord(c) for c in lanna_char]}) | Thai: {thai}\n")
print("Wrote fha_results.txt")
