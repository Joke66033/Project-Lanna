<?php
/**
 * จัดหมวดหมู่คำศัพท์โดยแก้ไขเฉพาะ vocabulary.category_vocab_id
 *
 * Preview: php categorize_vocabulary.php
 * Apply:   php categorize_vocabulary.php --apply
 */

require_once __DIR__ . '/../config/db.php';

const GENERAL_CATEGORY_ID = 'CV0008';

function containsAny(string $text, array $needles): bool {
    foreach ($needles as $needle) {
        if ($needle !== '' && mb_stripos($text, $needle, 0, 'UTF-8') !== false) {
            return true;
        }
    }
    return false;
}

function startsWithAny(string $text, array $prefixes): bool {
    $text = ltrim($text);
    foreach ($prefixes as $prefix) {
        if (mb_substr($text, 0, mb_strlen($prefix, 'UTF-8'), 'UTF-8') === $prefix) {
            return true;
        }
    }
    return false;
}

function classifyVocabulary(array $row): string {
    $word = trim((string)($row['thai_word'] ?? ''));
    $meaning = trim((string)($row['meaning'] ?? ''));
    $text = $word . ' ' . $meaning;

    // หมวดปฏิทินเฉพาะ ต้องมีหลักฐานตรงตัวเท่านั้น
    if (containsAny($text, ['วันอาทิตย์', 'วันจันทร์', 'วันอังคาร', 'วันพุธ', 'วันพฤหัสบดี', 'วันศุกร์', 'วันเสาร์'])) {
        return 'CV0003';
    }
    if (containsAny($text, ['เดือนล้านนา', 'เดือนเกี๋ยง', 'เดือนยี่', 'เดือน ๓', 'เดือน ๔', 'เดือน ๕', 'เดือน ๖', 'เดือน ๗', 'เดือน ๘', 'เดือน ๙', 'เดือน ๑๐', 'เดือน ๑๑', 'เดือน ๑๒'])) {
        return 'CV0004';
    }
    if (containsAny($text, ['ปีนักษัตร', 'ปีใจ้', 'ปีเป้า', 'ปียี', 'ปีเหม้า', 'ปีสี', 'ปีใส้', 'ปีสะง้า', 'ปีเม็ด', 'ปีสัน', 'ปีเร้า', 'ปีเส็ด', 'ปีไก๊'])) {
        return 'CV0005';
    }
    if (containsAny($text, ['วันดีวันเสีย', 'วันจม', 'วันฟู', 'วันเม็ง', 'วันไท'])) {
        return 'CV0006';
    }

    if (containsAny($text, ['คำทักทาย', 'กล่าวทักทาย', 'สวัสดี', 'ยินดีต้อนรับ', 'ลาก่อน'])) {
        return 'CV0001';
    }
    if (containsAny($meaning, [
        'อาหาร', 'ของกิน', 'ขนม', 'แกง', 'เครื่องดื่ม', 'เครื่องปรุง',
        'กับข้าว', 'อาหารมื้อ', 'ใช้รับประทาน', 'ใช้กิน'
    ])) {
        return 'CV0002';
    }
    if (containsAny($meaning, [
        'สัตว์', 'แมลง', 'นกชนิด', 'ปลาชนิด', 'งูชนิด', 'กบชนิด',
        'หอยชนิด', 'ปูชนิด', 'ตัวอ่อนของ', 'สัตว์น้ำ', 'สัตว์ปีก'
    ])) {
        return 'CV0007';
    }
    if (containsAny($meaning, [
        'พืช', 'สมุนไพร', 'ไม้ยืนต้น', 'ไม้พุ่ม', 'ไม้ล้มลุก', 'ไม้เถา',
        'ต้นไม้ชนิด', 'หญ้าชนิด', 'เห็ดชนิด', 'ดอกไม้ชนิด', 'พันธุ์ข้าว'
    ])) {
        return 'CV0009';
    }
    if (containsAny($meaning, [
        'เครื่องมือ', 'เครื่องใช้', 'อุปกรณ์', 'ภาชนะ', 'อาวุธ',
        'เครื่องจักสาน', 'เครื่องดนตรี', 'เครื่องนุ่งห่ม'
    ])) {
        return 'CV0010';
    }
    if (containsAny($meaning, [
        'พิธี', 'ประเพณี', 'ธรรมเนียม', 'ความเชื่อ', 'บูชา',
        'สืบชาตา', 'ส่งเคราะห์', 'ทำบุญ', 'งานศพ'
    ])) {
        return 'CV0014';
    }
    if (containsAny($meaning, [
        'สถานที่', 'ศาสนสถาน', 'วัด', 'วิหาร', 'เจดีย์', 'อุโบสถ',
        'หมู่บ้าน', 'เมือง', 'ถนน', 'ทางเดิน', 'ป่าช้า'
    ])) {
        return 'CV0013';
    }

    // อักษรย่อชนิดคำในพจนานุกรมเป็นหลักฐานที่ชัดเจนที่สุด
    if (startsWithAny($meaning, ['ก.', 'กริยา'])) {
        return 'CV0011';
    }
    if (startsWithAny($meaning, ['ว.', 'สำนวน', 'สำ.', 'สุภาษิต'])) {
        return 'CV0012';
    }

    return GENERAL_CATEGORY_ID;
}

$apply = in_array('--apply', $argv, true);
$pdo = getPdo();

$categoryRows = $pdo->query(
    'SELECT category_vocab_id, name FROM category_vocab'
)->fetchAll(PDO::FETCH_ASSOC);
$validCategoryIds = array_column($categoryRows, 'name', 'category_vocab_id');
if (!isset($validCategoryIds[GENERAL_CATEGORY_ID])) {
    throw new RuntimeException('ไม่พบหมวดเริ่มต้น CV0008 (คำศัพท์ทั่วไป)');
}

$rows = $pdo->query(
    'SELECT vocab_id, thai_word, meaning, category_vocab_id FROM vocabulary ORDER BY vocab_id'
)->fetchAll(PDO::FETCH_ASSOC);

$assignments = [];
$stats = [];
foreach ($rows as $row) {
    $categoryId = classifyVocabulary($row);
    if (!isset($validCategoryIds[$categoryId])) {
        $categoryId = GENERAL_CATEGORY_ID;
    }
    $stats[$categoryId] = ($stats[$categoryId] ?? 0) + 1;
    if ((string)($row['category_vocab_id'] ?? '') !== $categoryId) {
        $assignments[] = [$categoryId, $row['vocab_id']];
    }
}

echo 'คำศัพท์ทั้งหมด: ' . count($rows) . PHP_EOL;
echo 'รายการที่จะเปลี่ยนหมวด: ' . count($assignments) . PHP_EOL;
ksort($stats);
foreach ($stats as $categoryId => $count) {
    echo $categoryId . ' ' . $validCategoryIds[$categoryId] . ': ' . $count . PHP_EOL;
}

if (!$apply) {
    echo 'โหมดตรวจสอบเท่านั้น (ยังไม่ได้แก้ฐานข้อมูล)' . PHP_EOL;
    exit(0);
}

$pdo->beginTransaction();
try {
    // คำสั่งนี้ระบุเพียงฟิลด์ category_vocab_id ตามข้อจำกัดของงาน
    $update = $pdo->prepare(
        'UPDATE vocabulary SET category_vocab_id = :category_id WHERE vocab_id = :vocab_id'
    );
    foreach ($assignments as [$categoryId, $vocabId]) {
        $update->execute([
            ':category_id' => $categoryId,
            ':vocab_id' => $vocabId,
        ]);
    }
    $pdo->commit();
    echo 'อัปเดตหมวดหมู่สำเร็จ: ' . count($assignments) . ' รายการ' . PHP_EOL;
} catch (Throwable $error) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    throw $error;
}
