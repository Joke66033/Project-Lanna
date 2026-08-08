<?php
/**
 * learning_category_api.php
 * ตัวจัดการ API สำหรับหมวดหมู่การเรียนรู้หลัก (Learning Category)
 * Table: learning_category (PK: category_code เช่น LC001, LC002)
 *
 * Actions (GET):
 *   ?action=getAll              → ดึงข้อมูลหมวดหมู่ทั้งหมด เรียงตาม category_code ASC
 *                                 รองรับ parameter ?with_children=true เพื่อดึงข้อมูลอักขระหมวดหมู่ย่อย (category_lanna_char) แนบมาด้วย
 *   ?action=getById&id=         → ดึงข้อมูลหมวดหมู่ระบุตาม PK (category_code)
 *   ?action=checkUsage&id=      → ตรวจสอบว่ามีการใช้งานหมวดหมู่ในตารางย่อยหรือไม่
 *
 * Actions (POST):
 *   ?action=create              → สร้างหมวดหมู่ใหม่
 *   ?action=update&id=          → อัปเดตข้อมูลหมวดหมู่ตามรหัสที่กำหนด
 *   ?action=delete&id=&cascade= → ลบข้อมูลหมวดหมู่ (ถ้า cascade=true จะตั้งค่าหมวดหมู่ย่อยเป็น NULL)
 */

require_once __DIR__ . '/../config/db.php';
setCorsHeaders();

$action = $_GET['action'] ?? 'getAll';

// ===== GET METHODS =====
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    switch ($action) {

        case 'getAll':
            $withChildren = ($_GET['with_children'] ?? '') === 'true';
            $selectStr = $withChildren ? '*,category_lanna_char(*)' : '*';
            
            $onlyActive = ($_GET['only_active'] ?? '') === 'true';
            $filters = [];
            if ($onlyActive) {
                $filters['is_active'] = 'eq.true';
            }
            
            $res = dbSelect('learning_category', $selectStr, $filters, 'category_code.asc');
            if ($res['error']) {
                jsonError($res['error']['message']);
                break;
            }

            $categories = $res['data'] ?? [];
            for ($i = 0; $i < count($categories); $i++) {
                $catCode = $categories[$i]['category_code'] ?? '';
                if ($catCode !== '') {
                    $subCatsRes = dbSelect('category_lanna_char', 'category_char_id', ['learning_category_code' => 'eq.' . rawurlencode($catCode)]);
                    if (!$subCatsRes['error'] && !empty($subCatsRes['data'])) {
                        $subIds = array_column($subCatsRes['data'], 'category_char_id');
                        if (!empty($subIds)) {
                            $subIdStrs = array_map(function($id) { return rawurlencode($id); }, $subIds);
                            $inFilter = 'in.(' . implode(',', $subIdStrs) . ')';
                            $charCountRes = dbSelect('lanna_char', 'char_id', ['category_char_id' => $inFilter]);
                            if (!$charCountRes['error'] && is_array($charCountRes['data'])) {
                                $categories[$i]['total_items'] = count($charCountRes['data']);
                            }
                        }
                    }
                }
            }

            jsonOk($categories);
            break;

        case 'getById':
            $id = $_GET['id'] ?? '';
            if ($id === '') {
                jsonError('กรุณาระบุรหัสหมวดหมู่ (Missing category_code)');
                break;
            }
            $res = dbSelectSingle('learning_category', '*', ['category_code' => 'eq.' . rawurlencode($id)]);
            if ($res['error']) {
                jsonError($res['error']['message']);
                break;
            }
            $catData = $res['data'];
            if ($catData && isset($catData['category_code'])) {
                $subCatsRes = dbSelect('category_lanna_char', 'category_char_id', ['learning_category_code' => 'eq.' . rawurlencode($catData['category_code'])]);
                if (!$subCatsRes['error'] && !empty($subCatsRes['data'])) {
                    $subIds = array_column($subCatsRes['data'], 'category_char_id');
                    if (!empty($subIds)) {
                        $subIdStrs = array_map(function($id) { return rawurlencode($id); }, $subIds);
                        $inFilter = 'in.(' . implode(',', $subIdStrs) . ')';
                        $charCountRes = dbSelect('lanna_char', 'char_id', ['category_char_id' => $inFilter]);
                        if (!$charCountRes['error'] && is_array($charCountRes['data'])) {
                            $catData['total_items'] = count($charCountRes['data']);
                        }
                    }
                }
            }
            jsonOk($catData);
            break;

        case 'checkUsage':
            $id = $_GET['id'] ?? '';
            if ($id === '') { jsonError('Missing id'); break; }
            $pdo = getPdo();
            $stmt = $pdo->prepare("SELECT COUNT(*) FROM `category_lanna_char` WHERE `learning_category_code` = :id");
            $stmt->execute(['id' => $id]);
            $count = (int)$stmt->fetchColumn();
            jsonOk(['inUse' => ($count > 0), 'subCategoryCount' => $count]);
            break;

        default:
            jsonError('ไม่พบ Action ที่ระบุ');
    }
}

// ===== POST METHODS =====
elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $body = getJsonBody();

    switch ($action) {

        case 'create':
            $code = trim($body['category_code'] ?? '');
            if ($code === '') {
                $listRes = dbSelect('learning_category', 'category_code', [], 'category_code.desc', 1);
                if ($listRes['error']) {
                    jsonError($listRes['error']['message']);
                    break;
                }

                $nextNumber = 1;
                $list = $listRes['data'] ?? [];
                if (!empty($list)) {
                    $lastId = trim($list[0]['category_code'] ?? '');
                    if (preg_match('/\d+/', $lastId, $m)) {
                        $nextNumber = (int)$m[0] + 1;
                    }
                }
                $code = 'LC' . str_pad((string)$nextNumber, 3, '0', STR_PAD_LEFT);
            }

            $title = trim($body['title'] ?? '');
            if ($title === '') {
                jsonError('กรุณากรอกหัวข้อหมวดหมู่การเรียนรู้ (Title is required)');
                break;
            }

            $finalData = [
                'category_code' => $code,
                'title'         => $title,
                'description'   => $body['description'] ?? '',
                'is_active'     => isset($body['is_active']) ? (int)$body['is_active'] : 1,
            ];

            $res = dbInsert('learning_category', $finalData);
            if ($res['error']) {
                jsonError($res['error']['message']);
                break;
            }
            jsonOk($res['data']);
            break;

        case 'update':
            $id = $_GET['id'] ?? '';
            if ($id === '') {
                jsonError('กรุณาระบุรหัสหมวดหมู่ที่ต้องการแก้ไข (Missing id)');
                break;
            }

            $updateData = [];
            if (isset($body['title']))       $updateData['title'] = trim($body['title']);
            if (isset($body['description'])) $updateData['description'] = trim($body['description']);
            if (isset($body['is_active']))   $updateData['is_active'] = (int)$body['is_active'];

            $res = dbUpdate('learning_category', ['category_code' => 'eq.' . rawurlencode($id)], $updateData);
            if ($res['error']) {
                jsonError($res['error']['message']);
                break;
            }
            $resRow = dbSelectSingle('learning_category', '*', ['category_code' => 'eq.' . rawurlencode($id)]);
            if ($resRow['data']) {
                jsonOk($resRow['data']);
            } else {
                jsonOk(array_merge(['category_code' => $id], $updateData));
            }
            break;

        case 'delete':
            $id = $_GET['id'] ?? '';
            if ($id === '') {
                jsonError('กรุณาระบุรหัสหมวดหมู่ที่ต้องการลบ (Missing id)');
                break;
            }

            $cascade = ($_GET['cascade'] ?? '') === 'true';
            try {
                $pdo = getPdo();

                if ($count > 0) {
                    jsonError('ไม่สามารถลบข้อมูลได้ เนื่องจากมีการใช้งานหมวดหมู่นี้อยู่');
                    break;
                }

                // 2. หากไม่มีการอ้างอิง สามารถลบข้อมูลหมวดหมู่ได้
                $res = dbDelete('learning_category', ['category_code' => 'eq.' . rawurlencode($id)]);
                if ($res['error']) {
                    jsonError($res['error']['message']);
                    break;
                }
                jsonOk($res['data']);
            } catch (Exception $e) {
                jsonError('Database delete error: ' . $e->getMessage());
            }
            break;

        default:
            jsonError('ไม่พบ Action ที่ระบุ');
    }
}

else {
    jsonError('Method not allowed', 405);
}
