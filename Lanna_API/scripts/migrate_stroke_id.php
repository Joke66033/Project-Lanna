<?php
/**
 * migrate_stroke_final.php
 * สถานะปัจจุบัน:
 * - stroke_id = int(11) ไม่มี PK แล้ว (ถูกถอดออก)
 * - new_stroke_id = char(6) มีค่า S00001-S00193 ครบแล้ว
 * - new_sid = char(6) column ค้างอยู่ (ลบทิ้ง)
 * เป้าหมาย: เปลี่ยน new_stroke_id ให้กลายเป็น stroke_id (PK, CHAR(6))
 */
require_once __DIR__ . '/../config/db.php';
setCorsHeaders();
header('Content-Type: application/json');

$pdo = getPdo();
$results = [];

$sqls = [
    // 1. ลบ column ขยะ new_sid ออก
    'drop_new_sid'     => "ALTER TABLE `character_strokes` DROP COLUMN `new_sid`",
    // 2. ตั้ง new_stroke_id เป็น NOT NULL
    'set_not_null'     => "ALTER TABLE `character_strokes` MODIFY `new_stroke_id` CHAR(6) NOT NULL",
    // 3. เพิ่ม PK บน new_stroke_id
    'add_pk'           => "ALTER TABLE `character_strokes` ADD PRIMARY KEY (`new_stroke_id`)",
    // 4. ลบ stroke_id เดิม (INT)
    'drop_old_id'      => "ALTER TABLE `character_strokes` DROP COLUMN `stroke_id`",
    // 5. เปลี่ยนชื่อ new_stroke_id → stroke_id
    'rename_col'       => "ALTER TABLE `character_strokes` CHANGE `new_stroke_id` `stroke_id` CHAR(6) NOT NULL",
    // 6. ย้ายไปเป็น column แรก
    'move_first'       => "ALTER TABLE `character_strokes` MODIFY `stroke_id` CHAR(6) NOT NULL FIRST",
];

foreach ($sqls as $key => $sql) {
    try {
        $pdo->exec($sql);
        $results[$key] = 'OK';
    } catch (Exception $e) {
        $results[$key] = 'ERROR: ' . $e->getMessage();
    }
}

// ตรวจสอบผลลัพธ์สุดท้าย
try {
    $cols   = $pdo->query("SHOW COLUMNS FROM `character_strokes`")->fetchAll(PDO::FETCH_ASSOC);
    $sample = $pdo->query("SELECT `stroke_id` FROM `character_strokes` ORDER BY `stroke_id` LIMIT 5")->fetchAll(PDO::FETCH_COLUMN);
    $total  = $pdo->query("SELECT COUNT(*) FROM `character_strokes`")->fetchColumn();

    $results['final'] = [
        'columns' => array_map(fn($c) => $c['Field'].':'.$c['Type'].($c['Key']==='PRI'?' [PK]':''), $cols),
        'total_rows' => $total,
        'sample_stroke_ids' => $sample
    ];
} catch (Exception $e) {
    $results['final'] = 'ERROR: ' . $e->getMessage();
}

echo json_encode($results, JSON_PRETTY_PRINT);
