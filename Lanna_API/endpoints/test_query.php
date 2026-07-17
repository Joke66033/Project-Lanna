<?php
require_once __DIR__ . '/../config/db.php';
$pdo = getPdo();
try {
    $sql = "UPDATE users SET avatar = 'https://siripaporn.lnw.mn/lanna/assets/images/profile/profile_US0002_1783965832.jpg' WHERE user_id = 'US0002'";
    $affected = $pdo->exec($sql);
    echo "Success! Affected rows: " . $affected;
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
