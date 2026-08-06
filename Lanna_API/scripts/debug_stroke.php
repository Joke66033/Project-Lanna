<?php
// debug_stroke.php - ตรวจสอบ DB connection และ table structure

require_once __DIR__ . '/../config/db.php';
setCorsHeaders();

try {
    $pdo = getPdo();
    
    // ตรวจสอบ table structure
    $cols = $pdo->query("SHOW COLUMNS FROM `character_strokes`")->fetchAll(PDO::FETCH_ASSOC);
    
    // นับ rows
    $count = $pdo->query("SELECT COUNT(*) FROM `character_strokes`")->fetchColumn();
    
    // ดูตัวอย่างข้อมูล
    $sample = $pdo->query("SELECT stroke_id FROM `character_strokes` LIMIT 3")->fetchAll(PDO::FETCH_COLUMN);
    
    echo json_encode([
        'columns' => $cols,
        'row_count' => $count,
        'sample_ids' => $sample
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
