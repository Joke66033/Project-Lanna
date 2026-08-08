<?php
require_once __DIR__ . '/../config/db.php';
setCorsHeaders();

$tables = [
    'learning_category',
    'category_lanna_char',
    'category_vocab',
    'lanna_char',
    'vocabulary',
    'articles',
    'character_strokes',
    'users'
];

$pdo = getPdo();
$result = [];

foreach ($tables as $t) {
    try {
        $stmt = $pdo->query("DESCRIBE `$t`");
        $cols = $stmt->fetchAll(PDO::FETCH_COLUMN);
        $result[$t] = $cols;
    } catch (Exception $e) {
        $result[$t] = 'Error: ' . $e->getMessage();
    }
}

echo json_encode(['data' => $result], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
