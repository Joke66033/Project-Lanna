import urllib.request
import json

url = "https://siripaporn.lnw.mn/endpoints/lanna_char_api.php?action=getAll"
try:
    with urllib.request.urlopen(url) as response:
        raw = response.read().decode('utf-8')
        data = json.loads(raw)
except Exception as e:
    print(f"Error fetching: {e}")
    exit(1)

if isinstance(data, dict) and 'data' in data:
    items = data['data']
else:
    items = data

with open('codepoints_out.txt', 'w', encoding='utf-8') as outf:
    for item in items:
        char_id = item.get('char_id', '')
        lanna_char = item.get('lanna_char', '')
        thai_equivalent = item.get('thai_equivalent', '')
        
        codepoints = " ".join(f"U+{ord(c):04X}" for c in lanna_char)
        outf.write(f"ID: {char_id} | Lanna: '{lanna_char}' ({codepoints}) | Thai: '{thai_equivalent}'\n")

print("Wrote codepoints_out.txt successfully!")
