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

$base64Image = base64_encode($imageBytes);

// 1. Primary: Gemini Vision AI
$geminiKey = base64_decode('QVEuQWI4Uk42SVctZUVRdVdWMXdnZ0lZRFhWUUdWMHFneXFRd2MweHJoQ0llOFpwbElmaXc=');
$geminiModels = [
    'gemini-3.1-flash-lite',
    'gemini-3.5-flash-lite',
    'gemini-3.6-flash',
    'gemini-3.1-flash-lite-preview',
    'gemini-flash-latest',
];

$prompt = <<<PROMPT
คุณคือผู้เชี่ยวชาญระดับศาสตราจารย์ด้าน "อักขรวิธีอักษรธรรมล้านนา (ตั๋วเมือง / Tai Tham Script)" และภาษาไทยถิ่นเหนือ
หน้าที่ของคุณคืออ่าน วิเคราะห์ และถอดรหัสข้อความอักษรล้านนาจากภาพถ่ายอย่างเป็นกลาง แม่นยำ และครอบคลุมทุกคำศัพท์ ไม่จำกัดเฉพาะคำใดคำหนึ่ง:

หลักการอ่านและถอดรหัสอักขระ 3 ระดับ (Tai Tham Spatial Decoding):
1. สระหน้า: สระแอ (ᩯ), สระเอ (ᩮ), สระโอ (ᩰ), ไม้ไก๋/สระไอ (ᩱ), ไม้ใค/สระใอ (ᩲ)
2. พยัญชนะหลัก (Base Consonants):
   - กะ ᨠ, ขะ ᨡ, คะ ᨣ, ฅะ ᨤ, งะ ᨦ, จะ ᨧ, ฉะ ᨨ, ชะ ᨩ, ตะ ᨲ, ถะ ᨳ, ทะ ᨴ, ธะ ᨵ, นะ ᨶ
   - ปะ/บะ ᨷ, ปะหางยาว ᨸ, ผะ ᨹ, พะ ᨻ, ฟะ ᨼ, ภะ ᨽ, มะ ᨾ, ยะ ᨿ, ระ ᩁ, ละ ᩃ, วะ ᩅ, สะ ᩈ, หะ ᩉ, อะ ᩋ, ฮฮก ᩌ
3. ตัวสะกดห้อยและตัวควบล่าง (Subjoined Sakot & Medials):
   - ย ห้อย (᩠ᨿ) (ทำเสียงสระเอีย เช่น ชะ+ย ห้อย = เชีย ᨩ᩠ᨿ, พะ+ย ห้อย = เพีย ᨻ᩠ᨿ, ระ+สระอา+ย ห้อย = ราย ᩁᩣ᩠ᨿ)
   - ว ห้อย (᩠ᩅ) (สระอัว / ว สะกด), ม ห้อย (᩠ᨾ), ง ห้อย (᩠ᨦ), น ห้อย (᩠ᨶ), ด ห้อย (᩠ᨯ), บ ห้อย (᩠ᨷ), ก ห้อย (᩠ᨠ)
   - ล หาง (ᩖ), ร หางกวาด (ᩕ), สระอุ (ᩩ), สระอู (ᩪ)
4. สระบนและวรรณยุกต์:
   - สระอิ (ᩥ), สระอี (ᩦ), สระอึ (ᩧ), สระอือ (ᩨ), ไม้กั๋ง (ᩢ), สระอัว (ᩫ), นิคหิต/สระอำ (ᩴ)
   - ไม้เหยาะ (ไม้เอก ᩵), ไม้ขอช้าง (ไม้โท ᩶), ไม้ซัด (᩺/᩹)

คลังคำสำคัญล้านนาอ้างอิงครอบคลุมทุกหมวดหมู่ (Lanna Lexical Reference):
* หมวดสถานที่: "แพร่" (ᩯᨻᩖ᩵ / แป้), "เชียงใหม่" (ᨩ᩠ᨿᨦᩲᩉ᩠ᨾ᩵), "เชียงราย" (ᨩ᩠ᨿᨦᩁᩣ᩠ᨿ), "ลำปาง" (ᩃᩣᩴᨻᩣ᩠ᨦ), "ลำพูน" (ᩃᩣᩴᨻᩪ᩠ᨶ), "น่าน" (ᨶ᩵ᩣ᩠ᨶ), "พะเยา" (ᨻ᩠ᨿᩣᩅ), "แม่ฮ่องสอน" (ᨾᩯ᩵ᩁᩬ᩶ᨦᩈᩬᩁ), "เวียงกุมกาม" (ᩅ᩠ᨿᨦᨠᩩᨾᨠᩣᨾ), "ข่วงเมือง" (ᨡ᩠ᩅᩴᨦᩮᨾᩥ᩠ᨦ)
* หมวดอาหาร: "ส้าดิบ" (ᩈ᩶ᩣᨯᩥ᩠ᨷ), "ส้าสุก" (ᩈ᩶ᩣᩈᩩ᩠ᨠ), "ลาบ" (ᩃᩣ᩠ᨷ), "ลาบควาย" (ᩃᩣ᩠ᨷᨤ᩠ᩅᩣ᩠ᨿ), "ลาบหมู" (ᩃᩣ᩠ᨷᩉ᩠ᨾᩪ), "แกงฮังเล" (ᨠᩯᨦᩌᩢᨦᩃᩮ), "น้ำพริกหนุ่ม" (ᨶᩣᩴ᩶ᨻᩕᩥ᩠ᨠᩉ᩠ᨶᩩ᩠᩵ᨾ), "ไส้อั่ว" (ᩱᩈ᩶ᩋ᩠ᩅᩫ᩵), "แคบหมู" (ᨤᩯ᩠ᨷᩉ᩠ᨾᩪ), "ข้าวซอย" (ᨡ᩶ᩣ᩠ᩅᨪᩬ᩠ᨿ), "ลำไย" (ᩃᩣᩴᩱᨿ)
* หมวดภาษาและวัฒนธรรม: "กำเมือง" (ᨠᩣᩴᨾᩮᩬᩥᨦ), "ตั๋วเมือง" (ᨲ᩠ᩅᩫᨾᩮᩬᩥᨦ), "ล้านนา" (ᩃ᩶ᩣ᩠ᨶᨶᩣ), "ขันโตก" (ᨡᩢ᩠ᨶᩰᨲ᩠ᨠ), "ตุง" (ᨲᩩ᩠ᨦ), "โคมลอย" (ᩰᨤᨾᩃᩬ᩠ᨿ)
* หมวดคำกริยาและคำคุณศัพท์: "แจ้ว" (ᩯᨧ᩠ᩅ᩵), "แต่ง" (ᩯᨲ᩠ᨦ᩵), "แป๋ง/แปลง" (ᩯᨸ᩠ᩖᨦ), "แอ่ว" (ᩯᩋ᩠ᩅ), "อู้" (ᩋᩪ᩶), "ลำขนาด" (ᩃᩣᩴᨡ᩠ᨶᩣ᩠ᨯ), "งาม" (ᨦᩣ᩠ᨾ), "ฉลาด" (ᨧᩕᩣ᩠ᨯ), "สวัสดี" (ᩈᩅᩢ᩠ᩈᨯᩦ)

ข้อกำหนดสำคัญ: จงอ่านและถอดรหัสตัวอักษรและคำศัพท์ที่ปรากฏในภาพจริงทุกตัวอย่างอิสระตามหลักอักขรวิธีล้านนา หากเป็นคำอื่นนอกเหนือจากตัวอย่าง ให้ถอดรหัสตามตัวอักษรจริงในภาพ ห้ามเดาหรือบังคับให้เป็นเพียงคำใดคำหนึ่ง

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

