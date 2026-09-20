<?php
// Public Front Page & Policy Router for Tenkasi Dreams Land Web Portal
$page = strtolower(trim($_GET['page'] ?? ''));

if ($page === 'debug_diag') {
    header('Content-Type: application/json');
    echo json_encode([
        'dir' => __DIR__,
        'file' => __FILE__,
        'server_time' => date('Y-m-d H:i:s'),
        'php_version' => PHP_VERSION,
        'doc_root' => $_SERVER['DOCUMENT_ROOT'] ?? '',
        'script_filename' => $_SERVER['SCRIPT_FILENAME'] ?? ''
    ]);
    exit();
}

if ($page === 'privacy' || $page === 'privacy-policy') {
    require_once __DIR__ . '/privacy.html';
    exit();
}

if ($page === 'terms' || $page === 'terms-conditions' || $page === 'terms-and-conditions') {
    require_once __DIR__ . '/terms.html';
    exit();
}

if ($page === 'refund' || $page === 'refund-policy' || $page === 'cancellation') {
    require_once __DIR__ . '/refund.html';
    exit();
}

// Default: Render Home Page
require_once __DIR__ . '/index.html';
