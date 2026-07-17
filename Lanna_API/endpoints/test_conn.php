<?php
// test_conn.php
// ไฟล์สคริปต์ตรวจวินิจฉัยปัญหาการเชื่อมต่อฐานข้อมูลบนโฮสต์จริง

error_reporting(E_ALL);
ini_set('display_errors', '1');

require_once __DIR__ . '/../config/db.php';

header('Content-Type: text/plain; charset=utf-8');

echo "=== DATABASE CONNECTION DIAGNOSTIC ===\n\n";

// 1. ตรวจสอบค่าตัวแปรใน .env
echo "1. Checking Env variables:\n";
echo "DB_HOST: " . ($_ENV['DB_HOST'] ?? 'NOT SET') . "\n";
echo "DB_PORT: " . ($_ENV['DB_PORT'] ?? 'NOT SET') . "\n";
echo "DB_NAME: " . ($_ENV['DB_NAME'] ?? 'NOT SET') . "\n";
echo "DB_USER: " . ($_ENV['DB_USER'] ?? 'NOT SET') . "\n";

$pass = $_ENV['DB_PASSWORD'] ?? '';
$passLength = strlen($pass);
if ($passLength > 0) {
    echo "DB_PASSWORD: SET (Length: $passLength, Starts with: " . substr($pass, 0, 2) . "...)\n";
} else {
    echo "DB_PASSWORD: NOT SET or EMPTY\n";
}
echo "\n";

// 2. ทดสอบเชื่อมต่อแบบปกติ (localhost)
echo "2. Testing connection with host=localhost:\n";
try {
    $dsnLocal = "mysql:host=" . $_ENV['DB_HOST'] . ";port=" . $_ENV['DB_PORT'] . ";dbname=" . $_ENV['DB_NAME'] . ";charset=utf8mb4";
    $pdoLocal = new PDO($dsnLocal, $_ENV['DB_USER'], $_ENV['DB_PASSWORD'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
    ]);
    echo "-> SUCCESSFUL connection via localhost!\n";
} catch (PDOException $e) {
    echo "-> FAILED: " . $e->getMessage() . " (Code: " . $e->getCode() . ")\n";
}
echo "\n";

// 3. ทดสอบเชื่อมต่อแบบ 127.0.0.1 (TCP/IP)
echo "3. Testing connection with host=127.0.0.1:\n";
try {
    $dsnIp = "mysql:host=127.0.0.1;port=" . $_ENV['DB_PORT'] . ";dbname=" . $_ENV['DB_NAME'] . ";charset=utf8mb4";
    $pdoIp = new PDO($dsnIp, $_ENV['DB_USER'], $_ENV['DB_PASSWORD'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
    ]);
    echo "-> SUCCESSFUL connection via 127.0.0.1!\n";
} catch (PDOException $e) {
    echo "-> FAILED: " . $e->getMessage() . " (Code: " . $e->getCode() . ")\n";
}
echo "\n";

// 4. คำแนะนำช่วยเหลือเพิ่มเติม
echo "4. Recommendations:\n";
echo "- หาก FAILED ทั้งคู่ด้วยข้อความ 'Access denied' แสดงว่ารหัสผ่านฐานข้อมูลในไฟล์ .env ยังไม่ตรงกับในโฮสต์ หรือตัวผู้ใช้งานนี้ยังไม่ถูกผูกสิทธิ์เข้ากับฐานข้อมูลใน DirectAdmin\n";
echo "- ใน DirectAdmin ➔ MySQL Management ➔ คลิกชื่อ Database ➔ ไปที่หัวข้อ Add User to Database เพื่อผูกสิทธิ์เข้าด้วยกันก่อนครับ\n";
