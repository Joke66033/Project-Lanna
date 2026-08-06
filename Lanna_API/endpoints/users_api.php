<?php
/**
 * users_api.php
 * ย้าย logic จาก usersApi.js → PHP
 * Table: users (PK: user_id)
 *
 * Actions (GET):
 *   ?action=getAll              → SELECT * ORDER BY user_id ASC (status mapped, password_hash hidden)
 *   ?action=getById&id=         → SELECT * WHERE user_id = id (status mapped, password_hash hidden)
 *
 * Actions (POST):
 *   ?action=create              → INSERT (body: JSON) -> maps status & name, generates US####, hashes password
 *   ?action=register            → INSERT (body: JSON) -> maps status & name, generates US####, hashes password
 *   ?action=login               → Login with email & password, returns user & session token (only from users table)
 *   ?action=update&id=          → UPDATE WHERE user_id = id (body: JSON or multipart) (auth required for personal fields)
 *   ?action=delete&id=          → DELETE WHERE user_id = id (auth required if token present, cleans up avatar from disk)
 */

require_once __DIR__ . '/../config/db.php';
setCorsHeaders();

$action = $_GET['action'] ?? 'getAll';

/**
 * ฟังก์ชันตรวจสอบ token ของผู้ใช้ทั่วไป
 */
function verifyUserToken(): ?array {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (empty($authHeader) && function_exists('apache_request_headers')) {
        $headers = apache_request_headers();
        if (isset($headers['Authorization'])) {
            $authHeader = $headers['Authorization'];
        }
    }
    if (empty($authHeader) || !str_starts_with(strtolower($authHeader), 'bearer ')) {
        return null;
    }
    $token = substr($authHeader, 7);
    $decodedStr = base64_decode($token, true);
    if (!$decodedStr) return null;
    $payload = json_decode($decodedStr, true);
    if (!is_array($payload)) return null;
    if (!isset($payload['user_id']) || !isset($payload['exp'])) return null;
    if ($payload['exp'] < time()) return null; // Token expired
    return $payload;
}

/**
 * แปลง path avatar ให้เป็น URL endpoint สำหรับดึงรูป
 */
function resolveUserAvatar(array &$user): void {
    if (!empty($user['avatar'])) {
        $filename = '';
        if (str_contains($user['avatar'], 'filename=')) {
            $parts = parse_url($user['avatar']);
            if (isset($parts['query'])) {
                parse_str($parts['query'], $query);
                if (isset($query['filename'])) {
                    $filename = basename($query['filename']);
                }
            }
        }
        
        if (empty($filename)) {
            $filename = basename($user['avatar']);
            $filename = explode('?', $filename)[0];
        }
        
        $host = $_SERVER['HTTP_HOST'] ?? 'localhost:8000';
        $proto = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
        $baseUrl = "$proto://$host";
        $requestUri = $_SERVER['REQUEST_URI'] ?? '';
        $isSubdir = str_contains(strtolower($requestUri), '/lanna/');
        
        if ($isSubdir) {
            $user['avatar'] = "$baseUrl/LANNA/endpoints/users_api.php?action=getAvatar&filename=" . urlencode($filename);
        } else {
            $user['avatar'] = "$baseUrl/endpoints/users_api.php?action=getAvatar&filename=" . urlencode($filename);
        }
    }
}

// ===== GET =====
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    switch ($action) {

        case 'getAll':
            $res = dbSelect('users', '*', [], 'user_id.desc');
            if ($res['error']) { jsonError($res['error']['message']); break; }
            
            $users = $res['data'] ?? [];
            $mappedUsers = [];
            foreach ($users as $user) {
                if (isset($user['status'])) {
                    $user['status'] = ($user['status'] == 1) ? 'active' : 'banned';
                } else {
                    $user['status'] = 'active';
                }
                unset($user['password_hash']);
                resolveUserAvatar($user);
                $mappedUsers[] = $user;
            }
            jsonOk($mappedUsers);
            break;

        case 'getById':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbSelectSingle('users', '*', ['user_id' => 'eq.' . rawurlencode($id)]);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            
            $user = $res['data'];
            if ($user) {
                if (isset($user['status'])) {
                    $user['status'] = ($user['status'] == 1) ? 'active' : 'banned';
                } else {
                    $user['status'] = 'active';
                }
                unset($user['password_hash']);
                resolveUserAvatar($user);
            }
            jsonOk($user);
            break;

        case 'getAvatar':
            $filename = trim($_GET['filename'] ?? '');
            if ($filename === '') {
                jsonError('Missing filename');
                break;
            }
            $projectRoot = dirname(__DIR__, 2);
            
            // Check admin directory first if filename looks like admin or if file exists there
            $adminFilePath = $projectRoot . '/Lanna_Admin/src/assets/image/profile/' . $filename;
            $userFilePath = $projectRoot . '/lanna/assets/images/profile/' . $filename;
            
            $adminFilePath = str_replace(array('/', '\\'), DIRECTORY_SEPARATOR, $adminFilePath);
            $userFilePath = str_replace(array('/', '\\'), DIRECTORY_SEPARATOR, $userFilePath);
            
            $filePath = '';
            if (file_exists($adminFilePath) && !is_dir($adminFilePath)) {
                $filePath = $adminFilePath;
            } elseif (file_exists($userFilePath) && !is_dir($userFilePath)) {
                $filePath = $userFilePath;
            }
            
            if ($filePath !== '') {
                $ext = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
                $mimeTypes = [
                    'jpg'  => 'image/jpeg',
                    'jpeg' => 'image/jpeg',
                    'png'  => 'image/png',
                    'gif'  => 'image/gif',
                    'webp' => 'image/webp',
                    'svg'  => 'image/svg+xml',
                ];
                $mimeType = $mimeTypes[$ext] ?? 'application/octet-stream';
                
                header('Content-Type: ' . $mimeType, true);
                header('Content-Length: ' . filesize($filePath));
                readfile($filePath);
                exit();
            } else {
                http_response_code(404);
                header('Content-Type: application/json; charset=utf-8', true);
                echo json_encode(['error' => 'File not found: ' . $filename], JSON_UNESCAPED_UNICODE);
                exit();
            }
            break;

        default:
            jsonError('Unknown action');
    }
}

// ===== POST =====
elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $body = getJsonBody();

    switch ($action) {

        case 'create':
        case 'register':
            $username = trim($body['username'] ?? $body['name'] ?? '');
            $email = strtolower(trim($body['email'] ?? ''));
            $password = trim($body['password'] ?? '');

            if (empty($username) || empty($email) || empty($password)) {
                jsonError('กรุณากรอกข้อมูลให้ครบถ้วน');
                break;
            }

            if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                jsonError('รูปแบบอีเมลไม่ถูกต้อง');
                break;
            }

            // ค้นหาอีเมลในตาราง users เท่านั้น ห้ามปะปนกับ admin_user
            $check = dbSelect('users', 'user_id', ['email' => 'eq.' . rawurlencode($email)]);
            if (!empty($check['data'])) {
                jsonError('อีเมลนี้ถูกใช้งานแล้ว');
                break;
            }

            // ดึง ID ล่าสุดเพื่อนำมาบวก 1 และสร้างรหัสผู้ใช้รูปฟอร์แมต US####
            $listRes = dbSelect('users', 'user_id', [], 'user_id.desc', 1);
            $nextNumber = 1;
            if (empty($listRes['error'])) {
                $list = $listRes['data'] ?? [];
                if (!empty($list)) {
                    $lastId = $list[0]['user_id'] ?? '';
                    if (preg_match('/\d+/', $lastId, $m)) {
                        $nextNumber = (int)$m[0] + 1;
                    }
                }
            }
            $nextId = 'US' . str_pad((string)$nextNumber, 4, '0', STR_PAD_LEFT);

            // แปลงสถานะ String เป็น Integer (1 = active, 0 = banned)
            $statusVal = 1;
            if (isset($body['status'])) {
                if ($body['status'] === 'banned' || $body['status'] === '0' || $body['status'] === 0) {
                    $statusVal = 0;
                }
            }

            $newUser = [
                'user_id' => $nextId,
                'username' => $username,
                'email' => $email,
                'password_hash' => password_hash($password, PASSWORD_BCRYPT),
                'avatar' => $body['avatar'] ?? null,
                'status' => $statusVal
            ];

            $res = dbInsert('users', $newUser);
            if ($res['error']) { jsonError($res['error']['message']); break; }

            $insertedUser = $res['data'];
            if ($insertedUser) {
                if (isset($insertedUser['status'])) {
                    $insertedUser['status'] = ($insertedUser['status'] == 1) ? 'active' : 'banned';
                }
                unset($insertedUser['password_hash']);
                resolveUserAvatar($insertedUser);
            }

            // สร้าง Token สำหรับการล็อกอินอัตโนมัติ
            $tokenPayload = [
                'user_id' => $insertedUser['user_id'],
                'email' => $insertedUser['email'],
                'exp' => time() + (86400 * 30) // 30 วัน
            ];
            $token = base64_encode(json_encode($tokenPayload));

            jsonOk([
                'user' => $insertedUser,
                'token' => $token
            ]);
            break;

        case 'login':
            $email = strtolower(trim($body['email'] ?? ''));
            $password = trim($body['password'] ?? '');

            if (empty($email) || empty($password)) {
                jsonError('กรุณากรอกอีเมลและรหัสผ่าน');
                break;
            }

            // ค้นหาในตาราง users เท่านั้น
            $res = dbSelectSingle('users', '*', ['email' => 'eq.' . rawurlencode($email)]);
            if ($res['error'] || empty($res['data'])) {
                jsonError('ไม่พบบัญชีผู้ใช้นี้ กรุณาลงทะเบียนก่อน');
                break;
            }

            $user = $res['data'];
            if ($user['status'] == 0 || $user['status'] === '0') {
                jsonError('บัญชีนี้ถูกระงับการใช้งาน');
                break;
            }

            if (password_verify($password, $user['password_hash'])) {
                // สร้าง Session Token แบบง่าย (Base64 encoded JSON)
                $tokenPayload = [
                    'user_id' => $user['user_id'],
                    'email' => $user['email'],
                    'exp' => time() + (86400 * 30) // 30 วัน
                ];
                $token = base64_encode(json_encode($tokenPayload));

                unset($user['password_hash']);
                $user['status'] = ($user['status'] == 1) ? 'active' : 'banned';
                resolveUserAvatar($user);
                
                jsonOk([
                    'user' => $user,
                    'token' => $token
                ]);
            } else {
                jsonError('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
            }
            break;

        case 'update':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }

            // ตรวจสอบสิทธิ์โดยแกะ Token
            $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
            if (empty($authHeader) && function_exists('apache_request_headers')) {
                $headers = apache_request_headers();
                if (isset($headers['Authorization'])) {
                    $authHeader = $headers['Authorization'];
                }
            }

            // หากการอัปเดตมีข้อมูลส่วนตัว ต้องเช็คสิทธิ์ (เว้นแต่เป็นการแก้ไขเฉพาะสถานะจากฝั่งแอดมิน)
            $requiresAuth = true;
            if (empty($authHeader)) {
                $hasPersonalFields = isset($body['username']) || isset($body['name']) || isset($body['email']) || isset($body['avatar']) || isset($body['password']) 
                    || isset($_POST['username']) || isset($_POST['name']) || isset($_POST['email']) || isset($_POST['avatar']) || isset($_POST['password'])
                    || isset($_FILES['file']) || isset($_FILES['avatar']);
                if ((isset($body['status']) || isset($_POST['status'])) && !$hasPersonalFields) {
                    $requiresAuth = false;
                }
            }

            if ($requiresAuth) {
                if (empty($authHeader)) {
                    jsonError('Unauthorized: Missing token', 401);
                    break;
                }
                $tokenPayload = verifyUserToken();
                if (!$tokenPayload) {
                    jsonError('Unauthorized: Invalid or expired token', 401);
                    break;
                }
                if ($tokenPayload['user_id'] !== $id) {
                    jsonError('Forbidden: You can only update your own profile', 403);
                    break;
                }
            }

            // จัดการข้อมูลเพื่อส่งอัปเดตลงตาราง users (รองรับทั้ง JSON และ Multipart)
            $dbBody = [];
            if (isset($body['username'])) $dbBody['username'] = trim($body['username']);
            elseif (isset($_POST['username'])) $dbBody['username'] = trim($_POST['username']);

            if (isset($body['name'])) $dbBody['username'] = trim($body['name']);
            elseif (isset($_POST['name'])) $dbBody['username'] = trim($_POST['name']);

            if (isset($body['email'])) $dbBody['email'] = strtolower(trim($body['email']));
            elseif (isset($_POST['email'])) $dbBody['email'] = strtolower(trim($_POST['email']));

            $passVal = $body['password'] ?? $_POST['password'] ?? '';
            if ($passVal !== '') {
                $dbBody['password_hash'] = password_hash($passVal, PASSWORD_BCRYPT);
            }
            $statusVal = $body['status'] ?? $_POST['status'] ?? null;
            if ($statusVal !== null) {
                if ($statusVal === 'active' || $statusVal === '1' || $statusVal === 1) {
                    $dbBody['status'] = 1;
                } elseif ($statusVal === 'banned' || $statusVal === '0' || $statusVal === 0) {
                    $dbBody['status'] = 0;
                }
            }

            if (isset($body['avatar'])) $dbBody['avatar'] = $body['avatar'];
            elseif (isset($_POST['avatar'])) $dbBody['avatar'] = $_POST['avatar'];

            // รองรับอัปโหลดรูปภาพผ่าน Users update API โดยตรง
            $fileField = isset($_FILES['file']) ? 'file' : (isset($_FILES['avatar']) ? 'avatar' : null);
            if ($fileField && $_FILES[$fileField]['error'] === UPLOAD_ERR_OK) {
                $file = $_FILES[$fileField];
                $tmpPath = $file['tmp_name'];
                $fileSize = $file['size'];
                
                // ตรวจสอบขนาดไฟล์ไม่เกิน 2MB
                if ($fileSize <= 2 * 1024 * 1024) {
                    $allowedMimes = ['image/jpeg', 'image/png', 'image/webp'];
                    $mimeType = mime_content_type($tmpPath);
                    if (in_array($mimeType, $allowedMimes, true)) {
                        $extMap = [
                            'image/jpeg' => 'jpg',
                            'image/png'  => 'png',
                            'image/webp' => 'webp',
                        ];
                        $ext = $extMap[$mimeType];
                        
                        $host = $_SERVER['HTTP_HOST'] ?? 'localhost:8000';
                        $proto = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
                        $baseUrl = "$proto://$host";
                        $requestUri = $_SERVER['REQUEST_URI'] ?? '';
                        $isSubdir = str_contains(strtolower($requestUri), '/lanna/');
                        
                        $projectRoot = dirname(__DIR__, 2);
                        $uploadDir = $projectRoot . '/lanna/assets/images/profile/';
                        $uploadDir = str_replace(array('/', '\\'), DIRECTORY_SEPARATOR, $uploadDir);
                        
                        if ($isSubdir) {
                            $apacheBaseUrl = "$baseUrl/LANNA/lanna/assets/images/profile";
                        } else {
                            $apacheBaseUrl = "$baseUrl/lanna/assets/images/profile";
                        }
                        
                        if (!file_exists($uploadDir)) {
                            @mkdir($uploadDir, 0777, true);
                        }
                        
                        // ดึงและลบไฟล์รูปเดิมออกจาก disk
                        $oldAvatarRes = dbSelectSingle('users', 'avatar', ['user_id' => 'eq.' . rawurlencode($id)]);
                        $oldAvatarUrl = $oldAvatarRes['data']['avatar'] ?? '';
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
                            
                            if ($targetOldPath !== '' && file_exists($targetOldPath)) {
                                @unlink($targetOldPath);
                            }
                        }
                        
                        // บันทึกไฟล์ใหม่
                        $timestamp = time();
                        $safeId = preg_replace('/[^a-zA-Z0-9_\-]/', '', $id);
                        $newFilename = "profile_{$safeId}_{$timestamp}.{$ext}";
                        $newFilePath = $uploadDir . $newFilename;
                        
                        if (move_uploaded_file($tmpPath, $newFilePath)) {
                            $dbBody['avatar'] = $apacheBaseUrl . '/' . $newFilename;
                        }
                    }
                }
            }

            if (empty($dbBody)) {
                jsonError('No fields to update');
                break;
            }

            $res = dbUpdate('users', ['user_id' => 'eq.' . rawurlencode($id)], $dbBody);
            if ($res['error']) { jsonError($res['error']['message']); break; }

            $updatedUser = $res['data'];
            if ($updatedUser) {
                if (isset($updatedUser['status'])) {
                    $updatedUser['status'] = ($updatedUser['status'] == 1) ? 'active' : 'banned';
                }
                unset($updatedUser['password_hash']);
                resolveUserAvatar($updatedUser);
            }
            jsonOk($updatedUser);
            break;

        case 'delete':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }

            $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
            if (empty($authHeader) && function_exists('apache_request_headers')) {
                $headers = apache_request_headers();
                if (isset($headers['Authorization'])) {
                    $authHeader = $headers['Authorization'];
                }
            }

            // ถ้าส่ง Token มา ต้องตรวจสิทธิ์ว่าลบได้เฉพาะตนเอง
            if (!empty($authHeader)) {
                $tokenPayload = verifyUserToken();
                if (!$tokenPayload) {
                    jsonError('Unauthorized: Invalid or expired token', 401);
                    break;
                }
                if ($tokenPayload['user_id'] !== $id) {
                    jsonError('Forbidden: You can only delete your own account', 403);
                    break;
                }
            }

            // ดึงและลบไฟล์รูปโปรไฟล์เดิมออกจากเครื่อง Server ก่อนลบ Row ใน DB
            $userRes = dbSelectSingle('users', 'avatar', ['user_id' => 'eq.' . rawurlencode($id)]);
            $avatarUrl = $userRes['data']['avatar'] ?? '';
            if ($avatarUrl !== '') {
                $oldFilename = basename($avatarUrl);
                $oldFilename = explode('?', $oldFilename)[0];
                
                $targetOldPath = '';
                if (str_contains($avatarUrl, '/Lanna_Admin/src/assets/image/profile/')) {
                    $targetOldPath = 'D:\\PROJECT_LANNA\\Lanna_Admin\\src\\assets\\image\\profile\\' . $oldFilename;
                } elseif (str_contains($avatarUrl, '/lanna/assets/images/profile/')) {
                    $targetOldPath = 'D:\\PROJECT_LANNA\\lanna\\assets\\images\\profile\\' . $oldFilename;
                }
                
                if ($targetOldPath !== '' && file_exists($targetOldPath)) {
                    @unlink($targetOldPath);
                }
            }

            $res = dbDelete('users', ['user_id' => 'eq.' . rawurlencode($id)]);
            if ($res['error']) { jsonError($res['error']['message']); break; }

            $deletedUser = $res['data'];
            if (is_array($deletedUser) && isset($deletedUser[0])) {
                $deletedUser = $deletedUser[0];
            }
            if ($deletedUser) {
                if (isset($deletedUser['status'])) {
                    $deletedUser['status'] = ($deletedUser['status'] == 1) ? 'active' : 'banned';
                }
                unset($deletedUser['password_hash']);
            }
            jsonOk($deletedUser);
            break;

        default:
            jsonError('Unknown action');
    }
}

else {
    jsonError('Method not allowed', 405);
}
