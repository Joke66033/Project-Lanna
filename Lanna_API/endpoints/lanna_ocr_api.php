<?php
/**
 * Proxy for the experimental local Lanna OCR service.
 *
 * POST multipart/form-data:
 *   file: JPG, PNG or WEBP image (maximum 8 MB)
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

function lannaOcrRespond($data, ?string $errorMessage = null, int $status = 200): void {
    http_response_code($status);
    echo json_encode([
        'data' => $data,
        'error' => $errorMessage ? ['message' => $errorMessage] : null,
    ], JSON_UNESCAPED_UNICODE);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    lannaOcrRespond(null, 'Method not allowed', 405);
}

if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
    lannaOcrRespond(null, 'กรุณาเลือกภาพที่ต้องการอ่าน', 400);
}

$file = $_FILES['file'];
if (($file['size'] ?? 0) > 8 * 1024 * 1024) {
    lannaOcrRespond(null, 'ไฟล์ภาพต้องมีขนาดไม่เกิน 8 MB', 413);
}

$mimeType = mime_content_type($file['tmp_name']);
$allowedMimes = ['image/jpeg', 'image/png', 'image/webp'];
if (!in_array($mimeType, $allowedMimes, true)) {
    lannaOcrRespond(null, 'รองรับเฉพาะภาพ JPG, PNG และ WEBP', 415);
}

$imageBytes = file_get_contents($file['tmp_name']);
if ($imageBytes === false || $imageBytes === '') {
    lannaOcrRespond(null, 'ไม่สามารถอ่านไฟล์ภาพได้', 400);
}

$payload = json_encode([
    'image_base64' => base64_encode($imageBytes),
    'mime_type' => $mimeType,
], JSON_UNESCAPED_UNICODE);

$ch = curl_init('http://127.0.0.1:8005/api/ocr-lanna');
curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => $payload,
    CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_CONNECTTIMEOUT => 5,
    CURLOPT_TIMEOUT => 120,
]);

$response = curl_exec($ch);
$curlError = curl_error($ch);
$httpCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($response === false || $httpCode === 0) {
    error_log('Lanna OCR proxy error: ' . $curlError);
    lannaOcrRespond(null, 'บริการอ่านอักษรล้านนายังไม่พร้อมใช้งาน', 503);
}

$decoded = json_decode($response, true);
if (!is_array($decoded)) {
    lannaOcrRespond(null, 'บริการ OCR ล้านนาส่งผลลัพธ์ไม่ถูกต้อง', 502);
}

if ($httpCode < 200 || $httpCode >= 300 || ($decoded['status'] ?? '') !== 'success') {
    $message = $decoded['message'] ?? 'ไม่สามารถอ่านอักษรล้านนาจากภาพนี้ได้';
    lannaOcrRespond(null, $message, $httpCode >= 400 ? $httpCode : 502);
}

$result = $decoded['result'] ?? [];
lannaOcrRespond([
    'text' => trim((string) ($result['thai_text'] ?? '')),
    'confidence' => (float) ($result['confidence'] ?? 0),
    'is_low_confidence' => (bool) ($result['is_low_confidence'] ?? true),
    'characters' => $result['characters'] ?? [],
    'warning' => $result['warning'] ?? 'ผล OCR ล้านนาอยู่ในขั้นทดลอง',
    'experimental' => true,
]);

