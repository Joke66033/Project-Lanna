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

            // 2. INSERT with generated ID
            $finalData = array_merge($body, ['char_id' => $nextId]);
            $res = dbInsert('lanna_char', $finalData);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'update':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbUpdate('lanna_char', ['char_id' => 'eq.' . rawurlencode($id)], $body);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'delete':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbDelete('lanna_char', ['char_id' => 'eq.' . rawurlencode($id)]);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        default:
            jsonError('Unknown action');
    }
}

else {
    jsonError('Method not allowed', 405);
}
