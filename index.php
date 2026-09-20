<?php
// Public Front Page & Policy Router for Tenkasi Dreams Land Web Portal
$page = strtolower(trim($_GET['page'] ?? ''));

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
