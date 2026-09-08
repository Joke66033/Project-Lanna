<?php
/**
 * character_strokes_api.php
 * API endpoint for Lanna character stroke & drawing animation data
 * Table: character_strokes (PK: stroke_id, FK/Ref: category_char_id -> category_lanna_char.category_char_id)
 *
 * Actions (GET):
 *   ?action=getAll               → SELECT * with JOIN category_lanna_char ORDER BY stroke_id ASC
 *   ?action=getById&id=          → SELECT * WHERE stroke_id = id
 *   ?action=getByChar&char=      → SELECT * WHERE char_symbol = char
 *   ?action=getByCategory&cat=   → SELECT * WHERE category_char_id = cat
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
            `category_char_id` VARCHAR(10) NOT NULL DEFAULT 'CL0001',
            `stroke_count` INT NOT NULL DEFAULT 1,
            `stroke_data` LONGTEXT NOT NULL,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX `idx_cs_category_char_id` (`category_char_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;";
        $pdo->exec($sql);
    } catch (Exception $e) {
        // ignore if table creation fails
    }
}
ensureCharacterStrokesTableExists();

$action = $_GET['action'] ?? 'getAll';

$legacyCategoryMap = [
    'consonant' => 'CL0001',
    'vowel'     => 'CL0005',
    'tone'      => 'CL0006',
    'tone_mark' => 'CL0006',
    'number'    => 'CL0007',
    'sequence'  => 'CL0010',
    'other'     => 'CL0011'
];

// ===== GET =====
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $pdo = getPdo();

    switch ($action) {

        case 'getAll':
            $category = trim($_GET['category'] ?? '');
            $category_char_id = trim($_GET['category_char_id'] ?? '');
            $search = trim($_GET['search'] ?? '');
            
            $whereParts = [];
            $params = [];
            
            if ($category_char_id !== '' && strtolower($category_char_id) !== 'all') {
                if (str_contains($category_char_id, ',')) {
                    $catArr = explode(',', $category_char_id);
                    $inPlaceholders = [];
                    foreach ($catArr as $idx => $cId) {
                        $pKey = ':cat_id_' . $idx;
                        $inPlaceholders[] = $pKey;
                        $params[$pKey] = trim($cId);
                    }
                    $whereParts[] = "cs.`category_char_id` IN (" . implode(',', $inPlaceholders) . ")";
                } else {
                    $whereParts[] = "cs.`category_char_id` = :cat_id";
                    $params[':cat_id'] = $category_char_id;
                }
            } elseif ($category !== '' && strtolower($category) !== 'all') {
                if (strtolower($category) === 'tone') {
                    $whereParts[] = "cs.`category_char_id` IN ('CL0006')";
                } elseif (strtolower($category) === 'consonant') {
                    $whereParts[] = "cs.`category_char_id` IN ('CL0001', 'CL0002', 'CL0003')";
                } elseif (strtolower($category) === 'vowel') {
                    $whereParts[] = "cs.`category_char_id` IN ('CL0004', 'CL0005')";
                } elseif (strtolower($category) === 'number') {
                    $whereParts[] = "cs.`category_char_id` IN ('CL0007', 'CL0014')";
                } else {
                    $whereParts[] = "cs.`category_char_id` = :category";
                    $params[':category'] = $category;
                }
            }
            
            if ($search !== '') {
                $whereParts[] = "(cs.`char_symbol` LIKE :search OR cs.`char_name` LIKE :search OR cs.`stroke_id` LIKE :search OR clc.`name` LIKE :search)";
                $params[':search'] = '%' . $search . '%';
            }
            
            $whereSql = !empty($whereParts) ? ' WHERE ' . implode(' AND ', $whereParts) : '';
            
            // Query with LEFT JOIN to category_lanna_char table
            $sql = "SELECT 
                        cs.*,
                        cs.`category_char_id` AS `category`,
                        clc.`name` AS `category_name`,
                        clc.`learning_category_code`
                    FROM `character_strokes` cs
                    LEFT JOIN `category_lanna_char` clc ON cs.`category_char_id` = clc.`category_char_id`"
                    . $whereSql . "
                    ORDER BY CAST(SUBSTRING(cs.`stroke_id`, 2) AS UNSIGNED) ASC, cs.`stroke_id` ASC";
            
            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            jsonOk($rows);
            break;

        case 'getById':
            $id = trim($_GET['id'] ?? '');
            if ($id === '') { jsonError('Missing id'); break; }
            $sql = "SELECT 
                        cs.*,
                        cs.`category_char_id` AS `category`,
                        clc.`name` AS `category_name`,
                        clc.`learning_category_code`
                    FROM `character_strokes` cs
                    LEFT JOIN `category_lanna_char` clc ON cs.`category_char_id` = clc.`category_char_id`
                    WHERE cs.`stroke_id` = :id LIMIT 1";
            $stmt = $pdo->prepare($sql);
            $stmt->execute([':id' => $id]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($row) {
                jsonOk($row);
            } else {
                jsonError('Record not found', 404);
            }
            break;

        case 'getByChar':
            $char = trim($_GET['char'] ?? '');
            if ($char === '') { jsonError('Missing char parameter'); break; }
            $sql = "SELECT 
                        cs.*,
                        cs.`category_char_id` AS `category`,
                        clc.`name` AS `category_name`,
                        clc.`learning_category_code`
                    FROM `character_strokes` cs
                    LEFT JOIN `category_lanna_char` clc ON cs.`category_char_id` = clc.`category_char_id`
                    WHERE cs.`char_symbol` = :char LIMIT 1";
            $stmt = $pdo->prepare($sql);
            $stmt->execute([':char' => $char]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            jsonOk($row ?: null);
            break;

        case 'getByCategory':
            $category = trim($_GET['category'] ?? $_GET['cat'] ?? $_GET['category_char_id'] ?? '');
            $whereClause = ($category !== '' && strtolower($category) !== 'all') ? " WHERE cs.`category_char_id` = :cat" : "";
            $sql = "SELECT 
                        cs.*,
                        cs.`category_char_id` AS `category`,
                        clc.`name` AS `category_name`,
                        clc.`learning_category_code`
                    FROM `character_strokes` cs
                    LEFT JOIN `category_lanna_char` clc ON cs.`category_char_id` = clc.`category_char_id`"
                    . $whereClause . " 
                    ORDER BY CAST(SUBSTRING(cs.`stroke_id`, 2) AS UNSIGNED) ASC, cs.`stroke_id` ASC";
            $stmt = $pdo->prepare($sql);
            if ($whereClause !== '') {
                $stmt->execute([':cat' => $category]);
            } else {
                $stmt->execute();
            }
            jsonOk($stmt->fetchAll(PDO::FETCH_ASSOC));
            break;

        default:
            $sql = "SELECT 
                        cs.*,
                        cs.`category_char_id` AS `category`,
                        clc.`name` AS `category_name`,
                        clc.`learning_category_code`
                    FROM `character_strokes` cs
                    LEFT JOIN `category_lanna_char` clc ON cs.`category_char_id` = clc.`category_char_id`
                    ORDER BY CAST(SUBSTRING(cs.`stroke_id`, 2) AS UNSIGNED) ASC, cs.`stroke_id` ASC";
            $stmt = $pdo->query($sql);
            jsonOk($stmt->fetchAll(PDO::FETCH_ASSOC));
            break;
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
            
            $pdo = getPdo();
            if (empty($body['stroke_id'])) {
                $last = $pdo->query("SELECT `stroke_id` FROM `character_strokes` ORDER BY CAST(SUBSTRING(`stroke_id`, 2) AS UNSIGNED) DESC LIMIT 1")->fetchColumn();
                $nextNum = $last ? (intval(substr($last, 1)) + 1) : 1;
                $body['stroke_id'] = 'S' . str_pad($nextNum, 5, '0', STR_PAD_LEFT);
            }

            $catId = $body['category_char_id'] ?? $body['category'] ?? 'CL0001';
            if (isset($legacyCategoryMap[strtolower($catId)])) {
                $catId = $legacyCategoryMap[strtolower($catId)];
            }

            // Check for duplicate char_symbol
            $stmtCheckDup = $pdo->prepare("SELECT `stroke_id`, `char_name` FROM `character_strokes` WHERE `char_symbol` = :cs LIMIT 1");
            $stmtCheckDup->execute([':cs' => $body['char_symbol']]);
            $existingStroke = $stmtCheckDup->fetch(PDO::FETCH_ASSOC);
            if ($existingStroke) {
                jsonError("ตัวอักขระล้านนานี้ ('" . $body['char_symbol'] . "') มีอยู่ในระบบแล้ว หากต้องการปรับปรุงพิกัดเส้น กรุณาค้นหาและกดปุ่ม 'แก้ไข' ที่รายการเดิม");
                break;
            }

            $insertData = [
                'stroke_id'        => $body['stroke_id'],
                'char_symbol'      => $body['char_symbol'],
                'char_name'        => $body['char_name'] ?? '',
                'category_char_id' => $catId,
                'stroke_count'     => isset($body['stroke_count']) ? (int)$body['stroke_count'] : 1,
                'stroke_data'      => is_array($body['stroke_data'] ?? null) ? json_encode($body['stroke_data'], JSON_UNESCAPED_UNICODE) : ($body['stroke_data'] ?? '[]')
            ];

            $res = dbInsert('character_strokes', $insertData);
            if ($res['error']) { jsonError($res['error']['message']); break; }

            // ✅ Sync with lanna_char table so mobile app displays new character immediately
            try {
                $stmtCheck = $pdo->prepare("SELECT `char_id` FROM `lanna_char` WHERE `lanna_char` = :lc LIMIT 1");
                $stmtCheck->execute([':lc' => $body['char_symbol']]);
                $existingCharId = $stmtCheck->fetchColumn();

                if ($existingCharId) {
                    $stmtUpdateLC = $pdo->prepare("UPDATE `lanna_char` SET `thai_equivalent` = :th, `category_char_id` = :cat, `updated_at` = CURRENT_TIMESTAMP WHERE `char_id` = :cid");
                    $stmtUpdateLC->execute([
                        ':th'  => $body['char_name'] ?? '',
                        ':cat' => $catId,
                        ':cid' => $existingCharId
                    ]);
                } else {
                    $lastCharId = $pdo->query("SELECT `char_id` FROM `lanna_char` WHERE `char_id` LIKE 'V%' ORDER BY CAST(SUBSTRING(`char_id`, 2) AS UNSIGNED) DESC LIMIT 1")->fetchColumn();
                    $nextCharNum = 1;
                    if ($lastCharId && preg_match('/\d+/', $lastCharId, $m)) {
                        $nextCharNum = intval($m[0]) + 1;
                    }
                    $newCharId = 'V' . str_pad($nextCharNum, 3, '0', STR_PAD_LEFT);
                    $stmtInsertLC = $pdo->prepare("INSERT INTO `lanna_char` (`char_id`, `lanna_char`, `thai_equivalent`, `category_char_id`) VALUES (:cid, :lc, :th, :cat)");
                    $stmtInsertLC->execute([
                        ':cid' => $newCharId,
                        ':lc'  => $body['char_symbol'],
                        ':th'  => $body['char_name'] ?? '',
                        ':cat' => $catId
                    ]);
                }
            } catch (Exception $e) {
                // Ignore sync error
            }

            jsonOk($res['data']);
            break;

        case 'update':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }

            $pdo = getPdo();
            $stmtOld = $pdo->prepare("SELECT `char_symbol` FROM `character_strokes` WHERE `stroke_id` = :id");
            $stmtOld->execute([':id' => $id]);
            $oldSym = $stmtOld->fetchColumn();

            $catId = $body['category_char_id'] ?? $body['category'] ?? null;
            if ($catId !== null) {
                if (isset($legacyCategoryMap[strtolower($catId)])) {
                    $catId = $legacyCategoryMap[strtolower($catId)];
                }
            }

            $updateData = [];
            if (array_key_exists('char_symbol', $body))      $updateData['char_symbol'] = $body['char_symbol'];
            if (array_key_exists('char_name', $body))        $updateData['char_name'] = $body['char_name'];
            if ($catId !== null)                             $updateData['category_char_id'] = $catId;
            if (array_key_exists('stroke_count', $body))     $updateData['stroke_count'] = (int)$body['stroke_count'];
            if (array_key_exists('stroke_data', $body))      $updateData['stroke_data'] = is_array($body['stroke_data']) ? json_encode($body['stroke_data'], JSON_UNESCAPED_UNICODE) : $body['stroke_data'];
            
            if (!empty($updateData)) {
                $resUpdate = dbUpdate('character_strokes', ['stroke_id' => 'eq.' . rawurlencode($id)], $updateData);
                if ($resUpdate['error']) { jsonError($resUpdate['error']['message']); break; }
            }

            // ✅ Sync with lanna_char table
            try {
                $sym = $body['char_symbol'] ?? $oldSym;
                $thName = $body['char_name'] ?? null;

                if ($sym) {
                    $stmtCheck = $pdo->prepare("SELECT `char_id` FROM `lanna_char` WHERE `lanna_char` = :lc OR `lanna_char` = :oldlc OR `char_id` = :id LIMIT 1");
                    $stmtCheck->execute([':lc' => $sym, ':oldlc' => $oldSym, ':id' => $id]);
                    $existingCharId = $stmtCheck->fetchColumn();

                    if ($existingCharId) {
                        $lcUpdates = [];
                        $lcParams = [':cid' => $existingCharId];
                        if (array_key_exists('char_symbol', $body)) {
                            $lcUpdates[] = "`lanna_char` = :lc";
                            $lcParams[':lc'] = $body['char_symbol'];
                        }
                        if ($thName !== null) {
                            $lcUpdates[] = "`thai_equivalent` = :th";
                            $lcParams[':th'] = $thName;
                        }
                        if ($catId !== null) {
                            $lcUpdates[] = "`category_char_id` = :cat";
                            $lcParams[':cat'] = $catId;
                        }
                        if (!empty($lcUpdates)) {
                            $sqlLC = "UPDATE `lanna_char` SET " . implode(', ', $lcUpdates) . ", `updated_at` = CURRENT_TIMESTAMP WHERE `char_id` = :cid";
                            $pdo->prepare($sqlLC)->execute($lcParams);
                        }
                    } else {
                        $lastCharId = $pdo->query("SELECT `char_id` FROM `lanna_char` WHERE `char_id` LIKE 'V%' ORDER BY CAST(SUBSTRING(`char_id`, 2) AS UNSIGNED) DESC LIMIT 1")->fetchColumn();
                        $nextCharNum = 1;
                        if ($lastCharId && preg_match('/\d+/', $lastCharId, $m)) {
                            $nextCharNum = intval($m[0]) + 1;
                        }
                        $newCharId = 'V' . str_pad($nextCharNum, 3, '0', STR_PAD_LEFT);
                        $stmtInsertLC = $pdo->prepare("INSERT INTO `lanna_char` (`char_id`, `lanna_char`, `thai_equivalent`, `category_char_id`) VALUES (:cid, :lc, :th, :cat)");
                        $stmtInsertLC->execute([
                            ':cid' => $newCharId,
                            ':lc'  => $sym,
                            ':th'  => $thName ?? '',
                            ':cat' => $catId ?? 'CL0001'
                        ]);
                    }
                }
            } catch (Exception $e) {
                // Ignore sync error
            }

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

            $pdo = getPdo();
            $stmtSym = $pdo->prepare("SELECT `char_symbol` FROM `character_strokes` WHERE `stroke_id` = :id");
            $stmtSym->execute([':id' => $id]);
            $sym = $stmtSym->fetchColumn();

            $res = dbDelete('character_strokes', ['stroke_id' => 'eq.' . rawurlencode($id)]);
            if ($res['error']) { jsonError($res['error']['message']); break; }

            // Delete corresponding entry in lanna_char if it exists
            if ($sym) {
                try {
                    $stmtDelLC = $pdo->prepare("DELETE FROM `lanna_char` WHERE `lanna_char` = :lc OR `char_id` = :id");
                    $stmtDelLC->execute([':lc' => $sym, ':id' => $id]);
                } catch (Exception $e) {}
            }

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

            $lastRow = $pdo->query("SELECT `stroke_id` FROM `character_strokes` ORDER BY CAST(SUBSTRING(`stroke_id`, 2) AS UNSIGNED) DESC LIMIT 1")->fetchColumn();
            $counter = $lastRow ? intval(substr($lastRow, 1)) : 0;

            $stmtCheck = $pdo->prepare("SELECT `stroke_id` FROM `character_strokes` WHERE `char_symbol` = :cs LIMIT 1");
            $stmtInsert = $pdo->prepare("
                INSERT INTO `character_strokes` (`stroke_id`, `char_symbol`, `char_name`, `category_char_id`, `stroke_count`, `stroke_data`)
                VALUES (:stroke_id, :char_symbol, :char_name, :category_char_id, :stroke_count, :stroke_data)
            ");
            $stmtUpdate = $pdo->prepare("
                UPDATE `character_strokes`
                SET `char_name` = :char_name,
                    `category_char_id` = :category_char_id,
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

                $cat = $item['category_char_id'] ?? $item['category'] ?? 'CL0001';
                if (isset($legacyCategoryMap[strtolower($cat)])) {
                    $cat = $legacyCategoryMap[strtolower($cat)];
                }

                $stmtCheck->execute([':cs' => $item['char_symbol']]);
                $existingId = $stmtCheck->fetchColumn();

                if ($existingId) {
                    $stmtUpdate->execute([
                        ':char_symbol'       => $item['char_symbol'],
                        ':char_name'         => $item['char_name'] ?? ('อักขระ ' . $item['char_symbol']),
                        ':category_char_id'  => $cat,
                        ':stroke_count'      => (int)($item['stroke_count'] ?? 1),
                        ':stroke_data'       => $strokeData,
                    ]);
                    $updated++;
                } else {
                    $counter++;
                    $newId = 'S' . str_pad($counter, 5, '0', STR_PAD_LEFT);
                    $sid = !empty($item['stroke_id']) ? $item['stroke_id'] : $newId;
                    $stmtInsert->execute([
                        ':stroke_id'         => $sid,
                        ':char_symbol'       => $item['char_symbol'],
                        ':char_name'         => $item['char_name'] ?? ('อักขระ ' . $item['char_symbol']),
                        ':category_char_id'  => $cat,
                        ':stroke_count'      => (int)($item['stroke_count'] ?? 1),
                        ':stroke_data'       => $strokeData,
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

else {
    jsonError('Method not allowed', 405);
}
