<?php
// php-backend/vendor/index.php
// Vendor & Pakwan Center Manager Portal — Cupertino iOS Style (Minimal Gaps, High Density, Orange Theme)
session_start();

if (!isset($_SESSION['admin_user'])) {
    header('Location: /vendor/login.php');
    exit;
}

require_once __DIR__ . '/../config/database.php';
$pdo = getDb();

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
<body class="h-full flex overflow-hidden font-sans antialiased bg-[#09090b] text-zinc-100" x-data="vendorApp()" x-init="initApp()" x-cloak>

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

                <!-- Desktop Alert Test Audio Chime -->
                <button type="button" @click="playOrderChime(); showToast('🔔 Kitchen audio chime test fired!')"
                    class="p-1.5 bg-orange-500/10 hover:bg-orange-500/20 text-[#FF9500] rounded-xl border border-orange-500/30 transition-all text-xs font-bold"
                    title="Test Kitchen Audio Bell">
                    <i data-lucide="bell" class="w-3.5 h-3.5"></i>
                </button>
            </div>
        </header>

        <!-- Main Viewport Scrollable -->
        <main class="flex-1 overflow-y-auto p-3 sm:p-4 space-y-3.5">

            <!-- =============================================================== -->
            <!-- TAB 1: ANALYTICS (VENDOR OVERVIEW & FINANCIALS) -->
            <!-- =============================================================== -->
            <section x-show="activeTab === 'analytics'" class="space-y-3">
                
                <!-- 6 Top KPI Metrics Strip -->
                <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-2">
                    <div class="p-3 rounded-2xl cupertino-card flex flex-col justify-between">
                        <span class="text-[9.5px] uppercase font-bold text-zinc-400 tracking-wider">Gross Sales</span>
                        <h3 class="text-base font-black text-[#FF9500] mt-1 tabular-nums" x-text="'Rs. ' + (vendorStats.grossSales || 0).toLocaleString()"></h3>
                        <p class="text-[9.5px] text-zinc-400 mt-0.5">Lifetime Store Revenue</p>
                    </div>

                    <div class="p-3 rounded-2xl cupertino-card flex flex-col justify-between">
                        <span class="text-[9.5px] uppercase font-bold text-emerald-400 tracking-wider">Delivered</span>
                        <h3 class="text-base font-black text-emerald-400 mt-1 tabular-nums" x-text="vendorStats.completedOrders || 0"></h3>
                        <p class="text-[9.5px] text-emerald-400/80 mt-0.5">Completed Orders</p>
                    </div>

                    <div class="p-3 rounded-2xl cupertino-card flex flex-col justify-between">
                        <span class="text-[9.5px] uppercase font-bold text-amber-400 tracking-wider">Active In Hand</span>
                        <h3 class="text-base font-black text-amber-400 mt-1 tabular-nums" x-text="vendorStats.activeOrders || 0"></h3>
                        <p class="text-[9.5px] text-amber-400/80 mt-0.5">Kitchen & On the Way</p>
                    </div>

                    <div class="p-3 rounded-2xl cupertino-card flex flex-col justify-between">
                        <span class="text-[9.5px] uppercase font-bold text-red-400 tracking-wider">Cancelled / Loss</span>
                        <h3 class="text-base font-black text-red-400 mt-1 tabular-nums" x-text="(vendorStats.cancelledOrders || 0) + ' (' + (vendorStats.lossAmount || 0).toLocaleString() + ')'"></h3>
                        <p class="text-[9.5px] text-red-400/80 mt-0.5">Rejected / Cancelled</p>
                    </div>

                    <div class="p-3 rounded-2xl cupertino-card flex flex-col justify-between">
                        <span class="text-[9.5px] uppercase font-bold text-purple-400 tracking-wider">Store Customers</span>
                        <h3 class="text-base font-black text-purple-300 mt-1 tabular-nums" x-text="vendorStats.totalCustomers || vendorCustomers.length"></h3>
                        <p class="text-[9.5px] text-zinc-400 mt-0.5">Unique Foodies Served</p>
                    </div>

                    <div class="p-3 rounded-2xl cupertino-card flex flex-col justify-between">
                        <span class="text-[9.5px] uppercase font-bold text-sky-400 tracking-wider">Dedicated Fleet</span>
                        <h3 class="text-base font-black text-sky-300 mt-1 tabular-nums" x-text="outletRiders.length"></h3>
                        <p class="text-[9.5px] text-sky-400/80 mt-0.5">Store Delivery Riders</p>
                    </div>
                </div>

                <!-- Revenue Split & Order Pipeline (2 Columns) -->
                <div class="grid grid-cols-1 lg:grid-cols-12 gap-3">
                    
                    <!-- Left: Revenue Split (Pakwan Daigs vs Regular Food) -->
                    <div class="lg:col-span-5 p-4 rounded-2xl cupertino-card flex flex-col justify-between space-y-3">
                        <div class="flex items-center justify-between pb-2 border-b border-white/5">
                            <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                <i data-lucide="pie-chart" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                <span>Revenue Split (Daig vs Restaurant)</span>
                            </h4>
                            <span class="text-[10px] text-zinc-400 font-mono">100% Total</span>
                        </div>

                        <!-- Pakwan Daigs Share -->
                        <div class="p-3 rounded-xl bg-orange-500/10 border border-orange-500/20">
                            <div class="flex items-center justify-between text-xs mb-1">
                                <span class="font-bold text-amber-300 flex items-center gap-1">
                                    <span>👑 Shahi Pakwan Daigs</span>
                                </span>
                                <span class="font-black text-white tabular-nums" x-text="'Rs. ' + (vendorStats.daigSales || 0).toLocaleString()"></span>
                            </div>
                            <div class="w-full bg-zinc-800 rounded-full h-2 overflow-hidden mt-1.5">
                                <div class="bg-gradient-to-r from-amber-400 to-orange-500 h-2 rounded-full transition-all"
                                    :style="'width: ' + calcShare(vendorStats.daigSales, vendorStats.grossSales) + '%'"></div>
                            </div>
                            <div class="flex justify-between items-center text-[9.5px] text-zinc-400 mt-1 font-mono">
                                <span x-text="(vendorStats.daigOrders || 0) + ' Daig Bookings'"></span>
                                <span x-text="calcShare(vendorStats.daigSales, vendorStats.grossSales) + '% Share'"></span>
                            </div>
                        </div>

                        <!-- Regular Food Dishes Share -->
                        <div class="p-3 rounded-xl bg-amber-500/10 border border-amber-500/20">
                            <div class="flex items-center justify-between text-xs mb-1">
                                <span class="font-bold text-[#FF9500] flex items-center gap-1">
                                    <span>🍽️ Restaurant Menu Dishes</span>
                                </span>
                                <span class="font-black text-white tabular-nums" x-text="'Rs. ' + (vendorStats.foodSales || 0).toLocaleString()"></span>
                            </div>
                            <div class="w-full bg-zinc-800 rounded-full h-2 overflow-hidden mt-1.5">
                                <div class="bg-gradient-to-r from-[#FF9500] to-yellow-500 h-2 rounded-full transition-all"
                                    :style="'width: ' + calcShare(vendorStats.foodSales, vendorStats.grossSales) + '%'"></div>
                            </div>
                            <div class="flex justify-between items-center text-[9.5px] text-zinc-400 mt-1 font-mono">
                                <span x-text="(vendorStats.foodOrders || 0) + ' Food Orders'"></span>
                                <span x-text="calcShare(vendorStats.foodSales, vendorStats.grossSales) + '% Share'"></span>
                            </div>
                        </div>
                    </div>

                    <!-- Right: Order Lifecycle Funnel Pipeline -->
                    <div class="lg:col-span-7 p-4 rounded-2xl cupertino-card flex flex-col justify-between space-y-3">
                        <div class="flex items-center justify-between pb-2 border-b border-white/5">
                            <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                <i data-lucide="git-commit" class="w-3.5 h-3.5 text-sky-400"></i>
                                <span>Live Kitchen & Dispatch Funnel</span>
                            </h4>
                            <span class="text-[10px] text-emerald-400 font-bold">Real-time Pipeline</span>
                        </div>

                        <div class="grid grid-cols-2 sm:grid-cols-5 gap-2 text-center">
                            <div class="p-2.5 rounded-xl bg-sky-500/10 border border-sky-500/20">
                                <p class="text-[9px] uppercase font-bold text-sky-400">1. Accepted</p>
                                <p class="text-base font-black text-white mt-0.5 tabular-nums" x-text="getStatusCount('Accepted')"></p>
                                <p class="text-[8.5px] text-zinc-400 mt-0.5">In Queue</p>
                            </div>

                            <div class="p-2.5 rounded-xl bg-amber-500/10 border border-amber-500/20">
                                <p class="text-[9px] uppercase font-bold text-amber-400">2. Preparing</p>
                                <p class="text-base font-black text-white mt-0.5 tabular-nums" x-text="getStatusCount('Preparing')"></p>
                                <p class="text-[8.5px] text-zinc-400 mt-0.5">Cooking</p>
                            </div>

                            <div class="p-2.5 rounded-xl bg-orange-500/10 border border-orange-500/20">
                                <p class="text-[9px] uppercase font-bold text-[#FF9500]">3. On the Way</p>
                                <p class="text-base font-black text-white mt-0.5 tabular-nums" x-text="getStatusCount('On the Way')"></p>
                                <p class="text-[8.5px] text-zinc-400 mt-0.5">With Rider</p>
                            </div>

                            <div class="p-2.5 rounded-xl bg-purple-500/10 border border-purple-500/20">
                                <p class="text-[9px] uppercase font-bold text-purple-300">4. Arrived</p>
                                <p class="text-base font-black text-white mt-0.5 tabular-nums" x-text="getStatusCount('Arrived')"></p>
                                <p class="text-[8.5px] text-zinc-400 mt-0.5">At Doorstep</p>
                            </div>

                            <div class="p-2.5 rounded-xl bg-emerald-500/10 border border-emerald-500/20 col-span-2 sm:col-span-1">
                                <p class="text-[9px] uppercase font-bold text-emerald-400">5. Delivered</p>
                                <p class="text-base font-black text-white mt-0.5 tabular-nums" x-text="getStatusCount('Delivered')"></p>
                                <p class="text-[8.5px] text-emerald-400/80 mt-0.5">Completed</p>
                            </div>
                        </div>

                        <!-- Top 5 Bestsellers Mini Strip -->
                        <div class="pt-2 border-t border-white/5">
                            <p class="text-[10px] font-bold uppercase tracking-wider text-zinc-400 mb-1.5">Top Selling Dishes & Daigs</p>
                            <div class="grid grid-cols-1 sm:grid-cols-3 gap-2">
                                <template x-for="(item, idx) in topBestsellers.slice(0, 3)" :key="idx">
                                    <div class="p-2 rounded-xl bg-zinc-900 border border-white/5 flex items-center justify-between text-xs">
                                        <div class="min-w-0 pr-2">
                                            <p class="font-bold text-white truncate" x-text="item.name"></p>
                                            <p class="text-[9.5px] text-zinc-400" x-text="item.category"></p>
                                        </div>
                                        <span class="px-1.5 py-0.5 rounded text-[10px] font-black bg-orange-500/20 text-[#FF9500] whitespace-nowrap"
                                            x-text="'Rs. ' + item.price">
                                        </span>
                                    </div>
                                </template>
                            </div>
                        </div>

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
                                            <button type="button" @click="openCustomerSheet(cust)"
                                                class="px-2.5 py-1 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 rounded-lg text-[11px] font-semibold flex items-center gap-1 transition-all ml-auto">
                                                <i data-lucide="history" class="w-3 h-3 text-[#FF9500]"></i>
                                                <span>History</span>
                                            </button>
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
                                            <div class="text-[10px] text-[#FF9500] font-mono" x-text="ord.customerPhone"></div>
                                            <div class="text-[10px] text-zinc-400 truncate max-w-[140px]" x-text="ord.deliveryAddress"></div>
                                        </td>

                                        <td class="py-2.5 px-3">
                                            <div class="text-[11px] text-zinc-200 line-clamp-2 max-w-[180px]" x-text="formatOrderItemsSummary(ord.items)"></div>
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
            <!-- TAB 5: FOOD LISTING (DISHES, SHAHI DAIGS & PROMOS - COMPLETE CRUD) -->
            <!-- =============================================================== -->
            <section x-show="activeTab === 'food-listing'" class="space-y-3">
                
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

                        <button type="button" x-show="foodListingSection === 'dishes'" @click="openCreateFoodModal()"
                            class="px-3 py-1.5 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-black font-bold rounded-xl text-xs flex items-center gap-1 shadow-sm transition-all active:scale-95">
                            <i data-lucide="plus" class="w-3.5 h-3.5 text-black"></i>
                            <span>Upload Dish</span>
                        </button>

                        <button type="button" x-show="foodListingSection === 'daigs'" @click="openCreateDaigModal()"
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

                                        <td class="py-2.5 px-3">
                                            <button type="button" @click="toggleFoodAvailability(item)"
                                                class="px-2 py-0.5 rounded-full text-[9px] font-bold uppercase tracking-wider"
                                                :class="item.isVisible ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30' : 'bg-red-500/15 text-red-400 border border-red-500/30'"
                                                x-text="item.isVisible ? 'IN STOCK' : 'OUT OF STOCK'">
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

                                        <td class="py-2.5 px-3">
                                            <button type="button" @click="toggleDaigAvailability(d)"
                                                class="px-2 py-0.5 rounded-full text-[9px] font-bold uppercase tracking-wider"
                                                :class="d.isVisible ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30' : 'bg-red-500/15 text-red-400 border border-red-500/30'"
                                                x-text="d.isVisible ? 'AVAILABLE' : 'OFFLINE'">
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

                    <div class="relative" x-data="{ openCategory: false, categories: ['Biryani', 'Karahi & Handi', 'BBQ & Grill', 'Burgers', 'Desi Gravy', 'Desserts', 'Beverages'] }">
                        <label class="block text-[11px] font-semibold text-zinc-400 mb-0.5">Category</label>
                        <button type="button" @click="openCategory = !openCategory; $nextTick(() => lucide.createIcons())"
                            class="w-full px-2.5 py-1.5 bg-zinc-900 border border-white/10 hover:border-orange-500/40 rounded-xl text-xs text-white flex items-center justify-between transition-colors focus:outline-none focus:border-[#FF9500]">
                            <span x-text="foodForm.category || 'Select Category'"></span>
                            <i data-lucide="chevron-down" class="w-3.5 h-3.5 text-[#FF9500] transition-transform" :class="openCategory ? 'rotate-180' : ''"></i>
                        </button>
                        <div x-show="openCategory" @click.outside="openCategory = false" x-cloak
                            class="absolute left-0 mt-1 w-full max-h-48 overflow-y-auto cupertino-glass rounded-xl p-1 shadow-2xl border border-white/10 z-50 space-y-0.5 text-xs">
                            <template x-for="cat in categories" :key="cat">
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
                    <p class="text-zinc-400" x-text="activeOrder?.deliveryAddress"></p>
                    <template x-if="activeOrder?.latitude">
                        <a :href="'https://www.google.com/maps/search/?api=1&query=' + activeOrder.latitude + ',' + activeOrder.longitude" target="_blank"
                            class="text-[#FF9500] hover:underline font-bold inline-flex items-center gap-1 mt-0.5">
                            <i data-lucide="navigation" class="w-3 h-3"></i>
                            <span>View Customer GPS Location on Map</span>
                        </a>
                    </template>
                </div>

                <div class="space-y-1 pt-2 border-t border-white/5">
                    <p class="font-bold text-white">Items Summary:</p>
                    <p class="text-zinc-300" x-text="formatOrderItemsSummary(activeOrder?.items)"></p>
                </div>
            </div>

            <div class="pt-3 mt-3 border-t border-white/5 flex justify-end">
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

                // Top 6 Strict Tabs
                tabs: [
                    { id: 'analytics', label: 'Analytics', icon: 'pie-chart' },
                    { id: 'riders', label: 'Riders Fleet', icon: 'bike' },
                    { id: 'customers', label: 'Customers', icon: 'users' },
                    { id: 'orders', label: 'Orders Hub', icon: 'shopping-bag' },
                    { id: 'food-listing', label: 'Food Listing', icon: 'utensils' },
                    { id: 'profile', label: 'Profile & Settings', icon: 'store' }
                ],

                // Data Arrays
                vendorStats: {},
                orders: [],
                riders: [],
                vendorCustomers: [],
                foodItems: [],
                daigItems: [],

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
                modal: { rider: false, food: false, daig: false, orderDetail: false, reject: false, assignRider: false },
                activeCustomer: null,
                activeRider: null,
                activeOrder: null,
                rejectTarget: null,
                rejectReason: '',
                assignTarget: null,

                // Forms
                riderForm: { name: '', phone: '', email: '', password: '123456', city: 'Lahore' },
                editingRider: {},
                foodForm: { id: '', name: '', category: 'Biryani', price: 0, calories: 500, isDiscounted: false, discountPercent: 50, discountPrice: 0, promoBadge: '🔥 50% OFF', description: '', imageUrl: '' },
                daigForm: { id: '', name: '', urduName: '', fullDaigPrice: 15000, halfDaigPrice: 8000, promoBadge: '', deliveryNotice: '3-4 hours notice', imageUrl: '' },
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

                async initApp() {
                    await this.refreshAll();
                    // Auto poll for orders every 20 seconds
                    setInterval(() => this.fetchOrdersSilent(), 20000);
                    this.$nextTick(() => lucide.createIcons());
                },

                get activeOrdersCount() {
                    return this.orders.filter(o => ['Accepted', 'Preparing', 'On the Way', 'Arrived'].includes(o.status)).length;
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
                        osc.type = 'triangle';
                        osc.frequency.setValueAtTime(587.33, audioCtx.currentTime);
                        osc.frequency.setValueAtTime(880, audioCtx.currentTime + 0.12);
                        osc.frequency.setValueAtTime(1174.66, audioCtx.currentTime + 0.24);
                        gain.gain.setValueAtTime(0.2, audioCtx.currentTime);
                        gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.6);
                        osc.start();
                        osc.stop(audioCtx.currentTime + 0.6);
                    } catch(e) {}
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
                        const [statsRes, custRes, ordRes, ridRes, foodRes, daigRes] = await Promise.all([
                            fetch(`../api/vendor/stats?sub_admin_id=${sid}`).then(r => r.json()).catch(() => ({ data: {} })),
                            fetch(`../api/vendor/customers?sub_admin_id=${sid}`).then(r => r.json()).catch(() => ({ data: [] })),
                            fetch(`../api/orders?sub_admin_id=${sid}`).then(r => r.json()).catch(() => ({ data: [] })),
                            fetch(`../api/users?role=rider`).then(r => r.json()).catch(() => ({ data: [] })),
                            fetch(`../api/food-items`).then(r => r.json()).catch(() => ({ data: [] })),
                            fetch(`../api/daig-items`).then(r => r.json()).catch(() => ({ data: [] }))
                        ]);

                        if (statsRes?.data) this.vendorStats = statsRes.data;
                        if (custRes?.data) this.vendorCustomers = custRes.data;
                        if (ordRes?.data) this.orders = ordRes.data;
                        if (ridRes?.data) this.riders = ridRes.data;
                        if (foodRes?.data) this.foodItems = foodRes.data;
                        if (daigRes?.data) this.daigItems = daigRes.data;
                    } catch (e) {
                        this.showToast('Sync error: ' + e.message, 'error');
                    } finally {
                        this.loading = false;
                        this.$nextTick(() => lucide.createIcons());
                    }
                },

                async fetchOrdersSilent() {
                    try {
                        const res = await fetch(`../api/orders?sub_admin_id=${this.subAdmin.id}`);
                        const data = await res.json();
                        if (data?.data) {
                            if (data.data.length > this.orders.length) {
                                this.playOrderChime();
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
                                sub_admin_id: this.subAdmin.id
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
                        await fetch(`../api/food-items/${item.id}`, {
                            method: 'PUT',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ ...item, isVisible: !item.isVisible, sub_admin_id: this.subAdmin.id, restaurantId: this.subAdmin.id })
                        });
                        item.isVisible = !item.isVisible;
                        this.showToast('Dish stock availability updated.');
                    } catch(e) {}
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
                    this.daigForm = { id: '', name: '', urduName: '', fullDaigPrice: 16000, halfDaigPrice: 8500, promoBadge: 'SPECIAL SHAHI DEG', deliveryNotice: 'Order 3-4 hours in advance', imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80' };
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
                                sub_admin_id: this.subAdmin.id
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
                        await fetch(`../api/daig-items/${d.id}`, {
                            method: 'PUT',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ ...d, isVisible: !d.isVisible, sub_admin_id: this.subAdmin.id })
                        });
                        d.isVisible = !d.isVisible;
                        this.showToast('Daig availability updated.');
                    } catch(e) {}
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
