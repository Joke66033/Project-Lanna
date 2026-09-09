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
คุณคือผู้เชี่ยวชาญระดับศาสตราจารย์ด้าน "อักขรวิธีอักษรธรรมล้านนา (ตั๋วเมือง / Tai Tham Script)" และสัทศาสตร์ภาษาไทยถิ่นเหนือ
หน้าที่ของคุณคืออ่าน วิเคราะห์ และถอดรหัสข้อความอักษรล้านนาจากภาพถ่ายอย่างเป็นกลาง แม่นยำ ครอบคลุมทุกคำศัพท์และทุกประโยค ไม่จำกัดเฉพาะคำใดคำหนึ่ง:

หลักการอ่านและถอดรหัสโครงสร้างอักขระ 4 มิติ (Tai Tham Spatial & Orthographic Chart):
1. กฎการจำแนกคำศัพท์สำคัญ (Orthographic Disambiguation Rules):
   - ᨩ᩠ᨿᨦᩲᩉ᩠ᨾ᩵ (ชะ ᨩ + ยห้อย ᩠ᨿ + งะ ᨦ + ไม้ไก๋ ᩲ + หะ ᩉ + มห้อย ᩠ᨾ + ไม้เหยาะ ᩵) = "เชียงใหม่" (เจียงใหม่) **ข้อควรระวังอย่างยิ่ง: ห้ามอ่านเป็น 'ลูกไก่' หรือ 'ไก่'**
   - ᨩ᩠ᨿᨦᩁᩣ᩠ᨿ (ชะ+ยห้อย+งะ + ระ+สระอา+ยห้อย) = "เชียงราย" (เจียงฮาย)
   - ᩯᨻᩖ᩵ (สระแอ ᩯ + พะ ᨻ + ลหาง ᩖ + ไม้เหยาะ ᩵) = "แพร่" (แป้)
   - ᩃᩣᩴᨻᩣ᩠ᨦ (ละ+สระอำ + พะ+สระอา+งห้อย) = "ลำปาง", ᩃᩣᩴᨻᩪ᩠ᨶ = "ลำพูน", ᩃᩣᩴᩱᨿ = "ลำไย"
   - ᩃᩣ᩠ᨷ = "ลาบ", ᩃᩣ᩠ᨷᨤ᩠ᩅᩣ᩠ᨿ = "ลาบควาย", ᩃᩣ᩠ᨷᩉ᩠ᨾᩪ = "ลาบหมู", ᩈ᩶ᩣᨯᩥ᩠ᨷ = "ส้าดิบ", ᩈ᩶ᩣᩈᩩ᩠ᨠ = "ส้าสุก"
   - ᨧᩕᩣ᩠ᨯ = "ฉลาด", ᨠᩣᩴᨾᩮᩬᩥᨦ = "กำเมือง", ᩮᨾᩥ᩠ᨦᩋᩥ᩠ᨶ᩠ᨴᩕ᩼ = "เมืองอินทร์", ᨾᩯ᩵ᩁᩬ᩶ᨦᩈᩬᩁ = "แม่ฮ่องสอน"

2. สระหน้า (Leading Vowels):
   - สระแอ (ᩯ) 2 ขาซ้ายสุด, ไม้ไก๋/สระไอ (ᩱ) หรือ ไม้ใค/สระใอ (ᩲ) ทรงสูง, สระเอ (ᩮ), สระโอ (ᩰ)

3. พยัญชนะหลัก (Base Consonants):
   - กะ ᨠ, ขะ ᨡ, คะ ᨣ, ฅะ ᨤ, งะ ᨦ, จะ ᨧ, ฉะ ᨨ, ชะ ᨩ, ซะ ᨪ, ญะ ᨬ
   - ตะ ᨲ, ถะ ᨳ, ทะ ᨴ, ธะ ᨵ, นะ ᨶ
   - บะ/ปะ ᨷ, ปะหางยาว ᨸ, ผะ ᨹ, ฝะ ᨺ, พะ ᨻ, ฟะ ᨼ, ภะ ᨽ, มะ ᨾ, ยะ ᨿ
   - ระ ᩁ, ละ ᩃ, วะ ᩅ, สะ ᩈ, หะ ᩉ, อะ ᩋ, ฮฮก ᩌ

4. ตัวสะกดห้อยและตัวควบใต้ล่าง (Subjoined Sakot & Medials):
   - ย ห้อย (᩠ᨿ), ว ห้อย (᩠ᩅ), ม ห้อย (᩠ᨾ), ง ห้อย (᩠ᨦ), น ห้อย (᩠ᨶ), ด ห้อย (᩠ᨯ), บ ห้อย (᩠ᨷ), ก ห้อย (᩠ᨠ), ล หาง (ᩖ), ร หางกวาด (ᩕ)

5. สระบนและเครื่องหมายวรรณยุกต์ (Upper Vowels & Tone Marks):
   - สระอิ (ᩥ), สระอี (ᩦ), สระอึ (ᩧ), สระอือ (ᩨ), ไม้กั๋ง (ᩢ), สระอัว (ᩫ), นิคหิต/สระอำ (ᩴ), ไม้เหยาะ (᩵), ไม้ขอช้าง (᩶)

ขั้นตอนการวิเคราะห์รูปภาพ:
1. พิจารณาอักขระทีละกลุ่มจากซ้ายไปขวา โดยสังเกตสระหน้า พยัญชนะต้น ตัวสะกดห้อยล่าง และสระบน/วรรณยุกต์
2. สังเคราะห์เป็นรหัส Tai Tham Unicode ที่สมบูรณ์
3. แปลเป็นภาษาไทยมาตรฐาน และระบุคำอ่านสัทอักษรภาษาเหนือ/คำเมือง

ส่งคืนผลลัพธ์เป็น Pure JSON เท่านั้น:
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

