<?php
/**
 * category_vocab_api.php
 * ย้าย logic จาก categoryVocabApi.js → PHP
 * Table: category_vocab (PK: category_vocab_id เช่น CV0001, CV0002)
 *
 * Actions (GET):
 *   ?action=getAll              → SELECT * ORDER BY category_vocab_id ASC
 *   ?action=getById&id=         → SELECT * WHERE category_vocab_id = id
 *
 * Actions (POST):
 *   ?action=create              → auto-generate ID (CV####) แล้ว INSERT
 *   ?action=update&id=          → UPDATE WHERE category_vocab_id = id
 *   ?action=delete&id=          → DELETE WHERE category_vocab_id = id
 */

require_once __DIR__ . '/../config/db.php';
setCorsHeaders();

/* $action = $_GET['action'] ?? ''; */
$action = $_GET['action'] ?? 'getAll';

// ===== GET =====
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    switch ($action) {

        case 'getAll':
            $res = dbSelect('category_vocab', '*', [], 'category_vocab_id.desc');
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'getById':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbSelectSingle('category_vocab', '*', ['category_vocab_id' => 'eq.' . rawurlencode($id)]);
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
            // 1. ดึง ID ล่าสุดเพื่อ increment (เหมือน JS เดิม)
            $listRes = dbSelect('category_vocab', 'category_vocab_id', [], 'category_vocab_id.desc', 1);
            if ($listRes['error']) { jsonError($listRes['error']['message']); break; }

            $nextNumber = 1;
            $list = $listRes['data'] ?? [];
            if (!empty($list)) {
                $lastId = $list[0]['category_vocab_id'] ?? '';
                if (preg_match('/\d+/', $lastId, $m)) {
                    $nextNumber = (int)$m[0] + 1;
                }
            }
            $nextId = 'CV' . str_pad((string)$nextNumber, 4, '0', STR_PAD_LEFT);

            $insertData = [
                'category_vocab_id' => $nextId,
                'name'              => $body['name'] ?? ''
            ];
            $res = dbInsert('category_vocab', $insertData);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'update':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            
            $updateData = [];
            if (array_key_exists('name', $body)) $updateData['name'] = $body['name'];

            $res = dbUpdate('category_vocab', ['category_vocab_id' => 'eq.' . rawurlencode($id)], $updateData);
            if ($res['error']) { jsonError($res['error']['message']); break; }

            $resRow = dbSelectSingle('category_vocab', '*', ['category_vocab_id' => 'eq.' . rawurlencode($id)]);
            if ($resRow['data']) {
                jsonOk($resRow['data']);
            } else {
                jsonOk(array_merge(['category_vocab_id' => $id], $updateData));
            }
            break;

        case 'delete':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }

            try {
                $pdo = getPdo();

                // 1. ตรวจสอบว่ามีการใช้คำศัพท์ในหมวดหมู่นี้ในตาราง vocabulary หรือไม่
                $stmt = $pdo->prepare("SELECT COUNT(*) FROM `vocabulary` WHERE `category_vocab_id` = :id");
                $stmt->execute(['id' => $id]);
                $count = (int)$stmt->fetchColumn();

                if ($count > 0) {
                    jsonError('ไม่สามารถลบข้อมูลได้ เนื่องจากมีการใช้งานหมวดหมู่นี้อยู่');
                    break;
                }

                // 2. หากไม่มีการอ้างอิง สามารถลบหมวดหมู่คำศัพท์ได้
                $stmtDel = $pdo->prepare("DELETE FROM `category_vocab` WHERE `category_vocab_id` = :id");
                $stmtDel->execute(['id' => $id]);

                jsonOk(['message' => 'Deleted category successfully']);
            } catch (Exception $e) {
                jsonError('Database delete error: ' . $e->getMessage());
            }
            break;

        default:
            jsonError('Unknown action');
    }
}

else {
    jsonError('Method not allowed', 405);
}
