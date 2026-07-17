<?php
/**
 * upload_profile_api.php
 * รับไฟล์รูปโปรไฟล์ admin หรือ user ทั่วไป ผ่าน multipart/form-data
 * — บันทึกรูปใหม่ลงที่ Lanna_Admin/src/assets/image/profile/ หรือ lanna/assets/images/profile/
 * — ลบรูปเก่าออกจาก disk หลังจากบันทึกและอัปเดตสำเร็จ
 * — อัปเดต column avatar ใน MySQL table users หรือ admin_user
 *
 * POST fields:
 *   admin_id / user_id / id : string — PK ของแอดมิน (เช่น AD0001) หรือผู้ใช้ (เช่น US0001)
 *   type                     : string — 'admin' หรือ 'user'
 *   file                     : file   — ไฟล์รูปภาพ (jpg/jpeg/png/webp) ขนาดไม่เกิน 2MB
 */

require_once __DIR__ . '/../config/db.php';

// CORS (ไม่เรียก setCorsHeaders() ตรงๆ เพราะต้องตั้ง Content-Type ตามปกติก่อน)
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

// ===== Validate input =====
$host = $_SERVER['HTTP_HOST'] ?? 'localhost:8000';
$proto = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$baseUrl = "$proto://$host";

$type = trim($_POST['type'] ?? '');
$id = '';

$projectRoot = dirname(__DIR__, 2);

$requestUri = $_SERVER['REQUEST_URI'] ?? '';
$isSubdir = str_contains(strtolower($requestUri), '/lanna/');

if ($type === 'user') {
    $id = trim($_POST['user_id'] ?? $_POST['id'] ?? '');
    $table = 'users';
    $pkField = 'user_id';
    $uploadDir = $projectRoot . '/lanna/assets/images/profile/';
    $apacheBaseUrl = $isSubdir ? "$baseUrl/LANNA/lanna/assets/images/profile" : "$baseUrl/lanna/assets/images/profile";
} elseif ($type === 'admin') {
    $id = trim($_POST['admin_id'] ?? $_POST['id'] ?? '');
    $table = 'admin_user';
    $pkField = 'admin_id';
    $uploadDir = $projectRoot . '/Lanna_Admin/src/assets/image/profile/';
    $apacheBaseUrl = $isSubdir ? "$baseUrl/LANNA/Lanna_Admin/src/assets/image/profile" : "$baseUrl/Lanna_Admin/src/assets/image/profile";
} else {
    // Fallback: ตรวจจับจาก Prefix ของ ID
    $id = trim($_POST['admin_id'] ?? $_POST['user_id'] ?? $_POST['id'] ?? '');
    $isUser = str_starts_with(strtoupper($id), 'US');
    if ($isUser) {
        $table = 'users';
        $pkField = 'user_id';
        $uploadDir = $projectRoot . '/lanna/assets/images/profile/';
        $apacheBaseUrl = $isSubdir ? "$baseUrl/LANNA/lanna/assets/images/profile" : "$baseUrl/lanna/assets/images/profile";
    } else {
        $table = 'admin_user';
        $pkField = 'admin_id';
        $uploadDir = $projectRoot . '/Lanna_Admin/src/assets/image/profile/';
        $apacheBaseUrl = $isSubdir ? "$baseUrl/LANNA/Lanna_Admin/src/assets/image/profile" : "$baseUrl/Lanna_Admin/src/assets/image/profile";
    }
}

// แปลง Path ตัวแยกโฟลเดอร์ตาม OS
$uploadDir = str_replace(array('/', '\\'), DIRECTORY_SEPARATOR, $uploadDir);

if ($id === '') {
    respond(null, 'กรุณาระบุ admin_id หรือ user_id', 400);
}

// สร้างโฟลเดอร์สำหรับผู้ใช้ทั่วไปหากไม่มี
if (!file_exists($uploadDir)) {
    if (!@mkdir($uploadDir, 0777, true)) {
        respond(null, 'เซิร์ฟเวอร์ไม่สามารถสร้างโฟลเดอร์เก็บไฟล์ได้ กรุณาตรวจสอบสิทธิ์', 500);
    }
}

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

$file       = $_FILES['file'];
$tmpPath    = $file['tmp_name'];
$origName   = $file['name'];
$fileSize   = $file['size'];

// ===== ตรวจสอบขนาดไฟล์ (ไม่เกิน 2MB) =====
$maxSize = 2 * 1024 * 1024; // 2 MB
if ($fileSize > $maxSize) {
    respond(null, 'ขนาดไฟล์เกิน 2MB กรุณาเลือกไฟล์ที่มีขนาดเล็กกว่า', 400);
}

// ===== ตรวจสอบชนิดไฟล์ (MIME type จริง ไม่ใช่แค่นามสกุล) =====
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

// ===== ตั้งชื่อไฟล์ใหม่ =====
$safeId = preg_replace('/[^a-zA-Z0-9_\-]/', '', $id);

if ($table === 'admin_user') {
    // 1. ตั้งชื่อไฟล์อิงตาม admin_id เท่านั้น ไม่มี timestamp ต่อท้าย
    $newFilename = "profile_{$safeId}.{$ext}";
} else {
    // สำหรับผู้ใช้ทั่วไป (users) ใช้โครงสร้างเดิมที่มี timestamp
    $timestamp = time();
    $newFilename = "profile_{$safeId}_{$timestamp}.{$ext}";
}

$newFilePath = $uploadDir . $newFilename;

// ===== 1. บันทึกไฟล์ใหม่ลง disk จริงก่อนเพื่อความปลอดภัย =====
if (!move_uploaded_file($tmpPath, $newFilePath)) {
    respond(null, 'ไม่สามารถบันทึกไฟล์ใหม่ลง server ได้ กรุณาตรวจสอบสิทธิ์โฟลเดอร์ปลายทาง', 500);
}

// ===== 2. บันทึกสำเร็จ -> ดึงข้อมูล URL รูปเก่าจาก DB เพื่อเตรียมลบภายหลัง =====
$dbRes = dbSelectSingle($table, 'avatar', [$pkField => 'eq.' . rawurlencode($id)]);
$oldAvatarUrl = $dbRes['data']['avatar'] ?? '';

// ===== 3. อัปเดต avatar URL ในตารางฐานข้อมูล =====
$newAvatarUrl = $apacheBaseUrl . '/' . $newFilename;
$updateRes = dbUpdate($table, [$pkField => 'eq.' . rawurlencode($id)], ['avatar' => $newAvatarUrl]);

if ($updateRes['error']) {
    // Rollback: อัปเดต DB ล้มเหลว ให้ทำการลบไฟล์ใหม่ที่เพิ่งบันทึกสำเร็จทิ้งทันที
    @unlink($newFilePath);
    respond(null, 'บันทึกไฟล์รูปภาพสำเร็จ แต่ไม่สามารถอัปเดตฐานข้อมูลได้: ' . $updateRes['error']['message'], 500);
}

// ===== 4. บันทึกและบันทึก DB สำเร็จ -> ค่อยทำการลบไฟล์รูปเก่าออกจากดิสก์ =====
if ($oldAvatarUrl !== '') {
    $oldFilename = basename($oldAvatarUrl);
    $oldFilename = explode('?', $oldFilename)[0];
    
    $targetOldPath = '';
    if (str_contains($oldAvatarUrl, '/Lanna_Admin/src/assets/image/profile/users/')) {
        $targetOldPath = $projectRoot . '/Lanna_Admin/src/assets/image/profile/users/' . $oldFilename;
    } elseif (str_contains($oldAvatarUrl, '/Lanna_Admin/src/assets/image/profile/')) {
        $targetOldPath = $projectRoot . '/Lanna_Admin/src/assets/image/profile/' . $oldFilename;
    } elseif (str_contains($oldAvatarUrl, '/lanna/assets/images/profile/')) {
        $targetOldPath = $projectRoot . '/lanna/assets/images/profile/' . $oldFilename;
    }
    
    $targetOldPath = str_replace(array('/', '\\'), DIRECTORY_SEPARATOR, $targetOldPath);
    
    // ตรวจสอบว่าไม่ใช้ไฟล์เดียวกัน (กรณีแอดมินบันทึกซ้ำชื่อเดิม) และไฟล์เก่ามีอยู่จริง ค่อยสั่งลบ
    if ($targetOldPath !== '' && file_exists($targetOldPath) && realpath($targetOldPath) !== realpath($newFilePath)) {
        @unlink($targetOldPath);
    }
}

// สำหรับแอดมิน: ค้นหาและสั่งลบนามสกุลรูปอื่นๆ ของ ID นี้ที่ตกค้างออกไปด้วย (เนื่องจากชื่อไฟล์ไม่มี timestamp)
if ($table === 'admin_user') {
    $mask = $uploadDir . "profile_{$safeId}.*";
    $files = glob($mask);
    if (is_array($files)) {
        foreach ($files as $f) {
            if (is_file($f) && realpath($f) !== realpath($newFilePath)) {
                @unlink($f);
            }
        }
    }
}

if ($isSubdir) {
    $resolvedResponseUrl = "$baseUrl/LANNA/endpoints/users_api.php?action=getAvatar&filename=" . urlencode($newFilename);
} else {
    $resolvedResponseUrl = "$baseUrl/endpoints/users_api.php?action=getAvatar&filename=" . urlencode($newFilename);
}

respond([
    'avatar'   => $resolvedResponseUrl,
    'filename' => $newFilename,
]);
