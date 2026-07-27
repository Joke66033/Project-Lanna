"""
Lanna AI Translation Server (D:\\PROJECT_LANNA\\Lanna_API\\ai_engine\\ai_server.py)
Lightweight HTTP Server running on Port 8005.
Serves AI-powered Thai -> Lanna translation, Lanna reading, and word meanings.
"""

import os
import json
import sys
import base64
import tempfile
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler

# Ensure UTF-8 stdout encoding for Windows
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# Import Inference Engine
from inference import LannaAIInference

AI_ENGINE = None
LANNA_OCR_ENGINE = None


def load_local_env():
    env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
    if not os.path.isfile(env_path):
        return
    with open(env_path, 'r', encoding='utf-8') as env_file:
        for raw_line in env_file:
            line = raw_line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            name, value = line.split('=', 1)
            os.environ.setdefault(name.strip(), value.strip().strip('\'"'))


load_local_env()

def get_ai_engine():
    global AI_ENGINE
    if AI_ENGINE is None:
        AI_ENGINE = LannaAIInference()
    return AI_ENGINE


def get_lanna_ocr_engine():
    global LANNA_OCR_ENGINE
    if LANNA_OCR_ENGINE is None:
        from lanna_ocr import LannaOCR

        LANNA_OCR_ENGINE = LannaOCR()
    return LANNA_OCR_ENGINE

class LannaAIServerHandler(BaseHTTPRequestHandler):
    def _send_cors_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.send_header('Content-Type', 'application/json; charset=utf-8')

    def do_OPTIONS(self):
        self.send_response(200)
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self):
        parsed_path = urllib.parse.urlparse(self.path)
        path = parsed_path.path
        query_params = urllib.parse.parse_qs(parsed_path.query)

        if path in ['/translate', '/api/translate']:
            keyword = query_params.get('keyword', [''])[0] or query_params.get('text', [''])[0]
            self._handle_translate(keyword)
        elif path == '/health':
            model_path = os.path.join(
                os.path.dirname(__file__),
                'third_party',
                'OCR-Lanna',
                'Model',
                'OCR-lanna.h5',
            )
            self._send_json(200, {
                "status": "ok",
                "message": "Lanna AI Server is running",
                "services": {
                    "thai_ocr_configured": bool(
                        os.environ.get('TYPHOON_OCR_API_KEY')
                        or os.environ.get('OPENAI_API_KEY')
                    ),
                    "lanna_ocr_model_available": os.path.isfile(model_path),
                    "thai_to_lanna_available": True,
                }
            })
        else:
            self._send_json(404, {"error": "Endpoint not found"})

    def do_POST(self):
        parsed_path = urllib.parse.urlparse(self.path)
        path = parsed_path.path

        if path in ['/translate', '/api/translate']:
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)
            keyword = ""
            try:
                body = json.loads(post_data.decode('utf-8'))
                keyword = body.get('keyword', '') or body.get('text', '') or body.get('thai_word', '')
            except Exception:
                pass
            self._handle_translate(keyword)
        elif path in ['/ocr', '/api/ocr']:
            self._handle_ocr()
        elif path in ['/ocr-lanna', '/api/ocr-lanna']:
            self._handle_lanna_ocr()
        elif path in ['/ocr-auto', '/api/ocr-auto']:
            self._handle_auto_ocr()
        else:
            self._send_json(404, {"error": "Endpoint not found"})

    @staticmethod
    def _decode_image_payload(raw_body: bytes):
        body = json.loads(raw_body.decode('utf-8'))
        image_base64 = body.get('image_base64', '')
        mime_type = body.get('mime_type', 'image/jpeg')
        if ',' in image_base64:
            image_base64 = image_base64.split(',', 1)[1]
        image_bytes = base64.b64decode(image_base64, validate=True)
        if not image_bytes:
            raise ValueError('Empty image')
        if mime_type not in {'image/jpeg', 'image/png', 'image/webp'}:
            raise ValueError('Unsupported image type')
        return image_bytes, mime_type

    @staticmethod
    def _run_typhoon_reader(image_bytes: bytes, mime_type: str) -> str:
        api_key = (
            os.environ.get('TYPHOON_OCR_API_KEY')
            or os.environ.get('OPENAI_API_KEY')
        )
        if not api_key:
            raise RuntimeError('TYPHOON_OCR_API_KEY is not configured')
        suffix = {
            'image/jpeg': '.jpg',
            'image/png': '.png',
            'image/webp': '.webp',
        }[mime_type]
        temp_path = None
        try:
            with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp:
                temp.write(image_bytes)
                temp_path = temp.name
            from typhoon_ocr import ocr_document

            return (ocr_document(
                temp_path,
                model='typhoon-ocr',
                figure_language='Thai',
                task_type='v1.5',
                api_key=api_key,
            ) or '').strip()
        finally:
            if temp_path and os.path.exists(temp_path):
                try:
                    os.remove(temp_path)
                except OSError:
                    pass

    def _handle_auto_ocr(self):
        content_length = int(self.headers.get('Content-Length', 0))
        if content_length <= 0 or content_length > 16 * 1024 * 1024:
            self._send_json(400, {
                "status": "error",
                "message": "Image payload is missing or too large"
            })
            return
        try:
            image_bytes, mime_type = self._decode_image_payload(
                self.rfile.read(content_length)
            )
            from ocr_auto_router import AutoOCRRouter

            try:
                lanna_engine = get_lanna_ocr_engine()
            except Exception as error:
                print(
                    "Lanna OCR unavailable; continuing with Thai OCR: "
                    f"{type(error).__name__}: {error}"
                )
                lanna_engine = None

            router = AutoOCRRouter(
                lanna_engine=lanna_engine,
                thai_reader=self._run_typhoon_reader,
                thai_converter=get_ai_engine().convert_thai_to_lanna,
            )
            result = router.route(image_bytes, mime_type)
            self._send_json(200, {
                "status": "success",
                "result": result,
            })
        except (ValueError, json.JSONDecodeError):
            self._send_json(400, {
                "status": "error",
                "message": "ไม่พบข้อความที่รองรับในภาพ"
            })
        except RuntimeError as error:
            print(f"Auto OCR configuration error: {error}")
            self._send_json(503, {
                "status": "error",
                "message": "บริการ OCR ยังไม่พร้อมใช้งาน"
            })
        except Exception as error:
            print(f"Auto OCR error: {type(error).__name__}: {error}")
            self._send_json(502, {
                "status": "error",
                "message": "ไม่สามารถประมวลผลภาพนี้ได้"
            })

    def _handle_lanna_ocr(self):
        content_length = int(self.headers.get('Content-Length', 0))
        if content_length <= 0 or content_length > 16 * 1024 * 1024:
            self._send_json(400, {
                "status": "error",
                "message": "Image payload is missing or too large"
            })
            return

        try:
            body = json.loads(self.rfile.read(content_length).decode('utf-8'))
            image_base64 = body.get('image_base64', '')
            if ',' in image_base64:
                image_base64 = image_base64.split(',', 1)[1]
            image_bytes = base64.b64decode(image_base64, validate=True)
            if not image_bytes:
                raise ValueError('Empty image')

            import cv2
            import numpy as np

            encoded = np.frombuffer(image_bytes, dtype=np.uint8)
            image = cv2.imdecode(encoded, cv2.IMREAD_COLOR)
            if image is None:
                raise ValueError('Unsupported image')

            result = get_lanna_ocr_engine().recognize(image)
            self._send_json(200, {
                "status": "success",
                "experimental": True,
                "result": result.to_dict(),
            })
        except (ValueError, json.JSONDecodeError):
            self._send_json(400, {
                "status": "error",
                "message": "Image does not contain readable Lanna components"
            })
        except Exception as error:
            print(f"Lanna OCR error: {type(error).__name__}: {error}")
            self._send_json(500, {
                "status": "error",
                "message": "Experimental Lanna OCR could not process this image"
            })

    def _handle_ocr(self):
        content_length = int(self.headers.get('Content-Length', 0))
        if content_length <= 0 or content_length > 16 * 1024 * 1024:
            self._send_json(400, {
                "status": "error",
                "message": "Image payload is missing or too large"
            })
            return

        temp_path = None
        try:
            body = json.loads(self.rfile.read(content_length).decode('utf-8'))
            image_base64 = body.get('image_base64', '')
            mime_type = body.get('mime_type', 'image/jpeg')
            if ',' in image_base64:
                image_base64 = image_base64.split(',', 1)[1]
            image_bytes = base64.b64decode(image_base64, validate=True)
            if not image_bytes:
                raise ValueError('Empty image')

            suffixes = {
                'image/jpeg': '.jpg',
                'image/png': '.png',
                'image/webp': '.webp',
            }
            suffix = suffixes.get(mime_type)
            if suffix is None:
                self._send_json(415, {
                    "status": "error",
                    "message": "Only JPG, PNG and WEBP images are supported"
                })
                return

            api_key = (
                os.environ.get('TYPHOON_OCR_API_KEY')
                or os.environ.get('OPENAI_API_KEY')
            )
            if not api_key:
                self._send_json(503, {
                    "status": "error",
                    "message": "TYPHOON_OCR_API_KEY is not configured"
                })
                return

            with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp:
                temp.write(image_bytes)
                temp_path = temp.name

            from typhoon_ocr import ocr_document

            text = ocr_document(
                temp_path,
                model='typhoon-ocr',
                figure_language='Thai',
                task_type='v1.5',
                api_key=api_key,
            )
            self._send_json(200, {
                "status": "success",
                "text": (text or '').strip(),
                "provider": "typhoon-ocr",
                "model": "typhoon-ocr",
            })
        except (ValueError, json.JSONDecodeError):
            self._send_json(400, {
                "status": "error",
                "message": "Invalid image payload"
            })
        except Exception as error:
            print(f"Typhoon OCR error: {type(error).__name__}: {error}")
            self._send_json(502, {
                "status": "error",
                "message": "Typhoon OCR could not process this image"
            })
        finally:
            if temp_path and os.path.exists(temp_path):
                try:
                    os.remove(temp_path)
                except OSError:
                    pass

    def _handle_translate(self, keyword: str):
        keyword = keyword.strip()
        if not keyword:
            self._send_json(400, {"status": "error", "message": "Missing keyword parameter"})
            return

        engine = get_ai_engine()
        res = engine.convert_thai_to_lanna(keyword)

        # Structure full output with reading and meaning
        lanna_word = res["lanna_script"]
        details = res.get("details", [])
        
        reading = f"[{keyword}]"
        meaning = "ถอดอักขระล้านนาตามหลักอักขรวิทยา"

        if keyword in engine.dict_lookup:
            entry = engine.dict_lookup[keyword]
            reading = entry.get("pronunciation", reading)
            meaning = entry.get("definition", meaning)
        elif details:
            meaning = details[0]

        response_payload = {
            "status": "success",
            "thai_word": keyword,
            "lanna_word": lanna_word,
            "reading": reading,
            "meaning": meaning,
            "is_valid_unicode": res.get("is_valid_lanna_unicode", True),
            "details": details
        }

        self._send_json(200, response_payload)

    def _send_json(self, status_code: int, data: dict):
        self.send_response(status_code)
        self._send_cors_headers()
        self.end_headers()
        response_json = json.dumps(data, ensure_ascii=False)
        self.wfile.write(response_json.encode('utf-8'))

def run_server(port: int | None = None):
    if port is None:
        # Render.com sets PORT; fall back to 8005 for local development.
        port = int(os.environ.get('PORT', 8005))
    server_address = ('', port)
    httpd = HTTPServer(server_address, LannaAIServerHandler)
    print(f"Lanna AI Translation Server running on http://0.0.0.0:{port}")
    httpd.serve_forever()

if __name__ == '__main__':
    run_server()
