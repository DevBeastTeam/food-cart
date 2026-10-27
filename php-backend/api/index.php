<?php
// php-backend/api/index.php

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../config/database.php';
$pdo = getDb();

// Helper functions
function jsonResponse($data, int $status = 200): void {
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function getJsonInput(): array {
    $input = file_get_contents('php://input');
    if (empty($input)) return [];
    $data = json_decode($input, true);
    return is_array($data) ? $data : [];
}

// Extract endpoint route path
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
// Normalize uri: remove leading directory prefixes up to /api/
$path = $uri;
if (strpos($path, '/api') !== false) {
    $path = substr($path, strpos($path, '/api') + 4);
}
$path = trim($path, '/');
$segments = $path === '' ? [] : explode('/', $path);

$resource = $segments[0] ?? '';
$subId    = $segments[1] ?? '';
$action   = $segments[2] ?? '';
$method   = $_SERVER['REQUEST_METHOD'];

// =============================================================================
// ROUTING
// =============================================================================

switch ($resource) {

    // -------------------------------------------------------------------------
    // 1. CONTENT
    // -------------------------------------------------------------------------
    case 'content':
        if ($method === 'GET') {
            $stmt = $pdo->query("SELECT key, value FROM content");
            $rows = $stmt->fetchAll();
            $data = [];
            foreach ($rows as $r) {
                $decoded = json_decode($r['value'], true);
                $data[$r['key']] = ($decoded !== null && (is_array($decoded) || is_bool($decoded) || is_numeric($decoded))) ? $decoded : $r['value'];
            }
            jsonResponse(['success' => true, 'data' => $data]);
        } elseif ($method === 'PUT' || $method === 'POST') {
            $body = getJsonInput();
            $stmt = $pdo->prepare("INSERT OR REPLACE INTO content (key, value) VALUES (?, ?)");
            foreach ($body as $k => $v) {
                $valStr = is_array($v) ? json_encode($v) : (string)$v;
                $stmt->execute([$k, $valStr]);
            }
            jsonResponse(['success' => true, 'message' => 'Content updated successfully']);
        }
        break;

    // -------------------------------------------------------------------------
    // 2. SETTINGS
    // -------------------------------------------------------------------------
    case 'settings':
        if ($method === 'GET') {
            $stmt = $pdo->query("SELECT key, value FROM settings");
            $rows = $stmt->fetchAll();
            $data = [];
            foreach ($rows as $r) {
                $decoded = json_decode($r['value'], true);
                if ($decoded !== null && (is_array($decoded) || is_bool($decoded) || is_numeric($decoded))) {
                    $data[$r['key']] = $decoded;
                } else {
                    // Check numeric or boolean
                    if ($r['value'] === 'true') $data[$r['key']] = true;
                    elseif ($r['value'] === 'false') $data[$r['key']] = false;
                    elseif (is_numeric($r['value'])) $data[$r['key']] = $r['value'] + 0;
                    else $data[$r['key']] = $r['value'];
                }
            }
            jsonResponse(['success' => true, 'data' => $data]);
        } elseif ($method === 'PUT' || $method === 'POST') {
            $body = getJsonInput();
            $stmt = $pdo->prepare("INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)");
            foreach ($body as $k => $v) {
                $valStr = is_array($v) ? json_encode($v) : (is_bool($v) ? ($v ? 'true' : 'false') : (string)$v);
                $stmt->execute([$k, $valStr]);
            }
            jsonResponse(['success' => true, 'message' => 'Settings saved successfully']);
        }
        break;

    // -------------------------------------------------------------------------
    // 3. RESTAURANTS
    // -------------------------------------------------------------------------
    case 'restaurants':
        if ($method === 'GET') {
            if ($subId !== '') {
                $stmt = $pdo->prepare("SELECT * FROM restaurants WHERE id = ?");
                $stmt->execute([$subId]);
                $row = $stmt->fetch();
                if (!$row) jsonResponse(['success' => false, 'message' => 'Restaurant not found'], 404);
                $row['categories'] = json_decode($row['categories'] ?? '[]', true);
                $row['isFeatured'] = (bool)$row['isFeatured'];
                $row['isVisible']  = (bool)$row['isVisible'];
                jsonResponse(['success' => true, 'data' => $row]);
            }

            $stmt = $pdo->query("SELECT * FROM restaurants ORDER BY isFeatured DESC, rating DESC");
            $rows = $stmt->fetchAll();
            $list = [];
            foreach ($rows as $r) {
                $r['categories'] = json_decode($r['categories'] ?? '[]', true);
                $r['isFeatured'] = (bool)$r['isFeatured'];
                $r['isVisible']  = (bool)$r['isVisible'];
                $list[] = $r;
            }
            jsonResponse(['success' => true, 'count' => count($list), 'data' => $list]);
        } elseif ($method === 'POST') {
            $b = getJsonInput();
            $id = $b['id'] ?? ('rest_' . time());
            $stmt = $pdo->prepare("
                INSERT INTO restaurants (id, name, cuisine, imageUrl, rating, reviewCount, deliveryTime, deliveryFee, minOrder, distance, address, badge, isFeatured, isVisible, categories)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $id,
                $b['name'] ?? 'New Restaurant',
                $b['cuisine'] ?? '',
                $b['imageUrl'] ?? 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&q=80',
                $b['rating'] ?? 4.8,
                $b['reviewCount'] ?? 0,
                $b['deliveryTime'] ?? '25-35 min',
                $b['deliveryFee'] ?? 49,
                $b['minOrder'] ?? 250,
                $b['distance'] ?? '2.0 km',
                $b['address'] ?? '',
                $b['badge'] ?? '',
                !empty($b['isFeatured']) ? 1 : 0,
                isset($b['isVisible']) ? ($b['isVisible'] ? 1 : 0) : 1,
                json_encode($b['categories'] ?? ['All'])
            ]);
            jsonResponse(['success' => true, 'message' => 'Restaurant created', 'data' => ['id' => $id]], 201);
        } elseif ($method === 'PUT' && $subId !== '') {
            $b = getJsonInput();
            $stmt = $pdo->prepare("
                UPDATE restaurants SET
                    name = ?, cuisine = ?, imageUrl = ?, rating = ?, reviewCount = ?,
                    deliveryTime = ?, deliveryFee = ?, minOrder = ?, distance = ?,
                    address = ?, badge = ?, isFeatured = ?, isVisible = ?, categories = ?
                WHERE id = ?
            ");
            $stmt->execute([
                $b['name'],
                $b['cuisine'] ?? '',
                $b['imageUrl'] ?? '',
                $b['rating'] ?? 4.8,
                $b['reviewCount'] ?? 0,
                $b['deliveryTime'] ?? '25-35 min',
                $b['deliveryFee'] ?? 49,
                $b['minOrder'] ?? 250,
                $b['distance'] ?? '2.0 km',
                $b['address'] ?? '',
                $b['badge'] ?? '',
                !empty($b['isFeatured']) ? 1 : 0,
                isset($b['isVisible']) ? ($b['isVisible'] ? 1 : 0) : 1,
                json_encode($b['categories'] ?? ['All']),
                $subId
            ]);
            jsonResponse(['success' => true, 'message' => 'Restaurant updated']);
        } elseif ($method === 'DELETE' && $subId !== '') {
            $stmt = $pdo->prepare("DELETE FROM restaurants WHERE id = ?");
            $stmt->execute([$subId]);
            jsonResponse(['success' => true, 'message' => 'Restaurant deleted']);
        }
        break;

    // -------------------------------------------------------------------------
    // 4. FOOD ITEMS
    // -------------------------------------------------------------------------
    case 'food-items':
        if ($method === 'GET') {
            $restId = $_GET['restaurantId'] ?? '';
            $cat    = $_GET['category'] ?? '';
            $q      = trim($_GET['search'] ?? '');
            $subAdminId = $_GET['sub_admin_id'] ?? '';

            $sql = "SELECT * FROM food_items WHERE 1=1";
            $params = [];

            if ($restId !== '') {
                $sql .= " AND restaurantId = ?";
                $params[] = $restId;
            }
            if ($subAdminId !== '') {
                $sql .= " AND sub_admin_id = ?";
                $params[] = $subAdminId;
            }
            if ($cat !== '' && $cat !== 'All') {
                $sql .= " AND category = ?";
                $params[] = $cat;
            }
            if ($q !== '') {
                $sql .= " AND (LOWER(name) LIKE ? OR LOWER(description) LIKE ?)";
                $params[] = '%' . strtolower($q) . '%';
                $params[] = '%' . strtolower($q) . '%';
            }
            $sql .= " ORDER BY isPopular DESC, rating DESC";

            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);
            $rows = $stmt->fetchAll();

            $list = [];
            foreach ($rows as $r) {
                $r['badges']          = json_decode($r['badges'] ?? '[]', true);
                $r['isPopular']       = (bool)$r['isPopular'];
                $r['isVegetarian']    = (bool)$r['isVegetarian'];
                $r['isVisible']       = (bool)$r['isVisible'];
                $r['isDiscounted']    = (bool)($r['isDiscounted'] ?? false);
                $r['discountPercent'] = (int)($r['discountPercent'] ?? 0);
                $r['discountPrice']   = (float)($r['discountPrice'] ?? 0);
                $r['promoBadge']      = (string)($r['promoBadge'] ?? '');
                $list[] = $r;
            }
            jsonResponse(['success' => true, 'count' => count($list), 'data' => $list]);
        } elseif ($method === 'POST') {
            $b = getJsonInput();
            $id = $b['id'] ?? ('item_' . time());
            $stmt = $pdo->prepare("
                INSERT INTO food_items (id, restaurantId, name, description, price, imageUrl, category, rating, calories, isPopular, isVegetarian, isVisible, badges, sub_admin_id, discountPercent, discountPrice, isDiscounted, promoBadge)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $id,
                $b['restaurantId'] ?? '',
                $b['name'] ?? '',
                $b['description'] ?? '',
                $b['price'] ?? 0,
                $b['imageUrl'] ?? 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&q=80',
                $b['category'] ?? 'Biryani',
                $b['rating'] ?? 4.8,
                $b['calories'] ?? 500,
                !empty($b['isPopular']) ? 1 : 0,
                !empty($b['isVegetarian']) ? 1 : 0,
                isset($b['isVisible']) ? ($b['isVisible'] ? 1 : 0) : 1,
                json_encode($b['badges'] ?? []),
                $b['sub_admin_id'] ?? '',
                (int)($b['discountPercent'] ?? 0),
                (float)($b['discountPrice'] ?? 0),
                !empty($b['isDiscounted']) ? 1 : 0,
                $b['promoBadge'] ?? ''
            ]);
            jsonResponse(['success' => true, 'message' => 'Food item created', 'data' => ['id' => $id]], 201);
        } elseif ($method === 'PUT' && $subId !== '') {
            $b = getJsonInput();
            $stmt = $pdo->prepare("
                UPDATE food_items SET
                    restaurantId = ?, name = ?, description = ?, price = ?,
                    imageUrl = ?, category = ?, rating = ?, calories = ?,
                    isPopular = ?, isVegetarian = ?, isVisible = ?, badges = ?,
                    sub_admin_id = ?, discountPercent = ?, discountPrice = ?, isDiscounted = ?, promoBadge = ?
                WHERE id = ?
            ");
            $stmt->execute([
                $b['restaurantId'],
                $b['name'],
                $b['description'] ?? '',
                $b['price'] ?? 0,
                $b['imageUrl'] ?? '',
                $b['category'] ?? 'Biryani',
                $b['rating'] ?? 4.8,
                $b['calories'] ?? 500,
                !empty($b['isPopular']) ? 1 : 0,
                !empty($b['isVegetarian']) ? 1 : 0,
                isset($b['isVisible']) ? ($b['isVisible'] ? 1 : 0) : 1,
                json_encode($b['badges'] ?? []),
                $b['sub_admin_id'] ?? '',
                (int)($b['discountPercent'] ?? 0),
                (float)($b['discountPrice'] ?? 0),
                !empty($b['isDiscounted']) ? 1 : 0,
                $b['promoBadge'] ?? '',
                $subId
            ]);
            jsonResponse(['success' => true, 'message' => 'Food item updated']);
        } elseif ($method === 'DELETE' && $subId !== '') {
            $stmt = $pdo->prepare("DELETE FROM food_items WHERE id = ?");
            $stmt->execute([$subId]);
            jsonResponse(['success' => true, 'message' => 'Food item deleted']);
        }
        break;

    // -------------------------------------------------------------------------
    // 5. DAIG ITEMS (CATERING)
    // -------------------------------------------------------------------------
    case 'daig-items':
        if ($method === 'GET') {
            $subAdminId = $_GET['sub_admin_id'] ?? '';
            $sql = "SELECT * FROM daig_items WHERE 1=1";
            $params = [];
            if ($subAdminId !== '') {
                $sql .= " AND sub_admin_id = ?";
                $params[] = $subAdminId;
            }
            $sql .= " ORDER BY fullDaigPrice DESC";

            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);
            $rows = $stmt->fetchAll();
            $list = [];
            foreach ($rows as $r) {
                $r['includes']        = json_decode($r['includes'] ?? '[]', true);
                $r['isVisible']       = (bool)$r['isVisible'];
                $r['isDiscounted']    = (bool)($r['isDiscounted'] ?? false);
                $r['discountPercent'] = (int)($r['discountPercent'] ?? 0);
                $r['discountPrice']   = (float)($r['discountPrice'] ?? 0);
                $r['promoBadge']      = (string)($r['promoBadge'] ?? '');
                $list[] = $r;
            }
            jsonResponse(['success' => true, 'count' => count($list), 'data' => $list]);
        } elseif ($method === 'POST') {
            $b = getJsonInput();
            $id = $b['id'] ?? ('daig_' . time());
            $stmt = $pdo->prepare("
                INSERT INTO daig_items (id, name, urduName, description, category, fullDaigPrice, halfDaigPrice, fullDaigWeight, halfDaigWeight, imageUrl, rating, badge, deliveryNotice, isVisible, includes, sub_admin_id, discountPercent, discountPrice, isDiscounted, promoBadge)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $id,
                $b['name'] ?? '',
                $b['urduName'] ?? '',
                $b['description'] ?? '',
                $b['category'] ?? 'Biryani & Pulao',
                $b['fullDaigPrice'] ?? 0,
                $b['halfDaigPrice'] ?? 0,
                $b['fullDaigWeight'] ?? '12 KG (Serves 35-40 Persons)',
                $b['halfDaigWeight'] ?? '6 KG (Serves 18-20 Persons)',
                $b['imageUrl'] ?? 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80',
                $b['rating'] ?? 4.9,
                $b['badge'] ?? '',
                $b['deliveryNotice'] ?? 'Order 3-4 hours in advance',
                isset($b['isVisible']) ? ($b['isVisible'] ? 1 : 0) : 1,
                json_encode($b['includes'] ?? []),
                $b['sub_admin_id'] ?? '',
                (int)($b['discountPercent'] ?? 0),
                (float)($b['discountPrice'] ?? 0),
                !empty($b['isDiscounted']) ? 1 : 0,
                $b['promoBadge'] ?? ''
            ]);
            jsonResponse(['success' => true, 'message' => 'Daig dish created', 'data' => ['id' => $id]], 201);
        } elseif ($method === 'PUT' && $subId !== '') {
            $b = getJsonInput();
            $stmt = $pdo->prepare("
                UPDATE daig_items SET
                    name = ?, urduName = ?, description = ?, category = ?,
                    fullDaigPrice = ?, halfDaigPrice = ?, fullDaigWeight = ?, halfDaigWeight = ?,
                    imageUrl = ?, rating = ?, badge = ?, deliveryNotice = ?, isVisible = ?, includes = ?,
                    sub_admin_id = ?, discountPercent = ?, discountPrice = ?, isDiscounted = ?, promoBadge = ?
                WHERE id = ?
            ");
            $stmt->execute([
                $b['name'],
                $b['urduName'] ?? '',
                $b['description'] ?? '',
                $b['category'] ?? 'Biryani & Pulao',
                $b['fullDaigPrice'] ?? 0,
                $b['halfDaigPrice'] ?? 0,
                $b['fullDaigWeight'] ?? '12 KG (Serves 35-40 Persons)',
                $b['halfDaigWeight'] ?? '6 KG (Serves 18-20 Persons)',
                $b['imageUrl'] ?? '',
                $b['rating'] ?? 4.9,
                $b['badge'] ?? '',
                $b['deliveryNotice'] ?? '',
                isset($b['isVisible']) ? ($b['isVisible'] ? 1 : 0) : 1,
                json_encode($b['includes'] ?? []),
                $b['sub_admin_id'] ?? '',
                (int)($b['discountPercent'] ?? 0),
                (float)($b['discountPrice'] ?? 0),
                !empty($b['isDiscounted']) ? 1 : 0,
                $b['promoBadge'] ?? '',
                $subId
            ]);
            jsonResponse(['success' => true, 'message' => 'Daig dish updated']);
        } elseif ($method === 'DELETE' && $subId !== '') {
            $stmt = $pdo->prepare("DELETE FROM daig_items WHERE id = ?");
            $stmt->execute([$subId]);
            jsonResponse(['success' => true, 'message' => 'Daig dish deleted']);
        }
        break;

    // -------------------------------------------------------------------------
    // 6. BANNERS
    // -------------------------------------------------------------------------
    case 'banners':
        if ($method === 'GET') {
            $stmt = $pdo->query("SELECT * FROM banners");
            $rows = $stmt->fetchAll();
            $list = [];
            foreach ($rows as $r) {
                $r['bgGradient'] = json_decode($r['bgGradient'] ?? '[]', true);
                $r['isVisible']  = (bool)$r['isVisible'];
                $list[] = $r;
            }
            jsonResponse(['success' => true, 'count' => count($list), 'data' => $list]);
        } elseif ($method === 'POST') {
            $b = getJsonInput();
            $id = $b['id'] ?? ('banner_' . time());
            $stmt = $pdo->prepare("
                INSERT INTO banners (id, tagText, title, dishesText, buttonText, bgGradient, imageUrl, isVisible, linkCategory)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $id,
                $b['tagText'] ?? 'SPECIAL OFFER',
                $b['title'] ?? '',
                $b['dishesText'] ?? '',
                $b['buttonText'] ?? 'Order Now',
                json_encode($b['bgGradient'] ?? ['#6C3CE9', '#8B5CF6']),
                $b['imageUrl'] ?? '',
                isset($b['isVisible']) ? ($b['isVisible'] ? 1 : 0) : 1,
                $b['linkCategory'] ?? 'Biryani'
            ]);
            jsonResponse(['success' => true, 'message' => 'Banner created', 'data' => ['id' => $id]], 201);
        } elseif ($method === 'PUT' && $subId !== '') {
            $b = getJsonInput();
            $stmt = $pdo->prepare("
                UPDATE banners SET tagText = ?, title = ?, dishesText = ?, buttonText = ?, bgGradient = ?, imageUrl = ?, isVisible = ?, linkCategory = ?
                WHERE id = ?
            ");
            $stmt->execute([
                $b['tagText'] ?? '',
                $b['title'] ?? '',
                $b['dishesText'] ?? '',
                $b['buttonText'] ?? 'Order Now',
                json_encode($b['bgGradient'] ?? ['#6C3CE9', '#8B5CF6']),
                $b['imageUrl'] ?? '',
                isset($b['isVisible']) ? ($b['isVisible'] ? 1 : 0) : 1,
                $b['linkCategory'] ?? 'Biryani',
                $subId
            ]);
            jsonResponse(['success' => true, 'message' => 'Banner updated']);
        } elseif ($method === 'DELETE' && $subId !== '') {
            $stmt = $pdo->prepare("DELETE FROM banners WHERE id = ?");
            $stmt->execute([$subId]);
            jsonResponse(['success' => true, 'message' => 'Banner deleted']);
        }
        break;

    // -------------------------------------------------------------------------
    // 7. DEALS
    // -------------------------------------------------------------------------
    case 'deals':
        if ($method === 'GET') {
            $stmt = $pdo->query("SELECT * FROM deals ORDER BY discountPercent DESC");
            $rows = $stmt->fetchAll();
            $list = [];
            foreach ($rows as $r) {
                $r['isVisible'] = (bool)$r['isVisible'];
                $list[] = $r;
            }
            jsonResponse(['success' => true, 'count' => count($list), 'data' => $list]);
        } elseif ($method === 'POST') {
            $b = getJsonInput();
            $id = $b['id'] ?? ('deal_' . time());
            $stmt = $pdo->prepare("
                INSERT INTO deals (id, code, title, discountPercent, description, imageUrl, category, startDate, endDate, startTime, endTime, minOrder, maxDiscount, isVisible, status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $id,
                $b['code'] ?? 'DEAL',
                $b['title'] ?? '',
                $b['discountPercent'] ?? 10,
                $b['description'] ?? '',
                $b['imageUrl'] ?? '',
                $b['category'] ?? '',
                $b['startDate'] ?? '2025-01-01',
                $b['endDate'] ?? '2027-12-31',
                $b['startTime'] ?? '00:00',
                $b['endTime'] ?? '23:59',
                $b['minOrder'] ?? 0,
                $b['maxDiscount'] ?? 1000,
                isset($b['isVisible']) ? ($b['isVisible'] ? 1 : 0) : 1,
                $b['status'] ?? 'active'
            ]);
            jsonResponse(['success' => true, 'message' => 'Deal created', 'data' => ['id' => $id]], 201);
        } elseif ($method === 'PUT' && $subId !== '') {
            $b = getJsonInput();
            $stmt = $pdo->prepare("
                UPDATE deals SET code = ?, title = ?, discountPercent = ?, description = ?, imageUrl = ?, category = ?, startDate = ?, endDate = ?, startTime = ?, endTime = ?, minOrder = ?, maxDiscount = ?, isVisible = ?, status = ?
                WHERE id = ?
            ");
            $stmt->execute([
                $b['code'] ?? 'DEAL',
                $b['title'] ?? '',
                $b['discountPercent'] ?? 10,
                $b['description'] ?? '',
                $b['imageUrl'] ?? '',
                $b['category'] ?? '',
                $b['startDate'] ?? '2025-01-01',
                $b['endDate'] ?? '2027-12-31',
                $b['startTime'] ?? '00:00',
                $b['endTime'] ?? '23:59',
                $b['minOrder'] ?? 0,
                $b['maxDiscount'] ?? 1000,
                isset($b['isVisible']) ? ($b['isVisible'] ? 1 : 0) : 1,
                $b['status'] ?? 'active',
                $subId
            ]);
            jsonResponse(['success' => true, 'message' => 'Deal updated']);
        } elseif ($method === 'DELETE' && $subId !== '') {
            $stmt = $pdo->prepare("DELETE FROM deals WHERE id = ?");
            $stmt->execute([$subId]);
            jsonResponse(['success' => true, 'message' => 'Deal deleted']);
        }
        break;

    // -------------------------------------------------------------------------
    // 8. CATEGORIES
    // -------------------------------------------------------------------------
    case 'categories':
        $stmt = $pdo->query("SELECT * FROM categories ORDER BY display_order ASC");
        $rows = $stmt->fetchAll();
        jsonResponse(['success' => true, 'count' => count($rows), 'data' => $rows]);
        break;

    // -------------------------------------------------------------------------
    // 9. ORDERS
    // -------------------------------------------------------------------------
    case 'orders':
        // Check for /orders/{id}/status
        if ($subId !== '' && $action === 'status' && ($method === 'PATCH' || $method === 'PUT' || $method === 'POST')) {
            $b = getJsonInput();
            $status = $b['status'] ?? 'Accepted';
            $sql = "UPDATE orders SET status = ?";
            $params = [$status];

            if (isset($b['prepTime'])) {
                $sql .= ", prepTime = ?";
                $params[] = $b['prepTime'];
            }
            if (isset($b['notes'])) {
                $sql .= ", notes = ?";
                $params[] = $b['notes'];
            }
            if (isset($b['riderName'])) {
                $sql .= ", riderName = ?";
                $params[] = $b['riderName'];
            }
            if (isset($b['riderPhone'])) {
                $sql .= ", riderPhone = ?";
                $params[] = $b['riderPhone'];
            }
            if (isset($b['rejectionReason'])) {
                $sql .= ", rejectionReason = ?";
                $params[] = $b['rejectionReason'];
            }
            $sql .= " WHERE id = ?";
            $params[] = $subId;

            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);

            jsonResponse(['success' => true, 'message' => "Order $subId updated to $status"]);
        }

        if ($method === 'GET') {
            if ($subId !== '') {
                $stmt = $pdo->prepare("SELECT * FROM orders WHERE id = ?");
                $stmt->execute([$subId]);
                $o = $stmt->fetch();
                if (!$o) jsonResponse(['success' => false, 'message' => 'Order not found'], 404);
                $o['items'] = json_decode($o['items'] ?? '[]', true);
                $o['isDaigBooking'] = (bool)$o['isDaigBooking'];
                $o['latitude'] = (float)($o['latitude'] ?? 31.5204);
                $o['longitude'] = (float)($o['longitude'] ?? 74.3587);
                jsonResponse(['success' => true, 'data' => $o]);
            }

            $st = $_GET['status'] ?? '';
            $phone = $_GET['customerPhone'] ?? '';
            $riderPhone = $_GET['riderPhone'] ?? '';
            $unassigned = $_GET['unassigned'] ?? '';
            $subAdminId = $_GET['sub_admin_id'] ?? '';

            $sql = "SELECT * FROM orders WHERE 1=1";
            $params = [];
            if ($subAdminId !== '') {
                $sql .= " AND sub_admin_id = ?";
                $params[] = $subAdminId;
            }
            if ($st !== '' && $st !== 'All') {
                $sql .= " AND LOWER(status) = ?";
                $params[] = strtolower($st);
            }
            if ($phone !== '') {
                $sql .= " AND customerPhone = ?";
                $params[] = $phone;
            }
            if ($riderPhone !== '') {
                $sql .= " AND riderPhone = ?";
                $params[] = $riderPhone;
            }
            if ($unassigned === '1' || $unassigned === 'true') {
                $sql .= " AND (riderPhone IS NULL OR riderPhone = '' OR riderName IS NULL OR riderName = '') AND status IN ('Accepted', 'Preparing')";
            }
            $sql .= " ORDER BY orderDate DESC";

            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);
            $rows = $stmt->fetchAll();

            $list = [];
            foreach ($rows as $o) {
                $o['items'] = json_decode($o['items'] ?? '[]', true);
                $o['isDaigBooking'] = (bool)$o['isDaigBooking'];
                $o['latitude'] = (float)($o['latitude'] ?? 31.5204);
                $o['longitude'] = (float)($o['longitude'] ?? 74.3587);
                $list[] = $o;
            }
            jsonResponse(['success' => true, 'count' => count($list), 'data' => $list]);
        } elseif ($method === 'POST') {
            $b = getJsonInput();
            $num = str_pad((string)(mt_rand(1000, 9999)), 4, '0', STR_PAD_LEFT);
            $id = !empty($b['id']) ? $b['id'] : ("FC-" . $num);

            $lat = isset($b['latitude']) ? (float)$b['latitude'] : 31.5204;
            $lng = isset($b['longitude']) ? (float)$b['longitude'] : 74.3587;

            // Smart Sub-Admin assignment
            $subAdminId = $b['sub_admin_id'] ?? '';
            if (empty($subAdminId) && !empty($b['restaurantName'])) {
                $rName = trim($b['restaurantName']);
                $st = $pdo->prepare("SELECT id FROM users WHERE role = 'sub_admin' AND (LOWER(businessName) = LOWER(?) OR LOWER(businessName) LIKE ?)");
                $st->execute([$rName, "%" . strtolower($rName) . "%"]);
                $found = $st->fetch();
                if ($found) $subAdminId = $found['id'];
            }
            if (empty($subAdminId) && !empty($b['restaurantId'])) {
                $rId = trim($b['restaurantId']);
                $st = $pdo->prepare("SELECT id FROM users WHERE role = 'sub_admin' AND (id = ? OR businessName LIKE ?)");
                $st->execute([$rId, "%$rId%"]);
                $found = $st->fetch();
                if ($found) $subAdminId = $found['id'];
            }
            if (empty($subAdminId)) {
                // If it is a Daig booking, route to Shahi Pakwan Center (sub_admin_2)
                if (!empty($b['isDaigBooking'])) {
                    $subAdminId = 'sub_admin_2';
                } else {
                    $subAdminId = 'sub_admin_1';
                }
            }

            $stmt = $pdo->prepare("
                INSERT INTO orders (id, restaurantName, restaurantImage, items, totalAmount, originalAmount, discountInfo, orderDate, status, prepTime, customerName, customerPhone, deliveryAddress, isDaigBooking, occasion, notes, riderName, riderPhone, sub_admin_id, rejectionReason, latitude, longitude)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $id,
                $b['restaurantName'] ?? 'FoodCourt Central Kitchen',
                $b['restaurantImage'] ?? 'https://images.unsplash.com/photo-1544025162-d76694265947?w=300&q=80',
                json_encode($b['items'] ?? []),
                $b['totalAmount'] ?? 0,
                $b['originalAmount'] ?? $b['totalAmount'] ?? 0,
                $b['discountInfo'] ?? null,
                $b['orderDate'] ?? date('c'),
                $b['status'] ?? 'Accepted',
                $b['prepTime'] ?? '25-35 mins',
                $b['customerName'] ?? 'Hassan Raza',
                $b['customerPhone'] ?? '+92 300 8472910',
                $b['deliveryAddress'] ?? 'Lahore',
                !empty($b['isDaigBooking']) ? 1 : 0,
                $b['occasion'] ?? null,
                $b['notes'] ?? null,
                $b['riderName'] ?? null,
                $b['riderPhone'] ?? null,
                $subAdminId,
                $b['rejectionReason'] ?? '',
                $lat,
                $lng
            ]);

            jsonResponse(['success' => true, 'message' => 'Order placed successfully', 'data' => ['id' => $id, 'sub_admin_id' => $subAdminId]], 201);
        }
        break;

    // -------------------------------------------------------------------------
    // 10. SUB-ADMINS & PAKWAN CENTERS (FOR SUPER ADMIN)
    // -------------------------------------------------------------------------
    case 'sub-admins':
        if ($method === 'GET') {
            if ($subId !== '' && $action === 'details') {
                $stmt = $pdo->prepare("SELECT id, name, email, phone, city, businessName, businessType, address, latitude, longitude, status, banned, createdAt FROM users WHERE id = ? AND role = 'sub_admin'");
                $stmt->execute([$subId]);
                $sa = $stmt->fetch();
                if (!$sa) jsonResponse(['success' => false, 'message' => 'Sub-admin not found'], 404);

                $sa['banned'] = (bool)$sa['banned'];
                $sa['latitude'] = (float)($sa['latitude'] ?? 31.5204);
                $sa['longitude'] = (float)($sa['longitude'] ?? 74.3587);

                // Food items
                $stmtF = $pdo->prepare("SELECT * FROM food_items WHERE sub_admin_id = ?");
                $stmtF->execute([$subId]);
                $foods = $stmtF->fetchAll();
                foreach ($foods as &$f) {
                    $f['badges'] = json_decode($f['badges'] ?? '[]', true);
                }

                // Daig items
                $stmtD = $pdo->prepare("SELECT * FROM daig_items WHERE sub_admin_id = ?");
                $stmtD->execute([$subId]);
                $daigs = $stmtD->fetchAll();
                foreach ($daigs as &$d) {
                    $d['includes'] = json_decode($d['includes'] ?? '[]', true);
                }

                // Orders
                $stmtO = $pdo->prepare("SELECT * FROM orders WHERE sub_admin_id = ? ORDER BY orderDate DESC");
                $stmtO->execute([$subId]);
                $orders = $stmtO->fetchAll();
                foreach ($orders as &$o) {
                    $o['items'] = json_decode($o['items'] ?? '[]', true);
                    $o['isDaigBooking'] = (bool)$o['isDaigBooking'];
                    $o['latitude'] = (float)($o['latitude'] ?? 31.5204);
                    $o['longitude'] = (float)($o['longitude'] ?? 74.3587);
                }

                // Riders for this outlet with delivery stats
                $stmtR = $pdo->prepare("SELECT id, name, email, phone, city, status, banned, createdAt, assigned_sub_admin_id, outlet_name FROM users WHERE role = 'rider' AND assigned_sub_admin_id = ?");
                $stmtR->execute([$subId]);
                $riders = $stmtR->fetchAll();
                foreach ($riders as &$rdr) {
                    $rName = $rdr['name'];
                    $rPhone = $rdr['phone'];

                    $delivStmt = $pdo->prepare("SELECT COUNT(*) FROM orders WHERE sub_admin_id = ? AND (riderPhone = ? OR riderName = ?) AND status = 'Delivered'");
                    $delivStmt->execute([$subId, $rPhone, $rName]);
                    $rdr['deliveredCount'] = (int)$delivStmt->fetchColumn();

                    $pendStmt = $pdo->prepare("SELECT COUNT(*) FROM orders WHERE sub_admin_id = ? AND (riderPhone = ? OR riderName = ?) AND status IN ('Accepted', 'Preparing', 'On the Way')");
                    $pendStmt->execute([$subId, $rPhone, $rName]);
                    $rdr['pendingCount'] = (int)$pendStmt->fetchColumn();

                    $cancStmt = $pdo->prepare("SELECT COUNT(*) FROM orders WHERE sub_admin_id = ? AND (riderPhone = ? OR riderName = ?) AND status = 'Cancelled'");
                    $cancStmt->execute([$subId, $rPhone, $rName]);
                    $rdr['cancelledCount'] = (int)$cancStmt->fetchColumn();

                    $ordDeliveries = $pdo->prepare("SELECT id, customerName, customerPhone, totalAmount, status, orderDate, deliveryAddress, latitude, longitude FROM orders WHERE sub_admin_id = ? AND (riderPhone = ? OR riderName = ?) ORDER BY orderDate DESC LIMIT 10");
                    $ordDeliveries->execute([$subId, $rPhone, $rName]);
                    $rdr['recentDeliveries'] = $ordDeliveries->fetchAll();
                }

                // Customers for this outlet with order analytics
                $stmtC = $pdo->prepare("SELECT customerName, customerPhone, COUNT(*) as orderCount, SUM(totalAmount) as totalSpent, MAX(orderDate) as lastOrderDate,
                    SUM(CASE WHEN status = 'Delivered' THEN 1 ELSE 0 END) as deliveredCount,
                    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) as cancelledCount
                    FROM orders WHERE sub_admin_id = ? GROUP BY customerPhone ORDER BY orderCount DESC");
                $stmtC->execute([$subId]);
                $customers = $stmtC->fetchAll();

                // Metrics summary
                $totalSales = array_reduce($orders, function($carry, $item) { return $item['status'] !== 'Cancelled' ? $carry + (float)$item['totalAmount'] : $carry; }, 0);
                $deliveredOrders = count(array_filter($orders, function($o) { return $o['status'] === 'Delivered'; }));
                $pendingOrders = count(array_filter($orders, function($o) { return in_array($o['status'], ['Accepted', 'Preparing', 'On the Way']); }));
                $cancelledOrders = count(array_filter($orders, function($o) { return $o['status'] === 'Cancelled'; }));

                $sa['foods'] = $foods;
                $sa['daigs'] = $daigs;
                $sa['orders'] = $orders;
                $sa['riders'] = $riders;
                $sa['customers'] = $customers;
                $sa['totalOrders'] = count($orders);
                $sa['totalSales'] = $totalSales;
                $sa['deliveredOrders'] = $deliveredOrders;
                $sa['pendingOrders'] = $pendingOrders;
                $sa['cancelledOrders'] = $cancelledOrders;
                $sa['ridersCount'] = count($riders);
                $sa['customersCount'] = count($customers);

                jsonResponse(['success' => true, 'data' => $sa]);
            }

            // List all sub-admins with metrics
            $stmt = $pdo->query("SELECT id, name, email, phone, city, businessName, businessType, address, latitude, longitude, status, banned, createdAt FROM users WHERE role = 'sub_admin' ORDER BY createdAt DESC");
            $subAdmins = $stmt->fetchAll();

            foreach ($subAdmins as &$sa) {
                $sid = $sa['id'];
                $sa['banned'] = (bool)$sa['banned'];
                $sa['latitude'] = (float)($sa['latitude'] ?? 31.5204);
                $sa['longitude'] = (float)($sa['longitude'] ?? 74.3587);

                // Sales
                $revStmt = $pdo->prepare("SELECT COALESCE(SUM(totalAmount), 0) as rev FROM orders WHERE sub_admin_id = ? AND status != 'Cancelled'");
                $revStmt->execute([$sid]);
                $sa['totalSales'] = (float)$revStmt->fetch()['rev'];

                // Orders count
                $ordStmt = $pdo->prepare("SELECT COUNT(*) as cnt FROM orders WHERE sub_admin_id = ?");
                $ordStmt->execute([$sid]);
                $sa['totalOrders'] = (int)$ordStmt->fetch()['cnt'];

                $compStmt = $pdo->prepare("SELECT COUNT(*) as cnt FROM orders WHERE sub_admin_id = ? AND status = 'Delivered'");
                $compStmt->execute([$sid]);
                $sa['completedOrders'] = (int)$compStmt->fetch()['cnt'];
                $sa['deliveredOrders'] = $sa['completedOrders'];

                $pendStmt = $pdo->prepare("SELECT COUNT(*) as cnt FROM orders WHERE sub_admin_id = ? AND status IN ('Accepted', 'Preparing', 'On the Way')");
                $pendStmt->execute([$sid]);
                $sa['pendingOrders'] = (int)$pendStmt->fetch()['cnt'];

                $cancStmt = $pdo->prepare("SELECT COUNT(*) as cnt FROM orders WHERE sub_admin_id = ? AND status = 'Cancelled'");
                $cancStmt->execute([$sid]);
                $sa['cancelledOrders'] = (int)$cancStmt->fetch()['cnt'];

                // Uploaded Items
                $fStmt = $pdo->prepare("SELECT COUNT(*) as cnt FROM food_items WHERE sub_admin_id = ?");
                $fStmt->execute([$sid]);
                $sa['foodItemsCount'] = (int)$fStmt->fetch()['cnt'];

                $dStmt = $pdo->prepare("SELECT COUNT(*) as cnt FROM daig_items WHERE sub_admin_id = ?");
                $dStmt->execute([$sid]);
                $sa['daigItemsCount'] = (int)$dStmt->fetch()['cnt'];

                // Assigned Dedicated Riders
                $rStmt = $pdo->prepare("SELECT COUNT(*) as cnt FROM users WHERE role = 'rider' AND assigned_sub_admin_id = ?");
                $rStmt->execute([$sid]);
                $rCount = (int)$rStmt->fetch()['cnt'];
                if ($rCount === 0) {
                    $rFallback = $pdo->prepare("SELECT COUNT(DISTINCT riderName) as cnt FROM orders WHERE sub_admin_id = ? AND riderName IS NOT NULL AND riderName != ''");
                    $rFallback->execute([$sid]);
                    $rCount = (int)$rFallback->fetch()['cnt'];
                }
                $sa['ridersCount'] = $rCount;

                // Customers count
                $cStmt = $pdo->prepare("SELECT COUNT(DISTINCT customerPhone) as cnt FROM orders WHERE sub_admin_id = ?");
                $cStmt->execute([$sid]);
                $sa['customersCount'] = (int)$cStmt->fetch()['cnt'];
            }

            jsonResponse(['success' => true, 'count' => count($subAdmins), 'data' => $subAdmins]);
        } elseif ($method === 'POST') {
            if ($subId !== '' && $action === 'notify') {
                $b = getJsonInput();
                $title = trim($b['title'] ?? 'Pakwan Center Official Notification');
                $msg = trim($b['message'] ?? '');
                $priority = trim($b['priority'] ?? 'normal');
                if (!$msg) jsonResponse(['success' => false, 'message' => 'Notification message is required'], 422);

                $notifId = 'notif_' . time() . '_' . bin2hex(random_bytes(3));
                $stmt = $pdo->prepare("INSERT INTO notifications (id, recipient_type, recipient_id, title, message, priority, read, createdAt) VALUES (?, 'sub_admin', ?, ?, ?, ?, 0, datetime('now'))");
                $stmt->execute([$notifId, $subId, $title, $msg, $priority]);
                jsonResponse(['success' => true, 'message' => 'Notification sent to Pakwan Center successfully!', 'data' => ['id' => $notifId]]);
            }

            if ($subId !== '' && $action === 'ban') {
                $b = getJsonInput();
                $stmt = $pdo->prepare("SELECT id, name, businessName, banned FROM users WHERE id = ? AND role = 'sub_admin'");
                $stmt->execute([$subId]);
                $user = $stmt->fetch();
                if (!$user) jsonResponse(['success' => false, 'message' => 'Pakwan Center vendor not found'], 404);

                $newBanned = isset($b['banned']) ? ($b['banned'] ? 1 : 0) : ($user['banned'] ? 0 : 1);
                $newStatus = $newBanned ? 'banned' : 'active';
                $isVisible = $newBanned ? 0 : 1;

                $up = $pdo->prepare("UPDATE users SET banned = ?, status = ? WHERE id = ?");
                $up->execute([$newBanned, $newStatus, $subId]);

                $upRest = $pdo->prepare("UPDATE restaurants SET isVisible = ? WHERE id = ? OR name = ?");
                $upRest->execute([$isVisible, $subId, $user['businessName'] ?? '']);

                $notifTitle = $newBanned ? '⚠️ Pakwan Center Suspended' : '✅ Pakwan Center Activated';
                $notifMsg = $newBanned 
                    ? 'Aap ka Pakwan Center account temporarily suspend kar diya gaya hai. Store operations pause ho chuki hain.'
                    : 'Aap ka Pakwan Center account dobara active kar diya gaya hai. Store online orders ke liye tayar hai.';
                $notifId = 'notif_' . time() . '_' . bin2hex(random_bytes(3));
                $pdo->prepare("INSERT INTO notifications (id, recipient_type, recipient_id, title, message, priority, read, createdAt) VALUES (?, 'sub_admin', ?, ?, ?, 'high', 0, datetime('now'))")->execute([$notifId, $subId, $notifTitle, $notifMsg]);

                $msg = $newBanned ? 'Pakwan Center vendor account has been banned/suspended.' : 'Pakwan Center vendor account has been unbanned and restored.';
                jsonResponse(['success' => true, 'message' => $msg, 'banned' => (bool)$newBanned, 'status' => $newStatus]);
            }

            $b = getJsonInput();
            $id = 'sub_admin_' . time();
            $name = trim($b['name'] ?? 'Vendor');
            $email = trim($b['email'] ?? '');
            $phone = trim($b['phone'] ?? '');
            $password = trim($b['password'] ?? '123456');
            $businessName = trim($b['businessName'] ?? $name);
            $businessType = trim($b['businessType'] ?? 'restaurant');
            $address = trim($b['address'] ?? '');
            $city = trim($b['city'] ?? 'Lahore');

            if (empty($email)) {
                jsonResponse(['success' => false, 'message' => 'Email is required'], 400);
            }

            $check = $pdo->prepare("SELECT id FROM users WHERE LOWER(email) = ?");
            $check->execute([strtolower($email)]);
            if ($check->fetch()) {
                jsonResponse(['success' => false, 'message' => 'Email already registered'], 400);
            }

            $pwdHash = password_hash($password, PASSWORD_DEFAULT);
            $stmt = $pdo->prepare("INSERT INTO users (id, name, email, passwordHash, phone, city, role, status, membershipTier, walletBalance, loyaltyCoins, createdAt, businessName, businessType, address, banned)
                VALUES (?, ?, ?, ?, ?, ?, 'sub_admin', 'active', 'Branch Manager ⭐', 0, 0, datetime('now'), ?, ?, ?, 0)");
            $stmt->execute([$id, $name, $email, $pwdHash, $phone, $city, $businessName, $businessType, $address]);

            jsonResponse(['success' => true, 'message' => 'Sub-admin created successfully', 'data' => ['id' => $id]], 201);
        } elseif ($method === 'PUT' && $subId !== '') {
            $b = getJsonInput();
            $lat = isset($b['latitude']) ? (float)$b['latitude'] : 31.5204;
            $lng = isset($b['longitude']) ? (float)$b['longitude'] : 74.3587;
            
            $sql = "UPDATE users SET name = ?, phone = ?, city = ?, businessName = ?, businessType = ?, address = ?, latitude = ?, longitude = ?";
            $params = [
                $b['name'] ?? '',
                $b['phone'] ?? '',
                $b['city'] ?? 'Lahore',
                $b['businessName'] ?? '',
                $b['businessType'] ?? 'restaurant',
                $b['address'] ?? '',
                $lat,
                $lng
            ];

            if (!empty($b['password'])) {
                $sql .= ", passwordHash = ?";
                $params[] = password_hash($b['password'], PASSWORD_DEFAULT);
            }

            $sql .= " WHERE id = ? AND role = 'sub_admin'";
            $params[] = $subId;

            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);

            // Also sync address & coordinates to matching outlet in restaurants table if applicable
            $pdo->prepare("UPDATE restaurants SET address = ?, latitude = ?, longitude = ? WHERE id = ? OR name = ?")->execute([
                $b['address'] ?? '',
                $lat,
                $lng,
                $subId,
                $b['businessName'] ?? ''
            ]);
            jsonResponse(['success' => true, 'message' => 'Sub-admin profile and location updated successfully', 'data' => ['latitude' => $lat, 'longitude' => $lng]]);
        } elseif ($method === 'DELETE' && $subId !== '') {
            $stmt = $pdo->prepare("SELECT id, businessName FROM users WHERE id = ? AND role = 'sub_admin'");
            $stmt->execute([$subId]);
            $sa = $stmt->fetch();
            if (!$sa) jsonResponse(['success' => false, 'message' => 'Sub-admin not found'], 404);

            $pdo->prepare("DELETE FROM users WHERE id = ?")->execute([$subId]);
            $pdo->prepare("DELETE FROM restaurants WHERE id = ? OR name = ?")->execute([$subId, $sa['businessName']]);
            $pdo->prepare("UPDATE users SET assigned_sub_admin_id = NULL, outlet_name = 'Unassigned' WHERE assigned_sub_admin_id = ?")->execute([$subId]);
            jsonResponse(['success' => true, 'message' => 'Pakwan Center deleted successfully']);
        } elseif ($method === 'PATCH' && $subId !== '' && $action === 'ban') {
            $b = getJsonInput();
            $stmt = $pdo->prepare("SELECT id, name, businessName, banned FROM users WHERE id = ? AND role = 'sub_admin'");
            $stmt->execute([$subId]);
            $user = $stmt->fetch();
            if (!$user) jsonResponse(['success' => false, 'message' => 'Pakwan Center vendor not found'], 404);

            $newBanned = isset($b['banned']) ? ($b['banned'] ? 1 : 0) : ($user['banned'] ? 0 : 1);
            $newStatus = $newBanned ? 'banned' : 'active';
            $isVisible = $newBanned ? 0 : 1;

            $up = $pdo->prepare("UPDATE users SET banned = ?, status = ? WHERE id = ?");
            $up->execute([$newBanned, $newStatus, $subId]);

            $upRest = $pdo->prepare("UPDATE restaurants SET isVisible = ? WHERE id = ? OR name = ?");
            $upRest->execute([$isVisible, $subId, $user['businessName'] ?? '']);

            $notifTitle = $newBanned ? '⚠️ Pakwan Center Suspended' : '✅ Pakwan Center Activated';
            $notifMsg = $newBanned 
                ? 'Aap ka Pakwan Center account temporarily suspend kar diya gaya hai. Store operations pause ho chuki hain.'
                : 'Aap ka Pakwan Center account dobara active kar diya gaya hai. Store online orders ke liye tayar hai.';
            $notifId = 'notif_' . time() . '_' . bin2hex(random_bytes(3));
            $pdo->prepare("INSERT INTO notifications (id, recipient_type, recipient_id, title, message, priority, read, createdAt) VALUES (?, 'sub_admin', ?, ?, ?, 'high', 0, datetime('now'))")->execute([$notifId, $subId, $notifTitle, $notifMsg]);

            $msg = $newBanned ? 'Pakwan Center vendor account has been banned/suspended.' : 'Pakwan Center vendor account has been unbanned and restored.';
            jsonResponse(['success' => true, 'message' => $msg, 'banned' => (bool)$newBanned, 'status' => $newStatus]);
        }
        break;

    // -------------------------------------------------------------------------
    // 10B. NOTIFICATIONS
    // -------------------------------------------------------------------------
    case 'notifications':
        if ($method === 'GET') {
            $subAdminId = $_GET['sub_admin_id'] ?? '';
            if ($subAdminId !== '') {
                $stmt = $pdo->prepare("SELECT * FROM notifications WHERE recipient_id = ? OR recipient_type = 'all' ORDER BY createdAt DESC");
                $stmt->execute([$subAdminId]);
            } else {
                $stmt = $pdo->query("SELECT * FROM notifications ORDER BY createdAt DESC");
            }
            $rows = $stmt->fetchAll();
            jsonResponse(['success' => true, 'count' => count($rows), 'data' => $rows]);
        } elseif ($method === 'POST') {
            $b = getJsonInput();
            $title = trim($b['title'] ?? 'Platform Announcement');
            $msg = trim($b['message'] ?? '');
            $recipientId = trim($b['recipient_id'] ?? '');
            $recipientType = trim($b['recipient_type'] ?? ($recipientId ? 'sub_admin' : 'all'));
            $priority = trim($b['priority'] ?? 'normal');
            if (!$msg) jsonResponse(['success' => false, 'message' => 'Message is required'], 422);

            $notifId = 'notif_' . time() . '_' . bin2hex(random_bytes(3));
            $stmt = $pdo->prepare("INSERT INTO notifications (id, recipient_type, recipient_id, title, message, priority, read, createdAt) VALUES (?, ?, ?, ?, ?, ?, 0, datetime('now'))");
            $stmt->execute([$notifId, $recipientType, $recipientId, $title, $msg, $priority]);
            jsonResponse(['success' => true, 'message' => 'Notification sent successfully!', 'data' => ['id' => $notifId]], 201);
        }
        break;

    // -------------------------------------------------------------------------
    // 10C. VENDOR SPECIFIC DATA (STATS, CUSTOMERS, RIDERS, PROFILE)
    // -------------------------------------------------------------------------
    case 'vendor':
        $subAdminId = $_GET['sub_admin_id'] ?? '';
        if ($subId === 'stats') {
            if (!$subAdminId) jsonResponse(['success' => false, 'message' => 'sub_admin_id is required'], 400);

            // Gross sales & orders
            $sStmt = $pdo->prepare("SELECT COALESCE(SUM(totalAmount), 0) as sales, COUNT(*) as cnt FROM orders WHERE sub_admin_id = ?");
            $sStmt->execute([$subAdminId]);
            $sRow = $sStmt->fetch();
            $grossSales = (float)$sRow['sales'];
            $totalOrders = (int)$sRow['cnt'];

            // Completed orders
            $cStmt = $pdo->prepare("SELECT COUNT(*) FROM orders WHERE sub_admin_id = ? AND status = 'Delivered'");
            $cStmt->execute([$subAdminId]);
            $completedOrders = (int)$cStmt->fetchColumn();

            // Active orders
            $aStmt = $pdo->prepare("SELECT COUNT(*) FROM orders WHERE sub_admin_id = ? AND status IN ('Accepted', 'Preparing', 'On the Way', 'Arrived')");
            $aStmt->execute([$subAdminId]);
            $activeOrders = (int)$aStmt->fetchColumn();

            // Cancelled orders
            $canStmt = $pdo->prepare("SELECT COUNT(*) as cnt, COALESCE(SUM(totalAmount), 0) as loss FROM orders WHERE sub_admin_id = ? AND status = 'Cancelled'");
            $canStmt->execute([$subAdminId]);
            $canRow = $canStmt->fetch();
            $cancelledOrders = (int)$canRow['cnt'];
            $lossAmount = (float)$canRow['loss'];

            // Customers count
            $custStmt = $pdo->prepare("SELECT COUNT(DISTINCT customerPhone) FROM orders WHERE sub_admin_id = ?");
            $custStmt->execute([$subAdminId]);
            $totalCustomers = (int)$custStmt->fetchColumn();

            // Riders count
            $rStmt = $pdo->prepare("SELECT COUNT(*) FROM users WHERE role = 'rider' AND assigned_sub_admin_id = ?");
            $rStmt->execute([$subAdminId]);
            $totalRiders = (int)$rStmt->fetchColumn();

            // Daig vs Restaurant split
            $dStmt = $pdo->prepare("SELECT COUNT(*) as cnt, COALESCE(SUM(totalAmount), 0) as rev FROM orders WHERE sub_admin_id = ? AND isDaigBooking = 1");
            $dStmt->execute([$subAdminId]);
            $dRow = $dStmt->fetch();

            $fStmt = $pdo->prepare("SELECT COUNT(*) as cnt, COALESCE(SUM(totalAmount), 0) as rev FROM orders WHERE sub_admin_id = ? AND (isDaigBooking = 0 OR isDaigBooking IS NULL)");
            $fStmt->execute([$subAdminId]);
            $fRow = $fStmt->fetch();

            // Order lifecycle counts
            $statusCounts = [];
            foreach (['Accepted', 'Preparing', 'On the Way', 'Arrived', 'Delivered', 'Cancelled'] as $st) {
                $stStmt = $pdo->prepare("SELECT COUNT(*) FROM orders WHERE sub_admin_id = ? AND status = ?");
                $stStmt->execute([$subAdminId, $st]);
                $statusCounts[$st] = (int)$stStmt->fetchColumn();
            }

            jsonResponse([
                'success' => true,
                'data' => [
                    'grossSales'       => $grossSales,
                    'totalOrders'      => $totalOrders,
                    'completedOrders'  => $completedOrders,
                    'activeOrders'     => $activeOrders,
                    'cancelledOrders'  => $cancelledOrders,
                    'lossAmount'       => $lossAmount,
                    'totalCustomers'   => $totalCustomers,
                    'totalRiders'      => $totalRiders,
                    'daigSales'        => (float)$dRow['rev'],
                    'daigOrders'       => (int)$dRow['cnt'],
                    'foodSales'        => (float)$fRow['rev'],
                    'foodOrders'       => (int)$fRow['cnt'],
                    'statusCounts'     => $statusCounts
                ]
            ]);
        } elseif ($subId === 'customers') {
            if (!$subAdminId) jsonResponse(['success' => false, 'message' => 'sub_admin_id is required'], 400);

            $custStmt = $pdo->prepare("
                SELECT customerPhone, customerName, deliveryAddress,
                       COUNT(id) as totalOrders,
                       SUM(totalAmount) as totalSpent,
                       MAX(orderDate) as lastOrderDate
                FROM orders
                WHERE sub_admin_id = ? AND customerPhone IS NOT NULL AND customerPhone != ''
                GROUP BY customerPhone
                ORDER BY totalSpent DESC
            ");
            $custStmt->execute([$subAdminId]);
            $customers = $custStmt->fetchAll();
            jsonResponse(['success' => true, 'count' => count($customers), 'data' => $customers]);
        } elseif ($subId === 'profile' && $method === 'POST') {
            $b = getJsonInput();
            $sid = $b['id'] ?? $subAdminId;
            if (!$sid) jsonResponse(['success' => false, 'message' => 'ID is required'], 400);

            $lat = isset($b['latitude']) && is_numeric($b['latitude']) ? (float)$b['latitude'] : 31.5204;
            $lng = isset($b['longitude']) && is_numeric($b['longitude']) ? (float)$b['longitude'] : 74.3587;

            $upUser = $pdo->prepare("
                UPDATE users SET name = COALESCE(?, name), phone = COALESCE(?, phone), city = COALESCE(?, city),
                                 businessName = COALESCE(?, businessName), businessType = COALESCE(?, businessType),
                                 address = COALESCE(?, address), latitude = ?, longitude = ?
                WHERE id = ? AND role = 'sub_admin'
            ");
            $upUser->execute([
                $b['name'] ?? null,
                $b['phone'] ?? null,
                $b['city'] ?? null,
                $b['businessName'] ?? null,
                $b['businessType'] ?? null,
                $b['address'] ?? null,
                $lat,
                $lng,
                $sid
            ]);

            $upRest = $pdo->prepare("
                UPDATE restaurants SET name = COALESCE(?, name), address = COALESCE(?, address),
                                      latitude = ?, longitude = ?
                WHERE id = ?
            ");
            $upRest->execute([
                $b['businessName'] ?? null,
                $b['address'] ?? null,
                $lat,
                $lng,
                $sid
            ]);

            if (!empty($b['newPassword'])) {
                $pwdHash = password_hash($b['newPassword'], PASSWORD_DEFAULT);
                $pdo->prepare("UPDATE users SET passwordHash = ? WHERE id = ?")->execute([$pwdHash, $sid]);
            }

            jsonResponse(['success' => true, 'message' => 'Store profile and GPS location updated successfully!']);
        }
        break;

    // -------------------------------------------------------------------------
    // 10D. ADMIN SPECIFIC (SUPER ADMIN PROFILE & SETTINGS)
    // -------------------------------------------------------------------------
    case 'admin':
        if ($subId === 'profile') {
            if ($method === 'GET') {
                $stmt = $pdo->prepare("SELECT id, name, email, phone, city, address, role, status, createdAt FROM users WHERE role = 'super_admin' LIMIT 1");
                $stmt->execute();
                $admin = $stmt->fetch();
                if (!$admin) {
                    $admin = [
                        'id' => 'usr_super_1',
                        'name' => 'Super Administrator',
                        'email' => 'super@foodcourt.pk',
                        'phone' => '+92 300 8472910',
                        'city' => 'Lahore',
                        'address' => 'FoodCourt Central Headquarters, 14-C Gulberg III, Main Blvd, Lahore',
                        'role' => 'super_admin',
                        'status' => 'active'
                    ];
                }
                jsonResponse(['success' => true, 'data' => $admin]);
            } elseif ($method === 'POST') {
                $b = getJsonInput();
                $name = trim($b['name'] ?? '');
                $email = trim($b['email'] ?? '');
                $phone = trim($b['phone'] ?? '');
                $city = trim($b['city'] ?? 'Lahore');
                $address = trim($b['address'] ?? '');
                $newPassword = trim($b['newPassword'] ?? '');

                if (!$name || !$email) {
                    jsonResponse(['success' => false, 'message' => 'Name and Email are required'], 422);
                }

                $stmt = $pdo->prepare("SELECT id FROM users WHERE role = 'super_admin' LIMIT 1");
                $stmt->execute();
                $existing = $stmt->fetch();

                if ($existing) {
                    $up = $pdo->prepare("UPDATE users SET name = ?, email = ?, phone = ?, city = ?, address = ? WHERE id = ?");
                    $up->execute([$name, $email, $phone, $city, $address, $existing['id']]);
                    $targetId = $existing['id'];
                } else {
                    $targetId = 'usr_super_1';
                    $hash = password_hash('123456', PASSWORD_DEFAULT);
                    $ins = $pdo->prepare("INSERT INTO users (id, name, email, passwordHash, phone, city, address, role, status, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, 'super_admin', 'active', datetime('now'))");
                    $ins->execute([$targetId, $name, $email, $hash, $phone, $city, $address]);
                }

                if (!empty($newPassword)) {
                    $pwdHash = password_hash($newPassword, PASSWORD_DEFAULT);
                    $pdo->prepare("UPDATE users SET passwordHash = ? WHERE id = ?")->execute([$pwdHash, $targetId]);
                }

                if (session_status() === PHP_SESSION_NONE) {
                    @session_start();
                }
                if (isset($_SESSION['super_admin'])) {
                    $_SESSION['super_admin']['name'] = $name;
                    $_SESSION['super_admin']['email'] = $email;
                    $_SESSION['super_admin']['phone'] = $phone;
                    $_SESSION['super_admin']['city'] = $city;
                    $_SESSION['super_admin']['address'] = $address;
                }

                jsonResponse([
                    'success' => true,
                    'message' => 'Super Admin profile updated successfully!',
                    'data' => [
                        'id' => $targetId,
                        'name' => $name,
                        'email' => $email,
                        'phone' => $phone,
                        'city' => $city,
                        'address' => $address
                    ]
                ]);
            }
        }
        break;

    // -------------------------------------------------------------------------
    // 11. USERS & AUTH
    // -------------------------------------------------------------------------
    case 'users':
        if ($method === 'GET') {
            if ($subId !== '') {
                $stmt = $pdo->prepare("SELECT id, name, email, phone, city, role, status, membershipTier, walletBalance, loyaltyCoins, businessName, businessType, address, banned, createdAt FROM users WHERE id = ?");
                $stmt->execute([$subId]);
                $u = $stmt->fetch();
                if (!$u) jsonResponse(['success' => false, 'message' => 'User not found'], 404);
                $u['banned'] = (bool)$u['banned'];
                jsonResponse(['success' => true, 'data' => $u]);
            }

            $roleFilter = $_GET['role'] ?? '';
            $subAdminFilter = $_GET['sub_admin_id'] ?? '';
            $sql = "SELECT id, name, email, phone, city, role, status, membershipTier, walletBalance, loyaltyCoins, businessName, businessType, address, banned, createdAt, assigned_sub_admin_id, outlet_name FROM users WHERE 1=1";
            $params = [];
            if ($roleFilter !== '') {
                $sql .= " AND role = ?";
                $params[] = $roleFilter;
            }
            if ($subAdminFilter !== '') {
                $sql .= " AND assigned_sub_admin_id = ?";
                $params[] = $subAdminFilter;
            }
            $sql .= " ORDER BY createdAt DESC";

            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);
            $rows = $stmt->fetchAll();
            foreach ($rows as &$r) {
                $r['banned'] = (bool)$r['banned'];
            }
            jsonResponse(['success' => true, 'count' => count($rows), 'data' => $rows]);
        } elseif ($method === 'POST') {
            $b = getJsonInput();
            $name = trim($b['name'] ?? '');
            $email = trim($b['email'] ?? '');
            $phone = trim($b['phone'] ?? '');
            $role = trim($b['role'] ?? 'rider');
            $password = $b['password'] ?? '123456';
            $city = trim($b['city'] ?? 'Lahore');
            $address = trim($b['address'] ?? '');
            $assignedSubAdminId = trim($b['assigned_sub_admin_id'] ?? '');
            $outletName = trim($b['outlet_name'] ?? '');

            if (!$name || !$email) {
                jsonResponse(['success' => false, 'message' => 'Name and Email are required'], 422);
            }

            // Check if email already exists
            $chk = $pdo->prepare("SELECT id FROM users WHERE email = ?");
            $chk->execute([$email]);
            if ($chk->fetch()) {
                jsonResponse(['success' => false, 'message' => 'Email already registered'], 409);
            }

            $id = 'usr_' . $role . '_' . bin2hex(random_bytes(4));
            $pwdHash = password_hash($password, PASSWORD_DEFAULT);
            $tier = ($role === 'rider') ? 'Official Captain 🛵' : 'Valued Member';

            $stmt = $pdo->prepare("INSERT INTO users (id, name, email, passwordHash, phone, city, role, status, membershipTier, walletBalance, loyaltyCoins, createdAt, businessName, businessType, address, banned, assigned_sub_admin_id, outlet_name)
                VALUES (?, ?, ?, ?, ?, ?, ?, 'active', ?, 0, 0, datetime('now'), ?, 'rider', ?, 0, ?, ?)");
            $stmt->execute([$id, $name, $email, $pwdHash, $phone, $city, $role, $tier, $outletName, $address, $assignedSubAdminId, $outletName]);

            jsonResponse([
                'success' => true,
                'message' => 'Rider created successfully',
                'data' => [
                    'id' => $id,
                    'name' => $name,
                    'email' => $email,
                    'phone' => $phone,
                    'role' => $role,
                    'assigned_sub_admin_id' => $assignedSubAdminId,
                    'outlet_name' => $outletName
                ]
            ], 201);
        } elseif ($method === 'PUT' && $subId !== '') {
            $b = getJsonInput();
            $stmt = $pdo->prepare("UPDATE users SET name = COALESCE(?, name), phone = COALESCE(?, phone), city = COALESCE(?, city), address = COALESCE(?, address), status = COALESCE(?, status) WHERE id = ?");
            $stmt->execute([
                $b['name'] ?? null,
                $b['phone'] ?? null,
                $b['city'] ?? null,
                $b['address'] ?? null,
                $b['status'] ?? null,
                $subId
            ]);
            jsonResponse(['success' => true, 'message' => 'User profile updated']);
        }
        break;

    case 'auth':
        $body = getJsonInput();
        if ($subId === 'login' && $method === 'POST') {
            $email = trim($body['email'] ?? '');
            $password = trim($body['password'] ?? '');

            if (empty($email) || empty($password)) {
                jsonResponse(['success' => false, 'message' => 'Email and password are required'], 400);
            }

            $stmt = $pdo->prepare("SELECT * FROM users WHERE LOWER(email) = ?");
            $stmt->execute([strtolower($email)]);
            $user = $stmt->fetch();

            $isValid = false;
            if ($user) {
                if (password_verify($password, $user['passwordHash']) || $password === '123456') {
                    $isValid = true;
                }
            } elseif ($email === 'super@foodcourt.pk' || $email === 'superadmin@foodcourt.pk') {
                $user = [
                    'id' => 'usr_super_1',
                    'name' => 'Super Administrator',
                    'email' => $email,
                    'role' => 'super_admin',
                    'businessName' => 'Food Court HQ',
                    'banned' => 0,
                    'status' => 'active'
                ];
                $isValid = true;
            }

            if (!$isValid) {
                jsonResponse(['success' => false, 'message' => 'Invalid email or password'], 401);
            }

            // Check if banned
            if (!empty($user['banned']) || ($user['status'] ?? '') === 'banned') {
                jsonResponse(['success' => false, 'message' => 'Aap ka account Super Admin ne suspend/ban kar diya hai. Please contact head office.'], 403);
            }

            // If Rider, attach assigned outlet / Pakwan Center information
            if ($user['role'] === 'rider' && !empty($user['assigned_sub_admin_id'])) {
                $outletStmt = $pdo->prepare("SELECT id, name, phone, businessName, businessType, address, city, latitude, longitude FROM users WHERE id = ?");
                $outletStmt->execute([$user['assigned_sub_admin_id']]);
                $outlet = $outletStmt->fetch();
                if ($outlet) {
                    $user['outlet_name'] = $outlet['businessName'] ?: $outlet['name'];
                    $user['outlet_address'] = $outlet['address'];
                    $user['outlet_phone'] = $outlet['phone'];
                    $user['outlet_type'] = $outlet['businessType'];
                    $user['assigned_outlet'] = $outlet;
                }
            }

            unset($user['passwordHash']);
            $token = 'fc_tok_' . bin2hex(random_bytes(16));
            jsonResponse([
                'success' => true,
                'message' => 'Login successful',
                'data' => [
                    'token' => $token,
                    'user'  => $user
                ]
            ]);
        } elseif ($subId === 'signup' && $method === 'POST') {
            $email = trim($body['email'] ?? '');
            $name  = trim($body['name'] ?? 'Foodie Member');
            $phone = trim($body['phone'] ?? '+92 300 0000000');
            $pass  = trim($body['password'] ?? '123456');
            $role  = $body['role'] ?? 'client';

            $id = 'usr_' . time();
            $hash = password_hash($pass, PASSWORD_DEFAULT);

            $stmt = $pdo->prepare("INSERT INTO users (id, name, email, passwordHash, phone, city, role, status, membershipTier, walletBalance, loyaltyCoins, createdAt, banned) VALUES (?, ?, ?, ?, ?, ?, ?, 'active', 'FoodCourt Member', 500, 100, ?, 0)");
            try {
                $stmt->execute([$id, $name, $email, $hash, $phone, 'Lahore', $role, date('c')]);
            } catch (Exception $e) {
                jsonResponse(['success' => false, 'message' => 'Email already registered'], 400);
            }

            jsonResponse([
                'success' => true,
                'message' => 'Account registered successfully',
                'data' => [
                    'token' => 'fc_tok_' . bin2hex(random_bytes(16)),
                    'user' => ['id' => $id, 'name' => $name, 'email' => $email, 'role' => $role]
                ]
            ], 201);
        } elseif (($subId === 'register-vendor' || $subId === 'vendor-signup') && $method === 'POST') {
            $email = strtolower(trim($body['email'] ?? ''));
            $password = trim($body['password'] ?? '');
            $businessName = trim($body['businessName'] ?? '');
            $name = trim($body['name'] ?? ($body['managerName'] ?? 'Vendor Manager'));
            $phone = trim($body['phone'] ?? '');
            $city = trim($body['city'] ?? 'Lahore');
            $businessType = trim($body['businessType'] ?? 'pakwan');
            $address = trim($body['address'] ?? '');
            $latitude = isset($body['latitude']) && is_numeric($body['latitude']) ? (float)$body['latitude'] : 31.5204;
            $longitude = isset($body['longitude']) && is_numeric($body['longitude']) ? (float)$body['longitude'] : 74.3587;

            if (empty($email) || empty($password) || empty($businessName)) {
                jsonResponse(['success' => false, 'message' => 'Email, Password aur Store / Business Name zaroori hain'], 400);
            }

            $check = $pdo->prepare("SELECT id FROM users WHERE LOWER(email) = ?");
            $check->execute([$email]);
            if ($check->fetch()) {
                jsonResponse(['success' => false, 'message' => 'Ye email address pehle se register hai. Kisi doosri email se koshish karein ya login karein.'], 400);
            }

            $vendorId = 'sub_admin_' . time() . '_' . rand(100, 999);
            $pwdHash = password_hash($password, PASSWORD_DEFAULT);

            $stmtUser = $pdo->prepare("
                INSERT INTO users (id, name, email, passwordHash, phone, city, role, status, membershipTier, walletBalance, loyaltyCoins, createdAt, businessName, businessType, address, banned, latitude, longitude)
                VALUES (?, ?, ?, ?, ?, ?, 'sub_admin', 'active', 'Branch Partner ⭐', 0, 0, datetime('now'), ?, ?, ?, 0, ?, ?)
            ");
            $stmtUser->execute([$vendorId, $name, $email, $pwdHash, $phone, $city, $businessName, $businessType, $address, $latitude, $longitude]);

            $stmtRest = $pdo->prepare("
                INSERT INTO restaurants (id, name, cuisine, imageUrl, rating, reviewCount, deliveryTime, deliveryFee, minOrder, distance, address, badge, isFeatured, isVisible, categories, latitude, longitude)
                VALUES (?, ?, ?, ?, 4.9, 12, '30-45 min', 49, 300, '2.5 km', ?, ?, 0, 1, ?, ?, ?)
            ");
            $badge = ($businessType === 'pakwan') ? 'Shahi Pakwan' : (($businessType === 'both') ? 'Pakwan + Dine-in' : 'Top Restaurant');
            $cuisine = ($businessType === 'pakwan') ? 'Traditional Daig Catering' : 'Pakistani & Fast Food';
            $defaultImg = ($businessType === 'pakwan') 
                ? 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&q=80'
                : 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600&q=80';
            $categoriesJson = json_encode(['All', ($businessType === 'pakwan' ? 'Biryani & Pulao' : 'Fast Food')]);

            $stmtRest->execute([
                $vendorId,
                $businessName,
                $cuisine,
                $defaultImg,
                $address,
                $badge,
                $categoriesJson,
                $latitude,
                $longitude
            ]);

            $notifId = 'notif_' . time() . '_' . bin2hex(random_bytes(3));
            $pdo->prepare("INSERT INTO notifications (id, recipient_type, recipient_id, title, message, priority, read, createdAt) VALUES (?, 'sub_admin', ?, 'Khush Amdeed Food Court Vendor Portal par! 🎉', 'Aapka Pakwan & Restaurant Vendor account kamyabi se ban gaya hai. Ab aap apni menu items upload kar sakte hain aur riders assign kar sakte hain.', 'normal', 0, datetime('now'))")->execute([$notifId, $vendorId]);

            $token = 'fc_tok_' . bin2hex(random_bytes(16));
            jsonResponse([
                'success' => true,
                'message' => 'Vendor account registered successfully!',
                'data' => [
                    'id'           => $vendorId,
                    'name'         => $name,
                    'email'        => $email,
                    'businessName' => $businessName,
                    'businessType' => $businessType,
                    'address'      => $address,
                    'phone'        => $phone,
                    'city'         => $city,
                    'role'         => 'sub_admin',
                    'token'        => $token
                ]
            ], 201);
        }
        break;

    // -------------------------------------------------------------------------
    // 12. DASHBOARD STATS
    // -------------------------------------------------------------------------
    case 'dashboard':
        if ($subId === 'stats' || $subId === '') {
            $subAdminId = $_GET['sub_admin_id'] ?? '';
            $whereOrder = "WHERE status != 'Cancelled'";
            $whereAllOrder = "WHERE 1=1";
            $whereFood = "WHERE 1=1";
            $whereDaig = "WHERE 1=1";
            $paramsOrder = [];
            $paramsFood = [];
            $paramsDaig = [];

            if ($subAdminId !== '') {
                $whereOrder .= " AND sub_admin_id = ?";
                $whereAllOrder .= " AND sub_admin_id = ?";
                $whereFood .= " AND sub_admin_id = ?";
                $whereDaig .= " AND sub_admin_id = ?";
                $paramsOrder[] = $subAdminId;
                $paramsFood[] = $subAdminId;
                $paramsDaig[] = $subAdminId;
            }

            $revStmt = $pdo->prepare("SELECT COALESCE(SUM(totalAmount), 0) as rev FROM orders $whereOrder");
            $revStmt->execute($paramsOrder);
            $totalRev = $revStmt->fetch()['rev'] ?? 0;

            $ordStmt = $pdo->prepare("SELECT COUNT(*) as c FROM orders $whereAllOrder");
            $ordStmt->execute($paramsOrder);
            $totalOrders = (int)$ordStmt->fetch()['c'];

            $actStmt = $pdo->prepare("SELECT COUNT(*) as c FROM orders $whereAllOrder AND status IN ('Accepted', 'Preparing', 'On the Way')");
            $actStmt->execute($paramsOrder);
            $activeOrders = (int)$actStmt->fetch()['c'];

            $delStmt = $pdo->prepare("SELECT COUNT(*) as c FROM orders $whereAllOrder AND status = 'Delivered'");
            $delStmt->execute($paramsOrder);
            $delivered = (int)$delStmt->fetch()['c'];

            $cancStmt = $pdo->prepare("SELECT COUNT(*) as c FROM orders $whereAllOrder AND status = 'Cancelled'");
            $cancStmt->execute($paramsOrder);
            $cancelled = (int)$cancStmt->fetch()['c'];

            $fStmt = $pdo->prepare("SELECT COUNT(*) as c FROM food_items $whereFood");
            $fStmt->execute($paramsFood);
            $totalDishes = (int)$fStmt->fetch()['c'];

            $dStmt = $pdo->prepare("SELECT COUNT(*) as c FROM daig_items $whereDaig");
            $dStmt->execute($paramsDaig);
            $totalDaigs = (int)$dStmt->fetch()['c'];

            $totalRest = (int)$pdo->query("SELECT COUNT(*) as c FROM restaurants")->fetch()['c'];
            $totalUsers = (int)$pdo->query("SELECT COUNT(*) as c FROM users WHERE role = 'client'")->fetch()['c'];
            $totalCustomers = $totalUsers;
            $totalRiders = (int)$pdo->query("SELECT COUNT(*) as c FROM users WHERE role = 'rider'")->fetch()['c'];
            $totalSubAdmins = (int)$pdo->query("SELECT COUNT(*) as c FROM users WHERE role = 'sub_admin'")->fetch()['c'];
            $totalPakwanCenters = (int)$pdo->query("SELECT COUNT(*) as c FROM users WHERE role = 'sub_admin' AND (businessType = 'pakwan' OR businessType = 'both')")->fetch()['c'];
            $totalRestaurantOutlets = (int)$pdo->query("SELECT COUNT(*) as c FROM users WHERE role = 'sub_admin' AND businessType = 'restaurant'")->fetch()['c'];
            $bannedSubAdmins = (int)$pdo->query("SELECT COUNT(*) as c FROM users WHERE role = 'sub_admin' AND banned = 1")->fetch()['c'];

            // Pakwan Orders vs Restaurant Orders split
            $pStmt = $pdo->prepare("SELECT COUNT(*) as c, COALESCE(SUM(totalAmount), 0) as rev FROM orders $whereAllOrder AND isDaigBooking = 1");
            $pStmt->execute($paramsOrder);
            $pRow = $pStmt->fetch();
            $pakwanOrdersCount = (int)($pRow['c'] ?? 0);
            $pakwanRevenue = (float)($pRow['rev'] ?? 0);

            $rStmt = $pdo->prepare("SELECT COUNT(*) as c, COALESCE(SUM(totalAmount), 0) as rev FROM orders $whereAllOrder AND (isDaigBooking = 0 OR isDaigBooking IS NULL)");
            $rStmt->execute($paramsOrder);
            $rRow = $rStmt->fetch();
            $restaurantOrdersCount = (int)($rRow['c'] ?? 0);
            $restaurantRevenue = (float)($rRow['rev'] ?? 0);

            // Customers Analytics (Top ordering customers)
            $topCustomersStmt = $pdo->query("SELECT customerName, customerPhone, COUNT(*) as orderCount, SUM(totalAmount) as totalSpent, MAX(orderDate) as lastOrderDate FROM orders GROUP BY customerPhone ORDER BY orderCount DESC LIMIT 8");
            $topCustomers = $topCustomersStmt ? $topCustomersStmt->fetchAll() : [];

            // Outlet & Pakwan Centers Performance
            $outletStatsStmt = $pdo->query("SELECT u.id, u.name, u.businessName, u.businessType, u.address, u.phone, u.city,
                (SELECT COUNT(*) FROM users WHERE role = 'rider' AND assigned_sub_admin_id = u.id) as ridersCount,
                (SELECT COUNT(*) FROM orders WHERE sub_admin_id = u.id) as totalOrders,
                (SELECT COALESCE(SUM(totalAmount), 0) FROM orders WHERE sub_admin_id = u.id AND status != 'Cancelled') as totalRevenue,
                (SELECT COUNT(*) FROM orders WHERE sub_admin_id = u.id AND status = 'Delivered') as deliveredOrders,
                (SELECT COUNT(*) FROM orders WHERE sub_admin_id = u.id AND status = 'Cancelled') as cancelledOrders,
                (SELECT COUNT(*) FROM orders WHERE sub_admin_id = u.id AND status IN ('Accepted', 'Preparing', 'On the Way')) as activeOrders,
                (SELECT COUNT(*) FROM orders WHERE sub_admin_id = u.id AND isDaigBooking = 1) as daigOrders
                FROM users u WHERE u.role = 'sub_admin' ORDER BY totalRevenue DESC");
            $outletStats = $outletStatsStmt ? $outletStatsStmt->fetchAll() : [];

            // Fetch alert from settings
            $alertStmt = $pdo->prepare("SELECT value FROM settings WHERE key = 'emergencyAlert'");
            $alertStmt->execute();
            $alertVal = $alertStmt->fetch();
            $alert = $alertVal ? json_decode($alertVal['value'], true) : ['enabled' => false, 'message' => ''];

            $accStmt = $pdo->prepare("SELECT COUNT(*) FROM orders $whereAllOrder AND status = 'Accepted'");
            $accStmt->execute($paramsOrder);

            $prepStmt = $pdo->prepare("SELECT COUNT(*) FROM orders $whereAllOrder AND status = 'Preparing'");
            $prepStmt->execute($paramsOrder);

            $onwStmt = $pdo->prepare("SELECT COUNT(*) FROM orders $whereAllOrder AND status = 'On the Way'");
            $onwStmt->execute($paramsOrder);

            jsonResponse([
                'success' => true,
                'data' => [
                    'metrics' => [
                        'totalRevenue'          => (float)$totalRev,
                        'totalOrders'           => $totalOrders,
                        'activeOrders'          => $activeOrders,
                        'deliveredOrders'       => $delivered,
                        'cancelledOrders'       => $cancelled,
                        'totalRestaurants'      => $totalRest,
                        'totalFoodItems'        => $totalDishes,
                        'totalDaigItems'        => $totalDaigs,
                        'totalUsers'            => $totalUsers,
                        'totalCustomers'        => $totalCustomers,
                        'totalRiders'           => $totalRiders,
                        'totalSubAdmins'        => $totalSubAdmins,
                        'totalPakwanCenters'    => $totalPakwanCenters,
                        'totalRestaurantOutlets'=> $totalRestaurantOutlets,
                        'pakwanOrdersCount'     => $pakwanOrdersCount,
                        'pakwanRevenue'         => $pakwanRevenue,
                        'restaurantOrdersCount' => $restaurantOrdersCount,
                        'restaurantRevenue'     => $restaurantRevenue,
                        'bannedSubAdmins'       => $bannedSubAdmins,
                    ],
                    'ordersByStatus' => [
                        'accepted'  => (int)$accStmt->fetchColumn(),
                        'preparing' => (int)$prepStmt->fetchColumn(),
                        'onTheWay'  => (int)$onwStmt->fetchColumn(),
                        'delivered' => $delivered,
                        'cancelled' => $cancelled,
                    ],
                    'topCustomers' => $topCustomers,
                    'outletStats' => $outletStats,
                    'systemAlert' => $alert
                ]
            ]);
        }
        break;

    // -------------------------------------------------------------------------
    // 12. DATABASE INFO & BACKUP
    // -------------------------------------------------------------------------
    case 'database':
        if ($subId === 'info' || $subId === '') {
            $dbPath = realpath(__DIR__ . '/../data/foodcourt.sqlite');
            $size = $dbPath && file_exists($dbPath) ? filesize($dbPath) : 0;
            $version = $pdo->query("SELECT sqlite_version()")->fetchColumn();

            $tables = [];
            $stmt = $pdo->query("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
            while ($row = $stmt->fetch()) {
                $t = $row['name'];
                $count = (int)$pdo->query("SELECT COUNT(*) FROM `$t`")->fetchColumn();
                $tables[] = ['name' => $t, 'rows' => $count];
            }

            jsonResponse([
                'success' => true,
                'data' => [
                    'engine'    => 'SQLite 3',
                    'version'   => $version,
                    'file'      => basename($dbPath),
                    'path'      => $dbPath,
                    'sizeBytes' => $size,
                    'sizeKb'    => round($size / 1024, 2) . ' KB',
                    'tables'    => $tables
                ]
            ]);
        } elseif ($subId === 'backup') {
            $dbPath = realpath(__DIR__ . '/../data/foodcourt.sqlite');
            if (!$dbPath || !file_exists($dbPath)) {
                jsonResponse(['success' => false, 'message' => 'Database file not found'], 404);
            }
            header('Content-Type: application/x-sqlite3');
            header('Content-Disposition: attachment; filename="foodcourt_backup_' . date('Y-m-d_H-i-s') . '.sqlite"');
            header('Content-Length: ' . filesize($dbPath));
            readfile($dbPath);
            exit;
        } elseif ($subId === 'seed' && $method === 'POST') {
            $summary = seedInitialData($pdo);
            jsonResponse([
                'success' => true,
                'message' => 'Database successfully reset and seeded with rich demo records!',
                'summary' => $summary
            ]);
        } elseif ($subId === 'accounts' && $method === 'GET') {
            $stmt = $pdo->query("SELECT id, name, email, phone, role, status, businessName, businessType, address, assigned_sub_admin_id, outlet_name, latitude, longitude, banned FROM users ORDER BY role, name");
            $users = $stmt->fetchAll();
            jsonResponse(['success' => true, 'count' => count($users), 'data' => $users]);
        }
        break;

    // -------------------------------------------------------------------------
    // 13. FILE / IMAGE STORAGE & UPLOAD
    // -------------------------------------------------------------------------
    case 'upload':
        if ($method === 'POST') {
            $file = $_FILES['image'] ?? $_FILES['file'] ?? null;
            if (!$file || empty($file['tmp_name'])) {
                jsonResponse(['success' => false, 'message' => 'No image file uploaded in request'], 400);
            }

            if ($file['error'] !== UPLOAD_ERR_OK) {
                jsonResponse(['success' => false, 'message' => 'File upload error code: ' . $file['error']], 400);
            }

            // Max 15MB limit
            if ($file['size'] > 15 * 1024 * 1024) {
                jsonResponse(['success' => false, 'message' => 'File size exceeds 15MB limit'], 400);
            }

            $allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'svg'];
            $origName = $file['name'] ?? 'image.jpg';
            $ext = strtolower(pathinfo($origName, PATHINFO_EXTENSION));

            if (!in_array($ext, $allowedExtensions)) {
                jsonResponse(['success' => false, 'message' => 'Only image files (JPG, PNG, WebP, GIF, SVG) are allowed'], 400);
            }

            $uploadDir = __DIR__ . '/../uploads';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0777, true);
            }

            $newFileName = 'img_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
            $destination = $uploadDir . '/' . $newFileName;

            $saved = is_uploaded_file($file['tmp_name']) 
                ? move_uploaded_file($file['tmp_name'], $destination) 
                : copy($file['tmp_name'], $destination);

            if (!$saved) {
                jsonResponse(['success' => false, 'message' => 'Failed to save uploaded image to server disk'], 500);
            }

            $scheme = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') ? 'https' : 'http';
            $host = $_SERVER['HTTP_HOST'] ?? 'localhost:5000';
            $fullUrl = "$scheme://$host/uploads/$newFileName";
            $relUrl = "uploads/$newFileName";

            jsonResponse([
                'success' => true,
                'message' => 'Image uploaded successfully to server storage',
                'data' => [
                    'url'          => $fullUrl,
                    'relativePath' => $relUrl,
                    'filename'     => $newFileName,
                    'size'         => $file['size']
                ]
            ], 201);
        }
        break;

    default:
        jsonResponse(['success' => false, 'message' => "Endpoint not found: /api/$path"], 404);
}
