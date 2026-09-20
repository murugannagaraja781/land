<?php
require_once __DIR__ . '/config.php';
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

// Helper to get all properties - DB first, JSON fallback
function getPropertiesData() {
    $pdo = getDbConnection();
    if ($pdo) {
        try {
            $stmt = $pdo->query("SELECT * FROM `properties` ORDER BY `postedDate` DESC, `created_at` DESC");
            $rows = $stmt->fetchAll();
            if ($rows !== false) {
                $properties = [];
                foreach ($rows as $r) {
                    $prop = [
                        'id' => $r['id'],
                        'title' => $r['title'] ?? '',
                        'description' => $r['description'] ?? '',
                        'price' => (float)($r['price'] ?? 0),
                        'location' => $r['location'] ?? 'Tenkasi',
                        'city' => $r['city'] ?? 'Tenkasi',
                        'propertyType' => $r['propertyType'] ?? 'Land',
                        'areaSqFt' => (int)($r['areaSqFt'] ?? 0),
                        'superBuiltUpSqFt' => isset($r['superBuiltUpSqFt']) ? (int)$r['superBuiltUpSqFt'] : null,
                        'carpetAreaSqFt' => isset($r['carpetAreaSqFt']) ? (int)$r['carpetAreaSqFt'] : null,
                        'bedrooms' => isset($r['bedrooms']) && $r['bedrooms'] !== '' ? (int)$r['bedrooms'] : null,
                        'bathrooms' => isset($r['bathrooms']) && $r['bathrooms'] !== '' ? (int)$r['bathrooms'] : null,
                        'furnishingStatus' => $r['furnishingStatus'] ?? 'Unfurnished',
                        'facing' => $r['facing'] ?? 'East',
                        'floor' => $r['floor'] ?? 'Ground Floor',
                        'maintenanceMonthly' => isset($r['maintenanceMonthly']) ? (float)$r['maintenanceMonthly'] : null,
                        'landmark' => $r['landmark'] ?? '',
                        'posterType' => $r['posterType'] ?? 'Direct Owner',
                        'landUnit' => $r['landUnit'] ?? null,
                        'landUnitValue' => isset($r['landUnitValue']) ? (float)$r['landUnitValue'] : null,
                        'landFeatures' => json_decode($r['landFeatures'] ?? '[]', true) ?: [],
                        'approvalType' => $r['approvalType'] ?? null,
                        'isBankLoanAvailable' => (bool)($r['isBankLoanAvailable'] ?? false),
                        'isPriceNegotiable' => (bool)($r['isPriceNegotiable'] ?? true),
                        'waterSource' => $r['waterSource'] ?? 'Both',
                        'hasLift' => (bool)($r['hasLift'] ?? false),
                        'hasTrees' => (bool)($r['hasTrees'] ?? false),
                        'treesDetails' => $r['treesDetails'] ?? '',
                        'hasIncome' => (bool)($r['hasIncome'] ?? false),
                        'incomeDetails' => $r['incomeDetails'] ?? '',
                        'isLease' => (bool)($r['isLease'] ?? false),
                        'rentalSubType' => $r['rentalSubType'] ?? '',
                        'advanceAmount' => isset($r['advanceAmount']) ? (float)$r['advanceAmount'] : null,
                        'commercialAreaType' => $r['commercialAreaType'] ?? '',
                        'hasTable' => (bool)($r['hasTable'] ?? false),
                        'hasFan' => (bool)($r['hasFan'] ?? false),
                        'hasWaterSupply' => (bool)($r['hasWaterSupply'] ?? false),
                        'hasShutter' => (bool)($r['hasShutter'] ?? false),
                        'powerPhase' => $r['powerPhase'] ?? 'Single Phase',
                        'contactPhone' => $r['contactPhone'] ?? '+91 98941 74944',
                        'sellerName' => $r['sellerName'] ?? 'Direct Owner',
                        'sellerPhone' => $r['sellerPhone'] ?? '+91 98941 74944',
                        'imageKeys' => json_decode($r['imageKeys'] ?? '[]', true) ?: [],
                        'imageUrls' => json_decode($r['imageUrls'] ?? '[]', true) ?: [],
                        'amenities' => json_decode($r['amenities'] ?? '[]', true) ?: [],
                        'agent' => [
                            'id' => $r['agent_id'] ?? 'admin_agent',
                            'name' => $r['agent_name'] ?? $r['sellerName'] ?? 'Direct Owner',
                            'agencyName' => $r['agent_agencyName'] ?? 'நேரடி உரிமையாளர் (Direct Owner)',
                            'phone' => $r['agent_phone'] ?? $r['sellerPhone'] ?? '+91 98941 74944',
                            'email' => $r['agent_email'] ?? 'tenkasidreams@gmail.com'
                        ],
                        'postedDate' => $r['postedDate'] ?? $r['created_at'] ?? date('c'),
                        'status' => $r['status'] ?? 'active',
                        'isFavorite' => (bool)($r['isFavorite'] ?? false),
                        'isVerified' => (bool)($r['isVerified'] ?? true),
                        'isFeatured' => (bool)($r['isFeatured'] ?? false),
                        'isUserPosted' => (bool)($r['isUserPosted'] ?? false),
                        'views' => (int)($r['views'] ?? 0),
                        'enquiries' => (int)($r['enquiries'] ?? 0)
                    ];
                    $properties[] = $prop;
                }
                return $properties;
            }
        } catch (Exception $e) {
            // DB table query failed, fallback to json storage
        }
    }
    return readJsonStorage('properties.json');
}

// Helper to save property to DB + JSON
function savePropertyToDb($prop) {
    $pdo = getDbConnection();
    if (!$pdo) return false;

    try {
        $agent = $prop['agent'] ?? [];
        $sql = "INSERT INTO `properties` 
            (`id`, `title`, `description`, `price`, `location`, `city`, `propertyType`, `areaSqFt`, `superBuiltUpSqFt`, `carpetAreaSqFt`, `bedrooms`, `bathrooms`, `furnishingStatus`, `facing`, `floor`, `maintenanceMonthly`, `landmark`, `posterType`, `landUnit`, `landUnitValue`, `landFeatures`, `approvalType`, `isBankLoanAvailable`, `isPriceNegotiable`, `waterSource`, `hasLift`, `hasTrees`, `treesDetails`, `hasIncome`, `incomeDetails`, `isLease`, `rentalSubType`, `advanceAmount`, `commercialAreaType`, `hasTable`, `hasFan`, `hasWaterSupply`, `hasShutter`, `powerPhase`, `contactPhone`, `sellerName`, `sellerPhone`, `imageKeys`, `imageUrls`, `amenities`, `agent_id`, `agent_name`, `agent_agencyName`, `agent_phone`, `agent_email`, `postedDate`, `status`, `isFavorite`, `isVerified`, `isFeatured`, `isUserPosted`, `views`, `enquiries`)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE 
                `title`=VALUES(`title`), `description`=VALUES(`description`), `price`=VALUES(`price`),
                `location`=VALUES(`location`), `status`=VALUES(`status`), `isVerified`=VALUES(`isVerified`),
                `isFeatured`=VALUES(`isFeatured`), `views`=VALUES(`views`), `enquiries`=VALUES(`enquiries`)";
        
        $stmt = $pdo->prepare($sql);
        return $stmt->execute([
            $prop['id'],
            $prop['title'] ?? '',
            $prop['description'] ?? '',
            $prop['price'] ?? 0,
            $prop['location'] ?? 'Tenkasi',
            $prop['city'] ?? 'Tenkasi',
            $prop['propertyType'] ?? 'Land',
            $prop['areaSqFt'] ?? 0,
            $prop['superBuiltUpSqFt'] ?? null,
            $prop['carpetAreaSqFt'] ?? null,
            $prop['bedrooms'] ?? null,
            $prop['bathrooms'] ?? null,
            $prop['furnishingStatus'] ?? 'Unfurnished',
            $prop['facing'] ?? 'East',
            $prop['floor'] ?? 'Ground Floor',
            $prop['maintenanceMonthly'] ?? null,
            $prop['landmark'] ?? null,
            $prop['posterType'] ?? 'Direct Owner',
            $prop['landUnit'] ?? null,
            $prop['landUnitValue'] ?? null,
            json_encode($prop['landFeatures'] ?? [], JSON_UNESCAPED_UNICODE),
            $prop['approvalType'] ?? null,
            !empty($prop['isBankLoanAvailable']) ? 1 : 0,
            isset($prop['isPriceNegotiable']) ? ($prop['isPriceNegotiable'] ? 1 : 0) : 1,
            $prop['waterSource'] ?? 'Both',
            !empty($prop['hasLift']) ? 1 : 0,
            !empty($prop['hasTrees']) ? 1 : 0,
            $prop['treesDetails'] ?? null,
            !empty($prop['hasIncome']) ? 1 : 0,
            $prop['incomeDetails'] ?? null,
            !empty($prop['isLease']) ? 1 : 0,
            $prop['rentalSubType'] ?? null,
            $prop['advanceAmount'] ?? null,
            $prop['commercialAreaType'] ?? null,
            !empty($prop['hasTable']) ? 1 : 0,
            !empty($prop['hasFan']) ? 1 : 0,
            !empty($prop['hasWaterSupply']) ? 1 : 0,
            !empty($prop['hasShutter']) ? 1 : 0,
            $prop['powerPhase'] ?? null,
            $prop['contactPhone'] ?? '+91 98941 74944',
            $prop['sellerName'] ?? 'Direct Owner',
            $prop['sellerPhone'] ?? '+91 98941 74944',
            json_encode($prop['imageKeys'] ?? [], JSON_UNESCAPED_UNICODE),
            json_encode($prop['imageUrls'] ?? [], JSON_UNESCAPED_UNICODE),
            json_encode($prop['amenities'] ?? [], JSON_UNESCAPED_UNICODE),
            $agent['id'] ?? 'admin_agent',
            $agent['name'] ?? $prop['sellerName'] ?? 'Direct Owner',
            $agent['agencyName'] ?? 'நேரடி உரிமையாளர் (Direct Owner)',
            $agent['phone'] ?? $prop['sellerPhone'] ?? '+91 98941 74944',
            $agent['email'] ?? 'tenkasidreams@gmail.com',
            $prop['postedDate'] ?? date('Y-m-d H:i:s'),
            $prop['status'] ?? 'active',
            !empty($prop['isFavorite']) ? 1 : 0,
            isset($prop['isVerified']) ? ($prop['isVerified'] ? 1 : 0) : 1,
            !empty($prop['isFeatured']) ? 1 : 0,
            !empty($prop['isUserPosted']) ? 1 : 0,
            $prop['views'] ?? 0,
            $prop['enquiries'] ?? 0
        ]);
    } catch (Exception $e) {
        return false;
    }
}

// Helper to update property in DB
function updatePropertyInDb($id, $updates) {
    $pdo = getDbConnection();
    if (!$pdo) return false;

    try {
        $sets = [];
        $params = [];
        foreach ($updates as $k => $v) {
            if ($k === 'id' || $k === 'agent') continue;
            if (in_array($k, ['landFeatures', 'imageKeys', 'imageUrls', 'amenities'])) {
                $sets[] = "`$k` = ?";
                $params[] = json_encode($v, JSON_UNESCAPED_UNICODE);
            } elseif (is_bool($v)) {
                $sets[] = "`$k` = ?";
                $params[] = $v ? 1 : 0;
            } else {
                $sets[] = "`$k` = ?";
                $params[] = $v;
            }
        }
        if (empty($sets)) return false;
        $params[] = $id;
        $sql = "UPDATE `properties` SET " . implode(', ', $sets) . " WHERE `id` = ?";
        $stmt = $pdo->prepare($sql);
        return $stmt->execute($params);
    } catch (Exception $e) {
        return false;
    }
}

// Helper to delete property from DB
function deletePropertyFromDb($id) {
    $pdo = getDbConnection();
    if (!$pdo) return false;
    try {
        $stmt = $pdo->prepare("DELETE FROM `properties` WHERE `id` = ?");
        $stmt->execute([$id]);
        return $stmt->rowCount() > 0;
    } catch (Exception $e) {
        return false;
    }
}

// Helper to save all properties (JSON fallback + sync)
function savePropertiesData($properties) {
    writeJsonStorage('properties.json', $properties);
}

// Helper to update notifications file
function syncNotificationStatus($propertyId, $newStatus) {
    // Update JSON
    $notifsFile = DATA_DIR . '/notifications.json';
    if (file_exists($notifsFile)) {
        $notifs = json_decode(file_get_contents($notifsFile), true);
        if (is_array($notifs)) {
            $updated = false;
            foreach ($notifs as &$n) {
                if (($n['propertyId'] ?? '') == $propertyId) {
                    $n['status'] = $newStatus;
                    $n['isRead'] = true;
                    $updated = true;
                }
            }
            if ($updated) {
                file_put_contents($notifsFile, json_encode(array_values($notifs), JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
            }
        }
    }
    // Update DB
    $pdo = getDbConnection();
    if ($pdo) {
        try {
            $stmt = $pdo->prepare("UPDATE `notifications` SET `status` = ?, `isRead` = 1 WHERE `propertyId` = ?");
            $stmt->execute([$newStatus, $propertyId]);
        } catch (Exception $e) {}
    }
}

switch ($method) {
    case 'GET':
        $properties = getPropertiesData();
        
        // Single property lookup
        if (isset($_GET['id'])) {
            $id = $_GET['id'];
            foreach ($properties as $p) {
                if ($p['id'] == $id) {
                    sendResponse(['success' => true, 'property' => $p]);
                }
            }
            sendResponse(['success' => false, 'message' => 'விளம்பரம் கிடைக்கவில்லை (Property not found)'], 404);
        }

        // Search & Filter
        $filtered = $properties;

        // Category filter
        if (!empty($_GET['category']) && $_GET['category'] !== 'all') {
            $cat = strtolower($_GET['category']);
            $filtered = array_filter($filtered, function ($p) use ($cat) {
                $type = strtolower($p['propertyType'] ?? '');
                if ($cat === 'house' || $cat === 'villa') return str_contains($type, 'house') || str_contains($type, 'villa');
                if ($cat === 'land' || $cat === 'plot' || $cat === 'plots') return $type === 'land' || str_contains($type, 'land') || str_contains($type, 'plot');
                if ($cat === 'farmland' || $cat === 'thottam' || $cat === 'farm land') return str_contains($type, 'farm') || str_contains($type, 'thottam');
                if ($cat === 'shop' || $cat === 'commercial') return str_contains($type, 'shop') || str_contains($type, 'commercial') || str_contains($type, 'office');
                if ($cat === 'apartment' || $cat === 'flat') return str_contains($type, 'apartment') || str_contains($type, 'flat');
                if ($cat === 'rental' || $cat === 'lease') return ($p['isRental'] ?? false) || str_contains($type, 'rental') || str_contains($type, 'lease');
                return str_contains($type, $cat);
            });
        }

        // Status filter:
        // If status parameter is passed (e.g. status=pending, status=active, status=all)
        // Or if all=true is passed, show all.
        // By default for public requests without parameters, ONLY show 'active' properties!
        $showAll = (isset($_GET['all']) && $_GET['all'] === 'true');
        if (!empty($_GET['status']) && $_GET['status'] !== 'all') {
            $status = strtolower($_GET['status']);
            $filtered = array_filter($filtered, function ($p) use ($status) {
                return strtolower($p['status'] ?? 'active') === $status;
            });
        } elseif (!$showAll && empty($_GET['status'])) {
            // Strict default for public portal: ONLY active properties
            $filtered = array_filter($filtered, function ($p) {
                $st = strtolower($p['status'] ?? 'active');
                return $st === 'active';
            });
        }

        // Search query
        if (!empty($_GET['query']) || !empty($_GET['search'])) {
            $q = strtolower(trim($_GET['query'] ?? $_GET['search']));
            $filtered = array_filter($filtered, function ($p) use ($q) {
                return str_contains(strtolower($p['title'] ?? ''), $q) ||
                       str_contains(strtolower($p['location'] ?? ''), $q) ||
                       str_contains(strtolower($p['city'] ?? ''), $q) ||
                       str_contains(strtolower($p['description'] ?? ''), $q) ||
                       str_contains(strtolower($p['propertyType'] ?? ''), $q);
            });
        }

        sendResponse([
            'success' => true,
            'count' => count($filtered),
            'total' => count($properties),
            'properties' => array_values($filtered)
        ]);
        break;

    case 'POST':
        $action = $_GET['action'] ?? '';
        $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;
        if (empty($action) && isset($input['action'])) {
            $action = $input['action'];
        }

        // Handle Direct Admin Quick Approval Action
        if ($action === 'approve') {
            $propId = $input['id'] ?? $_GET['id'] ?? null;
            if (!$propId) {
                sendResponse(['success' => false, 'message' => 'Property ID is required for approval'], 400);
            }
            // Update in DB
            updatePropertyInDb($propId, ['status' => 'active', 'isVerified' => true]);
            // Update in JSON
            $properties = readJsonStorage('properties.json');
            foreach ($properties as &$p) {
                if ($p['id'] == $propId) {
                    $p['status'] = 'active';
                    $p['isVerified'] = true;
                    break;
                }
            }
            writeJsonStorage('properties.json', $properties);
            syncNotificationStatus($propId, 'approved');

            sendResponse([
                'success' => true,
                'message' => 'விளம்பரம் வெற்றிகரமாக ஒப்புதல் (Approved) அளிக்கப்பட்டு நேரலை செய்யப்பட்டது!',
                'propertyId' => $propId
            ]);
            break;
        }

        // Handle Direct Admin Quick Rejection Action
        if ($action === 'reject') {
            $propId = $input['id'] ?? $_GET['id'] ?? null;
            if (!$propId) {
                sendResponse(['success' => false, 'message' => 'Property ID is required for rejection'], 400);
            }
            // Update in DB
            updatePropertyInDb($propId, ['status' => 'rejected']);
            // Update in JSON
            $properties = readJsonStorage('properties.json');
            foreach ($properties as &$p) {
                if ($p['id'] == $propId) {
                    $p['status'] = 'rejected';
                    break;
                }
            }
            writeJsonStorage('properties.json', $properties);
            syncNotificationStatus($propId, 'rejected');

            sendResponse([
                'success' => true,
                'message' => 'விளம்பரம் நிராகரிக்கப்பட்டது (Property Rejected)',
                'propertyId' => $propId
            ]);
            break;
        }

        // Standard Property Creation (Public User or Admin)
        if (empty($input['title']) || empty($input['propertyType'])) {
            sendResponse(['success' => false, 'message' => 'விளம்பர தலைப்பு மற்றும் வகை தேவை (Title and Property Type are required)'], 400);
        }

        $newId = 'prop_' . (time()) . '_' . rand(100, 999);

        $isUserSubmission = !isset($input['fromAdmin']) || $input['fromAdmin'] !== true;
        $status = $isUserSubmission ? 'pending' : trim($input['status'] ?? 'active');
        $isVerified = $isUserSubmission ? false : (isset($input['isVerified']) ? (bool)$input['isVerified'] : true);
        $isUserPosted = $isUserSubmission ? true : (bool)($input['isUserPosted'] ?? false);

        $sellerName = trim($input['sellerName'] ?? $input['agent_name'] ?? $input['agentName'] ?? 'Direct Owner');
        $sellerPhone = trim($input['sellerPhone'] ?? $input['agent_phone'] ?? $input['contactPhone'] ?? '+91 98941 74944');

        $newProperty = [
            'id' => $newId,
            'title' => trim($input['title']),
            'description' => trim($input['description'] ?? ''),
            'price' => (float)($input['price'] ?? 0),
            'location' => trim($input['location'] ?? 'Tenkasi, Tamil Nadu'),
            'city' => trim($input['city'] ?? 'Tenkasi'),
            'propertyType' => trim($input['propertyType']),
            'areaSqFt' => (int)($input['areaSqFt'] ?? 0),
            'superBuiltUpSqFt' => (int)($input['superBuiltUpSqFt'] ?? $input['areaSqFt'] ?? 0),
            'carpetAreaSqFt' => (int)($input['carpetAreaSqFt'] ?? $input['areaSqFt'] ?? 0),
            'bedrooms' => isset($input['bedrooms']) && $input['bedrooms'] !== '' ? (int)$input['bedrooms'] : null,
            'bathrooms' => isset($input['bathrooms']) && $input['bathrooms'] !== '' ? (int)$input['bathrooms'] : null,
            'furnishingStatus' => trim($input['furnishingStatus'] ?? 'Unfurnished'),
            'facing' => trim($input['facing'] ?? 'East'),
            'floor' => trim($input['floor'] ?? 'Ground Floor'),
            'maintenanceMonthly' => isset($input['maintenanceMonthly']) ? (float)$input['maintenanceMonthly'] : null,
            'landmark' => trim($input['landmark'] ?? ''),
            'posterType' => trim($input['posterType'] ?? 'Direct Owner'),
            'landUnit' => trim($input['landUnit'] ?? 'Cent'),
            'landUnitValue' => isset($input['landUnitValue']) ? (float)$input['landUnitValue'] : null,
            'landFeatures' => is_array($input['landFeatures'] ?? null) ? $input['landFeatures'] : [],
            'approvalType' => trim($input['approvalType'] ?? 'DTCP Approved'),
            'isBankLoanAvailable' => (bool)($input['isBankLoanAvailable'] ?? false),
            'isPriceNegotiable' => (bool)($input['isPriceNegotiable'] ?? true),
            'waterSource' => trim($input['waterSource'] ?? 'Both'),
            'hasLift' => (bool)($input['hasLift'] ?? false),
            // Farmland
            'hasTrees' => (bool)($input['hasTrees'] ?? false),
            'treesDetails' => trim($input['treesDetails'] ?? ''),
            'hasIncome' => (bool)($input['hasIncome'] ?? false),
            'incomeDetails' => trim($input['incomeDetails'] ?? ''),
            // Rental & Commercial
            'isLease' => (bool)($input['isLease'] ?? false),
            'rentalSubType' => trim($input['rentalSubType'] ?? ''),
            'advanceAmount' => isset($input['advanceAmount']) ? (float)$input['advanceAmount'] : null,
            'commercialAreaType' => trim($input['commercialAreaType'] ?? ''),
            'hasTable' => (bool)($input['hasTable'] ?? false),
            'hasFan' => (bool)($input['hasFan'] ?? false),
            'hasWaterSupply' => (bool)($input['hasWaterSupply'] ?? false),
            'hasShutter' => (bool)($input['hasShutter'] ?? false),
            'powerPhase' => trim($input['powerPhase'] ?? 'Single Phase'),
            'contactPhone' => $sellerPhone,
            'sellerName' => $sellerName,
            'sellerPhone' => $sellerPhone,
            'imageKeys' => is_array($input['imageKeys'] ?? null) && count($input['imageKeys']) > 0 ? $input['imageKeys'] : ['house_1'],
            'imageUrls' => is_array($input['imageUrls'] ?? null) ? $input['imageUrls'] : (!empty($input['imageUrl']) ? [$input['imageUrl']] : []),
            'amenities' => is_array($input['amenities'] ?? null) ? $input['amenities'] : ['24x7 Security', 'Power Backup'],
            'agent' => [
                'id' => $isUserSubmission ? ('user_' . time()) : 'admin_agent',
                'name' => $sellerName,
                'agencyName' => $isUserSubmission ? 'நேரடி உரிமையாளர் (Direct Owner)' : 'Tenkasi Dreams Land',
                'phone' => $sellerPhone,
                'email' => trim($input['sellerEmail'] ?? 'tenkasidreams@gmail.com')
            ],
            'postedDate' => date('c'),
            'status' => $status,
            'isFavorite' => false,
            'isVerified' => $isVerified,
            'isFeatured' => isset($input['isFeatured']) ? (bool)$input['isFeatured'] : false,
            'isUserPosted' => $isUserPosted,
            'views' => 1,
            'enquiries' => 0
        ];

        // Save to DB
        savePropertyToDb($newProperty);

        // Save to JSON (as backup)
        $properties = readJsonStorage('properties.json');
        array_unshift($properties, $newProperty);
        writeJsonStorage('properties.json', $properties);

        // If user submitted, automatically add a Super Admin Notification
        if ($isUserSubmission) {
            $formattedPrice = '₹' . number_format($newProperty['price']);
            $newNotif = [
                'id' => 'notif_' . time() . '_' . rand(100, 999),
                'type' => 'new_property_ad',
                'title' => '🔔 புதிய விளம்பரம் அப்ரூவலுக்கு வந்துள்ளது!',
                'message' => "{$sellerName} ({$sellerPhone}) என்பவர் '{$newProperty['title']}' ({$formattedPrice}) என்ற புதிய விளம்பரத்தை பதிவிட்டுள்ளார். சரிபார்த்து அப்ரூவல் வழங்கவும்.",
                'propertyId' => $newId,
                'propertyTitle' => $newProperty['title'],
                'sellerName' => $sellerName,
                'sellerPhone' => $sellerPhone,
                'price' => $newProperty['price'],
                'propertyType' => $newProperty['propertyType'],
                'location' => $newProperty['location'],
                'timestamp' => date('c'),
                'isRead' => false,
                'status' => 'pending'
            ];

            // Save notification to JSON
            $notifsFile = DATA_DIR . '/notifications.json';
            $notifs = file_exists($notifsFile) ? json_decode(file_get_contents($notifsFile), true) : [];
            if (!is_array($notifs)) $notifs = [];
            array_unshift($notifs, $newNotif);
            file_put_contents($notifsFile, json_encode(array_values($notifs), JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

            // Save notification to DB
            $pdo = getDbConnection();
            if ($pdo) {
                try {
                    $nStmt = $pdo->prepare("INSERT INTO `notifications` (`id`, `type`, `title`, `message`, `propertyId`, `propertyTitle`, `sellerName`, `sellerPhone`, `price`, `propertyType`, `location`, `isRead`, `status`, `timestamp`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
                    $nStmt->execute([
                        $newNotif['id'], $newNotif['type'], $newNotif['title'], $newNotif['message'],
                        $newNotif['propertyId'], $newNotif['propertyTitle'], $newNotif['sellerName'],
                        $newNotif['sellerPhone'], $newNotif['price'], $newNotif['propertyType'],
                        $newNotif['location'], 0, 'pending', $newNotif['timestamp']
                    ]);
                } catch (Exception $e) {}
            }
        }

        $successMsg = $isUserSubmission 
            ? 'உங்கள் விளம்பரம் வெற்றிகரமாக சமர்ப்பிக்கப்பட்டது! சூப்பர் அட்மின் சரிபார்த்து அப்ரூவல் செய்தவுடன் தளத்தில் நேரலையாக தோன்றும்.'
            : 'புதிய விளம்பரம் வெற்றிகரமாக சேர்க்கப்பட்டது! (Property created successfully)';

        sendResponse([
            'success' => true,
            'message' => $successMsg,
            'property' => $newProperty,
            'isPendingApproval' => $isUserSubmission
        ], 201);
        break;

    case 'PUT':
        $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;
        $id = $input['id'] ?? $_GET['id'] ?? null;

        if (!$id) {
            sendResponse(['success' => false, 'message' => 'Property ID is required'], 400);
        }

        // Update in DB
        updatePropertyInDb($id, $input);

        // Update in JSON (backup)
        $properties = readJsonStorage('properties.json');
        $foundIndex = -1;
        foreach ($properties as $idx => $p) {
            if ($p['id'] == $id) {
                $foundIndex = $idx;
                break;
            }
        }

        if ($foundIndex !== -1) {
            foreach ($input as $k => $v) {
                if ($k !== 'id') {
                    $properties[$foundIndex][$k] = $v;
                }
            }
            writeJsonStorage('properties.json', $properties);
        }

        // Sync notification if status changed
        if (isset($input['status'])) {
            syncNotificationStatus($id, $input['status'] === 'active' ? 'approved' : $input['status']);
        }

        $updatedProp = $foundIndex !== -1 ? $properties[$foundIndex] : $input;
        sendResponse([
            'success' => true,
            'message' => 'விளம்பரம் வெற்றிகரமாக திருத்தப்பட்டது! (Property updated successfully)',
            'property' => $updatedProp
        ]);
        break;

    case 'DELETE':
        $id = $_GET['id'] ?? null;
        if (!$id) {
            $input = json_decode(file_get_contents('php://input'), true);
            $id = $input['id'] ?? null;
        }

        if (!$id) {
            sendResponse(['success' => false, 'message' => 'Property ID is required'], 400);
        }

        // Delete from DB
        $dbDeleted = deletePropertyFromDb($id);

        // Delete from JSON
        $properties = readJsonStorage('properties.json');
        $initialCount = count($properties);
        $properties = array_filter($properties, function ($p) use ($id) {
            return $p['id'] != $id;
        });
        $jsonDeleted = count($properties) !== $initialCount;

        if (!$dbDeleted && !$jsonDeleted) {
            sendResponse(['success' => false, 'message' => 'Property not found'], 404);
        }

        if ($jsonDeleted) {
            writeJsonStorage('properties.json', array_values($properties));
        }
        syncNotificationStatus($id, 'deleted');

        sendResponse([
            'success' => true,
            'message' => 'விளம்பரம் வெற்றிகரமாக நீக்கப்பட்டது! (Property deleted successfully)'
        ]);
        break;

    default:
        sendResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}
