<?php
require_once __DIR__ . '/../config/db.php';
$pdo = getPdo();

$stmt = $pdo->query("DESCRIBE `lanna_char`");
$cols_lc = $stmt->fetchAll(PDO::FETCH_ASSOC);

$stmt = $pdo->query("DESCRIBE `character_strokes`");
$cols_cs = $stmt->fetchAll(PDO::FETCH_ASSOC);

header('Content-Type: application/json; charset=utf-8');
echo json_encode(['lanna_char' => $cols_lc, 'character_strokes' => $cols_cs], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
