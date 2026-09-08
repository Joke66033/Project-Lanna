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

// 1. Fetch all strokes
$stmt = $pdo->query("SELECT * FROM `character_strokes`");
$strokes = $stmt->fetchAll(PDO::FETCH_ASSOC);

$synced = 0;
$updated = 0;

foreach ($strokes as $s) {
    $symbol = trim($s['char_symbol'] ?? '');
    if ($symbol === '') continue;
    
    $name = trim($s['char_name'] ?? '');
    $cat = trim($s['category'] ?? '');
    if (isset($legacyMap[strtolower($cat)])) {
        $cat = $legacyMap[strtolower($cat)];
    }
    if ($cat === '') $cat = 'CL0001';
    
    // Check if symbol exists in lanna_char
    $stmtCheck = $pdo->prepare("SELECT `char_id`, `lanna_char`, `thai_equivalent`, `category_char_id` FROM `lanna_char` WHERE `lanna_char` = :sym OR `char_id` = :cid LIMIT 1");
    $stmtCheck->execute([':sym' => $symbol, ':cid' => $s['stroke_id']]);
    $existing = $stmtCheck->fetch(PDO::FETCH_ASSOC);
    
    if ($existing) {
        // Update if category or name is missing
        $stmtUp = $pdo->prepare("UPDATE `lanna_char` SET `thai_equivalent` = COALESCE(NULLIF(:th, ''), `thai_equivalent`), `category_char_id` = COALESCE(NULLIF(:cat, ''), `category_char_id`) WHERE `char_id` = :cid");
        $stmtUp->execute([':th' => $name, ':cat' => $cat, ':cid' => $existing['char_id']]);
        $updated++;
    } else {
        // Insert new into lanna_char
        // Get next char_id
        $lastCharId = $pdo->query("SELECT `char_id` FROM `lanna_char` WHERE `char_id` LIKE 'V%' ORDER BY `char_id` DESC LIMIT 1")->fetchColumn();
        $nextCharNum = 1;
        if ($lastCharId && preg_match('/\d+/', $lastCharId, $m)) {
            $nextCharNum = intval($m[0]) + 1;
        }
        $newCharId = 'V' . str_pad($nextCharNum, 3, '0', STR_PAD_LEFT);
        
        $stmtIns = $pdo->prepare("INSERT INTO `lanna_char` (`char_id`, `lanna_char`, `thai_equivalent`, `category_char_id`) VALUES (:cid, :sym, :th, :cat)");
        $stmtIns->execute([
            ':cid' => $newCharId,
            ':sym' => $symbol,
            ':th'  => $name,
            ':cat' => $cat
        ]);
        $synced++;
    }
}

// Check count
$countLC = $pdo->query("SELECT COUNT(*) FROM `lanna_char`")->fetchColumn();
$countCS = $pdo->query("SELECT COUNT(*) FROM `character_strokes`")->fetchColumn();

header('Content-Type: application/json; charset=utf-8');
echo json_encode([
    'status' => 'success',
    'inserted' => $synced,
    'updated' => $updated,
    'lanna_char_count' => $countLC,
    'character_strokes_count' => $countCS
], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
