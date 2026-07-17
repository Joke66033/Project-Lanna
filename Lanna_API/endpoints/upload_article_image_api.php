<?php
/**
 * upload_article_image_api.php
 * รับไฟล์รูปบทความผ่าน multipart/form-data
 * — บันทึกรูปใหม่ลงที่ Lanna_Admin/src/assets/image/articles/ และ lanna/assets/images/articles/
 * — ส่งคืน URL รูปภาพบทความใหม่
 *
 * POST fields:
 *   file : file — ไฟล์รูปภาพ (jpg/jpeg/png/webp) ขนาดไม่เกิน 2MB
 */

require_once __DIR__ . '/../config/db.php';

// CORS (ตั้ง headers ด้วยตนเองเนื่องจากต้องสอดรับกับ multipart/form-data)
$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, apikey');
header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

header('Content-Type: application/json; charset=utf-8');

// ===== Helper =====
function respond($data, ?string $errorMsg = null, int $status = 200): void {
    http_response_code($status);
    echo json_encode(['data' => $data, 'error' => $errorMsg ? ['message' => $errorMsg] : null], JSON_UNESCAPED_UNICODE);
    exit();
}

// ===== รับเฉพาะ POST =====
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(null, 'Method not allowed', 405);
}

// ===== ตรวจสอบไฟล์อัปโหลด =====
if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
    $errCodes = [
        UPLOAD_ERR_INI_SIZE   => 'ไฟล์มีขนาดใหญ่เกินที่ server กำหนด',
        UPLOAD_ERR_FORM_SIZE  => 'ไฟล์มีขนาดใหญ่เกินที่ form กำหนด',
        UPLOAD_ERR_PARTIAL    => 'อัปโหลดไม่สมบูรณ์ กรุณาลองใหม่',
        UPLOAD_ERR_NO_FILE    => 'ไม่ได้เลือกไฟล์',
        UPLOAD_ERR_NO_TMP_DIR => 'ไม่พบโฟลเดอร์ชั่วคราว',
        UPLOAD_ERR_CANT_WRITE => 'ไม่สามารถเขียนไฟล์ลง disk ได้',
    ];
    $code = $_FILES['file']['error'] ?? UPLOAD_ERR_NO_FILE;
    respond(null, $errCodes[$code] ?? 'เกิดข้อผิดพลาดในการอัปโหลด', 400);
}

$file     = $_FILES['file'];
$tmpPath  = $file['tmp_name'];
$origName = $file['name'];
$fileSize = $file['size'];

// ===== ตรวจสอบขนาดไฟล์ (ไม่เกิน 2MB) =====
$maxSize = 2 * 1024 * 1024; // 2 MB
if ($fileSize > $maxSize) {
    respond(null, 'ขนาดไฟล์เกิน 2MB กรุณาเลือกไฟล์ที่มีขนาดเล็กกว่า', 400);
}

// ===== ตรวจสอบชนิดไฟล์ (MIME type) =====
$allowedMimes = ['image/jpeg', 'image/png', 'image/webp'];
$mimeType     = mime_content_type($tmpPath);

if (!in_array($mimeType, $allowedMimes, true)) {
    respond(null, 'ชนิดไฟล์ไม่รองรับ อนุญาตเฉพาะ JPG, PNG, WEBP เท่านั้น', 400);
}

// แปลง MIME → นามสกุล
$extMap = [
    'image/jpeg' => 'jpg',
    'image/png'  => 'png',
    'image/webp' => 'webp',
];
$ext = $extMap[$mimeType];

// ===== โฟลเดอร์ปลายทาง =====
$projectRoot = dirname(__DIR__, 2);
$uploadDirAdmin = $projectRoot . '/Lanna_Admin/src/assets/image/articles/';
$uploadDirAdmin = str_replace(array('/', '\\'), DIRECTORY_SEPARATOR, $uploadDirAdmin);

// สร้างโฟลเดอร์ฝั่ง Admin หากยังไม่มี
if (!file_exists($uploadDirAdmin)) {
    if (!@mkdir($uploadDirAdmin, 0777, true)) {
        respond(null, 'เซิร์ฟเวอร์ไม่สามารถสร้างโฟลเดอร์เก็บไฟล์บน Admin ได้', 500);
    }
}

// ===== ตั้งชื่อไฟล์ด้วย uniqid สำหรับบทความเพื่อไม่ให้ทับซ้อนกัน =====
$filename = 'article_' . uniqid() . '.' . $ext;
$newFilePathAdmin = $uploadDirAdmin . $filename;

// บันทึกไฟล์ลงโฟลเดอร์ Admin
if (!move_uploaded_file($tmpPath, $newFilePathAdmin)) {
    respond(null, 'ไม่สามารถบันทึกไฟล์ใหม่ลง server ได้', 500);
}

// ===== บันทึกไฟล์ลงฝั่ง Mobile (lanna/assets/images/articles/) หากโฟลเดอร์โปรเจกต์อยู่ร่วมกัน =====
$uploadDirLanna = $projectRoot . '/lanna/assets/images/articles/';
$uploadDirLanna = str_replace(array('/', '\\'), DIRECTORY_SEPARATOR, $uploadDirLanna);

if (file_exists($projectRoot . '/lanna')) {
    if (!file_exists($uploadDirLanna)) {
        @mkdir($uploadDirLanna, 0777, true);
    }
    if (file_exists($uploadDirLanna)) {
        @copy($newFilePathAdmin, $uploadDirLanna . $filename);
    }
}

// ===== ส่ง URL คืนไปยังหน้าบ้านเพื่อจัดเก็บลงฐานข้อมูล =====
$host = $_SERVER['HTTP_HOST'] ?? 'localhost:8000';
$proto = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$baseUrl = "$proto://$host";

$imageUrl = "$baseUrl/LANNA/Lanna_Admin/src/assets/image/articles/" . $filename;

respond([
    'image_path' => $imageUrl,
    'filename'   => $filename,
]);
