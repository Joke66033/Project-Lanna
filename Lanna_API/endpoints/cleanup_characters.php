<?php
/**
 * cleanup_characters.php
 * Cleans up duplicate, corrupted unicode strings, and fixes character names across all categories.
 */

require_once __DIR__ . '/../config/db.php';
setCorsHeaders();

$pdo = getPdo();
$results = [];

try {
    // 1. Delete corrupted literal backslash entries
    $deletedLiteralLC = $pdo->exec("DELETE FROM `lanna_char` WHERE `lanna_char` LIKE '%\\\\u%' OR `char_id` IN ('V202','V203','V204','V205','V206','V207','V208','V209','V210','V211','V212')");
    $deletedLiteralCS = $pdo->exec("DELETE FROM `character_strokes` WHERE `char_symbol` LIKE '%\\\\u%' OR `stroke_id` IN ('S00102','S00103','S00104','S00105','S00106','S00107','S00108','S00109','S00110','S00111','S00112')");
    $results['deleted_literal_backslash_lanna_char'] = $deletedLiteralLC;
    $results['deleted_literal_backslash_strokes'] = $deletedLiteralCS;

    // 2. Delete invalid tofu entries (U+1A7D, U+1A7E)
    $deletedTofuLC = $pdo->exec("DELETE FROM `lanna_char` WHERE `char_id` IN ('V158','V159') OR `lanna_char` IN (UNHEX('E1A9BD'), UNHEX('E1A9BE'))");
    $deletedTofuCS = $pdo->exec("DELETE FROM `character_strokes` WHERE `stroke_id` IN ('S00162','S00163') OR `char_symbol` IN (UNHEX('E1A9BD'), UNHEX('E1A9BE'))");
    $results['deleted_tofu_lanna_char'] = $deletedTofuLC;
    $results['deleted_tofu_strokes'] = $deletedTofuCS;

    // 3. Delete duplicates
    // V107 (duplicate U+1A80 in CL0014)
    $pdo->exec("DELETE FROM `lanna_char` WHERE `char_id` = 'V107'");
    // V189 (duplicate ᨷ᩠ᩁ in CL0010)
    $pdo->exec("DELETE FROM `lanna_char` WHERE `char_id` = 'V189'");

    // 4. Tone Marks standard dictionary (CL0006)
    $tones = [
        '᩵' => ['name' => 'ไม้เหยาะ (ไม้เอก)', 'cat' => 'CL0006'],
        '᩶' => ['name' => 'ไม้ขอช้าง (ไม้โท)', 'cat' => 'CL0006'],
        '᩷' => ['name' => 'ไม้ตรี', 'cat' => 'CL0006'],
        '᩸' => ['name' => 'ไม้จัตวา', 'cat' => 'CL0006'],
        '᩹' => ['name' => 'ไม้ซัด', 'cat' => 'CL0006'],
        '᩺' => ['name' => 'ไม้ระห้าม (ไม้ฆ่า)', 'cat' => 'CL0006'],
        '᩻' => ['name' => 'ไม้ซ้ำ (ไม้ยมก)', 'cat' => 'CL0006'],
        '᩼' => ['name' => 'ไม้การันต์ (ขึน-ลื้อ)', 'cat' => 'CL0006'],
    ];

    $stmtLC = $pdo->prepare("UPDATE `lanna_char` SET `thai_equivalent` = :th, `category_char_id` = :cat WHERE `lanna_char` = :sym");
    $stmtCS = $pdo->prepare("UPDATE `character_strokes` SET `char_name` = :th, `category_char_id` = :cat WHERE `char_symbol` = :sym");

    foreach ($tones as $sym => $meta) {
        $stmtLC->execute([':th' => $meta['name'], ':cat' => $meta['cat'], ':sym' => $sym]);
        $stmtCS->execute([':th' => $meta['name'], ':cat' => $meta['cat'], ':sym' => $sym]);
    }

    // 5. Vowels standard dictionary (CL0005)
    $vowels = [
        'ᩡ' => ['name' => 'สระอะ', 'cat' => 'CL0005'],
        'ᩢ' => ['name' => 'ไม้กัก (ไม้หันอากาศ)', 'cat' => 'CL0005'],
        'ᩣ' => ['name' => 'สระอา', 'cat' => 'CL0005'],
        'ᩤ' => ['name' => 'สระอาหาง', 'cat' => 'CL0005'],
        'ᩥ' => ['name' => 'สระอิ', 'cat' => 'CL0005'],
        'ᩦ' => ['name' => 'สระอี', 'cat' => 'CL0005'],
        'ᩧ' => ['name' => 'สระอึ', 'cat' => 'CL0005'],
        'ᩨ' => ['name' => 'สระอือ', 'cat' => 'CL0005'],
        'ᩩ' => ['name' => 'สระอุ', 'cat' => 'CL0005'],
        'ᩪ' => ['name' => 'สระอู', 'cat' => 'CL0005'],
        'ᩫ' => ['name' => 'ไม้โก๊ะ (สระโอะ)', 'cat' => 'CL0005'],
        'ᩬ' => ['name' => 'สระออ', 'cat' => 'CL0005'],
        'ᩭ' => ['name' => 'สระออย', 'cat' => 'CL0005'],
        'ᩮ' => ['name' => 'สระเอ', 'cat' => 'CL0005'],
        'ᩯ' => ['name' => 'สระแอ', 'cat' => 'CL0005'],
        'ᩰ' => ['name' => 'สระโอ', 'cat' => 'CL0005'],
        'ᩱ' => ['name' => 'สระใอ (ไม้ม้วน)', 'cat' => 'CL0005'],
        'ᩲ' => ['name' => 'สระไอ (ไม้มลาย)', 'cat' => 'CL0005'],
        'ᩳ' => ['name' => 'สระอัวะ (สระอึหน้อย)', 'cat' => 'CL0005'],
        'ᩴ' => ['name' => 'ไม้กัง (หยาดน้ำค้าง)', 'cat' => 'CL0005'],
        '᩠' => ['name' => 'ไม้ซ้อน (พยัญชนะซ้อน)', 'cat' => 'CL0005'],
    ];

    foreach ($vowels as $sym => $meta) {
        $stmtLC->execute([':th' => $meta['name'], ':cat' => $meta['cat'], ':sym' => $sym]);
        $stmtCS->execute([':th' => $meta['name'], ':cat' => $meta['cat'], ':sym' => $sym]);
    }

    // 6. Numbers Hora (CL0014)
    $numbersHora = [
        '᪀' => '๐ (ศูนย์)',
        '᪁' => '๑ (หนึ่ง)',
        '᪂' => '๒ (สอง)',
        '᪃' => '๓ (สาม)',
        '᪄' => '๔ (สี่)',
        '᪅' => '๕ (ห้า)',
        '᪆' => '๖ (หก)',
        '᪇' => '๗ (เจ็ด)',
        '᪈' => '๘ (แปด)',
        '᪉' => '๙ (เก้า)',
    ];
    foreach ($numbersHora as $sym => $name) {
        $stmtLC->execute([':th' => $name, ':cat' => 'CL0014', ':sym' => $sym]);
        $stmtCS->execute([':th' => $name, ':cat' => 'CL0014', ':sym' => $sym]);
    }

    // 7. Numbers Tham (CL0007)
    $numbersTham = [
        '᪐' => '᪐ (ศูนย์ธัมม์)',
        '᪑' => '᪑ (หนึ่งธัมม์)',
        '᪒' => '᪒ (สองธัมม์)',
        '᪓' => '᪓ (สามธัมม์)',
        '᪔' => '᪔ (สี่ธัมม์)',
        '᪕' => '᪕ (ห้าธัมม์)',
        '᪖' => '᪖ (หกธัมม์)',
        '᪗' => '᪗ (เจ็ดธัมม์)',
        '᪘' => '᪘ (แปดธัมม์)',
        '᪙' => '᪙ (เก้าธัมม์)',
    ];
    foreach ($numbersTham as $sym => $name) {
        $stmtLC->execute([':th' => $name, ':cat' => 'CL0007', ':sym' => $sym]);
        $stmtCS->execute([':th' => $name, ':cat' => 'CL0007', ':sym' => $sym]);
    }

    $results['status'] = 'success';
    $results['message'] = 'Database cleanup and standardization completed successfully!';
    jsonOk($results);
} catch (Exception $e) {
    jsonError($e->getMessage(), 500);
}
