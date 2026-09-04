<?php
/**
 * vocabulary_api.php
 * Table: vocabulary (PK: vocab_id เช่น V00001, V00002)
 * JOIN: category_vocab(name) → เพิ่ม field "category" = name หรือ "ทั่วไป"
 *
 * Actions (GET):
 *   ?action=getAll               → SELECT *,category_vocab(name) ORDER BY vocab_id ASC + mapping category
 *   ?action=getById&id=          → SELECT *,category_vocab(name) WHERE vocab_id = id + mapping
 *   ?action=search&keyword=      → OR filter บน lanna_word/reading/thai_word/meaning + mapping
 *
 * Actions (POST):
 *   ?action=create               → auto-generate ID (V#####), auto-generate lanna_word หากเว้นว่าง แล้ว INSERT
 *   ?action=update&id=           → UPDATE WHERE vocab_id = id (body: JSON)
 *   ?action=delete&id=           → DELETE WHERE vocab_id = id
 */

require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../helpers/lanna_generator.php';
setCorsHeaders();

$action = $_GET['action'] ?? 'getAll';

// ===== Helper: map category_vocab nested object → "category" field =====
function mapVocabCategory(array $items): array {
    return array_map(function ($item) {
        // PDO join คืนชื่อหมวดเป็น category_vocab_name
        $item['category'] = $item['category_vocab_name']
            ?? ($item['category_vocab']['name'] ?? 'คำศัพท์ทั่วไป');
        return $item;
    }, $items);
}

// ===== GET =====
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    switch ($action) {

        case 'getAll':
            try {
                $pdo = getPdo();
                // Delete any vocabulary entries where category_vocab_id is NULL, empty, or no longer exists in category_vocab table
                $pdo->exec("DELETE FROM `vocabulary` WHERE `category_vocab_id` IS NULL OR `category_vocab_id` = '' OR `category_vocab_id` NOT IN (SELECT `category_vocab_id` FROM `category_vocab`)");
            } catch (Exception $e) {
                // Ignore cleanup error if table is locked
            }

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
            $kw = '*' . $keyword . '*';
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

        case 'translate':
            $keyword = $_GET['keyword'] ?? $_GET['text'] ?? '';
            if ($keyword === '') { jsonError('Missing keyword'); break; }
            $res = translateThaiToLannaFull($keyword);
            jsonOk(array_merge(['status' => 'success', 'thai_word' => $keyword], $res));
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

            // 2. Auto-generate lanna_word หากเว้นว่างไว้
            if (empty($body['lanna_word'])) {
                $baseText = !empty($body['thai_word']) ? $body['thai_word'] : ($body['reading'] ?? '');
                $body['lanna_word'] = generateLannaUnicode($baseText);
            }

            $insertData = [
                'vocab_id'          => $nextId,
                'thai_word'         => $body['thai_word'] ?? '',
                'lanna_word'        => $body['lanna_word'] ?? '',
                'reading'           => $body['reading'] ?? '',
                'meaning'           => $body['meaning'] ?? '',
                'category_vocab_id' => !empty($body['category_vocab_id']) ? $body['category_vocab_id'] : null
            ];
            $res = dbInsert('vocabulary', $insertData);
            if ($res['error']) { jsonError($res['error']['message']); break; }

            $resRow = dbSelectSingle('vocabulary', '*,category_vocab(name)', ['vocab_id' => 'eq.' . rawurlencode($nextId)]);
            if (!empty($resRow['data'])) {
                jsonOk(mapVocabCategory([$resRow['data']])[0]);
            } else {
                jsonOk($res['data'] ?? $insertData);
            }
            break;

        case 'update':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            if (empty($body['lanna_word']) && (!empty($body['thai_word']) || !empty($body['reading']))) {
                $baseText = !empty($body['thai_word']) ? $body['thai_word'] : ($body['reading'] ?? '');
                $body['lanna_word'] = generateLannaUnicode($baseText);
            }

            $updateData = [];
            if (array_key_exists('thai_word', $body))         $updateData['thai_word'] = $body['thai_word'];
            if (array_key_exists('lanna_word', $body))        $updateData['lanna_word'] = $body['lanna_word'];
            if (array_key_exists('reading', $body))           $updateData['reading'] = $body['reading'];
            if (array_key_exists('meaning', $body))           $updateData['meaning'] = $body['meaning'];
            if (array_key_exists('category_vocab_id', $body)) $updateData['category_vocab_id'] = !empty($body['category_vocab_id']) ? $body['category_vocab_id'] : null;

            $res = dbUpdate('vocabulary', $updateData, ['vocab_id' => 'eq.' . rawurlencode($id)]);
            if ($res['error']) { jsonError($res['error']['message']); break; }

            $resRow = dbSelectSingle('vocabulary', '*,category_vocab(name)', ['vocab_id' => 'eq.' . rawurlencode($id)]);
            if (!empty($resRow['data'])) {
                jsonOk(mapVocabCategory([$resRow['data']])[0]);
            } else {
                jsonOk(array_merge(['vocab_id' => $id], $updateData));
            }
            break;

        case 'delete':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbDelete('vocabulary', ['vocab_id' => 'eq.' . rawurlencode($id)]);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'translate':
            $keyword = $body['keyword'] ?? $body['text'] ?? $body['thai_word'] ?? $_GET['keyword'] ?? '';
            if ($keyword === '') { jsonError('Missing keyword'); break; }
            $res = translateThaiToLannaFull($keyword);
            jsonOk(array_merge(['status' => 'success', 'thai_word' => $keyword], $res));
            break;

        default:
            jsonError('Unknown action');
    }
}

else {
    jsonError('Method not allowed', 405);
}
