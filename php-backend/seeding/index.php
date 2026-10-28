<?php
/**
 * FoodCourt & Shahi Pakwan — Standalone Database Seeding & Dummy Data Import Tool
 * Route: /seeding (or /seeding/index.php, /seeding.php)
 * 
 * Manages SQLite3 database seeding and imports from external seed files (seed_data.sql / seed_data.json).
 */

require_once __DIR__ . '/../config/database.php';

$pdo = getDb();
$message = null;
$messageType = null;
$executionLog = [];

// Determine paths to external seed files
$possibleSqlPaths = [
    __DIR__ . '/../seed_data.sql',
    dirname(__DIR__, 2) . '/seed_data.sql',
    __DIR__ . '/seed_data.sql'
];

$sqlFilePath = null;
foreach ($possibleSqlPaths as $path) {
    if (file_exists($path)) {
        $sqlFilePath = $path;
        break;
    }
}
if (!$sqlFilePath) {
    $sqlFilePath = __DIR__ . '/../seed_data.sql';
}

$possibleJsonPaths = [
    __DIR__ . '/../seed_data.json',
    dirname(__DIR__, 2) . '/seed_data.json',
    __DIR__ . '/seed_data.json'
];

$jsonFilePath = null;
foreach ($possibleJsonPaths as $path) {
    if (file_exists($path)) {
        $jsonFilePath = $path;
        break;
    }
}
if (!$jsonFilePath) {
    $jsonFilePath = __DIR__ . '/../seed_data.json';
}

// -----------------------------------------------------------------------------
// POST ACTIONS HANDLING
// -----------------------------------------------------------------------------
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    // 1. IMPORT FROM EXTERNAL SEED FILE (seed_data.sql)
    if ($action === 'import_external_sql') {
        if (!file_exists($sqlFilePath)) {
            $message = "External seed file not found at: " . htmlspecialchars($sqlFilePath);
            $messageType = "error";
        } else {
            $startTime = microtime(true);
            try {
                $sqlContent = file_get_contents($sqlFilePath);
                if (empty($sqlContent)) {
                    throw new Exception("External seed_data.sql is empty.");
                }

                initDatabaseSchema($pdo);
                migrateSchemaUpdates($pdo);

                $pdo->beginTransaction();
                // Execute multi-query SQL
                $pdo->exec($sqlContent);
                $pdo->commit();

                $elapsed = round((microtime(true) - $startTime) * 1000, 2);
                $fileSizeKb = round(filesize($sqlFilePath) / 1024, 1);
                $message = "Successfully imported entire external dummy dataset from seed_data.sql ({$fileSizeKb} KB) into SQLite3 in {$elapsed} ms!";
                $messageType = "success";
                $executionLog[] = "Read external file: {$sqlFilePath}";
                $executionLog[] = "Database schema verified & refreshed.";
                $executionLog[] = "Transaction committed successfully.";
            } catch (Throwable $e) {
                if ($pdo->inTransaction()) {
                    $pdo->rollBack();
                }
                $message = "Import Failed: " . $e->getMessage();
                $messageType = "error";
                $executionLog[] = "Error: " . $e->getMessage();
            }
        }
    }

    // 2. EXECUTE BUILT-IN SEED ENGINE (seedInitialData)
    elseif ($action === 'seed_builtin') {
        $startTime = microtime(true);
        try {
            initDatabaseSchema($pdo);
            migrateSchemaUpdates($pdo);

            $summary = seedInitialData($pdo);
            $elapsed = round((microtime(true) - $startTime) * 1000, 2);

            $message = "Built-in Seeding Engine executed successfully in {$elapsed} ms!";
            $messageType = "success";
            $executionLog[] = "Reset & seeded: {$summary['sub_admins']} Store/Pakwan Centers, {$summary['riders']} Dedicated Riders, {$summary['customers']} Customers.";
            $executionLog[] = "Seeded {$summary['food_items']} restaurant dishes and {$summary['daig_dishes']} Shahi Daigs.";
            $executionLog[] = "Generated {$summary['orders']} live lifecycle orders across all 5 stages.";
        } catch (Throwable $e) {
            $message = "Seeding Failed: " . $e->getMessage();
            $messageType = "error";
            $executionLog[] = "Error: " . $e->getMessage();
        }
    }

    // 3. EXPORT LIVE DATABASE TO EXTERNAL SEED FILES
    elseif ($action === 'export_to_external') {
        $startTime = microtime(true);
        try {
            $tables = ["settings", "content", "categories", "restaurants", "food_items", "daig_items", "banners", "deals", "orders", "users"];
            $sql = "-- =============================================================================\n";
            $sql .= "-- FoodCourt & Pakwan — External SQLite3 Dummy Seed Dataset\n";
            $sql .= "-- Location: Root / External (Can be modified outside without altering PHP code)\n";
            $sql .= "-- Snapshot Created: " . date("Y-m-d H:i:s") . "\n";
            $sql .= "-- =============================================================================\n\n";

            $jsonData = [];
            foreach ($tables as $table) {
                $rows = $pdo->query("SELECT * FROM \"$table\"")->fetchAll(PDO::FETCH_ASSOC);
                $jsonData[$table] = $rows;
                $sql .= "-- -----------------------------------------------------------------------------\n";
                $sql .= "-- Table: $table (" . count($rows) . " records)\n";
                $sql .= "-- -----------------------------------------------------------------------------\n";
                if (empty($rows)) {
                    $sql .= "\n";
                    continue;
                }
                $cols = array_keys($rows[0]);
                $colsStr = implode(", ", array_map(function($c) { return '"' . $c . '"'; }, $cols));
                foreach ($rows as $row) {
                    $vals = [];
                    foreach ($cols as $col) {
                        $val = $row[$col];
                        if ($val === null) {
                            $vals[] = 'NULL';
                        } elseif (is_numeric($val) && !preg_match('/^0[0-9]+/', (string)$val)) {
                            $vals[] = $val;
                        } else {
                            $vals[] = "'" . str_replace("'", "''", (string)$val) . "'";
                        }
                    }
                    $valsStr = implode(', ', $vals);
                    $sql .= "INSERT OR REPLACE INTO \"$table\" ($colsStr) VALUES ($valsStr);\n";
                }
                $sql .= "\n";
            }

            file_put_contents($sqlFilePath, $sql);
            if (file_exists(dirname(__DIR__, 2) . '/seed_data.sql')) {
                file_put_contents(dirname(__DIR__, 2) . '/seed_data.sql', $sql);
            }

            $jsonFormatted = json_encode($jsonData, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
            file_put_contents($jsonFilePath, $jsonFormatted);
            if (file_exists(dirname(__DIR__, 2) . '/seed_data.json')) {
                file_put_contents(dirname(__DIR__, 2) . '/seed_data.json', $jsonFormatted);
            }

            $elapsed = round((microtime(true) - $startTime) * 1000, 2);
            $message = "Live database snapshot successfully exported to external seed files ({$sqlFilePath}) in {$elapsed} ms!";
            $messageType = "success";
            $executionLog[] = "Wrote " . strlen($sql) . " bytes to " . basename($sqlFilePath);
            $executionLog[] = "Wrote " . strlen($jsonFormatted) . " bytes to " . basename($jsonFilePath);
        } catch (Throwable $e) {
            $message = "Export Failed: " . $e->getMessage();
            $messageType = "error";
            $executionLog[] = "Error: " . $e->getMessage();
        }
    }

    // 4. CUSTOM SQL EXECUTION
    elseif ($action === 'execute_custom_sql') {
        $customSql = trim($_POST['custom_sql'] ?? '');
        if (isset($_FILES['sql_file']) && $_FILES['sql_file']['error'] === UPLOAD_ERR_OK) {
            $customSql = file_get_contents($_FILES['sql_file']['tmp_name']);
        }

        if (empty($customSql)) {
            $message = "No SQL statement provided.";
            $messageType = "error";
        } else {
            $startTime = microtime(true);
            try {
                $pdo->beginTransaction();
                $pdo->exec($customSql);
                $pdo->commit();
                $elapsed = round((microtime(true) - $startTime) * 1000, 2);
                $message = "Custom SQL executed successfully in {$elapsed} ms!";
                $messageType = "success";
                $executionLog[] = "Executed custom script length: " . strlen($customSql) . " chars.";
            } catch (Throwable $e) {
                if ($pdo->inTransaction()) {
                    $pdo->rollBack();
                }
                $message = "SQL Error: " . $e->getMessage();
                $messageType = "error";
                $executionLog[] = "Error: " . $e->getMessage();
            }
        }
    }
}

// -----------------------------------------------------------------------------
// GATHER DATABASE & FILE STATS
// -----------------------------------------------------------------------------
$tables = [
    'users'        => ['label' => 'Users (Admin, Vendors, Riders, Clients)', 'icon' => 'users'],
    'restaurants'  => ['label' => 'Restaurants & Kitchens', 'icon' => 'store'],
    'categories'   => ['label' => 'Food & Daig Categories', 'icon' => 'layers'],
    'food_items'   => ['label' => 'Restaurant Menu Dishes', 'icon' => 'utensils'],
    'daig_items'   => ['label' => 'Shahi Daigs (12kg / 6kg)', 'icon' => 'soup'],
    'orders'       => ['label' => 'Orders (All Stages)', 'icon' => 'receipt'],
    'banners'      => ['label' => 'Promo Banners & Deals', 'icon' => 'sparkles'],
    'settings'     => ['label' => 'System & App Settings', 'icon' => 'settings'],
];

$stats = [];
foreach ($tables as $t => $meta) {
    try {
        $cnt = (int)$pdo->query("SELECT COUNT(*) FROM \"$t\"")->fetchColumn();
        $stats[$t] = array_merge($meta, ['count' => $cnt]);
    } catch (Throwable $e) {
        $stats[$t] = array_merge($meta, ['count' => 0, 'error' => $e->getMessage()]);
    }
}

$dbPath = __DIR__ . '/../data/foodcourt.sqlite';
$dbSize = file_exists($dbPath) ? round(filesize($dbPath) / 1024, 1) : 0;
$sqlFileExists = file_exists($sqlFilePath);
$sqlFileSize = $sqlFileExists ? round(filesize($sqlFilePath) / 1024, 1) : 0;
$sqlFileMTime = $sqlFileExists ? date('Y-m-d H:i:s', filemtime($sqlFilePath)) : 'N/A';
?>
<!DOCTYPE html>
<html lang="en" class="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Database Seeding & Dummy Data Import Manager — FoodCourt & Pakwan</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/lucide@latest"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800;900&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Plus Jakarta Sans', sans-serif; }
        code, pre { font-family: 'JetBrains Mono', monospace; }
        .glass-panel {
            background: rgba(18, 18, 22, 0.85);
            backdrop-filter: blur(16px);
            border: 1px solid rgba(255, 255, 255, 0.08);
        }
    </style>
</head>
<body class="bg-[#0A0A0C] text-zinc-100 min-h-screen antialiased flex flex-col selection:bg-amber-500 selection:text-black">

    <!-- Top Navigation Header -->
    <header class="border-b border-white/5 bg-[#121216]/90 sticky top-0 z-50 backdrop-blur-md">
        <div class="max-w-6xl mx-auto px-4 py-3 flex items-center justify-between">
            <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-xl bg-gradient-to-tr from-amber-500 to-orange-500 flex items-center justify-center shadow-lg shadow-amber-500/20">
                    <i data-lucide="database-zap" class="w-5 h-5 text-black"></i>
                </div>
                <div>
                    <h1 class="text-sm font-extrabold tracking-tight text-white flex items-center gap-2">
                        <span>Database Seeding Hub</span>
                        <span class="text-[10px] font-mono px-2 py-0.5 rounded-full bg-amber-500/10 text-amber-400 border border-amber-500/20 font-bold">/seeding</span>
                    </h1>
                    <p class="text-[11px] text-zinc-400">SQLite3 Dummy Data Importer & External Snapshot Sync</p>
                </div>
            </div>

            <div class="flex items-center gap-2 text-xs">
                <a href="../admin/" class="px-3 py-1.5 rounded-xl bg-zinc-900 hover:bg-zinc-800 text-zinc-300 font-semibold border border-white/5 transition-all flex items-center gap-1.5">
                    <i data-lucide="shield" class="w-3.5 h-3.5 text-amber-500"></i>
                    <span>Admin Panel</span>
                </a>
                <a href="../vendor/login.php" class="px-3 py-1.5 rounded-xl bg-zinc-900 hover:bg-zinc-800 text-zinc-300 font-semibold border border-white/5 transition-all flex items-center gap-1.5">
                    <i data-lucide="store" class="w-3.5 h-3.5 text-orange-500"></i>
                    <span>Vendor Portal</span>
                </a>
            </div>
        </div>
    </header>

    <!-- Main Container -->
    <main class="max-w-6xl mx-auto px-4 py-6 flex-1 w-full space-y-6">

        <!-- Notification Banner -->
        <?php if ($message): ?>
            <div class="p-4 rounded-2xl flex items-start gap-3 transition-all animate-fade-in <?= $messageType === 'success' ? 'bg-emerald-950/60 border border-emerald-500/40 text-emerald-200' : 'bg-rose-950/60 border border-rose-500/40 text-rose-200' ?>">
                <i data-lucide="<?= $messageType === 'success' ? 'check-circle-2' : 'alert-octagon' ?>" class="w-5 h-5 shrink-0 mt-0.5 <?= $messageType === 'success' ? 'text-emerald-400' : 'text-rose-400' ?>"></i>
                <div class="flex-1">
                    <h4 class="text-xs font-bold uppercase tracking-wider"><?= $messageType === 'success' ? 'Operation Completed' : 'Operation Failed' ?></h4>
                    <p class="text-xs mt-0.5 leading-relaxed"><?= htmlspecialchars($message) ?></p>
                    <?php if (!empty($executionLog)): ?>
                        <div class="mt-2.5 p-2.5 rounded-xl bg-black/40 border border-white/5 text-[11px] font-mono space-y-0.5 text-zinc-300">
                            <?php foreach ($executionLog as $line): ?>
                                <div>&gt; <?= htmlspecialchars($line) ?></div>
                            <?php endforeach; ?>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
        <?php endif; ?>

        <!-- Database Engine & External File Diagnostics Strip -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
            <div class="glass-panel p-4 rounded-2xl">
                <div class="flex items-center justify-between text-zinc-400 text-xs">
                    <span class="font-semibold uppercase tracking-wider text-[10px]">Database Engine</span>
                    <i data-lucide="cpu" class="w-4 h-4 text-amber-500"></i>
                </div>
                <div class="text-base font-bold text-white mt-1">SQLite 3 (WAL Mode)</div>
                <div class="text-[11px] text-zinc-400 mt-0.5 flex items-center gap-1.5">
                    <span class="w-1.5 h-1.5 rounded-full bg-emerald-500 inline-block"></span>
                    <span>Database size: <strong class="text-zinc-200 font-mono"><?= $dbSize ?> KB</strong></span>
                </div>
            </div>

            <div class="glass-panel p-4 rounded-2xl border-amber-500/20 bg-gradient-to-br from-amber-500/5 to-transparent">
                <div class="flex items-center justify-between text-zinc-400 text-xs">
                    <span class="font-semibold uppercase tracking-wider text-[10px] text-amber-400">External Seed File</span>
                    <i data-lucide="file-code" class="w-4 h-4 text-amber-400"></i>
                </div>
                <div class="text-base font-bold text-white mt-1 font-mono text-xs truncate" title="<?= htmlspecialchars($sqlFilePath) ?>">
                    <?= basename($sqlFilePath) ?>
                </div>
                <div class="text-[11px] text-zinc-400 mt-0.5">
                    <?php if ($sqlFileExists): ?>
                        <span class="text-emerald-400 font-semibold">✓ Ready (<?= $sqlFileSize ?> KB)</span> • <span class="font-mono text-[10px]"><?= $sqlFileMTime ?></span>
                    <?php else: ?>
                        <span class="text-rose-400 font-semibold">✗ Not Found</span>
                    <?php endif; ?>
                </div>
            </div>

            <div class="glass-panel p-4 rounded-2xl">
                <div class="flex items-center justify-between text-zinc-400 text-xs">
                    <span class="font-semibold uppercase tracking-wider text-[10px]">Architecture Rule</span>
                    <i data-lucide="info" class="w-4 h-4 text-orange-400"></i>
                </div>
                <div class="text-xs font-bold text-zinc-200 mt-1 leading-snug">
                    Externalized Dataset Architecture
                </div>
                <p class="text-[10.5px] text-zinc-400 mt-0.5 leading-tight">
                    Dummy seed data is stored in the external root directory (<code class="text-amber-400">seed_data.sql</code>) for easy external customization.
                </p>
            </div>
        </div>

        <!-- Live SQLite Table Record Counts -->
        <div class="glass-panel p-5 rounded-2xl">
            <div class="flex items-center justify-between mb-3.5">
                <div>
                    <h3 class="text-xs font-extrabold uppercase tracking-wider text-white flex items-center gap-2">
                        <i data-lucide="table-2" class="w-4 h-4 text-amber-400"></i>
                        <span>Live SQLite3 Record Counts</span>
                    </h3>
                    <p class="text-[11px] text-zinc-400">Current active records across all SQLite3 tables in <code class="text-zinc-300">foodcourt.sqlite</code></p>
                </div>
                <button type="button" onclick="location.reload()" class="p-1.5 rounded-lg bg-zinc-800 hover:bg-zinc-700 text-zinc-300 transition-colors" title="Refresh Record Counts">
                    <i data-lucide="refresh-cw" class="w-3.5 h-3.5"></i>
                </button>
            </div>

            <div class="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
                <?php foreach ($stats as $t => $info): ?>
                    <div class="p-3 rounded-xl bg-zinc-900/70 border border-white/5 flex flex-col justify-between">
                        <div class="flex items-center justify-between">
                            <span class="text-[10px] font-mono text-zinc-400 uppercase tracking-wider"><?= $t ?></span>
                            <i data-lucide="<?= $info['icon'] ?>" class="w-3.5 h-3.5 text-zinc-500"></i>
                        </div>
                        <div class="mt-2 flex items-baseline justify-between">
                            <span class="text-lg font-black font-mono text-white"><?= number_format($info['count']) ?></span>
                            <span class="text-[10px] text-zinc-500">rows</span>
                        </div>
                        <span class="text-[9.5px] text-zinc-400 mt-1 truncate" title="<?= $info['label'] ?>"><?= $info['label'] ?></span>
                    </div>
                <?php endforeach; ?>
            </div>
        </div>

        <!-- Seeding Action Cards Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">

            <!-- ACTION CARD 1: IMPORT FROM EXTERNAL SEED FILE (PRIMARY) -->
            <div class="glass-panel p-5 rounded-2xl border-amber-500/30 flex flex-col justify-between relative overflow-hidden">
                <div class="absolute -right-8 -top-8 w-32 h-32 bg-amber-500/10 rounded-full blur-2xl pointer-events-none"></div>
                <div>
                    <div class="flex items-center gap-2 text-amber-400 text-xs font-bold uppercase tracking-wider">
                        <span class="w-2 h-2 rounded-full bg-amber-400 animate-pulse"></span>
                        <span>Option 1 • Recommended</span>
                    </div>
                    <h3 class="text-base font-black text-white mt-1">Import External Dummy Dataset</h3>
                    <p class="text-xs text-zinc-400 mt-1 leading-relaxed">
                        Reads the entire external dataset from <code class="text-amber-400 font-semibold font-mono">seed_data.sql</code> located outside in the root folder and loads all tables, dishes, daigs, riders, and orders directly into SQLite3.
                    </p>

                    <div class="mt-3.5 p-3 rounded-xl bg-zinc-900/80 border border-white/5 text-xs space-y-1.5">
                        <div class="flex justify-between text-zinc-300">
                            <span class="text-zinc-400">Source File:</span>
                            <span class="font-mono font-bold text-amber-400"><?= basename($sqlFilePath) ?></span>
                        </div>
                        <div class="flex justify-between text-zinc-300">
                            <span class="text-zinc-400">File Size:</span>
                            <span class="font-mono"><?= $sqlFileSize ?> KB</span>
                        </div>
                        <div class="flex justify-between text-zinc-300">
                            <span class="text-zinc-400">Last Modified:</span>
                            <span class="font-mono text-[11px]"><?= $sqlFileMTime ?></span>
                        </div>
                    </div>
                </div>

                <form method="POST" class="mt-4" onsubmit="return confirm('Confirm: Import entire external seed_data.sql into SQLite3? Existing records with matching IDs will be refreshed.')">
                    <input type="hidden" name="action" value="import_external_sql">
                    <button type="submit" class="w-full py-2.5 px-4 rounded-xl bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-black font-extrabold text-xs flex items-center justify-center gap-2 shadow-lg shadow-amber-500/20 active:scale-[0.98] transition-all">
                        <i data-lucide="zap" class="w-4 h-4 fill-black"></i>
                        <span>Import External seed_data.sql to Database</span>
                    </button>
                </form>
            </div>

            <!-- ACTION CARD 2: BUILT-IN SEED ENGINE -->
            <div class="glass-panel p-5 rounded-2xl flex flex-col justify-between">
                <div>
                    <div class="text-zinc-400 text-xs font-bold uppercase tracking-wider">
                        <span>Option 2 • Code Engine</span>
                    </div>
                    <h3 class="text-base font-black text-white mt-1">Execute Built-in Seeder (PHP)</h3>
                    <p class="text-xs text-zinc-400 mt-1 leading-relaxed">
                        Executes the standard internal <code class="text-zinc-200 font-mono">seedInitialData()</code> function from <code class="text-zinc-200 font-mono">config/database.php</code>. Resets and populates standard demo records across all roles.
                    </p>

                    <div class="mt-3.5 p-3 rounded-xl bg-zinc-900/80 border border-white/5 text-xs space-y-1.5">
                        <div class="flex justify-between text-zinc-300">
                            <span class="text-zinc-400">Pakwan Centers:</span>
                            <span class="font-bold">4 Outlets</span>
                        </div>
                        <div class="flex justify-between text-zinc-300">
                            <span class="text-zinc-400">Dedicated Store Riders:</span>
                            <span class="font-bold">8 Active Captains</span>
                        </div>
                        <div class="flex justify-between text-zinc-300">
                            <span class="text-zinc-400">Lifecycle Orders:</span>
                            <span class="font-bold">10 Live Orders (Pending &rarr; Delivered)</span>
                        </div>
                    </div>
                </div>

                <form method="POST" class="mt-4" onsubmit="return confirm('Confirm: Reset and execute built-in PHP seeder?')">
                    <input type="hidden" name="action" value="seed_builtin">
                    <button type="submit" class="w-full py-2.5 px-4 rounded-xl bg-zinc-800 hover:bg-zinc-700 text-zinc-100 font-bold text-xs flex items-center justify-center gap-2 border border-white/10 active:scale-[0.98] transition-all">
                        <i data-lucide="refresh-cw" class="w-4 h-4 text-amber-400"></i>
                        <span>Execute Built-in PHP Seeder</span>
                    </button>
                </form>
            </div>

            <!-- ACTION CARD 3: SNAPSHOT / EXPORT LIVE DB TO EXTERNAL SEED FILES -->
            <div class="glass-panel p-5 rounded-2xl flex flex-col justify-between">
                <div>
                    <div class="text-zinc-400 text-xs font-bold uppercase tracking-wider">
                        <span>Utility • Sync Outside</span>
                    </div>
                    <h3 class="text-base font-black text-white mt-1">Snapshot Live DB to External Files</h3>
                    <p class="text-xs text-zinc-400 mt-1 leading-relaxed">
                        Exports the current SQLite3 database content back out into <code class="text-amber-400 font-mono">seed_data.sql</code> and <code class="text-amber-400 font-mono">seed_data.json</code> in the root folder so changes made in Admin/Vendor are preserved externally.
                    </p>
                </div>

                <form method="POST" class="mt-4" onsubmit="return confirm('Confirm: Overwrite external seed_data.sql and seed_data.json with current live database records?')">
                    <input type="hidden" name="action" value="export_to_external">
                    <button type="submit" class="w-full py-2.5 px-4 rounded-xl bg-zinc-800 hover:bg-zinc-700 text-zinc-200 font-bold text-xs flex items-center justify-center gap-2 border border-white/10 active:scale-[0.98] transition-all">
                        <i data-lucide="download" class="w-4 h-4 text-emerald-400"></i>
                        <span>Save Live Database to External seed_data.sql</span>
                    </button>
                </form>
            </div>

            <!-- ACTION CARD 4: CUSTOM SQL QUERY EXECUTION / UPLOAD -->
            <div class="glass-panel p-5 rounded-2xl flex flex-col justify-between" x-data="{ expanded: false }">
                <div>
                    <div class="text-zinc-400 text-xs font-bold uppercase tracking-wider">
                        <span>Custom SQL Query / File Upload</span>
                    </div>
                    <h3 class="text-base font-black text-white mt-1">Execute Custom SQL Script</h3>
                    <p class="text-xs text-zinc-400 mt-1 leading-relaxed">
                        Upload your own <code class="text-zinc-300 font-mono">.sql</code> file or write direct SQL queries to run directly inside SQLite3.
                    </p>
                </div>

                <form method="POST" enctype="multipart/form-data" class="mt-4 space-y-2.5">
                    <input type="hidden" name="action" value="execute_custom_sql">
                    <textarea name="custom_sql" rows="3" placeholder="-- Enter SQL statements here (e.g. UPDATE settings SET ...)" class="w-full p-2.5 rounded-xl bg-black/50 border border-white/10 text-xs font-mono text-zinc-200 focus:outline-none focus:border-amber-500/50 resize-y"></textarea>
                    
                    <div class="flex items-center gap-2">
                        <input type="file" name="sql_file" accept=".sql" class="block w-full text-[11px] text-zinc-400 file:mr-2 file:py-1 file:px-2.5 file:rounded-lg file:border-0 file:text-[11px] file:font-semibold file:bg-zinc-800 file:text-zinc-200 hover:file:bg-zinc-700">
                        <button type="submit" class="py-1.5 px-4 rounded-xl bg-amber-500 hover:bg-amber-400 text-black font-bold text-xs shrink-0 flex items-center gap-1.5 transition-all">
                            <i data-lucide="play" class="w-3.5 h-3.5 fill-black"></i>
                            <span>Execute</span>
                        </button>
                    </div>
                </form>
            </div>

        </div>

        <!-- Demo Credentials Reference Table -->
        <div class="glass-panel p-5 rounded-2xl">
            <h3 class="text-xs font-extrabold uppercase tracking-wider text-white flex items-center gap-2 mb-3">
                <i data-lucide="key-round" class="w-4 h-4 text-amber-400"></i>
                <span>Standard Test Credentials Directory (Password: <code class="text-amber-400 font-mono">123456</code>)</span>
            </h3>

            <div class="overflow-x-auto">
                <table class="w-full text-left text-xs">
                    <thead>
                        <tr class="border-b border-white/5 text-[10px] uppercase font-bold text-zinc-400 font-mono">
                            <th class="pb-2">Role</th>
                            <th class="pb-2">Name / Business</th>
                            <th class="pb-2">Email</th>
                            <th class="pb-2">Portal URL</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-white/5 text-zinc-300">
                        <tr>
                            <td class="py-2"><span class="px-2 py-0.5 rounded-md bg-purple-500/10 text-purple-400 font-bold text-[10px]">Super Admin</span></td>
                            <td class="py-2 font-semibold text-white">Super Administrator (FoodCourt HQ)</td>
                            <td class="py-2 font-mono text-zinc-300">super@foodcourt.pk</td>
                            <td class="py-2"><a href="../admin/" class="text-amber-400 hover:underline">/admin</a></td>
                        </tr>
                        <tr>
                            <td class="py-2"><span class="px-2 py-0.5 rounded-md bg-amber-500/10 text-amber-400 font-bold text-[10px]">Vendor (Rest)</span></td>
                            <td class="py-2 font-semibold text-white">Bannu Beef Pulao & Nalli Nihari</td>
                            <td class="py-2 font-mono text-zinc-300">bannu.admin@foodcourt.pk</td>
                            <td class="py-2"><a href="../vendor/login.php" class="text-amber-400 hover:underline">/vendor</a></td>
                        </tr>
                        <tr>
                            <td class="py-2"><span class="px-2 py-0.5 rounded-md bg-orange-500/10 text-orange-400 font-bold text-[10px]">Vendor (Pakwan)</span></td>
                            <td class="py-2 font-semibold text-white">Shahi Pakwan Center</td>
                            <td class="py-2 font-mono text-zinc-300">shahi.pakwan@foodcourt.pk</td>
                            <td class="py-2"><a href="../vendor/login.php" class="text-amber-400 hover:underline">/vendor</a></td>
                        </tr>
                        <tr>
                            <td class="py-2"><span class="px-2 py-0.5 rounded-md bg-blue-500/10 text-blue-400 font-bold text-[10px]">Rider</span></td>
                            <td class="py-2 font-semibold text-white">Captain Bilal Khan (Bannu Pulao)</td>
                            <td class="py-2 font-mono text-zinc-300">rider.bannu@foodcourt.pk</td>
                            <td class="py-2 text-zinc-500">Mobile App</td>
                        </tr>
                        <tr>
                            <td class="py-2"><span class="px-2 py-0.5 rounded-md bg-emerald-500/10 text-emerald-400 font-bold text-[10px]">Customer</span></td>
                            <td class="py-2 font-semibold text-white">Hassan Raza (DHA Lahore)</td>
                            <td class="py-2 font-mono text-zinc-300">client@foodcourt.pk</td>
                            <td class="py-2 text-zinc-500">Mobile App</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

    </main>

    <!-- Footer -->
    <footer class="border-t border-white/5 py-4 text-center text-xs text-zinc-500">
        FoodCourt & Shahi Pakwan — Standalone Database Seeding & Dummy Data Import Module • Route: <code class="text-amber-500">/seeding</code>
    </footer>

    <script>
        lucide.createIcons();
    </script>
</body>
</html>
