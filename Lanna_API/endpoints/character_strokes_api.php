<?php
/**
 * character_strokes_api.php
 * API endpoint for Lanna character stroke & drawing animation data
 * Table: character_strokes (PK: stroke_id)
 *
 * Actions (GET):
 *   ?action=getAll               → SELECT * ORDER BY stroke_id ASC
 *   ?action=getById&id=          → SELECT * WHERE stroke_id = id
 *   ?action=getByChar&char=      → SELECT * WHERE char_symbol = char
 *   ?action=getByCategory&cat=   → SELECT * WHERE category = cat
 *
 * Actions (POST):
 *   ?action=create               → INSERT new stroke entry
 *   ?action=update&id=           → UPDATE stroke entry
 *   ?action=delete&id=           → DELETE stroke entry
 *   ?action=seedBatch            → Batch insert/upsert stroke entries
 */

require_once __DIR__ . '/../config/db.php';
setCorsHeaders();

function ensureCharacterStrokesTableExists(): void {
    try {
        $pdo = getPdo();
        $sql = "CREATE TABLE IF NOT EXISTS `character_strokes` (
            `stroke_id` CHAR(6) NOT NULL PRIMARY KEY,
            `char_symbol` VARCHAR(50) NOT NULL UNIQUE,
            `char_name` VARCHAR(100) NULL,
            `category` VARCHAR(50) NOT NULL DEFAULT 'consonant',
            `stroke_count` INT NOT NULL DEFAULT 1,
            `stroke_data` LONGTEXT NOT NULL,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;";
        $pdo->exec($sql);
    } catch (Exception $e) {
        // ignore if table creation fails or permissions error
    }
}
ensureCharacterStrokesTableExists();

$action = $_GET['action'] ?? 'getAll';

// ===== GET =====
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    switch ($action) {

        case 'getAll':
            $filters = [];
            $category = $_GET['category'] ?? '';
            if ($category !== '') {
                $filters['category'] = 'eq.' . $category;
            }
            $res = dbSelect('character_strokes', '*', $filters, 'stroke_id.asc');
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'getById':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbSelectSingle('character_strokes', '*', ['stroke_id' => 'eq.' . rawurlencode($id)]);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'getByChar':
            $char = $_GET['char'] ?? '';
            if ($char === '') { jsonError('Missing char parameter'); break; }
            $res = dbSelectSingle('character_strokes', '*', ['char_symbol' => 'eq.' . rawurlencode($char)]);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        default:
            jsonError('Unknown action');
    }
}

// ===== POST =====
elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $body = getJsonBody();

    switch ($action) {

        case 'create':
            if (empty($body['char_symbol'])) {
                jsonError('Missing required field: char_symbol');
                break;
            }
            if (is_array($body['stroke_data'] ?? null)) {
                $body['stroke_data'] = json_encode($body['stroke_data'], JSON_UNESCAPED_UNICODE);
            }
            // Auto-generate stroke_id (S00001, S00002, ...)
            if (empty($body['stroke_id'])) {
                $pdo = getPdo();
                $last = $pdo->query("SELECT `stroke_id` FROM `character_strokes` ORDER BY `stroke_id` DESC LIMIT 1")->fetchColumn();
                $nextNum = $last ? (intval(substr($last, 1)) + 1) : 1;
                $body['stroke_id'] = 'S' . str_pad($nextNum, 5, '0', STR_PAD_LEFT);
            }

            $insertData = [
                'stroke_id'    => $body['stroke_id'],
                'char_symbol'  => $body['char_symbol'],
                'char_name'    => $body['char_name'] ?? '',
                'category'     => $body['category'] ?? 'consonant',
                'stroke_count' => isset($body['stroke_count']) ? (int)$body['stroke_count'] : 1,
                'stroke_data'  => is_array($body['stroke_data'] ?? null) ? json_encode($body['stroke_data'], JSON_UNESCAPED_UNICODE) : ($body['stroke_data'] ?? '[]')
            ];

            $res = dbInsert('character_strokes', $insertData);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'update':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }

            $updateData = [];
            if (array_key_exists('char_symbol', $body))  $updateData['char_symbol'] = $body['char_symbol'];
            if (array_key_exists('char_name', $body))    $updateData['char_name'] = $body['char_name'];
            if (array_key_exists('category', $body))     $updateData['category'] = $body['category'];
            if (array_key_exists('stroke_count', $body)) $updateData['stroke_count'] = (int)$body['stroke_count'];
            if (array_key_exists('stroke_data', $body))  $updateData['stroke_data'] = is_array($body['stroke_data']) ? json_encode($body['stroke_data'], JSON_UNESCAPED_UNICODE) : $body['stroke_data'];

            $resRow = dbSelectSingle('character_strokes', '*', ['stroke_id' => 'eq.' . rawurlencode($id)]);
            if ($resRow['data']) {
                jsonOk($resRow['data']);
            } else {
                jsonOk(array_merge(['stroke_id' => $id], $updateData));
            }
            break;

        case 'delete':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbDelete('character_strokes', ['stroke_id' => 'eq.' . rawurlencode($id)]);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'seedBatch':
            if (!is_array($body)) {
                jsonError('Expected JSON array of character stroke records');
                break;
            }
            $pdo = getPdo();
            $inserted = 0;
            $updated = 0;

            // ดึง max stroke_id ปัจจุบัน เพื่อ auto-increment ต่อ
            $lastRow = $pdo->query("SELECT `stroke_id` FROM `character_strokes` ORDER BY `stroke_id` DESC LIMIT 1")->fetchColumn();
            $counter = $lastRow ? intval(substr($lastRow, 1)) : 0;

            $stmtCheck = $pdo->prepare("SELECT `stroke_id` FROM `character_strokes` WHERE `char_symbol` = :cs LIMIT 1");
            $stmtInsert = $pdo->prepare("
                INSERT INTO `character_strokes` (`stroke_id`, `char_symbol`, `char_name`, `category`, `stroke_count`, `stroke_data`)
                VALUES (:stroke_id, :char_symbol, :char_name, :category, :stroke_count, :stroke_data)
            ");
            $stmtUpdate = $pdo->prepare("
                UPDATE `character_strokes`
                SET `char_name` = :char_name,
                    `category` = :category,
                    `stroke_count` = :stroke_count,
                    `stroke_data` = :stroke_data,
                    `updated_at` = CURRENT_TIMESTAMP
                WHERE `char_symbol` = :char_symbol
            ");

            foreach ($body as $item) {
                if (empty($item['char_symbol'])) continue;
                $strokeData = is_array($item['stroke_data'] ?? null)
                    ? json_encode($item['stroke_data'], JSON_UNESCAPED_UNICODE)
                    : ($item['stroke_data'] ?? '[]');

                $stmtCheck->execute([':cs' => $item['char_symbol']]);
                $existingId = $stmtCheck->fetchColumn();

                if ($existingId) {
                    // UPDATE
                    $stmtUpdate->execute([
                        ':char_symbol'  => $item['char_symbol'],
                        ':char_name'    => $item['char_name'] ?? ('อักขระ ' . $item['char_symbol']),
                        ':category'     => $item['category'] ?? 'consonant',
                        ':stroke_count' => (int)($item['stroke_count'] ?? 1),
                        ':stroke_data'  => $strokeData,
                    ]);
                    $updated++;
                } else {
                    // INSERT with new S##### id
                    $counter++;
                    $newId = 'S' . str_pad($counter, 5, '0', STR_PAD_LEFT);
                    // ถ้า item ระบุ stroke_id มาเอง ให้ใช้ค่านั้น
                    $sid = !empty($item['stroke_id']) ? $item['stroke_id'] : $newId;
                    $stmtInsert->execute([
                        ':stroke_id'    => $sid,
                        ':char_symbol'  => $item['char_symbol'],
                        ':char_name'    => $item['char_name'] ?? ('อักขระ ' . $item['char_symbol']),
                        ':category'     => $item['category'] ?? 'consonant',
                        ':stroke_count' => (int)($item['stroke_count'] ?? 1),
                        ':stroke_data'  => $strokeData,
                    ]);
                    $inserted++;
                }
            }
            jsonOk(['message' => 'Batch stroke data process completed', 'total' => $inserted]);
            break;

        default:
            jsonError('Unknown action');
    }
}
