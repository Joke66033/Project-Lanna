<?php
// Temporarily enable error display to diagnose HTTP 500 error
error_reporting(E_ALL);
ini_set('display_errors', '1');

// ===== PHP 8.0+ Polyfills for PHP 7.x Compatibility =====
if (!function_exists('str_contains')) {
    function str_contains(string $haystack, string $needle): bool {
        return $needle !== '' && strpos($haystack, $needle) !== false;
    }
}

if (!function_exists('str_starts_with')) {
    function str_starts_with(string $haystack, string $needle): bool {
        return strncmp($haystack, $needle, strlen($needle)) === 0;
    }
}

if (!function_exists('str_ends_with')) {
    function str_ends_with(string $haystack, string $needle): bool {
        return $needle === '' || $needle === substr($haystack, -strlen($needle));
    }
}

/**
 * Custom PHP/MySQL Database Client (Standard phpMyAdmin / PDO connection)
 */

// ===== Load .env =====
function loadEnv(string $path): void {
    if (!file_exists($path)) return;
    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        $line = trim($line);
        // Use PHP 7 compatible functions (avoid str_starts_with and str_contains for compatibility)
        if ($line === '' || strpos($line, '#') === 0) continue;
        if (strpos($line, '=') === false) continue;
        [$name, $value] = explode('=', $line, 2);
        
        $value = trim($value);
        // Clean wrapping quotes from env values if present
        $len = strlen($value);
        if ($len > 1 && (
            ($value[0] === '"' && $value[$len - 1] === '"') ||
            ($value[0] === "'" && $value[$len - 1] === "'")
        )) {
            $value = substr($value, 1, -1);
        }
        
        $_ENV[trim($name)] = $value;
    }
}

loadEnv(__DIR__ . '/../.env');

// ===== PDO Database Connection =====
$db_conn = null;
function getPdo(): PDO {
    global $db_conn;
    if ($db_conn !== null) return $db_conn;
    
    $host = $_ENV['DB_HOST'] ?? 'localhost';
    $dbname = $_ENV['DB_NAME'] ?? 'lanna_db';
    $username = $_ENV['DB_USER'] ?? 'root';
    $password = $_ENV['DB_PASSWORD'] ?? '';
    $port = $_ENV['DB_PORT'] ?? '3306';
    
    $dsn = "mysql:host=$host;dbname=$dbname;port=$port;charset=utf8mb4";
    try {
        $db_conn = new PDO($dsn, $username, $password, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
        return $db_conn;
    } catch (PDOException $e) {
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['data' => null, 'error' => ['message' => 'Database connection failed: ' . $e->getMessage()]], JSON_UNESCAPED_UNICODE);
        exit();
    }
}

// ===== Primary Key Helpers =====
function getPrimaryKeyField(string $table): string {
    switch ($table) {
        case 'admin_user': return 'admin_id';
        case 'articles': return 'article_id';
        case 'category_lanna_char': return 'category_char_id';
        case 'category_vocab': return 'category_vocab_id';
        case 'favorites': return 'favorite_id';
        case 'lanna_char': return 'char_id';
        case 'learning_category': return 'category_code';
        case 'translate_logs': return 'log_id';
        case 'users': return 'user_id';
        case 'vocabulary': return 'vocab_id';
        default: return 'id';
    }
}

// ===== CORS Headers =====
function setCorsHeaders(): void {
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
    header("Access-Control-Allow-Origin: $origin");
    header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
    header("Access-Control-Allow-Headers: Content-Type, Authorization, apikey");
    header('Access-Control-Allow-Credentials: true');
    header('Content-Type: application/json; charset=utf-8');

    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        exit();
    }
}

// ===== Query Parsers =====
function parseFilters(string $table, array $filters, array &$params): string {
    $whereParts = [];
    foreach ($filters as $col => $expr) {
        $cleanColName = '';
        if (strpos($col, '.') !== false) {
            $parts = explode('.', $col);
            $cleanColName = "`" . implode("`.`", $parts) . "`";
        } else {
            $cleanColName = "`$table`.`$col`";
        }
        
        $paramName = str_replace('.', '_', $col) . '_' . count($params);

        if ($col === 'or') {
            $expr = trim($expr, '()');
            $orParts = explode(',', $expr);
            $orSql = [];
            foreach ($orParts as $part) {
                $subParts = explode('.', $part, 3);
                if (count($subParts) >= 3) {
                    $subCol = $subParts[0];
                    $subOp = $subParts[1];
                    $subVal = rawurldecode($subParts[2]);
                    
                    $subColClean = strpos($subCol, '.') !== false 
                        ? "`" . implode("`.`", explode('.', $subCol)) . "`" 
                        : "`$table`.`$subCol`";
                    $subParamName = 'or_' . str_replace('.', '_', $subCol) . '_' . count($params);
                    
                    if ($subOp === 'ilike') {
                        $orSql[] = "$subColClean LIKE :$subParamName";
                        $params[$subParamName] = str_replace('*', '%', $subVal);
                    } else if ($subOp === 'eq') {
                        $orSql[] = "$subColClean = :$subParamName";
                        $params[$subParamName] = $subVal;
                    }
                }
            }
            if (!empty($orSql)) {
                $whereParts[] = '(' . implode(' OR ', $orSql) . ')';
            }
        } else {
            $parts = explode('.', $expr, 2);
            if (count($parts) === 2) {
                $op = $parts[0];
                $val = rawurldecode($parts[1]);
                
                if ($op === 'eq') {
                    $whereParts[] = "$cleanColName = :$paramName";
                    $params[$paramName] = $val;
                } else if ($op === 'ilike') {
                    $whereParts[] = "$cleanColName LIKE :$paramName";
                    $params[$paramName] = str_replace('*', '%', $val);
                } else if ($op === 'neq') {
                    $whereParts[] = "$cleanColName != :$paramName";
                    $params[$paramName] = $val;
                }
            } else {
                $whereParts[] = "$cleanColName = :$paramName";
                $params[$paramName] = $expr;
            }
        }
    }
    return !empty($whereParts) ? ' WHERE ' . implode(' AND ', $whereParts) : '';
}

function parseOrder(string $order): string {
    if (empty($order)) return '';
    $parts = explode('.', $order, 2);
    $col = $parts[0];
    $dir = isset($parts[1]) && strtolower($parts[1]) === 'desc' ? 'DESC' : 'ASC';
    return " ORDER BY `$col` $dir";
}

function buildSelectQuery(string $table, string $select, string $whereClause, string $orderClause, string $limitClause): string {
    $joinClause = '';
    $selectedColumns = ["`$table`.*"];
    
    $joinVocab = $table !== 'category_vocab' && (
        strpos($select, 'category_vocab(') !== false || 
        strpos($select, 'category_vocab!inner') !== false ||
        strpos($whereClause, '`category_vocab`.') !== false
    );
    $joinLannaChar = $table !== 'category_lanna_char' && (
        strpos($select, 'category_lanna_char(') !== false || 
        strpos($select, 'category_lanna_char!inner') !== false ||
        strpos($whereClause, '`category_lanna_char`.') !== false
    );
    
    if ($joinVocab) {
        $joinClause .= " LEFT JOIN `category_vocab` ON `$table`.`category_vocab_id` = `category_vocab`.`category_vocab_id`";
        $selectedColumns[] = "`category_vocab`.`name` AS `category_vocab_name`";
    }
    if ($joinLannaChar) {
        $joinClause .= " LEFT JOIN `category_lanna_char` ON `$table`.`category_char_id` = `category_lanna_char`.`category_char_id`";
        $selectedColumns[] = "`category_lanna_char`.`name` AS `category_lanna_char_name`";
        
        $joinLearning = strpos($select, 'learning_category(') !== false || 
                       strpos($select, 'learning_category!inner') !== false ||
                       strpos($whereClause, '`learning_category`.') !== false;
        if ($joinLearning) {
            $joinClause .= " LEFT JOIN `learning_category` ON `category_lanna_char`.`learning_category_code` = `learning_category`.`category_code`";
            $selectedColumns[] = "`category_lanna_char`.`learning_category_code` AS `category_lanna_char_learning_category_code`";
            $selectedColumns[] = "`learning_category`.`title` AS `learning_category_title`";
            $selectedColumns[] = "`learning_category`.`category_code` AS `learning_category_code`";
        }
    }
    
    if ($table === 'category_lanna_char') {
        $joinLearning = strpos($select, 'learning_category(') !== false || 
                       strpos($select, 'learning_category!inner') !== false ||
                       strpos($whereClause, '`learning_category`.') !== false;
        if ($joinLearning) {
            $joinClause .= " LEFT JOIN `learning_category` ON `$table`.`learning_category_code` = `learning_category`.`category_code`";
            $selectedColumns[] = "`learning_category`.`title` AS `learning_category_title`";
            $selectedColumns[] = "`learning_category`.`category_code` AS `learning_category_code`";
        }
    }
    
    if (strtolower(trim($select)) === 'count(*)') {
        $colsStr = 'count(*)';
    } else {
        $colsStr = implode(', ', $selectedColumns);
    }
    return "SELECT $colsStr FROM `$table` $joinClause $whereClause $orderClause $limitClause";
}

function formatRow(?array $row): ?array {
    if ($row === null) return null;
    
    if (isset($row['category_vocab_name'])) {
        $row['category_vocab'] = ['name' => $row['category_vocab_name']];
        unset($row['category_vocab_name']);
    }
    if (isset($row['category_lanna_char_name'])) {
        $row['category_lanna_char'] = [
            'name' => $row['category_lanna_char_name'],
            'learning_category_code' => $row['category_lanna_char_learning_category_code'] ?? null,
            'learning_category' => isset($row['learning_category_title']) ? [
                'title' => $row['learning_category_title'],
                'category_code' => $row['learning_category_code'] ?? null
            ] : null
        ];
        unset($row['category_lanna_char_name']);
        if (isset($row['category_lanna_char_learning_category_code'])) unset($row['category_lanna_char_learning_category_code']);
        if (isset($row['learning_category_title'])) unset($row['learning_category_title']);
        if (isset($row['learning_category_code'])) unset($row['learning_category_code']);
    }
    if (isset($row['learning_category_title'])) {
        $row['learning_category'] = [
            'title' => $row['learning_category_title'],
            'category_code' => $row['learning_category_code'] ?? null
        ];
        unset($row['learning_category_title']);
        unset($row['learning_category_code']);
    }
    if (isset($row['is_active'])) {
        $row['is_active'] = (bool)$row['is_active'];
    }
    if (isset($row['private'])) {
        $row['private'] = (bool)$row['private'];
    }
    return $row;
}

// ===== Database Request Interface =====

function dbRequest(
    string $method,
    string $table,
    array  $queryParams  = [],
           $body         = null,
    array  $extraHeaders = []
): array {
    $method = strtoupper($method);
    if ($method === 'GET') {
        $select = $queryParams['select'] ?? '*';
        $order = $queryParams['order'] ?? '';
        $limit = isset($queryParams['limit']) ? (int)$queryParams['limit'] : 0;
        
        $filters = [];
        foreach ($queryParams as $k => $v) {
            if (in_array($k, ['select', 'order', 'limit'], true)) continue;
            $filters[$k] = $v;
        }
        return dbSelect($table, $select, $filters, $order, $limit);
    } elseif ($method === 'POST') {
        return dbInsert($table, $body);
    } elseif ($method === 'PATCH' || $method === 'PUT') {
        $filters = [];
        foreach ($queryParams as $k => $v) {
            $filters[$k] = $v;
        }
        return dbUpdate($table, $filters, $body);
    } elseif ($method === 'DELETE') {
        $filters = [];
        foreach ($queryParams as $k => $v) {
            $filters[$k] = $v;
        }
        return dbDelete($table, $filters);
    }
    return ['data' => null, 'error' => ['message' => 'Unsupported method ' . $method]];
}

// ===== Convenience wrappers =====

function dbSelect(string $table, string $select = '*', array $filters = [], string $order = '', int $limit = 0): array {
    $pdo = getPdo();
    $params = [];
    $whereClause = parseFilters($table, $filters, $params);
    $orderClause = parseOrder($order);
    $limitClause = $limit > 0 ? " LIMIT $limit" : "";
    
    $sql = buildSelectQuery($table, $select, $whereClause, $orderClause, $limitClause);
    
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $formattedRows = array_map('formatRow', $rows);
        return ['data' => $formattedRows, 'error' => null];
    } catch (PDOException $e) {
        return ['data' => null, 'error' => ['message' => 'Database error: ' . $e->getMessage()]];
    }
}

function dbSelectSingle(string $table, string $select = '*', array $filters = []): array {
    $pdo = getPdo();
    $params = [];
    $whereClause = parseFilters($table, $filters, $params);
    
    $sql = buildSelectQuery($table, $select, $whereClause, '', ' LIMIT 1');
    
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row) {
            return ['data' => null, 'error' => ['message' => 'Row not found']];
        }
        return ['data' => formatRow($row), 'error' => null];
    } catch (PDOException $e) {
        return ['data' => null, 'error' => ['message' => 'Database error: ' . $e->getMessage()]];
    }
}

function dbInsert(string $table, array $data): array {
    $pdo = getPdo();
    $cols = array_keys($data);
    $placeholders = array_map(function($c) { return ":$c"; }, $cols);
    
    $sql = "INSERT INTO `$table` (`" . implode("`, `", $cols) . "`) VALUES (" . implode(", ", $placeholders) . ")";
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($data);
        
        $pk = getPrimaryKeyField($table);
        if ($pk && isset($data[$pk])) {
            $selectRes = dbSelectSingle($table, '*', [$pk => 'eq.' . $data[$pk]]);
            return $selectRes;
        }
        return ['data' => $data, 'error' => null];
    } catch (PDOException $e) {
        return ['data' => null, 'error' => ['message' => 'Database error: ' . $e->getMessage()]];
    }
}

function dbUpdate(string $table, array $filters, array $data): array {
    $pdo = getPdo();
    $params = [];
    
    $setParts = [];
    foreach ($data as $col => $val) {
        $setParts[] = "`$col` = :set_$col";
        $params["set_$col"] = $val;
    }
    
    $whereClause = parseFilters($table, $filters, $params);
    $sql = "UPDATE `$table` SET " . implode(", ", $setParts) . $whereClause;
    
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        
        $pk = getPrimaryKeyField($table);
        $pkVal = null;
        if (isset($filters[$pk])) {
            $parts = explode('.', $filters[$pk], 2);
            $pkVal = count($parts) === 2 ? rawurldecode($parts[1]) : rawurldecode($filters[$pk]);
        }
        
        if ($pkVal) {
            $selectRes = dbSelectSingle($table, '*', [$pk => 'eq.' . $pkVal]);
            return $selectRes;
        }
        return ['data' => $data, 'error' => null];
    } catch (PDOException $e) {
        return ['data' => null, 'error' => ['message' => 'Database error: ' . $e->getMessage()]];
    }
}

function dbDelete(string $table, array $filters): array {
    $pdo = getPdo();
    $params = [];
    
    $pk = getPrimaryKeyField($table);
    $pkVal = null;
    if (isset($filters[$pk])) {
        $parts = explode('.', $filters[$pk], 2);
        $pkVal = count($parts) === 2 ? rawurldecode($parts[1]) : rawurldecode($filters[$pk]);
    }
    
    $rowData = null;
    if ($pkVal) {
        $selectRes = dbSelectSingle($table, '*', [$pk => 'eq.' . $pkVal]);
        $rowData = $selectRes['data'];
    }
    
    $whereClause = parseFilters($table, $filters, $params);
    $sql = "DELETE FROM `$table`" . $whereClause;
    
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        return ['data' => $rowData ?? [], 'error' => null];
    } catch (PDOException $e) {
        return ['data' => null, 'error' => ['message' => 'Database error: ' . $e->getMessage()]];
    }
}

// ===== Output helpers =====
function jsonOk($data): void {
    echo json_encode(['data' => $data, 'error' => null], JSON_UNESCAPED_UNICODE);
}

function jsonError(string $message, int $status = 400): void {
    http_response_code($status);
    echo json_encode(['data' => null, 'error' => ['message' => $message]], JSON_UNESCAPED_UNICODE);
}

// ===== Read JSON body =====
function getJsonBody(): array {
    $raw = file_get_contents('php://input');
    return json_decode($raw, true) ?? [];
}
