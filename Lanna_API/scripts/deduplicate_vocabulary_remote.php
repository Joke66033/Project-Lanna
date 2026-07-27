<?php
/**
 * ลบคำศัพท์ซ้ำแบบข้อมูลตรงกันทุกช่อง โดยเก็บ vocab_id ที่เก่าที่สุดไว้
 * และย้ายรายการโปรดไปยังรายการหลักก่อนลบ
 *
 * Preview: php deduplicate_vocabulary_remote.php
 * Apply:   php deduplicate_vocabulary_remote.php --apply
 */

const API_BASE = 'https://siripaporn.lnw.mn/endpoints';

function requestJson(string $url, ?array $body = null): array {
    $lastError = '';
    for ($attempt = 1; $attempt <= 4; $attempt++) {
        $ch = curl_init($url);
        $options = [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 90,
            CURLOPT_HTTPHEADER => ['Accept: application/json'],
        ];
        if ($body !== null) {
            $options[CURLOPT_POST] = true;
            $options[CURLOPT_POSTFIELDS] = json_encode($body, JSON_UNESCAPED_UNICODE);
            $options[CURLOPT_HTTPHEADER][] = 'Content-Type: application/json';
        }
        curl_setopt_array($ch, $options);
        $response = curl_exec($ch);
        $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $lastError = curl_error($ch);
        curl_close($ch);
        $decoded = json_decode((string)$response, true);
        if ($status === 200 && is_array($decoded) && empty($decoded['error'])) {
            return $decoded['data'] ?? [];
        }
        usleep(400000 * $attempt);
    }
    throw new RuntimeException("เรียก API ไม่สำเร็จ: $url ($lastError)");
}

function normalizedValue($value): string {
    $value = trim((string)$value);
    $value = preg_replace('/\s+/u', ' ', $value) ?? $value;
    return mb_strtolower($value, 'UTF-8');
}

function duplicateKey(array $row): string {
    // category ถูกนับรวมด้วย เพื่อไม่รวมคำที่ตั้งใจแยกหมวดเข้าด้วยกัน
    $parts = [
        normalizedValue($row['thai_word'] ?? ''),
        normalizedValue($row['lanna_word'] ?? ''),
        normalizedValue($row['reading'] ?? ''),
        normalizedValue($row['meaning'] ?? ''),
        normalizedValue($row['category_vocab_id'] ?? ''),
    ];
    return hash('sha256', implode("\x1F", $parts));
}

function idNumber(string $id): int {
    return (int)preg_replace('/\D+/', '', $id);
}

$apply = in_array('--apply', $argv, true);
$vocabulary = requestJson(API_BASE . '/vocabulary_api.php?action=getAll');
$favorites = requestJson(API_BASE . '/favorites_api.php?action=getAll');

$groups = [];
foreach ($vocabulary as $row) {
    $groups[duplicateKey($row)][] = $row;
}

$duplicateGroups = [];
$deleteIds = [];
$keeperByDeletedId = [];
foreach ($groups as $rows) {
    if (count($rows) < 2) continue;
    usort($rows, fn($a, $b) =>
        idNumber((string)$a['vocab_id']) <=> idNumber((string)$b['vocab_id'])
    );
    $keeperId = (string)$rows[0]['vocab_id'];
    $duplicateGroups[] = $rows;
    foreach (array_slice($rows, 1) as $duplicate) {
        $duplicateId = (string)$duplicate['vocab_id'];
        $deleteIds[] = $duplicateId;
        $keeperByDeletedId[$duplicateId] = $keeperId;
    }
}

$favoriteMigrations = [];
$favoriteDeletes = [];
$favoriteByUserAndVocab = [];
foreach ($favorites as $favorite) {
    $key = (string)($favorite['user_id'] ?? '') . "\x1F" .
        (string)($favorite['vocab_id'] ?? '');
    $favoriteByUserAndVocab[$key] = $favorite;
}
foreach ($favorites as $favorite) {
    $oldVocabId = (string)($favorite['vocab_id'] ?? '');
    if (!isset($keeperByDeletedId[$oldVocabId])) continue;
    $keeperId = $keeperByDeletedId[$oldVocabId];
    $existingKey = (string)($favorite['user_id'] ?? '') . "\x1F" . $keeperId;
    if (isset($favoriteByUserAndVocab[$existingKey])) {
        $favoriteDeletes[] = (string)$favorite['favorite_id'];
    } else {
        $favoriteMigrations[] = [
            (string)$favorite['favorite_id'],
            $keeperId,
        ];
        $favoriteByUserAndVocab[$existingKey] = $favorite;
    }
}

echo 'คำศัพท์ทั้งหมด: ' . count($vocabulary) . PHP_EOL;
echo 'กลุ่มคำซ้ำ: ' . count($duplicateGroups) . PHP_EOL;
echo 'รายการคำศัพท์ที่จะลบ: ' . count($deleteIds) . PHP_EOL;
echo 'รายการโปรดที่จะย้าย: ' . count($favoriteMigrations) . PHP_EOL;
echo 'รายการโปรดซ้ำที่จะรวม: ' . count($favoriteDeletes) . PHP_EOL;

foreach (array_slice($duplicateGroups, 0, 10) as $rows) {
    $ids = array_column($rows, 'vocab_id');
    echo implode(', ', $ids) . ' — ' . ($rows[0]['thai_word'] ?? '') . PHP_EOL;
}
if (count($duplicateGroups) > 10) {
    echo '... และอีก ' . (count($duplicateGroups) - 10) . ' กลุ่ม' . PHP_EOL;
}

if (!$apply) {
    echo 'โหมดตรวจสอบเท่านั้น (ยังไม่ได้ลบข้อมูล)' . PHP_EOL;
    exit(0);
}

// เก็บ snapshot เฉพาะรายการที่จะเปลี่ยนไว้กู้คืนได้
$backupRows = array_values(array_filter(
    $vocabulary,
    fn($row) => in_array((string)$row['vocab_id'], $deleteIds, true)
));
$backup = [
    'created_at' => date(DATE_ATOM),
    'deleted_vocabulary' => $backupRows,
    'affected_favorites' => array_values(array_filter(
        $favorites,
        fn($row) =>
            in_array((string)$row['favorite_id'], $favoriteDeletes, true) ||
            in_array(
                (string)$row['favorite_id'],
                array_column($favoriteMigrations, 0),
                true
            )
    )),
];
$backupPath = __DIR__ . '/vocabulary_dedup_backup_' . date('Ymd_His') . '.json';
file_put_contents(
    $backupPath,
    json_encode($backup, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)
);
echo "สำรองข้อมูลไว้ที่ $backupPath" . PHP_EOL;

foreach ($favoriteMigrations as [$favoriteId, $keeperId]) {
    requestJson(
        API_BASE . '/favorites_api.php?action=update&id=' . rawurlencode($favoriteId),
        ['vocab_id' => $keeperId]
    );
}
foreach ($favoriteDeletes as $favoriteId) {
    requestJson(
        API_BASE . '/favorites_api.php?action=delete&id=' . rawurlencode($favoriteId),
        []
    );
}

$deleted = 0;
foreach ($deleteIds as $vocabId) {
    requestJson(
        API_BASE . '/vocabulary_api.php?action=delete&id=' . rawurlencode($vocabId),
        []
    );
    $deleted++;
    if ($deleted % 100 === 0 || $deleted === count($deleteIds)) {
        echo "ลบแล้ว $deleted/" . count($deleteIds) . PHP_EOL;
    }
}
echo 'ลบคำศัพท์ซ้ำสำเร็จ' . PHP_EOL;
