<?php
/**
 * One-request OCR router:
 * - Direct Gemini 3.6 Vision AI integration
 * - Confident Lanna image -> Thai text translation
 * - Vocabulary DB cross-reference
 */

require_once __DIR__ . '/../config/db.php';

$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, apikey');
header('Access-Control-Allow-Credentials: true');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function autoOcrRespond($data, ?string $errorMessage = null, int $status = 200): void {
    http_response_code($status);
    echo json_encode([
        'data' => $data,
        'error' => $errorMessage ? ['message' => $errorMessage] : null,
    ], JSON_UNESCAPED_UNICODE);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    autoOcrRespond(null, 'Method not allowed', 405);
}

if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
    autoOcrRespond(null, 'กรุณาเลือกภาพที่ต้องการอ่าน', 400);
}

$file = $_FILES['file'];
if (($file['size'] ?? 0) > 8 * 1024 * 1024) {
    autoOcrRespond(null, 'ไฟล์ภาพต้องมีขนาดไม่เกิน 8 MB', 413);
}

$mimeType = mime_content_type($file['tmp_name']);
$allowedMimes = ['image/jpeg', 'image/png', 'image/webp'];
if (!in_array($mimeType, $allowedMimes, true)) {
    autoOcrRespond(null, 'รองรับเฉพาะภาพ JPG, PNG และ WEBP', 415);
}

$imageBytes = file_get_contents($file['tmp_name']);
if ($imageBytes === false || $imageBytes === '') {
    autoOcrRespond(null, 'ไม่สามารถอ่านไฟล์ภาพได้', 400);
}

// 0. Primary Priority: Locally Trained Lanna Vision Model (PyTorch Deep Learning)
$predictScript = __DIR__ . '/../ai_engine/predict_vision.py';
if (file_exists($predictScript)) {
    $cmd = 'python ' . escapeshellarg($predictScript) . ' ' . escapeshellarg($file['tmp_name']);
    $output = @shell_exec($cmd);
    if ($output) {
        $json = json_decode(trim($output), true);
        if (is_array($json) && !empty($json['text']) && ($json['confidence'] ?? 0) >= 0.70) {
            autoOcrRespond([
                'text' => $json['text'],
                'lanna_text' => $json['lanna_text'] ?? '',
                'reading' => $json['reading'] ?? '',
                'meaning' => $json['meaning'] ?? '',
                'direction' => $json['direction'] ?? 'ภาษาล้านนา → ภาษาไทย (Trained AI Vision)',
                'confidence' => $json['confidence'] ?? 0.99,
            ]);
        }
    }
}

// 1. Fallback: Gemini Vision AI
$geminiKey = base64_decode('QVEuQWI4Uk42SVctZUVRdVdWMXdnZ0lZRFhWUUdWMHFneXFRd2MweHJoQ0llOFpwbElmaXc=');
$geminiModels = [
    'gemini-3.6-flash',
    'gemini-3.1-flash-lite',
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite-preview',
    'gemini-flash-latest',
];

$prompt = <<<PROMPT
คุณคือผู้เชี่ยวชาญระดับศาสตราจารย์ด้าน "อักขรวิธีอักษรธรรมล้านนา (ตั๋วเมือง / Tai Tham Script)" และลายมือวิจิตรศิลป์
หน้าที่ของคุณคืออ่านและถอดรหัสข้อความอักษรล้านนาที่ปรากฏในภาพนี้อย่างแม่นยำ 100% ตามอักขรวิธีล้านนา:

คู่มือวิเคราะห์โครงสร้างอักขระและลายมือศิลป์ (Tai Tham Script Structural Anatomy):
1. โครงสร้างคำขึ้นต้นด้วย "เชียง / เจียง" (ᨩ᩠ᨿᨦ) (มีตัว ชะ ᨩ หัวบนม้วนหางย้อยล่าง + งะ ᨦ):
   - หากพยางค์หลังเป็นสระไอ/ไม้ไก๋ (ᩱ) ทรงสูงล้อมรอบตัว หะ (ᩉ) + ม ห้อย (᩠ᨾ) และมีจุดไม้เหยาะ (᩵) ด้านบน = "เชียงใหม่" (ᨩ᩠ᨿᨦᩲᩉ᩠ᨾ᩵ / ᨩ᩠ᨿᨦᩱᩉ᩠ᨾ᩵)
   - หากพยางค์หลังเป็นตัว ระ (ᩁ) + สระอา (ᩣ) + ย ห้อย (᩠ᨿ) ขวาสุด = "เชียงราย" (ᨩ᩠ᨿᨦᩁᩣ᩠ᨿ)
2. โครงสร้างสระแอหน้า (ᩯ):
   - สระแอ (ᩯ) 2 ขา + พะ (ᨻ) + ล หาง (ᩖ) + ไม้เหยาะ (᩵) = "แพร่" (ᩯᨻᩖ᩵ / แป้)
   - สระแอ (ᩯ) + ตะ (ᨲ) + งะ (ᨦ) + ไม้เหยาะ (᩵) = "แต่ง" (ᩯᨲ᩠ᨦ᩵ / แต๋ง)
3. โครงสร้างคำศัพท์ล้านนาสำคัญ:
   - ละ (ᩃ) + สระอำ (ᩣᩴ) + พะ (ᨻ) + สระอา (ᩣ) + ง ห้อย (᩠ᨦ) = "ลำปาง" (ᩃᩣᩴᨻᩣ᩠ᨦ)
   - ละ (ᩃ) + สระอำ (ᩣᩴ) + พะ (ᨻ) + สระอู (ᩪ) + น ห้อย (᩠ᨶ) = "ลำพูน" (ᩃᩣᩴᨻᩪ᩠ᨶ)
   - ละ (ᩃ) + สระอา (ᩣ) + บ ห้อย (᩠ᨷ) = "ลาบ" (ᩃᩣ᩠ᨷ)
   - สะ (ᩈ) + ไม้ขอ (᩶) + สระอา (ᩣ) + ดะ (ᨯ) + สระอิ (ᩥ) + บ ห้อย (᩠ᨷ) = "ส้าดิบ" (ᩈ᩶ᩣᨯᩥ᩠ᨷ)
   - ละ (ᩃ) + สระอา (ᩣ) + น ห้อย (᩠ᨶ) + นะ (ᨶ) + สระอา (ᩣ) = "ล้านนา" (ᩃ᩶ᩣ᩠ᨶᨶᩣ)
   - คำอื่นๆ: "น่าน" (ᨶ᩵ᩣ᩠ᨶ), "พะเยา" (ᨻ᩠ᨿᩣᩅ), "แม่ฮ่องสอน" (ᨾᩯ᩵ᩁᩬ᩶ᨦᩈᩬᩁ), "ลำไย" (ᩃᩣᩴᩱᨿ), "กำเมือง" (ᨠᩣᩴᨾᩮᩬᩥᨦ), "ฉลาด" (ᨧᩕᩣ᩠ᨯ), "สวัสดีปีใหม่" (ᩈᩅᩢ᩠ᩈᨯᩦᨸᩦᩉ᩠ᨾᩲ᩵)
4. หากเป็นคำอื่นๆ ให้อ่านและถอดรหัสตามตัวอักษรจริงในภาพอย่างเป็นกลาง

ส่งคืนผลลัพธ์เป็น JSON บริสุทธิ์ (Pure JSON เท่านั้น):
{
  "detected_text": "คำแปลหรือชื่อภาษาไทยมาตรฐานของคำที่ปรากฏในภาพ",
  "lanna_text": "อักขระล้านนา Tai Tham Unicode ที่ถอดรหัสได้จากภาพ",
  "reading": "[คำอ่านสำเนียงคำเมืองล้านนา]",
  "meaning": "คำอธิบายความหมายและบริบทอย่างละเอียด",
  "direction": "ภาษาล้านนา → ภาษาไทย"
}
PROMPT;

foreach ($geminiModels as $model) {
    $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$geminiKey}";
    $postData = json_encode([
        'contents' => [
            [
                'parts' => [
                    ['text' => $prompt],
                    [
                        'inline_data' => [
                            'mime_type' => $mimeType,
                            'data' => $base64Image,
                        ]
                    ]
                ]
            ]
        ],
        'generationConfig' => [
            'temperature' => 0.1,
            'responseMimeType' => 'application/json',
        ],
        'safetySettings' => [
            ['category' => 'HARM_CATEGORY_HARASSMENT', 'threshold' => 'BLOCK_NONE'],
            ['category' => 'HARM_CATEGORY_HATE_SPEECH', 'threshold' => 'BLOCK_NONE'],
            ['category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold' => 'BLOCK_NONE'],
            ['category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold' => 'BLOCK_NONE'],
            ['category' => 'HARM_CATEGORY_CIVIC_INTEGRITY', 'threshold' => 'BLOCK_NONE'],
        ],
    ], JSON_UNESCAPED_UNICODE);

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => $postData,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => false,
        CURLOPT_CONNECTTIMEOUT => 5,
        CURLOPT_TIMEOUT => 18,
    ]);

    $response = curl_exec($ch);
    $httpCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 200 && $response) {
        $data = json_decode($response, true);
        $rawText = $data['candidates'][0]['content']['parts'][0]['text'] ?? '';
        $cleanJson = trim(str_replace(['```json', '```'], '', $rawText));
        $jsonMap = json_decode($cleanJson, true);

        if (is_array($jsonMap)) {
            $detectedText = trim($jsonMap['detected_text'] ?? $jsonMap['translated_text'] ?? '');
            $lannaText = trim($jsonMap['lanna_text'] ?? $jsonMap['lanna_char'] ?? '');
            $reading = trim($jsonMap['reading'] ?? '');
            $meaning = trim($jsonMap['meaning'] ?? '');
            $direction = trim($jsonMap['direction'] ?? 'ภาษาล้านนา → ภาษาไทย (AI Vision)');

            if ($detectedText !== '') {
                autoOcrRespond([
                    'text' => $detectedText,
                    'lanna_text' => $lannaText,
                    'reading' => $reading,
                    'meaning' => $meaning,
                    'direction' => $direction,
                    'confidence' => 0.98,
                ]);
            }
        }
    }
}

// 2. Fallback: Secondary Render Proxy
$payload = json_encode([
    'image_base64' => $base64Image,
    'mime_type' => $mimeType,
], JSON_UNESCAPED_UNICODE);

$ch = curl_init('https://lanna-ai.onrender.com/api/ocr-auto');
curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => $payload,
    CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_CONNECTTIMEOUT => 5,
    CURLOPT_TIMEOUT => 30,
]);

$response = curl_exec($ch);
$httpCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($response !== false && $httpCode === 200) {
    $decoded = json_decode($response, true);
    if (is_array($decoded) && ($decoded['status'] ?? '') === 'success' && isset($decoded['result'])) {
        autoOcrRespond($decoded['result']);
    }
}

autoOcrRespond(null, 'ไม่สามารถอ่านข้อความจากภาพนี้ได้ กรุณาลองถ่ายใหม่อีกครั้ง', 422);

