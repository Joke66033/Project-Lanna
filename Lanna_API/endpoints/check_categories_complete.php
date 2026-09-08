<?php
require_once __DIR__ . '/../config/db.php';
$pdo = getPdo();

// 1. Ensure CL0009 (พยัญชนะควบกล้ำ) exists in category_lanna_char
$stmt = $pdo->prepare("SELECT COUNT(*) FROM `category_lanna_char` WHERE `category_char_id` = 'CL0009'");
$stmt->execute();
if ($stmt->fetchColumn() == 0) {
    $pdo->prepare("INSERT INTO `category_lanna_char` (`category_char_id`, `name`, `learning_category_code`) VALUES ('CL0009', 'พยัญชนะควบกล้ำ', 'LC005')")->execute();
}

// 2. Summary of all sub-categories and their character counts
$sql = "SELECT 
            clc.`category_char_id`,
            clc.`name`,
            clc.`learning_category_code`,
            lc_cat.`title` AS `main_category_title`,
            COUNT(DISTINCT lc.`char_id`) AS `lanna_char_count`,
            COUNT(DISTINCT cs.`stroke_id`) AS `character_strokes_count`
        FROM `category_lanna_char` clc
        LEFT JOIN `learning_category` lc_cat ON clc.`learning_category_code` = lc_cat.`category_code`
        LEFT JOIN `lanna_char` lc ON clc.`category_char_id` = lc.`category_char_id`
        LEFT JOIN `character_strokes` cs ON clc.`category_char_id` = cs.`category_char_id`
        GROUP BY clc.`category_char_id`, clc.`name`, clc.`learning_category_code`, lc_cat.`title`
        ORDER BY clc.`learning_category_code` ASC, clc.`category_char_id` ASC";

$stmt = $pdo->query($sql);
$summary = $stmt->fetchAll(PDO::FETCH_ASSOC);

header('Content-Type: application/json; charset=utf-8');
echo json_encode(['categories' => $summary], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
