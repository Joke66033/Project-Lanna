<?php
require_once __DIR__ . '/../config/db.php';
$pdo = getPdo();

// 1. EXACT 25 Consonants in Vagga (CL0001)
$vagga25 = [
    // วรรคกะ
    'ᨠ' => ['th' => 'ก (ก๋ะ)', 'cat' => 'CL0001'],
    'ᨡ' => ['th' => 'ข (ข๋ะ)', 'cat' => 'CL0001'],
    'ᨣ' => ['th' => 'ค (ก๊ะ/คะ)', 'cat' => 'CL0001'],
    'ᨥ' => ['th' => 'ฆ (ฆะ/คะ)', 'cat' => 'CL0001'],
    'ᨦ' => ['th' => 'ง (งะ)', 'cat' => 'CL0001'],
    // วรรคจะ
    'ᨧ' => ['th' => 'จ (จ๋ะ)', 'cat' => 'CL0001'],
    'ᨨ' => ['th' => 'ฉ (ส้ะ/ฉะ)', 'cat' => 'CL0001'],
    'ᨩ' => ['th' => 'ช (จ๊ะ/ชะ)', 'cat' => 'CL0001'],
    'ᨫ' => ['th' => 'ฌ (ฌะ/ซะ)', 'cat' => 'CL0001'],
    'ᨬ' => ['th' => 'ญ (ญะ)', 'cat' => 'CL0001'],
    // วรรคระต๋ะ / วรรคฏะ
    'ᨭ' => ['th' => 'ฏ (ระต๊ะ/ฏะ)', 'cat' => 'CL0001'],
    'ᨮ' => ['th' => 'ฐ (ระถะ/ฐะ)', 'cat' => 'CL0001'],
    'ᨯ' => ['th' => 'ฑ (ระทะ/ดะ)', 'cat' => 'CL0001'],
    'ᨰ' => ['th' => 'ฒ (ระทะ/ฒะ)', 'cat' => 'CL0001'],
    'ᨱ' => ['th' => 'ณ (ระนะ/ณะ)', 'cat' => 'CL0001'],
    // วรรคต๋ะ
    'ᨲ' => ['th' => 'ต (ต๋ะ)', 'cat' => 'CL0001'],
    'ᨳ' => ['th' => 'ถ (ถ๋ะ/ถะ)', 'cat' => 'CL0001'],
    'ᨴ' => ['th' => 'ท (ต๊ะ/ทะ)', 'cat' => 'CL0001'],
    'ᨵ' => ['th' => 'ธ (ธะ/ทะ)', 'cat' => 'CL0001'],
    'ᨶ' => ['th' => 'น (นะ)', 'cat' => 'CL0001'],
    // วรรคป๋ะ
    'ᨷ' => ['th' => 'บ (บ๋ะ)', 'cat' => 'CL0001'],
    'ᨸ' => ['th' => 'ป (ป๋ะ)', 'cat' => 'CL0001'],
    'ᨹ' => ['th' => 'ผ (ผ๋ะ/ผะ)', 'cat' => 'CL0001'],
    'ᨻ' => ['th' => 'พ (ป๊ะ/พะ)', 'cat' => 'CL0001'],
    'ᨾ' => ['th' => 'ม (มะ)', 'cat' => 'CL0001'],
];

// 2. Consonants Outside Vagga (CL0002)
$extraConsonants = [
    // 8 ตัวเดิม
    'ᨿ' => ['th' => 'ย (ยะ)', 'cat' => 'CL0002'],
    'ᩁ' => ['th' => 'ร (ระ)', 'cat' => 'CL0002'],
    'ᩃ' => ['th' => 'ล (ละ)', 'cat' => 'CL0002'],
    'ᩅ' => ['th' => 'ว (วะ)', 'cat' => 'CL0002'],
    'ᩈ' => ['th' => 'ส (สะ/ส๋ะ)', 'cat' => 'CL0002'],
    'ᩉ' => ['th' => 'ห (หะ/ห๋ะ)', 'cat' => 'CL0002'],
    'ᩊ' => ['th' => 'ฬ (ฬะ)', 'cat' => 'CL0002'],
    'ᩋ' => ['th' => 'อ (อ๋ะ/อะ)', 'cat' => 'CL0002'],
    // 11 ตัวประดิษฐ์เพิ่ม
    'ᨢ' => ['th' => 'ฃ (ขะหางยาว)', 'cat' => 'CL0002'],
    'ᨤ' => ['th' => 'ฅ (ฅะ)', 'cat' => 'CL0002'],
    'ᨪ' => ['th' => 'ซ (ซะ)', 'cat' => 'CL0002'],
    'ᨺ' => ['th' => 'ฝ (ฝะ)', 'cat' => 'CL0002'],
    'ᨼ' => ['th' => 'ฟ (ฟะ)', 'cat' => 'CL0002'],
    'ᨽ' => ['th' => 'ภ (พ๊ะ/ภะ)', 'cat' => 'CL0002'],
    'ᩆ' => ['th' => 'ศ (ศะ)', 'cat' => 'CL0002'],
    'ᩇ' => ['th' => 'ษ (ษะ)', 'cat' => 'CL0002'],
    'ᩌ' => ['th' => 'ฮ (ฮะ)', 'cat' => 'CL0002'],
    'ᩀ' => ['th' => 'อย (ย่า/อย)', 'cat' => 'CL0002'],
    'ล' => ['th' => 'ล (ละ)', 'cat' => 'CL0002']
];

// 3. Additional Consonants / Ho Nam (CL0003)
$hoNamConsonants = [
    'ᩉ᩠ᨦ' => ['th' => 'หง (หงะ)', 'cat' => 'CL0003'],
    'ᩉ᩠ᨶ' => ['th' => 'หน (หนะ)', 'cat' => 'CL0003'],
    'ᩉ᩠ᨾ' => ['th' => 'หม (หมะ)', 'cat' => 'CL0003'],
    'ᩉ᩠ᨿ' => ['th' => 'หย (หยะ)', 'cat' => 'CL0003'],
    'ᩉ᩠ᩃ' => ['th' => 'หล (หละ)', 'cat' => 'CL0003'],
    'ᩉ᩠ᩅ' => ['th' => 'หว (หวะ)', 'cat' => 'CL0003'],
];

// 4. Clean up special characters to correct categories
$otherMoves = [
    'ᩂ' => 'CL0004', // ฤ -> สระลอย
    'ᩄ' => 'CL0004', // ฦ -> สระลอย
    'ᩡ' => 'CL0005', // สระอะ -> สระจม
];

// Reset & assign precise categories
$stmtUpCS = $pdo->prepare("UPDATE `character_strokes` SET `category_char_id` = :cat, `char_name` = COALESCE(:th, `char_name`) WHERE `char_symbol` = :sym");
$stmtUpLC = $pdo->prepare("UPDATE `lanna_char` SET `category_char_id` = :cat, `thai_equivalent` = COALESCE(:th, `thai_equivalent`) WHERE `lanna_char` = :sym");

foreach ($vagga25 as $sym => $info) {
    $stmtUpCS->execute([':cat' => $info['cat'], ':th' => $info['th'], ':sym' => $sym]);
    $stmtUpLC->execute([':cat' => $info['cat'], ':th' => $info['th'], ':sym' => $sym]);
}

foreach ($extraConsonants as $sym => $info) {
    $stmtUpCS->execute([':cat' => $info['cat'], ':th' => $info['th'], ':sym' => $sym]);
    $stmtUpLC->execute([':cat' => $info['cat'], ':th' => $info['th'], ':sym' => $sym]);
}

foreach ($hoNamConsonants as $sym => $info) {
    $stmtUpCS->execute([':cat' => $info['cat'], ':th' => $info['th'], ':sym' => $sym]);
    $stmtUpLC->execute([':cat' => $info['cat'], ':th' => $info['th'], ':sym' => $sym]);
}

foreach ($otherMoves as $sym => $cat) {
    $pdo->prepare("UPDATE `character_strokes` SET `category_char_id` = :cat WHERE `char_symbol` = :sym")->execute([':cat' => $cat, ':sym' => $sym]);
    $pdo->prepare("UPDATE `lanna_char` SET `category_char_id` = :cat WHERE `lanna_char` = :sym")->execute([':cat' => $cat, ':sym' => $sym]);
}

// Move any non-consonant in CL0001 to other
$pdo->exec("UPDATE `lanna_char` SET `category_char_id` = 'CL0011' WHERE `category_char_id` = 'CL0001' AND `lanna_char` NOT IN ('" . implode("','", array_keys($vagga25)) . "')");
$pdo->exec("UPDATE `character_strokes` SET `category_char_id` = 'CL0011' WHERE `category_char_id` = 'CL0001' AND `char_symbol` NOT IN ('" . implode("','", array_keys($vagga25)) . "')");

// Output clean results
$cl0001 = $pdo->query("SELECT `char_id`, `lanna_char`, `thai_equivalent` FROM `lanna_char` WHERE `category_char_id` = 'CL0001' ORDER BY `char_id` ASC")->fetchAll(PDO::FETCH_ASSOC);
$cl0002 = $pdo->query("SELECT `char_id`, `lanna_char`, `thai_equivalent` FROM `lanna_char` WHERE `category_char_id` = 'CL0002' ORDER BY `char_id` ASC")->fetchAll(PDO::FETCH_ASSOC);
$cl0003 = $pdo->query("SELECT `char_id`, `lanna_char`, `thai_equivalent` FROM `lanna_char` WHERE `category_char_id` = 'CL0003' ORDER BY `char_id` ASC")->fetchAll(PDO::FETCH_ASSOC);

header('Content-Type: application/json; charset=utf-8');
echo json_encode([
    'status' => 'success',
    'cl0001_count' => count($cl0001),
    'cl0001_items' => $cl0001,
    'cl0002_count' => count($cl0002),
    'cl0002_items' => $cl0002,
    'cl0003_count' => count($cl0003),
    'cl0003_items' => $cl0003,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
