<?php
// ==========================================================
// Tenkasi Dreams Land - Live Users & User Management API
// Tracks Active Online Users & Enables Super Admin Direct Messaging
// ==========================================================

require_once __DIR__ . '/config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$liveUsersFile = DATA_DIR . '/live_users.json';
$adminMsgsFile = DATA_DIR . '/admin_messages.json';

function getJsonData($file, $default = []) {
    if (!file_exists($file)) return $default;
    $raw = file_get_contents($file);
    $data = json_decode($raw, true);
    return is_array($data) ? $data : $default;
}

function saveJsonData($file, $data) {
    file_put_contents($file, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
}

function cleanPhone($phone) {
    return preg_replace('/[^0-9]/', '', (string)$phone);
}

// Auto-create live_users & admin_messages tables in MySQL if connected
$pdo = getDbConnection();
if ($pdo) {
    try {
        $pdo->exec("CREATE TABLE IF NOT EXISTS `live_users` (
            `id` VARCHAR(64) PRIMARY KEY,
            `user_id` VARCHAR(64) NOT NULL,
            `user_name` VARCHAR(150) NOT NULL,
            `user_phone` VARCHAR(50) DEFAULT '',
            `user_email` VARCHAR(150) DEFAULT '',
            `platform` VARCHAR(50) DEFAULT 'Android App',
            `current_screen` VARCHAR(255) DEFAULT 'Home',
            `role` VARCHAR(50) DEFAULT 'buyer',
            `ip_address` VARCHAR(64) DEFAULT '',
            `last_active` DATETIME NOT NULL,
            `created_at` DATETIME NOT NULL,
            INDEX (`user_id`),
            INDEX (`user_phone`),
            INDEX (`last_active`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");

        $pdo->exec("CREATE TABLE IF NOT EXISTS `admin_direct_messages` (
            `id` VARCHAR(64) PRIMARY KEY,
            `user_id` VARCHAR(64) DEFAULT '',
            `user_phone` VARCHAR(50) NOT NULL,
            `user_name` VARCHAR(150) DEFAULT '',
            `admin_name` VARCHAR(150) DEFAULT 'Super Admin',
            `message` TEXT NOT NULL,
            `is_read` TINYINT(1) DEFAULT 0,
            `created_at` DATETIME NOT NULL,
            INDEX (`user_phone`),
            INDEX (`is_read`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;");
    } catch (Exception $e) {
        error_log('Table creation error in users.php: ' . $e->getMessage());
    }
}

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$action = $_GET['action'] ?? ($_POST['action'] ?? 'list_live');

switch ($method) {
    case 'GET':
        // 1. List Live Users for Super Admin
        if ($action === 'list_live' || $action === 'list') {
            $liveUsers = [];
            $now = time();

            if ($pdo) {
                try {
                    $stmt = $pdo->query("SELECT * FROM `live_users` ORDER BY `last_active` DESC LIMIT 300");
                    $liveUsers = $stmt->fetchAll(PDO::FETCH_ASSOC);
                } catch (Exception $e) {}
            }

            if (empty($liveUsers)) {
                $liveUsers = getJsonData($liveUsersFile, []);
                usort($liveUsers, function($a, $b) {
                    return strtotime($b['last_active'] ?? '0') <=> strtotime($a['last_active'] ?? '0');
                });
            }

            $activeNowCount = 0;
            $appUsersCount = 0;
            $webUsersCount = 0;
            $formattedUsers = [];

            foreach ($liveUsers as $u) {
                $lastActiveTime = strtotime($u['last_active'] ?? '0');
                $diffSec = $now - $lastActiveTime;

                // Status calculation:
                // <= 180s (3 mins) -> Online
                // <= 900s (15 mins) -> Idle
                // > 900s -> Offline
                $status = 'offline';
                $isOnline = false;
                if ($diffSec <= 180) {
                    $status = 'online';
                    $isOnline = true;
                    $activeNowCount++;
                } elseif ($diffSec <= 900) {
                    $status = 'idle';
                }

                $platform = $u['platform'] ?? 'Android App';
                if (stripos($platform, 'web') !== false) {
                    if ($isOnline) $webUsersCount++;
                } else {
                    if ($isOnline) $appUsersCount++;
                }

                $formattedUsers[] = [
                    'id' => $u['id'] ?? ('user_' . rand(100, 999)),
                    'user_id' => $u['user_id'] ?? '',
                    'user_name' => $u['user_name'] ?? 'Customer',
                    'user_phone' => $u['user_phone'] ?? '',
                    'user_email' => $u['user_email'] ?? '',
                    'platform' => $platform,
                    'current_screen' => $u['current_screen'] ?? 'Home',
                    'role' => $u['role'] ?? 'buyer',
                    'last_active' => $u['last_active'] ?? date('Y-m-d H:i:s'),
                    'last_active_diff' => $diffSec,
                    'status' => $status,
                    'is_online' => $isOnline
                ];
            }

            sendResponse([
                'success' => true,
                'stats' => [
                    'active_now' => $activeNowCount,
                    'app_active' => $appUsersCount,
                    'web_active' => $webUsersCount,
                    'total_users' => count($formattedUsers)
                ],
                'users' => $formattedUsers,
                'server_time' => date('Y-m-d H:i:s')
            ]);
            break;
        }

        // 2. Fetch admin messages for a specific user
        if ($action === 'get_admin_messages') {
            $userPhone = cleanPhone($_GET['user_phone'] ?? '');
            $userId = trim($_GET['user_id'] ?? '');
            $messages = [];

            if ($pdo && (!empty($userPhone) || !empty($userId))) {
                try {
                    $stmt = $pdo->prepare("SELECT * FROM `admin_direct_messages` 
                        WHERE (REPLACE(REPLACE(REPLACE(user_phone, ' ', ''), '+', ''), '-', '') LIKE ?) 
                           OR (`user_id` = ? AND `user_id` != '') 
                        ORDER BY `created_at` DESC LIMIT 50");
                    $stmt->execute(['%' . $userPhone . '%', $userId]);
                    $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);
                } catch (Exception $e) {}
            }

            if (empty($messages)) {
                $allMsgs = getJsonData($adminMsgsFile, []);
                $messages = array_values(array_filter($allMsgs, function($m) use ($userPhone, $userId) {
                    $p = cleanPhone($m['user_phone'] ?? '');
                    return (!empty($userPhone) && strpos($p, $userPhone) !== false) || (!empty($userId) && ($m['user_id'] ?? '') === $userId);
                }));
            }

            sendResponse([
                'success' => true,
                'messages' => $messages
            ]);
            break;
        }

        sendResponse(['success' => false, 'error' => 'Invalid GET action'], 400);
        break;

    case 'POST':
        $rawInput = file_get_contents('php://input');
        $input = json_decode($rawInput, true) ?? $_POST;
        $postAction = $input['action'] ?? $_GET['action'] ?? 'heartbeat';

        // 1. Heartbeat / Ping from App or Web
        if ($postAction === 'heartbeat' || $postAction === 'ping') {
            $userId = trim($input['user_id'] ?? $input['userId'] ?? '');
            $userName = trim($input['user_name'] ?? $input['userName'] ?? 'Customer');
            $userPhone = trim($input['user_phone'] ?? $input['userPhone'] ?? '');
            $userEmail = trim($input['user_email'] ?? $input['userEmail'] ?? '');
            $platform = trim($input['platform'] ?? 'Android App');
            $currentScreen = trim($input['current_screen'] ?? $input['currentScreen'] ?? 'Home');
            $role = trim($input['role'] ?? 'buyer');
            $ipAddress = $_SERVER['REMOTE_ADDR'] ?? '';
            $now = date('Y-m-d H:i:s');

            // Unique record key per user or phone
            $cleanP = cleanPhone($userPhone);
            $recordId = !empty($cleanP) ? ('live_' . $cleanP) : (!empty($userId) ? ('live_' . $userId) : ('live_guest_' . md5($ipAddress . '_' . $platform)));

            $userRecord = [
                'id' => $recordId,
                'user_id' => $userId,
                'user_name' => $userName,
                'user_phone' => $userPhone,
                'user_email' => $userEmail,
                'platform' => $platform,
                'current_screen' => $currentScreen,
                'role' => $role,
                'ip_address' => $ipAddress,
                'last_active' => $now,
                'created_at' => $now
            ];

            // 1. Upsert into MySQL
            if ($pdo) {
                try {
                    $stmt = $pdo->prepare("INSERT INTO `live_users` 
                        (`id`, `user_id`, `user_name`, `user_phone`, `user_email`, `platform`, `current_screen`, `role`, `ip_address`, `last_active`, `created_at`) 
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) 
                        ON DUPLICATE KEY UPDATE 
                        `user_name` = VALUES(`user_name`), 
                        `user_email` = VALUES(`user_email`), 
                        `platform` = VALUES(`platform`), 
                        `current_screen` = VALUES(`current_screen`), 
                        `role` = VALUES(`role`), 
                        `last_active` = VALUES(`last_active`)");
                    $stmt->execute([
                        $recordId, $userId, $userName, $userPhone, $userEmail, $platform, $currentScreen, $role, $ipAddress, $now, $now
                    ]);
                } catch (Exception $e) {
                    error_log('Live user MySQL update error: ' . $e->getMessage());
                }
            }

            // 2. Upsert into JSON
            $allUsers = getJsonData($liveUsersFile, []);
            $foundIndex = -1;
            foreach ($allUsers as $idx => $u) {
                if (($u['id'] ?? '') === $recordId || (!empty($cleanP) && cleanPhone($u['user_phone'] ?? '') === $cleanP)) {
                    $foundIndex = $idx;
                    break;
                }
            }
            if ($foundIndex !== -1) {
                $userRecord['created_at'] = $allUsers[$foundIndex]['created_at'] ?? $now;
                $allUsers[$foundIndex] = $userRecord;
            } else {
                array_unshift($allUsers, $userRecord);
            }
            if (count($allUsers) > 1000) {
                $allUsers = array_slice($allUsers, 0, 1000);
            }
            saveJsonData($liveUsersFile, $allUsers);

            // 3. Check for any unread admin messages for this user
            $unreadAdminMsgs = [];
            if (!empty($cleanP)) {
                if ($pdo) {
                    try {
                        $mStmt = $pdo->prepare("SELECT * FROM `admin_direct_messages` 
                            WHERE (REPLACE(REPLACE(REPLACE(user_phone, ' ', ''), '+', ''), '-', '') LIKE ?) 
                              AND `is_read` = 0 ORDER BY `created_at` ASC");
                        $mStmt->execute(['%' . $cleanP . '%']);
                        $unreadAdminMsgs = $mStmt->fetchAll(PDO::FETCH_ASSOC);
                    } catch (Exception $e) {}
                }
                if (empty($unreadAdminMsgs)) {
                    $allMsgs = getJsonData($adminMsgsFile, []);
                    $unreadAdminMsgs = array_values(array_filter($allMsgs, function($m) use ($cleanP) {
                        return cleanPhone($m['user_phone'] ?? '') === $cleanP && empty($m['is_read']);
                    }));
                }
            }

            sendResponse([
                'success' => true,
                'status' => 'online',
                'server_time' => $now,
                'unread_admin_messages' => $unreadAdminMsgs
            ]);
            break;
        }

        // 2. Super Admin Sends Direct Message to User
        if ($postAction === 'send_admin_message') {
            $userPhone = trim($input['user_phone'] ?? $input['userPhone'] ?? '');
            $userId = trim($input['user_id'] ?? $input['userId'] ?? '');
            $userName = trim($input['user_name'] ?? $input['userName'] ?? 'Customer');
            $adminName = trim($input['admin_name'] ?? $input['adminName'] ?? 'Super Admin');
            $message = trim($input['message'] ?? $input['text'] ?? '');

            if (empty($message)) {
                sendResponse(['success' => false, 'error' => 'Message cannot be empty'], 400);
            }
            if (empty($userPhone) && empty($userId)) {
                sendResponse(['success' => false, 'error' => 'User phone or ID is required'], 400);
            }

            $msgId = 'adm_msg_' . time() . '_' . rand(100, 999);
            $now = date('Y-m-d H:i:s');

            $msgRecord = [
                'id' => $msgId,
                'user_id' => $userId,
                'user_phone' => $userPhone,
                'user_name' => $userName,
                'admin_name' => $adminName,
                'message' => $message,
                'is_read' => 0,
                'created_at' => $now
            ];

            // Save in MySQL
            if ($pdo) {
                try {
                    $stmt = $pdo->prepare("INSERT INTO `admin_direct_messages` 
                        (`id`, `user_id`, `user_phone`, `user_name`, `admin_name`, `message`, `is_read`, `created_at`) 
                        VALUES (?, ?, ?, ?, ?, ?, 0, ?)");
                    $stmt->execute([$msgId, $userId, $userPhone, $userName, $adminName, $message, $now]);
                } catch (Exception $e) {}
            }

            // Save in JSON
            $allMsgs = getJsonData($adminMsgsFile, []);
            array_unshift($allMsgs, $msgRecord);
            if (count($allMsgs) > 1000) $allMsgs = array_slice($allMsgs, 0, 1000);
            saveJsonData($adminMsgsFile, $allMsgs);

            // Also log in user activities so Super Admin sees it in timeline
            $actFile = DATA_DIR . '/activities.json';
            $allActs = getJsonData($actFile, []);
            array_unshift($allActs, [
                'id' => 'act_' . time() . '_' . rand(100, 999),
                'user_name' => $userName,
                'user_phone' => $userPhone,
                'user_email' => '',
                'action_type' => 'admin_direct_message',
                'action_title' => '🛡️ அட்மின் நேரடி செய்தி அனுப்பப்பட்டது (Admin Message)',
                'property_id' => '',
                'property_title' => 'Direct Message to ' . $userName,
                'seller_name' => $adminName,
                'seller_phone' => 'Super Admin',
                'amount' => 0.0,
                'details' => $message,
                'created_at' => $now
            ]);
            saveJsonData($actFile, array_slice($allActs, 0, 2000));

            sendResponse([
                'success' => true,
                'message' => 'செய்தி வெற்றிகரமாக பயனருக்கு அனுப்பப்பட்டது (Message sent to user)',
                'data' => $msgRecord
            ]);
            break;
        }

        // 3. Mark Admin Message as Read
        if ($postAction === 'mark_read') {
            $msgId = trim($input['message_id'] ?? $input['msgId'] ?? '');
            if ($pdo && !empty($msgId)) {
                try {
                    $stmt = $pdo->prepare("UPDATE `admin_direct_messages` SET `is_read` = 1 WHERE `id` = ?");
                    $stmt->execute([$msgId]);
                } catch (Exception $e) {}
            }
            $allMsgs = getJsonData($adminMsgsFile, []);
            foreach ($allMsgs as &$m) {
                if (($m['id'] ?? '') === $msgId) {
                    $m['is_read'] = 1;
                    break;
                }
            }
            saveJsonData($adminMsgsFile, $allMsgs);

            sendResponse(['success' => true]);
            break;
        }

        sendResponse(['success' => false, 'error' => 'Invalid POST action'], 400);
        break;

    default:
        sendResponse(['success' => false, 'error' => 'Method not allowed'], 405);
}
