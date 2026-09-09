import os
import sys
import json
import io
from http.server import HTTPServer, BaseHTTPRequestHandler
from PIL import Image
import torch
import torchvision.transforms as transforms
import torchvision.models as models
import torch.nn as nn

sys.stdout.reconfigure(encoding='utf-8')

DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
MODEL_PATH = r'D:\PROJECT_LANNA\Lanna_API\ai_engine\lanna_vision_model.pth'
CLASSES_PATH = r'D:\PROJECT_LANNA\Lanna_API\ai_engine\lanna_model_classes.json'

with open(CLASSES_PATH, 'r', encoding='utf-8') as f:
    meta = json.load(f)

classes = meta['classes']
model = models.mobilenet_v3_small()
model.classifier[3] = nn.Linear(model.classifier[3].in_features, len(classes))
ckpt = torch.load(MODEL_PATH, map_location=DEVICE)
model.load_state_dict(ckpt['state_dict'])
model.eval()
model = model.to(DEVICE)

LEXICON = {
    'เชียงใหม่': {'lanna': 'ᨩ᩠ᨿᨦᩲᩉ᩠ᨾ᩵', 'reading': 'เจียงใหม่', 'meaning': 'จังหวัดเชียงใหม่ในภาคเหนือ'},
    'เชียงราย': {'lanna': 'ᨩ᩠ᨿᨦᩁᩣ᩠ᨿ', 'reading': 'เจียงฮาย', 'meaning': 'จังหวัดเชียงรายในภาคเหนือ'},
    'เมืองอินทร์': {'lanna': 'ᩮᨾᩥ᩠ᨦᩋᩥ᩠ᨶ᩠ᨴᩕ᩼', 'reading': 'เมืองอินทร์', 'meaning': 'ชื่อเฉพาะ / ชื่อสถานที่'},
    'แพร่': {'lanna': 'ᩯᨻᩖ᩵', 'reading': 'แป้', 'meaning': 'จังหวัดแพร่ในภาคเหนือ'},
    'แม่ฮองสอน': {'lanna': 'ᨾᩯ᩵ᩁᩬ᩶ᨦᩈᩬᩁ', 'reading': 'แม่ฮ่องสอน', 'meaning': 'จังหวัดแม่ฮ่องสอนในภาคเหนือ'},
    'น่าน': {'lanna': 'ᨶ᩵ᩣ᩠ᨶ', 'reading': 'น่าน', 'meaning': 'จังหวัดน่านในภาคเหนือ'},
    'พะเยา': {'lanna': 'ᨻ᩠ᨿᩣᩅ', 'reading': 'พะเยา', 'meaning': 'จังหวัดพะเยาในภาคเหนือ'},
    'ลำปาง': {'lanna': 'ᩃᩣᩴᨻᩣ᩠ᨦ', 'reading': 'ลำปาง', 'meaning': 'จังหวัดลำปางในภาคเหนือ'},
    'ลำพูน': {'lanna': 'ᩃᩣᩴᨻᩪ᩠ᨶ', 'reading': 'ลำปูน', 'meaning': 'จังหวัดลำพูนในภาคเหนือ'},
    'ลำไย': {'lanna': 'ᩃᩣᩴᩱᨿ', 'reading': 'ลำไย', 'meaning': 'ผลไม้ลำไย'},
    'ลาบ': {'lanna': 'ᩃᩣ᩠ᨷ', 'reading': 'ลาบ', 'meaning': 'อาหารคาวพื้นเมืองล้านนา'},
    'ลาบควาย': {'lanna': 'ᩃᩣ᩠ᨷᨤ᩠ᩅᩣ᩠ᨿ', 'reading': 'ลาบควย', 'meaning': 'ลาบที่ทำจากเนื้อกระบือ/ควาย'},
    'ลาบหมู': {'lanna': 'ᩃᩣ᩠ᨷᩉ᩠ᨾᩪ', 'reading': 'ลาบหมู', 'meaning': 'ลาบที่ทำจากเนื้อหมู'},
    'ส้าดิบ': {'lanna': 'ᩈ᩶ᩣᨯᩥ᩠ᨷ', 'reading': 'ส้าดิบ', 'meaning': 'อาหารพื้นบ้านล้านนา'},
    'ส้าสุก': {'lanna': 'ᩈ᩶ᩣᩈᩩ᩠ᨠ', 'reading': 'ส้าสุก', 'meaning': 'อาหารประเภทส้าที่ปรุงสุก'},
    'กำเมือง': {'lanna': 'ᨠᩣᩴᨾᩮᩬᩥᨦ', 'reading': 'กำเมือง', 'meaning': 'ภาษาถิ่นเหนือ / ภาษาล้านนา'},
    'ฉลาด': {'lanna': 'ᨧᩕᩣ᩠ᨯ', 'reading': 'ฉลาด / สล่า', 'meaning': 'มีความรู้ ปัญญา ไหวพริบดี หรือช่างฝีมือ'},
    'ชีวิตธรรมดา': {'lanna': 'ᨩᩦᩅᩥ᩠ᨲᨵᩢ᩠ᨾᨯᩣ', 'reading': 'ชีวิตทำมะดา', 'meaning': 'การดำเนินชีวิตอย่างเรียบง่าย'},
    'ผองจาย': {'lanna': 'ᨹᩬᨦᨧᩣ᩠ᨿ', 'reading': 'ผองจาย', 'meaning': 'พวกพ้องชาย / เพื่อนฝูงผู้ชาย'},
    'มหาวิทยาลัยเชียงใหม่': {'lanna': 'ᨾᩉᩣᩅᩥᨴ᩠ᨿᩣᩃᩢ᩠ᨿᨩ᩠ᨿᨦᩲᩉ᩠ᨾ᩵', 'reading': 'มะหาวิดทะยาลัยเจียงใหม่', 'meaning': 'มหาวิทยาลัยเชียงใหม่'},
    'มีความสุข': {'lanna': 'ᨾᩦᨤ᩠ᩅᩣ᩠ᨾᩈᩩ᩠ᨡ', 'reading': 'มีความสุก', 'meaning': 'ความสุข ความสบายใจ'},
    'ราชัน': {'lanna': 'ᩁᩣᨩᩢ᩠ᨶ', 'reading': 'ราชัน', 'meaning': 'พระราชา / ผู้เป็นใหญ่'},
    'ร่ำรวย': {'lanna': 'ᩁᩣᩴ᩵ᩁ᩠ᩅᩫ᩠ᨿ', 'reading': 'ฮ่ำฮวย', 'meaning': 'มั่งคั่ง มีทรัพย์สมบัติมาก'},
    'วัดป่าอ้อเมืองอินทร์': {'lanna': 'ᩅᩢ᩠ᨯᨸ᩵ᩣᩋᩬ᩶ᩮᨾᩥ᩠ᨦᩋᩥ᩠ᨶ᩠ᨴᩕ᩼', 'reading': 'วัดป่าอ้อเมืองอินทร์', 'meaning': 'วัดป่าอ้อเมืองอินทร์ จ.เชียงราย'},
    'วัดพระสิงห์วรมหาวิหาร': {'lanna': 'ᩅᩢ᩠ᨯᨻᩕᩈᩥ᩠ᨦᩉ᩺ᩅᩁᨾᩉᩣᩅᩥᩉᩣᩁ', 'reading': 'วัดพระสิงห์วรมหาวิหาร', 'meaning': 'พระอารามหลวงสำคัญในจังหวัดเชียงใหม่'},
    'วันนี้เป็นวันดีขอให้มีโชค': {'lanna': 'ᩅᩢ᩠ᨶᨶᩦ᩶ᩮᨸ᩠ᨶᩅᩢ᩠ᨶᨯᩦᨡᩬᩁᩱᩉ᩶ᨾᩦᩰᨩ᩠ᨣ', 'reading': 'วันนี้เป๋นวันดี ขอหื้อมีโชค', 'meaning': 'คำอวยพรขอให้พบเจอแต่สิ่งดีและโชคลาภ'},
    'ศิริวิมล': {'lanna': 'ᩈᩥᩁᩥᩅᩥᨾᩃ', 'reading': 'สิริวิมล', 'meaning': 'ชื่อเฉพาะ (มีความงามและบริสุทธิ์)'},
    'สวัสดีปีใหม่': {'lanna': 'ᩈᩅᩢ᩠ᩈᨯᩦᨸᩦᩉ᩠ᨾᩲ᩵', 'reading': 'สวัสดีปีใหม่', 'meaning': 'คำทักทายและอวยพรในเทศกาลปีใหม่'},
    'ส้าดิบ': {'lanna': 'ᩈ᩶ᩣᨯᩥ᩠ᨷ', 'reading': 'ส้าดิบ', 'meaning': 'อาหารพื้นบ้านล้านนา'},
    'ส้าสุก': {'lanna': 'ᩈ᩶ᩣᩈᩩ᩠ᨠ', 'reading': 'ส้าสุก', 'meaning': 'อาหารประเภทส้าที่ปรุงสุก'},
    'อี้': {'lanna': 'ᩋᩦ᩶', 'reading': 'อี้', 'meaning': 'อย่างนี้ / เช่นนี้'},
    'ไนท์': {'lanna': 'ᨶᩱᨴ᩺', 'reading': 'ไนท์', 'meaning': 'ชื่อเฉพาะ (Night)'},
    'กั๊บโต๊ะโละ': {'lanna': 'ᨠᩢ᩠ᨷᨲᩰᩬᩡᩃᩰᩬᩡ', 'reading': 'กั๊บโต๊ะโละ', 'meaning': 'คำอุทานภาษาล้านนาโบราณ'}
}

transform = transforms.Compose([
    transforms.Resize((128, 256)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

def extract_image_bytes(body):
    # Search for JPEG or PNG headers
    png_idx = body.find(b'\x89PNG\r\n\x1a\n')
    if png_idx != -1:
        # Search for PNG end
        iend = body.find(b'IEND', png_idx)
        if iend != -1:
            return body[png_idx:iend + 8]
        return body[png_idx:]
        
    jpg_idx = body.find(b'\xff\xd8\xff')
    if jpg_idx != -1:
        jend = body.rfind(b'\xff\xd9')
        if jend != -1:
            return body[jpg_idx:jend + 2]
        return body[jpg_idx:]
        
    if b'\r\n\r\n' in body:
        parts = body.split(b'\r\n\r\n', 1)
        return parts[1].rsplit(b'\r\n', 1)[0]
        
    return body

class AIRequestHandler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization, apikey')
        self.end_headers()

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)
        
        try:
            img_data = extract_image_bytes(body)
            img = Image.open(io.BytesIO(img_data)).convert('RGB')
            tensor = transform(img).unsqueeze(0).to(DEVICE)
            
            with torch.no_grad():
                out = model(tensor)
                probs = torch.softmax(out, dim=1)[0]
                conf, pred_idx = torch.max(probs, dim=0)
                
            pred_class = classes[pred_idx.item()]
            info = LEXICON.get(pred_class, {'lanna': '', 'reading': pred_class, 'meaning': 'แปลจากอักษรล้านนาด้วย PyTorch Model'})
            
            resp_data = {
                'status': 'success',
                'success': True,
                'data': {
                    'text': pred_class,
                    'translatedText': pred_class,
                    'lanna_text': info.get('lanna', ''),
                    'reading': info.get('reading', pred_class),
                    'meaning': info.get('meaning', ''),
                    'confidence': float(conf.item()),
                    'direction': 'ภาษาล้านนา → ภาษาไทย (PyTorch AI Model)'
                }
            }
        except Exception as e:
            resp_data = {'status': 'error', 'message': str(e)}

        resp_bytes = json.dumps(resp_data, ensure_ascii=False).encode('utf-8')
        
        self.send_response(200)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Content-Length', str(len(resp_bytes)))
        self.end_headers()
        self.wfile.write(resp_bytes)

    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    server = HTTPServer(('127.0.0.1', 5005), AIRequestHandler)
    print('PyTorch AI Vision Server running on http://127.0.0.1:5005 ...')
    server.serve_forever()
