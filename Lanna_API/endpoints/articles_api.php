<?php
/**
 * articles_api.php
 * ย้าย logic จาก articlesApi.js → PHP
 * Table: articles (PK: article_id)
 *
 * Actions (GET):
 *   ?action=getAll           → SELECT * ORDER BY article_id ASC
 *   ?action=getById&id=      → SELECT * WHERE article_id = id
 *
 * Actions (POST):
 *   ?action=create           → INSERT (body: JSON)
 *   ?action=update&id=       → UPDATE WHERE article_id = id (body: JSON)
 *   ?action=delete&id=       → DELETE WHERE article_id = id
 */

require_once __DIR__ . '/../config/db.php';
setCorsHeaders();

/* $action = $_GET['action'] ?? ''; */
$action = $_GET['action'] ?? 'getAll';

// ===== GET =====
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    switch ($action) {

        case 'getAll':
            $filters = [];
            $category_char_id = $_GET['category_char_id'] ?? '';
            $learning_category_code = $_GET['learning_category_code'] ?? '';
            
            // ใช้ postgrest embedding เพื่อ join ตาราง category_lanna_char และ learning_category อัตโนมัติ
            $selectStr = '*,category_lanna_char(*,learning_category(*))';
            
            if ($category_char_id !== '') {
                if (str_contains($category_char_id, ',')) {
                    $filters['category_char_id'] = 'in.(' . $category_char_id . ')';
                } else {
                    $filters['category_char_id'] = 'eq.' . $category_char_id;
                }
            }
            
            // กรองตามรหัสหมวดหมู่การเรียนรู้หลัก (Learning Category Code) หากมีการระบุมา
            if ($learning_category_code !== '') {
                // บังคับทำ inner join เพื่อกรองแถวเฉพาะตามเงื่อนไข relation ของตาราง category_lanna_char
                $selectStr = '*,category_lanna_char!inner(*,learning_category(*))';
                $filters['category_lanna_char.learning_category_code'] = 'eq.' . $learning_category_code;
            }
            
            $res = dbSelect('articles', $selectStr, $filters, 'article_id.desc');
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'getById':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            // ดึงข้อมูลรายตัวพร้อมดึงข้อมูล relations
            $res = dbSelectSingle('articles', '*,category_lanna_char(*,learning_category(*))', ['article_id' => 'eq.' . $id]);
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
            // 1. ดึง ID ล่าสุดเพื่อ increment (AR#### format)
            $listRes = dbSelect('articles', 'article_id', [], 'article_id.desc', 1);
            if ($listRes['error']) { jsonError($listRes['error']['message']); break; }

            $nextNumber = 1;
            $list = $listRes['data'] ?? [];
            if (!empty($list)) {
                $lastId = trim($list[0]['article_id'] ?? '');
                if (preg_match('/\d+/', $lastId, $m)) {
                    $nextNumber = (int)$m[0] + 1;
                }
            }
            $nextId = 'AR' . str_pad((string)$nextNumber, 4, '0', STR_PAD_LEFT);

            $insertData = [
                'article_id'       => $nextId,
                'title'            => $body['title'] ?? '',
                'content'          => $body['content'] ?? '',
                'image_path'       => $body['image_path'] ?? $body['cover_image_url'] ?? '',
                'category_char_id' => !empty($body['category_char_id']) ? $body['category_char_id'] : null
            ];

            $res = dbInsert('articles', $insertData);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            
            $insertedId = $res['data']['article_id'] ?? $nextId;
            $resRow = dbSelectSingle('articles', '*', ['article_id' => 'eq.' . $insertedId]);
            if ($resRow['data']) {
                jsonOk($resRow['data']);
            } else {
                jsonOk($insertData);
            }
            break;

        case 'update':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }

            $updateData = [];
            if (array_key_exists('title', $body))            $updateData['title'] = $body['title'];
            if (array_key_exists('content', $body))          $updateData['content'] = $body['content'];
            if (array_key_exists('image_path', $body) || array_key_exists('cover_image_url', $body)) {
                $updateData['image_path'] = $body['image_path'] ?? ($body['cover_image_url'] ?? '');
            }
            if (array_key_exists('category_char_id', $body)) $updateData['category_char_id'] = !empty($body['category_char_id']) ? $body['category_char_id'] : null;

            $res = dbUpdate('articles', ['article_id' => 'eq.' . rawurlencode($id)], $updateData);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            
            $resRow = dbSelectSingle('articles', '*', ['article_id' => 'eq.' . rawurlencode($id)]);
            if ($resRow['data']) {
                jsonOk($resRow['data']);
            } else {
                jsonOk(array_merge(['article_id' => $id], $updateData));
            }
            break;

        case 'delete':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbDelete('articles', ['article_id' => 'eq.' . $id]);
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
