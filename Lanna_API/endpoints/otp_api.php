<?php
/**
 * otp_api.php
 * ระบบ OTP สำหรับการลืมรหัสผ่าน ใช้ได้ทั้งฝั่ง users และ admin_user (รูปแบบ Stateless Token-based)
 * เข้ารหัสและส่ง OTP ยืนยันสิทธิ์โดยไม่ต้องใช้ตารางฐานข้อมูล
 *
 * Actions (POST):
 *   ?action=send           → สร้าง OTP 6 หลัก + ส่งอีเมล + คืนค่า token (body: email, type)
 *   ?action=verify         → ตรวจสอบ OTP + คืนค่า resetToken (body: email, otp, type, token)
 *   ?action=resetPassword  → ตั้งรหัสผ่านใหม่ (body: newPassword, resetToken)
 */

require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception;

// Log Request parameters for debugging
error_log('=== OTP API REQUEST === Method: ' . ($_SERVER['REQUEST_METHOD'] ?? ''));
error_log('GET params: ' . json_encode($_GET));
error_log('POST params: ' . json_encode($_POST));
error_log('Raw body: ' . file_get_contents('php://input'));

setCorsHeaders();

$action = $_GET['action'] ?? '';

// ===== รับเฉพาะ POST =====
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError('Method not allowed', 405);
    exit();
}

$body = getJsonBody();
$encryptionKey = $_ENV['ENCRYPTION_KEY'] ?? 'default_key_lanna_translation_12345';

// =============================================
// ฟังก์ชันช่วยเข้ารหัสและถอดรหัส Token (AES-256-CBC)
// =============================================
function encryptToken(array $payload, string $key): string {
    $cipher = 'aes-256-cbc';
    $ivLen = openssl_cipher_iv_length($cipher);
    $iv = openssl_random_pseudo_bytes($ivLen);
    
    // คีย์ต้องเป็น 32 ไบต์ (256 บิต) — หากเป็น Base64 ให้ถอดรหัสก่อน
    $rawKey = base64_decode($key);
    if (strlen($rawKey) !== 32) {
        $rawKey = str_pad(substr($key, 0, 32), 32, "\0");
    }
    
    $jsonData = json_encode($payload);
    $encrypted = openssl_encrypt($jsonData, $cipher, $rawKey, OPENSSL_RAW_DATA, $iv);
    
    return base64_encode($iv . $encrypted);
}

function decryptToken(string $token, string $key): ?array {
    try {
        $cipher = 'aes-256-cbc';
        $ivLen = openssl_cipher_iv_length($cipher);
        $decoded = base64_decode($token, true);
        if (!$decoded || strlen($decoded) <= $ivLen) return null;
        
        $iv = substr($decoded, 0, $ivLen);
        $encrypted = substr($decoded, $ivLen);
        
        $rawKey = base64_decode($key);
        if (strlen($rawKey) !== 32) {
            $rawKey = str_pad(substr($key, 0, 32), 32, "\0");
        }
        
        $decrypted = openssl_decrypt($encrypted, $cipher, $rawKey, OPENSSL_RAW_DATA, $iv);
        if ($decrypted === false) return null;
        
        return json_decode($decrypted, true);
    } catch (\Exception $e) {
        return null;
    }
}

switch ($action) {

    // ========================================
    // ACTION: send — สร้าง OTP + ส่งอีเมล + คืนค่า token
    // ========================================
    case 'send':
        $email = strtolower(trim($body['email'] ?? ''));
        $type  = trim($body['type'] ?? '');

        if (empty($email)) {
            jsonError('กรุณาระบุอีเมล');
            break;
        }
        if (!in_array($type, ['user', 'admin'], true)) {
            jsonError('กรุณาระบุ type เป็น "user" หรือ "admin"');
            break;
        }

        // ตรวจสอบว่าอีเมลมีอยู่ในตารางที่ระบุหรือไม่
        $table   = ($type === 'user') ? 'users' : 'admin_user';
        $pkField = ($type === 'user') ? 'user_id' : 'admin_id';
        $check   = dbSelectSingle($table, $pkField, ['email' => 'eq.' . rawurlencode($email)]);

        if ($check['error'] || empty($check['data'])) {
            jsonError('ไม่พบบัญชีผู้ใช้ที่ลงทะเบียนด้วยอีเมลนี้');
            break;
        }

        // สร้าง OTP 6 หลัก
        $otpCode = str_pad((string)rand(100000, 999999), 6, '0', STR_PAD_LEFT);
        $expiresAt = time() + 180; // หมดอายุใน 3 นาที (180 วินาที)

        // สร้าง Token ที่เก็บข้อมูลรหัส OTP
        $payload = [
            'email'      => $email,
            'type'       => $type,
            'otp_code'   => $otpCode,
            'expires_at' => $expiresAt
        ];
        $token = encryptToken($payload, $encryptionKey);

        // ส่งอีเมล OTP
        $mailSent = sendOtpEmail($email, $otpCode);

        if (!$mailSent['success']) {
            jsonError('ไม่สามารถส่งอีเมลได้: ' . $mailSent['error']);
            break;
        }

        jsonOk([
            'message' => 'ส่งรหัส OTP ไปยังอีเมลของคุณเรียบร้อยแล้ว',
            'token'   => $token
        ]);
        break;

    // ========================================
    // ACTION: verify — ตรวจสอบ OTP + ออก resetToken
    // ========================================
    case 'verify':
        $email = strtolower(trim($body['email'] ?? ''));
        $otp   = trim($body['otp'] ?? '');
        $type  = trim($body['type'] ?? '');
        $token = trim($body['token'] ?? '');

        if (empty($email) || empty($otp) || empty($type) || empty($token)) {
            jsonError('ข้อมูลไม่ครบถ้วน (กรุณาส่ง email, otp, type, token)');
            break;
        }

        // ถอดรหัส Token
        $payload = decryptToken($token, $encryptionKey);
        if (!$payload) {
            jsonError('รหัส OTP ไม่ถูกต้อง หรือโทเค็นการขอทำรายการหมดอายุแล้ว');
            break;
        }

        // ตรวจสอบค่าภายใน Token
        if (
            strtolower(trim($payload['email'])) !== $email ||
            $payload['type'] !== $type ||
            $payload['otp_code'] !== $otp
        ) {
            jsonError('รหัส OTP ไม่ถูกต้อง');
            break;
        }

        // ตรวจสอบว่า OTP หมดอายุแล้วหรือยัง
        if ($payload['expires_at'] < time()) {
            jsonError('รหัส OTP หมดอายุแล้ว กรุณาขอรหัสใหม่');
            break;
        }

        // หากยืนยันผ่าน ให้ออก resetToken (มีอายุ 5 นาที) เพื่อใช้สำหรับขั้นตอนตั้งรหัสผ่านใหม่
        $resetPayload = [
            'email'    => $email,
            'type'     => $type,
            'verified' => true,
            'expires'  => time() + 300 // 5 นาที
        ];
        $resetToken = encryptToken($resetPayload, $encryptionKey);

        jsonOk([
            'message'    => 'ยืนยันรหัส OTP สำเร็จ',
            'resetToken' => $resetToken
        ]);
        break;

    // ========================================
    // ACTION: resetPassword — ตั้งรหัสผ่านใหม่โดยใช้ resetToken
    // ========================================
    case 'resetPassword':
        $newPassword = trim($body['newPassword'] ?? $body['new_password'] ?? '');
        $resetToken  = trim($body['resetToken'] ?? $body['reset_token'] ?? '');

        if (empty($newPassword) || empty($resetToken)) {
            jsonError('กรุณาระบุรหัสผ่านใหม่และโทเค็นรีเซ็ต');
            break;
        }
        if (strlen($newPassword) < 6) {
            jsonError('รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร');
            break;
        }

        // ถอดรหัส resetToken
        $payload = decryptToken($resetToken, $encryptionKey);
        if (!$payload || !($payload['verified'] ?? false)) {
            jsonError('โทเค็นการตั้งรหัสผ่านใหม่ไม่ถูกต้องหรือหมดอายุ');
            break;
        }

        // ตรวจสอบเวลาหมดอายุของโทเค็นรีเซ็ต
        if ($payload['expires'] < time()) {
            jsonError('ลิงก์หรือโทเค็นการตั้งรหัสผ่านใหม่หมดอายุแล้ว กรุณาขอ OTP อีกครั้ง');
            break;
        }

        $email = strtolower(trim($payload['email']));
        $type  = $payload['type'];
        $table = ($type === 'user') ? 'users' : 'admin_user';

        // Hash รหัสผ่านใหม่
        $hashedPassword = password_hash($newPassword, PASSWORD_BCRYPT);

        // Debug Log
        error_log("=== RESET PASSWORD DEBUG === Attempting reset on table: {$table}, email: {$email}");

        // อัปเดตรหัสผ่านในตาราง (สำหรับแอดมิน ให้อัปเดต password_plain ด้วย เพื่อใช้แสดงในโปรไฟล์)
        $updateData = [
            'password_hash' => $hashedPassword
        ];
        if ($type === 'admin') {
            $updateData['password_plain'] = $newPassword;
        }

        $updateRes = dbUpdate($table, ['email' => 'eq.' . rawurlencode($email)], $updateData);

        // Debug Log output
        error_log("=== RESET PASSWORD DEBUG === Update Response: " . json_encode($updateRes, JSON_UNESCAPED_UNICODE));

        if ($updateRes['error']) {
            jsonError('ไม่สามารถอัปเดตรหัสผ่านได้: ' . $updateRes['error']['message']);
            break;
        }

        // เช็คว่ามีแถวถูกอัปเดตจริงหรือไม่ (PostgREST คืน array ว่างถ้าไม่มีข้อมูลตรงตาม filter)
        if (empty($updateRes['data'])) {
            jsonError('ไม่พบบัญชีผู้ใช้ที่ตรงกับอีเมลนี้ ไม่สามารถอัปเดตรหัสผ่านได้');
            break;
        }

        jsonOk([
            'message' => 'ตั้งรหัสผ่านใหม่เรียบร้อยแล้ว',
            'email'   => $email
        ]);
        break;

    default:
        jsonError('Unknown action: กรุณาระบุ action เป็น send, verify หรือ resetPassword');
}

function sendOtpEmail(string $toEmail, string $otpCode): array {
    // 1. ส่งผ่าน Google Apps Script Webhook (ส่งจากบัญชี Google ของคุณโดยตรงผ่าน HTTPS ไม่โดนบล็อกพอร์ต)
    $googleWebhook = $_ENV['GOOGLE_MAIL_WEBHOOK'] ?? getenv('GOOGLE_MAIL_WEBHOOK') ?? '';
    if (!empty($googleWebhook)) {
        $ch = curl_init($googleWebhook);
        $payload = json_encode([
            'to' => $toEmail,
            'subject' => '🔑 รหัส OTP สำหรับรีเซ็ตรหัสผ่าน - แปลภาษาล้านนา',
            'html' => buildOtpEmailHtml($otpCode),
        ]);
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_TIMEOUT => 15,
            CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
            CURLOPT_POSTFIELDS => $payload
        ]);
        $resp = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($code >= 200 && $code < 400) {
            return ['success' => true, 'error' => null];
        }
    }

    // 2. ส่งผ่าน Brevo API (HTTPS Port 443)
    $brevoKey = $_ENV['BREVO_API_KEY'] ?? getenv('BREVO_API_KEY') ?? '';
    if (!empty($brevoKey)) {
        $ch = curl_init('https://api.brevo.com/v3/smtp/email');
        $payload = json_encode([
            'sender' => [
                'name' => 'แปลภาษาล้านนา',
                'email' => $_ENV['MAIL_FROM_ADDRESS'] ?? '661463033@crru.ac.th'
            ],
            'to' => [
                ['email' => $toEmail]
            ],
            'subject' => '🔑 รหัส OTP สำหรับรีเซ็ตรหัสผ่าน - แปลภาษาล้านนา',
            'htmlContent' => buildOtpEmailHtml($otpCode),
        ]);
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 10,
            CURLOPT_HTTPHEADER => [
                'api-key: ' . $brevoKey,
                'Content-Type: application/json',
                'Accept: application/json'
            ],
            CURLOPT_POSTFIELDS => $payload
        ]);
        $resp = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($code >= 200 && $code < 300) {
            return ['success' => true, 'error' => null];
        }
    }

    // 3. ส่งผ่าน Google SMTP (PHPMailer)
    $mail = new PHPMailer(true);

    try {
        $mail->CharSet = 'UTF-8';
        $mailerType = $_ENV['MAIL_MAILER'] ?? 'smtp';
        
        if ($mailerType === 'smtp') {
            $mail->isSMTP();
            $mail->Host       = $_ENV['MAIL_HOST'] ?? '127.0.0.1';
            $mail->SMTPAuth   = !empty($_ENV['MAIL_PASSWORD']);
            $mail->Username   = $_ENV['MAIL_USERNAME'] ?? 'siripaporn';
            $mail->Password   = $_ENV['MAIL_PASSWORD'] ?? '';
            
            $enc = strtolower($_ENV['MAIL_ENCRYPTION'] ?? 'none');
            if ($enc === 'ssl') {
                $mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS;
            } elseif ($enc === 'tls') {
                $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
            } else {
                $mail->SMTPSecure = false;
                $mail->SMTPAutoTLS = false;
            }
            $mail->Port       = (int)($_ENV['MAIL_PORT'] ?? 25);
            $mail->Timeout    = 10;
            $mail->SMTPOptions = [
                'ssl' => [
                    'verify_peer' => false,
                    'verify_peer_name' => false,
                    'allow_self_signed' => true
                ]
            ];
            
        $mail->CharSet = 'UTF-8';
        $mail->Encoding = 'base64';
        
        // ผู้ส่ง
        $fromAddress = $_ENV['MAIL_FROM_ADDRESS'] ?? 'siripaporn@siripaporn.lnw.mn';
        $fromName    = $_ENV['MAIL_FROM_NAME'] ?? 'แปลภาษาล้านนา';
        $mail->setFrom($fromAddress, $fromName);
        
        // ผู้รับ
        $mail->addAddress($toEmail);
        
        // เนื้อหา
        $mail->isHTML(true);
        $mail->Subject = '🔑 รหัส OTP สำหรับรีเซ็ตรหัสผ่าน - แปลภาษาล้านนา';
        $mail->Body    = buildOtpEmailHtml($otpCode);
        $mail->AltBody = "รหัส OTP ของคุณคือ: $otpCode (หมดอายุใน 3 นาที)";
        
        $mail->send();
        return ['success' => true, 'error' => null];
        }
        
        return ['success' => false, 'error' => 'Mailer configuration not supported'];
    } catch (Exception $e) {
        return ['success' => false, 'error' => $mail->ErrorInfo ?: $e->getMessage()];
    }
}

// =============================================
// สร้าง HTML Template สำหรับอีเมล OTP ดีไซน์สวยงามตามรูปแบบ
// =============================================
function buildOtpEmailHtml(string $otpCode): string {
    return <<<HTML
<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>รหัสยืนยัน OTP - แปลภาษาล้านนา</title>
</head>
<body style="margin:0; padding:0; background-color:#f4f5f7; font-family:'Segoe UI','Noto Sans Thai',Tahoma,sans-serif; -webkit-font-smoothing:antialiased;">
  <table align="center" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px; margin:40px auto; background:#ffffff; border-radius:18px; box-shadow:0 6px 24px rgba(0,0,0,0.07); overflow:hidden; border:1px solid #e5e7eb;">
    
    <!-- Header -->
    <tr>
      <td style="background:linear-gradient(135deg, #F59E0B 0%, #EA580C 50%, #C2410C 100%); padding:34px 24px; text-align:center;">
        <h1 style="color:#ffffff; margin:0; font-size:24px; font-weight:700; letter-spacing:0.5px; text-shadow:0 1px 2px rgba(0,0,0,0.12);">
          🔑 รีเซ็ตรหัสผ่าน
        </h1>
        <p style="color:rgba(255,255,255,0.95); margin:8px 0 0; font-size:14px; font-weight:400;">
          แปลภาษาล้านนา — Lanna Translation
        </p>
      </td>
    </tr>

    <!-- Body -->
    <tr>
      <td style="padding:34px 24px; text-align:center;">
        <p style="color:#374151; font-size:16px; line-height:1.6; margin:0 0 26px;">
          สวัสดีค่ะ คุณได้ร้องขอรีเซ็ตรหัสผ่าน<br>
          กรุณาใช้รหัส OTP ด้านล่างเพื่อดำเนินการ:
        </p>

        <!-- OTP Code Box -->
        <div style="display:inline-block; background:linear-gradient(135deg, #FEF3C7 0%, #FDE68A 100%); border:2px solid #F59E0B; border-radius:14px; padding:18px 44px; margin:0 0 26px; box-shadow:0 4px 12px rgba(245,158,11,0.15);">
          <span style="font-size:38px; font-weight:800; color:#9A3412; letter-spacing:14px; padding-left:14px; font-family:'Courier New',Consolas,monospace; display:block; line-height:1.1;">
            {$otpCode}
          </span>
        </div>

        <p style="color:#6B7280; font-size:14px; line-height:1.6; margin:0;">
          ⏱️ รหัสนี้จะหมดอายุใน <strong style="color:#DC2626;">3 นาที</strong><br>
          หากคุณไม่ได้ร้องขอรีเซ็ตรหัสผ่าน กรุณาเพิกเฉยอีเมลนี้
        </p>
      </td>
    </tr>

    <!-- Footer -->
    <tr>
      <td style="background:#f9fafb; padding:20px 24px; text-align:center; border-top:1px solid #e5e7eb;">
        <p style="color:#9CA3AF; font-size:12px; margin:0;">
          © 2026 แปลภาษาล้านนา — ส่งอัตโนมัติจากระบบ กรุณาอย่าตอบกลับอีเมลนี้
        </p>
      </td>
    </tr>

  </table>
</body>
</html>
HTML;
}
