<?php
header('Content-Type: application/json');
echo json_encode([
    'status' => 'success',
    'message' => 'Hello World from angie.local!',
    'timestamp' => date('Y-m-d H:i:s'),
    'remote_ip' => $_SERVER['REMOTE_ADDR']
]);