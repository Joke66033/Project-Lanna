<?php
require_once __DIR__ . '/../config/db.php';
$pdo = getPdo();

// 1. Delete duplicate placeholder rows with raw Thai letters
$junkStrokes = ['S00176', 'S00177', 'S00178', 'S00179', 'S00180', 'S00181', 'S00182', 'S00194'];
$junkChars = ['ฅ', 'ผ', 'ฝ', 'พ', 'ฟ', 'ภ', 'ม', 'ล'];

$stmtDelCS = $pdo->prepare("DELETE FROM `character_strokes` WHERE `stroke_id` IN ('" . implode("','", $junkStrokes) . "') OR (`char_symbol` IN ('" . implode("','", $junkChars) . "') AND `stroke_id` > 'S00150')");
$stmtDelCS->execute();
$deletedCS = $stmtDelCS->rowCount();

$stmtDelLC = $pdo->prepare("DELETE FROM `lanna_char` WHERE `lanna_char` IN ('" . implode("','", $junkChars) . "') AND `char_id` > 'V150'");
$stmtDelLC->execute();
$deletedLC = $stmtDelLC->rowCount();

// 2. Fetch clean list of all character strokes
$sql = "SELECT 
            cs.`stroke_id`, 
            cs.`char_symbol`, 
            cs.`char_name`, 
            cs.`category_char_id`, 
            clc.`name` AS `category_name`,
            clc.`learning_category_code`
        FROM `character_strokes` cs
        LEFT JOIN `category_lanna_char` clc ON cs.`category_char_id` = clc.`category_char_id`
        ORDER BY CAST(SUBSTRING(cs.`stroke_id`, 2) AS UNSIGNED) ASC";

$stmt = $pdo->query($sql);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

header('Content-Type: application/json; charset=utf-8');
echo json_encode([
    'status' => 'success',
    'deleted_strokes' => $deletedCS,
    'deleted_lanna_char' => $deletedLC,
    'total_remaining' => count($rows),
    'first_10' => array_slice($rows, 0, 10)
], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
