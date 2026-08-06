# Typhoon OCR setup

The Flutter camera sends images to:

`Lanna_API/endpoints/typhoon_ocr_api.php`

The PHP endpoint securely proxies the image to the Python AI server on port
`8005`. The API key is used only by the Python server and is never returned to
the Flutter app.

## 1. Install the Python dependencies

From `Lanna_API`:

```powershell
python -m pip install -r ai_engine/requirements.txt
```

## 2. Configure the API key

Add this entry to `Lanna_API/.env`:

```dotenv
TYPHOON_OCR_API_KEY=your_api_key_here
```

Do not commit `.env` or place this key in Flutter source code.

## 3. Start the services

Run:

```powershell
..\start_api_server.bat
```

The script starts the Python AI server on port `8005` and the PHP API on port
`8000`.

## 4. Verify the AI server

Open:

`http://localhost:8005/health`

The response should contain `"status": "ok"`.

If Typhoon OCR is unavailable on Android, the app automatically falls back to
the existing on-device Thai OCR. Web requires the Typhoon endpoint.
