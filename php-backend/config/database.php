<?php
// php-backend/config/database.php

function getDb(): PDO {
    static $pdo = null;
    if ($pdo !== null) {
        return $pdo;
    }

    $dbDir = __DIR__ . '/../data';
    if (!is_dir($dbDir)) {
        mkdir($dbDir, 0755, true);
    }

    $dbPath = $dbDir . '/foodcourt.sqlite';
    $isNewDb = !file_exists($dbPath);

    $pdo = new PDO('sqlite:' . $dbPath, null, null, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);

    $pdo->exec('PRAGMA foreign_keys = ON;');
    $pdo->exec('PRAGMA journal_mode = WAL;');

    // Initialize Schema if fresh database
    initDatabaseSchema($pdo);
    migrateSchemaUpdates($pdo);

    if ($isNewDb || getTableCount($pdo, 'restaurants') === 0) {
        seedInitialData($pdo);
    }

    return $pdo;
}

function getTableCount(PDO $pdo, string $table): int {
    try {
        $stmt = $pdo->query("SELECT COUNT(*) as cnt FROM $table");
        $res = $stmt->fetch();
        return (int)($res['cnt'] ?? 0);
    } catch (Exception $e) {
        return 0;
    }
}

function initDatabaseSchema(PDO $pdo): void {
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT
        );

        CREATE TABLE IF NOT EXISTS content (
            key TEXT PRIMARY KEY,
            value TEXT
        );

        CREATE TABLE IF NOT EXISTS categories (
            id TEXT PRIMARY KEY,
            name TEXT,
            icon TEXT,
            image TEXT,
            display_order INTEGER DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS restaurants (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            cuisine TEXT,
            imageUrl TEXT,
            rating REAL DEFAULT 4.8,
            reviewCount INTEGER DEFAULT 0,
            deliveryTime TEXT DEFAULT '25-35 min',
            deliveryFee REAL DEFAULT 49,
            minOrder REAL DEFAULT 250,
            distance TEXT DEFAULT '2.0 km',
            address TEXT,
            badge TEXT,
            isFeatured INTEGER DEFAULT 0,
            isVisible INTEGER DEFAULT 1,
            categories TEXT -- JSON array
        );

        CREATE TABLE IF NOT EXISTS food_items (
            id TEXT PRIMARY KEY,
            restaurantId TEXT NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            price REAL NOT NULL,
            imageUrl TEXT,
            category TEXT,
            rating REAL DEFAULT 4.8,
            calories INTEGER DEFAULT 500,
            isPopular INTEGER DEFAULT 0,
            isVegetarian INTEGER DEFAULT 0,
            isVisible INTEGER DEFAULT 1,
            badges TEXT -- JSON array
        );

        CREATE TABLE IF NOT EXISTS daig_items (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            urduName TEXT,
            description TEXT,
            category TEXT DEFAULT 'Biryani & Pulao',
            fullDaigPrice REAL NOT NULL,
            halfDaigPrice REAL NOT NULL,
            fullDaigWeight TEXT DEFAULT '12 KG (Serves 35-40 Persons)',
            halfDaigWeight TEXT DEFAULT '6 KG (Serves 18-20 Persons)',
            imageUrl TEXT,
            rating REAL DEFAULT 4.9,
            badge TEXT,
            deliveryNotice TEXT,
            isVisible INTEGER DEFAULT 1,
            includes TEXT -- JSON array
        );

        CREATE TABLE IF NOT EXISTS banners (
            id TEXT PRIMARY KEY,
            tagText TEXT,
            title TEXT,
            dishesText TEXT,
            buttonText TEXT DEFAULT 'Order Now',
            bgGradient TEXT, -- JSON array
            imageUrl TEXT,
            isVisible INTEGER DEFAULT 1,
            linkCategory TEXT
        );

        CREATE TABLE IF NOT EXISTS deals (
            id TEXT PRIMARY KEY,
            code TEXT NOT NULL,
            title TEXT NOT NULL,
            discountPercent INTEGER NOT NULL,
            description TEXT,
            imageUrl TEXT,
            category TEXT,
            startDate TEXT,
            endDate TEXT,
            startTime TEXT,
            endTime TEXT,
            minOrder REAL DEFAULT 0,
            maxDiscount REAL DEFAULT 1000,
            isVisible INTEGER DEFAULT 1,
            status TEXT DEFAULT 'active'
        );

        CREATE TABLE IF NOT EXISTS orders (
            id TEXT PRIMARY KEY,
            restaurantName TEXT,
            restaurantImage TEXT,
            items TEXT, -- JSON array
            totalAmount REAL NOT NULL,
            originalAmount REAL,
            discountInfo TEXT,
            orderDate TEXT,
            status TEXT DEFAULT 'Accepted',
            prepTime TEXT DEFAULT '25-35 mins',
            customerName TEXT,
            customerPhone TEXT,
            deliveryAddress TEXT,
            isDaigBooking INTEGER DEFAULT 0,
            occasion TEXT,
            notes TEXT,
            riderName TEXT,
            riderPhone TEXT
        );

        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT UNIQUE,
            passwordHash TEXT,
            phone TEXT,
            city TEXT DEFAULT 'Lahore',
            role TEXT DEFAULT 'client', -- client, rider, sub_admin, super_admin
            status TEXT DEFAULT 'active',
            membershipTier TEXT DEFAULT 'Valued Member',
            walletBalance REAL DEFAULT 0.0,
            loyaltyCoins INTEGER DEFAULT 0,
            createdAt TEXT,
            businessName TEXT DEFAULT '',
            businessType TEXT DEFAULT 'restaurant', -- restaurant, pakwan, both
            address TEXT DEFAULT '',
            banned INTEGER DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS notifications (
            id TEXT PRIMARY KEY,
            recipient_type TEXT DEFAULT 'sub_admin', -- sub_admin, client, rider, all
            recipient_id TEXT,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            priority TEXT DEFAULT 'normal', -- normal, important, urgent
            read INTEGER DEFAULT 0,
            createdAt TEXT
        );
    ");
}

function migrateSchemaUpdates(PDO $pdo): void {
    $helper = function($tbl, $col, $def) use ($pdo) {
        $stmt = $pdo->query("PRAGMA table_info($tbl)");
        $cols = array_column($stmt->fetchAll(), 'name');
        if (!in_array($col, $cols)) {
            $pdo->exec("ALTER TABLE $tbl ADD COLUMN $col $def");
        }
    };

    $helper('users', 'businessName', "TEXT DEFAULT ''");
    $helper('users', 'businessType', "TEXT DEFAULT 'restaurant'");
    $helper('users', 'address', "TEXT DEFAULT ''");
    $helper('users', 'banned', "INTEGER DEFAULT 0");

    $helper('banners', 'sub_admin_id', "TEXT DEFAULT ''");
    $helper('banners', 'discountPercent', "INTEGER DEFAULT 0");
    $helper('food_items', 'sub_admin_id', "TEXT DEFAULT ''");
    $helper('food_items', 'discountPercent', "INTEGER DEFAULT 0");
    $helper('food_items', 'discountPrice', "REAL DEFAULT 0");
    $helper('food_items', 'isDiscounted', "INTEGER DEFAULT 0");
    $helper('food_items', 'promoBadge', "TEXT DEFAULT ''");

    $helper('daig_items', 'sub_admin_id', "TEXT DEFAULT ''");
    $helper('daig_items', 'discountPercent', "INTEGER DEFAULT 0");
    $helper('daig_items', 'discountPrice', "REAL DEFAULT 0");
    $helper('daig_items', 'isDiscounted', "INTEGER DEFAULT 0");
    $helper('daig_items', 'promoBadge', "TEXT DEFAULT ''");
    $helper('orders', 'sub_admin_id', "TEXT DEFAULT ''");
    $helper('orders', 'rejectionReason', "TEXT DEFAULT ''");
    $helper('orders', 'latitude', "REAL DEFAULT 31.5204");
    $helper('orders', 'longitude', "REAL DEFAULT 74.3587");
    $helper('orders', 'event_date', "TEXT DEFAULT ''");
    $helper('orders', 'event_time', "TEXT DEFAULT ''");
    $helper('users', 'latitude', "REAL DEFAULT 31.5204");
    $helper('users', 'longitude', "REAL DEFAULT 74.3587");
    $helper('users', 'assigned_sub_admin_id', "TEXT DEFAULT 'sub_admin_2'");
    $helper('users', 'outlet_name', "TEXT DEFAULT 'Shahi Pakwan Center'");
    $helper('restaurants', 'latitude', "REAL DEFAULT 31.5204");
    $helper('restaurants', 'longitude', "REAL DEFAULT 74.3587");

    // Default coordinates for outlets
    $pdo->exec("UPDATE users SET latitude = 31.4870, longitude = 74.3210 WHERE id = 'sub_admin_2' AND (latitude IS NULL OR latitude = 0)");
    $pdo->exec("UPDATE users SET latitude = 31.5204, longitude = 74.3587 WHERE id = 'sub_admin_1' AND (latitude IS NULL OR latitude = 0)");
    $pdo->exec("UPDATE users SET latitude = 31.4697, longitude = 74.3792 WHERE id = 'sub_admin_3' AND (latitude IS NULL OR latitude = 0)");

    // Ensure banners have vendor and discount set
    $pdo->exec("UPDATE banners SET sub_admin_id = 'sub_admin_2', discountPercent = 25 WHERE id = 'ban_1' AND (sub_admin_id IS NULL OR sub_admin_id = '')");
    $pdo->exec("UPDATE banners SET sub_admin_id = 'sub_admin_1', discountPercent = 40 WHERE id = 'ban_2' AND (sub_admin_id IS NULL OR sub_admin_id = '')");
    $pdo->exec("UPDATE banners SET sub_admin_id = 'sub_admin_3', discountPercent = 30 WHERE id = 'ban_3' AND (sub_admin_id IS NULL OR sub_admin_id = '')");

    $pdo->exec("CREATE TABLE IF NOT EXISTS notifications (
        id TEXT PRIMARY KEY,
        recipient_type TEXT DEFAULT 'sub_admin',
        recipient_id TEXT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        priority TEXT DEFAULT 'normal',
        read INTEGER DEFAULT 0,
        createdAt TEXT
    )");
}

function seedInitialData(PDO $pdo): array {
    $pwd = password_hash('123456', PASSWORD_DEFAULT);

    // 1. SETTINGS
    $settings = [
        'appName' => 'Food Court & Shahi Pakwan',
        'currency' => 'Rs.',
        'deliveryFee' => '49',
        'supportPhone' => '+92 300 8472910',
        'platformFeePercent' => '5'
    ];
    $stmt = $pdo->prepare("INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)");
    foreach ($settings as $k => $v) {
        $stmt->execute([$k, (string)$v]);
    }

    // 2. CATEGORIES
    $categories = [
        ['cat_1', 'Biryani & Rice', '🍚', 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=300&q=80', 1],
        ['cat_2', 'Shahi Daig Catering', '👑', 'https://images.unsplash.com/photo-1544025162-d76694265947?w=300&q=80', 2],
        ['cat_3', 'Karahi & Handi', '🥘', 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=300&q=80', 3],
        ['cat_4', 'BBQ & Grills', '🍢', 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=300&q=80', 4],
        ['cat_5', 'Desserts & Sweets', '🍮', 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=300&q=80', 5],
        ['cat_6', 'Beverages & Chai', '🥤', 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=300&q=80', 6]
    ];
    $stmt = $pdo->prepare("INSERT OR REPLACE INTO categories (id, name, icon, image, display_order) VALUES (?, ?, ?, ?, ?)");
    foreach ($categories as $c) {
        $stmt->execute($c);
    }

    // 3. RESTAURANTS & PAKWAN CENTERS (for Mobile Discovery)
    $restaurants = [
        [
            'rest_1', 'Bannu Beef Pulao & Nalli Nihari', 'Traditional Bannu Pulao & Slow Cooked Nihari',
            'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&q=80', 4.9, 142, '25-35 min', 49, 250, '1.8 km',
            'Shop 12, Block K, Gulberg III, Lahore', 'BESTSELLER', 1, 1, json_encode(['Biryani & Rice', 'Desi Traditional']), 31.5204, 74.3587
        ],
        [
            'rest_2', 'Shahi Pakwan Center', 'Ceremonial Wood-fire Wedding & Event Daigs',
            'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&q=80', 4.9, 318, '45-60 min', 0, 5000, '3.2 km',
            'Bungalow 18-C, Model Town, Lahore', 'ROYAL HERITAGE 👑', 1, 1, json_encode(['Shahi Daig Catering', 'Biryani & Rice']), 31.4870, 74.3210
        ],
        [
            'rest_3', 'Dawat Khana Desi Heritage', 'Authentic Shinwari Karahi, Handi & BBQ',
            'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=500&q=80', 4.8, 89, '30-40 min', 49, 400, '2.5 km',
            'Main Boulevard, Phase 5, DHA, Lahore', 'FEATURED', 1, 1, json_encode(['Karahi & Handi', 'BBQ & Grills']), 31.4697, 74.3792
        ],
        [
            'rest_4', 'Madina Pakwan & Catering Service', 'Special Event Daigs, Haleem, Zarda & Kheer',
            'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=500&q=80', 4.7, 65, '50-70 min', 0, 4500, '4.1 km',
            'Commercial Plaza 8, Block G, Johar Town, Lahore', 'POPULAR PAKWAN', 1, 1, json_encode(['Shahi Daig Catering', 'Desserts & Sweets']), 31.4695, 74.2980
        ]
    ];
    $stmt = $pdo->prepare("INSERT OR REPLACE INTO restaurants (id, name, cuisine, imageUrl, rating, reviewCount, deliveryTime, deliveryFee, minOrder, distance, address, badge, isFeatured, isVisible, categories, latitude, longitude)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    foreach ($restaurants as $r) {
        $stmt->execute($r);
    }

    // 4. USERS: SUPER ADMIN (Platform Owner)
    $stmt = $pdo->prepare("INSERT OR REPLACE INTO users (id, name, email, passwordHash, phone, city, role, status, membershipTier, walletBalance, loyaltyCoins, createdAt, businessName, businessType, address, banned, latitude, longitude)
        VALUES ('usr_super_1', 'Super Administrator', 'super@foodcourt.pk', ?, '+92 300 8472910', 'Lahore', 'super_admin', 'active', 'Platform Owner 👑', 999999, 99999, datetime('now'), 'Food Court HQ', 'both', 'FoodCourt HQ, 14-C Gulberg III, Lahore', 0, 31.5204, 74.3587)");
    $stmt->execute([$pwd]);

    // 5. USERS: SUB-ADMINS (4 Pakwan Centers & Stores)
    $subAdmins = [
        [
            'id' => 'sub_admin_1',
            'name' => 'Tariq Mehmood',
            'email' => 'bannu.admin@foodcourt.pk',
            'phone' => '+92 300 1122334',
            'city' => 'Lahore',
            'businessName' => 'Bannu Beef Pulao & Nalli Nihari',
            'businessType' => 'restaurant',
            'address' => 'Shop 12, Block K, Gulberg III, Lahore',
            'lat' => 31.5204,
            'lng' => 74.3587
        ],
        [
            'id' => 'sub_admin_2',
            'name' => 'Chaudhry Tariq',
            'email' => 'shahi.pakwan@foodcourt.pk',
            'phone' => '+92 301 4455667',
            'city' => 'Lahore',
            'businessName' => 'Shahi Pakwan Center',
            'businessType' => 'pakwan',
            'address' => 'Bungalow 18-C, Model Town, Lahore',
            'lat' => 31.4870,
            'lng' => 74.3210
        ],
        [
            'id' => 'sub_admin_3',
            'name' => 'Malik Sohail',
            'email' => 'dawat.admin@foodcourt.pk',
            'phone' => '+92 322 1122334',
            'city' => 'Lahore',
            'businessName' => 'Dawat Khana Desi Heritage',
            'businessType' => 'both',
            'address' => 'Main Boulevard, Phase 5, DHA, Lahore',
            'lat' => 31.4697,
            'lng' => 74.3792
        ],
        [
            'id' => 'sub_admin_4',
            'name' => 'Haji Abdul Rehman',
            'email' => 'madina.pakwan@foodcourt.pk',
            'phone' => '+92 333 4455667',
            'city' => 'Lahore',
            'businessName' => 'Madina Pakwan & Catering Service',
            'businessType' => 'pakwan',
            'address' => 'Commercial Plaza 8, Block G, Johar Town, Lahore',
            'lat' => 31.4695,
            'lng' => 74.2980
        ]
    ];
    $stmt = $pdo->prepare("INSERT OR REPLACE INTO users (id, name, email, passwordHash, phone, city, role, status, membershipTier, walletBalance, loyaltyCoins, createdAt, businessName, businessType, address, banned, latitude, longitude)
        VALUES (?, ?, ?, ?, ?, ?, 'sub_admin', 'active', 'Branch Manager ⭐', 25000, 1500, datetime('now'), ?, ?, ?, 0, ?, ?)");
    foreach ($subAdmins as $sa) {
        $stmt->execute([$sa['id'], $sa['name'], $sa['email'], $pwd, $sa['phone'], $sa['city'], $sa['businessName'], $sa['businessType'], $sa['address'], $sa['lat'], $sa['lng']]);
    }

    // 6. USERS: DELIVERY RIDERS (2 Dedicated Riders for EACH Pakwan Center)
    $riders = [
        // Sub-Admin 1 Riders (Bannu Beef Pulao)
        [
            'id' => 'usr_rider_bannu_1',
            'name' => 'Captain Bilal Khan',
            'email' => 'rider.bannu@foodcourt.pk',
            'phone' => '+92 301 5551234',
            'city' => 'Lahore',
            'assigned_sub_admin_id' => 'sub_admin_1',
            'outlet_name' => 'Bannu Beef Pulao & Nalli Nihari',
            'address' => 'Gulberg III, Lahore'
        ],
        [
            'id' => 'usr_rider_bannu_2',
            'name' => 'Captain Zeeshan Tariq',
            'email' => 'rider.bannu2@foodcourt.pk',
            'phone' => '+92 301 8882233',
            'city' => 'Lahore',
            'assigned_sub_admin_id' => 'sub_admin_1',
            'outlet_name' => 'Bannu Beef Pulao & Nalli Nihari',
            'address' => 'Gulberg III, Lahore'
        ],
        // Sub-Admin 2 Riders (Shahi Pakwan Center)
        [
            'id' => 'usr_rider_shahi_1',
            'name' => 'Captain Ali Raza',
            'email' => 'rider@foodcourt.pk',
            'phone' => '+92 302 9988776',
            'city' => 'Lahore',
            'assigned_sub_admin_id' => 'sub_admin_2',
            'outlet_name' => 'Shahi Pakwan Center',
            'address' => 'Model Town, Lahore'
        ],
        [
            'id' => 'usr_rider_shahi_2',
            'name' => 'Captain Hamza Gujjar',
            'email' => 'rider.shahi2@foodcourt.pk',
            'phone' => '+92 302 4443322',
            'city' => 'Lahore',
            'assigned_sub_admin_id' => 'sub_admin_2',
            'outlet_name' => 'Shahi Pakwan Center',
            'address' => 'Model Town, Lahore'
        ],
        // Sub-Admin 3 Riders (Dawat Khana Desi Heritage)
        [
            'id' => 'usr_rider_dawat_1',
            'name' => 'Captain Usman Farooq',
            'email' => 'rider.dawat@foodcourt.pk',
            'phone' => '+92 321 4455667',
            'city' => 'Lahore',
            'assigned_sub_admin_id' => 'sub_admin_3',
            'outlet_name' => 'Dawat Khana Desi Heritage',
            'address' => 'Phase 5, DHA, Lahore'
        ],
        [
            'id' => 'usr_rider_dawat_2',
            'name' => 'Captain Kamran Butt',
            'email' => 'rider.dawat2@foodcourt.pk',
            'phone' => '+92 321 7776655',
            'city' => 'Lahore',
            'assigned_sub_admin_id' => 'sub_admin_3',
            'outlet_name' => 'Dawat Khana Desi Heritage',
            'address' => 'Phase 5, DHA, Lahore'
        ],
        // Sub-Admin 4 Riders (Madina Pakwan Center)
        [
            'id' => 'usr_rider_madina_1',
            'name' => 'Captain Rashid Minhas',
            'email' => 'rider.madina@foodcourt.pk',
            'phone' => '+92 333 1114455',
            'city' => 'Lahore',
            'assigned_sub_admin_id' => 'sub_admin_4',
            'outlet_name' => 'Madina Pakwan & Catering Service',
            'address' => 'Johar Town, Lahore'
        ],
        [
            'id' => 'usr_rider_madina_2',
            'name' => 'Captain Asad Warraich',
            'email' => 'rider.madina2@foodcourt.pk',
            'phone' => '+92 333 8889900',
            'city' => 'Lahore',
            'assigned_sub_admin_id' => 'sub_admin_4',
            'outlet_name' => 'Madina Pakwan & Catering Service',
            'address' => 'Johar Town, Lahore'
        ]
    ];
    $stmt = $pdo->prepare("INSERT OR REPLACE INTO users (id, name, email, passwordHash, phone, city, role, status, membershipTier, walletBalance, loyaltyCoins, createdAt, businessName, businessType, address, banned, assigned_sub_admin_id, outlet_name)
        VALUES (?, ?, ?, ?, ?, ?, 'rider', 'active', 'Official Captain 🛵', 1500, 50, datetime('now'), ?, 'rider', ?, 0, ?, ?)");
    foreach ($riders as $rd) {
        $stmt->execute([$rd['id'], $rd['name'], $rd['email'], $pwd, $rd['phone'], $rd['city'], $rd['outlet_name'], $rd['address'], $rd['assigned_sub_admin_id'], $rd['outlet_name']]);
    }

    // 7. USERS: DIVERSE CUSTOMERS (2-3 for EACH Pakwan Center / Store)
    $customers = [
        [
            'id' => 'usr_client_1',
            'name' => 'Hassan Raza',
            'email' => 'client@foodcourt.pk',
            'phone' => '+92 300 8472910',
            'city' => 'Lahore',
            'address' => 'House 42, Block H, Phase 5, DHA, Lahore',
            'lat' => 31.4720,
            'lng' => 74.3750,
            'tier' => 'Platinum Foodie 👑'
        ],
        [
            'id' => 'usr_client_2',
            'name' => 'Ayesha Khan',
            'email' => 'ayesha.client@foodcourt.pk',
            'phone' => '+92 301 2345678',
            'city' => 'Lahore',
            'address' => 'Flat 4B, Pace Tower, Gulberg III, Lahore',
            'lat' => 31.5150,
            'lng' => 74.3510,
            'tier' => 'Gold Member ⭐'
        ],
        [
            'id' => 'usr_client_3',
            'name' => 'Muhammad Ahmed',
            'email' => 'ahmed.client@foodcourt.pk',
            'phone' => '+92 302 3456789',
            'city' => 'Lahore',
            'address' => 'House 12, Block C, Model Town, Lahore',
            'lat' => 31.4850,
            'lng' => 74.3260,
            'tier' => 'Valued Member'
        ],
        [
            'id' => 'usr_client_4',
            'name' => 'Zainab Fatima',
            'email' => 'zainab.client@foodcourt.pk',
            'phone' => '+92 303 4567890',
            'city' => 'Lahore',
            'address' => 'House 88, Block G, Johar Town, Lahore',
            'lat' => 31.4680,
            'lng' => 74.2950,
            'tier' => 'Gold Member ⭐'
        ],
        [
            'id' => 'usr_client_5',
            'name' => 'Usman Tariq',
            'email' => 'usman.client@foodcourt.pk',
            'phone' => '+92 304 5678901',
            'city' => 'Lahore',
            'address' => 'Plaza 14, Main Market, Faisal Town, Lahore',
            'lat' => 31.4920,
            'lng' => 74.3080,
            'tier' => 'Valued Member'
        ],
        [
            'id' => 'usr_client_6',
            'name' => 'Sana Mir',
            'email' => 'sana.client@foodcourt.pk',
            'phone' => '+92 305 6789012',
            'city' => 'Lahore',
            'address' => 'House 17, Usman Block, Garden Town, Lahore',
            'lat' => 31.5030,
            'lng' => 74.3310,
            'tier' => 'Valued Member'
        ],
        [
            'id' => 'usr_client_7',
            'name' => 'Bilal Siddiqui',
            'email' => 'bilal.client@foodcourt.pk',
            'phone' => '+92 306 7890123',
            'city' => 'Lahore',
            'address' => 'House 23, Block E, Wapda Town, Lahore',
            'lat' => 31.4350,
            'lng' => 74.2620,
            'tier' => 'Platinum Foodie 👑'
        ],
        [
            'id' => 'usr_client_8',
            'name' => 'Fatima Noor',
            'email' => 'fatima.client@foodcourt.pk',
            'phone' => '+92 307 8901234',
            'city' => 'Lahore',
            'address' => 'House 9, St 4, Cavalry Ground, Lahore',
            'lat' => 31.5120,
            'lng' => 74.3780,
            'tier' => 'Gold Member ⭐'
        ]
    ];
    $stmt = $pdo->prepare("INSERT OR REPLACE INTO users (id, name, email, passwordHash, phone, city, role, status, membershipTier, walletBalance, loyaltyCoins, createdAt, businessName, businessType, address, banned, latitude, longitude)
        VALUES (?, ?, ?, ?, ?, ?, 'client', 'active', ?, 2400, 180, datetime('now'), '', 'client', ?, 0, ?, ?)");
    foreach ($customers as $cs) {
        $stmt->execute([$cs['id'], $cs['name'], $cs['email'], $pwd, $cs['phone'], $cs['city'], $cs['tier'], $cs['address'], $cs['lat'], $cs['lng']]);
    }

    // 8. FOOD ITEMS (For Restaurants & Outlets)
    $foodItems = [
        // Bannu Beef Pulao (sub_admin_1)
        ['food_1', 'rest_1', 'Special Bannu Beef Pulao Single', 'Authentic beef pulao cooked in rich bone marrow broth with tender beef pieces & fried onions.', 550, 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&q=80', 'Biryani & Rice', 4.9, 650, 1, 0, 'sub_admin_1'],
        ['food_2', 'rest_1', 'Bannu Beef Pulao Double Platter', 'Double serving of traditional Bannu beef pulao with nalli marrow chunks, raita & salad.', 950, 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&q=80', 'Biryani & Rice', 4.9, 1100, 1, 0, 'sub_admin_1'],
        ['food_3', 'rest_1', 'Special Nalli Nihari Bowl', 'Slow-cooked shank beef in rich spiced gravy with flowing bone marrow and ginger garnishing.', 750, 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&q=80', 'Karahi & Handi', 4.8, 800, 1, 0, 'sub_admin_1'],
        ['food_4', 'rest_1', 'Chicken Seekh Kabab (4 Pcs)', 'Charcoal grilled minced chicken skewers seasoned with ground aromatic herbs.', 450, 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&q=80', 'BBQ & Grills', 4.7, 450, 0, 0, 'sub_admin_1'],
        ['food_5', 'rest_1', 'Fresh Mint Lemonade', 'Chilled refreshing freshly squeezed lemon with crushed garden mint.', 150, 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=500&q=80', 'Beverages & Chai', 4.6, 120, 0, 1, 'sub_admin_1'],

        // Dawat Khana (sub_admin_3)
        ['food_6', 'rest_3', 'Mutton Shinwari Karahi Full', 'Peshawari style fresh mutton prepared in tomatoes, green chilies and pure animal fat/ghee.', 2800, 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=500&q=80', 'Karahi & Handi', 4.9, 1400, 1, 0, 'sub_admin_3'],
        ['food_7', 'rest_3', 'Chicken Madrasi Handi', 'Boneless creamy chicken cooked in clay pot handi with coconut and curry leaves.', 1450, 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=500&q=80', 'Karahi & Handi', 4.8, 900, 0, 0, 'sub_admin_3'],
        ['food_8', 'rest_3', 'Dawat Khana Dum Biryani', 'Layered saffron basmati rice with marinated chicken, fried onions, and whole spices.', 650, 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&q=80', 'Biryani & Rice', 4.8, 700, 1, 0, 'sub_admin_3'],
        ['food_9', 'rest_3', 'Special Gulab Jamun Warm (4 Pcs)', 'Soft milk solid dumplings soaked in rose and cardamom scented sugar syrup.', 400, 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=500&q=80', 'Desserts & Sweets', 4.9, 380, 1, 1, 'sub_admin_3'],
        ['food_10', 'rest_3', 'Garlic Naan Basket (2 Pcs)', 'Tandoori fresh leavened bread brushed with garlic butter and fresh coriander.', 160, 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&q=80', 'Karahi & Handi', 4.7, 240, 0, 1, 'sub_admin_3'],

        // Shahi Pakwan Tasting Dishes (sub_admin_2)
        ['food_11', 'rest_2', 'Shahi Deg Mutton Pulao Tasting Platter', 'Single premium portion of ceremonial wood-fire mutton deg with raita.', 750, 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&q=80', 'Biryani & Rice', 4.9, 680, 1, 0, 'sub_admin_2'],
        ['food_12', 'rest_2', 'Shahi Haleem Bowl with Tarka', 'Rich slow-cooked beef, lentils and cracked wheat garnished with golden onions and chaat masala.', 450, 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&q=80', 'Karahi & Handi', 4.8, 520, 0, 0, 'sub_admin_2']
    ];
    $stmt = $pdo->prepare("INSERT OR REPLACE INTO food_items (id, restaurantId, name, description, price, imageUrl, category, rating, calories, isPopular, isVegetarian, isVisible, badges, sub_admin_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, '[]', ?)");
    foreach ($foodItems as $fi) {
        $stmt->execute($fi);
    }

    // 9. SHAHI DAIG ITEMS (12 KG & 6 KG Event Cauldrons for Pakwan Centers)
    $daigDishes = [
        // Shahi Pakwan Center (sub_admin_2)
        [
            'daig_1', 'Shahi Mutton Deg Pulao', 'شاہی مٹن دیگ پلاؤ',
            'Prepared on traditional babool wood fire using premium basmati rice, tender young goat meat, and imperial spices.',
            'Biryani & Pulao', 18500, 9800, '12 KG (Serves 35-40 Persons)', '6 KG (Serves 18-20 Persons)',
            'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80', 5.0, 'SHAHI KHAS 👑',
            'Please book 4-6 hours prior for authentic wood-fire preparation.', 'sub_admin_2'
        ],
        [
            'daig_2', 'Special Shahi Beef Biryani Deg', 'شاہی بیف دیگ بریانی',
            'Rich beef cuts cooked in aromatic Karachi style masala with potatoes, prunes, and long grain aged rice.',
            'Biryani & Pulao', 16500, 8800, '12 KG (Serves 35-40 Persons)', '6 KG (Serves 18-20 Persons)',
            'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80', 4.9, 'ROYAL WEDDING',
            'Includes 2 Litres of Zeera Raita and Special Mint Chutney.', 'sub_admin_2'
        ],
        [
            'daig_3', 'Shahi Zarda Mutanjan Deg', 'شاہی متنجن زردہ دیگ',
            'Multicolor ceremonial sweet rice loaded with khoya, gulab jamun, ashrafi murabba, and roasted dry fruits.',
            'Desserts & Sweets', 11500, 6200, '12 KG (Serves 35-40 Persons)', '6 KG (Serves 18-20 Persons)',
            'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=700&q=80', 4.9, 'SWEET FEAST',
            'Perfect for Mehndi, Milad, and Reception feasts.', 'sub_admin_2'
        ],
        [
            'daig_4', 'Shahi Haleem Deg with Desi Ghee Tarka', 'شاہی خاص حلیم دیگ',
            'Slow simmered for 10 hours with 7 whole grains, shredded beef fibers, and sizzling desi ghee tarka.',
            'Traditional Desi', 14000, 7500, '12 KG (Serves 35-40 Persons)', '6 KG (Serves 18-20 Persons)',
            'https://images.unsplash.com/photo-1544025162-d76694265947?w=700&q=80', 4.8, 'AUTHENTIC',
            'Includes full garnishing platter (fried onions, green chilies, ginger & lemons).', 'sub_admin_2'
        ],
        [
            'daig_5', 'Shahi Chicken Qorma Deg', 'شاہi چکن قورمہ دیگ',
            'Velvety almond and yogurt based gravy cooked with whole pieces of chicken and scented kewra essence.',
            'Traditional Desi', 15000, 8000, '12 KG (Serves 35-40 Persons)', '6 KG (Serves 18-20 Persons)',
            'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=700&q=80', 4.8, 'EVENT FAVORITE',
            'Best served with hot tandoori roghani naan.', 'sub_admin_2'
        ],

        // Madina Pakwan Center (sub_admin_4)
        [
            'daig_6', 'Madina Shahi Chicken Biryani Deg', 'مدینہ شاہی چکن بریانی دیگ',
            'Fragrant chicken biryani prepared in desi spices, whole black cardamom, and saffron dum.',
            'Biryani & Pulao', 12500, 6800, '12 KG (Serves 35-40 Persons)', '6 KG (Serves 18-20 Persons)',
            'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80', 4.7, 'TOP VALUE',
            'Includes free raita canisters.', 'sub_admin_4'
        ],
        [
            'daig_7', 'Traditional Beef Pulao Deg', 'روایتی بیف پلاؤ دیگ',
            'Rich beef yakhni pulao cooked in pure beef stock with golden fried onions.',
            'Biryani & Pulao', 15500, 8200, '12 KG (Serves 35-40 Persons)', '6 KG (Serves 18-20 Persons)',
            'https://images.unsplash.com/photo-1544025162-d76694265947?w=700&q=80', 4.8, 'CLASSIC LAHORE',
            'Prepared with aged super kernel basmati.', 'sub_admin_4'
        ],
        [
            'daig_8', 'Madina Special Sweet Kheer Deg', 'مدینہ زعفرانی کھیر دیگ',
            'Slow-boiled full cream milk kheer infused with saffron, crushed pistachios, and silver wark.',
            'Desserts & Sweets', 9500, 5200, '12 KG (Serves 35-40 Persons)', '6 KG (Serves 18-20 Persons)',
            'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=700&q=80', 4.9, 'DESI MITHAS',
            'Served cold in traditional clay pots upon request.', 'sub_admin_4'
        ]
    ];
    $stmt = $pdo->prepare("INSERT OR REPLACE INTO daig_items (id, name, urduName, description, category, fullDaigPrice, halfDaigPrice, fullDaigWeight, halfDaigWeight, imageUrl, rating, badge, deliveryNotice, isVisible, includes, sub_admin_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, '[]', ?)");
    foreach ($daigDishes as $dd) {
        $stmt->execute($dd);
    }

    // 10. DEALS & VOUCHERS
    $deals = [
        ['deal_1', 'BANNU15', 'Bannu Special Discount', 15, 'Flat 15% discount on all beef pulao orders above Rs. 1000', 'sub_admin_1', 1000],
        ['deal_2', 'SHAHI20', 'Shahi Daig Booking Off', 20, 'Flat 20% discount on ceremonial event daigs booking above Rs. 10,000', 'sub_admin_2', 10000],
        ['deal_3', 'DAWAT10', 'Dawat Khana Feast Offer', 10, 'Flat 10% discount on Shinwari Karahi & Handi platters', 'sub_admin_3', 1500],
        ['deal_4', 'MADINA25', 'Madina Pakwan Weekend Deal', 25, 'Flat 25% discount on advance daig bookings', 'sub_admin_4', 8000],
        ['deal_5', 'WELCOME100', 'New Customer Welcome', 10, 'Welcome discount for new app customers', '', 500]
    ];
    $stmt = $pdo->prepare("INSERT OR REPLACE INTO deals (id, code, title, discountPercent, description, category, startDate, endDate, startTime, endTime, minOrder, maxDiscount, isVisible, status)
        VALUES (?, ?, ?, ?, ?, ?, '2025-01-01', '2027-12-31', '00:00', '23:59', ?, 1500, 1, 'active')");
    foreach ($deals as $dl) {
        $stmt->execute([$dl[0], $dl[1], $dl[2], $dl[3], $dl[4], $dl[5], $dl[6]]);
    }

    // 11. BANNERS
    $banners = [
        ['ban_1', 'SHAHI PAKWAN', 'Wood-Fire Shahi Daig Booking', 'Biryani, Pulao, Zarda, Haleem & Kheer Cauldrons', 'Book Daig Now', json_encode(['#FF9500', '#EA580C']), 'https://images.unsplash.com/photo-1544025162-d76694265947?w=700&q=80', 1, 'Shahi Daig Catering'],
        ['ban_2', 'SPECIAL DEAL', 'Authentic Bannu Beef Pulao', 'Rich bone marrow stock & slow simmered meat', 'Order Pulao', json_encode(['#D97706', '#B45309']), 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80', 1, 'Biryani & Rice'],
        ['ban_3', 'HERITAGE FEAST', 'Shinwari Mutton Karahi', 'Cooked fresh in tomatoes & traditional ghee', 'Order Shinwari', json_encode(['#DC2626', '#991B1B']), 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=700&q=80', 1, 'Karahi & Handi']
    ];
    $stmt = $pdo->prepare("INSERT OR REPLACE INTO banners (id, tagText, title, dishesText, buttonText, bgGradient, imageUrl, isVisible, linkCategory)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
    foreach ($banners as $bn) {
        $stmt->execute($bn);
    }

    // 12. ORDERS: COMPREHENSIVE ORDERS COVERING ALL LIFECYCLE STATES
    // - Approval / Pending (Accepted)
    // - Kitchen Preparation (Preparing)
    // - Ride Pohanchana / Route Active (On the Way) with assigned rider & GPS
    // - Delivered (Delivered)
    // - Rejected / Cancelled with Reason (Cancelled)
    // - Daig Ceremonial Bookings (isDaigBooking = 1)
    $orders = [
        // Order 1: APPROVAL / PENDING (Accepted) -> Bannu Beef Pulao
        [
            'id' => 'FC-1011',
            'restaurantName' => 'Bannu Beef Pulao & Nalli Nihari',
            'restaurantImage' => 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&q=80',
            'items' => json_encode(['Special Bannu Beef Pulao Single', 'Special Nalli Nihari Bowl']),
            'totalAmount' => 1300,
            'originalAmount' => 1300,
            'orderDate' => date('Y-m-d H:i:s', strtotime('-15 minutes')),
            'status' => 'Accepted', // Approval / Pending stage
            'prepTime' => '25-35 mins',
            'customerName' => 'Ayesha Khan',
            'customerPhone' => '+92 301 2345678',
            'deliveryAddress' => 'Flat 4B, Pace Tower, Gulberg III, Lahore',
            'isDaigBooking' => 0,
            'occasion' => '',
            'notes' => 'Please provide extra raita and spoons.',
            'riderName' => '',
            'riderPhone' => '',
            'sub_admin_id' => 'sub_admin_1',
            'rejectionReason' => '',
            'latitude' => 31.5150,
            'longitude' => 74.3510
        ],
        // Order 2: KITCHEN COOKING (Preparing) -> Shahi Pakwan Center
        [
            'id' => 'FC-1022',
            'restaurantName' => 'Shahi Pakwan Center',
            'restaurantImage' => 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&q=80',
            'items' => json_encode(['1x Special Shahi Beef Biryani Deg (Full Daig 12 KG)']),
            'totalAmount' => 16500,
            'originalAmount' => 16500,
            'orderDate' => date('Y-m-d H:i:s', strtotime('-45 minutes')),
            'status' => 'Preparing', // In Kitchen cooking stage
            'prepTime' => '45-60 mins',
            'customerName' => 'Muhammad Ahmed',
            'customerPhone' => '+92 302 3456789',
            'deliveryAddress' => 'House 12, Block C, Model Town, Lahore',
            'isDaigBooking' => 1,
            'occasion' => 'Family Valima Dawat',
            'notes' => 'Prepare with mild spices for wedding guests.',
            'riderName' => '',
            'riderPhone' => '',
            'sub_admin_id' => 'sub_admin_2',
            'rejectionReason' => '',
            'latitude' => 31.4850,
            'longitude' => 74.3260
        ],
        // Order 3: RIDE POHANCHANA / IN TRANSIT (On the Way) -> Shahi Pakwan Center
        [
            'id' => 'FC-1033',
            'restaurantName' => 'Shahi Pakwan Center',
            'restaurantImage' => 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&q=80',
            'items' => json_encode(['1x Shahi Mutton Deg Pulao (Half Daig 6 KG)', '2x Zeera Raita', 'Fresh Salad']),
            'totalAmount' => 9800,
            'originalAmount' => 9800,
            'orderDate' => date('Y-m-d H:i:s', strtotime('-1 hour 10 minutes')),
            'status' => 'On the Way', // Ride Pohanchana / Active delivery stage
            'prepTime' => 'Dispatched',
            'customerName' => 'Hassan Raza',
            'customerPhone' => '+92 300 8472910',
            'deliveryAddress' => 'House 42, Block H, Phase 5, DHA, Lahore',
            'isDaigBooking' => 1,
            'occasion' => 'Milad Mehfil',
            'notes' => 'Deliver before Maghrib prayer.',
            'riderName' => 'Captain Ali Raza',
            'riderPhone' => '+92 302 9988776',
            'sub_admin_id' => 'sub_admin_2',
            'rejectionReason' => '',
            'latitude' => 31.4720,
            'longitude' => 74.3750
        ],
        // Order 4: RIDE POHANCHANA / IN TRANSIT (On the Way) -> Bannu Beef Pulao
        [
            'id' => 'FC-1044',
            'restaurantName' => 'Bannu Beef Pulao & Nalli Nihari',
            'restaurantImage' => 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&q=80',
            'items' => json_encode(['2x Bannu Beef Pulao Double Platter', '2x Fresh Mint Lemonade']),
            'totalAmount' => 2200,
            'originalAmount' => 2200,
            'orderDate' => date('Y-m-d H:i:s', strtotime('-30 minutes')),
            'status' => 'On the Way', // Ride Pohanchana stage
            'prepTime' => 'Dispatched',
            'customerName' => 'Usman Tariq',
            'customerPhone' => '+92 304 5678901',
            'deliveryAddress' => 'Plaza 14, Main Market, Faisal Town, Lahore',
            'isDaigBooking' => 0,
            'occasion' => '',
            'notes' => 'Call rider when arriving at gate.',
            'riderName' => 'Captain Bilal Khan',
            'riderPhone' => '+92 301 5551234',
            'sub_admin_id' => 'sub_admin_1',
            'rejectionReason' => '',
            'latitude' => 31.4920,
            'longitude' => 74.3080
        ],
        // Order 5: DELIVERED (Successfully Completed) -> Dawat Khana Desi Heritage
        [
            'id' => 'FC-1055',
            'restaurantName' => 'Dawat Khana Desi Heritage',
            'restaurantImage' => 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=500&q=80',
            'items' => json_encode(['Mutton Shinwari Karahi Full', '6x Roghani Naan', 'Special Gulab Jamun Warm']),
            'totalAmount' => 4850,
            'originalAmount' => 4850,
            'orderDate' => date('Y-m-d H:i:s', strtotime('-3 hours')),
            'status' => 'Delivered', // Successfully delivered stage
            'prepTime' => 'Delivered in 28 mins',
            'customerName' => 'Zainab Fatima',
            'customerPhone' => '+92 303 4567890',
            'deliveryAddress' => 'House 88, Block G, Johar Town, Lahore',
            'isDaigBooking' => 0,
            'occasion' => '',
            'notes' => 'Order completed satisfactorily.',
            'riderName' => 'Captain Usman Farooq',
            'riderPhone' => '+92 321 4455667',
            'sub_admin_id' => 'sub_admin_3',
            'rejectionReason' => '',
            'latitude' => 31.4680,
            'longitude' => 74.2950
        ],
        // Order 6: DELIVERED (Successfully Completed) -> Shahi Pakwan Center
        [
            'id' => 'FC-1066',
            'restaurantName' => 'Shahi Pakwan Center',
            'restaurantImage' => 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&q=80',
            'items' => json_encode(['1x Shahi Zarda Mutanjan Deg (Full Daig 12 KG)']),
            'totalAmount' => 11500,
            'originalAmount' => 11500,
            'orderDate' => date('Y-m-d H:i:s', strtotime('-5 hours')),
            'status' => 'Delivered', // Delivered stage
            'prepTime' => 'Delivered on Schedule',
            'customerName' => 'Bilal Siddiqui',
            'customerPhone' => '+92 306 7890123',
            'deliveryAddress' => 'House 23, Block E, Wapda Town, Lahore',
            'isDaigBooking' => 1,
            'occasion' => 'Wedding Mehndi Night',
            'notes' => 'Received hot and fresh.',
            'riderName' => 'Captain Hamza Gujjar',
            'riderPhone' => '+92 302 4443322',
            'sub_admin_id' => 'sub_admin_2',
            'rejectionReason' => '',
            'latitude' => 31.4350,
            'longitude' => 74.2620
        ],
        // Order 7: REJECTED / CANCELLED (With Reason) -> Bannu Beef Pulao
        [
            'id' => 'FC-1077',
            'restaurantName' => 'Bannu Beef Pulao & Nalli Nihari',
            'restaurantImage' => 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&q=80',
            'items' => json_encode(['4x Bannu Beef Pulao Single', '2x Special Nalli Nihari Bowl']),
            'totalAmount' => 3700,
            'originalAmount' => 3700,
            'orderDate' => date('Y-m-d H:i:s', strtotime('-2 hours')),
            'status' => 'Cancelled', // Rejected stage
            'prepTime' => 'Rejected',
            'customerName' => 'Sana Mir',
            'customerPhone' => '+92 305 6789012',
            'deliveryAddress' => 'House 17, Usman Block, Garden Town, Lahore',
            'isDaigBooking' => 0,
            'occasion' => '',
            'notes' => '',
            'riderName' => '',
            'riderPhone' => '',
            'sub_admin_id' => 'sub_admin_1',
            'rejectionReason' => 'Kitchen is over capacity / rush hour',
            'latitude' => 31.5030,
            'longitude' => 74.3310
        ],
        // Order 8: REJECTED / CANCELLED (With Reason) -> Madina Pakwan Center
        [
            'id' => 'FC-1088',
            'restaurantName' => 'Madina Pakwan & Catering Service',
            'restaurantImage' => 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=500&q=80',
            'items' => json_encode(['1x Madina Shahi Chicken Biryani Deg (Full Daig 12 KG)']),
            'totalAmount' => 12500,
            'originalAmount' => 12500,
            'orderDate' => date('Y-m-d H:i:s', strtotime('-4 hours')),
            'status' => 'Cancelled', // Rejected stage
            'prepTime' => 'Rejected',
            'customerName' => 'Fatima Noor',
            'customerPhone' => '+92 307 8901234',
            'deliveryAddress' => 'House 9, St 4, Cavalry Ground, Lahore',
            'isDaigBooking' => 1,
            'occasion' => 'Dinner Party',
            'notes' => '',
            'riderName' => '',
            'riderPhone' => '',
            'sub_admin_id' => 'sub_admin_4',
            'rejectionReason' => 'Delivery address is beyond service radius (18 km away)',
            'latitude' => 31.5120,
            'longitude' => 74.3780
        ],
        // Order 9: APPROVAL / PENDING (Accepted) -> Madina Pakwan Center
        [
            'id' => 'FC-1099',
            'restaurantName' => 'Madina Pakwan & Catering Service',
            'restaurantImage' => 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=500&q=80',
            'items' => json_encode(['1x Traditional Beef Pulao Deg (Half Daig 6 KG)', '1x Madina Special Sweet Kheer Deg (Half Daig 6 KG)']),
            'totalAmount' => 13400,
            'originalAmount' => 13400,
            'orderDate' => date('Y-m-d H:i:s', strtotime('-10 minutes')),
            'status' => 'Accepted', // Approval / Pending stage
            'prepTime' => '60 mins',
            'customerName' => 'Muhammad Ahmed',
            'customerPhone' => '+92 302 3456789',
            'deliveryAddress' => 'Commercial Area, Johar Town, Lahore',
            'isDaigBooking' => 1,
            'occasion' => 'Office Milestone Celebration',
            'notes' => 'Please arrive at 8 PM sharp.',
            'riderName' => '',
            'riderPhone' => '',
            'sub_admin_id' => 'sub_admin_4',
            'rejectionReason' => '',
            'latitude' => 31.4695,
            'longitude' => 74.2980
        ],
        // Order 10: KITCHEN COOKING (Preparing) -> Dawat Khana Desi Heritage
        [
            'id' => 'FC-1100',
            'restaurantName' => 'Dawat Khana Desi Heritage',
            'restaurantImage' => 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=500&q=80',
            'items' => json_encode(['Chicken Madrasi Handi', 'Dawat Khana Dum Biryani', '4x Garlic Naan Basket']),
            'totalAmount' => 2420,
            'originalAmount' => 2420,
            'orderDate' => date('Y-m-d H:i:s', strtotime('-25 minutes')),
            'status' => 'Preparing', // In Kitchen cooking stage
            'prepTime' => '30 mins',
            'customerName' => 'Hassan Raza',
            'customerPhone' => '+92 300 8472910',
            'deliveryAddress' => 'House 42, Block H, Phase 5, DHA, Lahore',
            'isDaigBooking' => 0,
            'occasion' => '',
            'notes' => 'Extra spicy please.',
            'riderName' => '',
            'riderPhone' => '',
            'sub_admin_id' => 'sub_admin_3',
            'rejectionReason' => '',
            'latitude' => 31.4720,
            'longitude' => 74.3750
        ]
    ];
    $stmt = $pdo->prepare("INSERT OR REPLACE INTO orders (id, restaurantName, restaurantImage, items, totalAmount, originalAmount, orderDate, status, prepTime, customerName, customerPhone, deliveryAddress, isDaigBooking, occasion, notes, riderName, riderPhone, sub_admin_id, rejectionReason, latitude, longitude)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    foreach ($orders as $od) {
        $stmt->execute([
            $od['id'], $od['restaurantName'], $od['restaurantImage'], $od['items'],
            $od['totalAmount'], $od['originalAmount'], $od['orderDate'], $od['status'],
            $od['prepTime'], $od['customerName'], $od['customerPhone'], $od['deliveryAddress'],
            $od['isDaigBooking'], $od['occasion'], $od['notes'], $od['riderName'],
            $od['riderPhone'], $od['sub_admin_id'], $od['rejectionReason'], $od['latitude'], $od['longitude']
        ]);
    }

    return [
        'super_admins' => 1,
        'sub_admins' => count($subAdmins),
        'riders' => count($riders),
        'customers' => count($customers),
        'orders' => count($orders),
        'food_items' => count($foodItems),
        'daig_dishes' => count($daigDishes),
        'deals' => count($deals)
    ];
}
