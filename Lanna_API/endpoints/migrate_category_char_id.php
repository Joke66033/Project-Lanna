<?php
require_once __DIR__ . '/../config/db.php';
$pdo = getPdo();

$legacyMap = [
    'consonant' => 'CL0001',
    'vowel'     => 'CL0005',
    'tone'      => 'CL0006',
    'tone_mark' => 'CL0006',
    'number'    => 'CL0007',
    'sequence'  => 'CL0010',
    'other'     => 'CL0011'
];

$output = [];

// 1. Check columns of character_strokes
$cols = $pdo->query("DESCRIBE `character_strokes`")->fetchAll(PDO::FETCH_ASSOC);
$colNames = array_column($cols, 'Field');
$output['initial_columns'] = $colNames;

// 2. Map existing data in character_strokes to valid category_char_id
if (in_array('category', $colNames)) {
    $stmtSyncFromLC = $pdo->exec("
        UPDATE `character_strokes` cs
        INNER JOIN `lanna_char` lc ON cs.`char_symbol` = lc.`lanna_char`
        SET cs.`category` = lc.`category_char_id`
        WHERE lc.`category_char_id` IS NOT NULL AND lc.`category_char_id` != ''
    ");
    $output['updated_from_lanna_char'] = $stmtSyncFromLC;

    foreach ($legacyMap as $oldCat => $newCat) {
        $stmt = $pdo->prepare("UPDATE `character_strokes` SET `category` = :newCat WHERE LOWER(`category`) = :oldCat");
        $stmt->execute([':newCat' => $newCat, ':oldCat' => $oldCat]);
    }

    $pdo->exec("UPDATE `character_strokes` SET `category` = 'CL0001' WHERE `category` IS NULL OR `category` = '' OR `category` NOT IN (SELECT `category_char_id` FROM `category_lanna_char`)");
}

// 3. Rename column `category` to `category_char_id`
if (in_array('category', $colNames) && !in_array('category_char_id', $colNames)) {
    $pdo->exec("ALTER TABLE `character_strokes` CHANGE `category` `category_char_id` VARCHAR(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'CL0001'");
    $output['alter_action'] = 'Renamed category to category_char_id';
} elseif (in_array('category', $colNames) && in_array('category_char_id', $colNames)) {
    $pdo->exec("UPDATE `character_strokes` SET `category_char_id` = `category` WHERE `category_char_id` IS NULL OR `category_char_id` = ''");
    $pdo->exec("ALTER TABLE `character_strokes` DROP COLUMN `category`");
    $output['alter_action'] = 'Copied to category_char_id and dropped category';
}

// 4. Add index
try {
    $pdo->exec("ALTER TABLE `character_strokes` ADD INDEX `idx_cs_category_char_id` (`category_char_id`)");
} catch (Exception $e) {
    // index might already exist
}

// 5. Verify columns and sample data
$colsAfter = $pdo->query("DESCRIBE `character_strokes`")->fetchAll(PDO::FETCH_ASSOC);
$output['after_columns'] = array_column($colsAfter, 'Field');

$sample = $pdo->query("
    SELECT 
        cs.`stroke_id`, 
        cs.`char_symbol`, 
        cs.`char_name`, 
        cs.`category_char_id`, 
        clc.`name` AS `category_name`,
        clc.`learning_category_code`
    FROM `character_strokes` cs
    LEFT JOIN `category_lanna_char` clc ON cs.`category_char_id` = clc.`category_char_id`
    LIMIT 10
")->fetchAll(PDO::FETCH_ASSOC);
$output['sample_data'] = $sample;

header('Content-Type: application/json; charset=utf-8');
echo json_encode($output, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
