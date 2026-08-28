<?php
/**
 * translate_logs_api.php
 * ย้าย logic จาก translateLogsApi.js → PHP
 * Table: translate_logs (PK: log_id)
 *
 * Actions (GET):
 *   ?action=getAll              → SELECT * ORDER BY log_id ASC
 *   ?action=getById&id=         → SELECT * WHERE log_id = id
 *
 * Actions (POST):
 *   ?action=create              → INSERT (body: JSON)
 *   ?action=update&id=          → UPDATE WHERE log_id = id (body: JSON)
 *   ?action=delete&id=          → DELETE WHERE log_id = id
 */

require_once __DIR__ . '/../config/db.php';
setCorsHeaders();

/* $action = $_GET['action'] ?? ''; */
$action = $_GET['action'] ?? 'getAll';

// ===== GET =====
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    switch ($action) {

        case 'getAll':
            $res = dbSelect('translate_logs', '*', [], 'log_id.asc');
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'getById':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbSelectSingle('translate_logs', '*', ['log_id' => 'eq.' . $id]);
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
            if (empty($body['log_id'])) {
                $body['log_id'] = 'TL' . str_pad((string)mt_rand(1, 9999), 4, '0', STR_PAD_LEFT);
            }
            if (empty($body['created_at'])) {
                $body['created_at'] = date('Y-m-d H:i:s');
            }
            $allowed = ['log_id', 'category_vocab_id', 'translate_type', 'input_text', 'output_text', 'created_at'];
            $cleanData = [];
            foreach ($allowed as $f) {
                if (isset($body[$f]) && $body[$f] !== null && $body[$f] !== '') {
                    $cleanData[$f] = $body[$f];
                }
            }
            if (!isset($cleanData['log_id'])) {
                $cleanData['log_id'] = 'TL' . str_pad((string)mt_rand(1, 9999), 4, '0', STR_PAD_LEFT);
            }
            // Check foreign key constraint for category_vocab_id
            if (!empty($cleanData['category_vocab_id'])) {
                $chk = dbSelectSingle('category_vocab', 'category_vocab_id', ['category_vocab_id' => 'eq.' . rawurlencode($cleanData['category_vocab_id'])]);
                if (!empty($chk['error']) || empty($chk['data'])) {
                    // Category ID doesn't exist in category_vocab table, set to null to avoid FK constraint error
                    unset($cleanData['category_vocab_id']);
                }
            }
            $res = dbInsert('translate_logs', $cleanData);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'update':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbUpdate('translate_logs', ['log_id' => 'eq.' . $id], $body);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'delete':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbDelete('translate_logs', ['log_id' => 'eq.' . $id]);
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
