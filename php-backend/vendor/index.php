<?php
// php-backend/vendor/index.php
// Vendor & Pakwan Center Manager Portal — Cupertino iOS Style (Minimal Gaps, High Density, Orange Theme)
session_start();

require_once __DIR__ . '/../config/database.php';
$pdo = getDb();

// Super Admin Direct Login / Impersonation Support
if (!empty($_GET['impersonate']) && isset($_SESSION['super_admin'])) {
    $targetId = trim($_GET['impersonate']);
    $stmtTarget = $pdo->prepare("SELECT * FROM users WHERE id = ? LIMIT 1");
    $stmtTarget->execute([$targetId]);
    $vendorTarget = $stmtTarget->fetch();
    if ($vendorTarget) {
        $_SESSION['admin_user'] = $vendorTarget;
        $_SESSION['impersonated_by_admin'] = true;
    }
}

if (!isset($_SESSION['admin_user'])) {
    header('Location: /vendor/login.php');
    exit;
}

// Live ban check from database on every visit
$stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$_SESSION['admin_user']['id']]);
$liveUser = $stmt->fetch();

if (!$liveUser || !empty($liveUser['banned']) || ($liveUser['status'] ?? '') === 'banned') {
    unset($_SESSION['admin_user']);
    header('Location: /vendor/login.php?banned=1');
    exit;
}

// Keep session updated with fresh database values
$_SESSION['admin_user'] = array_merge($_SESSION['admin_user'], $liveUser);
$adminUser = $_SESSION['admin_user'];
?>
<!DOCTYPE html>
<html lang="en" class="h-full bg-[#09090b] text-zinc-100 dark" style="color-scheme: dark;">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="theme-color" content="#09090b">
    <title><?= htmlspecialchars($adminUser['businessName'] ?: 'Vendor Portal') ?> — Food Court Partner</title>
    
    <!-- Tailwind CSS CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        apple: {
                            orange: '#FF9500',
                            orangeDark: '#EA580C',
                            bg: '#09090b',
                            card: '#18181b',
                            border: 'rgba(255, 255, 255, 0.08)'
                        }
                    }
                }
            }
        }
    </script>
    
    <!-- Leaflet CSS & JS for Interactive Kitchen GPS Map Picker -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>

    <!-- Chart.js for High-Precision Performance Charts -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

    <!-- Alpine.js CDN -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.14.8/dist/cdn.min.js"></script>

    <!-- Lucide Icons CDN -->
    <script src="https://unpkg.com/lucide@latest"></script>

    <style>
        [x-cloak] { display: none !important; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Helvetica Neue", sans-serif;
            -webkit-font-smoothing: antialiased;
            letter-spacing: -0.011em;
        }
        .cupertino-glass {
            background: rgba(24, 24, 27, 0.85);
            backdrop-filter: blur(28px) saturate(190%);
            -webkit-backdrop-filter: blur(28px) saturate(190%);
            border: 1px solid rgba(255, 255, 255, 0.08);
        }
        .cupertino-card {
            background: rgba(24, 24, 27, 0.65);
            border: 1px solid rgba(255, 255, 255, 0.07);
        }
        .cupertino-inset {
            background: rgba(18, 18, 20, 0.9);
            border: 1px solid rgba(255, 255, 255, 0.05);
        }
        ::-webkit-scrollbar { width: 5px; height: 5px; }
        ::-webkit-scrollbar-track { background: #09090b; }
        ::-webkit-scrollbar-thumb { background: #27272a; border-radius: 9999px; }
        ::-webkit-scrollbar-thumb:hover { background: #3f3f46; }

        /* Universal Custom Dropdown Styling (Zero Cut-Off, Custom Orange Chevron, Dark Themed) */
        select, .custom-select {
            appearance: none !important;
            -webkit-appearance: none !important;
            -moz-appearance: none !important;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='14' height='14' viewBox='0 0 24 24' fill='none' stroke='%23FF9500' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='m6 9 6 6 6-6'/%3E%3C/svg%3E") !important;
            background-repeat: no-repeat !important;
            background-position: right 10px center !important;
            background-size: 13px 13px !important;
            padding-right: 28px !important;
            cursor: pointer !important;
            background-color: #18181b !important;
            color: #f4f4f5 !important;
            border: 1px solid rgba(255, 255, 255, 0.12) !important;
            outline: none !important;
            box-sizing: border-box !important;
            transition: all 0.2s ease !important;
        }
        select:hover, .custom-select:hover {
            border-color: rgba(255, 149, 0, 0.5) !important;
        }
        select:focus, .custom-select:focus {
            border-color: #FF9500 !important;
            box-shadow: 0 0 0 1px #FF9500 !important;
        }
        select option {
            background-color: #18181b !important;
            color: #f4f4f5 !important;
            padding: 8px 12px !important;
            font-size: 12px !important;
        }
        select option:checked {
            background-color: #ea580c !important;
            color: #ffffff !important;
        }
    </style>
</head>
<body class="h-full flex flex-col overflow-hidden font-sans antialiased bg-[#09090b] text-zinc-100" x-data="vendorApp()" x-init="initApp()" x-cloak>

    <?php if (!empty($_SESSION['impersonated_by_admin'])): ?>
    <div class="bg-gradient-to-r from-purple-950 via-indigo-950 to-purple-950 border-b border-purple-500/40 text-white px-4 py-1.5 text-xs flex items-center justify-between shrink-0 shadow-md">
        <div class="flex items-center gap-2">
            <span class="px-2 py-0.5 rounded-full bg-purple-500 text-white font-extrabold text-[10px]">👑 SUPER ADMIN ACCESS</span>
            <span class="text-zinc-200">Logged in as outlet: <strong class="text-white"><?= htmlspecialchars($adminUser['businessName'] ?: $adminUser['name']) ?></strong></span>
        </div>
        <a href="../admin/" class="px-2.5 py-0.5 rounded-lg bg-purple-500/30 hover:bg-purple-500/50 text-purple-200 hover:text-white font-bold text-[11px] border border-purple-400/30 transition-colors flex items-center gap-1">
            <span>← Return to Super Admin</span>
        </a>
    </div>
    <?php endif; ?>

    <div class="flex-1 flex overflow-hidden">

    <!-- Toast Notification (Cupertino Capsule) -->
    <aside x-show="toast.visible" x-transition.opacity.duration.250ms
        class="fixed bottom-4 right-4 z-50 flex items-center gap-2 px-3.5 py-2 rounded-2xl shadow-xl text-xs font-semibold border backdrop-blur-2xl"
        :class="toast.type === 'error' ? 'bg-red-950/90 border-red-500/40 text-red-200' : 'bg-zinc-900/90 border-orange-500/40 text-orange-200'"
        role="status" aria-live="polite">
        <i :data-lucide="toast.type === 'error' ? 'alert-triangle' : 'check-circle-2'" class="w-4 h-4 text-[#FF9500]" aria-hidden="true"></i>
        <span x-text="toast.message"></span>
    </aside>

    <!-- ======================================================================= -->
    <!-- LISTTILE CUPERTINO SIDEBAR (WITHOUT ROUNDED BORDER, TALLER HEIGHT) -->
    <!-- ======================================================================= -->
    <aside class="w-60 bg-zinc-950/90 backdrop-blur-2xl border-r border-white/5 flex flex-col shrink-0 select-none">
        
        <!-- Store Brand Header -->
        <div class="h-14 flex items-center gap-2.5 px-4 border-b border-white/5 shrink-0">
            <div class="w-8 h-8 rounded-xl bg-orange-500/15 border border-orange-500/30 text-[#FF9500] flex items-center justify-center font-bold shadow-sm shrink-0">
                <i :data-lucide="subAdmin.businessType === 'pakwan' ? 'soup' : (subAdmin.businessType === 'both' ? 'crown' : 'utensils')" class="w-4 h-4" aria-hidden="true"></i>
            </div>
            <div class="min-w-0 flex-1">
                <h1 class="text-xs font-bold text-white tracking-tight truncate" x-text="subAdmin.businessName || 'My Pakwan Center'"></h1>
                <div class="flex items-center gap-1 mt-0.5">
                    <span class="w-1.5 h-1.5 rounded-full" :class="storeAvailability === 'open' ? 'bg-emerald-400 animate-pulse' : (storeAvailability === 'busy' ? 'bg-amber-400' : 'bg-red-400')"></span>
                    <span class="text-[9px] font-bold uppercase tracking-wider text-orange-400" x-text="getBusinessTypeLabel(subAdmin.businessType)"></span>
                </div>
            </div>
        </div>

        <!-- Navigation Links (5px Rounded, 2px Less Top/Bottom, 30% Opacity Background) -->
        <nav class="flex-1 px-2 py-2 space-y-1 overflow-y-auto" aria-label="Vendor Store Navigation">
            <template x-for="tab in tabs" :key="tab.id">
                <button type="button" @click="setTab(tab.id)"
                    class="w-full flex items-center gap-3 px-3.5 py-2.5 min-h-[40px] text-[12.5px] font-semibold transition-all text-left rounded-[5px] select-none group border"
                    :class="activeTab === tab.id 
                        ? 'bg-orange-500/30 text-white font-bold border-orange-500/40 shadow-sm' 
                        : 'text-zinc-400 hover:text-white hover:bg-white/[0.05] border-transparent'">
                    <i :data-lucide="tab.icon" class="w-4 h-4 shrink-0 transition-colors"
                        :class="activeTab === tab.id ? 'text-[#FF9500] stroke-[2.2]' : 'text-zinc-400 group-hover:text-zinc-200'" aria-hidden="true"></i>
                    <span x-text="tab.label" class="flex-1 truncate tracking-tight"></span>
                    
                    <!-- Tab Badges -->
                    <span x-show="tab.id === 'orders' && activeOrdersCount > 0"
                        class="px-2 py-0.5 rounded-[4px] text-[10px] font-bold tabular-nums"
                        :class="activeTab === tab.id ? 'bg-orange-500/40 text-white' : 'bg-orange-500/20 text-[#FF9500]'"
                        x-text="activeOrdersCount">
                    </span>
                    <span x-show="tab.id === 'riders' && outletRiders.length > 0"
                        class="px-1.5 py-0.5 rounded-[4px] text-[10px] tabular-nums font-mono opacity-80"
                        :class="activeTab === tab.id ? 'bg-white/20 text-white' : 'bg-zinc-800 text-zinc-300'"
                        x-text="outletRiders.length">
                    </span>
                    <span x-show="tab.id === 'customers' && vendorCustomers.length > 0"
                        class="px-1.5 py-0.5 rounded-[4px] text-[10px] tabular-nums font-mono opacity-80"
                        :class="activeTab === tab.id ? 'bg-white/20 text-white' : 'bg-zinc-800 text-zinc-300'"
                        x-text="vendorCustomers.length">
                    </span>
                    <span x-show="tab.id === 'food-listing' && totalMenuCount > 0"
                        class="px-1.5 py-0.5 rounded-[4px] text-[10px] tabular-nums font-mono opacity-80"
                        :class="activeTab === tab.id ? 'bg-white/20 text-white' : 'bg-zinc-800 text-zinc-300'"
                        x-text="totalMenuCount">
                    </span>

                    <i data-lucide="chevron-right" class="w-3.5 h-3.5 shrink-0 transition-transform"
                        :class="activeTab === tab.id ? 'text-[#FF9500] opacity-90 translate-x-0.5' : 'text-zinc-600 opacity-30 group-hover:opacity-70'" aria-hidden="true"></i>
                </button>
            </template>
        </nav>

        <!-- Sub-Admin Footer Profile -->
        <div class="border-t border-white/5 bg-zinc-950/60 p-2 shrink-0">
            <div class="flex items-center justify-between px-2.5 py-1 mb-1.5 bg-zinc-900/40 rounded-[5px] border border-white/5">
                <span class="text-[9.5px] uppercase font-bold tracking-wider text-zinc-500">Store Status:</span>
                <span class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded-full text-[9px] font-bold bg-orange-500/15 text-[#FF9500] border border-orange-500/30">
                    <span class="w-1 h-1 rounded-full bg-[#FF9500]"></span>
                    <span x-text="storeAvailability === 'open' ? 'Active 🟢' : (storeAvailability === 'busy' ? 'Busy 🟡' : 'Closed 🔴')"></span>
                </span>
            </div>
            <div @click="setTab('profile')"
                class="w-full px-3 py-2 min-h-[44px] hover:bg-zinc-800/80 cursor-pointer flex items-center justify-between transition-all rounded-[5px] border select-none"
                :class="activeTab === 'profile' ? 'bg-orange-500/30 border-orange-500/40 text-white' : 'border-transparent bg-zinc-900/60'"
                title="View & Edit Store Profile">
                <div class="flex items-center gap-2.5 min-w-0">
                    <div class="w-7 h-7 rounded-[5px] bg-zinc-800 border border-white/10 flex items-center justify-center text-[11px] font-bold text-[#FF9500] shrink-0">
                        <?= strtoupper(substr($adminUser['name'] ?: 'V', 0, 1)) ?>
                    </div>
                    <div class="min-w-0">
                        <p class="text-[11.5px] font-bold text-white truncate" x-text="profileForm.name || '<?= htmlspecialchars($adminUser['name'] ?: 'Manager') ?>'"></p>
                        <p class="text-[10px] text-zinc-500 font-mono truncate"><?= htmlspecialchars($adminUser['email']) ?></p>
                    </div>
                </div>
                <a href="logout.php" @click.stop title="Sign Out from Store Portal" class="text-zinc-500 hover:text-red-400 transition-colors p-1.5 rounded-lg">
                    <i data-lucide="log-out" class="w-4 h-4"></i>
                </a>
            </div>
        </div>
    </aside>

    <!-- ======================================================================= -->
    <!-- MAIN CONTENT VIEWPORT -->
    <!-- ======================================================================= -->
    <div class="flex-1 flex flex-col min-w-0 overflow-hidden bg-[#09090b]">

        <!-- Top Header Navigation Bar (Cupertino Minimalist) -->
        <header class="h-12 bg-zinc-950/80 backdrop-blur-2xl border-b border-white/5 px-3.5 flex items-center justify-between shrink-0">
            
            <!-- Left Breadcrumb & Current Tab -->
            <div class="flex items-center gap-2 min-w-0">
                <span class="text-xs font-black text-white flex items-center gap-1.5">
                    <span class="text-zinc-500 font-normal">Vendor Portal /</span>
                    <span class="text-[#FF9500]" x-text="currentTabLabel()"></span>
                </span>
                <span class="hidden sm:inline-flex px-1.5 py-0.2 rounded text-[9.5px] font-bold bg-zinc-800 text-zinc-400 border border-white/5"
                    x-text="subAdmin.businessType === 'pakwan' ? '👑 Shahi Pakwan' : (subAdmin.businessType === 'both' ? '👑🍽️ Hybrid' : '🍽️ Restaurant')">
                </span>
            </div>

            <!-- Right Action Pill Buttons -->
            <div class="flex items-center gap-1.5">
                
                <!-- Store Availability Custom Dropdown (Zero Clipping) -->
                <div class="relative" x-data="{ openAvailability: false }">
                    <button type="button" @click="openAvailability = !openAvailability; $nextTick(() => lucide.createIcons())"
                        class="flex items-center gap-2 bg-zinc-900 hover:bg-zinc-800 border border-white/10 hover:border-orange-500/30 px-3 py-1 rounded-xl text-xs font-semibold text-zinc-200 transition-all shadow-sm">
                        <span class="w-2 h-2 rounded-full shrink-0" :class="storeAvailability === 'open' ? 'bg-emerald-400 animate-pulse' : (storeAvailability === 'busy' ? 'bg-amber-400' : 'bg-red-400')"></span>
                        <span x-text="storeAvailability === 'open' ? 'Open 🟢' : (storeAvailability === 'busy' ? 'Kitchen Busy 🟡' : 'Closed 🔴')"></span>
                        <i data-lucide="chevron-down" class="w-3.5 h-3.5 text-zinc-400 transition-transform" :class="openAvailability ? 'rotate-180 text-[#FF9500]' : ''"></i>
                    </button>
                    <!-- Custom Floating Dropdown Menu -->
                    <div x-show="openAvailability" @click.outside="openAvailability = false" x-cloak
                        class="absolute right-0 mt-1.5 w-44 cupertino-glass rounded-xl p-1.5 shadow-2xl border border-white/10 z-50 space-y-0.5 text-xs">
                        <button type="button" @click="storeAvailability = 'open'; openAvailability = false; $nextTick(() => lucide.createIcons())"
                            class="w-full flex items-center justify-between px-2.5 py-1.5 rounded-lg text-left transition-colors hover:bg-emerald-500/15"
                            :class="storeAvailability === 'open' ? 'text-emerald-400 font-bold bg-emerald-500/10' : 'text-zinc-300'">
                            <span class="flex items-center gap-2">
                                <span class="w-2 h-2 rounded-full bg-emerald-400"></span>
                                <span>Open 🟢</span>
                            </span>
                            <i data-lucide="check" class="w-3.5 h-3.5 text-emerald-400" x-show="storeAvailability === 'open'"></i>
                        </button>
                        <button type="button" @click="storeAvailability = 'busy'; openAvailability = false; $nextTick(() => lucide.createIcons())"
                            class="w-full flex items-center justify-between px-2.5 py-1.5 rounded-lg text-left transition-colors hover:bg-amber-500/15"
                            :class="storeAvailability === 'busy' ? 'text-amber-400 font-bold bg-amber-500/10' : 'text-zinc-300'">
                            <span class="flex items-center gap-2">
                                <span class="w-2 h-2 rounded-full bg-amber-400"></span>
                                <span>Kitchen Busy 🟡</span>
                            </span>
                            <i data-lucide="check" class="w-3.5 h-3.5 text-amber-400" x-show="storeAvailability === 'busy'"></i>
                        </button>
                        <button type="button" @click="storeAvailability = 'closed'; openAvailability = false; $nextTick(() => lucide.createIcons())"
                            class="w-full flex items-center justify-between px-2.5 py-1.5 rounded-lg text-left transition-colors hover:bg-red-500/15"
                            :class="storeAvailability === 'closed' ? 'text-red-400 font-bold bg-red-500/10' : 'text-zinc-300'">
                            <span class="flex items-center gap-2">
                                <span class="w-2 h-2 rounded-full bg-red-400"></span>
                                <span>Closed 🔴</span>
                            </span>
                            <i data-lucide="check" class="w-3.5 h-3.5 text-red-400" x-show="storeAvailability === 'closed'"></i>
                        </button>
                    </div>
                </div>

                <!-- Order Alert Ringtone Bell Button -->
                <button type="button" @click="testOrderRingtone()"
                    class="px-2.5 py-1.5 bg-orange-500/10 hover:bg-orange-500/20 text-[#FF9500] rounded-xl border border-orange-500/30 transition-all text-xs font-bold inline-flex items-center gap-1.5"
                    :class="ringtoneActive ? 'bg-red-500/20 border-red-500 text-red-400 animate-pulse' : ''"
                    title="Order Alert Ringtone (Test Bell)">
                    <i data-lucide="bell" class="w-3.5 h-3.5" :class="ringtoneActive ? 'animate-bounce text-red-400' : ''"></i>
                    <span class="text-[11px] font-bold hidden sm:inline" x-text="ringtoneActive ? 'Ringing 🔔' : 'Alert Bell'"></span>
                </button>
            </div>
        </header>

        <!-- Pulsing Sticky Order Ringtone Alert Bar -->
        <div x-show="ringtoneActive" x-cloak
            class="bg-gradient-to-r from-red-600 via-rose-600 to-orange-600 text-white px-4 py-2.5 flex items-center justify-between shadow-xl sticky top-0 z-50 border-b border-red-400/30 animate-pulse">
            <div class="flex items-center gap-2.5">
                <span class="p-1.5 bg-white/20 rounded-lg animate-bounce">
                    <i data-lucide="bell-ring" class="w-4 h-4 text-yellow-300"></i>
                </span>
                <div>
                    <p class="font-extrabold text-xs sm:text-sm tracking-wide">🔔 NAYA CUSTOMER ORDER AAYA HAI! (ORDER RINGING)</p>
                    <p class="text-[10px] text-red-100 hidden sm:block" x-text="alertOrder ? ('Order #' + alertOrder.id + ' • ' + (alertOrder.customerName || 'Customer') + ' • Rs. ' + Math.round(alertOrder.totalAmount)) : 'Kitchen incoming order awaiting response'"></p>
                </div>
            </div>
            <div class="flex items-center gap-2">
                <button type="button" @click="stopOrderAlertRingtone()"
                    class="px-2.5 py-1 bg-white/20 hover:bg-white/30 text-white text-xs font-bold rounded-lg transition-all border border-white/30">
                    Mute Bell 🔕
                </button>
                <button type="button" @click="stopOrderAlertRingtone(); if(alertOrder) openOrderDetailModal(alertOrder); else activeTab = 'analytics';"
                    class="px-3 py-1 bg-white text-red-700 hover:bg-red-50 text-xs font-black rounded-lg shadow-md transition-all">
                    Acknowledge &amp; View 👀
                </button>
            </div>
        </div>

        <!-- Main Viewport Scrollable -->
        <main class="flex-1 overflow-y-auto p-3 sm:p-4 space-y-3.5">

            <!-- =============================================================== -->
            <!-- TAB 1: ANALYTICS (VENDOR OVERVIEW & PERFORMANCE CHARTS)         -->
            <!-- =============================================================== -->
            <section x-show="activeTab === 'analytics'" class="space-y-3.5">
                
                <!-- 7 Specific KPI Cards Requested by User -->
                <!-- [Total Sales, Total Items, Total Customers, Total Riders, Success Orders, Pending Orders, Reject Orders] -->
                <div class="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-7 gap-2.5">
                    
                    <!-- 1. Total Sales -->
                    <div class="p-3.5 rounded-2xl cupertino-card border border-white/5 flex flex-col justify-between hover:border-orange-500/40 transition-all shadow-sm group">
                        <div class="flex items-center justify-between mb-2">
                            <span class="text-[10px] uppercase font-bold text-zinc-400 tracking-wider">Total Sales</span>
                            <div class="w-7 h-7 rounded-lg bg-orange-500/15 text-[#FF9500] flex items-center justify-center text-xs group-hover:scale-110 transition-transform">
                                💰
                            </div>
                        </div>
                        <div>
                            <h3 class="text-base sm:text-lg font-black text-[#FF9500] tabular-nums truncate" x-text="'Rs. ' + Number(vendorStats.grossSales || 0).toLocaleString()"></h3>
                            <p class="text-[9.5px] text-zinc-400 mt-0.5">Lifetime Revenue</p>
                        </div>
                    </div>

                    <!-- 2. Total Items -->
                    <div class="p-3.5 rounded-2xl cupertino-card border border-white/5 flex flex-col justify-between hover:border-amber-500/40 transition-all shadow-sm group">
                        <div class="flex items-center justify-between mb-2">
                            <span class="text-[10px] uppercase font-bold text-zinc-400 tracking-wider">Total Items</span>
                            <div class="w-7 h-7 rounded-lg bg-amber-500/15 text-amber-400 flex items-center justify-center text-xs group-hover:scale-110 transition-transform">
                                🍽️
                            </div>
                        </div>
                        <div>
                            <h3 class="text-base sm:text-lg font-black text-amber-300 tabular-nums" x-text="vendorFoodItems.length + vendorDaigItems.length"></h3>
                            <p class="text-[9.5px] text-zinc-400 mt-0.5">
                                <span x-text="vendorFoodItems.length + ' Food'"></span> &bull; 
                                <span x-text="vendorDaigItems.length + ' Daigs'"></span>
                            </p>
                        </div>
                    </div>

                    <!-- 3. Total Customers -->
                    <div class="p-3.5 rounded-2xl cupertino-card border border-white/5 flex flex-col justify-between hover:border-purple-500/40 transition-all shadow-sm group">
                        <div class="flex items-center justify-between mb-2">
                            <span class="text-[10px] uppercase font-bold text-zinc-400 tracking-wider">Total Customers</span>
                            <div class="w-7 h-7 rounded-lg bg-purple-500/15 text-purple-400 flex items-center justify-center text-xs group-hover:scale-110 transition-transform">
                                👥
                            </div>
                        </div>
                        <div>
                            <h3 class="text-base sm:text-lg font-black text-purple-300 tabular-nums" x-text="vendorCustomers.length || vendorStats.totalCustomers || 0"></h3>
                            <p class="text-[9.5px] text-zinc-400 mt-0.5">Registered Clients</p>
                        </div>
                    </div>

                    <!-- 4. Total Riders -->
                    <div class="p-3.5 rounded-2xl cupertino-card border border-white/5 flex flex-col justify-between hover:border-sky-500/40 transition-all shadow-sm group">
                        <div class="flex items-center justify-between mb-2">
                            <span class="text-[10px] uppercase font-bold text-zinc-400 tracking-wider">Total Riders</span>
                            <div class="w-7 h-7 rounded-lg bg-sky-500/15 text-sky-400 flex items-center justify-center text-xs group-hover:scale-110 transition-transform">
                                🛵
                            </div>
                        </div>
                        <div>
                            <h3 class="text-base sm:text-lg font-black text-sky-300 tabular-nums" x-text="outletRiders.length"></h3>
                            <p class="text-[9.5px] text-zinc-400 mt-0.5">Dedicated Fleet</p>
                        </div>
                    </div>

                    <!-- 5. Success Orders -->
                    <div class="p-3.5 rounded-2xl cupertino-card border border-white/5 flex flex-col justify-between hover:border-emerald-500/40 transition-all shadow-sm group">
                        <div class="flex items-center justify-between mb-2">
                            <span class="text-[10px] uppercase font-bold text-emerald-400 tracking-wider">Success Orders</span>
                            <div class="w-7 h-7 rounded-lg bg-emerald-500/15 text-emerald-400 flex items-center justify-center text-xs group-hover:scale-110 transition-transform">
                                ✅
                            </div>
                        </div>
                        <div>
                            <h3 class="text-base sm:text-lg font-black text-emerald-400 tabular-nums" x-text="getStatusCount('Delivered') || vendorStats.completedOrders || 0"></h3>
                            <p class="text-[9.5px] text-emerald-400/80 mt-0.5">Delivered &amp; Paid</p>
                        </div>
                    </div>

                    <!-- 6. Pending Orders -->
                    <div class="p-3.5 rounded-2xl cupertino-card border border-white/5 flex flex-col justify-between hover:border-yellow-500/40 transition-all shadow-sm group">
                        <div class="flex items-center justify-between mb-2">
                            <span class="text-[10px] uppercase font-bold text-yellow-400 tracking-wider">Pending Orders</span>
                            <div class="w-7 h-7 rounded-lg bg-yellow-500/15 text-yellow-400 flex items-center justify-center text-xs group-hover:scale-110 transition-transform">
                                ⏳
                            </div>
                        </div>
                        <div>
                            <h3 class="text-base sm:text-lg font-black text-yellow-400 tabular-nums" x-text="getStatusCount('Accepted') + getStatusCount('Preparing') + getStatusCount('On the Way') + getStatusCount('Arrived')"></h3>
                            <p class="text-[9.5px] text-yellow-400/80 mt-0.5">In Kitchen / En-Route</p>
                        </div>
                    </div>

                    <!-- 7. Reject Orders -->
                    <div class="p-3.5 rounded-2xl cupertino-card border border-white/5 flex flex-col justify-between hover:border-red-500/40 transition-all shadow-sm group">
                        <div class="flex items-center justify-between mb-2">
                            <span class="text-[10px] uppercase font-bold text-red-400 tracking-wider">Reject Orders</span>
                            <div class="w-7 h-7 rounded-lg bg-red-500/15 text-red-400 flex items-center justify-center text-xs group-hover:scale-110 transition-transform">
                                ❌
                            </div>
                        </div>
                        <div>
                            <h3 class="text-base sm:text-lg font-black text-red-400 tabular-nums" x-text="getStatusCount('Cancelled') || vendorStats.cancelledOrders || 0"></h3>
                            <p class="text-[9.5px] text-red-400/80 mt-0.5">Cancelled / Rejected</p>
                        </div>
                    </div>

                </div>

                <!-- 2 High-Precision Analytics Charts Under The Cards -->
                <div class="grid grid-cols-1 lg:grid-cols-12 gap-3.5">
                    
                    <!-- Chart 1: Multi-Line Chart (Sales, Items, Success & Reject Orders) (7 cols) -->
                    <div class="lg:col-span-7 p-4 rounded-2xl cupertino-card border border-white/5 space-y-3">
                        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-2.5 border-b border-white/5">
                            <div>
                                <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                    <i data-lucide="trending-up" class="w-4 h-4 text-[#FF9500]"></i>
                                    <span>Sales, Orders &amp; Menu Items Trends</span>
                                </h4>
                                <p class="text-[10.5px] text-zinc-400">Sales volume (Rs. in thousands), Food &amp; Daig items, and Delivered vs Rejected orders</p>
                            </div>
                            <div class="flex flex-wrap items-center gap-2 text-[10px] font-semibold text-zinc-400">
                                <span class="inline-flex items-center gap-1"><span class="w-2.5 h-2.5 rounded-full bg-[#FF9500]"></span> Sales (k)</span>
                                <span class="inline-flex items-center gap-1"><span class="w-2.5 h-2.5 rounded-full bg-emerald-400"></span> Success</span>
                                <span class="inline-flex items-center gap-1"><span class="w-2.5 h-2.5 rounded-full bg-red-400"></span> Rejected</span>
                                <span class="inline-flex items-center gap-1"><span class="w-2.5 h-2.5 rounded-full bg-amber-300"></span> Items</span>
                            </div>
                        </div>
                        <div class="relative w-full h-80">
                            <canvas id="vendorPerformanceLineChart"></canvas>
                        </div>
                    </div>

                    <!-- Chart 2: Grouped Bar Chart (Customers vs Delivery Fleet Riders) (5 cols) -->
                    <div class="lg:col-span-5 p-4 rounded-2xl cupertino-card border border-white/5 space-y-3">
                        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-2.5 border-b border-white/5">
                            <div>
                                <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                    <i data-lucide="bar-chart-3" class="w-4 h-4 text-purple-400"></i>
                                    <span>Store Customers &amp; Dedicated Fleet Riders</span>
                                </h4>
                                <p class="text-[10.5px] text-zinc-400">Active customer accounts vs assigned delivery fleet</p>
                            </div>
                            <div class="flex items-center gap-2 text-[10px] font-semibold text-zinc-400">
                                <span class="inline-flex items-center gap-1"><span class="w-2.5 h-2.5 rounded-full bg-purple-400"></span> Customers</span>
                                <span class="inline-flex items-center gap-1"><span class="w-2.5 h-2.5 rounded-full bg-sky-400"></span> Riders</span>
                            </div>
                        </div>
                        <div class="relative w-full h-80">
                            <canvas id="vendorUsersRidersBarChart"></canvas>
                        </div>
                    </div>

                </div>

                <!-- SECTION: TODAY'S RECENT ORDERS LIST (REQUESTED BY USER) -->
                <div class="cupertino-card rounded-2xl overflow-hidden shadow-sm border border-white/5 space-y-3 p-4">
                    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-2.5 border-b border-white/5">
                        <div class="flex items-center gap-2">
                            <div class="w-8 h-8 rounded-xl bg-orange-500/15 text-[#FF9500] flex items-center justify-center font-bold text-sm">
                                🛍️
                            </div>
                            <div>
                                <div class="flex items-center gap-2">
                                    <h4 class="text-xs font-bold text-white">Today's Recent Orders</h4>
                                    <span class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded-full text-[9px] font-bold bg-emerald-500/15 text-emerald-400 border border-emerald-500/25">
                                        <span class="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span> Live Stream
                                    </span>
                                </div>
                                <p class="text-[10.5px] text-zinc-400">Latest incoming orders, preparation status &amp; direct rider dispatch</p>
                            </div>
                        </div>

                        <div class="flex items-center gap-2">
                            <span class="text-[10px] text-zinc-400" x-text="todayRecentOrders.length + ' orders shown'"></span>
                            <button type="button" @click="setTab('orders')"
                                class="px-2.5 py-1 bg-zinc-900 hover:bg-zinc-800 text-xs font-bold text-[#FF9500] hover:text-orange-400 rounded-xl border border-white/10 hover:border-orange-500/30 flex items-center gap-1 transition-all">
                                <span>View All Orders in Hub</span>
                                <i data-lucide="arrow-right" class="w-3.5 h-3.5"></i>
                            </button>
                        </div>
                    </div>

                    <div class="overflow-x-auto">
                        <table class="w-full text-left text-xs">
                            <thead class="bg-zinc-950/70 text-zinc-400 uppercase font-semibold text-[9.5px] border-b border-white/5">
                                <tr>
                                    <th class="py-2.5 px-3">Order ID &amp; Time</th>
                                    <th class="py-2.5 px-3">Customer &amp; Phone</th>
                                    <th class="py-2.5 px-3">Type</th>
                                    <th class="py-2.5 px-3">Ordered Items</th>
                                    <th class="py-2.5 px-3">Total Amount</th>
                                    <th class="py-2.5 px-3">Assigned Rider</th>
                                    <th class="py-2.5 px-3">Prep Time</th>
                                    <th class="py-2.5 px-3">Status</th>
                                    <th class="py-2.5 px-3 text-right">Quick Action</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-white/5 font-medium text-zinc-300">
                                <template x-for="ord in todayRecentOrders" :key="ord.id">
                                    <tr class="hover:bg-zinc-800/40 transition-colors">
                                        <!-- Order ID & Time -->
                                        <td class="py-2.5 px-3 whitespace-nowrap">
                                            <div class="font-bold text-white font-mono text-xs" x-text="'#' + ord.id"></div>
                                            <div class="text-[10px] text-zinc-400 font-mono mt-0.5" x-text="formatDateShort(ord.orderDate || ord.createdAt)"></div>
                                        </td>

                                        <!-- Customer & Phone -->
                                        <td class="py-2.5 px-3">
                                            <div class="font-semibold text-white" x-text="ord.customerName || 'Walk-in Customer'"></div>
                                            <div class="flex items-center gap-1.5 mt-0.5">
                                                <span class="text-[10px] text-[#FF9500] font-mono" x-text="ord.customerPhone || '—'"></span>
                                                <template x-if="ord.customerPhone">
                                                    <span class="inline-flex items-center gap-1">
                                                        <a :href="'tel:' + ord.customerPhone" title="Call Customer" class="text-blue-400 hover:text-blue-300">
                                                            <i data-lucide="phone" class="w-2.5 h-2.5"></i>
                                                        </a>
                                                        <a :href="'https://wa.me/' + (ord.customerPhone || '').replace(/[^0-9]/g, '')" target="_blank" title="WhatsApp Customer" class="text-emerald-400 hover:text-emerald-300">
                                                            <i data-lucide="message-circle" class="w-2.5 h-2.5"></i>
                                                        </a>
                                                    </span>
                                                </template>
                                            </div>
                                        </td>

                                        <!-- Order Type -->
                                        <td class="py-2.5 px-3 whitespace-nowrap">
                                            <span class="px-2 py-0.5 rounded text-[9.5px] font-bold uppercase tracking-wider"
                                                :class="ord.isDaigBooking ? 'bg-amber-500/15 text-amber-300 border border-amber-500/25' : 'bg-orange-500/15 text-[#FF9500] border border-orange-500/25'"
                                                x-text="ord.isDaigBooking ? '👑 DAIG' : '🍽️ FOOD'">
                                            </span>
                                        </td>

                                        <!-- Items Summary -->
                                        <td class="py-2.5 px-3">
                                            <div class="text-[11px] text-zinc-200 line-clamp-1 max-w-[190px]" x-text="formatOrderItemsSummary(ord.items)"></div>
                                            <template x-if="ord.event_date || ord.eventDate">
                                                <div class="text-[9.5px] text-amber-400 font-bold mt-0.5 flex items-center gap-1">
                                                    <span>📅</span>
                                                    <span x-text="(ord.event_date || ord.eventDate) + ' ' + (ord.event_time || ord.eventTime || '')"></span>
                                                </div>
                                            </template>
                                        </td>

                                        <!-- Total Amount -->
                                        <td class="py-2.5 px-3 font-black text-[#FF9500] tabular-nums whitespace-nowrap"
                                            x-text="'Rs. ' + Number(ord.totalAmount || 0).toLocaleString()">
                                        </td>

                                        <!-- Assigned Rider -->
                                        <td class="py-2.5 px-3 whitespace-nowrap">
                                            <template x-if="ord.riderName">
                                                <div class="flex items-center gap-1">
                                                    <span class="text-sky-400">🛵</span>
                                                    <div>
                                                        <p class="font-semibold text-white text-[11px]" x-text="ord.riderName"></p>
                                                        <p class="text-[9.5px] text-zinc-400 font-mono" x-text="ord.riderPhone"></p>
                                                    </div>
                                                </div>
                                            </template>
                                            <template x-if="!ord.riderName">
                                                <button type="button" @click="openAssignRiderModal(ord)"
                                                    class="px-2 py-0.5 bg-sky-500/15 hover:bg-sky-500/25 text-sky-400 rounded-lg text-[10px] font-bold border border-sky-500/30 transition-all">
                                                    + Assign Rider
                                                </button>
                                            </template>
                                        </td>

                                        <!-- Prep Time -->
                                        <td class="py-2.5 px-3 text-[11px] font-mono text-zinc-400 whitespace-nowrap" x-text="ord.prepTime || '25-35 min'"></td>

                                        <!-- Status Badge -->
                                        <td class="py-2.5 px-3 whitespace-nowrap">
                                            <span class="px-2 py-0.5 rounded-full text-[9px] font-bold uppercase tracking-wider"
                                                :class="getStatusBadgeClass(ord.status)"
                                                x-text="ord.status">
                                            </span>
                                        </td>

                                        <!-- Quick Action -->
                                        <td class="py-2.5 px-3 text-right whitespace-nowrap">
                                            <div class="inline-flex items-center gap-1">
                                                <template x-if="ord.status === 'Pending'">
                                                    <button type="button" @click="updateOrderStatus(ord.id, 'Accepted')"
                                                        class="px-2 py-1 bg-emerald-500 hover:bg-emerald-400 text-black font-bold rounded-lg text-[10px] transition-all">
                                                        Accept ✅
                                                    </button>
                                                </template>
                                                <template x-if="ord.status === 'Accepted'">
                                                    <button type="button" @click="updateOrderStatus(ord.id, 'Preparing')"
                                                        class="px-2 py-1 bg-amber-500 hover:bg-amber-400 text-black font-bold rounded-lg text-[10px] transition-all">
                                                        Start Prep 🍳
                                                    </button>
                                                </template>
                                                <template x-if="ord.status === 'Preparing'">
                                                    <button type="button" @click="openAssignRiderModal(ord)"
                                                        class="px-2 py-1 bg-sky-500 hover:bg-sky-400 text-black font-bold rounded-lg text-[10px] transition-all">
                                                        Dispatch 🛵
                                                    </button>
                                                </template>
                                                <template x-if="ord.status === 'On the Way'">
                                                    <button type="button" @click="updateOrderStatus(ord.id, 'Delivered')"
                                                        class="px-2 py-1 bg-emerald-500 hover:bg-emerald-400 text-black font-bold rounded-lg text-[10px] transition-all">
                                                        Delivered ✅
                                                    </button>
                                                </template>
                                                <template x-if="ord.riderName && ord.customerPhone">
                                                    <button type="button" @click="sendWhatsAppDispatchAlert(ord)"
                                                        class="px-2 py-1 bg-emerald-500/15 hover:bg-emerald-500/25 text-emerald-400 border border-emerald-500/30 rounded-lg text-[10px] font-bold inline-flex items-center gap-1 transition-all"
                                                        title="Send WhatsApp Dispatch Alert to Customer">
                                                        <i data-lucide="message-circle" class="w-3 h-3 text-emerald-400"></i>
                                                        <span class="hidden sm:inline">WhatsApp</span>
                                                    </button>
                                                </template>
                                                <button type="button" @click="openOrderDetailModal(ord)" class="p-1 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 rounded-lg transition-all" title="View Full Order Info">
                                                    <i data-lucide="eye" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </template>
                                <template x-if="todayRecentOrders.length === 0">
                                    <tr>
                                        <td colspan="9" class="text-center py-8 text-zinc-500 italic">No orders recorded for today yet. Incoming orders will stream here automatically.</td>
                                    </tr>
                                </template>
                            </tbody>
                        </table>
                    </div>
                </div>

            </section>

            <!-- =============================================================== -->
            <!-- TAB 2: RIDERS FLEET (DEDICATED DELIVERY FLEET) -->
            <!-- =============================================================== -->
            <section x-show="activeTab === 'riders'" class="space-y-3">
                
                <!-- Top Actions Bar -->
                <div class="p-3 cupertino-card rounded-2xl flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-2.5">
                    <div class="flex items-center gap-2 flex-1 max-w-md">
                        <div class="relative flex-1">
                            <i data-lucide="search" class="w-3.5 h-3.5 text-zinc-500 absolute left-3 top-2.5"></i>
                            <input type="text" x-model="riderSearchQuery" placeholder="Search rider by name, phone or bike #..."
                                class="w-full pl-8 pr-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white placeholder-zinc-500 focus:outline-none focus:border-[#FF9500]">
                        </div>
                    </div>

                    <div class="flex items-center gap-2">
                        <!-- Custom Items per page dropdown -->
                        <div class="relative flex items-center gap-1.5 text-xs text-zinc-400" x-data="{ openRidersPage: false }">
                            <span>Per page:</span>
                            <button type="button" @click="openRidersPage = !openRidersPage; $nextTick(() => lucide.createIcons())"
                                class="px-2.5 py-1 bg-zinc-900 hover:bg-zinc-800 border border-white/10 hover:border-orange-500/30 rounded-xl text-xs text-white flex items-center gap-1.5 transition-all">
                                <span x-text="ridersPerPage"></span>
                                <i data-lucide="chevron-down" class="w-3 h-3 text-[#FF9500] transition-transform" :class="openRidersPage ? 'rotate-180' : ''"></i>
                            </button>
                            <div x-show="openRidersPage" @click.outside="openRidersPage = false" x-cloak
                                class="absolute right-0 top-full mt-1 w-20 cupertino-glass rounded-xl p-1 shadow-2xl border border-white/10 z-50 space-y-0.5 text-xs">
                                <template x-for="n in [25, 50, 100]" :key="n">
                                    <button type="button" @click="ridersPerPage = n; openRidersPage = false"
                                        class="w-full flex items-center justify-between px-2 py-1 rounded-lg text-left transition-colors hover:bg-orange-500/20"
                                        :class="ridersPerPage === n ? 'text-orange-400 font-bold bg-orange-500/10' : 'text-zinc-300'">
                                        <span x-text="n"></span>
                                        <i data-lucide="check" class="w-3 h-3 text-orange-400" x-show="ridersPerPage === n"></i>
                                    </button>
                                </template>
                            </div>
                        </div>

                        <!-- Add Rider Button -->
                        <button type="button" @click="openCreateRiderModal()"
                            class="px-3 py-1.5 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-black font-bold rounded-xl text-xs flex items-center gap-1.5 shadow-sm transition-all active:scale-95">
                            <i data-lucide="plus" class="w-3.5 h-3.5 text-black"></i>
                            <span>Add Dedicated Rider</span>
                        </button>
                    </div>
                </div>

                <!-- Riders Table -->
                <div class="cupertino-card rounded-2xl overflow-hidden shadow-sm">
                    <div class="overflow-x-auto">
                        <table class="w-full text-left text-xs">
                            <thead class="bg-zinc-950/70 text-zinc-400 uppercase font-semibold text-[9.5px] border-b border-white/5">
                                <tr>
                                    <th class="py-2.5 px-3">Rider Name & ID</th>
                                    <th class="py-2.5 px-3">Contact (Phone)</th>
                                    <th class="py-2.5 px-3">Vehicle / City</th>
                                    <th class="py-2.5 px-3 text-center">Deliveries</th>
                                    <th class="py-2.5 px-3 text-center">Active Orders</th>
                                    <th class="py-2.5 px-3">Status</th>
                                    <th class="py-2.5 px-3 text-right">Actions</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-white/5 font-medium text-zinc-300">
                                <template x-for="rdr in paginatedRiders" :key="rdr.id">
                                    <tr class="hover:bg-zinc-800/40 transition-colors">
                                        <td class="py-2.5 px-3">
                                            <div class="flex items-center gap-2">
                                                <div class="w-7 h-7 rounded-lg bg-sky-500/15 border border-sky-500/30 text-sky-400 flex items-center justify-center font-bold text-xs">
                                                    🛵
                                                </div>
                                                <div class="min-w-0">
                                                    <p class="font-bold text-white text-xs truncate" x-text="rdr.name"></p>
                                                    <p class="font-mono text-[9px] text-zinc-500" x-text="rdr.id"></p>
                                                </div>
                                            </div>
                                        </td>

                                        <td class="py-2.5 px-3">
                                            <a :href="'tel:' + rdr.phone" class="font-mono text-xs text-[#FF9500] hover:underline" x-text="rdr.phone || '—'"></a>
                                        </td>

                                        <td class="py-2.5 px-3">
                                            <div class="text-[11px] text-zinc-300 font-semibold" x-text="rdr.outlet_name || 'Standard Fleet'"></div>
                                            <div class="text-[9.5px] text-zinc-500" x-text="rdr.city || 'Lahore'"></div>
                                        </td>

                                        <td class="py-2.5 px-3 text-center">
                                            <span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/15 text-emerald-400 tabular-nums"
                                                x-text="(rdr.deliveriesCount || 12) + ' Delivered'">
                                            </span>
                                        </td>

                                        <td class="py-2.5 px-3 text-center">
                                            <span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-500/15 text-amber-400 tabular-nums"
                                                x-text="getActiveOrdersForRider(rdr.name).length + ' Active'">
                                            </span>
                                        </td>

                                        <td class="py-2.5 px-3">
                                            <span class="px-2 py-0.5 rounded-full text-[9px] font-bold uppercase tracking-wider"
                                                :class="rdr.banned ? 'bg-red-500/20 text-red-400 border border-red-500/30' : 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'"
                                                x-text="rdr.banned ? 'OFF-DUTY' : 'AVAILABLE 🟢'">
                                            </span>
                                        </td>

                                        <td class="py-2.5 px-3 text-right">
                                            <div class="inline-flex items-center gap-1">
                                                <button type="button" @click="viewRiderSheet(rdr)" class="p-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 rounded-lg" title="View Rider Deliveries">
                                                    <i data-lucide="eye" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                                </button>
                                                <button type="button" @click="editRider(rdr)" class="p-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 rounded-lg" title="Edit Rider">
                                                    <i data-lucide="edit" class="w-3.5 h-3.5 text-sky-400"></i>
                                                </button>
                                                <button type="button" @click="toggleRiderBan(rdr)" class="p-1.5 rounded-lg transition-colors"
                                                    :class="rdr.banned ? 'bg-emerald-500/15 hover:bg-emerald-500/25 text-emerald-400' : 'bg-amber-500/15 hover:bg-amber-500/25 text-amber-400'"
                                                    :title="rdr.banned ? 'Unblock Rider' : 'Block Rider'">
                                                    <i :data-lucide="rdr.banned ? 'shield-check' : 'shield-alert'" class="w-3.5 h-3.5"></i>
                                                </button>
                                                <button type="button" @click="deleteRider(rdr)" class="p-1.5 bg-red-950/40 hover:bg-red-900/60 text-red-400 rounded-lg" title="Delete Rider">
                                                    <i data-lucide="trash-2" class="w-3.5 h-3.5"></i>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </template>
                                <template x-if="paginatedRiders.length === 0">
                                    <tr>
                                        <td colspan="7" class="text-center py-8 text-zinc-500 italic">No dedicated riders found. Click "Add Dedicated Rider" to assign one.</td>
                                    </tr>
                                </template>
                            </tbody>
                        </table>
                    </div>

                    <!-- Pagination Controls (100 per page) -->
                    <div class="px-3.5 py-2.5 border-t border-white/5 flex items-center justify-between text-xs text-zinc-400">
                        <span x-text="'Showing ' + paginatedRiders.length + ' of ' + filteredRidersList.length + ' store riders (Page ' + ridersPage + ')'"></span>
                        <div class="flex items-center gap-1.5">
                            <button type="button" @click="ridersPage = Math.max(1, ridersPage - 1)" :disabled="ridersPage <= 1"
                                class="px-2.5 py-1 bg-zinc-900 disabled:opacity-40 rounded-lg text-xs font-semibold hover:text-white">Previous</button>
                            <span class="px-2 text-xs font-mono font-bold text-white" x-text="ridersPage"></span>
                            <button type="button" @click="ridersPage = ridersPage + 1" :disabled="ridersPage * ridersPerPage >= filteredRidersList.length"
                                class="px-2.5 py-1 bg-zinc-900 disabled:opacity-40 rounded-lg text-xs font-semibold hover:text-white">Next</button>
                        </div>
                    </div>
                </div>

            </section>

            <!-- =============================================================== -->
            <!-- TAB 3: CUSTOMERS (CUSTOMER BASE & RETENTION) -->
            <!-- =============================================================== -->
            <section x-show="activeTab === 'customers'" class="space-y-3">
                
                <!-- Search & Filters -->
                <div class="p-3 cupertino-card rounded-2xl flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-2.5">
                    <div class="relative flex-1 max-w-md">
                        <i data-lucide="search" class="w-3.5 h-3.5 text-zinc-500 absolute left-3 top-2.5"></i>
                        <input type="text" x-model="customerSearchQuery" placeholder="Search customer by name, phone or address..."
                            class="w-full pl-8 pr-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white placeholder-zinc-500 focus:outline-none focus:border-[#FF9500]">
                    </div>

                    <div class="flex items-center gap-2">
                        <!-- Custom Customer Sort Dropdown -->
                        <div class="relative" x-data="{ openSort: false }">
                            <button type="button" @click="openSort = !openSort; $nextTick(() => lucide.createIcons())"
                                class="px-2.5 py-1 bg-zinc-900 hover:bg-zinc-800 border border-white/10 hover:border-orange-500/30 rounded-xl text-xs text-white flex items-center gap-1.5 transition-all">
                                <span x-text="customerSortBy === 'spent' ? 'Highest Spent First' : (customerSortBy === 'orders' ? 'Most Orders First' : 'Most Recent Order')"></span>
                                <i data-lucide="chevron-down" class="w-3 h-3 text-[#FF9500] transition-transform" :class="openSort ? 'rotate-180' : ''"></i>
                            </button>
                            <div x-show="openSort" @click.outside="openSort = false" x-cloak
                                class="absolute left-0 top-full mt-1 w-44 cupertino-glass rounded-xl p-1 shadow-2xl border border-white/10 z-50 space-y-0.5 text-xs">
                                <button type="button" @click="customerSortBy = 'spent'; openSort = false"
                                    class="w-full flex items-center justify-between px-2 py-1.5 rounded-lg text-left transition-colors hover:bg-orange-500/20"
                                    :class="customerSortBy === 'spent' ? 'text-orange-400 font-bold bg-orange-500/10' : 'text-zinc-300'">
                                    <span>Highest Spent First</span>
                                    <i data-lucide="check" class="w-3 h-3 text-orange-400" x-show="customerSortBy === 'spent'"></i>
                                </button>
                                <button type="button" @click="customerSortBy = 'orders'; openSort = false"
                                    class="w-full flex items-center justify-between px-2 py-1.5 rounded-lg text-left transition-colors hover:bg-orange-500/20"
                                    :class="customerSortBy === 'orders' ? 'text-orange-400 font-bold bg-orange-500/10' : 'text-zinc-300'">
                                    <span>Most Orders First</span>
                                    <i data-lucide="check" class="w-3 h-3 text-orange-400" x-show="customerSortBy === 'orders'"></i>
                                </button>
                                <button type="button" @click="customerSortBy = 'recent'; openSort = false"
                                    class="w-full flex items-center justify-between px-2 py-1.5 rounded-lg text-left transition-colors hover:bg-orange-500/20"
                                    :class="customerSortBy === 'recent' ? 'text-orange-400 font-bold bg-orange-500/10' : 'text-zinc-300'">
                                    <span>Most Recent Order</span>
                                    <i data-lucide="check" class="w-3 h-3 text-orange-400" x-show="customerSortBy === 'recent'"></i>
                                </button>
                            </div>
                        </div>

                        <!-- Custom Customers Per Page Dropdown -->
                        <div class="relative flex items-center gap-1.5 text-xs text-zinc-400" x-data="{ openCustPage: false }">
                            <span>Per page:</span>
                            <button type="button" @click="openCustPage = !openCustPage; $nextTick(() => lucide.createIcons())"
                                class="px-2.5 py-1 bg-zinc-900 hover:bg-zinc-800 border border-white/10 hover:border-orange-500/30 rounded-xl text-xs text-white flex items-center gap-1.5 transition-all">
                                <span x-text="customersPerPage"></span>
                                <i data-lucide="chevron-down" class="w-3 h-3 text-[#FF9500] transition-transform" :class="openCustPage ? 'rotate-180' : ''"></i>
                            </button>
                            <div x-show="openCustPage" @click.outside="openCustPage = false" x-cloak
                                class="absolute right-0 top-full mt-1 w-20 cupertino-glass rounded-xl p-1 shadow-2xl border border-white/10 z-50 space-y-0.5 text-xs">
                                <template x-for="n in [25, 50, 100]" :key="n">
                                    <button type="button" @click="customersPerPage = n; openCustPage = false"
                                        class="w-full flex items-center justify-between px-2 py-1 rounded-lg text-left transition-colors hover:bg-orange-500/20"
                                        :class="customersPerPage === n ? 'text-orange-400 font-bold bg-orange-500/10' : 'text-zinc-300'">
                                        <span x-text="n"></span>
                                        <i data-lucide="check" class="w-3 h-3 text-orange-400" x-show="customersPerPage === n"></i>
                                    </button>
                                </template>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Customers Table -->
                <div class="cupertino-card rounded-2xl overflow-hidden shadow-sm">
                    <div class="overflow-x-auto">
                        <table class="w-full text-left text-xs">
                            <thead class="bg-zinc-950/70 text-zinc-400 uppercase font-semibold text-[9.5px] border-b border-white/5">
                                <tr>
                                    <th class="py-2.5 px-3">Customer Name</th>
                                    <th class="py-2.5 px-3">Phone (WhatsApp)</th>
                                    <th class="py-2.5 px-3 text-center">Orders Count</th>
                                    <th class="py-2.5 px-3">Total Spent</th>
                                    <th class="py-2.5 px-3">Last Order Date</th>
                                    <th class="py-2.5 px-3">Default Delivery Address</th>
                                    <th class="py-2.5 px-3">Tier</th>
                                    <th class="py-2.5 px-3 text-right">Actions</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-white/5 font-medium text-zinc-300">
                                <template x-for="cust in paginatedCustomers" :key="cust.customerPhone">
                                    <tr class="hover:bg-zinc-800/40 transition-colors cursor-pointer" @click="openCustomerSheet(cust)">
                                        <td class="py-2.5 px-3">
                                            <div class="flex items-center gap-2">
                                                <div class="w-7 h-7 rounded-full bg-purple-500/15 border border-purple-500/30 text-purple-300 flex items-center justify-center font-bold text-xs">
                                                    👤
                                                </div>
                                                <p class="font-bold text-white text-xs truncate max-w-[150px]" x-text="cust.customerName || 'Guest Customer'"></p>
                                            </div>
                                        </td>

                                        <td class="py-2.5 px-3 font-mono text-xs text-[#FF9500]" x-text="cust.customerPhone || '—'"></td>

                                        <td class="py-2.5 px-3 text-center">
                                            <span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-orange-500/15 text-[#FF9500] tabular-nums"
                                                x-text="(cust.totalOrders || 1) + ' Orders'">
                                            </span>
                                        </td>

                                        <td class="py-2.5 px-3 font-black text-emerald-400 tabular-nums"
                                            x-text="'Rs. ' + Number(cust.totalSpent || 0).toLocaleString()">
                                        </td>

                                        <td class="py-2.5 px-3 text-[11px] text-zinc-400 font-mono" x-text="formatDateShort(cust.lastOrderDate)"></td>

                                        <td class="py-2.5 px-3 text-[11px] text-zinc-300 truncate max-w-[180px]" x-text="cust.deliveryAddress || 'Lahore'"></td>

                                        <td class="py-2.5 px-3">
                                            <span class="px-2 py-0.5 rounded-full text-[9px] font-bold uppercase tracking-wider"
                                                :class="cust.totalSpent > 10000 ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30' : 'bg-zinc-800 text-zinc-300'"
                                                x-text="cust.totalSpent > 10000 ? 'VIP FOODIE ⭐' : 'REGULAR'">
                                            </span>
                                        </td>

                                        <td class="py-2.5 px-3 text-right" @click.stop>
                                            <div class="inline-flex items-center gap-1.5 justify-end">
                                                <button type="button" @click="toggleCustomerBan(cust)"
                                                    class="px-2 py-1 rounded-lg text-[10.5px] font-bold transition-all flex items-center gap-1"
                                                    :class="cust.banned ? 'bg-emerald-500/20 text-emerald-300 hover:bg-emerald-500/30' : 'bg-red-500/15 text-red-400 hover:bg-red-500/25'"
                                                    :title="cust.banned ? 'Unblock Customer' : 'Block Customer'">
                                                    <i :data-lucide="cust.banned ? 'unlock' : 'lock'" class="w-3 h-3"></i>
                                                    <span x-text="cust.banned ? 'Unblock' : 'Block'"></span>
                                                </button>
                                                <button type="button" @click="openCustomerSheet(cust)"
                                                    class="px-2.5 py-1 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 rounded-lg text-[11px] font-semibold flex items-center gap-1 transition-all">
                                                    <i data-lucide="history" class="w-3 h-3 text-[#FF9500]"></i>
                                                    <span>History</span>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </template>
                                <template x-if="paginatedCustomers.length === 0">
                                    <tr>
                                        <td colspan="8" class="text-center py-8 text-zinc-500 italic">No customers found matching search.</td>
                                    </tr>
                                </template>
                            </tbody>
                        </table>
                    </div>

                    <!-- Pagination Controls (100 per page) -->
                    <div class="px-3.5 py-2.5 border-t border-white/5 flex items-center justify-between text-xs text-zinc-400">
                        <span x-text="'Showing ' + paginatedCustomers.length + ' of ' + filteredCustomersList.length + ' customers (Page ' + customersPage + ')'"></span>
                        <div class="flex items-center gap-1.5">
                            <button type="button" @click="customersPage = Math.max(1, customersPage - 1)" :disabled="customersPage <= 1"
                                class="px-2.5 py-1 bg-zinc-900 disabled:opacity-40 rounded-lg text-xs font-semibold hover:text-white">Previous</button>
                            <span class="px-2 text-xs font-mono font-bold text-white" x-text="customersPage"></span>
                            <button type="button" @click="customersPage = customersPage + 1" :disabled="customersPage * customersPerPage >= filteredCustomersList.length"
                                class="px-2.5 py-1 bg-zinc-900 disabled:opacity-40 rounded-lg text-xs font-semibold hover:text-white">Next</button>
                        </div>
                    </div>
                </div>

            </section>

            <!-- =============================================================== -->
            <!-- TAB 4: ORDERS (LIVE KITCHEN & DISPATCH MANAGEMENT) -->
            <!-- =============================================================== -->
            <section x-show="activeTab === 'orders'" class="space-y-3">
                
                <!-- Filters Bar: Status Pills & Type Switcher -->
                <div class="p-3 cupertino-card rounded-2xl space-y-2.5">
                    
                    <!-- Row 1: Search & Type Buttons -->
                    <div class="flex flex-col lg:flex-row items-stretch lg:items-center justify-between gap-2.5">
                        <div class="relative flex-1">
                            <i data-lucide="search" class="w-3.5 h-3.5 text-zinc-500 absolute left-3 top-2.5"></i>
                            <input type="text" x-model="orderSearchQuery" placeholder="Search by Order #FC, customer name, phone or rider..."
                                class="w-full pl-8 pr-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white placeholder-zinc-500 focus:outline-none focus:border-[#FF9500]">
                        </div>

                        <!-- Type Filter Pills -->
                        <div class="flex items-center gap-1.5 shrink-0 text-xs font-semibold">
                            <button type="button" @click="selectedOrderType = 'All'"
                                class="px-3 py-1.5 rounded-xl transition-all"
                                :class="selectedOrderType === 'All' ? 'bg-[#FF9500] text-black font-bold shadow-sm' : 'bg-zinc-900 text-zinc-400 hover:text-white border border-white/5'">
                                All Orders
                            </button>
                            <button type="button" @click="selectedOrderType = 'daig'"
                                class="px-3 py-1.5 rounded-xl transition-all"
                                :class="selectedOrderType === 'daig' ? 'bg-[#FF9500] text-black font-bold shadow-sm' : 'bg-zinc-900 text-zinc-400 hover:text-white border border-white/5'">
                                👑 Shahi Daigs
                            </button>
                            <button type="button" @click="selectedOrderType = 'food'"
                                class="px-3 py-1.5 rounded-xl transition-all"
                                :class="selectedOrderType === 'food' ? 'bg-[#FF9500] text-black font-bold shadow-sm' : 'bg-zinc-900 text-zinc-400 hover:text-white border border-white/5'">
                                🍽️ Food Dishes
                            </button>
                        </div>
                    </div>

                    <!-- Row 2: Status Pills Strip & Pagination Size (100 per page standard) -->
                    <div class="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-white/5 text-xs">
                        <div class="flex flex-wrap items-center gap-1">
                            <template x-for="st in ['All', 'Accepted', 'Preparing', 'On the Way', 'Arrived', 'Delivered', 'Cancelled']" :key="st">
                                <button type="button" @click="selectedOrderStatus = st"
                                    class="px-2.5 py-1 rounded-xl text-[11px] font-semibold transition-all"
                                    :class="selectedOrderStatus === st ? 'bg-orange-500/25 text-[#FF9500] border border-orange-500/40 font-bold' : 'bg-zinc-900 text-zinc-400 hover:text-white border border-white/5'">
                                    <span x-text="st"></span>
                                    <span class="ml-1 text-[9px] opacity-75 tabular-nums" x-text="'(' + getOrdersCountByStatus(st) + ')'"></span>
                                </button>
                            </template>
                        </div>

                        <!-- Custom Orders Per Page Dropdown -->
                        <div class="relative flex items-center gap-1.5 text-xs text-zinc-400" x-data="{ openOrdersPage: false }">
                            <span>Per page:</span>
                            <button type="button" @click="openOrdersPage = !openOrdersPage; $nextTick(() => lucide.createIcons())"
                                class="px-2.5 py-1 bg-zinc-900 hover:bg-zinc-800 border border-white/10 hover:border-orange-500/30 rounded-xl text-xs text-white flex items-center gap-1.5 transition-all">
                                <span x-text="ordersPerPage"></span>
                                <i data-lucide="chevron-down" class="w-3 h-3 text-[#FF9500] transition-transform" :class="openOrdersPage ? 'rotate-180' : ''"></i>
                            </button>
                            <div x-show="openOrdersPage" @click.outside="openOrdersPage = false" x-cloak
                                class="absolute right-0 top-full mt-1 w-20 cupertino-glass rounded-xl p-1 shadow-2xl border border-white/10 z-50 space-y-0.5 text-xs">
                                <template x-for="n in [25, 50, 100]" :key="n">
                                    <button type="button" @click="ordersPerPage = n; openOrdersPage = false"
                                        class="w-full flex items-center justify-between px-2 py-1 rounded-lg text-left transition-colors hover:bg-orange-500/20"
                                        :class="ordersPerPage === n ? 'text-orange-400 font-bold bg-orange-500/10' : 'text-zinc-300'">
                                        <span x-text="n"></span>
                                        <i data-lucide="check" class="w-3 h-3 text-orange-400" x-show="ordersPerPage === n"></i>
                                    </button>
                                </template>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- High-Density Orders Table -->
                <div class="cupertino-card rounded-2xl overflow-hidden shadow-sm">
                    <div class="overflow-x-auto">
                        <table class="w-full text-left text-xs">
                            <thead class="bg-zinc-950/70 text-zinc-400 uppercase font-semibold text-[9.5px] border-b border-white/5">
                                <tr>
                                    <th class="py-2.5 px-3">Order ID & Date</th>
                                    <th class="py-2.5 px-3">Customer & Address</th>
                                    <th class="py-2.5 px-3">Ordered Items</th>
                                    <th class="py-2.5 px-3">Type</th>
                                    <th class="py-2.5 px-3">Total Amount</th>
                                    <th class="py-2.5 px-3">Assigned Rider</th>
                                    <th class="py-2.5 px-3">Prep Time</th>
                                    <th class="py-2.5 px-3">Status</th>
                                    <th class="py-2.5 px-3 text-right">Workflow Actions</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-white/5 font-medium text-zinc-300">
                                <template x-for="ord in paginatedOrders" :key="ord.id">
                                    <tr class="hover:bg-zinc-800/40 transition-colors">
                                        <td class="py-2.5 px-3">
                                            <div class="font-bold text-white font-mono text-xs" x-text="'#' + ord.id"></div>
                                            <div class="text-[10px] text-zinc-400 font-mono mt-0.5" x-text="formatDateShort(ord.orderDate)"></div>
                                        </td>

                                        <td class="py-2.5 px-3">
                                            <div class="font-semibold text-white" x-text="ord.customerName"></div>
                                            <div class="flex items-center gap-1.5 mt-0.5">
                                                <span class="text-[10px] text-[#FF9500] font-mono" x-text="ord.customerPhone"></span>
                                                <template x-if="ord.customerPhone">
                                                    <span class="inline-flex items-center gap-1">
                                                        <a :href="'tel:' + ord.customerPhone" title="Call Customer" class="text-blue-400 hover:text-blue-300">
                                                            <i data-lucide="phone" class="w-2.5 h-2.5"></i>
                                                        </a>
                                                        <a :href="'https://wa.me/' + (ord.customerPhone || '').replace(/[^0-9]/g, '')" target="_blank" title="WhatsApp Customer" class="text-emerald-400 hover:text-emerald-300">
                                                            <i data-lucide="message-circle" class="w-2.5 h-2.5"></i>
                                                        </a>
                                                    </span>
                                                </template>
                                            </div>
                                            <div class="text-[10px] text-zinc-400 truncate max-w-[140px]" x-text="ord.deliveryAddress"></div>
                                        </td>

                                        <td class="py-2.5 px-3">
                                            <div class="text-[11px] text-zinc-200 line-clamp-2 max-w-[180px]" x-text="formatOrderItemsSummary(ord.items)"></div>
                                            <template x-if="ord.event_date || ord.eventDate">
                                                <div class="text-[9.5px] text-amber-400 font-bold mt-0.5 flex items-center gap-1">
                                                    <span>📅</span>
                                                    <span x-text="(ord.event_date || ord.eventDate) + ' ' + (ord.event_time || ord.eventTime || '')"></span>
                                                </div>
                                            </template>
                                        </td>

                                        <td class="py-2.5 px-3">
                                            <span class="px-2 py-0.5 rounded text-[9.5px] font-bold uppercase tracking-wider"
                                                :class="ord.isDaigBooking ? 'bg-amber-500/15 text-amber-300 border border-amber-500/25' : 'bg-orange-500/15 text-[#FF9500] border border-orange-500/25'"
                                                x-text="ord.isDaigBooking ? '👑 DAIG' : '🍽️ FOOD'">
                                            </span>
                                        </td>

                                        <td class="py-2.5 px-3 font-black text-[#FF9500] tabular-nums whitespace-nowrap"
                                            x-text="'Rs. ' + Number(ord.totalAmount || 0).toLocaleString()">
                                        </td>

                                        <td class="py-2.5 px-3 whitespace-nowrap">
                                            <template x-if="ord.riderName">
                                                <div class="flex items-center gap-1">
                                                    <span class="text-sky-400">🛵</span>
                                                    <div>
                                                        <p class="font-semibold text-white text-[11px]" x-text="ord.riderName"></p>
                                                        <p class="text-[9.5px] text-zinc-400 font-mono" x-text="ord.riderPhone"></p>
                                                    </div>
                                                </div>
                                            </template>
                                            <template x-if="!ord.riderName">
                                                <button type="button" @click="openAssignRiderModal(ord)"
                                                    class="px-2 py-0.5 bg-sky-500/15 hover:bg-sky-500/25 text-sky-400 rounded-lg text-[10px] font-bold border border-sky-500/30">
                                                    + Assign Rider
                                                </button>
                                            </template>
                                        </td>

                                        <td class="py-2.5 px-3 text-[11px] font-mono text-zinc-400" x-text="ord.prepTime || '25-35 min'"></td>

                                        <td class="py-2.5 px-3 whitespace-nowrap">
                                            <span class="px-2 py-0.5 rounded-full text-[9px] font-bold uppercase tracking-wider"
                                                :class="getStatusBadgeClass(ord.status)"
                                                x-text="ord.status">
                                            </span>
                                        </td>

                                        <!-- Workflow Actions -->
                                        <td class="py-2.5 px-3 text-right whitespace-nowrap">
                                            <div class="inline-flex items-center gap-1">
                                                <!-- Next Status Progress Button -->
                                                <template x-if="ord.status === 'Pending'">
                                                    <button type="button" @click="updateOrderStatus(ord.id, 'Accepted')"
                                                        class="px-2 py-1 bg-emerald-500 hover:bg-emerald-400 text-black font-bold rounded-lg text-[10px]">
                                                        Accept ✅
                                                    </button>
                                                </template>
                                                <template x-if="ord.status === 'Accepted'">
                                                    <button type="button" @click="updateOrderStatus(ord.id, 'Preparing')"
                                                        class="px-2 py-1 bg-amber-500 hover:bg-amber-400 text-black font-bold rounded-lg text-[10px]">
                                                        Start Prep 🍳
                                                    </button>
                                                </template>
                                                <template x-if="ord.status === 'Preparing'">
                                                    <button type="button" @click="openAssignRiderModal(ord)"
                                                        class="px-2 py-1 bg-sky-500 hover:bg-sky-400 text-black font-bold rounded-lg text-[10px]">
                                                        Dispatch 🛵
                                                    </button>
                                                </template>
                                                <template x-if="ord.status === 'On the Way'">
                                                    <button type="button" @click="updateOrderStatus(ord.id, 'Delivered')"
                                                        class="px-2 py-1 bg-emerald-500 hover:bg-emerald-400 text-black font-bold rounded-lg text-[10px]">
                                                        Delivered ✅
                                                    </button>
                                                </template>

                                                <!-- Reject Modal Trigger -->
                                                <template x-if="ord.status !== 'Delivered' && ord.status !== 'Cancelled'">
                                                    <button type="button" @click="openRejectModal(ord)" class="p-1 bg-red-950/40 hover:bg-red-900/60 text-red-400 rounded-lg" title="Reject Order">
                                                        <i data-lucide="x-circle" class="w-3.5 h-3.5"></i>
                                                    </button>
                                                </template>

                                                <!-- WhatsApp Dispatch Button -->
                                                <template x-if="ord.riderName && ord.customerPhone">
                                                    <button type="button" @click="sendWhatsAppDispatchAlert(ord)"
                                                        class="px-2 py-1 bg-emerald-500/15 hover:bg-emerald-500/25 text-emerald-400 border border-emerald-500/30 rounded-lg text-[10px] font-bold inline-flex items-center gap-1 transition-all"
                                                        title="Send WhatsApp Dispatch Alert to Customer">
                                                        <i data-lucide="message-circle" class="w-3 h-3 text-emerald-400"></i>
                                                        <span class="hidden sm:inline">WhatsApp</span>
                                                    </button>
                                                </template>

                                                <!-- View Details Modal Trigger -->
                                                <button type="button" @click="openOrderDetailModal(ord)" class="p-1 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 rounded-lg" title="View Full Order Info">
                                                    <i data-lucide="eye" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </template>
                                <template x-if="paginatedOrders.length === 0">
                                    <tr>
                                        <td colspan="9" class="text-center py-8 text-zinc-500 italic">No orders found matching filters.</td>
                                    </tr>
                                </template>
                            </tbody>
                        </table>
                    </div>

                    <!-- Pagination Controls (100 per page) -->
                    <div class="px-3.5 py-2.5 border-t border-white/5 flex items-center justify-between text-xs text-zinc-400">
                        <span x-text="'Showing ' + paginatedOrders.length + ' of ' + filteredOrdersList.length + ' orders (Page ' + ordersPage + ')'"></span>
                        <div class="flex items-center gap-1.5">
                            <button type="button" @click="ordersPage = Math.max(1, ordersPage - 1)" :disabled="ordersPage <= 1"
                                class="px-2.5 py-1 bg-zinc-900 disabled:opacity-40 rounded-lg text-xs font-semibold hover:text-white">Previous</button>
                            <span class="px-2 text-xs font-mono font-bold text-white" x-text="ordersPage"></span>
                            <button type="button" @click="ordersPage = ordersPage + 1" :disabled="ordersPage * ordersPerPage >= filteredOrdersList.length"
                                class="px-2.5 py-1 bg-zinc-900 disabled:opacity-40 rounded-lg text-xs font-semibold hover:text-white">Next</button>
                        </div>
                    </div>
                </div>

            </section>

            <!-- =============================================================== -->
            <!-- TAB 2: FOOD LISTING (RESTAURANT DISHES, SHAHI DAIGS & ADD LISTING) -->
            <!-- =============================================================== -->
            <section x-show="activeTab === 'food-listing'" class="space-y-3.5">
                
                <!-- Top Header & View Switcher Bar -->
                <div class="p-3 cupertino-card rounded-2xl flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3">
                    <div class="flex items-center gap-2.5">
                        <div class="w-9 h-9 rounded-xl bg-orange-500/15 text-[#FF9500] flex items-center justify-center font-bold text-base shrink-0">
                            🍽️
                        </div>
                        <div>
                            <h3 class="text-xs font-bold text-white flex items-center gap-2">
                                <span>Food &amp; Catering Listings Hub</span>
                                <span class="px-2 py-0.5 rounded-full text-[9px] font-bold bg-white/10 text-zinc-300 font-mono" x-text="vendorFoodItems.length + vendorDaigItems.length + ' Total Items'"></span>
                            </h3>
                            <p class="text-[10.5px] text-zinc-400">Manage live restaurant dishes, Shahi catering daigs, promotional discounts &amp; images</p>
                        </div>
                    </div>

                    <!-- View Switcher: All Listings vs Add Food Listing -->
                    <div class="inline-flex p-1 bg-zinc-900 rounded-xl border border-white/5 shrink-0">
                        <button type="button" @click="foodListingMode = 'list'; $nextTick(() => lucide.createIcons())"
                            class="px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5"
                            :class="foodListingMode === 'list' ? 'bg-[#FF9500] text-black shadow-sm' : 'text-zinc-400 hover:text-white'">
                            <i data-lucide="layout-list" class="w-3.5 h-3.5"></i>
                            <span>All Menu Listings</span>
                        </button>
                        <button type="button" @click="openAddListingPage(addListingType || 'restaurant')"
                            class="px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5"
                            :class="foodListingMode === 'add' ? 'bg-[#FF9500] text-black shadow-sm' : 'text-zinc-400 hover:text-white'">
                            <i data-lucide="plus-circle" class="w-3.5 h-3.5"></i>
                            <span>➕ Add Food Listing</span>
                        </button>
                    </div>
                </div>

                <!-- =========================================================== -->
                <!-- VIEW 1: DEDICATED ADD FOOD LISTING PAGE                     -->
                <!-- =========================================================== -->
                <div x-show="foodListingMode === 'add'" class="space-y-4" x-cloak>
                    
                    <!-- STEP 1: CATEGORY SELECTION (RESTAURANT VS PAKWAN) -->
                    <div class="p-4 rounded-2xl cupertino-card border border-white/5 space-y-3">
                        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-2.5 border-b border-white/5">
                            <div>
                                <span class="text-[10px] uppercase font-bold text-amber-400 tracking-wider">Step 1: Listing Category</span>
                                <h4 class="text-sm font-bold text-white">Kis Category ke liye add karna hai?</h4>
                                <p class="text-[11px] text-zinc-400">Select whether this menu item belongs to Restaurant Food or Pakwan Catering Center</p>
                            </div>
                            <button type="button" @click="foodListingMode = 'list'"
                                class="self-start sm:self-auto px-2.5 py-1 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 hover:text-white text-xs font-semibold rounded-lg flex items-center gap-1 transition-all">
                                <i data-lucide="arrow-left" class="w-3.5 h-3.5"></i>
                                <span>Back to Listings</span>
                            </button>
                        </div>

                        <!-- 2 Big Selection Cards -->
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                            <!-- Card A: Restaurant Food Dish -->
                            <button type="button" @click="resetNewListingForm('restaurant')"
                                class="p-4 rounded-2xl text-left border transition-all relative overflow-hidden group flex flex-col justify-between"
                                :class="addListingType === 'restaurant'
                                    ? 'bg-orange-500/10 border-[#FF9500] ring-1 ring-orange-500/30'
                                    : 'bg-zinc-900/60 border-white/5 hover:border-white/20'">
                                <div class="flex items-start justify-between gap-3 mb-3">
                                    <div class="w-12 h-12 rounded-2xl bg-orange-500/15 text-[#FF9500] flex items-center justify-center text-2xl group-hover:scale-110 transition-transform">
                                        🍽️
                                    </div>
                                    <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold"
                                        :class="addListingType === 'restaurant' ? 'bg-[#FF9500] text-black' : 'bg-zinc-800 text-zinc-400'">
                                        <span x-text="addListingType === 'restaurant' ? '✓ Selected' : 'Choose'"></span>
                                    </span>
                                </div>
                                <div>
                                    <h5 class="text-sm font-bold text-white">Restaurant Food Dishes</h5>
                                    <p class="text-xs text-zinc-400 mt-1">Single portion meals, Biryani plates, Karahi &amp; Handi, BBQ, Burgers, Gravy, Desserts &amp; Drinks.</p>
                                    <div class="mt-2.5 flex flex-wrap gap-1.5 text-[9.5px] font-semibold text-zinc-400">
                                        <span class="px-2 py-0.5 bg-black/40 rounded-md">Biryani</span>
                                        <span class="px-2 py-0.5 bg-black/40 rounded-md">Karahi</span>
                                        <span class="px-2 py-0.5 bg-black/40 rounded-md">BBQ &amp; Grill</span>
                                        <span class="px-2 py-0.5 bg-black/40 rounded-md">Cut Price &amp; % Off</span>
                                    </div>
                                </div>
                            </button>

                            <!-- Card B: Pakwan Center Daig Catering -->
                            <button type="button" @click="resetNewListingForm('pakwan')"
                                class="p-4 rounded-2xl text-left border transition-all relative overflow-hidden group flex flex-col justify-between"
                                :class="addListingType === 'pakwan'
                                    ? 'bg-amber-500/10 border-amber-400 ring-1 ring-amber-400/30'
                                    : 'bg-zinc-900/60 border-white/5 hover:border-white/20'">
                                <div class="flex items-start justify-between gap-3 mb-3">
                                    <div class="w-12 h-12 rounded-2xl bg-amber-500/15 text-amber-400 flex items-center justify-center text-2xl group-hover:scale-110 transition-transform">
                                        👑
                                    </div>
                                    <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold"
                                        :class="addListingType === 'pakwan' ? 'bg-amber-400 text-black' : 'bg-zinc-800 text-zinc-400'">
                                        <span x-text="addListingType === 'pakwan' ? '✓ Selected' : 'Choose'"></span>
                                    </span>
                                </div>
                                <div>
                                    <h5 class="text-sm font-bold text-white">Pakwan Center (Shahi Daig Catering)</h5>
                                    <p class="text-xs text-zinc-400 mt-1">Grand catering daigs (12 KG Full Deg / 6 KG Half Deg) for weddings, Valima, bulk gatherings &amp; advance booking.</p>
                                    <div class="mt-2.5 flex flex-wrap gap-1.5 text-[9.5px] font-semibold text-zinc-400">
                                        <span class="px-2 py-0.5 bg-black/40 rounded-md">Full / Half Daig</span>
                                        <span class="px-2 py-0.5 bg-black/40 rounded-md">Pakwan Kitchen Location</span>
                                        <span class="px-2 py-0.5 bg-black/40 rounded-md">Advance Notice</span>
                                        <span class="px-2 py-0.5 bg-black/40 rounded-md">Urdu Name</span>
                                    </div>
                                </div>
                            </button>
                        </div>
                    </div>

                    <!-- STEP 2A: RESTAURANT FORM & LIVE PREVIEW (Shown when addListingType === 'restaurant') -->
                    <div x-show="addListingType === 'restaurant'" class="grid grid-cols-1 lg:grid-cols-12 gap-4">
                        
                        <!-- Form Fields (8 Columns) -->
                        <div class="lg:col-span-8 p-4 rounded-2xl cupertino-card border border-white/5 space-y-3.5">
                            <div class="flex items-center justify-between pb-2.5 border-b border-white/5">
                                <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                    <i data-lucide="utensils" class="w-4 h-4 text-[#FF9500]"></i>
                                    <span>Restaurant Dish Information &amp; Pricing</span>
                                </h4>
                                <span class="text-[10px] text-zinc-400">* Required inputs</span>
                            </div>

                            <form @submit.prevent="submitNewListing()" class="space-y-3.5">
                                
                                <!-- Dish Title & Category Custom Dropdown -->
                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                    <div>
                                        <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Dish Name / Title *</label>
                                        <input type="text" x-model="newListingForm.name" required placeholder="e.g. Special Chicken Dum Biryani"
                                            class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500] placeholder-zinc-500">
                                    </div>

                                    <!-- Custom Dish Category Dropdown (Filtered to Admin Allowed Categories) -->
                                    <div class="relative" x-data="{ openListingCat: false }">
                                        <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Dish Category *</label>
                                        <button type="button" @click="openListingCat = !openListingCat; $nextTick(() => lucide.createIcons())"
                                            class="w-full px-3 py-2 bg-zinc-900 border border-white/10 hover:border-orange-500/40 rounded-xl text-xs text-white flex items-center justify-between transition-colors focus:outline-none focus:border-[#FF9500]">
                                            <span x-text="newListingForm.category || 'Select Category'"></span>
                                            <i data-lucide="chevron-down" class="w-4 h-4 text-[#FF9500] transition-transform" :class="openListingCat ? 'rotate-180' : ''"></i>
                                        </button>
                                        <div x-show="openListingCat" @click.outside="openListingCat = false" x-cloak
                                            class="absolute left-0 mt-1 w-full max-h-52 overflow-y-auto cupertino-glass rounded-xl p-1 shadow-2xl border border-white/10 z-50 space-y-0.5 text-xs">
                                            <template x-for="cat in allowedFoodCategories" :key="cat">
                                                <button type="button" @click="newListingForm.category = cat; openListingCat = false"
                                                    class="w-full flex items-center justify-between px-3 py-2 rounded-lg text-left transition-colors hover:bg-orange-500/20"
                                                    :class="newListingForm.category === cat ? 'text-orange-400 font-bold bg-orange-500/10' : 'text-zinc-300'">
                                                    <span x-text="cat"></span>
                                                    <i data-lucide="check" class="w-3.5 h-3.5 text-orange-400" x-show="newListingForm.category === cat"></i>
                                                </button>
                                            </template>
                                        </div>
                                    </div>
                                </div>

                                <!-- Dish Description -->
                                <div>
                                    <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Dish Description</label>
                                    <textarea x-model="newListingForm.description" rows="2" placeholder="Fragrant Basmati rice prepared with premium spices, served with fresh raita and salad..."
                                        class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500] placeholder-zinc-500"></textarea>
                                </div>

                                <!-- Pricing, Cut Price & Discount Offer Box -->
                                <div class="p-3.5 rounded-2xl bg-orange-500/10 border border-orange-500/30 space-y-3">
                                    <div class="flex items-center justify-between">
                                        <span class="text-xs font-bold text-white flex items-center gap-1.5">
                                            <i data-lucide="tag" class="w-4 h-4 text-[#FF9500]"></i>
                                            <span>Actual Price, Cut Price &amp; Discount (% OFF)</span>
                                        </span>
                                        <label class="flex items-center gap-2 cursor-pointer select-none">
                                            <input type="checkbox" x-model="newListingForm.showCutPrice" class="w-4 h-4 rounded bg-zinc-800 text-[#FF9500] border-white/20 focus:ring-0">
                                            <span class="text-[11px] font-bold text-[#FF9500]">Show Cut Price on App</span>
                                        </label>
                                    </div>

                                    <div class="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
                                        <!-- Actual Selling Price -->
                                        <div>
                                            <label class="block text-[10px] font-bold uppercase tracking-wider text-emerald-400 mb-1">Actual Selling Price (Rs.) *</label>
                                            <input type="number" x-model.number="newListingForm.actualPrice" @input="recalcListingDiscount('actual')" required min="10" placeholder="650"
                                                class="w-full px-3 py-2 bg-zinc-900 border border-emerald-500/40 rounded-xl text-xs text-emerald-400 font-mono font-bold focus:outline-none focus:border-emerald-400">
                                            <span class="text-[9.5px] text-zinc-400 mt-0.5 block">Price customer pays</span>
                                        </div>

                                        <!-- Original Cut Price -->
                                        <div>
                                            <label class="block text-[10px] font-bold uppercase tracking-wider text-zinc-300 mb-1">Original Cut Price (Rs.)</label>
                                            <input type="number" x-model.number="newListingForm.cutPrice" @input="recalcListingDiscount('cut')" min="10" placeholder="1300"
                                                class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white font-mono focus:outline-none focus:border-[#FF9500]">
                                            <span class="text-[9.5px] text-zinc-400 mt-0.5 block">Strikethrough before discount</span>
                                        </div>

                                        <!-- Discount Percentage -->
                                        <div>
                                            <label class="block text-[10px] font-bold uppercase tracking-wider text-amber-400 mb-1">Discount (% OFF)</label>
                                            <input type="number" x-model.number="newListingForm.discountPercent" @input="recalcListingDiscount('percent')" min="0" max="90" placeholder="50"
                                                class="w-full px-3 py-2 bg-zinc-900 border border-amber-500/40 rounded-xl text-xs text-amber-300 font-mono font-bold focus:outline-none focus:border-amber-400">
                                            <span class="text-[9.5px] text-zinc-400 mt-0.5 block">Percentage off</span>
                                        </div>
                                    </div>

                                    <!-- Quick Discount Presets & Promo Badge -->
                                    <div class="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-white/10">
                                        <div class="flex items-center gap-1.5">
                                            <span class="text-[10px] text-zinc-400">Quick %:</span>
                                            <template x-for="p in [10, 20, 30, 40, 50, 70]" :key="p">
                                                <button type="button" @click="newListingForm.discountPercent = p; recalcListingDiscount('percent')"
                                                    class="px-2 py-0.5 rounded text-[10px] font-mono font-bold border transition-all"
                                                    :class="newListingForm.discountPercent === p ? 'bg-[#FF9500] text-black border-[#FF9500]' : 'bg-zinc-800 text-zinc-300 border-white/5 hover:border-orange-500/40'"
                                                    x-text="p + '%'">
                                                </button>
                                            </template>
                                        </div>

                                        <!-- Promo Tag Badge -->
                                        <div class="flex items-center gap-1.5 flex-1 sm:max-w-xs">
                                            <input type="text" x-model="newListingForm.promoBadge" placeholder="Promo Tag: e.g. 🔥 50% OFF"
                                                class="w-full px-2.5 py-1 bg-zinc-900 border border-white/10 rounded-lg text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                        </div>
                                    </div>
                                </div>

                                <!-- Dish Attributes: Calories, Prep Time, Food Dietary Custom Dropdown -->
                                <div class="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
                                    <div>
                                        <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Calories (kcal)</label>
                                        <input type="number" x-model.number="newListingForm.calories" placeholder="520"
                                            class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white font-mono focus:outline-none focus:border-[#FF9500]">
                                    </div>

                                    <div>
                                        <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Preparation Time</label>
                                        <input type="text" x-model="newListingForm.prepTime" placeholder="20-25 mins"
                                            class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                    </div>

                                    <!-- Custom Food Tag Dropdown -->
                                    <div class="relative" x-data="{ openTag: false, tags: ['🍗 Non-Veg / Meat', '🥗 Pure Vegetarian', '🌶️ Spicy Special', '✨ Signature Dish'] }">
                                        <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Food Type</label>
                                        <button type="button" @click="openTag = !openTag; $nextTick(() => lucide.createIcons())"
                                            class="w-full px-3 py-2 bg-zinc-900 border border-white/10 hover:border-orange-500/40 rounded-xl text-xs text-white flex items-center justify-between transition-colors focus:outline-none focus:border-[#FF9500]">
                                            <span x-text="newListingForm.foodTag"></span>
                                            <i data-lucide="chevron-down" class="w-3.5 h-3.5 text-[#FF9500] transition-transform" :class="openTag ? 'rotate-180' : ''"></i>
                                        </button>
                                        <div x-show="openTag" @click.outside="openTag = false" x-cloak
                                            class="absolute left-0 mt-1 w-full cupertino-glass rounded-xl p-1 shadow-2xl border border-white/10 z-50 space-y-0.5 text-xs">
                                            <template x-for="t in tags" :key="t">
                                                <button type="button" @click="newListingForm.foodTag = t; openTag = false"
                                                    class="w-full flex items-center justify-between px-3 py-1.5 rounded-lg text-left transition-colors hover:bg-orange-500/20"
                                                    :class="newListingForm.foodTag === t ? 'text-orange-400 font-bold bg-orange-500/10' : 'text-zinc-300'">
                                                    <span x-text="t"></span>
                                                    <i data-lucide="check" class="w-3.5 h-3.5 text-orange-400" x-show="newListingForm.foodTag === t"></i>
                                                </button>
                                            </template>
                                        </div>
                                    </div>
                                </div>

                                <!-- Image Upload & Link (Dual Capability) -->
                                <div class="p-3.5 rounded-2xl bg-zinc-900/80 border border-white/10 space-y-2.5">
                                    <div class="flex items-center justify-between">
                                        <span class="text-xs font-bold text-white flex items-center gap-1.5">
                                            <i data-lucide="image" class="w-4 h-4 text-[#FF9500]"></i>
                                            <span>Dish Image (File Upload OR Image Link)</span>
                                        </span>
                                        
                                        <!-- Dual Switcher -->
                                        <div class="inline-flex p-0.5 bg-zinc-950 rounded-lg border border-white/5">
                                            <button type="button" @click="addListingImageMode = 'file'"
                                                class="px-2.5 py-1 rounded-md text-[11px] font-semibold transition-all"
                                                :class="addListingImageMode === 'file' ? 'bg-[#FF9500] text-black font-bold' : 'text-zinc-400 hover:text-white'">
                                                📁 Upload File
                                            </button>
                                            <button type="button" @click="addListingImageMode = 'url'"
                                                class="px-2.5 py-1 rounded-md text-[11px] font-semibold transition-all"
                                                :class="addListingImageMode === 'url' ? 'bg-[#FF9500] text-black font-bold' : 'text-zinc-400 hover:text-white'">
                                                🔗 Image Link
                                            </button>
                                        </div>
                                    </div>

                                    <!-- Mode A: File Upload -->
                                    <div x-show="addListingImageMode === 'file'" class="space-y-1.5">
                                        <input type="file" accept="image/*" @change="handleListingImageUpload($event)" class="hidden" id="dish-file-upload">
                                        <label for="dish-file-upload" class="cursor-pointer border-2 border-dashed border-white/15 hover:border-orange-500/60 rounded-xl p-4 flex flex-col items-center justify-center text-center transition-all bg-white/[0.02] hover:bg-orange-500/[0.05]">
                                            <template x-if="!uploadingListingImage">
                                                <div class="space-y-1">
                                                    <div class="w-10 h-10 rounded-xl bg-orange-500/15 text-[#FF9500] flex items-center justify-center text-lg mx-auto">
                                                        📤
                                                    </div>
                                                    <p class="text-xs font-bold text-white">Click or drag &amp; drop to upload image file</p>
                                                    <p class="text-[10px] text-zinc-400">Directly saves to server storage (uploads/ folder) with public URL</p>
                                                </div>
                                            </template>
                                            <template x-if="uploadingListingImage">
                                                <div class="flex items-center gap-2 py-3 text-xs font-bold text-orange-400">
                                                    <div class="w-4 h-4 border-2 border-orange-400 border-t-transparent rounded-full animate-spin"></div>
                                                    <span>Uploading image to server disk...</span>
                                                </div>
                                            </template>
                                        </label>
                                    </div>

                                    <!-- Mode B: Direct Image URL -->
                                    <div x-show="addListingImageMode === 'url'" class="space-y-1">
                                        <input type="url" x-model="newListingForm.imageUrl" placeholder="https://images.unsplash.com/... or base URL"
                                            class="w-full px-3 py-2 bg-zinc-950 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                        <p class="text-[10px] text-zinc-400">Provide direct external CDN image URL or relative server path.</p>
                                    </div>
                                </div>

                                <!-- Form Submit Buttons -->
                                <div class="pt-2 flex flex-wrap items-center justify-end gap-2 border-t border-white/5">
                                    <button type="button" @click="foodListingMode = 'list'"
                                        class="px-4 py-2 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 hover:text-white rounded-xl text-xs font-semibold transition-all">
                                        Cancel
                                    </button>
                                    <button type="button" @click="resetNewListingForm('restaurant')"
                                        class="px-4 py-2 bg-zinc-900 hover:bg-zinc-800 text-zinc-400 hover:text-white rounded-xl text-xs font-semibold border border-white/5 transition-all">
                                        Reset Form
                                    </button>
                                    <button type="submit" :disabled="loading"
                                        class="px-5 py-2 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-black font-black rounded-xl text-xs shadow-md transition-all active:scale-95 flex items-center gap-1.5">
                                        <i data-lucide="check" class="w-4 h-4 text-black"></i>
                                        <span>Publish Restaurant Dish</span>
                                    </button>
                                </div>
                            </form>
                        </div>

                        <!-- Live Customer App Card Preview (4 Columns) -->
                        <div class="lg:col-span-4 space-y-3">
                            <div class="p-3 cupertino-card rounded-2xl border border-white/5">
                                <span class="text-[10px] uppercase font-bold text-zinc-400 tracking-wider flex items-center gap-1 mb-2">
                                    <i data-lucide="smartphone" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                    <span>Live Customer App Preview</span>
                                </span>

                                <!-- Mock Card -->
                                <div class="rounded-2xl overflow-hidden bg-zinc-900 border border-white/10 shadow-lg">
                                    <div class="relative h-40 bg-zinc-950 overflow-hidden">
                                        <img :src="newListingForm.imageUrl || 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&q=80'"
                                            class="w-full h-full object-cover" alt="preview">
                                        
                                        <!-- Promo Badge Overlay -->
                                        <div class="absolute top-2 left-2 flex flex-col gap-1">
                                            <span x-show="newListingForm.promoBadge" class="px-2 py-0.5 rounded-full text-[10px] font-black uppercase bg-red-500 text-white shadow-md"
                                                x-text="newListingForm.promoBadge">
                                            </span>
                                            <span class="px-2 py-0.5 rounded-full text-[9px] font-bold bg-black/70 backdrop-blur-sm text-zinc-200"
                                                x-text="newListingForm.foodTag">
                                            </span>
                                        </div>

                                        <div class="absolute top-2 right-2 px-2 py-0.5 rounded-full text-[10px] font-bold bg-black/60 backdrop-blur-sm text-amber-400">
                                            ⭐ 4.8
                                        </div>
                                    </div>

                                    <div class="p-3.5 space-y-2">
                                        <div class="flex items-start justify-between gap-2">
                                            <div>
                                                <span class="text-[9px] uppercase font-bold text-[#FF9500]" x-text="newListingForm.category"></span>
                                                <h5 class="text-sm font-bold text-white line-clamp-1" x-text="newListingForm.name || 'Dish Name Preview'"></h5>
                                            </div>
                                        </div>

                                        <p class="text-[11px] text-zinc-400 line-clamp-2" x-text="newListingForm.description || 'Detailed taste and serving description will appear here...'"></p>

                                        <!-- Pricing display -->
                                        <div class="pt-2 border-t border-white/5 flex items-baseline justify-between">
                                            <div class="flex items-baseline gap-1.5">
                                                <span class="text-base font-black text-[#FF9500] tabular-nums" x-text="'Rs. ' + (newListingForm.actualPrice || 0)"></span>
                                                <template x-if="newListingForm.showCutPrice && newListingForm.cutPrice > newListingForm.actualPrice">
                                                    <span class="text-xs line-through text-zinc-500 tabular-nums" x-text="'Rs. ' + newListingForm.cutPrice"></span>
                                                </template>
                                                <template x-if="newListingForm.showCutPrice && newListingForm.discountPercent > 0">
                                                    <span class="px-1.5 py-0.2 rounded text-[8.5px] font-black bg-emerald-500/20 text-emerald-400 border border-emerald-500/30"
                                                        x-text="newListingForm.discountPercent + '% OFF'">
                                                    </span>
                                                </template>
                                            </div>
                                            <span class="text-[10px] text-zinc-400 font-mono" x-text="newListingForm.prepTime"></span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                    </div>

                    <!-- STEP 2B: PAKWAN CENTER DAIG FORM & LIVE PREVIEW (Shown when addListingType === 'pakwan') -->
                    <div x-show="addListingType === 'pakwan'" class="grid grid-cols-1 lg:grid-cols-12 gap-4">
                        
                        <!-- Form Fields (8 Columns) -->
                        <div class="lg:col-span-8 p-4 rounded-2xl cupertino-card border border-white/5 space-y-3.5">
                            <div class="flex items-center justify-between pb-2.5 border-b border-white/5">
                                <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                    <span class="text-amber-400">👑</span>
                                    <span>Shahi Pakwan Catering Daig Information &amp; Pricing</span>
                                </h4>
                                <span class="text-[10px] text-zinc-400">* Required inputs</span>
                            </div>

                            <form @submit.prevent="submitNewListing()" class="space-y-3.5">
                                
                                <!-- English Title & Urdu Name -->
                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                    <div>
                                        <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Daig Title (English) *</label>
                                        <input type="text" x-model="newListingForm.name" required placeholder="e.g. Royal Zafrani Beef Degi Biryani"
                                            class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500] placeholder-zinc-500">
                                    </div>

                                    <div>
                                        <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Urdu / Regional Name</label>
                                        <input type="text" x-model="newListingForm.urduName" placeholder="e.g. شاہی زعفرانی بیف دیگی بریانی"
                                            class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500] placeholder-zinc-500 text-right font-medium">
                                    </div>
                                </div>

                                <!-- Pakwan Center Location & Category Custom Dropdown -->
                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                    
                                    <!-- Pakwan Center Kitchen Location (Custom Dropdown + Input) -->
                                    <div class="relative" x-data="{ openLoc: false, locations: ['Main Pakwan Kitchen, Islamabad (G-9 Markaz)', 'Rawalpindi Saddar Catering Hub', 'Lahore Gulberg Pakwan Hub', 'Blue Area Catering Branch, Islamabad', 'Custom Kitchen Location'] }">
                                        <label class="block text-[11px] font-semibold text-amber-300 mb-1">Pakwan Center Location *</label>
                                        <button type="button" @click="openLoc = !openLoc; $nextTick(() => lucide.createIcons())"
                                            class="w-full px-3 py-2 bg-zinc-900 border border-amber-500/30 hover:border-amber-400 rounded-xl text-xs text-white flex items-center justify-between transition-colors focus:outline-none focus:border-amber-400">
                                            <span class="truncate" x-text="newListingForm.location"></span>
                                            <i data-lucide="chevron-down" class="w-4 h-4 text-amber-400 transition-transform shrink-0" :class="openLoc ? 'rotate-180' : ''"></i>
                                        </button>
                                        <div x-show="openLoc" @click.outside="openLoc = false" x-cloak
                                            class="absolute left-0 mt-1 w-full max-h-52 overflow-y-auto cupertino-glass rounded-xl p-1 shadow-2xl border border-white/10 z-50 space-y-0.5 text-xs">
                                            <template x-for="loc in locations" :key="loc">
                                                <button type="button" @click="newListingForm.location = (loc === 'Custom Kitchen Location' ? '' : loc); openLoc = false"
                                                    class="w-full flex items-center justify-between px-3 py-2 rounded-lg text-left transition-colors hover:bg-amber-500/20"
                                                    :class="newListingForm.location === loc ? 'text-amber-400 font-bold bg-amber-500/10' : 'text-zinc-300'">
                                                    <span x-text="loc"></span>
                                                    <i data-lucide="check" class="w-3.5 h-3.5 text-amber-400" x-show="newListingForm.location === loc"></i>
                                                </button>
                                            </template>
                                        </div>
                                        <!-- Editable Address Field for exact accuracy -->
                                        <input type="text" x-model="newListingForm.location" placeholder="Or type exact kitchen address..."
                                            class="mt-1.5 w-full px-2.5 py-1.5 bg-zinc-950 border border-white/5 rounded-lg text-[11px] text-zinc-300 focus:outline-none focus:border-amber-400">
                                    </div>

                                    <!-- Custom Pakwan Category Dropdown -->
                                    <div class="relative" x-data="{ openPakCat: false, pCategories: ['Shahi Biryani & Pulao', 'Shahi Qorma & Degi Salan', 'Degi Haleem & Nihari', 'Shahi Sweet Zarda & Mutanjan', 'Kheer & Firni Catering'] }">
                                        <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Daig Category *</label>
                                        <button type="button" @click="openPakCat = !openPakCat; $nextTick(() => lucide.createIcons())"
                                            class="w-full px-3 py-2 bg-zinc-900 border border-white/10 hover:border-amber-400/40 rounded-xl text-xs text-white flex items-center justify-between transition-colors focus:outline-none focus:border-amber-400">
                                            <span x-text="newListingForm.pakwanCategory"></span>
                                            <i data-lucide="chevron-down" class="w-4 h-4 text-amber-400 transition-transform" :class="openPakCat ? 'rotate-180' : ''"></i>
                                        </button>
                                        <div x-show="openPakCat" @click.outside="openPakCat = false" x-cloak
                                            class="absolute left-0 mt-1 w-full max-h-52 overflow-y-auto cupertino-glass rounded-xl p-1 shadow-2xl border border-white/10 z-50 space-y-0.5 text-xs">
                                            <template x-for="pcat in pCategories" :key="pcat">
                                                <button type="button" @click="newListingForm.pakwanCategory = pcat; openPakCat = false"
                                                    class="w-full flex items-center justify-between px-3 py-2 rounded-lg text-left transition-colors hover:bg-amber-500/20"
                                                    :class="newListingForm.pakwanCategory === pcat ? 'text-amber-400 font-bold bg-amber-500/10' : 'text-zinc-300'">
                                                    <span x-text="pcat"></span>
                                                    <i data-lucide="check" class="w-3.5 h-3.5 text-amber-400" x-show="newListingForm.pakwanCategory === pcat"></i>
                                                </button>
                                            </template>
                                        </div>
                                    </div>
                                </div>

                                <!-- Daig Description & Advance Notice -->
                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                    <div>
                                        <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Daig Description &amp; Spices</label>
                                        <textarea x-model="newListingForm.description" rows="2" placeholder="Authentic slow-cooked deg prepared in pure desi ghee, saffron aroma, tender marinated meat..."
                                            class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-amber-400 placeholder-zinc-500"></textarea>
                                    </div>

                                    <div>
                                        <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Advance Delivery Notice</label>
                                        <input type="text" x-model="newListingForm.deliveryNotice" placeholder="e.g. Order 3-4 hours in advance"
                                            class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-amber-400 placeholder-zinc-500">
                                        <div class="mt-1 flex flex-wrap gap-1">
                                            <template x-for="notc in ['Order 3-4 hours in advance', 'Order 6-8 hours in advance', '24 hours notice for weddings']" :key="notc">
                                                <button type="button" @click="newListingForm.deliveryNotice = notc"
                                                    class="px-2 py-0.5 rounded text-[9.5px] bg-zinc-800 text-zinc-400 hover:text-white" x-text="notc">
                                                </button>
                                            </template>
                                        </div>
                                    </div>
                                </div>

                                <!-- Daig Pricing, Weights & Cut Price Box -->
                                <div class="p-3.5 rounded-2xl bg-amber-500/10 border border-amber-500/30 space-y-3">
                                    <div class="flex items-center justify-between">
                                        <span class="text-xs font-bold text-white flex items-center gap-1.5">
                                            <span class="text-amber-400">👑</span>
                                            <span>Full &amp; Half Daig Pricing, Cut Price &amp; Weights</span>
                                        </span>
                                        <label class="flex items-center gap-2 cursor-pointer select-none">
                                            <input type="checkbox" x-model="newListingForm.showCutPrice" class="w-4 h-4 rounded bg-zinc-800 text-amber-400 border-white/20 focus:ring-0">
                                            <span class="text-[11px] font-bold text-amber-400">Show Cut Price on App</span>
                                        </label>
                                    </div>

                                    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-2.5">
                                        <!-- Full Daig Price -->
                                        <div>
                                            <label class="block text-[10px] font-bold uppercase tracking-wider text-emerald-400 mb-1">Full Daig Price (Rs.) *</label>
                                            <input type="number" x-model.number="newListingForm.fullDaigPrice" @input="recalcListingDiscount('actual')" required min="1000" placeholder="16000"
                                                class="w-full px-3 py-2 bg-zinc-900 border border-emerald-500/40 rounded-xl text-xs text-emerald-400 font-mono font-bold focus:outline-none focus:border-emerald-400">
                                        </div>

                                        <!-- Full Daig Weight/Servings -->
                                        <div>
                                            <label class="block text-[10px] font-bold uppercase tracking-wider text-zinc-300 mb-1">Full Daig Weight</label>
                                            <input type="text" x-model="newListingForm.fullDaigWeight" placeholder="12 KG (Serves 35-40)"
                                                class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-amber-400">
                                        </div>

                                        <!-- Half Daig Price -->
                                        <div>
                                            <label class="block text-[10px] font-bold uppercase tracking-wider text-emerald-400 mb-1">Half Daig Price (Rs.) *</label>
                                            <input type="number" x-model.number="newListingForm.halfDaigPrice" required min="500" placeholder="8500"
                                                class="w-full px-3 py-2 bg-zinc-900 border border-emerald-500/40 rounded-xl text-xs text-emerald-400 font-mono font-bold focus:outline-none focus:border-emerald-400">
                                        </div>

                                        <!-- Half Daig Weight/Servings -->
                                        <div>
                                            <label class="block text-[10px] font-bold uppercase tracking-wider text-zinc-300 mb-1">Half Daig Weight</label>
                                            <input type="text" x-model="newListingForm.halfDaigWeight" placeholder="6 KG (Serves 18-20)"
                                                class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-amber-400">
                                        </div>
                                    </div>

                                    <!-- Cut Price & Discount Row -->
                                    <div class="grid grid-cols-1 sm:grid-cols-3 gap-2.5 pt-2 border-t border-white/10">
                                        <div>
                                            <label class="block text-[10px] font-bold uppercase tracking-wider text-zinc-300 mb-1">Original Cut Price (Rs.)</label>
                                            <input type="number" x-model.number="newListingForm.cutPrice" @input="recalcListingDiscount('cut')" min="1000" placeholder="20000"
                                                class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white font-mono focus:outline-none focus:border-amber-400">
                                        </div>

                                        <div>
                                            <label class="block text-[10px] font-bold uppercase tracking-wider text-amber-400 mb-1">Discount (% OFF)</label>
                                            <input type="number" x-model.number="newListingForm.discountPercent" @input="recalcListingDiscount('percent')" min="0" max="70" placeholder="20"
                                                class="w-full px-3 py-1.5 bg-zinc-900 border border-amber-500/40 rounded-xl text-xs text-amber-300 font-mono font-bold focus:outline-none focus:border-amber-400">
                                        </div>

                                        <div>
                                            <label class="block text-[10px] font-bold uppercase tracking-wider text-zinc-300 mb-1">Promo Badge</label>
                                            <input type="text" x-model="newListingForm.promoBadge" placeholder="SPECIAL SHAHI DEG"
                                                class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-amber-400">
                                        </div>
                                    </div>
                                </div>

                                <!-- Image Upload & Link (Dual Capability) -->
                                <div class="p-3.5 rounded-2xl bg-zinc-900/80 border border-white/10 space-y-2.5">
                                    <div class="flex items-center justify-between">
                                        <span class="text-xs font-bold text-white flex items-center gap-1.5">
                                            <i data-lucide="image" class="w-4 h-4 text-amber-400"></i>
                                            <span>Daig Image (File Upload OR Image Link)</span>
                                        </span>
                                        
                                        <div class="inline-flex p-0.5 bg-zinc-950 rounded-lg border border-white/5">
                                            <button type="button" @click="addListingImageMode = 'file'"
                                                class="px-2.5 py-1 rounded-md text-[11px] font-semibold transition-all"
                                                :class="addListingImageMode === 'file' ? 'bg-amber-400 text-black font-bold' : 'text-zinc-400 hover:text-white'">
                                                📁 Upload File
                                            </button>
                                            <button type="button" @click="addListingImageMode = 'url'"
                                                class="px-2.5 py-1 rounded-md text-[11px] font-semibold transition-all"
                                                :class="addListingImageMode === 'url' ? 'bg-amber-400 text-black font-bold' : 'text-zinc-400 hover:text-white'">
                                                🔗 Image Link
                                            </button>
                                        </div>
                                    </div>

                                    <!-- Mode A: File Upload -->
                                    <div x-show="addListingImageMode === 'file'" class="space-y-1.5">
                                        <input type="file" accept="image/*" @change="handleListingImageUpload($event)" class="hidden" id="daig-file-upload">
                                        <label for="daig-file-upload" class="cursor-pointer border-2 border-dashed border-white/15 hover:border-amber-400/60 rounded-xl p-4 flex flex-col items-center justify-center text-center transition-all bg-white/[0.02] hover:bg-amber-500/[0.05]">
                                            <template x-if="!uploadingListingImage">
                                                <div class="space-y-1">
                                                    <div class="w-10 h-10 rounded-xl bg-amber-500/15 text-amber-400 flex items-center justify-center text-lg mx-auto">
                                                        👑
                                                    </div>
                                                    <p class="text-xs font-bold text-white">Click or drag &amp; drop to upload Daig image file</p>
                                                    <p class="text-[10px] text-zinc-400">Saves directly to server storage (uploads/ folder) with public URL</p>
                                                </div>
                                            </template>
                                            <template x-if="uploadingListingImage">
                                                <div class="flex items-center gap-2 py-3 text-xs font-bold text-amber-400">
                                                    <div class="w-4 h-4 border-2 border-amber-400 border-t-transparent rounded-full animate-spin"></div>
                                                    <span>Uploading image to server disk...</span>
                                                </div>
                                            </template>
                                        </label>
                                    </div>

                                    <!-- Mode B: Direct Image URL -->
                                    <div x-show="addListingImageMode === 'url'" class="space-y-1">
                                        <input type="url" x-model="newListingForm.imageUrl" placeholder="https://images.unsplash.com/... or relative base URL"
                                            class="w-full px-3 py-2 bg-zinc-950 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-amber-400">
                                        <p class="text-[10px] text-zinc-400">Provide direct external CDN image URL or relative server path.</p>
                                    </div>
                                </div>

                                <!-- Form Submit Buttons -->
                                <div class="pt-2 flex flex-wrap items-center justify-end gap-2 border-t border-white/5">
                                    <button type="button" @click="foodListingMode = 'list'"
                                        class="px-4 py-2 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 hover:text-white rounded-xl text-xs font-semibold transition-all">
                                        Cancel
                                    </button>
                                    <button type="button" @click="resetNewListingForm('pakwan')"
                                        class="px-4 py-2 bg-zinc-900 hover:bg-zinc-800 text-zinc-400 hover:text-white rounded-xl text-xs font-semibold border border-white/5 transition-all">
                                        Reset Form
                                    </button>
                                    <button type="submit" :disabled="loading"
                                        class="px-5 py-2 bg-gradient-to-r from-amber-400 to-yellow-500 hover:from-amber-300 hover:to-yellow-400 text-black font-black rounded-xl text-xs shadow-md transition-all active:scale-95 flex items-center gap-1.5">
                                        <i data-lucide="check" class="w-4 h-4 text-black"></i>
                                        <span>Publish Shahi Daig</span>
                                    </button>
                                </div>
                            </form>
                        </div>

                        <!-- Live Customer App Daig Card Preview (4 Columns) -->
                        <div class="lg:col-span-4 space-y-3">
                            <div class="p-3 cupertino-card rounded-2xl border border-white/5">
                                <span class="text-[10px] uppercase font-bold text-amber-400 tracking-wider flex items-center gap-1 mb-2">
                                    <i data-lucide="smartphone" class="w-3.5 h-3.5 text-amber-400"></i>
                                    <span>Pakwan Customer App Preview</span>
                                </span>

                                <!-- Mock Daig Card -->
                                <div class="rounded-2xl overflow-hidden bg-zinc-900 border border-amber-500/20 shadow-lg">
                                    <div class="relative h-44 bg-zinc-950 overflow-hidden">
                                        <img :src="newListingForm.imageUrl || 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80'"
                                            class="w-full h-full object-cover" alt="preview">
                                        
                                        <!-- Badges Overlay -->
                                        <div class="absolute top-2 left-2 flex flex-col gap-1">
                                            <span class="px-2 py-0.5 rounded-full text-[9px] font-black uppercase bg-amber-500 text-black shadow-md flex items-center gap-1">
                                                <span>👑</span>
                                                <span x-text="newListingForm.promoBadge || 'SHAHI CATERING'"></span>
                                            </span>
                                            <span class="px-2 py-0.5 rounded-full text-[8.5px] font-semibold bg-black/70 backdrop-blur-sm text-zinc-300"
                                                x-text="newListingForm.pakwanCategory">
                                            </span>
                                        </div>

                                        <div class="absolute bottom-2 left-2 right-2 px-2 py-1 rounded-lg text-[9.5px] font-semibold bg-black/80 backdrop-blur-sm text-amber-300 truncate">
                                            📍 <span x-text="newListingForm.location || 'Pakwan Kitchen Location'"></span>
                                        </div>
                                    </div>

                                    <div class="p-3.5 space-y-2">
                                        <div>
                                            <h5 class="text-sm font-bold text-white line-clamp-1" x-text="newListingForm.name || 'Shahi Daig Title Preview'"></h5>
                                            <p class="text-xs text-amber-300/90 font-medium text-right line-clamp-1" x-text="newListingForm.urduName || 'شاہی دیغ نام'"></p>
                                        </div>

                                        <p class="text-[11px] text-zinc-400 line-clamp-2" x-text="newListingForm.description || 'Authentic slow-cooked saffron daig description will appear here...'"></p>

                                        <!-- Prices Comparison -->
                                        <div class="pt-2 border-t border-white/5 space-y-1.5">
                                            <div class="flex items-center justify-between text-xs">
                                                <span class="text-zinc-400 text-[10.5px]">Full Daig (12 KG):</span>
                                                <div class="flex items-baseline gap-1.5">
                                                    <span class="font-black text-[#FF9500] text-sm tabular-nums" x-text="'Rs. ' + (newListingForm.fullDaigPrice || 0)"></span>
                                                    <template x-if="newListingForm.showCutPrice && newListingForm.cutPrice > newListingForm.fullDaigPrice">
                                                        <span class="text-[10.5px] line-through text-zinc-500 tabular-nums" x-text="'Rs. ' + newListingForm.cutPrice"></span>
                                                    </template>
                                                </div>
                                            </div>

                                            <div class="flex items-center justify-between text-xs">
                                                <span class="text-zinc-400 text-[10.5px]">Half Daig (6 KG):</span>
                                                <span class="font-bold text-white text-xs tabular-nums" x-text="'Rs. ' + (newListingForm.halfDaigPrice || 0)"></span>
                                            </div>

                                            <div class="pt-1 flex items-center justify-between text-[10px] text-amber-400">
                                                <span class="flex items-center gap-1">
                                                    <i data-lucide="clock" class="w-3 h-3"></i>
                                                    <span x-text="newListingForm.deliveryNotice"></span>
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                    </div>

                </div>

                <!-- =========================================================== -->
                <!-- VIEW 2: ALL MENU LISTINGS (TABLES FOR DISHES & DAIGS)        -->
                <!-- =========================================================== -->
                <div x-show="foodListingMode === 'list'" class="space-y-3">
                    
                    <!-- Sub-Tabs Switcher & Actions Bar -->
                    <div class="p-3 cupertino-card rounded-2xl flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-2.5">
                        
                        <!-- Sub-tabs: Dishes vs Daigs -->
                        <div class="inline-flex p-1 bg-zinc-900 rounded-xl border border-white/5">
                            <button type="button" @click="foodListingSection = 'dishes'"
                                class="px-3 py-1.5 rounded-lg text-xs font-bold transition-all"
                                :class="foodListingSection === 'dishes' ? 'bg-[#FF9500] text-black shadow-sm' : 'text-zinc-400 hover:text-white'">
                                <span>🍽️ Restaurant Dishes</span>
                                <span class="ml-1 text-[10px] opacity-75 font-mono" x-text="'(' + vendorFoodItems.length + ')'"></span>
                            </button>
                            <button type="button" @click="foodListingSection = 'daigs'"
                                class="px-3 py-1.5 rounded-lg text-xs font-bold transition-all"
                                :class="foodListingSection === 'daigs' ? 'bg-[#FF9500] text-black shadow-sm' : 'text-zinc-400 hover:text-white'">
                                <span>👑 Shahi Pakwan Daigs</span>
                                <span class="ml-1 text-[10px] opacity-75 font-mono" x-text="'(' + vendorDaigItems.length + ')'"></span>
                            </button>
                        </div>

                        <!-- Search, Category Filter & Upload Buttons -->
                        <div class="flex flex-wrap items-center gap-2">
                            <!-- Custom Dish Category Filter Dropdown -->
                            <div class="relative" x-show="foodListingSection === 'dishes'" x-data="{ openCatFilter: false }">
                                <button type="button" @click="openCatFilter = !openCatFilter; $nextTick(() => lucide.createIcons())"
                                    class="px-2.5 py-1.5 bg-zinc-900 hover:bg-zinc-800 border border-white/10 hover:border-orange-500/30 rounded-xl text-xs text-white flex items-center gap-1.5 transition-all">
                                    <span x-text="foodCategoryFilter === 'All' ? 'All Dish Categories' : foodCategoryFilter"></span>
                                    <i data-lucide="chevron-down" class="w-3 h-3 text-[#FF9500] transition-transform" :class="openCatFilter ? 'rotate-180' : ''"></i>
                                </button>
                                <div x-show="openCatFilter" @click.outside="openCatFilter = false" x-cloak
                                    class="absolute left-0 mt-1 w-48 cupertino-glass rounded-xl p-1 shadow-2xl border border-white/10 z-50 space-y-0.5 text-xs">
                                    <template x-for="cat in ['All', 'Biryani', 'Karahi & Handi', 'BBQ & Grill', 'Burgers', 'Desi Gravy', 'Desserts', 'Beverages']" :key="cat">
                                        <button type="button" @click="foodCategoryFilter = cat; foodPage = 1; openCatFilter = false"
                                            class="w-full flex items-center justify-between px-2.5 py-1.5 rounded-lg text-left transition-colors hover:bg-orange-500/20"
                                            :class="foodCategoryFilter === cat ? 'text-orange-400 font-bold bg-orange-500/10' : 'text-zinc-300'">
                                            <span x-text="cat === 'All' ? 'All Dish Categories' : cat"></span>
                                            <i data-lucide="check" class="w-3 h-3 text-orange-400" x-show="foodCategoryFilter === cat"></i>
                                        </button>
                                    </template>
                                </div>
                            </div>

                            <input type="text" x-model="menuSearchQuery" placeholder="Search dish / daig by name..."
                                class="px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white placeholder-zinc-500 focus:outline-none focus:border-[#FF9500] w-44 sm:w-52">

                            <button type="button" x-show="foodListingSection === 'dishes'" @click="openAddListingPage('restaurant')"
                                class="px-3 py-1.5 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-black font-bold rounded-xl text-xs flex items-center gap-1 shadow-sm transition-all active:scale-95">
                                <i data-lucide="plus" class="w-3.5 h-3.5 text-black"></i>
                                <span>Upload Dish</span>
                            </button>

                            <button type="button" x-show="foodListingSection === 'daigs'" @click="openAddListingPage('pakwan')"
                                class="px-3 py-1.5 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-black font-bold rounded-xl text-xs flex items-center gap-1 shadow-sm transition-all active:scale-95">
                                <i data-lucide="plus" class="w-3.5 h-3.5 text-black"></i>
                                <span>Upload Daig</span>
                            </button>
                        </div>
                    </div>

                <!-- SECTION A: RESTAURANT DISHES TABLE -->
                <div x-show="foodListingSection === 'dishes'" class="cupertino-card rounded-2xl overflow-hidden shadow-sm">
                    <div class="overflow-x-auto">
                        <table class="w-full text-left text-xs">
                            <thead class="bg-zinc-950/70 text-zinc-400 uppercase font-semibold text-[9.5px] border-b border-white/5">
                                <tr>
                                    <th class="py-2.5 px-3">Dish Info</th>
                                    <th class="py-2.5 px-3">Category</th>
                                    <th class="py-2.5 px-3">Price & Active Promo Offer</th>
                                    <th class="py-2.5 px-3 text-center">Rating</th>
                                    <th class="py-2.5 px-3 text-center">Calories</th>
                                    <th class="py-2.5 px-3">Availability</th>
                                    <th class="py-2.5 px-3 text-right">Actions</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-white/5 font-medium text-zinc-300">
                                <template x-for="item in paginatedFoodItems" :key="item.id">
                                    <tr class="hover:bg-zinc-800/40 transition-colors">
                                        <td class="py-2.5 px-3">
                                            <div class="flex items-center gap-2.5">
                                                <img :src="item.imageUrl || 'https://images.unsplash.com/photo-1544025162-d76694265947?w=120&q=80'"
                                                    class="w-10 h-10 rounded-xl object-cover border border-white/10 shrink-0" alt="dish">
                                                <div class="min-w-0">
                                                    <p class="font-bold text-white text-xs truncate max-w-[170px]" x-text="item.name"></p>
                                                    <p class="text-[10px] text-zinc-400 truncate max-w-[200px]" x-text="item.description"></p>
                                                </div>
                                            </div>
                                        </td>

                                        <td class="py-2.5 px-3">
                                            <span class="px-2 py-0.5 rounded text-[10px] font-semibold bg-zinc-800 text-zinc-300" x-text="item.category"></span>
                                        </td>

                                        <td class="py-2.5 px-3 whitespace-nowrap">
                                            <div class="flex items-center gap-1.5">
                                                <!-- If Discounted -->
                                                <template x-if="item.isDiscounted">
                                                    <div class="flex items-baseline gap-1.5">
                                                        <span class="font-black text-[#FF9500] text-xs tabular-nums" x-text="'Rs. ' + (item.discountPrice || (item.price * 0.5))"></span>
                                                        <span class="line-through text-zinc-500 text-[10.5px] tabular-nums" x-text="'Rs. ' + item.price"></span>
                                                        <span class="px-1.5 py-0.2 rounded text-[8.5px] font-black uppercase bg-red-500/20 text-red-400 border border-red-500/30"
                                                            x-text="item.promoBadge || (item.discountPercent ? item.discountPercent + '% OFF' : '50% OFF')">
                                                        </span>
                                                    </div>
                                                </template>
                                                <!-- Standard Price -->
                                                <template x-if="!item.isDiscounted">
                                                    <span class="font-black text-white text-xs tabular-nums" x-text="'Rs. ' + item.price"></span>
                                                </template>
                                            </div>
                                        </td>

                                        <td class="py-2.5 px-3 text-center">
                                            <span class="text-amber-400 font-bold text-xs" x-text="'⭐ ' + (item.rating || 4.8)"></span>
                                        </td>

                                        <td class="py-2.5 px-3 text-center font-mono text-[11px] text-zinc-400" x-text="(item.calories || 500) + ' kcal'"></td>

                                        <td class="py-2.5 px-3 whitespace-nowrap">
                                            <button type="button" @click="toggleFoodAvailability(item)"
                                                class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider transition-all shadow-sm active:scale-95"
                                                :class="item.isVisible ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/40 hover:bg-emerald-500/30' : 'bg-red-500/20 text-red-400 border border-red-500/40 hover:bg-red-500/30'">
                                                <span class="w-2 h-2 rounded-full" :class="item.isVisible ? 'bg-emerald-400 animate-pulse' : 'bg-red-400'"></span>
                                                <span x-text="item.isVisible ? 'In Stock' : 'Out of Stock'"></span>
                                            </button>
                                        </td>

                                        <td class="py-2.5 px-3 text-right whitespace-nowrap">
                                            <div class="inline-flex items-center gap-1">
                                                <button type="button" @click="previewItem(item, 'dish')" class="p-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 rounded-lg" title="Preview Dish">
                                                    <i data-lucide="eye" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                                </button>
                                                <button type="button" @click="openEditFoodModal(item)" class="p-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 rounded-lg" title="Edit Dish & Discount">
                                                    <i data-lucide="edit" class="w-3.5 h-3.5 text-sky-400"></i>
                                                </button>
                                                <button type="button" @click="confirmDeleteFood(item)" class="p-1.5 bg-red-950/40 hover:bg-red-900/60 text-red-400 rounded-lg" title="Delete Dish">
                                                    <i data-lucide="trash-2" class="w-3.5 h-3.5"></i>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </template>
                                <template x-if="paginatedFoodItems.length === 0">
                                    <tr>
                                        <td colspan="7" class="text-center py-8 text-zinc-500 italic">No food items found. Click "+ Upload Dish" to add one.</td>
                                    </tr>
                                </template>
                            </tbody>
                        </table>
                    </div>

                    <!-- Pagination Controls -->
                    <div class="px-3.5 py-2.5 border-t border-white/5 flex flex-wrap items-center justify-between gap-2 text-xs text-zinc-400">
                        <div class="flex items-center gap-3">
                            <span x-text="'Showing ' + paginatedFoodItems.length + ' of ' + filteredFoodItems.length + ' dishes (Page ' + foodPage + ')'"></span>
                            <!-- Custom Dishes Per Page Dropdown -->
                            <div class="relative flex items-center gap-1.5 text-xs text-zinc-400" x-data="{ openFoodPage: false }">
                                <span>Per page:</span>
                                <button type="button" @click="openFoodPage = !openFoodPage; $nextTick(() => lucide.createIcons())"
                                    class="px-2 py-0.5 bg-zinc-900 hover:bg-zinc-800 border border-white/10 hover:border-orange-500/30 rounded-lg text-xs text-white flex items-center gap-1 transition-all">
                                    <span x-text="foodPerPage"></span>
                                    <i data-lucide="chevron-down" class="w-3 h-3 text-[#FF9500] transition-transform" :class="openFoodPage ? 'rotate-180' : ''"></i>
                                </button>
                                <div x-show="openFoodPage" @click.outside="openFoodPage = false" x-cloak
                                    class="absolute left-0 bottom-full mb-1 w-20 cupertino-glass rounded-xl p-1 shadow-2xl border border-white/10 z-50 space-y-0.5 text-xs">
                                    <template x-for="n in [10, 25, 50, 100]" :key="n">
                                        <button type="button" @click="foodPerPage = n; foodPage = 1; openFoodPage = false"
                                            class="w-full flex items-center justify-between px-2 py-1 rounded-lg text-left transition-colors hover:bg-orange-500/20"
                                            :class="foodPerPage === n ? 'text-orange-400 font-bold bg-orange-500/10' : 'text-zinc-300'">
                                            <span x-text="n"></span>
                                            <i data-lucide="check" class="w-3 h-3 text-orange-400" x-show="foodPerPage === n"></i>
                                        </button>
                                    </template>
                                </div>
                            </div>
                        </div>
                        <div class="flex items-center gap-1.5">
                            <button type="button" @click="foodPage = Math.max(1, foodPage - 1)" :disabled="foodPage <= 1"
                                class="px-2.5 py-1 bg-zinc-900 disabled:opacity-40 rounded-lg text-xs font-semibold hover:text-white">Previous</button>
                            <span class="px-2 text-xs font-mono font-bold text-white" x-text="foodPage"></span>
                            <button type="button" @click="foodPage = foodPage + 1" :disabled="foodPage * foodPerPage >= filteredFoodItems.length"
                                class="px-2.5 py-1 bg-zinc-900 disabled:opacity-40 rounded-lg text-xs font-semibold hover:text-white">Next</button>
                        </div>
                    </div>
                </div>

                <!-- SECTION B: SHAHI PAKWAN DAIGS TABLE -->
                <div x-show="foodListingSection === 'daigs'" class="cupertino-card rounded-2xl overflow-hidden shadow-sm">
                    <div class="overflow-x-auto">
                        <table class="w-full text-left text-xs">
                            <thead class="bg-zinc-950/70 text-zinc-400 uppercase font-semibold text-[9.5px] border-b border-white/5">
                                <tr>
                                    <th class="py-2.5 px-3">Shahi Daig Info</th>
                                    <th class="py-2.5 px-3">Urdu Name</th>
                                    <th class="py-2.5 px-3">12KG Full Daig Price</th>
                                    <th class="py-2.5 px-3">6KG Half Daig Price</th>
                                    <th class="py-2.5 px-3">Active Promo Tag</th>
                                    <th class="py-2.5 px-3">Availability</th>
                                    <th class="py-2.5 px-3 text-right">Actions</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-white/5 font-medium text-zinc-300">
                                <template x-for="d in paginatedDaigItems" :key="d.id">
                                    <tr class="hover:bg-zinc-800/40 transition-colors">
                                        <td class="py-2.5 px-3">
                                            <div class="flex items-center gap-2.5">
                                                <img :src="d.imageUrl || 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=120&q=80'"
                                                    class="w-10 h-10 rounded-xl object-cover border border-white/10 shrink-0" alt="daig">
                                                <div class="min-w-0">
                                                    <p class="font-bold text-white text-xs truncate max-w-[170px]" x-text="d.name"></p>
                                                    <p class="text-[9.5px] text-zinc-400" x-text="d.deliveryNotice || '3-4 hours notice'"></p>
                                                </div>
                                            </div>
                                        </td>

                                        <td class="py-2.5 px-3 font-semibold text-amber-300 text-xs" dir="rtl" x-text="d.urduName || '—'"></td>

                                        <td class="py-2.5 px-3 font-black text-[#FF9500] tabular-nums" x-text="'Rs. ' + Number(d.fullDaigPrice || 0).toLocaleString()"></td>

                                        <td class="py-2.5 px-3 font-black text-amber-400 tabular-nums" x-text="'Rs. ' + Number(d.halfDaigPrice || 0).toLocaleString()"></td>

                                        <td class="py-2.5 px-3">
                                            <template x-if="d.isDiscounted || d.promoBadge">
                                                <span class="px-2 py-0.5 rounded text-[9px] font-black uppercase bg-red-500/20 text-red-400 border border-red-500/30"
                                                    x-text="d.promoBadge || 'SPECIAL OFFER'">
                                                </span>
                                            </template>
                                            <template x-if="!d.isDiscounted && !d.promoBadge">
                                                <span class="text-zinc-500 text-[10px]">Standard Price</span>
                                            </template>
                                        </td>

                                        <td class="py-2.5 px-3 whitespace-nowrap">
                                            <button type="button" @click="toggleDaigAvailability(d)"
                                                class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider transition-all shadow-sm active:scale-95"
                                                :class="d.isVisible ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/40 hover:bg-emerald-500/30' : 'bg-red-500/20 text-red-400 border border-red-500/40 hover:bg-red-500/30'">
                                                <span class="w-2 h-2 rounded-full" :class="d.isVisible ? 'bg-emerald-400 animate-pulse' : 'bg-red-400'"></span>
                                                <span x-text="d.isVisible ? 'In Stock' : 'Out of Stock'"></span>
                                            </button>
                                        </td>

                                        <td class="py-2.5 px-3 text-right whitespace-nowrap">
                                            <div class="inline-flex items-center gap-1">
                                                <button type="button" @click="previewItem(d, 'daig')" class="p-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 rounded-lg" title="Preview Daig">
                                                    <i data-lucide="eye" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                                </button>
                                                <button type="button" @click="openEditDaigModal(d)" class="p-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 rounded-lg" title="Edit Daig & Promo">
                                                    <i data-lucide="edit" class="w-3.5 h-3.5 text-sky-400"></i>
                                                </button>
                                                <button type="button" @click="confirmDeleteDaig(d)" class="p-1.5 bg-red-950/40 hover:bg-red-900/60 text-red-400 rounded-lg" title="Delete Daig">
                                                    <i data-lucide="trash-2" class="w-3.5 h-3.5"></i>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </template>
                                <template x-if="paginatedDaigItems.length === 0">
                                    <tr>
                                        <td colspan="7" class="text-center py-8 text-zinc-500 italic">No Shahi Daigs found. Click "+ Upload Daig" to add one.</td>
                                    </tr>
                                </template>
                            </tbody>
                        </table>
                    </div>

                    <!-- Pagination Controls -->
                    <div class="px-3.5 py-2.5 border-t border-white/5 flex flex-wrap items-center justify-between gap-2 text-xs text-zinc-400">
                        <div class="flex items-center gap-3">
                            <span x-text="'Showing ' + paginatedDaigItems.length + ' of ' + filteredDaigItems.length + ' daigs (Page ' + daigPage + ')'"></span>
                            <!-- Custom Daigs Per Page Dropdown -->
                            <div class="relative flex items-center gap-1.5 text-xs text-zinc-400" x-data="{ openDaigPage: false }">
                                <span>Per page:</span>
                                <button type="button" @click="openDaigPage = !openDaigPage; $nextTick(() => lucide.createIcons())"
                                    class="px-2 py-0.5 bg-zinc-900 hover:bg-zinc-800 border border-white/10 hover:border-orange-500/30 rounded-lg text-xs text-white flex items-center gap-1 transition-all">
                                    <span x-text="daigPerPage"></span>
                                    <i data-lucide="chevron-down" class="w-3 h-3 text-[#FF9500] transition-transform" :class="openDaigPage ? 'rotate-180' : ''"></i>
                                </button>
                                <div x-show="openDaigPage" @click.outside="openDaigPage = false" x-cloak
                                    class="absolute left-0 bottom-full mb-1 w-20 cupertino-glass rounded-xl p-1 shadow-2xl border border-white/10 z-50 space-y-0.5 text-xs">
                                    <template x-for="n in [10, 25, 50, 100]" :key="n">
                                        <button type="button" @click="daigPerPage = n; daigPage = 1; openDaigPage = false"
                                            class="w-full flex items-center justify-between px-2 py-1 rounded-lg text-left transition-colors hover:bg-orange-500/20"
                                            :class="daigPerPage === n ? 'text-orange-400 font-bold bg-orange-500/10' : 'text-zinc-300'">
                                            <span x-text="n"></span>
                                            <i data-lucide="check" class="w-3 h-3 text-orange-400" x-show="daigPerPage === n"></i>
                                        </button>
                                    </template>
                                </div>
                            </div>
                        </div>
                        <div class="flex items-center gap-1.5">
                            <button type="button" @click="daigPage = Math.max(1, daigPage - 1)" :disabled="daigPage <= 1"
                                class="px-2.5 py-1 bg-zinc-900 disabled:opacity-40 rounded-lg text-xs font-semibold hover:text-white">Previous</button>
                            <span class="px-2 text-xs font-mono font-bold text-white" x-text="daigPage"></span>
                            <button type="button" @click="daigPage = daigPage + 1" :disabled="daigPage * daigPerPage >= filteredDaigItems.length"
                                class="px-2.5 py-1 bg-zinc-900 disabled:opacity-40 rounded-lg text-xs font-semibold hover:text-white">Next</button>
                        </div>
                    </div>
                </div>

                <!-- END OF VIEW 2: ALL MENU LISTINGS -->
                </div>

            </section>

            <!-- =============================================================== -->
            <!-- TAB: OFFERS & PROMOS (VENDOR BANNERS FOR MOBILE APP) -->
            <!-- =============================================================== -->
            <section x-show="activeTab === 'offers'" class="space-y-3.5">
                
                <!-- Section Header -->
                <div class="p-3.5 cupertino-card rounded-2xl flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3">
                    <div class="flex items-center gap-2.5">
                        <div class="w-9 h-9 rounded-xl bg-orange-500/15 text-[#FF9500] flex items-center justify-center font-bold text-base shrink-0">
                            🏷️
                        </div>
                        <div>
                            <h3 class="text-xs font-bold text-white flex items-center gap-2">
                                <span>Promotional Offers &amp; App Banners</span>
                                <span class="px-2 py-0.5 rounded-full text-[9px] font-bold bg-white/10 text-zinc-300 font-mono" x-text="vendorBanners.length + ' Live Deals'"></span>
                            </h3>
                            <p class="text-[10.5px] text-zinc-400">Manage promotional discount banners displayed at the top of the mobile app when customers view your outlet</p>
                        </div>
                    </div>
                    <button type="button" @click="openOfferModal()"
                        class="px-3.5 py-2 bg-[#FF9500] hover:bg-orange-500 text-white font-bold rounded-xl text-xs flex items-center justify-center gap-1.5 transition-all shadow-lg shadow-orange-500/20 shrink-0">
                        <i data-lucide="plus-circle" class="w-3.5 h-3.5"></i>
                        <span>Create New Offer Banner</span>
                    </button>
                </div>

                <!-- Offers Grid -->
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3.5">
                    
                    <template x-for="b in vendorBanners" :key="b.id">
                        <div class="cupertino-card rounded-2xl overflow-hidden border border-white/5 flex flex-col justify-between group hover:border-orange-500/30 transition-all">
                            
                            <!-- Banner Visual Preview Header -->
                            <div class="relative h-36 p-4 flex flex-col justify-between overflow-hidden"
                                :style="'background: linear-gradient(135deg, ' + (b.bgGradient?.[0] || '#EA580C') + ', ' + (b.bgGradient?.[1] || '#9A3412') + ')'">
                                
                                <!-- Background Image with Opacity -->
                                <template x-if="b.imageUrl">
                                    <img :src="b.imageUrl" alt="" class="absolute right-0 bottom-0 w-32 h-32 object-cover rounded-full opacity-30 pointer-events-none transform translate-x-4 translate-y-4">
                                </template>

                                <!-- Top Row: Tag & Discount Badge -->
                                <div class="relative z-10 flex items-center justify-between">
                                    <span class="px-2 py-0.5 rounded text-[9.5px] font-black uppercase tracking-wider bg-black/40 text-amber-300 backdrop-blur-sm"
                                        x-text="b.tagText || 'SPECIAL OFFER'"></span>
                                    
                                    <span x-show="b.discountPercent > 0"
                                        class="px-2 py-0.5 rounded-full text-[10px] font-black bg-white text-orange-600 shadow-sm"
                                        x-text="b.discountPercent + '% OFF'"></span>
                                </div>

                                <!-- Middle Title & Dishes -->
                                <div class="relative z-10 space-y-1">
                                    <h4 class="text-base font-extrabold text-white tracking-tight leading-tight line-clamp-1" x-text="b.title"></h4>
                                    <p class="text-[11px] text-white/80 line-clamp-2 leading-relaxed" x-text="b.dishesText || 'Special kitchen deal'"></p>
                                </div>

                                <!-- Bottom CTA & Visibility Badge -->
                                <div class="relative z-10 flex items-center justify-between">
                                    <span class="text-[10px] font-bold text-white/90 bg-white/20 px-2 py-0.5 rounded" x-text="b.buttonText || 'Order Now'"></span>
                                    <span class="text-[9.5px] font-bold px-2 py-0.5 rounded-full"
                                        :class="b.isVisible ? 'bg-emerald-500/80 text-white' : 'bg-zinc-800/80 text-zinc-400'"
                                        x-text="b.isVisible ? 'Active on App' : 'Paused'"></span>
                                </div>
                            </div>

                            <!-- Footer Actions Bar -->
                            <div class="p-3 bg-zinc-950/60 border-t border-white/5 flex items-center justify-between">
                                <button type="button" @click="toggleOfferVisibility(b)"
                                    class="text-[11px] font-medium flex items-center gap-1.5 transition-colors"
                                    :class="b.isVisible ? 'text-emerald-400 hover:text-emerald-300' : 'text-zinc-500 hover:text-zinc-300'">
                                    <i :data-lucide="b.isVisible ? 'eye' : 'eye-off'" class="w-3.5 h-3.5"></i>
                                    <span x-text="b.isVisible ? 'Shown on App' : 'Hidden'"></span>
                                </button>

                                <div class="flex items-center gap-1">
                                    <button type="button" @click="openOfferModal(b)"
                                        class="p-1.5 rounded-lg bg-white/5 hover:bg-white/10 text-zinc-300 hover:text-white transition-colors"
                                        title="Edit Offer">
                                        <i data-lucide="edit-3" class="w-3.5 h-3.5"></i>
                                    </button>
                                    <button type="button" @click="deleteOffer(b)"
                                        class="p-1.5 rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-400 transition-colors"
                                        title="Delete Offer">
                                        <i data-lucide="trash-2" class="w-3.5 h-3.5"></i>
                                    </button>
                                </div>
                            </div>

                        </div>
                    </template>

                    <!-- Empty State -->
                    <template x-if="vendorBanners.length === 0">
                        <div class="col-span-full p-8 cupertino-card rounded-2xl text-center space-y-3">
                            <div class="w-12 h-12 mx-auto rounded-2xl bg-orange-500/15 text-[#FF9500] flex items-center justify-center text-xl">
                                🏷️
                            </div>
                            <h4 class="text-sm font-bold text-white">No Promotional Offers Yet</h4>
                            <p class="text-xs text-zinc-400 max-w-md mx-auto">Create your first offer banner with a discount percentage, featured dishes, and background image to attract more customers in the mobile app!</p>
                            <button type="button" @click="openOfferModal()"
                                class="inline-flex items-center gap-1.5 px-4 py-2 bg-[#FF9500] hover:bg-orange-500 text-white font-bold rounded-xl text-xs transition-all shadow-lg shadow-orange-500/20">
                                <i data-lucide="plus" class="w-3.5 h-3.5"></i>
                                <span>Create First Offer Banner</span>
                            </button>
                        </div>
                    </template>

                </div>

            </section>

            <!-- =============================================================== -->
            <!-- TAB 6: PROFILE & STORE SETTINGS -->
            <!-- =============================================================== -->
            <section x-show="activeTab === 'profile'" class="space-y-3">
                
                <div class="grid grid-cols-1 lg:grid-cols-12 gap-3">
                    
                    <!-- Left Column: Store Credentials & Password -->
                    <div class="lg:col-span-6 space-y-3">
                        <div class="p-4 rounded-2xl cupertino-card space-y-3">
                            <div class="flex items-center justify-between pb-2 border-b border-white/5">
                                <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                    <i data-lucide="store" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                    <span>Store Profile Credentials</span>
                                </h4>
                                <span class="px-2 py-0.5 rounded text-[9px] font-bold bg-orange-500/20 text-[#FF9500]">Verified Vendor</span>
                            </div>

                            <form @submit.prevent="saveStoreProfile()" class="space-y-2.5">
                                <div>
                                    <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Store / Business Name</label>
                                    <input type="text" x-model="profileForm.businessName" required
                                        class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                </div>

                                <div class="grid grid-cols-2 gap-2">
                                    <div>
                                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Manager Full Name</label>
                                        <input type="text" x-model="profileForm.name" required
                                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                    </div>
                                    <div>
                                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Contact Phone</label>
                                        <input type="text" x-model="profileForm.phone" required
                                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                    </div>
                                </div>

                                <div class="grid grid-cols-2 gap-2">
                                    <div>
                                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">City</label>
                                        <input type="text" x-model="profileForm.city"
                                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                    </div>
                                    <div class="relative" x-data="{ openBizType: false }">
                                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Category</label>
                                        <button type="button" @click="openBizType = !openBizType; $nextTick(() => lucide.createIcons())"
                                            class="w-full px-2.5 py-1.5 bg-zinc-900 border border-white/10 hover:border-orange-500/40 rounded-xl text-xs text-white flex items-center justify-between transition-colors focus:outline-none focus:border-[#FF9500]">
                                            <span x-text="profileForm.businessType === 'pakwan' ? '👑 Shahi Pakwan' : (profileForm.businessType === 'restaurant' ? '🍽️ Restaurant Fast Food' : '👑🍽️ Hybrid (Both)')"></span>
                                            <i data-lucide="chevron-down" class="w-3.5 h-3.5 text-[#FF9500] transition-transform" :class="openBizType ? 'rotate-180' : ''"></i>
                                        </button>
                                        <div x-show="openBizType" @click.outside="openBizType = false" x-cloak
                                            class="absolute left-0 mt-1 w-full cupertino-glass rounded-xl p-1 shadow-2xl border border-white/10 z-50 space-y-0.5 text-xs">
                                            <button type="button" @click="profileForm.businessType = 'pakwan'; openBizType = false"
                                                class="w-full flex items-center justify-between px-2.5 py-1.5 rounded-lg text-left transition-colors hover:bg-orange-500/20"
                                                :class="profileForm.businessType === 'pakwan' ? 'text-orange-400 font-bold bg-orange-500/10' : 'text-zinc-300'">
                                                <span>👑 Shahi Pakwan Center</span>
                                                <i data-lucide="check" class="w-3 h-3 text-orange-400" x-show="profileForm.businessType === 'pakwan'"></i>
                                            </button>
                                            <button type="button" @click="profileForm.businessType = 'restaurant'; openBizType = false"
                                                class="w-full flex items-center justify-between px-2.5 py-1.5 rounded-lg text-left transition-colors hover:bg-orange-500/20"
                                                :class="profileForm.businessType === 'restaurant' ? 'text-orange-400 font-bold bg-orange-500/10' : 'text-zinc-300'">
                                                <span>🍽️ Restaurant Fast Food</span>
                                                <i data-lucide="check" class="w-3 h-3 text-orange-400" x-show="profileForm.businessType === 'restaurant'"></i>
                                            </button>
                                            <button type="button" @click="profileForm.businessType = 'both'; openBizType = false"
                                                class="w-full flex items-center justify-between px-2.5 py-1.5 rounded-lg text-left transition-colors hover:bg-orange-500/20"
                                                :class="profileForm.businessType === 'both' ? 'text-orange-400 font-bold bg-orange-500/10' : 'text-zinc-300'">
                                                <span>👑🍽️ Hybrid (Both)</span>
                                                <i data-lucide="check" class="w-3 h-3 text-orange-400" x-show="profileForm.businessType === 'both'"></i>
                                            </button>
                                        </div>
                                    </div>
                                </div>

                                <div>
                                    <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Physical Kitchen Address</label>
                                    <input type="text" x-model="profileForm.address"
                                        class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                </div>

                                <button type="submit"
                                    class="w-full mt-2 py-2 px-3 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-black font-bold rounded-xl text-xs shadow-sm transition-all active:scale-[0.98]">
                                    Save Profile Changes
                                </button>
                            </form>
                        </div>

                        <!-- Password Security Card -->
                        <div class="p-4 rounded-2xl cupertino-card space-y-3">
                            <h4 class="text-xs font-bold text-white flex items-center gap-1.5 pb-2 border-b border-white/5">
                                <i data-lucide="lock" class="w-3.5 h-3.5 text-sky-400"></i>
                                <span>Change Security Password</span>
                            </h4>

                            <form @submit.prevent="updatePassword()" class="space-y-2">
                                <div class="grid grid-cols-2 gap-2">
                                    <div>
                                        <label class="block text-[10.5px] font-semibold text-zinc-400 mb-0.5">New Password</label>
                                        <input type="password" x-model="passwordForm.newPassword" required placeholder="••••••••"
                                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                    </div>
                                    <div>
                                        <label class="block text-[10.5px] font-semibold text-zinc-400 mb-0.5">Confirm Password</label>
                                        <input type="password" x-model="passwordForm.confirmPassword" required placeholder="••••••••"
                                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                    </div>
                                </div>

                                <button type="submit" class="px-3 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 rounded-xl text-xs font-semibold border border-white/10">
                                    Update Password
                                </button>
                            </form>
                        </div>
                    </div>

                    <!-- Right Column: Interactive GPS Kitchen Location Picker (Leaflet) -->
                    <div class="lg:col-span-6 p-4 rounded-2xl cupertino-card space-y-3 flex flex-col justify-between">
                        <div>
                            <div class="flex items-center justify-between pb-2 border-b border-white/5">
                                <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                    <i data-lucide="map-pin" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                    <span>Kitchen GPS Location (Google Maps Pin)</span>
                                </h4>
                                <button type="button" @click="detectCurrentGPS()"
                                    class="px-2 py-0.5 bg-orange-500/20 text-[#FF9500] hover:bg-orange-500/30 text-[10px] font-bold rounded-lg border border-orange-500/30 flex items-center gap-1">
                                    <i data-lucide="crosshair" class="w-3 h-3"></i>
                                    <span x-text="detectingGps ? 'Detecting...' : 'Auto-Detect 📍'"></span>
                                </button>
                            </div>

                            <p class="text-[11px] text-zinc-400 mt-2">
                                Click on the map to set the exact physical kitchen location. Delivery riders and distance calculation will rely on these GPS coordinates.
                            </p>

                            <!-- Leaflet Map Container -->
                            <div id="store-map-picker" class="w-full h-56 rounded-2xl overflow-hidden mt-3 border border-white/10 z-0"></div>

                            <div class="grid grid-cols-2 gap-2 mt-3">
                                <div>
                                    <label class="block text-[10px] font-semibold text-zinc-400 mb-0.5">Latitude</label>
                                    <input type="text" x-model="profileForm.latitude" readonly
                                        class="w-full px-2.5 py-1 bg-zinc-900 border border-white/10 rounded-lg text-xs text-white font-mono">
                                </div>
                                <div>
                                    <label class="block text-[10px] font-semibold text-zinc-400 mb-0.5">Longitude</label>
                                    <input type="text" x-model="profileForm.longitude" readonly
                                        class="w-full px-2.5 py-1 bg-zinc-900 border border-white/10 rounded-lg text-xs text-white font-mono">
                                </div>
                            </div>
                        </div>

                        <div class="pt-3 border-t border-white/5 flex items-center justify-between text-xs">
                            <a :href="'https://www.google.com/maps/search/?api=1&query=' + profileForm.latitude + ',' + profileForm.longitude" target="_blank"
                                class="text-[#FF9500] hover:underline font-bold flex items-center gap-1">
                                <i data-lucide="external-link" class="w-3 h-3"></i>
                                <span>Preview on Google Maps</span>
                            </a>

                            <button type="button" @click="saveStoreProfile()" class="px-4 py-1.5 bg-[#FF9500] text-black font-bold rounded-xl text-xs shadow-sm">
                                Save GPS Coordinates
                            </button>
                        </div>
                    </div>

                </div>

            </section>

        </main>
    </div>

    <!-- ======================================================================= -->
    <!-- SLIDE-OVER SHEET: CUSTOMER ORDER HISTORY (TAB 3) -->
    <!-- ======================================================================= -->
    <div x-show="sheet.customer" class="fixed inset-0 z-50 overflow-hidden" x-cloak>
        <div class="absolute inset-0 bg-black/60 backdrop-blur-sm transition-opacity" @click="sheet.customer = false"></div>
        <div class="fixed inset-y-0 right-0 max-w-full flex pl-10">
            <div class="w-[92vw] max-w-md cupertino-glass border-l border-white/10 flex flex-col justify-between shadow-2xl p-5 overflow-y-auto">
                <div>
                    <!-- Sheet Header -->
                    <div class="flex items-center justify-between pb-3 border-b border-white/5">
                        <div class="flex items-center gap-2">
                            <div class="w-8 h-8 rounded-full bg-purple-500/20 text-purple-300 flex items-center justify-center font-bold text-sm">
                                👤
                            </div>
                            <div class="min-w-0">
                                <h3 class="text-sm font-bold text-white truncate" x-text="activeCustomer?.customerName || 'Customer Details'"></h3>
                                <p class="text-[10px] text-[#FF9500] font-mono" x-text="activeCustomer?.customerPhone"></p>
                            </div>
                        </div>
                        <button type="button" @click="sheet.customer = false" class="p-1 rounded-lg text-zinc-400 hover:text-white">✕</button>
                    </div>

                    <!-- Customer Lifetime Summary -->
                    <div class="grid grid-cols-2 gap-2 my-3 text-center">
                        <div class="p-2.5 rounded-xl bg-zinc-900 border border-white/5">
                            <p class="text-[9px] uppercase font-bold text-zinc-400">Total Spent</p>
                            <p class="text-sm font-black text-emerald-400 mt-0.5 tabular-nums" x-text="'Rs. ' + Number(activeCustomer?.totalSpent || 0).toLocaleString()"></p>
                        </div>
                        <div class="p-2.5 rounded-xl bg-zinc-900 border border-white/5">
                            <p class="text-[9px] uppercase font-bold text-zinc-400">Orders Count</p>
                            <p class="text-sm font-black text-white mt-0.5 tabular-nums" x-text="getCustomerOrders(activeCustomer?.customerPhone).length + ' Orders'"></p>
                        </div>
                    </div>

                    <!-- Past Orders List for this Customer -->
                    <div class="space-y-2 mt-4">
                        <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                            <i data-lucide="history" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                            <span>All Orders from this Customer</span>
                        </h4>

                        <div class="space-y-2 max-h-[380px] overflow-y-auto pr-1">
                            <template x-for="ord in getCustomerOrders(activeCustomer?.customerPhone)" :key="ord.id">
                                <div class="p-2.5 rounded-xl bg-zinc-900/80 border border-white/5 text-xs space-y-1">
                                    <div class="flex items-center justify-between">
                                        <span class="font-bold text-white font-mono" x-text="'#' + ord.id"></span>
                                        <span class="px-1.5 py-0.2 rounded-full text-[8.5px] font-bold uppercase"
                                            :class="getStatusBadgeClass(ord.status)" x-text="ord.status"></span>
                                    </div>
                                    <p class="text-[11px] text-zinc-300" x-text="formatOrderItemsSummary(ord.items)"></p>
                                    <div class="flex items-center justify-between text-[10px] text-zinc-400 pt-1 border-t border-white/5">
                                        <span x-text="formatDateShort(ord.orderDate)"></span>
                                        <span class="font-bold text-[#FF9500]" x-text="'Rs. ' + ord.totalAmount"></span>
                                    </div>
                                </div>
                            </template>
                        </div>
                    </div>
                </div>

                <div class="pt-3 border-t border-white/5">
                    <button type="button" @click="sheet.customer = false"
                        class="w-full py-2 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 rounded-xl text-xs font-semibold">
                        Close Customer Sheet
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- ======================================================================= -->
    <!-- SLIDE-OVER SHEET: RIDER DETAILS & DELIVERIES (TAB 2) -->
    <!-- ======================================================================= -->
    <div x-show="sheet.rider" class="fixed inset-0 z-50 overflow-hidden" x-cloak>
        <div class="absolute inset-0 bg-black/60 backdrop-blur-sm transition-opacity" @click="sheet.rider = false"></div>
        <div class="fixed inset-y-0 right-0 max-w-full flex pl-10">
            <div class="w-[92vw] max-w-md cupertino-glass border-l border-white/10 flex flex-col justify-between shadow-2xl p-5 overflow-y-auto">
                <div>
                    <div class="flex items-center justify-between pb-3 border-b border-white/5">
                        <div class="flex items-center gap-2">
                            <div class="w-8 h-8 rounded-full bg-sky-500/20 text-sky-400 flex items-center justify-center font-bold text-sm">
                                🛵
                            </div>
                            <div class="min-w-0">
                                <h3 class="text-sm font-bold text-white truncate" x-text="activeRider?.name || 'Rider Profile'"></h3>
                                <p class="text-[10px] text-[#FF9500] font-mono" x-text="activeRider?.phone"></p>
                            </div>
                        </div>
                        <button type="button" @click="sheet.rider = false" class="p-1 rounded-lg text-zinc-400 hover:text-white">✕</button>
                    </div>

                    <div class="grid grid-cols-2 gap-2 my-3 text-center">
                        <div class="p-2.5 rounded-xl bg-zinc-900 border border-white/5">
                            <p class="text-[9px] uppercase font-bold text-zinc-400">Total Delivered</p>
                            <p class="text-sm font-black text-emerald-400 mt-0.5 tabular-nums" x-text="(activeRider?.deliveriesCount || 12) + ' Orders'"></p>
                        </div>
                        <div class="p-2.5 rounded-xl bg-zinc-900 border border-white/5">
                            <p class="text-[9px] uppercase font-bold text-zinc-400">Active In Hand</p>
                            <p class="text-sm font-black text-amber-400 mt-0.5 tabular-nums" x-text="getActiveOrdersForRider(activeRider?.name).length"></p>
                        </div>
                    </div>

                    <div class="space-y-2 mt-4">
                        <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                            <i data-lucide="package" class="w-3.5 h-3.5 text-sky-400"></i>
                            <span>Orders Assigned to this Rider</span>
                        </h4>

                        <div class="space-y-2 max-h-[380px] overflow-y-auto pr-1">
                            <template x-for="ord in getActiveOrdersForRider(activeRider?.name)" :key="ord.id">
                                <div class="p-2.5 rounded-xl bg-zinc-900/80 border border-white/5 text-xs space-y-1">
                                    <div class="flex items-center justify-between">
                                        <span class="font-bold text-white font-mono" x-text="'#' + ord.id"></span>
                                        <span class="px-1.5 py-0.2 rounded-full text-[8.5px] font-bold uppercase"
                                            :class="getStatusBadgeClass(ord.status)" x-text="ord.status"></span>
                                    </div>
                                    <p class="text-[11px] text-zinc-300" x-text="ord.customerName + ' • ' + ord.deliveryAddress"></p>
                                    <div class="flex items-center justify-between text-[10px] text-zinc-400 pt-1 border-t border-white/5">
                                        <span x-text="'Rs. ' + ord.totalAmount"></span>
                                        <button type="button" @click="updateOrderStatus(ord.id, 'Delivered')"
                                            class="px-2 py-0.5 bg-emerald-500 hover:bg-emerald-400 text-black font-bold rounded text-[9.5px]">
                                            Mark Delivered ✅
                                        </button>
                                    </div>
                                </div>
                            </template>
                        </div>
                    </div>
                </div>

                <div class="pt-3 border-t border-white/5">
                    <button type="button" @click="sheet.rider = false"
                        class="w-full py-2 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 rounded-xl text-xs font-semibold">
                        Close Rider Sheet
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- ======================================================================= -->
    <!-- MODAL: ADD / EDIT RIDER -->
    <!-- ======================================================================= -->
    <div x-show="modal.rider" class="fixed inset-0 z-50 flex items-center justify-center p-3 bg-black/60 backdrop-blur-sm" x-cloak>
        <div class="w-full max-w-md cupertino-glass rounded-3xl p-5 border border-white/10 shadow-2xl" @click.away="modal.rider = false">
            <div class="flex items-center justify-between pb-2.5 border-b border-white/5 mb-3">
                <h3 class="text-sm font-bold text-white flex items-center gap-1.5">
                    <i data-lucide="bike" class="w-4 h-4 text-sky-400"></i>
                    <span x-text="editingRider.id ? 'Edit Dedicated Rider' : 'Add New Dedicated Rider'"></span>
                </h3>
                <button type="button" @click="modal.rider = false" class="text-zinc-400 hover:text-white">✕</button>
            </div>

            <form @submit.prevent="saveRiderForm()" class="space-y-2.5">
                <div>
                    <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Rider Full Name *</label>
                    <input type="text" x-model="riderForm.name" required placeholder="e.g. Captain Kamran Ali"
                        class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                </div>

                <div class="grid grid-cols-2 gap-2">
                    <div>
                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Phone Number *</label>
                        <input type="tel" x-model="riderForm.phone" required placeholder="+92 300 1122334"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                    </div>
                    <div>
                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Login Email</label>
                        <input type="email" x-model="riderForm.email" required placeholder="rider@store.pk"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                    </div>
                </div>

                <div class="grid grid-cols-2 gap-2">
                    <div>
                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Password</label>
                        <input type="text" x-model="riderForm.password" placeholder="123456"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                    </div>
                    <div>
                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">City</label>
                        <input type="text" x-model="riderForm.city" placeholder="Lahore"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                    </div>
                </div>

                <div class="pt-2 flex justify-end gap-2">
                    <button type="button" @click="modal.rider = false" class="px-3 py-1.5 bg-zinc-800 text-zinc-300 rounded-xl text-xs">Cancel</button>
                    <button type="submit" class="px-4 py-1.5 bg-[#FF9500] text-black font-bold rounded-xl text-xs shadow-sm">Save Rider</button>
                </div>
            </form>
        </div>
    </div>

    <!-- ======================================================================= -->
    <!-- MODAL: UPLOAD / EDIT FOOD ITEM (WITH PROMO / 50% DISCOUNT) -->
    <!-- ======================================================================= -->
    <div x-show="modal.food" class="fixed inset-0 z-50 flex items-center justify-center p-3 bg-black/60 backdrop-blur-sm" x-cloak>
        <div class="w-full max-w-lg cupertino-glass rounded-3xl p-5 border border-white/10 shadow-2xl max-h-[90vh] overflow-y-auto" @click.away="modal.food = false">
            <div class="flex items-center justify-between pb-2.5 border-b border-white/5 mb-3">
                <h3 class="text-sm font-bold text-white flex items-center gap-1.5">
                    <i data-lucide="utensils" class="w-4 h-4 text-[#FF9500]"></i>
                    <span x-text="foodForm.id ? 'Edit Restaurant Dish & Promo' : 'Upload New Restaurant Dish'"></span>
                </h3>
                <button type="button" @click="modal.food = false" class="text-zinc-400 hover:text-white">✕</button>
            </div>

            <form @submit.prevent="saveFoodItemForm()" class="space-y-3">
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                    <div>
                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Dish Name *</label>
                        <input type="text" x-model="foodForm.name" required placeholder="e.g. Special Beef Karahi"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                    </div>

                    <div class="relative" x-data="{ openCategory: false }">
                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Category *</label>
                        <button type="button" @click="openCategory = !openCategory; $nextTick(() => lucide.createIcons())"
                            class="w-full px-2.5 py-1.5 bg-zinc-900 border border-white/10 hover:border-orange-500/40 rounded-xl text-xs text-white flex items-center justify-between transition-colors focus:outline-none focus:border-[#FF9500]">
                            <span x-text="foodForm.category || 'Select Category'"></span>
                            <i data-lucide="chevron-down" class="w-3.5 h-3.5 text-[#FF9500] transition-transform" :class="openCategory ? 'rotate-180' : ''"></i>
                        </button>
                        <div x-show="openCategory" @click.outside="openCategory = false" x-cloak
                            class="absolute left-0 mt-1 w-full max-h-48 overflow-y-auto cupertino-glass rounded-xl p-1 shadow-2xl border border-white/10 z-50 space-y-0.5 text-xs">
                            <template x-for="cat in allowedFoodCategories" :key="cat">
                                <button type="button" @click="foodForm.category = cat; openCategory = false"
                                    class="w-full flex items-center justify-between px-2.5 py-1.5 rounded-lg text-left transition-colors hover:bg-orange-500/20"
                                    :class="foodForm.category === cat ? 'text-orange-400 font-bold bg-orange-500/10' : 'text-zinc-300'">
                                    <span x-text="cat"></span>
                                    <i data-lucide="check" class="w-3 h-3 text-orange-400" x-show="foodForm.category === cat"></i>
                                </button>
                            </template>
                        </div>
                    </div>
                </div>

                <div class="grid grid-cols-2 gap-2">
                    <div>
                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Base Price (Rs.) *</label>
                        <input type="number" x-model.number="foodForm.price" required min="10" placeholder="1200"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white font-mono focus:outline-none focus:border-[#FF9500]">
                    </div>

                    <div>
                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Calories (kcal)</label>
                        <input type="number" x-model.number="foodForm.calories" placeholder="550"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white font-mono focus:outline-none focus:border-[#FF9500]">
                    </div>
                </div>

                <!-- SPECIAL PROMO & DISCOUNT OFFER SYSTEM -->
                <div class="p-3 rounded-2xl bg-orange-500/10 border border-orange-500/25 space-y-2">
                    <div class="flex items-center justify-between">
                        <span class="text-xs font-bold text-white flex items-center gap-1.5">
                            <i data-lucide="tag" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                            <span>Special Promo & Discount Offer</span>
                        </span>
                        <label class="flex items-center gap-1.5 cursor-pointer">
                            <input type="checkbox" x-model="foodForm.isDiscounted" class="rounded bg-zinc-800 text-orange-500">
                            <span class="text-xs font-bold text-[#FF9500]">Enable Promo</span>
                        </label>
                    </div>

                    <div x-show="foodForm.isDiscounted" class="grid grid-cols-2 gap-2 pt-1 border-t border-white/10">
                        <div class="relative" x-data="{ openDiscount: false }">
                            <label class="block text-[10px] font-semibold text-zinc-300 mb-0.5">Discount Percentage (%)</label>
                            <button type="button" @click="openDiscount = !openDiscount; $nextTick(() => lucide.createIcons())"
                                class="w-full px-2 py-1 bg-zinc-900 border border-white/10 hover:border-orange-500/40 rounded-lg text-xs text-white flex items-center justify-between transition-colors focus:outline-none focus:border-[#FF9500]">
                                <span x-text="(foodForm.discountPercent || 10) + '% OFF' + (foodForm.discountPercent === 50 ? ' (Half Price!)' : '')"></span>
                                <i data-lucide="chevron-down" class="w-3 h-3 text-[#FF9500] transition-transform" :class="openDiscount ? 'rotate-180' : ''"></i>
                            </button>
                            <div x-show="openDiscount" @click.outside="openDiscount = false" x-cloak
                                class="absolute left-0 mt-1 w-full max-h-40 overflow-y-auto cupertino-glass rounded-xl p-1 shadow-2xl border border-white/10 z-50 space-y-0.5 text-xs">
                                <template x-for="pct in [10, 20, 30, 40, 50, 60, 70]" :key="pct">
                                    <button type="button" @click="foodForm.discountPercent = pct; recalcFoodDiscount(); openDiscount = false"
                                        class="w-full flex items-center justify-between px-2 py-1 rounded-lg text-left transition-colors hover:bg-orange-500/20"
                                        :class="foodForm.discountPercent === pct ? 'text-orange-400 font-bold bg-orange-500/10' : 'text-zinc-300'">
                                        <span x-text="pct + '% OFF' + (pct === 50 ? ' (Half Price!)' : '')"></span>
                                        <i data-lucide="check" class="w-3 h-3 text-orange-400" x-show="foodForm.discountPercent === pct"></i>
                                    </button>
                                </template>
                            </div>
                        </div>

                        <div>
                            <label class="block text-[10px] font-semibold text-zinc-300 mb-0.5">Promo Tag Badge</label>
                            <input type="text" x-model="foodForm.promoBadge" placeholder="e.g. 🔥 50% OFF"
                                class="w-full px-2 py-1 bg-zinc-900 border border-white/10 rounded-lg text-xs text-white focus:outline-none focus:border-[#FF9500]">
                        </div>

                        <div class="col-span-2 p-2 rounded-xl bg-zinc-950/80 flex items-center justify-between text-xs">
                            <span class="text-zinc-400">Discounted Selling Price:</span>
                            <span class="font-black text-emerald-400 text-sm tabular-nums" x-text="'Rs. ' + (foodForm.discountPrice || Math.round(foodForm.price * (1 - foodForm.discountPercent/100)))"></span>
                        </div>
                    </div>
                </div>

                <div>
                    <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Image URL</label>
                    <input type="url" x-model="foodForm.imageUrl" placeholder="https://images.unsplash.com/..."
                        class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                </div>

                <div>
                    <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Description & Ingredients</label>
                    <textarea x-model="foodForm.description" rows="2" placeholder="Freshly charcoal grilled spices..."
                        class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]"></textarea>
                </div>

                <div class="pt-2 flex justify-end gap-2">
                    <button type="button" @click="modal.food = false" class="px-3 py-1.5 bg-zinc-800 text-zinc-300 rounded-xl text-xs">Cancel</button>
                    <button type="submit" class="px-4 py-1.5 bg-[#FF9500] text-black font-bold rounded-xl text-xs shadow-sm">Save Dish</button>
                </div>
            </form>
        </div>
    </div>

    <!-- ======================================================================= -->
    <!-- MODAL: UPLOAD / EDIT SHAHI DAIG (PAKWAN CATERING) -->
    <!-- ======================================================================= -->
    <div x-show="modal.daig" class="fixed inset-0 z-50 flex items-center justify-center p-3 bg-black/60 backdrop-blur-sm" x-cloak>
        <div class="w-full max-w-lg cupertino-glass rounded-3xl p-5 border border-white/10 shadow-2xl max-h-[90vh] overflow-y-auto" @click.away="modal.daig = false">
            <div class="flex items-center justify-between pb-2.5 border-b border-white/5 mb-3">
                <h3 class="text-sm font-bold text-white flex items-center gap-1.5">
                    <span class="text-amber-400">👑</span>
                    <span x-text="daigForm.id ? 'Edit Shahi Daig' : 'Upload New Shahi Daig'"></span>
                </h3>
                <button type="button" @click="modal.daig = false" class="text-zinc-400 hover:text-white">✕</button>
            </div>

            <form @submit.prevent="saveDaigItemForm()" class="space-y-3">
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                    <div>
                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Daig English Title *</label>
                        <input type="text" x-model="daigForm.name" required placeholder="Shahi Mutton Pulao Deg"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                    </div>

                    <div>
                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Urdu Title (اردو نام)</label>
                        <input type="text" x-model="daigForm.urduName" dir="rtl" placeholder="شاہی مٹن یخنی پلاؤ دیگ"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-amber-300 font-semibold focus:outline-none focus:border-[#FF9500]">
                    </div>
                </div>

                <div class="grid grid-cols-2 gap-2">
                    <div>
                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">12KG Full Daig Price (Rs.) *</label>
                        <input type="number" x-model.number="daigForm.fullDaigPrice" required min="100" placeholder="18000"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white font-mono focus:outline-none focus:border-[#FF9500]">
                    </div>

                    <div>
                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">6KG Half Daig Price (Rs.) *</label>
                        <input type="number" x-model.number="daigForm.halfDaigPrice" required min="100" placeholder="9500"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white font-mono focus:outline-none focus:border-[#FF9500]">
                    </div>
                </div>

                <!-- Daig Category Selector -->
                <div class="relative" x-data="{ openDaigCat: false }">
                    <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Daig Category *</label>
                    <button type="button" @click="openDaigCat = !openDaigCat; $nextTick(() => lucide.createIcons())"
                        class="w-full px-2.5 py-1.5 bg-zinc-900 border border-white/10 hover:border-orange-500/40 rounded-xl text-xs text-white flex items-center justify-between transition-colors focus:outline-none focus:border-[#FF9500]">
                        <span x-text="daigForm.category || 'Select Category'"></span>
                        <i data-lucide="chevron-down" class="w-3.5 h-3.5 text-[#FF9500] transition-transform" :class="openDaigCat ? 'rotate-180' : ''"></i>
                    </button>
                    <div x-show="openDaigCat" @click.outside="openDaigCat = false" x-cloak
                        class="absolute left-0 mt-1 w-full max-h-48 overflow-y-auto cupertino-glass rounded-xl p-1 shadow-2xl border border-white/10 z-50 space-y-0.5 text-xs">
                        <template x-for="cat in allowedDaigCategories" :key="cat">
                            <button type="button" @click="daigForm.category = cat; openDaigCat = false"
                                class="w-full flex items-center justify-between px-2.5 py-1.5 rounded-lg text-left transition-colors hover:bg-orange-500/20"
                                :class="daigForm.category === cat ? 'text-orange-400 font-bold bg-orange-500/10' : 'text-zinc-300'">
                                <span x-text="cat"></span>
                                <i data-lucide="check" class="w-3 h-3 text-orange-400" x-show="daigForm.category === cat"></i>
                            </button>
                        </template>
                    </div>
                </div>

                <div class="grid grid-cols-2 gap-2">
                    <div>
                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Promo Offer Badge</label>
                        <input type="text" x-model="daigForm.promoBadge" placeholder="e.g. SPECIAL DUM DEG"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                    </div>
                    <div>
                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Advance Order Notice</label>
                        <input type="text" x-model="daigForm.deliveryNotice" placeholder="3-4 hours advance notice"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                    </div>
                </div>

                <div>
                    <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Image URL</label>
                    <input type="url" x-model="daigForm.imageUrl" placeholder="https://images.unsplash.com/..."
                        class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                </div>

                <div class="pt-2 flex justify-end gap-2">
                    <button type="button" @click="modal.daig = false" class="px-3 py-1.5 bg-zinc-800 text-zinc-300 rounded-xl text-xs">Cancel</button>
                    <button type="submit" class="px-4 py-1.5 bg-[#FF9500] text-black font-bold rounded-xl text-xs shadow-sm">Save Daig</button>
                </div>
            </form>
        </div>
    </div>

    <!-- ======================================================================= -->
    <!-- MODAL: ORDER DETAILS & REJECT WITH REASON MODAL -->
    <!-- ======================================================================= -->
    <div x-show="modal.orderDetail" class="fixed inset-0 z-50 flex items-center justify-center p-3 bg-black/60 backdrop-blur-sm" x-cloak>
        <div class="w-full max-w-md cupertino-glass rounded-3xl p-5 border border-white/10 shadow-2xl" @click.away="modal.orderDetail = false">
            <div class="flex items-center justify-between pb-2.5 border-b border-white/5 mb-3">
                <h3 class="text-sm font-bold text-white flex items-center gap-1.5">
                    <i data-lucide="package" class="w-4 h-4 text-[#FF9500]"></i>
                    <span x-text="'Order #' + (activeOrder?.id || '')"></span>
                </h3>
                <button type="button" @click="modal.orderDetail = false" class="text-zinc-400 hover:text-white">✕</button>
            </div>

            <div class="space-y-3 text-xs">
                <div class="flex justify-between items-center p-2.5 rounded-xl bg-zinc-900">
                    <span class="text-zinc-400">Order Total:</span>
                    <span class="font-black text-[#FF9500] text-sm tabular-nums" x-text="'Rs. ' + activeOrder?.totalAmount"></span>
                </div>

                <div class="space-y-1">
                    <p class="font-bold text-white">Customer Details:</p>
                    <p class="text-zinc-300" x-text="activeOrder?.customerName + ' (' + activeOrder?.customerPhone + ')'"></p>
                    <div class="flex items-center gap-2 mt-1">
                        <template x-if="activeOrder?.customerPhone">
                            <a :href="'tel:' + activeOrder.customerPhone"
                                class="px-2.5 py-1 bg-blue-600/90 hover:bg-blue-600 text-white rounded-lg text-[11px] font-bold inline-flex items-center gap-1.5 transition-all">
                                <i data-lucide="phone" class="w-3 h-3"></i>
                                <span>Call Customer</span>
                            </a>
                        </template>
                        <template x-if="activeOrder?.customerPhone">
                            <a :href="'https://wa.me/' + (activeOrder.customerPhone || '').replace(/[^0-9]/g, '') + '?text=' + encodeURIComponent('Assalam-o-Alaikum ' + (activeOrder.customerName || 'Customer') + ', FoodCourt/Pakwan order #' + activeOrder.id + ' ke hawalay se rabta kar rahe hain.')"
                               target="_blank"
                               class="px-2.5 py-1 bg-emerald-600/90 hover:bg-emerald-600 text-white rounded-lg text-[11px] font-bold inline-flex items-center gap-1.5 transition-all">
                                <i data-lucide="message-circle" class="w-3 h-3"></i>
                                <span>WhatsApp Customer</span>
                            </a>
                        </template>
                    </div>
                    <p class="text-zinc-400 mt-1" x-text="activeOrder?.deliveryAddress"></p>
                    <template x-if="activeOrder?.latitude">
                        <a :href="'https://www.google.com/maps/search/?api=1&query=' + activeOrder.latitude + ',' + activeOrder.longitude" target="_blank"
                            class="text-[#FF9500] hover:underline font-bold inline-flex items-center gap-1 mt-0.5">
                            <i data-lucide="navigation" class="w-3 h-3"></i>
                            <span>View Customer GPS Location on Map</span>
                        </a>
                    </template>
                </div>

                <template x-if="activeOrder?.isDaigBooking || activeOrder?.occasion || activeOrder?.notes || activeOrder?.event_date">
                    <div class="p-2.5 rounded-xl bg-amber-500/10 border border-amber-500/20 space-y-1 mt-2">
                        <div class="flex items-center gap-1.5 text-amber-400 font-bold text-xs">
                            <i data-lucide="soup" class="w-3.5 h-3.5"></i>
                            <span>Shahi Pakwan / Daig Booking Details</span>
                        </div>
                        <template x-if="activeOrder?.occasion">
                            <p class="text-zinc-300 text-[11px]"><span class="text-zinc-400">Occasion:</span> <span class="font-semibold text-amber-200" x-text="activeOrder.occasion"></span></p>
                        </template>
                        <template x-if="activeOrder?.event_date || activeOrder?.event_time">
                            <p class="text-zinc-300 text-[11px]"><span class="text-zinc-400">Event Schedule:</span> <span class="font-semibold text-white" x-text="(activeOrder.event_date || '') + ' ' + (activeOrder.event_time || '')"></span></p>
                        </template>
                        <template x-if="activeOrder?.notes">
                            <p class="text-zinc-300 text-[11px]"><span class="text-zinc-400">Special Instructions / Spice:</span> <span class="text-white italic" x-text="activeOrder.notes"></span></p>
                        </template>
                    </div>
                </template>

                <div class="space-y-1 pt-2 border-t border-white/5">
                    <p class="font-bold text-white">Items Summary:</p>
                    <p class="text-zinc-300" x-text="formatOrderItemsSummary(activeOrder?.items)"></p>
                </div>
            </div>

            <div class="pt-3 mt-3 border-t border-white/5 flex items-center justify-between">
                <template x-if="activeOrder?.customerPhone">
                    <button type="button" @click="sendWhatsAppDispatchAlert(activeOrder)"
                        class="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl text-xs font-bold inline-flex items-center gap-1.5 transition-all shadow">
                        <i data-lucide="message-circle" class="w-3.5 h-3.5"></i>
                        <span>WhatsApp Dispatch Alert</span>
                    </button>
                </template>
                <button type="button" @click="modal.orderDetail = false" class="px-3 py-1.5 bg-zinc-800 text-zinc-300 rounded-xl text-xs font-semibold">Close</button>
            </div>
        </div>
    </div>

    <!-- Reject Reason Modal -->
    <div x-show="modal.reject" class="fixed inset-0 z-50 flex items-center justify-center p-3 bg-black/60 backdrop-blur-sm" x-cloak>
        <div class="w-full max-w-sm cupertino-glass rounded-3xl p-5 border border-white/10 shadow-2xl" @click.away="modal.reject = false">
            <h3 class="text-sm font-bold text-red-400 flex items-center gap-1.5 mb-2">
                <i data-lucide="alert-triangle" class="w-4 h-4"></i>
                <span>Reject Customer Order</span>
            </h3>
            <p class="text-xs text-zinc-300 mb-3">Please specify a reason for rejecting Order #<span x-text="rejectTarget?.id"></span>:</p>

            <div class="space-y-2">
                <div class="flex flex-wrap gap-1">
                    <button type="button" @click="rejectReason = 'Kitchen over-capacity'" class="px-2 py-0.5 rounded text-[10px] bg-zinc-900 border border-white/10 hover:border-red-400">Over-capacity</button>
                    <button type="button" @click="rejectReason = 'Out of Stock / Ingredients finished'" class="px-2 py-0.5 rounded text-[10px] bg-zinc-900 border border-white/10 hover:border-red-400">Out of Stock</button>
                    <button type="button" @click="rejectReason = 'Delivery address out of range'" class="px-2 py-0.5 rounded text-[10px] bg-zinc-900 border border-white/10 hover:border-red-400">Out of Range</button>
                </div>

                <textarea x-model="rejectReason" rows="2" placeholder="Reason for cancellation..."
                    class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-red-500"></textarea>
            </div>

            <div class="pt-3 mt-3 border-t border-white/5 flex justify-end gap-2">
                <button type="button" @click="modal.reject = false" class="px-3 py-1.5 bg-zinc-800 text-zinc-300 rounded-xl text-xs">Cancel</button>
                <button type="button" @click="confirmRejectOrder()" class="px-4 py-1.5 bg-red-600 hover:bg-red-500 text-white font-bold rounded-xl text-xs">Confirm Rejection</button>
            </div>
        </div>
    </div>

    <!-- Assign Rider Modal -->
    <div x-show="modal.assignRider" class="fixed inset-0 z-50 flex items-center justify-center p-3 bg-black/60 backdrop-blur-sm" x-cloak>
        <div class="w-full max-w-sm cupertino-glass rounded-3xl p-5 border border-white/10 shadow-2xl" @click.away="modal.assignRider = false">
            <h3 class="text-sm font-bold text-white flex items-center gap-1.5 mb-2">
                <i data-lucide="bike" class="w-4 h-4 text-sky-400"></i>
                <span>Assign Store Rider</span>
            </h3>
            <p class="text-xs text-zinc-400 mb-3">Select dedicated delivery rider for Order #<span x-text="assignTarget?.id"></span>:</p>

            <div class="space-y-1.5 max-h-48 overflow-y-auto">
                <template x-for="rdr in outletRiders" :key="rdr.id">
                    <button type="button" @click="assignRiderToOrder(rdr)"
                        class="w-full p-2 rounded-xl bg-zinc-900 hover:bg-zinc-800 border border-white/5 flex items-center justify-between text-xs text-left transition-colors">
                        <div>
                            <p class="font-bold text-white" x-text="rdr.name"></p>
                            <p class="text-[9.5px] text-zinc-400" x-text="rdr.phone"></p>
                        </div>
                        <span class="px-2 py-0.5 rounded text-[9.5px] font-bold bg-sky-500/20 text-sky-400">Assign</span>
                    </button>
                </template>
            </div>

            <div class="pt-3 mt-3 border-t border-white/5 flex justify-end">
                <button type="button" @click="modal.assignRider = false" class="px-3 py-1.5 bg-zinc-800 text-zinc-300 rounded-xl text-xs">Cancel</button>
            </div>
        </div>
    </div>

    <!-- Offer Banner Modal -->
    <div x-show="modal.offer" class="fixed inset-0 z-50 flex items-center justify-center p-3 bg-black/60 backdrop-blur-sm" x-cloak>
        <div class="w-full max-w-lg cupertino-glass rounded-3xl p-5 border border-white/10 shadow-2xl max-h-[90vh] overflow-y-auto" @click.away="modal.offer = false">
            
            <div class="flex items-center justify-between pb-3 border-b border-white/5">
                <div class="flex items-center gap-2">
                    <div class="w-7 h-7 rounded-lg bg-orange-500/20 text-[#FF9500] flex items-center justify-center font-bold text-xs">
                        🏷️
                    </div>
                    <div>
                        <h3 class="text-xs font-bold text-white" x-text="offerForm.id ? 'Edit Promo Offer Banner' : 'Create New Promo Offer Banner'"></h3>
                        <p class="text-[10px] text-zinc-400">Offer will be displayed in mobile app auto-carousel &amp; outlet filter</p>
                    </div>
                </div>
                <button type="button" @click="modal.offer = false" class="p-1 rounded-lg text-zinc-400 hover:text-white">
                    <i data-lucide="x" class="w-4 h-4"></i>
                </button>
            </div>

            <!-- Form Fields -->
            <form @submit.prevent="saveOffer()" class="space-y-3.5 mt-3.5">
                
                <!-- Tag & Discount % Row -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div>
                        <label class="block text-[11px] font-bold text-zinc-300 mb-1">Badge Tag</label>
                        <input type="text" x-model="offerForm.tagText" placeholder="e.g. SPECIAL OFFER, WEEKEND DEAL"
                            class="w-full px-3 py-2 rounded-xl bg-zinc-900 border border-white/10 text-white text-xs focus:outline-none focus:border-[#FF9500]">
                    </div>
                    <div>
                        <label class="block text-[11px] font-bold text-zinc-300 mb-1">Discount % Off</label>
                        <div class="relative">
                            <input type="number" min="0" max="90" x-model.number="offerForm.discountPercent" placeholder="e.g. 25, 40"
                                class="w-full px-3 py-2 pr-8 rounded-xl bg-zinc-900 border border-white/10 text-white text-xs font-bold focus:outline-none focus:border-[#FF9500]">
                            <span class="absolute right-3 top-2 text-xs font-bold text-zinc-400">%</span>
                        </div>
                    </div>
                </div>

                <!-- Main Offer Title -->
                <div>
                    <label class="block text-[11px] font-bold text-zinc-300 mb-1">
                        Offer Title <span class="text-red-400">*</span>
                    </label>
                    <input type="text" x-model="offerForm.title" placeholder="e.g. 40% OFF Special Bannu Feast or Wood-Fire Daig Deal" required
                        class="w-full px-3 py-2 rounded-xl bg-zinc-900 border border-white/10 text-white text-xs font-bold focus:outline-none focus:border-[#FF9500]">
                </div>

                <!-- Subtitle / Dishes Included -->
                <div>
                    <label class="block text-[11px] font-bold text-zinc-300 mb-1">Subtitle / Featured Dishes</label>
                    <textarea x-model="offerForm.dishesText" rows="2" placeholder="e.g. Shahi Qorma, Beef Kabab, Degi Biryani, Mutton Karahi, Zarda with Free Raita & Naan"
                        class="w-full px-3 py-2 rounded-xl bg-zinc-900 border border-white/10 text-white text-xs focus:outline-none focus:border-[#FF9500]"></textarea>
                </div>

                <!-- Background Image (File Upload or Direct URL) -->
                <div class="space-y-2">
                    <div class="flex items-center justify-between">
                        <label class="text-[11px] font-bold text-zinc-300">Banner Background Image</label>
                        <div class="flex items-center gap-1 text-[10px]">
                            <button type="button" @click="offerForm.imageMode = 'file'"
                                :class="offerForm.imageMode === 'file' ? 'bg-[#FF9500] text-white font-bold' : 'bg-zinc-800 text-zinc-400'"
                                class="px-2 py-0.5 rounded transition-all">Upload File</button>
                            <button type="button" @click="offerForm.imageMode = 'url'"
                                :class="offerForm.imageMode === 'url' ? 'bg-[#FF9500] text-white font-bold' : 'bg-zinc-800 text-zinc-400'"
                                class="px-2 py-0.5 rounded transition-all">Image URL</button>
                        </div>
                    </div>

                    <!-- File Upload Mode -->
                    <div x-show="offerForm.imageMode === 'file'" class="space-y-1.5">
                        <input type="file" accept="image/*" @change="uploadOfferImageFile($event)"
                            class="block w-full text-xs text-zinc-400 file:mr-2.5 file:py-1.5 file:px-3 file:rounded-xl file:border-0 file:text-[11px] file:font-bold file:bg-[#FF9500]/20 file:text-[#FF9500] hover:file:bg-[#FF9500]/30 cursor-pointer">
                        <p x-show="uploadingOfferImage" class="text-[10px] text-orange-400 flex items-center gap-1">
                            <span class="animate-spin inline-block w-3 h-3 border border-orange-400 border-t-transparent rounded-full"></span>
                            <span>Uploading image to server...</span>
                        </p>
                    </div>

                    <!-- Image URL Mode -->
                    <div x-show="offerForm.imageMode === 'url'">
                        <input type="url" x-model="offerForm.imageUrl" placeholder="https://images.unsplash.com/photo-..."
                            class="w-full px-3 py-2 rounded-xl bg-zinc-900 border border-white/10 text-white text-xs focus:outline-none focus:border-[#FF9500]">
                    </div>

                    <!-- Live Image Thumbnail Preview -->
                    <template x-if="offerForm.imageUrl">
                        <div class="relative w-full h-24 rounded-xl overflow-hidden border border-white/10 bg-zinc-900">
                            <img :src="offerForm.imageUrl" alt="" class="w-full h-full object-cover">
                            <button type="button" @click="offerForm.imageUrl = ''"
                                class="absolute top-1.5 right-1.5 p-1 rounded-full bg-black/60 text-white hover:bg-black/80">
                                <i data-lucide="x" class="w-3 h-3"></i>
                            </button>
                        </div>
                    </template>
                </div>

                <!-- Action Button Text & Visibility -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1">
                    <div>
                        <label class="block text-[11px] font-bold text-zinc-300 mb-1">Button Text</label>
                        <input type="text" x-model="offerForm.buttonText" placeholder="Order Now"
                            class="w-full px-3 py-2 rounded-xl bg-zinc-900 border border-white/10 text-white text-xs focus:outline-none focus:border-[#FF9500]">
                    </div>
                    <div class="flex items-center gap-2 pt-5">
                        <input type="checkbox" id="offerIsVisible" x-model="offerForm.isVisible"
                            class="w-4 h-4 rounded text-orange-500 focus:ring-0 bg-zinc-900 border-white/20">
                        <label for="offerIsVisible" class="text-xs font-semibold text-zinc-200 cursor-pointer">
                            Active &amp; Visible on Mobile App
                        </label>
                    </div>
                </div>

                <!-- Footer Buttons -->
                <div class="pt-3 border-t border-white/5 flex items-center justify-end gap-2">
                    <button type="button" @click="modal.offer = false"
                        class="px-3.5 py-1.5 rounded-xl bg-zinc-800 text-zinc-300 text-xs font-medium hover:bg-zinc-700">
                        Cancel
                    </button>
                    <button type="submit"
                        class="px-4 py-1.5 rounded-xl bg-[#FF9500] hover:bg-orange-500 text-white text-xs font-bold shadow-md shadow-orange-500/20">
                        Save &amp; Publish Offer
                    </button>
                </div>

            </form>

        </div>
    </div>

    <!-- ======================================================================= -->
    <!-- ALPINE CONTROLLER FOR VENDOR PORTAL -->
    <!-- ======================================================================= -->
    <script>
        function vendorApp() {
            return {
                subAdmin: <?= json_encode($adminUser) ?>,
                activeTab: 'analytics',
                foodListingSection: 'dishes',
                storeAvailability: 'open',
                detectingGps: false,
                loading: false,

                // Order Alert Ringtone State
                ringtoneActive: false,
                ringtoneInterval: null,
                alertOrder: null,

                // Top 6 Strict Tabs in User Requested Order
                // [1. Analytics, 2. Food Listing, 3. Customers, 4. Riders, 5. Orders, 6. Profile & Settings]
                tabs: [
                    { id: 'analytics', label: 'Analytics', icon: 'pie-chart' },
                    { id: 'food-listing', label: 'Food Listing', icon: 'utensils' },
                    { id: 'offers', label: 'Offers & Promos', icon: 'tag' },
                    { id: 'customers', label: 'Customers', icon: 'users' },
                    { id: 'riders', label: 'Riders Fleet', icon: 'bike' },
                    { id: 'orders', label: 'Orders Hub', icon: 'shopping-bag' },
                    { id: 'profile', label: 'Profile & Settings', icon: 'store' }
                ],

                // Data Arrays
                vendorStats: {},
                orders: [],
                riders: [],
                vendorCustomers: [],
                foodItems: [],
                daigItems: [],
                vendorBanners: [],

                // Pagination (100 per page standard)
                ridersPage: 1,
                ridersPerPage: 100,
                customersPage: 1,
                customersPerPage: 100,
                ordersPage: 1,
                ordersPerPage: 100,
                foodPage: 1,
                foodPerPage: 100,
                daigPage: 1,
                daigPerPage: 100,

                // Searches & Filters
                riderSearchQuery: '',
                customerSearchQuery: '',
                customerSortBy: 'spent',
                orderSearchQuery: '',
                selectedOrderStatus: 'All',
                selectedOrderType: 'All',
                menuSearchQuery: '',
                foodCategoryFilter: 'All',

                // Drawers & Modals
                sheet: { customer: false, rider: false },
                modal: { rider: false, food: false, daig: false, orderDetail: false, reject: false, assignRider: false, offer: false },
                offerForm: {
                    id: '',
                    tagText: 'SPECIAL OFFER',
                    title: '',
                    discountPercent: 25,
                    dishesText: '',
                    buttonText: 'Order Now',
                    imageUrl: '',
                    isVisible: true,
                    imageMode: 'file',
                },
                uploadingOfferImage: false,
                activeCustomer: null,
                activeRider: null,
                activeOrder: null,
                rejectTarget: null,
                rejectReason: '',
                assignTarget: null,

                // Dedicated "Add Food Listing" State (Restaurant vs Pakwan)
                foodListingMode: 'list', // 'list' | 'add'
                addListingType: 'restaurant', // 'restaurant' | 'pakwan'
                addListingImageMode: 'file', // 'file' | 'url'
                uploadingListingImage: false,
                newListingForm: {
                    name: '',
                    urduName: '',
                    category: 'Biryani',
                    pakwanCategory: 'Shahi Biryani & Pulao',
                    description: '',
                    actualPrice: 650,
                    cutPrice: 1300,
                    showCutPrice: true,
                    isDiscounted: true,
                    discountPercent: 50,
                    promoBadge: '🔥 50% OFF',
                    calories: 520,
                    prepTime: '20-25 mins',
                    foodTag: 'Non-Veg / Meat',
                    location: 'Main Pakwan Kitchen, Islamabad (G-9 Markaz)',
                    fullDaigPrice: 16000,
                    halfDaigPrice: 8500,
                    fullDaigWeight: '12 KG (Serves 35-40 Persons)',
                    halfDaigWeight: '6 KG (Serves 18-20 Persons)',
                    deliveryNotice: 'Order 3-4 hours in advance',
                    imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&q=80'
                },

                // Forms
                riderForm: { name: '', phone: '', email: '', password: '123456', city: 'Lahore' },
                editingRider: {},
                foodForm: { id: '', name: '', category: 'Biryani', price: 0, calories: 500, isDiscounted: false, discountPercent: 50, discountPrice: 0, promoBadge: '🔥 50% OFF', description: '', imageUrl: '' },
                daigForm: { id: '', name: '', urduName: '', category: 'Biryani & Pulao', fullDaigPrice: 15000, halfDaigPrice: 8000, promoBadge: '', deliveryNotice: '3-4 hours notice', imageUrl: '' },
                allCategories: [],
                get allowedFoodCategories() {
                    const bType = this.subAdmin?.businessType || 'restaurant';
                    const list = this.allCategories.filter(c => {
                        if (c.name === 'All') return false;
                        if (bType === 'both') return true;
                        return c.type === bType || c.type === 'both';
                    });
                    if (list.length === 0) {
                        return ['Biryani', 'Karahi & Handi', 'BBQ & Grill', 'Burgers', 'Pulao', 'Desi Gravy', 'Desserts', 'Beverages'];
                    }
                    return list.map(c => c.name);
                },
                get allowedDaigCategories() {
                    const list = this.allCategories.filter(c => {
                        if (c.name === 'All') return false;
                        return c.type === 'pakwan' || c.type === 'both';
                    });
                    if (list.length === 0) {
                        return ['Biryani & Pulao', 'Qorma & Karahi', 'Haleem & Nihari', 'Sweet & Desserts', 'Shahi Daig Catering'];
                    }
                    return list.map(c => c.name);
                },
                profileForm: {
                    businessName: '<?= addslashes($adminUser['businessName'] ?? '') ?>',
                    name: '<?= addslashes($adminUser['name'] ?? '') ?>',
                    phone: '<?= addslashes($adminUser['phone'] ?? '') ?>',
                    city: '<?= addslashes($adminUser['city'] ?? 'Lahore') ?>',
                    address: '<?= addslashes($adminUser['address'] ?? '') ?>',
                    businessType: '<?= addslashes($adminUser['businessType'] ?? 'pakwan') ?>',
                    latitude: <?= (float)($adminUser['latitude'] ?? 31.5204) ?>,
                    longitude: <?= (float)($adminUser['longitude'] ?? 74.3587) ?>
                },
                passwordForm: { newPassword: '', confirmPassword: '' },

                toast: { visible: false, message: '', type: 'success' },
                storeMap: null,
                storeMarker: null,
                lineChartInstance: null,
                barChartInstance: null,

                async initApp() {
                    await this.refreshAll();
                    setTimeout(() => this.initCharts(), 120);
                    // Auto poll for orders every 20 seconds
                    setInterval(() => this.fetchOrdersSilent(), 20000);
                    this.$nextTick(() => lucide.createIcons());
                },

                initCharts() {
                    if (typeof Chart === 'undefined') {
                        setTimeout(() => this.initCharts(), 150);
                        return;
                    }
                    this.$nextTick(() => {
                        this.renderLineChart();
                        this.renderBarChart();
                    });
                },

                renderLineChart() {
                    const canvas = document.getElementById('vendorPerformanceLineChart');
                    if (!canvas) return;
                    if (this.lineChartInstance) {
                        this.lineChartInstance.destroy();
                        this.lineChartInstance = null;
                    }

                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    const deliveredCount = this.getStatusCount('Delivered') || (this.vendorStats.completedOrders || 0);
                    const rejectedCount = this.getStatusCount('Cancelled') || (this.vendorStats.cancelledOrders || 0);
                    const grossSalesK = Math.round((Number(this.vendorStats.grossSales || 18000)) / 1000);
                    const totalItems = this.vendorFoodItems.length + this.vendorDaigItems.length;

                    const salesData = [
                        Math.max(1, Math.round(grossSalesK * 0.10)),
                        Math.max(2, Math.round(grossSalesK * 0.12)),
                        Math.max(3, Math.round(grossSalesK * 0.15)),
                        Math.max(3, Math.round(grossSalesK * 0.14)),
                        Math.max(4, Math.round(grossSalesK * 0.18)),
                        Math.max(5, Math.round(grossSalesK * 0.22)),
                        Math.max(6, Math.round(grossSalesK * 0.25))
                    ];

                    const deliveredData = [
                        Math.max(0, Math.round(deliveredCount * 0.10)),
                        Math.max(0, Math.round(deliveredCount * 0.12)),
                        Math.max(1, Math.round(deliveredCount * 0.15)),
                        Math.max(1, Math.round(deliveredCount * 0.14)),
                        Math.max(1, Math.round(deliveredCount * 0.18)),
                        Math.max(2, Math.round(deliveredCount * 0.22)),
                        Math.max(2, Math.round(deliveredCount * 0.25))
                    ];

                    const rejectedData = [
                        Math.round(rejectedCount * 0.1),
                        Math.round(rejectedCount * 0.2),
                        Math.round(rejectedCount * 0.1),
                        Math.round(rejectedCount * 0.3),
                        Math.round(rejectedCount * 0.1),
                        Math.round(rejectedCount * 0.2),
                        Math.round(rejectedCount * 0.2)
                    ];

                    const itemsData = [
                        Math.max(1, totalItems - 3),
                        Math.max(1, totalItems - 2),
                        Math.max(1, totalItems - 2),
                        Math.max(1, totalItems - 1),
                        Math.max(1, totalItems - 1),
                        totalItems,
                        totalItems
                    ];

                    const ctx = canvas.getContext('2d');
                    const salesGradient = ctx.createLinearGradient(0, 0, 0, 300);
                    salesGradient.addColorStop(0, 'rgba(255, 149, 0, 0.28)');
                    salesGradient.addColorStop(1, 'rgba(255, 149, 0, 0.00)');

                    this.lineChartInstance = new Chart(ctx, {
                        type: 'line',
                        data: {
                            labels: days,
                            datasets: [
                                {
                                    label: 'Total Sales (Rs. in K)',
                                    data: salesData,
                                    borderColor: '#FF9500',
                                    backgroundColor: salesGradient,
                                    fill: true,
                                    tension: 0.35,
                                    borderWidth: 2.5,
                                    pointBackgroundColor: '#FF9500',
                                    pointBorderColor: '#ffffff',
                                    pointRadius: 4,
                                    pointHoverRadius: 6
                                },
                                {
                                    label: 'Delivered (Success)',
                                    data: deliveredData,
                                    borderColor: '#10B981',
                                    backgroundColor: 'transparent',
                                    tension: 0.35,
                                    borderWidth: 2,
                                    pointBackgroundColor: '#10B981',
                                    pointRadius: 3.5
                                },
                                {
                                    label: 'Rejected Orders',
                                    data: rejectedData,
                                    borderColor: '#EF4444',
                                    backgroundColor: 'transparent',
                                    tension: 0.35,
                                    borderWidth: 2,
                                    pointBackgroundColor: '#EF4444',
                                    pointRadius: 3.5
                                },
                                {
                                    label: 'Menu Items (Dishes + Daigs)',
                                    data: itemsData,
                                    borderColor: '#FBBF24',
                                    backgroundColor: 'transparent',
                                    borderDash: [4, 4],
                                    tension: 0.2,
                                    borderWidth: 1.8,
                                    pointBackgroundColor: '#FBBF24',
                                    pointRadius: 3
                                }
                            ]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            plugins: {
                                legend: { display: false },
                                tooltip: {
                                    backgroundColor: 'rgba(24, 24, 27, 0.95)',
                                    titleColor: '#ffffff',
                                    bodyColor: '#e4e4e7',
                                    borderColor: 'rgba(255, 255, 255, 0.12)',
                                    borderWidth: 1,
                                    padding: 10,
                                    cornerRadius: 10
                                }
                            },
                            scales: {
                                x: {
                                    grid: { color: 'rgba(255, 255, 255, 0.04)' },
                                    ticks: { color: '#a1a1aa', font: { size: 11, weight: '600' } }
                                },
                                y: {
                                    grid: { color: 'rgba(255, 255, 255, 0.05)' },
                                    ticks: { color: '#a1a1aa', font: { size: 10.5 } }
                                }
                            }
                        }
                    });
                },

                renderBarChart() {
                    const canvas = document.getElementById('vendorUsersRidersBarChart');
                    if (!canvas) return;
                    if (this.barChartInstance) {
                        this.barChartInstance.destroy();
                        this.barChartInstance = null;
                    }

                    const labels = ['Central', 'North', 'South', 'East', 'West'];
                    const totalCust = this.vendorCustomers.length || (this.vendorStats.totalCustomers || 18);
                    const totalRiders = this.outletRiders.length || 4;

                    const custData = [
                        Math.max(1, Math.round(totalCust * 0.32)),
                        Math.max(1, Math.round(totalCust * 0.24)),
                        Math.max(1, Math.round(totalCust * 0.20)),
                        Math.max(1, Math.round(totalCust * 0.14)),
                        Math.max(1, Math.round(totalCust * 0.10))
                    ];

                    const ridersData = [
                        Math.max(1, Math.round(totalRiders * 0.40)),
                        Math.max(1, Math.round(totalRiders * 0.25)),
                        Math.max(1, Math.round(totalRiders * 0.20)),
                        Math.max(1, Math.round(totalRiders * 0.10)),
                        Math.max(1, Math.round(totalRiders * 0.05))
                    ];

                    const ctx = canvas.getContext('2d');
                    this.barChartInstance = new Chart(ctx, {
                        type: 'bar',
                        data: {
                            labels: labels,
                            datasets: [
                                {
                                    label: 'Total Customers',
                                    data: custData,
                                    backgroundColor: 'rgba(192, 132, 252, 0.85)',
                                    borderRadius: 6,
                                    borderSkipped: false
                                },
                                {
                                    label: 'Fleet Riders',
                                    data: ridersData,
                                    backgroundColor: 'rgba(56, 189, 248, 0.85)',
                                    borderRadius: 6,
                                    borderSkipped: false
                                }
                            ]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            plugins: {
                                legend: { display: false },
                                tooltip: {
                                    backgroundColor: 'rgba(24, 24, 27, 0.95)',
                                    titleColor: '#ffffff',
                                    bodyColor: '#e4e4e7',
                                    borderColor: 'rgba(255, 255, 255, 0.12)',
                                    borderWidth: 1,
                                    padding: 10,
                                    cornerRadius: 10
                                }
                            },
                            scales: {
                                x: {
                                    grid: { display: false },
                                    ticks: { color: '#a1a1aa', font: { size: 11, weight: '600' } }
                                },
                                y: {
                                    grid: { color: 'rgba(255, 255, 255, 0.05)' },
                                    ticks: { color: '#a1a1aa', font: { size: 10.5 }, precision: 0 }
                                }
                            }
                        }
                    });
                },

                get activeOrdersCount() {
                    return this.orders.filter(o => ['Pending', 'Accepted', 'Preparing', 'On the Way', 'Arrived'].includes(o.status)).length;
                },

                get todayRecentOrders() {
                    const todayStr = new Date().toISOString().split('T')[0];
                    const todays = this.orders.filter(o => (o.orderDate || o.createdAt || '').startsWith(todayStr));
                    if (todays.length > 0) {
                        return [...todays].sort((a, b) => new Date(b.orderDate || b.createdAt || 0) - new Date(a.orderDate || a.createdAt || 0));
                    }
                    // Fallback to latest 10 most recent orders so the list is always active & visible
                    return [...this.orders].sort((a, b) => new Date(b.orderDate || b.createdAt || 0) - new Date(a.orderDate || a.createdAt || 0)).slice(0, 10);
                },

                get totalMenuCount() {
                    return this.vendorFoodItems.length + this.vendorDaigItems.length;
                },

                currentTabLabel() {
                    const t = this.tabs.find(x => x.id === this.activeTab);
                    return t ? t.label : 'Analytics';
                },

                setTab(tabId) {
                    this.activeTab = tabId;
                    if (tabId === 'analytics') {
                        setTimeout(() => this.initCharts(), 120);
                    }
                    if (tabId === 'profile') {
                        setTimeout(() => this.initLeafletMap(), 150);
                    }
                    this.$nextTick(() => lucide.createIcons());
                },

                showToast(message, type = 'success') {
                    this.toast = { visible: true, message, type };
                    setTimeout(() => { this.toast.visible = false; }, 3200);
                },

                playOrderChime() {
                    try {
                        const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
                        const osc = audioCtx.createOscillator();
                        const gain = audioCtx.createGain();
                        osc.connect(gain);
                        gain.connect(audioCtx.destination);
                        osc.type = 'sine';
                        // High-frequency 2-tone doorbell chime (Ding-Dong)
                        osc.frequency.setValueAtTime(784.00, audioCtx.currentTime); // G5 (Ding)
                        osc.frequency.setValueAtTime(659.25, audioCtx.currentTime + 0.22); // E5 (Dong)
                        gain.gain.setValueAtTime(0.35, audioCtx.currentTime);
                        gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.7);
                        osc.start();
                        osc.stop(audioCtx.currentTime + 0.7);
                    } catch(e) {}
                },

                startOrderAlertRingtone(order = null) {
                    this.alertOrder = order;
                    this.ringtoneActive = true;
                    this.playOrderChime();
                    if (this.ringtoneInterval) clearInterval(this.ringtoneInterval);
                    this.ringtoneInterval = setInterval(() => {
                        if (this.ringtoneActive) {
                            this.playOrderChime();
                        } else {
                            clearInterval(this.ringtoneInterval);
                        }
                    }, 2800);
                    this.$nextTick(() => lucide.createIcons());
                },

                stopOrderAlertRingtone() {
                    this.ringtoneActive = false;
                    if (this.ringtoneInterval) {
                        clearInterval(this.ringtoneInterval);
                        this.ringtoneInterval = null;
                    }
                },

                testOrderRingtone() {
                    if (this.ringtoneActive) {
                        this.stopOrderAlertRingtone();
                        this.showToast('🔕 Alert bell silenced');
                    } else {
                        const sampleOrder = this.orders.length > 0 ? this.orders[0] : { id: 'FC-TEST', totalAmount: 2450, customerName: 'Live Test Customer' };
                        this.startOrderAlertRingtone(sampleOrder);
                        this.showToast('🔔 Order Alert Ringtone started! (Ding-Dong sound looping)');
                    }
                },

                sendWhatsAppDispatchAlert(ord) {
                    if (!ord) return;
                    const rawPhone = (ord.customerPhone || '').replace(/[^0-9]/g, '');
                    let cleanPhone = rawPhone;
                    if (cleanPhone.startsWith('0')) {
                        cleanPhone = '92' + cleanPhone.substring(1);
                    } else if (!cleanPhone.startsWith('92')) {
                        cleanPhone = '92' + cleanPhone;
                    }
                    const riderName = ord.riderName || 'Dedicated Rider';
                    const riderPhone = ord.riderPhone || 'Contact store';
                    const restaurant = ord.restaurantName || this.subAdmin.businessName || 'Cravee FoodCourt & Shahi Pakwan';
                    const amount = Math.round(ord.totalAmount || 0);

                    let eventText = '';
                    if (ord.event_date || ord.eventDate) {
                        const ed = ord.event_date || ord.eventDate;
                        const et = ord.event_time || ord.eventTime || '';
                        eventText = `📅 Delivery Schedule: ${ed} ${et}\n`;
                    }

                    const text = `Assalam-o-Alaikum ${ord.customerName}! 🍽️\n` +
                        `Aapka order #${ord.id} (${restaurant}) tayar ho kar Rider ke hawale kar diya gaya hai aur raste mein hai.\n\n` +
                        (eventText ? `${eventText}\n` : '') +
                        `🛵 Rider Name: ${riderName}\n` +
                        `📞 Rider Contact: ${riderPhone}\n` +
                        `💵 Cash to Pay (COD): Rs. ${amount}\n` +
                        `📍 Delivery Address: ${ord.deliveryAddress}\n\n` +
                        `Kisi bhi maslay ki surat mein rider se direct rabta karein.\n` +
                        `Shukriya! ${restaurant}`;

                    const waUrl = `https://wa.me/${cleanPhone}?text=${encodeURIComponent(text)}`;
                    window.open(waUrl, '_blank');
                    this.showToast(`💬 WhatsApp Dispatch alert opened for ${ord.customerName}!`);
                },

                calcShare(val, total) {
                    if (!total || total === 0) return 0;
                    return Math.round(((val || 0) / total) * 100);
                },

                getBusinessTypeLabel(type) {
                    switch (type) {
                        case 'pakwan': return '👑 Shahi Pakwan Center';
                        case 'both': return '👑🍽️ Hybrid (Both)';
                        default: return '🍽️ Restaurant';
                    }
                },

                formatDateShort(iso) {
                    if (!iso) return '—';
                    const d = new Date(iso);
                    if (isNaN(d.getTime())) return iso;
                    return d.toLocaleDateString([], { day: '2-digit', month: 'short', year: 'numeric' });
                },

                formatOrderItemsSummary(items) {
                    if (!items) return 'Standard Platter';
                    if (typeof items === 'string') {
                        try { items = JSON.parse(items); } catch(e) { return items; }
                    }
                    if (Array.isArray(items)) {
                        return items.map(i => typeof i === 'string' ? i : `${i.quantity || 1}x ${i.name || 'Item'}`).join(', ');
                    }
                    return 'Platter Item';
                },

                getStatusBadgeClass(status) {
                    switch (status) {
                        case 'Pending': return 'bg-amber-500/15 text-amber-400 border border-amber-500/25';
                        case 'Accepted': return 'bg-sky-500/15 text-sky-400 border border-sky-500/25';
                        case 'Preparing': return 'bg-amber-500/15 text-amber-400 border border-amber-500/25';
                        case 'On the Way': return 'bg-orange-500/15 text-[#FF9500] border border-orange-500/25';
                        case 'Arrived': return 'bg-purple-500/15 text-purple-400 border border-purple-500/25';
                        case 'Delivered': return 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/25';
                        case 'Cancelled': return 'bg-red-500/15 text-red-400 border border-red-500/25';
                        default: return 'bg-zinc-800 text-zinc-300';
                    }
                },

                getStatusCount(st) {
                    return this.orders.filter(o => o.status === st).length;
                },

                getOrdersCountByStatus(st) {
                    if (st === 'All') return this.orders.length;
                    return this.orders.filter(o => o.status === st).length;
                },

                get outletRiders() {
                    return this.riders.filter(r => r.assigned_sub_admin_id === this.subAdmin.id);
                },

                getActiveOrdersForRider(riderName) {
                    if (!riderName) return [];
                    return this.orders.filter(o => o.riderName === riderName && ['Accepted', 'Preparing', 'On the Way', 'Arrived'].includes(o.status));
                },

                getCustomerOrders(phone) {
                    if (!phone) return [];
                    return this.orders.filter(o => o.customerPhone === phone);
                },

                get topBestsellers() {
                    const combined = [...this.vendorFoodItems, ...this.vendorDaigItems];
                    return combined.sort((a, b) => (b.price || 0) - (a.price || 0));
                },

                get vendorFoodItems() {
                    return this.foodItems.filter(f => f.sub_admin_id === this.subAdmin.id || f.restaurantId === this.subAdmin.id);
                },

                get vendorDaigItems() {
                    return this.daigItems.filter(d => d.sub_admin_id === this.subAdmin.id);
                },

                // Filtered Lists & Pagination
                get filteredRidersList() {
                    const q = (this.riderSearchQuery || '').toLowerCase();
                    return this.outletRiders.filter(r => {
                        return (r.name || '').toLowerCase().includes(q) ||
                               (r.phone || '').toLowerCase().includes(q) ||
                               (r.id || '').toLowerCase().includes(q);
                    });
                },
                get paginatedRiders() {
                    const start = (this.ridersPage - 1) * this.ridersPerPage;
                    return this.filteredRidersList.slice(start, start + this.ridersPerPage);
                },

                get filteredCustomersList() {
                    const q = (this.customerSearchQuery || '').toLowerCase();
                    return this.vendorCustomers.filter(c => {
                        return (c.customerName || '').toLowerCase().includes(q) ||
                               (c.customerPhone || '').toLowerCase().includes(q) ||
                               (c.deliveryAddress || '').toLowerCase().includes(q);
                    }).sort((a, b) => {
                        if (this.customerSortBy === 'spent') return (b.totalSpent || 0) - (a.totalSpent || 0);
                        if (this.customerSortBy === 'orders') return (b.totalOrders || 0) - (a.totalOrders || 0);
                        return new Date(b.lastOrderDate || 0) - new Date(a.lastOrderDate || 0);
                    });
                },
                get paginatedCustomers() {
                    const start = (this.customersPage - 1) * this.customersPerPage;
                    return this.filteredCustomersList.slice(start, start + this.customersPerPage);
                },

                get filteredOrdersList() {
                    const q = (this.orderSearchQuery || '').toLowerCase();
                    return this.orders.filter(o => {
                        if (this.selectedOrderStatus !== 'All' && o.status !== this.selectedOrderStatus) return false;
                        if (this.selectedOrderType === 'daig' && !o.isDaigBooking) return false;
                        if (this.selectedOrderType === 'food' && o.isDaigBooking) return false;
                        if (q) {
                            const match = (o.id || '').toLowerCase().includes(q) ||
                                          (o.customerName || '').toLowerCase().includes(q) ||
                                          (o.customerPhone || '').toLowerCase().includes(q) ||
                                          (o.riderName || '').toLowerCase().includes(q);
                            if (!match) return false;
                        }
                        return true;
                    });
                },
                get paginatedOrders() {
                    const start = (this.ordersPage - 1) * this.ordersPerPage;
                    return this.filteredOrdersList.slice(start, start + this.ordersPerPage);
                },

                get filteredFoodItems() {
                    const q = (this.menuSearchQuery || '').toLowerCase();
                    const cat = this.foodCategoryFilter;
                    return this.vendorFoodItems.filter(f => {
                        const matchesQ = (f.name || '').toLowerCase().includes(q) || (f.category || '').toLowerCase().includes(q);
                        const matchesCat = (cat === 'All' || f.category === cat);
                        return matchesQ && matchesCat;
                    });
                },
                get paginatedFoodItems() {
                    const start = (this.foodPage - 1) * this.foodPerPage;
                    return this.filteredFoodItems.slice(start, start + this.foodPerPage);
                },

                get filteredDaigItems() {
                    const q = (this.menuSearchQuery || '').toLowerCase();
                    return this.vendorDaigItems.filter(d => (d.name || '').toLowerCase().includes(q) || (d.urduName || '').toLowerCase().includes(q));
                },
                get paginatedDaigItems() {
                    const start = (this.daigPage - 1) * this.daigPerPage;
                    return this.filteredDaigItems.slice(start, start + this.daigPerPage);
                },

                // API Calls & Data Sync
                async refreshAll() {
                    this.loading = true;
                    try {
                        const sid = this.subAdmin.id;
                        const [statsRes, custRes, ordRes, ridRes, foodRes, daigRes, banRes, catRes] = await Promise.all([
                            fetch(`../api/vendor/stats?sub_admin_id=${sid}`).then(r => r.json()).catch(() => ({ data: {} })),
                            fetch(`../api/vendor/customers?sub_admin_id=${sid}`).then(r => r.json()).catch(() => ({ data: [] })),
                            fetch(`../api/orders?sub_admin_id=${sid}`).then(r => r.json()).catch(() => ({ data: [] })),
                            fetch(`../api/users?role=rider`).then(r => r.json()).catch(() => ({ data: [] })),
                            fetch(`../api/food-items`).then(r => r.json()).catch(() => ({ data: [] })),
                            fetch(`../api/daig-items`).then(r => r.json()).catch(() => ({ data: [] })),
                            fetch(`../api/banners?sub_admin_id=${sid}`).then(r => r.json()).catch(() => ({ data: [] })),
                            fetch(`../api/categories`).then(r => r.json()).catch(() => ({ data: [] }))
                        ]);

                        if (statsRes?.data) this.vendorStats = statsRes.data;
                        if (custRes?.data) this.vendorCustomers = custRes.data;
                        if (ordRes?.data) this.orders = ordRes.data;
                        if (ridRes?.data) this.riders = ridRes.data;
                        if (foodRes?.data) this.foodItems = foodRes.data;
                        if (daigRes?.data) this.daigItems = daigRes.data;
                        if (banRes?.data) this.vendorBanners = banRes.data;
                        if (catRes?.data) this.allCategories = catRes.data;
                    } catch (e) {
                        this.showToast('Sync error: ' + e.message, 'error');
                    } finally {
                        this.loading = false;
                        if (this.activeTab === 'analytics') {
                            setTimeout(() => this.initCharts(), 120);
                        }
                        this.$nextTick(() => lucide.createIcons());
                    }
                },

                // Promotional Offers & Banners Management
                openOfferModal(offer = null) {
                    if (offer) {
                        this.offerForm = {
                            id: offer.id,
                            tagText: offer.tagText || 'SPECIAL OFFER',
                            title: offer.title || '',
                            discountPercent: offer.discountPercent || 20,
                            dishesText: offer.dishesText || '',
                            buttonText: offer.buttonText || 'Order Now',
                            imageUrl: offer.imageUrl || '',
                            isVisible: offer.isVisible !== false,
                            imageMode: (offer.imageUrl && offer.imageUrl.startsWith('http')) ? 'url' : 'file',
                        };
                    } else {
                        this.offerForm = {
                            id: '',
                            tagText: 'SPECIAL OFFER',
                            title: '',
                            discountPercent: 25,
                            dishesText: '',
                            buttonText: 'Order Now',
                            imageUrl: '',
                            isVisible: true,
                            imageMode: 'file',
                        };
                    }
                    this.modal.offer = true;
                    this.$nextTick(() => lucide.createIcons());
                },

                async uploadOfferImageFile(e) {
                    const file = e.target.files[0];
                    if (!file) return;
                    this.uploadingOfferImage = true;
                    try {
                        const fd = new FormData();
                        fd.append('image', file);
                        const res = await fetch('../api/upload', { method: 'POST', body: fd });
                        const data = await res.json();
                        if (data.success && data.url) {
                            this.offerForm.imageUrl = data.url;
                            this.showToast('✅ Offer banner image uploaded!');
                        } else {
                            this.showToast(data.message || 'Image upload failed', 'error');
                        }
                    } catch (err) {
                        this.showToast('Upload error: ' + err.message, 'error');
                    } finally {
                        this.uploadingOfferImage = false;
                    }
                },

                async saveOffer() {
                    if (!this.offerForm.title.trim()) {
                        this.showToast('Please enter an offer title', 'error');
                        return;
                    }
                    try {
                        const isEdit = !!this.offerForm.id;
                        const url = isEdit ? `../api/banners/${this.offerForm.id}` : '../api/banners';
                        const method = isEdit ? 'PUT' : 'POST';
                        const payload = {
                            ...this.offerForm,
                            sub_admin_id: this.subAdmin.id,
                            discountPercent: parseInt(this.offerForm.discountPercent) || 0,
                            tagText: this.offerForm.tagText || 'SPECIAL OFFER',
                            buttonText: this.offerForm.buttonText || 'Order Now',
                            bgGradient: ['#EA580C', '#C2410C']
                        };
                        const res = await fetch(url, {
                            method,
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify(payload)
                        });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast(`✅ Offer banner ${isEdit ? 'updated' : 'published'} successfully!`);
                            this.modal.offer = false;
                            await this.refreshAll();
                        } else {
                            this.showToast(data.message || 'Failed to save offer', 'error');
                        }
                    } catch (e) {
                        this.showToast('Error saving offer: ' + e.message, 'error');
                    }
                },

                async deleteOffer(b) {
                    if (!confirm(`Are you sure you want to delete offer "${b.title}"?`)) return;
                    try {
                        const res = await fetch(`../api/banners/${b.id}`, { method: 'DELETE' });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast('🗑️ Offer deleted successfully');
                            await this.refreshAll();
                        } else {
                            this.showToast(data.message || 'Failed to delete offer', 'error');
                        }
                    } catch (e) {
                        this.showToast('Delete error: ' + e.message, 'error');
                    }
                },

                async toggleOfferVisibility(b) {
                    try {
                        const newVis = !b.isVisible;
                        const res = await fetch(`../api/banners/${b.id}`, {
                            method: 'PUT',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                                ...b,
                                isVisible: newVis,
                                sub_admin_id: this.subAdmin.id
                            })
                        });
                        const data = await res.json();
                        if (data.success) {
                            b.isVisible = newVis;
                            this.showToast(`Offer is now ${newVis ? 'active & visible' : 'hidden'}`);
                        }
                    } catch (e) {
                        this.showToast('Error updating status: ' + e.message, 'error');
                    }
                },

                // Rider Block / Unblock Action
                async toggleRiderBan(rdr) {
                    const actionText = rdr.banned ? 'unblock' : 'block';
                    if (!confirm(`Are you sure you want to ${actionText} rider ${rdr.name}?`)) return;
                    try {
                        const res = await fetch(`../api/users/${rdr.id}/ban`, {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ banned: !rdr.banned })
                        });
                        const data = await res.json();
                        if (data.success) {
                            rdr.banned = !rdr.banned;
                            this.showToast(data.message || `Rider ${actionText}ed successfully!`);
                            this.$nextTick(() => lucide.createIcons());
                        } else {
                            this.showToast(data.message || 'Action failed', 'error');
                        }
                    } catch(e) {
                        this.showToast('Error: ' + e.message, 'error');
                    }
                },

                // Customer Block / Unblock Action
                async toggleCustomerBan(cust) {
                    const actionText = cust.banned ? 'unblock' : 'block';
                    if (!confirm(`Are you sure you want to ${actionText} customer ${cust.customerName || cust.customerPhone}?`)) return;
                    try {
                        const res = await fetch(`../api/vendor/customers/ban`, {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ phone: cust.customerPhone, banned: !cust.banned })
                        });
                        const data = await res.json();
                        if (data.success) {
                            cust.banned = !cust.banned;
                            this.showToast(data.message || `Customer ${actionText}ed successfully!`);
                            this.$nextTick(() => lucide.createIcons());
                        } else {
                            this.showToast(data.message || 'Action failed', 'error');
                        }
                    } catch(e) {
                        this.showToast('Error: ' + e.message, 'error');
                    }
                },

                async fetchOrdersSilent() {
                    try {
                        const res = await fetch(`../api/orders?sub_admin_id=${this.subAdmin.id}`);
                        const data = await res.json();
                        if (data?.data) {
                            if (data.data.length > this.orders.length) {
                                const latestOrder = data.data[0];
                                this.startOrderAlertRingtone(latestOrder);
                                this.showToast('🔔 New Customer Order Placed in Kitchen!');
                            }
                            this.orders = data.data;
                        }
                    } catch(e) {}
                },

                // Workflow Actions
                async updateOrderStatus(orderId, status) {
                    try {
                        const res = await fetch(`../api/orders/${orderId}/status`, {
                            method: 'PATCH',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ status })
                        });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast(`✅ Order #${orderId} marked as ${status}!`);
                            await this.refreshAll();
                        } else {
                            this.showToast(data.message || 'Status update failed', 'error');
                        }
                    } catch(e) {
                        this.showToast('Error: ' + e.message, 'error');
                    }
                },

                openRejectModal(ord) {
                    this.rejectTarget = ord;
                    this.rejectReason = 'Kitchen over-capacity';
                    this.modal.reject = true;
                },

                async confirmRejectOrder() {
                    if (!this.rejectTarget) return;
                    try {
                        const res = await fetch(`../api/orders/${this.rejectTarget.id}/status`, {
                            method: 'PATCH',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                                status: 'Cancelled',
                                rejectionReason: this.rejectReason
                            })
                        });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast(`Order #${this.rejectTarget.id} rejected.`);
                            this.modal.reject = false;
                            await this.refreshAll();
                        }
                    } catch(e) {
                        this.showToast('Reject error: ' + e.message, 'error');
                    }
                },

                openAssignRiderModal(ord) {
                    this.assignTarget = ord;
                    this.modal.assignRider = true;
                    this.$nextTick(() => lucide.createIcons());
                },

                async assignRiderToOrder(rdr) {
                    if (!this.assignTarget) return;
                    const assignedOrd = { ...this.assignTarget, riderName: rdr.name, riderPhone: rdr.phone };
                    try {
                        const res = await fetch(`../api/orders/${this.assignTarget.id}/status`, {
                            method: 'PATCH',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                                riderName: rdr.name,
                                riderPhone: rdr.phone,
                                status: 'On the Way'
                            })
                        });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast(`🛵 Order #${this.assignTarget.id} assigned to ${rdr.name}!`);
                            this.modal.assignRider = false;
                            this.sendWhatsAppDispatchAlert(assignedOrd);
                            await this.refreshAll();
                        }
                    } catch(e) {
                        this.showToast('Assign error: ' + e.message, 'error');
                    }
                },

                openOrderDetailModal(ord) {
                    this.activeOrder = ord;
                    this.modal.orderDetail = true;
                    this.$nextTick(() => lucide.createIcons());
                },

                // Sheets
                openCustomerSheet(cust) {
                    this.activeCustomer = cust;
                    this.sheet.customer = true;
                    this.$nextTick(() => lucide.createIcons());
                },

                viewRiderSheet(rdr) {
                    this.activeRider = rdr;
                    this.sheet.rider = true;
                    this.$nextTick(() => lucide.createIcons());
                },

                // Rider CRUD
                openCreateRiderModal() {
                    this.editingRider = {};
                    this.riderForm = { name: '', phone: '', email: '', password: '123456', city: this.subAdmin.city || 'Lahore' };
                    this.modal.rider = true;
                    this.$nextTick(() => lucide.createIcons());
                },

                editRider(rdr) {
                    this.editingRider = rdr;
                    this.riderForm = { ...rdr, password: '123456' };
                    this.modal.rider = true;
                    this.$nextTick(() => lucide.createIcons());
                },

                async saveRiderForm() {
                    try {
                        const url = this.editingRider.id ? `../api/users/${this.editingRider.id}` : `../api/users`;
                        const method = this.editingRider.id ? 'PUT' : 'POST';
                        const res = await fetch(url, {
                            method,
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                                ...this.riderForm,
                                role: 'rider',
                                assigned_sub_admin_id: this.subAdmin.id,
                                outlet_name: this.subAdmin.businessName || this.subAdmin.name
                            })
                        });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast('✅ Rider details saved successfully!');
                            this.modal.rider = false;
                            await this.refreshAll();
                        } else {
                            this.showToast(data.message || 'Action failed', 'error');
                        }
                    } catch(e) {
                        this.showToast('Rider save error: ' + e.message, 'error');
                    }
                },

                async deleteRider(rdr) {
                    if (!confirm(`Are you sure you want to remove rider ${rdr.name}?`)) return;
                    try {
                        const res = await fetch(`../api/users/${rdr.id}`, { method: 'DELETE' });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast(`Rider ${rdr.name} removed.`);
                            await this.refreshAll();
                        }
                    } catch(e) {
                        this.showToast('Delete error: ' + e.message, 'error');
                    }
                },

                // ===============================================================
                // DEDICATED "ADD FOOD LISTING" PAGE METHODS (RESTAURANT & PAKWAN)
                // ===============================================================
                openAddListingPage(type = 'restaurant') {
                    this.foodListingMode = 'add';
                    this.resetNewListingForm(type);
                    this.$nextTick(() => lucide.createIcons());
                },

                resetNewListingForm(type = 'restaurant') {
                    this.addListingType = type;
                    this.newListingForm = {
                        name: '',
                        urduName: '',
                        category: 'Biryani',
                        pakwanCategory: 'Shahi Biryani & Pulao',
                        description: '',
                        actualPrice: type === 'restaurant' ? 650 : 16000,
                        cutPrice: type === 'restaurant' ? 1300 : 20000,
                        showCutPrice: true,
                        isDiscounted: true,
                        discountPercent: type === 'restaurant' ? 50 : 20,
                        promoBadge: type === 'restaurant' ? '🔥 50% OFF' : 'SPECIAL SHAHI DEG',
                        calories: 520,
                        prepTime: '20-25 mins',
                        foodTag: 'Non-Veg / Meat',
                        location: 'Main Pakwan Kitchen, Islamabad (G-9 Markaz)',
                        fullDaigPrice: 16000,
                        halfDaigPrice: 8500,
                        fullDaigWeight: '12 KG (Serves 35-40 Persons)',
                        halfDaigWeight: '6 KG (Serves 18-20 Persons)',
                        deliveryNotice: 'Order 3-4 hours in advance',
                        imageUrl: type === 'restaurant' 
                            ? 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&q=80'
                            : 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80'
                    };
                },

                recalcListingDiscount(source) {
                    if (this.addListingType === 'restaurant') {
                        const cut = Number(this.newListingForm.cutPrice) || 0;
                        let pct = Number(this.newListingForm.discountPercent) || 0;
                        let act = Number(this.newListingForm.actualPrice) || 0;

                        if (source === 'cut' || source === 'percent') {
                            if (cut > 0 && pct >= 0) {
                                this.newListingForm.actualPrice = Math.round(cut * (1 - pct / 100));
                            }
                        } else if (source === 'actual') {
                            if (cut > 0 && act > 0 && act <= cut) {
                                this.newListingForm.discountPercent = Math.round(((cut - act) / cut) * 100);
                            }
                        }
                        if (this.newListingForm.discountPercent > 0) {
                            this.newListingForm.promoBadge = `🔥 ${this.newListingForm.discountPercent}% OFF`;
                        }
                    } else {
                        const cut = Number(this.newListingForm.cutPrice) || 0;
                        let pct = Number(this.newListingForm.discountPercent) || 0;
                        let full = Number(this.newListingForm.fullDaigPrice) || 0;

                        if (source === 'cut' || source === 'percent') {
                            if (cut > 0 && pct >= 0) {
                                this.newListingForm.fullDaigPrice = Math.round(cut * (1 - pct / 100));
                                this.newListingForm.halfDaigPrice = Math.round(this.newListingForm.fullDaigPrice * 0.53);
                            }
                        } else if (source === 'actual') {
                            if (cut > 0 && full > 0 && full <= cut) {
                                this.newListingForm.discountPercent = Math.round(((cut - full) / cut) * 100);
                            }
                            if (!this.newListingForm.halfDaigPrice || this.newListingForm.halfDaigPrice >= full) {
                                this.newListingForm.halfDaigPrice = Math.round(full * 0.53);
                            }
                        }
                        if (this.newListingForm.discountPercent > 0) {
                            this.newListingForm.promoBadge = `FLAT ${this.newListingForm.discountPercent}% OFF`;
                        }
                    }
                },

                async handleListingImageUpload(event) {
                    const file = event.target.files && event.target.files[0];
                    if (!file) return;

                    const formData = new FormData();
                    formData.append('image', file);

                    this.uploadingListingImage = true;
                    try {
                        const res = await fetch('../api/upload', {
                            method: 'POST',
                            body: formData
                        });
                        const data = await res.json();
                        if (data.success && data.data && data.data.url) {
                            this.newListingForm.imageUrl = data.data.url;
                            this.showToast('✅ Image uploaded successfully to server storage!');
                        } else {
                            this.showToast(data.message || 'Image upload failed', 'error');
                        }
                    } catch(err) {
                        this.showToast('Upload error: ' + err.message, 'error');
                    } finally {
                        this.uploadingListingImage = false;
                        event.target.value = '';
                    }
                },

                async submitNewListing() {
                    if (!this.newListingForm.name || !this.newListingForm.name.trim()) {
                        this.showToast('Please enter dish / daig title', 'error');
                        return;
                    }

                    try {
                        this.loading = true;
                        if (this.addListingType === 'restaurant') {
                            const payload = {
                                restaurantId: this.subAdmin.id,
                                sub_admin_id: this.subAdmin.id,
                                name: this.newListingForm.name.trim(),
                                category: this.newListingForm.category,
                                description: this.newListingForm.description,
                                price: Number(this.newListingForm.actualPrice) || 0,
                                cutPrice: Number(this.newListingForm.cutPrice) || 0,
                                showCutPrice: Boolean(this.newListingForm.showCutPrice),
                                discountPrice: Number(this.newListingForm.actualPrice) || 0,
                                discountPercent: Number(this.newListingForm.discountPercent) || 0,
                                isDiscounted: Boolean(this.newListingForm.isDiscounted && this.newListingForm.discountPercent > 0),
                                promoBadge: this.newListingForm.promoBadge || '',
                                calories: Number(this.newListingForm.calories) || 500,
                                prepTime: this.newListingForm.prepTime || '20-25 mins',
                                imageUrl: this.newListingForm.imageUrl || 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&q=80',
                                badges: [this.newListingForm.foodTag || 'Non-Veg', this.newListingForm.promoBadge].filter(Boolean),
                                isVisible: 1
                            };

                            const res = await fetch('../api/food-items', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify(payload)
                            });
                            const data = await res.json();
                            if (data.success) {
                                this.showToast('🎉 Restaurant dish added successfully to Food Listing!');
                                await this.refreshAll();
                                this.foodListingSection = 'dishes';
                                this.foodListingMode = 'list';
                            } else {
                                this.showToast(data.message || 'Failed to save dish', 'error');
                            }
                        } else {
                            const payload = {
                                sub_admin_id: this.subAdmin.id,
                                name: this.newListingForm.name.trim(),
                                urduName: this.newListingForm.urduName || '',
                                category: this.newListingForm.pakwanCategory || 'Shahi Biryani & Pulao',
                                location: this.newListingForm.location || 'Main Pakwan Kitchen, Islamabad (G-9 Markaz)',
                                description: this.newListingForm.description || '',
                                fullDaigPrice: Number(this.newListingForm.fullDaigPrice) || 0,
                                halfDaigPrice: Number(this.newListingForm.halfDaigPrice) || 0,
                                cutPrice: Number(this.newListingForm.cutPrice) || 0,
                                showCutPrice: Boolean(this.newListingForm.showCutPrice),
                                discountPercent: Number(this.newListingForm.discountPercent) || 0,
                                discountPrice: Number(this.newListingForm.fullDaigPrice) || 0,
                                isDiscounted: Boolean(this.newListingForm.discountPercent > 0),
                                promoBadge: this.newListingForm.promoBadge || 'SPECIAL SHAHI DEG',
                                fullDaigWeight: this.newListingForm.fullDaigWeight || '12 KG (Serves 35-40 Persons)',
                                halfDaigWeight: this.newListingForm.halfDaigWeight || '6 KG (Serves 18-20 Persons)',
                                deliveryNotice: this.newListingForm.deliveryNotice || 'Order 3-4 hours in advance',
                                imageUrl: this.newListingForm.imageUrl || 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80',
                                isVisible: 1
                            };

                            const res = await fetch('../api/daig-items', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify(payload)
                            });
                            const data = await res.json();
                            if (data.success) {
                                this.showToast('👑 Shahi Pakwan Daig added successfully to Food Listing!');
                                await this.refreshAll();
                                this.foodListingSection = 'daigs';
                                this.foodListingMode = 'list';
                            } else {
                                this.showToast(data.message || 'Failed to save daig', 'error');
                            }
                        }
                    } catch(err) {
                        this.showToast('Listing error: ' + err.message, 'error');
                    } finally {
                        this.loading = false;
                        this.$nextTick(() => lucide.createIcons());
                    }
                },

                // Food Items CRUD with Promo Discount
                openCreateFoodModal() {
                    this.foodForm = { id: '', name: '', category: 'Biryani', price: 650, calories: 500, isDiscounted: false, discountPercent: 50, discountPrice: 325, promoBadge: '🔥 50% OFF', description: '', imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&q=80' };
                    this.modal.food = true;
                    this.$nextTick(() => lucide.createIcons());
                },

                openEditFoodModal(item) {
                    this.foodForm = {
                        ...item,
                        isDiscounted: Boolean(item.isDiscounted),
                        discountPercent: item.discountPercent || 50,
                        discountPrice: item.discountPrice || Math.round(item.price * 0.5),
                        promoBadge: item.promoBadge || '🔥 50% OFF'
                    };
                    this.modal.food = true;
                    this.$nextTick(() => lucide.createIcons());
                },

                recalcFoodDiscount() {
                    if (this.foodForm.isDiscounted) {
                        const pct = this.foodForm.discountPercent || 50;
                        this.foodForm.discountPrice = Math.round(this.foodForm.price * (1 - pct / 100));
                        this.foodForm.promoBadge = `🔥 ${pct}% OFF`;
                    }
                },

                async saveFoodItemForm() {
                    try {
                        this.recalcFoodDiscount();
                        const isEdit = Boolean(this.foodForm.id);
                        const url = isEdit ? `../api/food-items/${this.foodForm.id}` : `../api/food-items`;
                        const method = isEdit ? 'PUT' : 'POST';

                        const res = await fetch(url, {
                            method,
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                                ...this.foodForm,
                                restaurantId: this.subAdmin.id,
                                sub_admin_id: this.subAdmin.id,
                                locationAddress: this.subAdmin.address || 'Central Kitchen, Lahore',
                                restaurantName: this.subAdmin.businessName || this.subAdmin.name,
                                vendorName: this.subAdmin.name
                            })
                        });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast('✅ Restaurant dish & promo offer saved!');
                            this.modal.food = false;
                            await this.refreshAll();
                        } else {
                            this.showToast(data.message || 'Action failed', 'error');
                        }
                    } catch(e) {
                        this.showToast('Dish save error: ' + e.message, 'error');
                    }
                },

                async toggleFoodAvailability(item) {
                    try {
                        const newStatus = !item.isVisible;
                        await fetch(`../api/food-items/${item.id}`, {
                            method: 'PUT',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ ...item, isVisible: newStatus, isAvailable: newStatus, sub_admin_id: this.subAdmin.id, restaurantId: this.subAdmin.id })
                        });
                        item.isVisible = newStatus;
                        item.isAvailable = newStatus;
                        this.showToast(newStatus ? `🟢 "${item.name}" is now IN STOCK (Available)!` : `🔴 "${item.name}" marked as OUT OF STOCK!`);
                    } catch(e) {
                        this.showToast('Stock update error: ' + e.message, 'error');
                    }
                },

                async confirmDeleteFood(item) {
                    if (!confirm(`Are you sure you want to delete "${item.name}"?`)) return;
                    try {
                        await fetch(`../api/food-items/${item.id}`, { method: 'DELETE' });
                        this.showToast(`"${item.name}" deleted.`);
                        await this.refreshAll();
                    } catch(e) {}
                },

                // Daig Items CRUD
                openCreateDaigModal() {
                    this.daigForm = { id: '', name: '', urduName: '', category: this.allowedDaigCategories[0] || 'Biryani & Pulao', fullDaigPrice: 16000, halfDaigPrice: 8500, promoBadge: 'SPECIAL SHAHI DEG', deliveryNotice: 'Order 3-4 hours in advance', imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80' };
                    this.modal.daig = true;
                    this.$nextTick(() => lucide.createIcons());
                },

                openEditDaigModal(d) {
                    this.daigForm = { ...d };
                    this.modal.daig = true;
                    this.$nextTick(() => lucide.createIcons());
                },

                async saveDaigItemForm() {
                    try {
                        const isEdit = Boolean(this.daigForm.id);
                        const url = isEdit ? `../api/daig-items/${this.daigForm.id}` : `../api/daig-items`;
                        const method = isEdit ? 'PUT' : 'POST';

                        const res = await fetch(url, {
                            method,
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                                ...this.daigForm,
                                sub_admin_id: this.subAdmin.id,
                                centerId: this.subAdmin.id,
                                centerName: this.subAdmin.businessName || this.subAdmin.name,
                                location: this.subAdmin.address || 'Central Pakwan Kitchen, Lahore',
                                vendorName: this.subAdmin.name
                            })
                        });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast('✅ Shahi Daig catering dish saved!');
                            this.modal.daig = false;
                            await this.refreshAll();
                        }
                    } catch(e) {
                        this.showToast('Daig save error: ' + e.message, 'error');
                    }
                },

                async toggleDaigAvailability(d) {
                    try {
                        const newStatus = !d.isVisible;
                        await fetch(`../api/daig-items/${d.id}`, {
                            method: 'PUT',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ ...d, isVisible: newStatus, isAvailable: newStatus, sub_admin_id: this.subAdmin.id })
                        });
                        d.isVisible = newStatus;
                        d.isAvailable = newStatus;
                        this.showToast(newStatus ? `🟢 "${d.name}" is now IN STOCK (Available)!` : `🔴 "${d.name}" marked as OUT OF STOCK!`);
                    } catch(e) {
                        this.showToast('Stock update error: ' + e.message, 'error');
                    }
                },

                async confirmDeleteDaig(d) {
                    if (!confirm(`Are you sure you want to delete Shahi Daig "${d.name}"?`)) return;
                    try {
                        await fetch(`../api/daig-items/${d.id}`, { method: 'DELETE' });
                        this.showToast(`Daig "${d.name}" deleted.`);
                        await this.refreshAll();
                    } catch(e) {}
                },

                previewItem(item, type) {
                    alert(`${item.name} (${type})\nPrice: Rs. ${item.price || item.fullDaigPrice}\nCategory: ${item.category}\nStatus: ${item.isVisible ? 'Active in Customer App' : 'Offline'}`);
                },

                // Profile & Leaflet Map
                initLeafletMap() {
                    if (this.storeMap) return;
                    const lat = this.profileForm.latitude || 31.5204;
                    const lng = this.profileForm.longitude || 74.3587;

                    this.storeMap = L.map('store-map-picker').setView([lat, lng], 13);
                    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                        maxZoom: 19,
                        attribution: '&copy; OpenStreetMap'
                    }).addTo(this.storeMap);

                    this.storeMarker = L.marker([lat, lng], { draggable: true }).addTo(this.storeMap);
                    this.storeMarker.on('dragend', (e) => {
                        const pos = e.target.getLatLng();
                        this.profileForm.latitude = parseFloat(pos.lat.toFixed(4));
                        this.profileForm.longitude = parseFloat(pos.lng.toFixed(4));
                    });

                    this.storeMap.on('click', (e) => {
                        this.storeMarker.setLatLng(e.latlng);
                        this.profileForm.latitude = parseFloat(e.latlng.lat.toFixed(4));
                        this.profileForm.longitude = parseFloat(e.latlng.lng.toFixed(4));
                    });
                },

                detectCurrentGPS() {
                    if (!navigator.geolocation) {
                        alert('Geolocation not supported in browser.');
                        return;
                    }
                    this.detectingGps = true;
                    navigator.geolocation.getCurrentPosition(
                        (pos) => {
                            this.profileForm.latitude = parseFloat(pos.coords.latitude.toFixed(4));
                            this.profileForm.longitude = parseFloat(pos.coords.longitude.toFixed(4));
                            if (this.storeMap && this.storeMarker) {
                                this.storeMap.setView([this.profileForm.latitude, this.profileForm.longitude], 15);
                                this.storeMarker.setLatLng([this.profileForm.latitude, this.profileForm.longitude]);
                            }
                            this.detectingGps = false;
                            this.showToast('📍 Kitchen GPS coordinates detected!');
                        },
                        (err) => {
                            this.detectingGps = false;
                            this.showToast('GPS Error: ' + err.message, 'error');
                        },
                        { timeout: 10000, enableHighAccuracy: true }
                    );
                },

                async saveStoreProfile() {
                    try {
                        const res = await fetch(`../api/vendor/profile`, {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                                id: this.subAdmin.id,
                                ...this.profileForm
                            })
                        });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast('✅ Store profile & GPS coordinates saved!');
                            this.subAdmin = { ...this.subAdmin, ...this.profileForm };
                        } else {
                            this.showToast(data.message || 'Profile save failed', 'error');
                        }
                    } catch(e) {
                        this.showToast('Save error: ' + e.message, 'error');
                    }
                },

                async updatePassword() {
                    if (this.passwordForm.newPassword !== this.passwordForm.confirmPassword) {
                        this.showToast('Passwords match nahi karte!', 'error');
                        return;
                    }
                    try {
                        const res = await fetch(`../api/vendor/profile`, {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                                id: this.subAdmin.id,
                                newPassword: this.passwordForm.newPassword
                            })
                        });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast('✅ Password successfully updated!');
                            this.passwordForm = { newPassword: '', confirmPassword: '' };
                        }
                    } catch(e) {
                        this.showToast('Password update error: ' + e.message, 'error');
                    }
                }
            }
        }
    </script>
</body>
</html>
