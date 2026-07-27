# Deploying camera OCR

The Flutter app uses:

`POST /endpoints/auto_ocr_api.php`

That PHP endpoint forwards the image only to the private Python service at
`127.0.0.1:8005/api/ocr-auto`.

## Server requirements

- PHP with cURL and fileinfo extensions
- Python 3.10 or newer
- Enough memory for TensorFlow when experimental Lanna OCR is enabled
- Outbound HTTPS access to `api.opentyphoon.ai`
- A private `.env` file containing `TYPHOON_OCR_API_KEY`

The API key must never be placed in Flutter source, committed to Git, or
returned by an endpoint.

## Install

From the project directory on the server:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r Lanna_API/ai_engine/requirements.txt
```

Copy `deploy/systemd/lanna-ai.service.example`, replace every `CHANGE_ME`,
install it as `/etc/systemd/system/lanna-ai.service`, then run:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now lanna-ai
sudo systemctl status lanna-ai
```

Do not expose port `8005` publicly. PHP communicates with it through localhost.

## Health check

Open the service locally on the server:

```text
http://127.0.0.1:8005/health
```

The response reports:

- whether the Typhoon key is configured;
- whether the experimental OCR-Lanna model is present;
- whether Thai-to-Lanna conversion is available.

Thai image OCR continues to work when the experimental Lanna model is missing.

## Public endpoint smoke test

Upload a JPG, PNG, or WEBP image as multipart field `file`:

```text
https://YOUR_DOMAIN/endpoints/auto_ocr_api.php
```

Expected `data.direction` values:

- `thai_to_lanna`
- `lanna_to_thai`

The Lanna-to-Thai route remains experimental and is selected only when model
confidence is at least `0.65`.

## Hosting limitation

Traditional PHP-only shared hosting cannot run this Python/TensorFlow service.
In that case, run the Python service on a VPS or container host and secure the
PHP-to-Python connection. Do not point the Flutter app directly at port 8005.

The upstream OCR-Lanna repository has no supplied license. Obtain permission
from its owner before distributing its model or dataset on a public server.

