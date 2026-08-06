import urllib.request
import json

url = "https://siripaporn.lnw.mn/endpoints/lanna_char_api.php?action=getAll"
try:
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as response:
        raw = response.read().decode('utf-8')
        data = json.loads(raw)
        
        # Save to file to view safely
        with open('api_response.txt', 'w', encoding='utf-8') as f:
            f.write(json.dumps(data, indent=2, ensure_ascii=False))
        print("Success, wrote api_response.txt")
except Exception as e:
    print(f"Error: {e}")
