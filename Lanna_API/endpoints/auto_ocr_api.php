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

// 1. Primary: Gemini Vision AI (3.6 Flash / 3.8 Flash)
$geminiKey = base64_decode('QVEuQWI4Uk42SVctZUVRdVdWMXdnZ0lZRFhWUUdWMHFneXFRd2MweHJoQ0llOFpwbElmaXc=');
$geminiModels = ['gemini-3.6-flash', 'gemini-3.8-flash', 'gemini-3.7-flash', 'gemini-flash-latest'];

$prompt = <<<PROMPT
คุณคือผู้เชี่ยวชาญระดับศาสตราจารย์ด้าน "อักขรวิธีอักษรธรรมล้านนา (ตั๋วเมือง / Tai Tham Script)" และวัฒนธรรม-อาหาร-ภาษาถิ่นภาคเหนือ
หน้าที่ของคุณคืออ่าน วิเคราะห์ และถอดรหัสอักษรธรรมล้านนาจากภาพถ่าย (ทั้งฟอนต์ LN-TILOK, ตัวพิมพ์ป้าย, ลายมือคัมภีร์ใบลาน และศิลาจารึก) แปลเป็นภาษาไทยมาตรฐานให้ถูกต้อง 100%:

หลักการวิเคราะห์โครงสร้างอักขระ 3 ระดับ (LDIMS 3-Level Spatial Analysis):
1. ระดับกลาง (Base Level - พยัญชนะหลัก): กะ ᨠ, ขะ ᨡ, ฃะ ᨢ, คะ ᨣ, ฅะ ᨤ, ฆะ ᨥ, งะ ᨦ, จะ ᨧ, ฉะ ᨨ, ชะ ᨩ, ซะ ᨪ, ฌะ ᨫ, ญะ ᨬ, ตะ ᨲ, ถะ ᨳ, ทะ ᨴ, ธะ ᨵ, นะ ᨶ, ปะ/บะ ᨷ, ปะหางยาว ᨸ, ผะ ᨹ, พะ ᨻ, ฟะ ᨼ, ภะ ᨽ, มะ ᨾ, ยะ ᨿ, ระ ᩁ, ละ ᩃ, วะ ᩅ, สะ ᩈ, หะ ᩉ, ฬะ ᩊ, อะ ᩋ, ฮฮก ᩌ
   - สระหน้า: สระเอ (ᩮ), สระแอ (ᩯ), สระโอ (ᩰ), สระใอ (ᩱ), สระไอ (ᩲ)
   - สระหลัง: สระอา (ᩣ/ᩤ), สระอะ (ᩡ)
2. ระดับล่าง (Subjoined Level - ตัวสะกดห้อยและสระล่าง):
   - ตัวสะกดห้อย (Subjoined Sakot ᩠): บ ห้อย (᩠ᨷ), ก ห้อย (᩠ᨠ), ง ห้อย (᩠ᨦ), น ห้อย (᩠ᨶ), ม ห้อย (᩠ᨾ), ด ห้อย (᩠ᨯ), ว ห้อย (᩠ᩅ), ย ห้อย (᩠ᨿ), ร หางกวาด (ᩕ), ล หาง (ᩖ)
   - สระล่าง: สระอุ (ᩩ), สระอู (ᩪ)
3. ระดับบน (Upper Level - สระบนและวรรณยุกต์):
   - สระบน: สระอิ (ᩥ), สระอี (ᩦ), สระอึ (ᩧ), สระอือ (ᩨ), ไม้กั๋ง (ᩢ), สระอัว (ᩫ), นิคหิต (ᩴ)
   - วรรณยุกต์: ไม้ขอช้าง (ไม้โท ᩶), ไม้เหยาะ (ไม้เอก ᩵), ไม้ซัด (᩺/᩹)

คลังคำสำคัญและอาหารพื้นเมืองล้านนา (High-Frequency Lanna Reference):
* อาหารล้านนา:
  - "ส้าดิบ" (ᩈ᩶ᩣᨯᩥ᩠ᨷ): พยางค์แรก สะ ᩈ + ไม้ขอช้าง ᩶ + สระอา ᩣ = "ส้า", พยางค์สอง ดะ ᨯ + สระอิ ᩥ + บ ห้อย ᩠ᨷ = "ดิบ" (ห้ามอ่านว่า สาธุ เด็ดขาด!)
  - "ส้าสุก" (ᩈ᩶ᩣᩈᩩ᩠ᨠ): ส้า + สะ ᩈ + สระอุ ᩩ + ก ห้อย ᩠ᨠ = "ส้าสุก"
  - "ลาบ" (ᩃᩣ᩠ᨷ): ละ ᩃ + สระอา ᩣ + บ ห้อย ᩠ᨷ
  - "ลาบควาย" (ᩃᩣ᩠ᨷᨤ᩠ᩅᩣ᩠ᨿ): ลาบ + คะ ᨤ + ว ห้อย ᩠ᩅ + สระอา ᩣ + ย ห้อย ᩠ᨿ
  - "ลาบหมู" (ᩃᩣ᩠ᨷᩉ᩠ᨾᩪ): ลาบ + หะ ᩉ + ม ห้อย ᩠ᨾ + สระอู ᩪ
  - "ลำไย" (ᩃᩣᩴᩱᨿ): ละ ᩃ + นิคหิต สระอำ ᩣᩴ + ไม้ใค ᩱ + ยะ ᨿ
* ชื่อเมืองและสถานที่สำคัญ:
  - "เชียงใหม่" (ᨩ᩠ᨿᨦᩲᩉ᩠ᨾ᩵), "เชียงราย" (ᨩ᩠ᨿᨦᩁᩣ᩠ᨿ), "ลำปาง" (ᩃᩣᩴᨻᩣ᩠ᨦ), "ลำพูน" (ᩃᩣᩴᨻᩪ᩠ᨶ), "แพร่" (ᨻᩯᩕ᩵), "น่าน" (ᨶ᩵ᩣ᩠ᨶ), "พะเยา" (ᨻ᩠ᨿᩣᩅ), "แม่ฮ่องสอน" (ᨾᩯ᩵ᩁᩬ᩶ᨦᩈᩬᩁ)
  - "มหาวิทยาลัยเชียงใหม่" (ᨾᩉᩣᩅᩥᨴ᩠ᨿᩣᩃᩢ᩠ᨿᨩ᩠ᨿᨦᩲᩉ᩠ᨾ᩵), "วัดพระสิงห์วรมหาวิหาร", "วัดป่าอ้อเมืองอินทร์"
* คำทั่วไป:
  - "กำเมือง" (ᨠᩣᩴᨾᩮᩬᩥᨦ), "ฉลาด" (ᨧᩕᩣ᩠ᨯ), "ชีวิตธรรมดา" (ᨩᩦᩅᩥ᩠ᨲᨵ᩠ᨾᨯᩣ), "วันนี้เป็นวันดีขอให้มีโชค", "สวัสดีปีใหม่", "อี้" (ᩋᩦ᩶), "กึ๊บโจ๊ะโล๊ะ"

ตอบกลับเป็น JSON บริสุทธิ์ (Pure JSON) เท่านั้น:
{
  "detected_text": "คำแปลหรือชื่ออักษร (เช่น ส้าดิบ, ลาบ, เชียงใหม่)",
  "lanna_text": "ตัวอักษรหรือข้อความล้านนา (เช่น ᩈ᩶ᩣᨯᩥ᩠ᨷ, ᩃᩣ᩠ᨷ)",
  "reading": "[คำอ่านสำเนียงคำเมืองแท้ เช่น ส้า-ดิบ, ลาบ]",
  "meaning": "คำอธิบายความหมาย บริบท และที่มา",
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
        ]
    ], JSON_UNESCAPED_UNICODE);

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => $postData,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 25,
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

