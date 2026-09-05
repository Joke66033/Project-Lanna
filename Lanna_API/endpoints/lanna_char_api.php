<?php
/**
 * lanna_char_api.php
 * ย้าย logic จาก lannaCharApi.js → PHP
 * Table: lanna_char (PK: char_id)
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

/* $action = $_GET['action'] ?? ''; */
$action = $_GET['action'] ?? 'getAll';

// ===== GET =====
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    switch ($action) {

        case 'getAll':
            try {
                $pdo = getPdo();
                // Clean up orphan characters whose category_char_id is NULL, empty, or no longer exists in category_lanna_char table
                $pdo->exec("DELETE FROM `lanna_char` WHERE `category_char_id` IS NULL OR `category_char_id` = '' OR `category_char_id` NOT IN (SELECT `category_char_id` FROM `category_lanna_char`)");
            } catch (Exception $e) {
                // Ignore cleanup error if table is locked
            }

            $filters = [];
            $category_char_id = $_GET['category_char_id'] ?? '';
            if ($category_char_id !== '') {
                if (str_contains($category_char_id, ',')) {
                    $filters['category_char_id'] = 'in.(' . $category_char_id . ')';
                } else {
                    $filters['category_char_id'] = 'eq.' . $category_char_id;
                }
            }
            $res = dbSelect('lanna_char', '*,category_lanna_char(name)', $filters, 'char_id.desc');
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

    switch ($action) {

        case 'create':
            // 1. ดึง ID ล่าสุดเพื่อ increment (V### format)
            $listRes = dbSelect('lanna_char', 'char_id', [], 'char_id.desc', 1);
            if ($listRes['error']) { jsonError($listRes['error']['message']); break; }

            $nextNumber = 1;
            $list = $listRes['data'] ?? [];
            if (!empty($list)) {
                $lastId = trim($list[0]['char_id'] ?? '');
                if (preg_match('/\d+/', $lastId, $m)) {
                    $nextNumber = (int)$m[0] + 1;
                }
            }
            $nextId = 'V' . str_pad((string)$nextNumber, 3, '0', STR_PAD_LEFT);

            $insertData = [
                'char_id'          => $nextId,
                'lanna_char'       => $body['lanna_char'] ?? $body['char_symbol'] ?? $body['ln'] ?? '',
                'thai_equivalent'  => $body['thai_equivalent'] ?? $body['char_name'] ?? $body['th'] ?? '',
                'category_char_id' => !empty($body['category_char_id']) ? $body['category_char_id'] : null
            ];
            $res = dbInsert('lanna_char', $insertData);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'update':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }

            $updateData = [];
            if (array_key_exists('lanna_char', $body) || array_key_exists('char_symbol', $body) || array_key_exists('ln', $body)) {
                $updateData['lanna_char'] = $body['lanna_char'] ?? $body['char_symbol'] ?? $body['ln'];
            }
            if (array_key_exists('thai_equivalent', $body) || array_key_exists('char_name', $body) || array_key_exists('th', $body)) {
                $updateData['thai_equivalent'] = $body['thai_equivalent'] ?? $body['char_name'] ?? $body['th'];
            }
            if (array_key_exists('category_char_id', $body)) {
                $updateData['category_char_id'] = !empty($body['category_char_id']) ? $body['category_char_id'] : null;
            }

            $res = dbUpdate('lanna_char', ['char_id' => 'eq.' . rawurlencode($id)], $updateData);
            if ($res['error']) { jsonError($res['error']['message']); break; }

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
                $pdo = getPdo();
                if ($id !== null && $id !== '') {
                    $stmt = $pdo->prepare("DELETE FROM `lanna_char` WHERE `char_id` = ?");
                    $stmt->execute([$id]);
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
                    if ($id === '') {
                        $conditions[] = "(`char_id` = '' OR `char_id` IS NULL)";
                    }
                    $sql = "DELETE FROM `lanna_char` WHERE " . implode(" AND ", $conditions);
                    $stmt = $pdo->prepare($sql);
                    $stmt->execute($params);
                    jsonOk(['deleted' => true]);
                } elseif ($id === '') {
                    $stmt = $pdo->prepare("DELETE FROM `lanna_char` WHERE `char_id` = '' OR `char_id` IS NULL LIMIT 1");
                    $stmt->execute();
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
