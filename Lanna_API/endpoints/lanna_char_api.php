<?php
/**
 * lanna_char_api.php
 * Table: lanna_char (PK: char_id)
 * Synchronized with character_strokes table for seamless Flutter App & Admin integration.
 *
 * Actions (GET):
 *   ?action=getAll              → SELECT * ORDER BY char_id ASC
 *   ?action=getById&id=         → SELECT * WHERE char_id = id
 *
 * Actions (POST):
 *   ?action=create              → INSERT (body: JSON)
 *   ?action=update&id=          → UPDATE WHERE char_id = id (body: JSON)
 *   ?action=delete&id=          → DELETE WHERE char_id = id
 */

require_once __DIR__ . '/../config/db.php';
setCorsHeaders();

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

function syncStrokesToLannaChar(PDO $pdo, array $legacyCategoryMap): void {
    try {
        // Find any character_strokes not yet in lanna_char
        $stmt = $pdo->query("SELECT cs.`stroke_id`, cs.`char_symbol`, cs.`char_name`, cs.`category_char_id` AS `category` 
                             FROM `character_strokes` cs
                             LEFT JOIN `lanna_char` lc ON cs.`char_symbol` = lc.`lanna_char`
                             WHERE lc.`char_id` IS NULL AND cs.`char_symbol` IS NOT NULL AND TRIM(cs.`char_symbol`) != ''");
        $missing = $stmt->fetchAll(PDO::FETCH_ASSOC);

        if (!empty($missing)) {
            $lastCharId = $pdo->query("SELECT `char_id` FROM `lanna_char` WHERE `char_id` LIKE 'V%' ORDER BY CAST(SUBSTRING(`char_id`, 2) AS UNSIGNED) DESC LIMIT 1")->fetchColumn();
            $nextCharNum = 1;
            if ($lastCharId && preg_match('/\d+/', $lastCharId, $m)) {
                $nextCharNum = intval($m[0]) + 1;
            }

            $stmtIns = $pdo->prepare("INSERT INTO `lanna_char` (`char_id`, `lanna_char`, `thai_equivalent`, `category_char_id`) VALUES (:cid, :sym, :th, :cat)");
            foreach ($missing as $item) {
                $cat = trim($item['category'] ?? '');
                if (isset($legacyCategoryMap[strtolower($cat)])) {
                    $cat = $legacyCategoryMap[strtolower($cat)];
                }
                if ($cat === '') $cat = 'CL0001';

                $cid = 'V' . str_pad($nextCharNum, 3, '0', STR_PAD_LEFT);
                $nextCharNum++;

                $stmtIns->execute([
                    ':cid' => $cid,
                    ':sym' => trim($item['char_symbol']),
                    ':th'  => trim($item['char_name'] ?? ''),
                    ':cat' => $cat
                ]);
            }
        }
    } catch (Exception $e) {
        // Ignore background sync errors
    }
}

// ===== GET =====
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $pdo = getPdo();

    switch ($action) {

        case 'getAll':
            // 1. Sync character_strokes to lanna_char
            syncStrokesToLannaChar($pdo, $legacyCategoryMap);

            $filters = [];
            $category_char_id = $_GET['category_char_id'] ?? '';
            if ($category_char_id !== '') {
                if (str_contains($category_char_id, ',')) {
                    $filters['category_char_id'] = 'in.(' . $category_char_id . ')';
                } else {
                    $filters['category_char_id'] = 'eq.' . $category_char_id;
                }
            }
            $res = dbSelect('lanna_char', '*,category_lanna_char(name)', $filters, 'char_id.asc');
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'getById':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbSelectSingle('lanna_char', '*', ['char_id' => 'eq.' . rawurlencode($id)]);
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
    $pdo = getPdo();

    switch ($action) {

        case 'create':
            // 1. ดึง ID ล่าสุดเพื่อ increment (V### format)
            $lastCharId = $pdo->query("SELECT `char_id` FROM `lanna_char` WHERE `char_id` LIKE 'V%' ORDER BY CAST(SUBSTRING(`char_id`, 2) AS UNSIGNED) DESC LIMIT 1")->fetchColumn();
            $nextNumber = 1;
            if ($lastCharId && preg_match('/\d+/', $lastCharId, $m)) {
                $nextNumber = (int)$m[0] + 1;
            }
            $nextId = 'V' . str_pad((string)$nextNumber, 3, '0', STR_PAD_LEFT);

            $lannaSymbol = $body['lanna_char'] ?? $body['char_symbol'] ?? $body['ln'] ?? '';
            $thaiName = $body['thai_equivalent'] ?? $body['char_name'] ?? $body['th'] ?? '';
            $catId = !empty($body['category_char_id']) ? $body['category_char_id'] : ($body['category'] ?? 'CL0001');
            if (isset($legacyCategoryMap[strtolower($catId)])) {
                $catId = $legacyCategoryMap[strtolower($catId)];
            }

            $insertData = [
                'char_id'          => $nextId,
                'lanna_char'       => $lannaSymbol,
                'thai_equivalent'  => $thaiName,
                'category_char_id' => $catId
            ];
            $res = dbInsert('lanna_char', $insertData);
            if ($res['error']) { jsonError($res['error']['message']); break; }

            // Sync with character_strokes table
            if (!empty($lannaSymbol)) {
                try {
                    $stmtCS = $pdo->prepare("SELECT `stroke_id` FROM `character_strokes` WHERE `char_symbol` = :sym LIMIT 1");
                    $stmtCS->execute([':sym' => $lannaSymbol]);
                    if (!$stmtCS->fetchColumn()) {
                        $lastStrokeId = $pdo->query("SELECT `stroke_id` FROM `character_strokes` ORDER BY `stroke_id` DESC LIMIT 1")->fetchColumn();
                        $nextStrokeNum = $lastStrokeId ? (intval(substr($lastStrokeId, 1)) + 1) : 1;
                        $newStrokeId = 'S' . str_pad($nextStrokeNum, 5, '0', STR_PAD_LEFT);
                        $stmtInsCS = $pdo->prepare("INSERT INTO `character_strokes` (`stroke_id`, `char_symbol`, `char_name`, `category`, `stroke_count`, `stroke_data`) VALUES (:sid, :sym, :nm, :cat, 1, '[]')");
                        $stmtInsCS->execute([
                            ':sid' => $newStrokeId,
                            ':sym' => $lannaSymbol,
                            ':nm'  => $thaiName,
                            ':cat' => $catId
                        ]);
                    }
                } catch (Exception $e) {}
            }

            jsonOk($res['data']);
            break;

        case 'update':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }

            $updateData = [];
            $lannaSymbol = null;
            $thaiName = null;
            $catId = null;

            if (array_key_exists('lanna_char', $body) || array_key_exists('char_symbol', $body) || array_key_exists('ln', $body)) {
                $lannaSymbol = $body['lanna_char'] ?? $body['char_symbol'] ?? $body['ln'];
                $updateData['lanna_char'] = $lannaSymbol;
            }
            if (array_key_exists('thai_equivalent', $body) || array_key_exists('char_name', $body) || array_key_exists('th', $body)) {
                $thaiName = $body['thai_equivalent'] ?? $body['char_name'] ?? $body['th'];
                $updateData['thai_equivalent'] = $thaiName;
            }
            if (array_key_exists('category_char_id', $body) || array_key_exists('category', $body)) {
                $catId = $body['category_char_id'] ?? $body['category'];
                if (isset($legacyCategoryMap[strtolower($catId)])) {
                    $catId = $legacyCategoryMap[strtolower($catId)];
                }
                $updateData['category_char_id'] = !empty($catId) ? $catId : null;
            }

            $res = dbUpdate('lanna_char', ['char_id' => 'eq.' . rawurlencode($id)], $updateData);
            if ($res['error']) { jsonError($res['error']['message']); break; }

            // Sync with character_strokes
            try {
                $targetSymbol = $lannaSymbol;
                if (!$targetSymbol) {
                    $targetSymbol = $pdo->query("SELECT `lanna_char` FROM `lanna_char` WHERE `char_id` = " . $pdo->quote($id))->fetchColumn();
                }
                if ($targetSymbol) {
                    $csUpdates = [];
                    $csParams = [':sym' => $targetSymbol];
                    if ($thaiName !== null) {
                        $csUpdates[] = "`char_name` = :nm";
                        $csParams[':nm'] = $thaiName;
                    }
                    if ($catId !== null) {
                        $csUpdates[] = "`category` = :cat";
                        $csParams[':cat'] = $catId;
                    }
                    if (!empty($csUpdates)) {
                        $sqlCS = "UPDATE `character_strokes` SET " . implode(', ', $csUpdates) . ", `updated_at` = CURRENT_TIMESTAMP WHERE `char_symbol` = :sym";
                        $pdo->prepare($sqlCS)->execute($csParams);
                    }
                }
            } catch (Exception $e) {}

            $resRow = dbSelectSingle('lanna_char', '*', ['char_id' => 'eq.' . rawurlencode($id)]);
            if ($resRow['data']) {
                jsonOk($resRow['data']);
            } else {
                jsonOk(array_merge(['char_id' => $id], $updateData));
            }
            break;

        case 'delete':
            $id = $_GET['id'] ?? $body['char_id'] ?? $body['id'] ?? null;
            $thai = $_GET['thai_equivalent'] ?? $body['thai_equivalent'] ?? $body['th'] ?? null;
            $lanna = $_GET['lanna_char'] ?? $body['lanna_char'] ?? $body['ln'] ?? null;

            try {
                if ($id !== null && $id !== '') {
                    $symbol = $pdo->query("SELECT `lanna_char` FROM `lanna_char` WHERE `char_id` = " . $pdo->quote($id))->fetchColumn();
                    $stmt = $pdo->prepare("DELETE FROM `lanna_char` WHERE `char_id` = ?");
                    $stmt->execute([$id]);

                    if ($symbol) {
                        $stmtDelCS = $pdo->prepare("DELETE FROM `character_strokes` WHERE `char_symbol` = ?");
                        $stmtDelCS->execute([$symbol]);
                    }
                    jsonOk(['deleted' => true, 'char_id' => $id]);
                } elseif ($thai !== null || $lanna !== null) {
                    $conditions = [];
                    $params = [];
                    if ($thai !== null) {
                        $conditions[] = "`thai_equivalent` = ?";
                        $params[] = $thai;
                    }
                    if ($lanna !== null) {
                        $conditions[] = "`lanna_char` = ?";
                        $params[] = $lanna;
                    }
                    $sql = "DELETE FROM `lanna_char` WHERE " . implode(" AND ", $conditions);
                    $stmt = $pdo->prepare($sql);
                    $stmt->execute($params);

                    if ($lanna !== null) {
                        $stmtDelCS = $pdo->prepare("DELETE FROM `character_strokes` WHERE `char_symbol` = ?");
                        $stmtDelCS->execute([$lanna]);
                    }
                    jsonOk(['deleted' => true]);
                } else {
                    jsonError('Missing id');
                }
            } catch (Exception $e) {
                jsonError($e->getMessage());
            }
            break;

        default:
            jsonError('Unknown action');
    }
}

else {
    jsonError('Method not allowed', 405);
}
