<?php
/**
 * admin_user_api.php
 * ย้าย logic จาก adminUserApi.js → PHP
 * Table: admin_user (PK: admin_id)
 *
 * Actions (GET):
 *   ?action=getAll           → SELECT * ORDER BY admin_id ASC
 *   ?action=getById&id=      → SELECT * WHERE admin_id = id
 *   ?action=getByEmail&email=→ SELECT * WHERE email = email
 *   ?action=getOtpByEmail&email= → SELECT otp_code,otp_expires_at WHERE email = email
 *
 * Actions (POST):
 *   ?action=create           → INSERT (body: JSON)
 *   ?action=update&id=       → UPDATE WHERE admin_id = id (body: JSON)
 *   ?action=updateByEmail&email= → UPDATE WHERE email = email (body: JSON)
 *   ?action=delete&id=       → DELETE WHERE admin_id = id
 */

require_once __DIR__ . '/../config/db.php';
setCorsHeaders();

/* $action = $_GET['action'] ?? ''; */
$action = $_GET['action'] ?? 'getAll';

// ===== GET =====
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    switch ($action) {

        case 'getAll':
            $res = dbSelect('admin_user', '*', [], 'admin_id.asc');
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'getById':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbSelectSingle('admin_user', '*', ['admin_id' => 'eq.' . $id]);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'getByEmail':
            $email = strtolower(trim($_GET['email'] ?? ''));
            if ($email === '') { jsonError('Missing email'); break; }
            // ไม่ต้อง rawurlencode เพราะ PHP decode $_GET ให้แล้ว
            // แต่ต้อง quote ค่าสำหรับ PostgREST filter ที่มี @ หรือ special chars
            $res = dbSelectSingle('admin_user', '*', ['email' => 'eq.' . $email]);
            if ($res['error']) { jsonError($res['error']['message'], 404); break; }
            jsonOk($res['data']);
            break;

        case 'getOtpByEmail':
            $email = strtolower(trim($_GET['email'] ?? ''));
            if ($email === '') { jsonError('Missing email'); break; }
            // SELECT เฉพาะ fields ที่จำเป็น (ถ้า otp fields ไม่มีใน DB ให้ return null แทน error)
            $res = dbSelectSingle('admin_user', '*', ['email' => 'eq.' . $email]);
            if ($res['error']) { jsonOk(null); break; } // ไม่มีข้อมูลหรือ column ไม่มี → return null
            $row = $res['data'];
            jsonOk([
                'otp_code'       => $row['otp_code']       ?? null,
                'otp_expires_at' => $row['otp_expires_at'] ?? null,
            ]);
            break;

        default:
            jsonError('Unknown action');
    }
}

// ===== POST =====
elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $body = getJsonBody();

    switch ($action) {

        case 'login':
            $email = strtolower(trim($body['email'] ?? ''));
            $password = trim($body['password'] ?? '');

            if (empty($email) || empty($password)) {
                jsonError('กรุณากรอกอีเมลและรหัสผ่าน');
                break;
            }

            // ค้นหาข้อมูลแอดมินด้วยอีเมล
            // หมายเหตุ: ไม่ใช้ rawurlencode() เพราะ dbRequest() จะ encode ค่าให้อีกรอบอยู่แล้ว
            // การ encode ซ้ำทำให้ @ กลายเป็น %2540 → query ไม่ match record จริง
            $res = dbSelectSingle('admin_user', '*', ['email' => 'eq.' . $email]);
            if ($res['error'] || empty($res['data'])) {
                jsonError('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
                break;
            }

            $admin = $res['data'];
            
            // เช็คว่าสถานะยังเปิดใช้งานหรือไม่ (status = 1)
            if (isset($admin['status']) && $admin['status'] == 0) {
                jsonError('บัญชีนี้ถูกระงับการใช้งาน');
                break;
            }

            // เปรียบเทียบรหัสผ่าน (รองรับทั้ง bcrypt และ plain text สำหรับแอดมินเก่า)
            $isMatch = false;
            $hash = $admin['password_hash'] ?? '';
            
            // ตรวจสอบว่ารหัสผ่านเป็น bcrypt หรือไม่ ($2y$, $2a$, $2b$)
            $isBcrypt = (str_starts_with($hash, '$2a$') || str_starts_with($hash, '$2b$') || str_starts_with($hash, '$2y$'));

            if ($isBcrypt) {
                $isMatch = password_verify($password, $hash);
            } else {
                // แอดมินเก่าที่ยังเก็บรหัสผ่าน plain text
                $isMatch = ($password === $hash);
                
                // อัปเกรดเป็น bcrypt อัตโนมัติเมื่อตรวจสอบผ่าน
                if ($isMatch) {
                    $newHash = password_hash($password, PASSWORD_BCRYPT);
                    dbUpdate('admin_user', ['admin_id' => 'eq.' . $admin['admin_id']], [
                        'password_hash'  => $newHash,
                        'password_plain' => $password,
                    ]);
                    $admin['password_hash'] = $newHash;
                }
            }

            if (!$isMatch) {
                jsonError('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
                break;
            }

            // ลบ password_hash ก่อนส่งกลับฝั่ง frontend เพื่อความปลอดภัย
            unset($admin['password_hash']);

            jsonOk($admin);
            break;

        case 'create':
            $res = dbInsert('admin_user', $body);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'update':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }

            // Log received body for debugging
            error_log('=== ADMIN PROFILE UPDATE DEBUG ===');
            error_log('GET params: ' . json_encode($_GET, JSON_UNESCAPED_UNICODE));
            error_log('Raw request body: ' . file_get_contents('php://input'));
            error_log('Parsed request body: ' . json_encode($body, JSON_UNESCAPED_UNICODE));

            // Create update data starting from name, email, avatar
            $updateData = [];
            if (isset($body['name'])) {
                $updateData['name'] = trim($body['name']);
            }
            if (isset($body['email'])) {
                $updateData['email'] = strtolower(trim($body['email']));
            }
            if (isset($body['avatar'])) {
                $updateData['avatar'] = trim($body['avatar']);
            }

            // Check if newPassword is provided and not empty
            if (isset($body['newPassword']) && trim($body['newPassword']) !== '') {
                $updateData['password_hash'] = password_hash(trim($body['newPassword']), PASSWORD_BCRYPT);
                $updateData['password_plain'] = trim($body['newPassword']);
            }

            error_log('Payload sent to dbUpdate: ' . json_encode($updateData, JSON_UNESCAPED_UNICODE));

            $res = dbUpdate('admin_user', ['admin_id' => 'eq.' . $id], $updateData);

            error_log('Response from dbUpdate: ' . json_encode($res, JSON_UNESCAPED_UNICODE));

            if ($res['error']) { 
                jsonError($res['error']['message']); 
                break; 
            }
            if (empty($res['data'])) {
                jsonError('ไม่สามารถอัปเดตข้อมูลผู้ดูแลระบบได้ หรือไม่พบข้อมูลผู้ดูแลระบบ ID นี้');
                break;
            }

            // Sync avatar to local folder (non-blocking)
            try {
                syncAvatarFromDatabase($id);
            } catch (\Throwable $e) {
                error_log("syncAvatarFromDatabase exception: " . $e->getMessage());
            }

            jsonOk($res['data']);
            break;

        case 'updateByEmail':
            $email = strtolower(trim($_GET['email'] ?? ''));
            if ($email === '') { jsonError('Missing email'); break; }

            // Log received body for debugging
            error_log('=== ADMIN PROFILE UPDATE BY EMAIL DEBUG ===');
            error_log('GET params: ' . json_encode($_GET, JSON_UNESCAPED_UNICODE));
            error_log('Raw request body: ' . file_get_contents('php://input'));
            error_log('Parsed request body: ' . json_encode($body, JSON_UNESCAPED_UNICODE));

            // Create update data starting from name, email, avatar
            $updateData = [];
            if (isset($body['name'])) {
                $updateData['name'] = trim($body['name']);
            }
            if (isset($body['email'])) {
                $updateData['email'] = strtolower(trim($body['email']));
            }
            if (isset($body['avatar'])) {
                $updateData['avatar'] = trim($body['avatar']);
            }

            // Check if newPassword is provided and not empty
            if (isset($body['newPassword']) && trim($body['newPassword']) !== '') {
                $updateData['password_hash'] = password_hash(trim($body['newPassword']), PASSWORD_BCRYPT);
                $updateData['password_plain'] = trim($body['newPassword']);
            }

            error_log('Payload sent to dbUpdate: ' . json_encode($updateData, JSON_UNESCAPED_UNICODE));

            $res = dbUpdate('admin_user', ['email' => 'eq.' . $email], $updateData);

            error_log('Response from dbUpdate: ' . json_encode($res, JSON_UNESCAPED_UNICODE));

            if ($res['error']) { 
                jsonError($res['error']['message']); 
                break; 
            }
            if (empty($res['data'])) {
                jsonError('ไม่สามารถอัปเดตข้อมูลผู้ดูแลระบบได้ หรือไม่พบผู้ดูแลระบบด้วยอีเมลนี้');
                break;
            }

            // Sync avatar to local folder (non-blocking)
            $adminId = $res['data']['admin_id'] ?? '';
            if ($adminId !== '') {
                try {
                    syncAvatarFromDatabase($adminId);
                } catch (\Throwable $e) {
                    error_log("syncAvatarFromDatabase exception: " . $e->getMessage());
                }
            }

            jsonOk($res['data']);
            break;

        case 'delete':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbDelete('admin_user', ['admin_id' => 'eq.' . $id]);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        default:
            jsonError('Unknown action');
    }
}

else {
    jsonError('Method not allowed', 405);
}

/**
 * Sync avatar from Database to local folder src/assets/image/profile/
 *
 * @param string $adminId
 * @return bool
 */
function syncAvatarFromDatabase(string $adminId): bool {
    // The previous logic here was deleting the file from disk before trying to fetch it via HTTP from the same disk, causing it to self-destruct.
    // Files are already saved properly by upload_profile_api.php, so this sync is unnecessary and destructive.
    return true;
}
