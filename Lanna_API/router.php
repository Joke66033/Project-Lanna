<?php
/**
 * router.php
 * Router script for PHP built-in web server.
 * Intercepts requests for static assets stored in sibling folders (lanna, Lanna_Admin)
 * and falls back to default PHP built-in server handling for regular PHP scripts.
 */

$uri = $_SERVER['REQUEST_URI'];
// Remove query string to get clean path
$path = parse_url($uri, PHP_URL_PATH);

// Clean up double slashes
$path = str_replace('//', '/', $path);

// Define patterns for profile image paths
$lannaProfilePattern = '#^/(LANNA/)?lanna/assets/images/profile/(.+)#i';
$adminProfilePattern = '#^/(LANNA/)?Lanna_Admin/src/assets/image/profile/(.+)#i';
$lannaArticlesPattern = '#^/(LANNA/)?lanna/assets/images/articles/(.+)#i';
$adminArticlesPattern = '#^/(LANNA/)?Lanna_Admin/src/assets/image/articles/(.+)#i';

// 1. Serve lanna mobile profile images
if (preg_match($lannaProfilePattern, $path, $matches)) {
    $filename = $matches[2];
    $filePath = 'D:\\PROJECT_LANNA\\lanna\\assets\\images\\profile\\' . $filename;
    serveStaticFile($filePath);
    exit;
}

// 2. Serve Lanna_Admin profile images
if (preg_match($adminProfilePattern, $path, $matches)) {
    $filename = $matches[2];
    $filePath = 'D:\\PROJECT_LANNA\\Lanna_Admin\\src\\assets\\image\\profile\\' . $filename;
    serveStaticFile($filePath);
    exit;
}

// 3. Serve lanna mobile articles images
if (preg_match($lannaArticlesPattern, $path, $matches)) {
    $filename = $matches[2];
    $filePath = 'D:\\PROJECT_LANNA\\lanna\\assets\\images\\articles\\' . $filename;
    serveStaticFile($filePath);
    exit;
}

// 4. Serve Lanna_Admin articles images
if (preg_match($adminArticlesPattern, $path, $matches)) {
    $filename = $matches[2];
    $filePath = 'D:\\PROJECT_LANNA\\Lanna_Admin\\src\\assets\\image\\articles\\' . $filename;
    serveStaticFile($filePath);
    exit;
}

/**
 * Serve static files with correct MIME type and headers.
 */
function serveStaticFile(string $filePath): void {
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
    header("Access-Control-Allow-Origin: $origin");
    header("Access-Control-Allow-Methods: GET, OPTIONS");
    header("Access-Control-Allow-Headers: Content-Type, Authorization, apikey");
    header('Access-Control-Allow-Credentials: true');

    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        exit();
    }

    if (file_exists($filePath) && !is_dir($filePath)) {
        $ext = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
        $mimeTypes = [
            'jpg'  => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'png'  => 'image/png',
            'gif'  => 'image/gif',
            'webp' => 'image/webp',
            'svg'  => 'image/svg+xml',
        ];
        
        $mimeType = $mimeTypes[$ext] ?? 'application/octet-stream';
        header('Content-Type: ' . $mimeType);
        header('Content-Length: ' . filesize($filePath));
        readfile($filePath);
    } else {
        http_response_code(404);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['error' => 'File not found: ' . basename($filePath)], JSON_UNESCAPED_UNICODE);
    }
}

// Return false so PHP built-in web server processes the requested PHP files or static files in document root
return false;
