<?php
require_once __DIR__ . '/../config/db.php';
$pdo = getPdo();

// Clean up any remaining junk rows
$pdo->exec("DELETE FROM `character_strokes` WHERE `char_name` LIKE '%consonant%' OR `char_symbol` IN ('ผ', 'พ', 'ภ', 'ม', 'ฅ', 'ฝ', 'ฟ', 'ล')");
$pdo->exec("DELETE FROM `lanna_char` WHERE `thai_equivalent` LIKE '%consonant%' OR `lanna_char` IN ('ผ', 'พ', 'ภ', 'ม', 'ฅ', 'ฝ', 'ฟ')");

// Custom desired order of Lanna consonants first
$priorityOrder = [
    // วรรคกะ
    'ᨠ', 'ᨡ', 'ᨣ', 'ᨥ', 'ᨦ',
    // วรรคจะ
    'ᨧ', 'ᨨ', 'ᨩ', 'ᨫ', 'ᨬ',
    // วรรคระต๋ะ / วรรคฏะ
    'ᨭ', 'ᨮ', 'ᨯ', 'ᨰ', 'ᨱ',
    // วรรคต๋ะ
    'ᨲ', 'ᨳ', 'ᨴ', 'ᨵ', 'ᨶ',
    // วรรคป๋ะ
    'ᨷ', 'ᨸ', 'ᨹ', 'ᨻ', 'ᨾ',
    // นอกวรรค 8 ตัวเดิม
    'ᨿ', 'ᩁ', 'ᩃ', 'ᩅ', 'ᩈ', 'ᩉ', 'ᩊ', 'ᩋ',
    // อักษรประดิษฐ์เพิ่ม
    'ᨢ', 'ᨤ', 'ᨪ', 'ᨺ', 'ᨼ', 'ᨽ', 'ᩆ', 'ᩇ', 'ᩌ', 'ᩀ',
    // ห นำ
    'ᩉ᩠ᨦ', 'ᩉ᩠ᨶ', 'ᩉ᩠ᨾ', 'ᩉ᩠ᨿ', 'ᩉ᩠ᩃ', 'ᩉ᩠ᩅ',
    // สระลอย
    'ᩍ', 'ᩎ', 'ᩏ', 'ᩐ', 'ᩑ', 'ᩒ', 'ᩂ', 'ᩄ',
    // สระจม
    'ᩣ', 'ᩤ', 'ᩥ', 'ᩦ', 'ᩧ', 'ᩨ', 'ᩩ', 'ᩪ', 'ᩫ', 'ᩬ', 'ᩭ', 'ᩮ', 'ᩯ', 'ᩰ', 'ᩱ', 'ᩲ', 'ᩡ',
    // วรรณยุกต์
    '᩵', '᩶', '᩷', '᩸', 'ᩴ', '᩺', '᩻', '᩼',
    // เลขในธัมม์
    '᪐', '᪑', '᪒', '᪓', '᪔', '᪕', '᪖', '᪗', '᪘', '᪙',
    // เลขโหรา
    '᪀', '᪁', '᪂', '᪃', '᪄', '᪅', '᪆', '᪇', '᪈', '᪉'
];

// Fetch all rows
$allRows = $pdo->query("SELECT * FROM `character_strokes`")->fetchAll(PDO::FETCH_ASSOC);

usort($allRows, function($a, $b) use ($priorityOrder) {
    $idxA = array_search($a['char_symbol'], $priorityOrder);
    $idxB = array_search($b['char_symbol'], $priorityOrder);
    if ($idxA !== false && $idxB !== false) return $idxA - $idxB;
    if ($idxA !== false) return -1;
    if ($idxB !== false) return 1;
    return strcmp($a['char_symbol'], $b['char_symbol']);
});

$pdo->beginTransaction();
$pdo->exec("CREATE TEMPORARY TABLE `temp_cs` LIKE `character_strokes`");
$pdo->exec("INSERT INTO `temp_cs` SELECT * FROM `character_strokes`");
$pdo->exec("DELETE FROM `character_strokes`");

$counter = 1;
$stmtIns = $pdo->prepare("
    INSERT INTO `character_strokes` 
    (`stroke_id`, `char_symbol`, `char_name`, `category_char_id`, `stroke_count`, `stroke_data`, `created_at`, `updated_at`)
    VALUES (:sid, :sym, :nm, :cat, :cnt, :dt, :c_at, :u_at)
");

foreach ($allRows as $row) {
    $newId = 'S' . str_pad($counter, 5, '0', STR_PAD_LEFT);
    $stmtIns->execute([
        ':sid'  => $newId,
        ':sym'  => $row['char_symbol'],
        ':nm'   => $row['char_name'],
        ':cat'  => $row['category_char_id'],
        ':cnt'  => $row['stroke_count'],
        ':dt'   => $row['stroke_data'],
        ':c_at' => $row['created_at'],
        ':u_at' => $row['updated_at']
    ]);
    $counter++;
}
$pdo->commit();

// Fetch first 20 to verify
$sample = $pdo->query("
    SELECT cs.`stroke_id`, cs.`char_symbol`, cs.`char_name`, cs.`category_char_id`, clc.`name` as category_name
    FROM `character_strokes` cs
    LEFT JOIN `category_lanna_char` clc ON cs.`category_char_id` = clc.`category_char_id`
    ORDER BY CAST(SUBSTRING(cs.`stroke_id`, 2) AS UNSIGNED) ASC
    LIMIT 20
")->fetchAll(PDO::FETCH_ASSOC);

header('Content-Type: application/json; charset=utf-8');
echo json_encode([
    'status' => 'success',
    'total' => count($allRows),
    'first_20' => $sample
], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
