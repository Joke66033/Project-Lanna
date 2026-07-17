<?php
require_once __DIR__ . '/../config/db.php';
$pdo = getPdo();
$tables = ['articles', 'category_lanna_char', 'learning_category'];
$result = [];
foreach ($tables as $t) {
    try {
        $stmt = $pdo->query("DESCRIBE `$t`");
        $result[$t] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (Exception $e) {
        $result[$t] = $e->getMessage();
    }
}
echo json_encode($result, JSON_PRETTY_PRINT);
