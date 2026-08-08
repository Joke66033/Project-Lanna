<?php
/**
 * category_lanna_char_api.php
 * ย้าย logic จาก categoryLannaCharApi.js → PHP
 * Table: category_lanna_char (PK: category_char_id เช่น CC0001, CC0002)
 *
 * Actions (GET):
 *   ?action=getAll              → SELECT * ORDER BY category_char_id ASC
 *   ?action=getById&id=         → SELECT * WHERE category_char_id = id
 *
 * Actions (POST):
 *   ?action=create              → auto-generate ID (CC####) แล้ว INSERT
 *   ?action=update&id=          → UPDATE WHERE category_char_id = id
 *   ?action=delete&id=          → DELETE WHERE category_char_id = id
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
            $learning_category_code = $_GET['learning_category_code'] ?? '';
            
            // กรองข้อมูลตามรหัสหมวดหมู่การเรียนรู้หลัก (learning_category_code)
            if ($learning_category_code !== '') {
                $filters['learning_category_code'] = 'eq.' . $learning_category_code;
            }
            
            $res = dbSelect('category_lanna_char', '*', $filters, 'category_char_id.desc');
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'getById':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $res = dbSelectSingle('category_lanna_char', '*', ['category_char_id' => 'eq.' . rawurlencode($id)]);
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
            // 1. ดึง ID ล่าสุดเพื่อดึงรูปแบบตัวนำหน้ารหัส (Prefix) และบวกเพิ่ม 1
            $listRes = dbSelect('category_lanna_char', 'category_char_id', [], 'category_char_id.desc', 1);
            if ($listRes['error']) { jsonError($listRes['error']['message']); break; }

            $nextNumber = 1;
            $prefix = 'CL'; // ใช้ CL เป็นค่าเริ่มต้นตามโครงสร้าง DB จริง
            $list = $listRes['data'] ?? [];
            if (!empty($list)) {
                $lastId = trim($list[0]['category_char_id'] ?? '');
                if (preg_match('/([A-Za-z]+)(\d+)/', $lastId, $m)) {
                    $prefix = $m[1];
                    $nextNumber = (int)$m[2] + 1;
                }
            }
            $nextId = $prefix . str_pad((string)$nextNumber, 4, '0', STR_PAD_LEFT);

            // 2. INSERT ข้อมูลพร้อมกับ ID และรหัสหมวดหมู่หลัก (learning_category_code)
            $finalData = [
                'category_char_id'       => $nextId,
                'name'                   => $body['name'] ?? '',
                'description'            => $body['description'] ?? '',
                'learning_category_code' => !empty($body['learning_category_code']) ? $body['learning_category_code'] : null,
                'is_active'              => isset($body['is_active']) ? (int)$body['is_active'] : 1
            ];
            $res = dbInsert('category_lanna_char', $finalData);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'update':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            
            $updateData = [];
            if (array_key_exists('name', $body))                   $updateData['name'] = $body['name'];
            if (array_key_exists('description', $body))            $updateData['description'] = $body['description'];
            if (array_key_exists('learning_category_code', $body)) $updateData['learning_category_code'] = !empty($body['learning_category_code']) ? $body['learning_category_code'] : null;
            if (array_key_exists('is_active', $body))              $updateData['is_active'] = (int)$body['is_active'];

            $res = dbUpdate('category_lanna_char', ['category_char_id' => 'eq.' . rawurlencode($id)], $updateData);
            if ($res['error']) { jsonError($res['error']['message']); break; }
            jsonOk($res['data']);
            break;

        case 'delete':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }

            try {
                $pdo = getPdo();

                // 1. ตรวจสอบว่ามีการใช้อักขระในหมวดหมู่นี้ในตาราง lanna_char หรือไม่
                $stmt1 = $pdo->prepare("SELECT COUNT(*) FROM `lanna_char` WHERE `category_char_id` = :id");
                $stmt1->execute(['id' => $id]);
                $count1 = (int)$stmt1->fetchColumn();

                // 2. ตรวจสอบว่ามีการใช้อักขระในหมวดหมู่นี้ในตาราง articles หรือไม่
                $stmt2 = $pdo->prepare("SELECT COUNT(*) FROM `articles` WHERE `category_char_id` = :id");
                $stmt2->execute(['id' => $id]);
                $count2 = (int)$stmt2->fetchColumn();

                if ($count1 > 0 || $count2 > 0) {
                    jsonError('ไม่สามารถลบข้อมูลได้ เนื่องจากมีการใช้งานหมวดหมู่นี้อยู่');
                    break;
                }

                // 3. หากไม่มีการอ้างอิง สามารถลบหมวดหมู่อักขระได้
                $stmtDel = $pdo->prepare("DELETE FROM `category_lanna_char` WHERE `category_char_id` = :id");
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
