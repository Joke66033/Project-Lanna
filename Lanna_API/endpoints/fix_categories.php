<?php
require_once __DIR__ . '/../config/db.php';
$pdo = getPdo();

// 1. Precise mapping for all 25 Consonants in Vagga (CL0001 พยัญชนะในวรรค)
$vaggaConsonants = [
    // วรรคกะ
    'ᨠ' => 'CL0001', 'ᨡ' => 'CL0001', 'ᨣ' => 'CL0001', 'ᨥ' => 'CL0001', 'ᨦ' => 'CL0001',
    // วรรคจะ
    'ᨧ' => 'CL0001', 'ᨨ' => 'CL0001', 'ᨩ' => 'CL0001', 'ᨫ' => 'CL0001', 'ᨬ' => 'CL0001',
    // วรรคระต๋ะ (วรรคฏะ)
    'ᨭ' => 'CL0001', 'ᨮ' => 'CL0001', 'ᨯ' => 'CL0001', 'ᨰ' => 'CL0001', 'ᨱ' => 'CL0001',
    // วรรคต๋ะ
    'ᨲ' => 'CL0001', 'ᨳ' => 'CL0001', 'ᨴ' => 'CL0001', 'ᨵ' => 'CL0001', 'ᨶ' => 'CL0001',
    // วรรคป๋ะ
    'ᨷ' => 'CL0001', 'ᨸ' => 'CL0001', 'ᨹ' => 'CL0001', 'ᨻ' => 'CL0001', 'ᨾ' => 'CL0001'
];

// 2. Precise mapping for Consonants outside Vagga (CL0002 พยัญชนะนอกวรรค / เศษวรรค และอักษรประดิษฐ์เพิ่ม)
$extraConsonants = [
    // 8 ตัวเดิม
    'ᨿ' => 'CL0002', 'ᩁ' => 'CL0002', 'ᩃ' => 'CL0002', 'ᩅ' => 'CL0002', 
    'ᩈ' => 'CL0002', 'ᩉ' => 'CL0002', 'ᩊ' => 'CL0002', 'ᩋ' => 'CL0002',
    // อักษรประดิษฐ์เพิ่ม
    'ᨢ' => 'CL0002', 'ᨤ' => 'CL0002', 'ᨪ' => 'CL0002', 'ᨺ' => 'CL0002', 
    'ᨼ' => 'CL0002', 'ᨽ' => 'CL0002', 'ᩆ' => 'CL0002', 'ᩇ' => 'CL0002', 
    'ᩌ' => 'CL0002', 'ᩀ' => 'CL0002', 'ᩡ' => 'CL0002',
    // Thai equivalent symbols fallback
    'ล' => 'CL0002', 'ย' => 'CL0002', 'ร' => 'CL0002', 'ว' => 'CL0002', 'ส' => 'CL0002',
    'ห' => 'CL0002', 'ฬ' => 'CL0002', 'อ' => 'CL0002', 'ฃ' => 'CL0002', 'ฅ' => 'CL0002',
    'ซ' => 'CL0002', 'ฝ' => 'CL0002', 'ฟ' => 'CL0002', 'ฮ' => 'CL0002'
];

// 3. Precise mapping for Consonants with Ho Nam / Compound (CL0003 พยัญชนะเพิ่มเติม)
$hoNamConsonants = [
    'ᩉ᩠ᨦ' => 'CL0003', 'ᩉ᩠ᨶ' => 'CL0003', 'ᩉ᩠ᨾ' => 'CL0003', 
    'ᩉ᩠ᨿ' => 'CL0003', 'ᩉ᩠ᩃ' => 'CL0003', 'ᩉ᩠ᩅ' => 'CL0003',
    'ᩋ᩠ᨿ' => 'CL0003'
];

// 4. Standalone Vowels (CL0004 สระลอย / สระหลวง)
$floatVowels = [
    'ᩐ' => 'CL0004', 'ᩑ' => 'CL0004', 'ᩒ' => 'CL0004', 'ᩓ' => 'CL0004', 
    'ᩔ' => 'CL0004', 'ᩕ' => 'CL0004', 'ᩖ' => 'CL0004', 'ᩗ' => 'CL0004',
    'ᩏ' => 'CL0004'
];

// 5. Dependent Vowels (CL0005 สระจม / สระหน้อย)
$attachedVowels = [
    'ᩣ' => 'CL0005', 'ᩤ' => 'CL0005', 'ᩥ' => 'CL0005', 'ᩦ' => 'CL0005', 
    'ᩧ' => 'CL0005', 'ᩨ' => 'CL0005', 'ᩩ' => 'CL0005', 'ᩪ' => 'CL0005', 
    'ᩫ' => 'CL0005', 'ᩬ' => 'CL0005', 'ᩭ' => 'CL0005', 'ᩮ' => 'CL0005', 
    'ᩯ' => 'CL0005', 'ᩰ' => 'CL0005', 'ᩱ' => 'CL0005', 'ᩲ' => 'CL0005'
];

// 6. Tone Marks & Special Signs (CL0006 วรรณยุกต์)
$toneMarks = [
    '᩵' => 'CL0006', '᩶' => 'CL0006', '᩷' => 'CL0006', '᩸' => 'CL0006', 
    'ᩴ' => 'CL0006', '᩺' => 'CL0006', '᩻' => 'CL0006', '᩼' => 'CL0006',
    '\u1a75' => 'CL0006', '\u1a76' => 'CL0006', '\u1a77' => 'CL0006', 
    '\u1a78' => 'CL0006', '\u1a79' => 'CL0006', '\u1a7a' => 'CL0006',
    '\u1a7b' => 'CL0006', '\u1a7c' => 'CL0006', '\u1a74' => 'CL0006',
    '\u1a7f' => 'CL0006', '\u1a53' => 'CL0006', '\u1a62' => 'CL0006'
];

// 7. Tham Digits (CL0007 เลขในธัมม์)
$thamDigits = [
    '᪐' => 'CL0007', '᪑' => 'CL0007', '᪒' => 'CL0007', '᪓' => 'CL0007', 
    '᪔' => 'CL0007', '᪕' => 'CL0007', '᪖' => 'CL0007', '᪗' => 'CL0007', 
    '᪘' => 'CL0007', '᪙' => 'CL0007'
];

// 8. Hora Digits (CL0014 เลขโหรา)
$horaDigits = [
    '᪀' => 'CL0014', '᪁' => 'CL0014', '᪂' => 'CL0014', '᪃' => 'CL0014', 
    '᪄' => 'CL0014', '᪅' => 'CL0014', '᪆' => 'CL0014', '᪇' => 'CL0014', 
    '᪈' => 'CL0014', '᪉' => 'CL0014'
];

$allMaps = array_merge(
    $vaggaConsonants,
    $extraConsonants,
    $hoNamConsonants,
    $floatVowels,
    $attachedVowels,
    $toneMarks,
    $thamDigits,
    $horaDigits
);

$stmtUpCS = $pdo->prepare("UPDATE `character_strokes` SET `category_char_id` = :cat WHERE `char_symbol` = :sym");
$stmtUpLC = $pdo->prepare("UPDATE `lanna_char` SET `category_char_id` = :cat WHERE `lanna_char` = :sym");

foreach ($allMaps as $sym => $cat) {
    $stmtUpCS->execute([':cat' => $cat, ':sym' => $sym]);
    $stmtUpLC->execute([':cat' => $cat, ':sym' => $sym]);
}

$nameMap = [
    'หงะ' => 'CL0003', 'หนะ' => 'CL0003', 'หมะ' => 'CL0003', 'หยะ' => 'CL0003', 'หละ' => 'CL0003', 'หวะ' => 'CL0003',
    'ไม้เอก' => 'CL0006', 'ไม้โท' => 'CL0006', 'ไม้ซัด' => 'CL0006', 'ไม้ก๋างต๋น' => 'CL0006',
    'ขะหางยาว' => 'CL0002', 'ฅะ' => 'CL0002', 'ซะ' => 'CL0002', 'ฝะ' => 'CL0002', 'ฟะ' => 'CL0002', 'ศะ' => 'CL0002', 'ษะ' => 'CL0002', 'ฮะ' => 'CL0002',
    'ละ' => 'CL0002', 'ระ' => 'CL0002', 'ยะ' => 'CL0002', 'วะ' => 'CL0002', 'สะ' => 'CL0002', 'หะ' => 'CL0002', 'ฬะ' => 'CL0002', 'อะ' => 'CL0002'
];

foreach ($nameMap as $nm => $cat) {
    $pdo->prepare("UPDATE `character_strokes` SET `category_char_id` = :cat WHERE `char_name` LIKE :nm AND `category_char_id` = 'CL0001'")
        ->execute([':cat' => $cat, ':nm' => "%$nm%"]);
    $pdo->prepare("UPDATE `lanna_char` SET `category_char_id` = :cat WHERE `thai_equivalent` LIKE :nm AND `category_char_id` = 'CL0001'")
        ->execute([':cat' => $cat, ':nm' => "%$nm%"]);
}

// S00194 specifically
$pdo->exec("UPDATE `character_strokes` SET `category_char_id` = 'CL0002' WHERE `stroke_id` = 'S00194'");
$pdo->exec("UPDATE `lanna_char` SET `category_char_id` = 'CL0002' WHERE `lanna_char` = 'ล' OR `thai_equivalent` = 'ละ'");

$csBreakdown = $pdo->query("SELECT `category_char_id`, COUNT(*) as cnt FROM `character_strokes` GROUP BY `category_char_id`")->fetchAll(PDO::FETCH_ASSOC);
$lcBreakdown = $pdo->query("SELECT `category_char_id`, COUNT(*) as cnt FROM `lanna_char` GROUP BY `category_char_id`")->fetchAll(PDO::FETCH_ASSOC);

header('Content-Type: application/json; charset=utf-8');
echo json_encode([
    'status' => 'success',
    'cs_breakdown' => $csBreakdown,
    'lc_breakdown' => $lcBreakdown
], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
