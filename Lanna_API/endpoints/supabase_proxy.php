<?php
require_once __DIR__ . '/../config/db.php';
setCorsHeaders();

// Enable debug/errorsชั่วคราวเพื่อช่วยวิเคราะห์
error_reporting(E_ALL);
ini_set('display_errors', '1');

$requestUri = $_SERVER['REQUEST_URI'] ?? '';
$requestUri = explode('?', $requestUri)[0]; // ตัด query parameters ออก

$table = '';

// Check if table name is passed in query string (e.g. from ?table=)
$tableParam = $_GET['table'] ?? '';
if (!empty($tableParam)) {
    if (preg_match('/\/rest\/v1\/([a-zA-Z0-9_]+)/', $tableParam, $matches)) {
        $table = $matches[1];
    } else {
        $table = trim($tableParam, '/');
    }
}

// Fallback to request URI
if (empty($table)) {
    if (preg_match('/\/rest\/v1\/([a-zA-Z0-9_]+)/', $requestUri, $matches)) {
        $table = $matches[1];
    }
}

// Fallback to PATH_INFO
if (empty($table)) {
    $pathInfo = $_SERVER['PATH_INFO'] ?? '';
    if (preg_match('/\/rest\/v1\/([a-zA-Z0-9_]+)/', $pathInfo, $matches)) {
        $table = $matches[1];
    }
}

if (empty($table)) {
    jsonError('Table name not found in request URI: ' . $requestUri, 400);
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];

// Parse Range header สำหรับทำ Pagination (ตามแบบ PostgREST ของ Supabase)
$rangeHeader = $_SERVER['HTTP_RANGE'] ?? '';
if (empty($rangeHeader)) {
    $headers = getallheaders();
    $rangeHeader = $headers['Range'] ?? $headers['range'] ?? '';
}

$offset = 0;
$limit = 1000; // default limit
$hasRange = false;

if (!empty($rangeHeader) && preg_match('/(\d+)-(\d+)/', $rangeHeader, $matches)) {
    $from = (int)$matches[1];
    $to = (int)$matches[2];
    $offset = $from;
    $limit = $to - $from + 1;
    $hasRange = true;
} else {
    $queryParams = [];
    $queryString = $_SERVER['QUERY_STRING'] ?? '';
    if (!empty($queryString)) {
        $pairs = explode('&', $queryString);
        foreach ($pairs as $pair) {
            $parts = explode('=', $pair, 2);
            if (count($parts) === 2) {
                $key = rawurldecode($parts[0]);
                $val = rawurldecode($parts[1]);
                $queryParams[$key] = $val;
            }
        }
    }
    if (isset($queryParams['offset'])) {
        $offset = (int)$queryParams['offset'];
        $hasRange = true;
    }
    if (isset($queryParams['limit'])) {
        $limit = (int)$queryParams['limit'];
        $hasRange = true;
    }
}

if (!isset($queryParams)) {
    $queryParams = [];
    $queryString = $_SERVER['QUERY_STRING'] ?? '';
    if (!empty($queryString)) {
        $pairs = explode('&', $queryString);
        foreach ($pairs as $pair) {
            $parts = explode('=', $pair, 2);
            if (count($parts) === 2) {
                $key = rawurldecode($parts[0]);
                $val = rawurldecode($parts[1]);
                $queryParams[$key] = $val;
            }
        }
    }
}

$select = $queryParams['select'] ?? '*';
$order = $queryParams['order'] ?? '';

$filters = [];
foreach ($queryParams as $key => $value) {
    if (in_array($key, ['select', 'order', 'limit', 'offset', 'table'], true)) continue;
    $filters[$key] = $value;
}

if ($method === 'GET') {
    $pdo = getPdo();
    $params = [];
    $whereClause = parseFilters($table, $filters, $params);
    $orderClause = parseOrder($order);
    $limitClause = " LIMIT $limit OFFSET $offset";
    
    $sql = buildSelectQuery($table, $select, $whereClause, $orderClause, $limitClause);
    try {
        // 1. ดึงข้อมูลจริง
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $formattedRows = array_map('formatRow', $rows);
        
        // 2. นับจำนวนข้อมูลทั้งหมด (ถ้ามีการขอ Prefer: count หรือมี Pagination)
        $preferHeader = $_SERVER['HTTP_PREFER'] ?? '';
        if (empty($preferHeader)) {
            $headers = getallheaders();
            $preferHeader = $headers['Prefer'] ?? $headers['prefer'] ?? '';
        }
        
        $totalCount = null;
        if (strpos($preferHeader, 'count=exact') !== false || $hasRange) {
            $countSql = buildSelectQuery($table, "count(*)", $whereClause, "", "");
            $countStmt = $pdo->prepare($countSql);
            $countStmt->execute($params);
            $totalCount = (int)$countStmt->fetchColumn();
        }
        
        // 3. ส่ง Content-Range Header กลับไปตามมาตรฐาน PostgREST
        if ($totalCount !== null) {
            $toIndex = $offset + count($formattedRows) - 1;
            $toIndex = max(0, min($toIndex, $totalCount - 1));
            header("Content-Range: $offset-$toIndex/$totalCount");
        }
        
        // ส่งผลลัพธ์กลับในรูป JSON Array
        echo json_encode($formattedRows, JSON_UNESCAPED_UNICODE);
        exit();
    } catch (PDOException $e) {
        jsonError('Database error: ' . $e->getMessage(), 500);
        exit();
    }
} elseif ($method === 'POST') {
    $body = getJsonBody();
    $res = dbInsert($table, $body);
    if ($res['error']) {
        jsonError($res['error']['message'], 400);
    } else {
        header('HTTP/1.1 201 Created');
        echo json_encode([$res['data']], JSON_UNESCAPED_UNICODE);
    }
    exit();
} elseif ($method === 'PATCH') {
    $body = getJsonBody();
    $res = dbUpdate($table, $filters, $body);
    if ($res['error']) {
        jsonError($res['error']['message'], 400);
    } else {
        echo json_encode([$res['data']], JSON_UNESCAPED_UNICODE);
    }
    exit();
} elseif ($method === 'DELETE') {
    $res = dbDelete($table, $filters);
    if ($res['error']) {
        jsonError($res['error']['message'], 400);
    } else {
        echo json_encode([$res['data']], JSON_UNESCAPED_UNICODE);
    }
    exit();
} else {
    jsonError('Unsupported HTTP Method: ' . $method, 405);
}
