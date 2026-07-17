<?php
/**
 * favorites_api.php
 * ย้าย logic จาก favoritesApi.js → PHP
 * Table: favorites (PK: favorite_id)
 *
 * Actions (GET):
 *   ?action=getAll               → SELECT * ORDER BY favorite_id ASC
 *   ?action=getById&id=          → SELECT * WHERE favorite_id = id
 *   ?action=getByUserId&userId=  → SELECT * WHERE user_id = userId
 *
 * Actions (POST):
 *   ?action=create               → INSERT (body: JSON)
 *   ?action=update&id=           → UPDATE WHERE favorite_id = id (body: JSON)
 *   ?action=delete&id=           → DELETE WHERE favorite_id = id
 */

require_once __DIR__ . '/../config/db.php';
setCorsHeaders();

/* $action = $_GET['action'] ?? ''; */
$action = $_GET['action'] ?? 'getAll';

// ===== GET =====
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    switch ($action) {

        case 'getAll':
            $res = dbSelect('favorites', '*', [], 'favorite_id.asc');
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'getById':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbSelectSingle('favorites', '*', ['favorite_id' => 'eq.' . $id]);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'getByUserId':
            $userId = $_GET['userId'] ?? '';
            if ($userId === '') { jsonError('Missing userId'); break; }
            $res = dbSelect('favorites', '*', ['user_id' => 'eq.' . rawurlencode($userId)]);
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
            // 1. ดึง ID ล่าสุดเพื่อ increment (FA00001 format)
            $listRes = dbSelect('favorites', 'favorite_id', [], 'favorite_id.desc', 1);
            if ($listRes['error']) { jsonError($listRes['error']['message']); break; }

            $nextNumber = 1;
            $list = $listRes['data'] ?? [];
            if (!empty($list)) {
                $lastId = $list[0]['favorite_id'] ?? '';
                if (preg_match('/\d+/', $lastId, $m)) {
                    $nextNumber = (int)$m[0] + 1;
                }
            }
            $nextId = 'FA' . str_pad((string)$nextNumber, 4, '0', STR_PAD_LEFT);

            // 2. INSERT with generated ID
            $finalData = array_merge($body, ['favorite_id' => $nextId]);
            $res = dbInsert('favorites', $finalData);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'update':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbUpdate('favorites', ['favorite_id' => 'eq.' . $id], $body);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'delete':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbDelete('favorites', ['favorite_id' => 'eq.' . $id]);
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
