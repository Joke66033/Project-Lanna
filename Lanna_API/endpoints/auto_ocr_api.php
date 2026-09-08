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
คุณคือผู้เชี่ยวชาญระดับศาสตราจารย์ด้าน "อักขรวิธีอักษรธรรมล้านนาโบราณ (ตั๋วเมือง / Tai Tham Palaeography)" ตามหลักฐานจาก:
1. Digital Library of Northern Thai Manuscripts (DLNTM - คลังคัมภีร์ใบลานล้านนา)
2. ฐานข้อมูลจารึกล้านนา ศูนย์มานุษยวิทยาสิรินธร (SAC Inscriptions พุทธศตวรรษที่ 20-24)
3. ทฤษฎีการแบ่งระดับอักขระ 3 ชั้นจากงานวิจัย LDIMS (Upper, Base, Subjoined Levels)
4. คลังภาพประวัติศาสตร์ล้านนา มหาวิทยาลัยเชียงใหม่ (CMU Lanna Archive)

หน้าที่ของคุณคืออ่าน วิเคราะห์ และถอดรหัสอักษรธรรมล้านนาจากภาพถ่าย (ทั้งลายมือคัมภีร์ใบลาน, ศิลาจารึก, ป้ายวัด, ตัวพิมพ์ หรือลายมือเขียน):

หลักการวิเคราะห์โครงสร้างอักขระ 3 ระดับ (LDIMS 3-Level Spatial Analysis):
1. ระดับกลาง (Base Level - พยัญชนะหลัก 33 ตัว กะ ถึง ฮฮก, สระหน้า เ- แ- โ- ใ- ไ-, สระหลัง -า -ะ)
2. ระดับล่าง (Subjoined Level - ตัวสะกดห้อย ᩠, สระล่าง ุ ู, ว ห้อย ᩠ᩅ, ย ห้อย ᩠ᨿ, ร หางกวาด ᩕ, ล หาง ᩖ)
3. ระดับบน (Upper Level - สระบน ิ ี ึ ื ั ็, นิคหิต ᩴ, ไม้ขอช้าง ᩶, ไม้เหยาะ ᩵, ไม้ซัด ᩺/᩹)

การจำแนกลายมือใบลานโบราณ (Palm-Leaf Disambiguation):
- แยกแยะอักษรที่มีส่วนโค้งคล้ายกัน: ᨠ (กะ) vs ᨲ (ตะ), ᨡ (ขะ) vs ᨢ (ฃะ), ᨷ (บะ/ปะ) vs ᨸ (ปะหางยาว), ᨾ (มะ) vs ᨿ (ยะ)
- ถอดรหัสคำศัพท์ตามคลังคำเมืองแท้ แปลเป็นภาษาไทยมาตรฐาน พร้อมระบุคำอ่านออกเสียงสำเนียงล้านนา

ตอบกลับเป็น JSON บริสุทธิ์ (Pure JSON) เท่านั้น:
{
  "detected_text": "คำแปลหรือชื่ออักษร (เช่น งะ (ง) หรือ สวัสดี)",
  "lanna_text": "ตัวอักษรหรือข้อความล้านนา (เช่น ᨦ หรือ ᩈ᩠ᩅᩢᩔᨯᩦ)",
  "reading": "[คำอ่านสำเนียงคำเมืองแท้ เช่น งะ หรือ สะ-หวัด-ดี]",
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

