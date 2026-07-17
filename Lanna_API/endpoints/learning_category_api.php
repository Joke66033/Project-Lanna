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
 *
 * Actions (POST):
 *   ?action=create              → สร้างหมวดหมู่ใหม่ (กำหนดรหัสเอง หรือให้ระบบ auto-generate รหัส LC### ลำดับถัดไปอัตโนมัติ)
 *   ?action=update&id=          → อัปเดตข้อมูลหมวดหมู่ตามรหัสที่กำหนด
 *   ?action=delete&id=          → ลบข้อมูลหมวดหมู่ตามรหัสที่กำหนด
 */

require_once __DIR__ . '/../config/db.php';
setCorsHeaders();

$action = $_GET['action'] ?? 'getAll';

// ===== GET METHODS =====
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    switch ($action) {

        case 'getAll':
            // รองรับการดึงข้อมูลแบบ nested children ถ้าส่ง parameter with_children=true
            $withChildren = ($_GET['with_children'] ?? '') === 'true';
            $selectStr = $withChildren ? '*,category_lanna_char(*)' : '*';
            
            // ดึงข้อมูลเฉพาะที่ is_active = true หรือไม่
            $onlyActive = ($_GET['only_active'] ?? '') === 'true';
            $filters = [];
            if ($onlyActive) {
                $filters['is_active'] = 'eq.true';
            }
            
            // ดึงข้อมูลจัดเรียงตามรหัสหมวดหมู่จากน้อยไปมาก
            $res = dbSelect('learning_category', $selectStr, $filters, 'category_code.asc');
            if ($res['error']) {
                jsonError($res['error']['message']);
                break;
            }
            jsonOk($res['data']);
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
            jsonOk($res['data']);
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
            // 1. ตรวจสอบรหัส category_code (หากเว้นว่าง ให้ระบบ auto-generate รูปแบบ LC###)
            $code = trim($body['category_code'] ?? '');
            if ($code === '') {
                // ดึงข้อมูลรหัสล่าสุดเพื่อนำมาคำนวณรหัสถัดไป
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

            // 2. ตรวจสอบข้อมูลจำเป็น (Required Fields validation)
            $title = trim($body['title'] ?? '');
            if ($title === '') {
                jsonError('กรุณากรอกหัวข้อหมวดหมู่การเรียนรู้ (Title is required)');
                break;
            }

            // กรองและกำหนดค่าเริ่มต้นข้อมูลสำหรับการบันทึก
            $finalData = [
                'category_code' => $code,
                'title'         => $title,
                'description'   => $body['description'] ?? '',
                'is_active'     => isset($body['is_active']) ? (int)$body['is_active'] : 1,
                'total_items'   => isset($body['total_items']) ? (int)$body['total_items'] : 0,
            ];

            // 3. ทำการ INSERT ข้อมูลลงตาราง learning_category
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

            // กรองข้อมูลเฉพาะฟิลด์ที่ได้รับอนุญาตให้แก้ไขได้เท่านั้น
            $updateData = [];
            if (isset($body['title']))       $updateData['title'] = trim($body['title']);
            if (isset($body['description'])) $updateData['description'] = trim($body['description']);
            if (isset($body['is_active']))   $updateData['is_active'] = (int)$body['is_active'];
            if (isset($body['total_items'])) $updateData['total_items'] = (int)$body['total_items'];

            // ทำการ UPDATE ข้อมูลลงในฐานข้อมูล
            $res = dbUpdate('learning_category', ['category_code' => 'eq.' . rawurlencode($id)], $updateData);
            if ($res['error']) {
                jsonError($res['error']['message']);
                break;
            }
            jsonOk($res['data']);
            break;

        case 'delete':
            $id = $_GET['id'] ?? '';
            if ($id === '') {
                jsonError('กรุณาระบุรหัสหมวดหมู่ที่ต้องการลบ (Missing id)');
                break;
            }

            // ทำการ DELETE ข้อมูลออกจากฐานข้อมูล
            $res = dbDelete('learning_category', ['category_code' => 'eq.' . rawurlencode($id)]);
            if ($res['error']) {
                jsonError($res['error']['message']);
                break;
            }
            jsonOk($res['data']);
            break;

        default:
            jsonError('ไม่พบ Action ที่ระบุ');
    }
}

else {
    jsonError('Method not allowed', 405);
}
