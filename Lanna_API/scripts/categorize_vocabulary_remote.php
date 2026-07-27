<?php
/**
 * ตัวเรียกใช้งานผ่าน Production API สำหรับเครื่องที่เชื่อม MySQL โดยตรงไม่ได้
 * ส่ง PATCH เชิงความหมายผ่าน update endpoint โดย body มีเฉพาะ category_vocab_id
 */

const API_BASE = 'https://siripaporn.lnw.mn/endpoints';
const GENERAL_CATEGORY_ID = 'CV0008';

function apiGet(string $url): array {
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 120,
        CURLOPT_HTTPHEADER => ['Accept: application/json'],
    ]);
    $body = curl_exec($ch);
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    if ($status !== 200 || $body === false) {
        throw new RuntimeException("GET ล้มเหลว ($status): $error");
    }
    $decoded = json_decode($body, true);
    if (!is_array($decoded) || !array_key_exists('data', $decoded)) {
        throw new RuntimeException('รูปแบบข้อมูล API ไม่ถูกต้อง');
    }
    return $decoded['data'] ?? [];
}

function containsAny(string $text, array $needles): bool {
    foreach ($needles as $needle) {
        if (mb_stripos($text, $needle, 0, 'UTF-8') !== false) return true;
    }
    return false;
}

function startsWithAny(string $text, array $prefixes): bool {
    $text = ltrim($text);
    foreach ($prefixes as $prefix) {
        if (mb_substr($text, 0, mb_strlen($prefix, 'UTF-8'), 'UTF-8') === $prefix) return true;
    }
    return false;
}

function classifyVocabulary(array $row): string {
    $word = trim((string)($row['thai_word'] ?? ''));
    $meaning = trim((string)($row['meaning'] ?? ''));
    $text = $word . ' ' . $meaning;

    if (containsAny($text, ['วันอาทิตย์', 'วันจันทร์', 'วันอังคาร', 'วันพุธ', 'วันพฤหัสบดี', 'วันศุกร์', 'วันเสาร์'])) return 'CV0003';
    if (containsAny($text, ['เดือนล้านนา', 'เดือนเกี๋ยง', 'เดือนยี่', 'เดือน ๓', 'เดือน ๔', 'เดือน ๕', 'เดือน ๖', 'เดือน ๗', 'เดือน ๘', 'เดือน ๙', 'เดือน ๑๐', 'เดือน ๑๑', 'เดือน ๑๒'])) return 'CV0004';
    if (containsAny($text, ['ปีนักษัตร', 'ปีใจ้', 'ปีเป้า', 'ปียี', 'ปีเหม้า', 'ปีสี', 'ปีใส้', 'ปีสะง้า', 'ปีเม็ด', 'ปีสัน', 'ปีเร้า', 'ปีเส็ด', 'ปีไก๊'])) return 'CV0005';
    if (containsAny($text, ['วันดีวันเสีย', 'วันจม', 'วันฟู', 'วันเม็ง', 'วันไท'])) return 'CV0006';
    if (containsAny($text, ['คำทักทาย', 'กล่าวทักทาย', 'สวัสดี', 'ยินดีต้อนรับ', 'ลาก่อน'])) return 'CV0001';
    if (containsAny($meaning, ['อาหาร', 'ของกิน', 'ขนม', 'แกง', 'เครื่องดื่ม', 'เครื่องปรุง', 'กับข้าว', 'อาหารมื้อ', 'ใช้รับประทาน', 'ใช้กิน'])) return 'CV0002';
    if (containsAny($meaning, ['สัตว์', 'แมลง', 'นกชนิด', 'ปลาชนิด', 'งูชนิด', 'กบชนิด', 'หอยชนิด', 'ปูชนิด', 'ตัวอ่อนของ', 'สัตว์น้ำ', 'สัตว์ปีก'])) return 'CV0007';
    if (containsAny($meaning, ['พืช', 'สมุนไพร', 'ไม้ยืนต้น', 'ไม้พุ่ม', 'ไม้ล้มลุก', 'ไม้เถา', 'ต้นไม้ชนิด', 'หญ้าชนิด', 'เห็ดชนิด', 'ดอกไม้ชนิด', 'พันธุ์ข้าว'])) return 'CV0009';
    if (containsAny($meaning, ['เครื่องมือ', 'เครื่องใช้', 'อุปกรณ์', 'ภาชนะ', 'อาวุธ', 'เครื่องจักสาน', 'เครื่องดนตรี', 'เครื่องนุ่งห่ม'])) return 'CV0010';
    if (containsAny($meaning, ['พิธี', 'ประเพณี', 'ธรรมเนียม', 'ความเชื่อ', 'บูชา', 'สืบชาตา', 'ส่งเคราะห์', 'ทำบุญ', 'งานศพ'])) return 'CV0014';
    if (containsAny($meaning, ['สถานที่', 'ศาสนสถาน', 'วัด', 'วิหาร', 'เจดีย์', 'อุโบสถ', 'หมู่บ้าน', 'เมือง', 'ถนน', 'ทางเดิน', 'ป่าช้า'])) return 'CV0013';
    if (startsWithAny($meaning, ['ก.', 'กริยา'])) return 'CV0011';
    if (startsWithAny($meaning, ['ว.', 'สำนวน', 'สำ.', 'สุภาษิต'])) return 'CV0012';
    return GENERAL_CATEGORY_ID;
}

function sendUpdateBatch(array $assignments): void {
    $multi = curl_multi_init();
    $handles = [];
    foreach ($assignments as [$vocabId, $categoryId]) {
        $url = API_BASE . '/vocabulary_api.php?action=update&id=' . rawurlencode($vocabId);
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => json_encode(
                ['category_vocab_id' => $categoryId],
                JSON_UNESCAPED_UNICODE
            ),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 60,
            CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
        ]);
        curl_multi_add_handle($multi, $ch);
        $handles[] = [$ch, $vocabId];
    }

    do {
        $status = curl_multi_exec($multi, $running);
        if ($running) curl_multi_select($multi, 1.0);
    } while ($running && $status === CURLM_OK);

    $failed = [];
    foreach ($handles as [$ch, $vocabId]) {
        $httpStatus = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $response = curl_multi_getcontent($ch);
        $decoded = json_decode($response, true);
        if ($httpStatus !== 200 || !is_array($decoded) || !empty($decoded['error'])) {
            foreach ($assignments as [$assignedId, $categoryId]) {
                if ($assignedId === $vocabId) {
                    $failed[] = [$vocabId, $categoryId];
                    break;
                }
            }
        }
        curl_multi_remove_handle($multi, $ch);
        curl_close($ch);
    }
    curl_multi_close($multi);

    // การเชื่อมต่อ hosting อาจสะดุดชั่วคราว ลองซ้ำเฉพาะรายการที่ล้มเหลว
    foreach ($failed as [$vocabId, $categoryId]) {
        $success = false;
        for ($attempt = 1; $attempt <= 4 && !$success; $attempt++) {
            $url = API_BASE . '/vocabulary_api.php?action=update&id=' . rawurlencode($vocabId);
            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_POST => true,
                CURLOPT_POSTFIELDS => json_encode(
                    ['category_vocab_id' => $categoryId],
                    JSON_UNESCAPED_UNICODE
                ),
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT => 60,
                CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
            ]);
            $response = curl_exec($ch);
            $httpStatus = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $decoded = json_decode((string)$response, true);
            curl_close($ch);
            $success = $httpStatus === 200 &&
                is_array($decoded) &&
                empty($decoded['error']);
            if (!$success) usleep(500000 * $attempt);
        }
        if (!$success) {
            throw new RuntimeException("อัปเดต $vocabId ไม่สำเร็จหลังลองซ้ำ");
        }
    }
}

$apply = in_array('--apply', $argv, true);
$categories = apiGet(API_BASE . '/category_vocab_api.php?action=getAll');
$validIds = array_fill_keys(array_column($categories, 'category_vocab_id'), true);
if (!isset($validIds[GENERAL_CATEGORY_ID])) {
    throw new RuntimeException('ไม่พบหมวดคำศัพท์ทั่วไป CV0008');
}

$rows = apiGet(API_BASE . '/vocabulary_api.php?action=getAll');
$assignments = [];
$stats = [];
foreach ($rows as $row) {
    $categoryId = classifyVocabulary($row);
    if (!isset($validIds[$categoryId])) $categoryId = GENERAL_CATEGORY_ID;
    $stats[$categoryId] = ($stats[$categoryId] ?? 0) + 1;
    if ((string)($row['category_vocab_id'] ?? '') !== $categoryId) {
        $assignments[] = [(string)$row['vocab_id'], $categoryId];
    }
}

echo 'คำศัพท์ทั้งหมด: ' . count($rows) . PHP_EOL;
echo 'รายการที่จะเปลี่ยนหมวด: ' . count($assignments) . PHP_EOL;
ksort($stats);
foreach ($stats as $categoryId => $count) echo "$categoryId: $count" . PHP_EOL;
if (!$apply) {
    echo 'โหมดตรวจสอบเท่านั้น (ยังไม่ได้แก้ฐานข้อมูล)' . PHP_EOL;
    exit(0);
}

$completed = 0;
foreach (array_chunk($assignments, 20) as $batch) {
    sendUpdateBatch($batch);
    $completed += count($batch);
    echo "อัปเดตแล้ว $completed/" . count($assignments) . PHP_EOL;
}
echo 'อัปเดตหมวดหมู่สำเร็จ' . PHP_EOL;
