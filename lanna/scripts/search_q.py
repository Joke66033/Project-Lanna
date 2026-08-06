import json

with open('api_response.txt', 'r', encoding='utf-8') as f:
    data = json.load(f)

with open('search_results.txt', 'w', encoding='utf-8') as out:
    for item in data['data']:
        lanna_char = item.get('lanna_char', '')
        thai = item.get('thai_equivalent', '')
        if 'Q' in lanna_char or 'Q' in thai or 'ม' in thai:
            out.write(json.dumps(item, ensure_ascii=False) + '\n')
print("Wrote search_results.txt")
