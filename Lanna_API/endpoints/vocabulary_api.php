<?php
/**
 * vocabulary_api.php
 * ย้าย logic จาก vocabularyApi.js → PHP
 * Table: vocabulary (PK: vocab_id เช่น V00001, V00002)
 * JOIN: category_vocab(name) → เพิ่ม field "category" = name หรือ "ทั่วไป"
 *
 * Actions (GET):
 *   ?action=getAll               → SELECT *,category_vocab(name) ORDER BY vocab_id ASC + mapping category
 *   ?action=getById&id=          → SELECT *,category_vocab(name) WHERE vocab_id = id + mapping
 *   ?action=search&keyword=      → OR filter บน lanna_word/reading/thai_word/meaning + mapping
 *
 * Actions (POST):
 *   ?action=create               → auto-generate ID (V#####) แล้ว INSERT
 *   ?action=update&id=           → UPDATE WHERE vocab_id = id (body: JSON)
 *   ?action=delete&id=           → DELETE WHERE vocab_id = id
 */

require_once __DIR__ . '/../config/db.php';
setCorsHeaders();

/* $action = $_GET['action'] ?? ''; */
$action = $_GET['action'] ?? 'getAll';

// ===== Helper: map category_vocab nested object → "category" field =====
function mapVocabCategory(array $items): array {
    return array_map(function ($item) {
        $item['category'] = $item['category_vocab']['name'] ?? 'ทั่วไป';
        return $item;
    }, $items);
}

// ===== GET =====
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    switch ($action) {

        case 'getAll':
            // SELECT *,category_vocab(name) ORDER BY vocab_id.asc
            $res = dbRequest('GET', 'vocabulary', [
                'select' => '*,category_vocab(name)',
                'order'  => 'vocab_id.desc',
            ]);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk(mapVocabCategory($res['data'] ?? []));
            break;

        case 'getById':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbRequest('GET', 'vocabulary', [
                'select'   => '*,category_vocab(name)',
                'vocab_id' => 'eq.' . rawurlencode($id),
            ], null, ['Accept: application/vnd.pgrst.object+json']);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            $mapped = $res['data'] ? mapVocabCategory([$res['data']])[0] : null;
            jsonOk($mapped);
            break;

        case 'search':
            $keyword = $_GET['keyword'] ?? '';
            if ($keyword === '') { jsonError('Missing keyword'); break; }
            $kw = '*' . $keyword . '*';   // PostgREST ilike wildcard style
            $orFilter = 'lanna_word.ilike.' . $kw
                . ',reading.ilike.' . $kw
                . ',thai_word.ilike.' . $kw
                . ',meaning.ilike.' . $kw;

            $res = dbRequest('GET', 'vocabulary', [
                'select' => '*,category_vocab(name)',
                'or'     => '(' . $orFilter . ')',
            ]);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk(mapVocabCategory($res['data'] ?? []));
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
            // 1. ดึง ID ล่าสุดเพื่อ increment (V00001 format → 5 digits)
            $listRes = dbSelect('vocabulary', 'vocab_id', [], 'vocab_id.desc', 1);
            if ($listRes['error']) { jsonError($listRes['error']['message']); break; }

            $nextNumber = 1;
            $list = $listRes['data'] ?? [];
            if (!empty($list)) {
                $lastId = $list[0]['vocab_id'] ?? '';
                if (preg_match('/\d+/', $lastId, $m)) {
                    $nextNumber = (int)$m[0] + 1;
                }
            }
            $nextId = 'V' . str_pad((string)$nextNumber, 5, '0', STR_PAD_LEFT);

            // 2. INSERT with generated ID
            $finalData = array_merge($body, ['vocab_id' => $nextId]);
            $res = dbInsert('vocabulary', $finalData);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'update':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbUpdate('vocabulary', ['vocab_id' => 'eq.' . rawurlencode($id)], $body);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'delete':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbDelete('vocabulary', ['vocab_id' => 'eq.' . rawurlencode($id)]);
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
