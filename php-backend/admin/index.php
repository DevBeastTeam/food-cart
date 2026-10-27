<?php
// php-backend/admin/index.php (Super Admin Control Center)
session_start();

if (!isset($_SESSION['super_admin'])) {
    header('Location: /admin/login.php');
    exit;
}

require_once __DIR__ . '/../config/database.php';
$pdo = getDb();

$superUser = $_SESSION['super_admin'];
$stmt = $pdo->prepare("SELECT * FROM users WHERE role = 'super_admin' OR id = ? OR email = ? LIMIT 1");
$stmt->execute([$superUser['id'] ?? '', $superUser['email'] ?? 'super@foodcourt.pk']);
$liveSuper = $stmt->fetch();
if ($liveSuper) {
    $_SESSION['super_admin'] = array_merge($_SESSION['super_admin'], $liveSuper);
    $superUser = $_SESSION['super_admin'];
}
?>
<!DOCTYPE html>
<html lang="en" class="h-full bg-[#09090b] text-zinc-100 dark" style="color-scheme: dark;">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="theme-color" content="#09090b">
    <title>Food Court — Super Admin Control Center</title>
    
    <!-- Tailwind CSS CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        ios: {
                            orange: '#FF9500',
                            orangeHover: '#EA580C',
                            bg: '#09090b',
                            card: '#18181b',
                            border: 'rgba(255, 255, 255, 0.08)'
                        }
                    }
                }
            }
        }
    </script>
    
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
            background: rgba(24, 24, 27, 0.78);
            backdrop-filter: blur(24px) saturate(190%);
            -webkit-backdrop-filter: blur(24px) saturate(190%);
            border: 1px solid rgba(255, 255, 255, 0.08);
        }
        .cupertino-card {
            background: rgba(24, 24, 27, 0.65);
            border: 1px solid rgba(255, 255, 255, 0.07);
        }
        ::-webkit-scrollbar { width: 5px; height: 5px; }
        ::-webkit-scrollbar-track { background: #09090b; }
        ::-webkit-scrollbar-thumb { background: #27272a; border-radius: 9999px; }
        ::-webkit-scrollbar-thumb:hover { background: #3f3f46; }
    </style>
</head>
<body class="h-full flex overflow-hidden font-sans antialiased bg-[#09090b] text-zinc-100" x-data="superAdminApp()" x-init="initApp()" x-cloak>

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
        <!-- Brand Header -->
        <div class="h-14 flex items-center gap-3 px-4 border-b border-white/5 shrink-0">
            <div class="w-8 h-8 rounded-xl bg-orange-500/15 border border-orange-500/30 text-[#FF9500] flex items-center justify-center font-bold shadow-sm">
                <i data-lucide="crown" class="w-4 h-4" aria-hidden="true"></i>
            </div>
            <div class="min-w-0">
                <h1 class="text-xs font-bold text-white tracking-tight truncate">Food Court</h1>
                <p class="text-[9.5px] font-bold text-[#FF9500] uppercase tracking-wider">Super Control</p>
            </div>
        </div>

        <!-- Navigation Links (5px Rounded, 2px Less Top/Bottom, 30% Opacity Background) -->
        <nav class="flex-1 px-2 py-2 space-y-1 overflow-y-auto" aria-label="Main Navigation">
            <template x-for="t in tabs" :key="t.id">
                <button type="button" @click="setTab(t.id)"
                    class="w-full flex items-center gap-3 px-3.5 py-2.5 min-h-[40px] text-[12.5px] font-semibold transition-all text-left rounded-[5px] select-none group border"
                    :class="activeTab === t.id 
                        ? 'bg-orange-500/30 text-white font-bold border-orange-500/40 shadow-sm' 
                        : 'text-zinc-400 hover:text-white hover:bg-white/[0.05] border-transparent'">
                    <i :data-lucide="t.icon" class="w-4 h-4 shrink-0 transition-colors"
                        :class="activeTab === t.id ? 'text-[#FF9500] stroke-[2.2]' : 'text-zinc-400 group-hover:text-zinc-200'" aria-hidden="true"></i>
                    <span x-text="t.label" class="flex-1 truncate tracking-tight"></span>
                    <i data-lucide="chevron-right" class="w-3.5 h-3.5 shrink-0 transition-transform"
                        :class="activeTab === t.id ? 'text-[#FF9500] opacity-90 translate-x-0.5' : 'text-zinc-600 opacity-30 group-hover:opacity-70'" aria-hidden="true"></i>
                </button>
            </template>
        </nav>

        <!-- Super Admin Profile Tile (5px Rounded, 2px Less Top/Bottom, 30% Opacity Background) -->
        <div class="p-2 border-t border-white/5 shrink-0">
            <div @click="setTab('profile')"
                class="w-full px-3 py-2 min-h-[44px] bg-zinc-900/60 hover:bg-zinc-800/80 cursor-pointer flex items-center justify-between transition-all rounded-[5px] border select-none"
                :class="activeTab === 'profile' ? 'bg-orange-500/30 border-orange-500/40 text-white' : 'border-transparent'"
                title="View & Edit Super Admin Profile">
                <div class="flex items-center gap-2.5 min-w-0">
                    <div class="w-7 h-7 rounded-[5px] bg-orange-500/15 border border-orange-500/30 text-[#FF9500] flex items-center justify-center font-bold text-xs shrink-0 shadow-sm">
                        👑
                    </div>
                    <div class="min-w-0">
                        <p class="text-[11.5px] font-bold text-white truncate" x-text="adminProfileForm.name || '<?= htmlspecialchars($superUser['name']) ?>'"></p>
                        <p class="text-[10px] text-zinc-400 font-mono truncate" x-text="adminProfileForm.email || '<?= htmlspecialchars($superUser['email']) ?>'"></p>
                    </div>
                </div>
                <a href="logout.php" @click.stop class="p-1.5 text-zinc-400 hover:text-red-400 rounded-[5px] transition-colors" title="Logout" aria-label="Sign Out">
                    <i data-lucide="log-out" class="w-4 h-4" aria-hidden="true"></i>
                </a>
            </div>
        </div>
    </aside>

    <!-- ======================================================================= -->
    <!-- MAIN WORKSPACE -->
    <!-- ======================================================================= -->
    <div class="flex-1 flex flex-col min-w-0 overflow-hidden">
        
        <!-- Compact Cupertino Top Bar -->
        <header class="h-12 bg-zinc-950/70 backdrop-blur-xl border-b border-white/5 px-4 flex items-center justify-between shrink-0">
            <div class="flex items-center gap-2 min-w-0">
                <h2 class="text-xs sm:text-sm font-bold text-white flex items-center gap-1.5 truncate">
                    <span x-text="currentTabLabel()"></span>
                    <span class="px-1.5 py-0.5 rounded-full text-[9px] font-bold uppercase bg-orange-500/15 text-[#FF9500] border border-orange-500/25">Super</span>
                </h2>
            </div>

            <div class="flex items-center gap-1.5">
                <!-- Desktop Browser Notifications Toggle -->
                <button type="button" x-show="desktopNotificationPermission === 'granted'" @click="sendDesktopNotification('Platform Alert Test', 'Desktop notifications are active across all Pakwan Centers!'); playOrderChime(); showToast('Desktop alert test fired! 🔔')" class="px-2.5 py-1 bg-orange-500/15 hover:bg-orange-500/25 text-orange-300 rounded-xl border border-orange-500/30 transition-all text-[11px] font-semibold flex items-center gap-1 active:scale-95" title="Desktop Alerts Active (Click to Test)">
                    <i data-lucide="bell" class="w-3 h-3 text-[#FF9500]" aria-hidden="true"></i>
                    <span>Alerts: On 🔔</span>
                </button>
                <button type="button" x-show="desktopNotificationPermission !== 'granted'" @click="requestDesktopNotificationPermission()" class="px-2.5 py-1 bg-orange-500/20 hover:bg-orange-500/30 text-orange-300 rounded-xl border border-orange-500/40 transition-all text-[11px] font-semibold flex items-center gap-1 animate-pulse" title="Click to allow instant Desktop Notifications for new incoming orders">
                    <i data-lucide="bell-ring" class="w-3 h-3 text-[#FF9500]" aria-hidden="true"></i>
                    <span>Enable Alerts</span>
                </button>

                <button type="button" @click="playOrderChime(); showToast('Platform Sound Alert Active! 🔔')" class="px-2 py-1 bg-zinc-900 hover:bg-zinc-800 text-zinc-300 rounded-xl border border-white/5 transition-all text-[11px] font-medium flex items-center gap-1" title="Test Order Chime" aria-label="Test Sound Chime">
                    <i data-lucide="volume-2" class="w-3 h-3 text-[#FF9500]" aria-hidden="true"></i>
                    <span>Chime</span>
                </button>
                <button type="button" @click="refreshAll()" class="p-1.5 bg-zinc-900 hover:bg-zinc-800 text-zinc-300 rounded-xl border border-white/5 transition-all text-[11px] font-medium flex items-center gap-1" title="Refresh Live Data" aria-label="Sync Live Data">
                    <i data-lucide="refresh-cw" class="w-3 h-3" :class="loading ? 'animate-spin' : ''" aria-hidden="true"></i>
                </button>
                <button type="button" @click="seedDatabaseDemo()" class="px-2.5 py-1 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-black font-bold rounded-xl text-[11px] flex items-center gap-1 shadow-sm transition-all" title="Seed / Reset Demo Data (Customers, Pakwan Centers, Store Riders, Orders across all stages)">
                    <i data-lucide="sparkles" class="w-3 h-3 text-black" aria-hidden="true"></i>
                    <span>🌱 Seed Data</span>
                </button>
                <div class="h-4 w-px bg-zinc-800 mx-0.5" aria-hidden="true"></div>
                <a href="../vendor/login.php" target="_blank" class="px-2.5 py-1 bg-zinc-900/90 hover:bg-zinc-800 text-zinc-300 rounded-xl text-[11px] font-medium border border-white/5 flex items-center gap-1 transition-colors" title="Open Vendor & Pakwan Center Portal">
                    <i data-lucide="store" class="w-3 h-3 text-[#FF9500]" aria-hidden="true"></i>
                    <span>Vendor Portal (/vendor)</span>
                </a>
            </div>
        </header>

        <!-- Main Viewport Scrollable (Ultra-Compact Inset Layout) -->
        <main class="flex-1 overflow-y-auto p-3 sm:p-4">

            <!-- =============================================================== -->
            <!-- TAB 1: PLATFORM ANALYTICS DASHBOARD (PRIMARY TAB) -->
            <!-- =============================================================== -->
            <div x-show="activeTab === 'analytics'" class="space-y-3.5">
                
                <!-- Header Toolbar with Live Refresh -->
                <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
                    <div>
                        <h3 class="text-sm font-bold text-white flex items-center gap-2">
                            <i data-lucide="line-chart" class="w-4 h-4 text-[#FF9500]"></i>
                            <span>Platform Executive Analytics</span>
                        </h3>
                        <p class="text-[11px] text-zinc-400">Live platform performance, Pakwan vs Restaurant order split, rider fleet & customer insights</p>
                    </div>
                    <div class="flex items-center gap-2">
                        <span class="text-[10.5px] text-zinc-500 tabular-nums" x-text="'Last updated: ' + (new Date()).toLocaleTimeString()"></span>
                        <button type="button" @click="refreshAll()" class="px-2.5 py-1 bg-zinc-900 hover:bg-zinc-800 border border-white/10 rounded-xl text-xs text-zinc-300 flex items-center gap-1.5 transition-all">
                            <i data-lucide="refresh-cw" class="w-3 h-3" :class="loading ? 'animate-spin' : ''"></i>
                            <span>Sync Metrics</span>
                        </button>
                    </div>
                </div>

                <!-- Primary KPI Metrics Strip -->
                <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-2">
                    <!-- Total Revenue -->
                    <div class="p-3 rounded-2xl cupertino-card flex flex-col justify-between">
                        <div class="flex items-center justify-between text-zinc-400">
                            <span class="text-[9.5px] font-bold uppercase tracking-wider">Gross Platform Sales</span>
                            <i data-lucide="coins" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                        </div>
                        <h4 class="text-lg font-black text-[#FF9500] mt-1 tabular-nums" x-text="'Rs. ' + Number(stats?.metrics?.totalRevenue || 0).toLocaleString()"></h4>
                        <p class="text-[10px] text-emerald-400 mt-0.5">Across all Pakwan Centers</p>
                    </div>

                    <!-- Total Orders -->
                    <div class="p-3 rounded-2xl cupertino-card flex flex-col justify-between">
                        <div class="flex items-center justify-between text-zinc-400">
                            <span class="text-[9.5px] font-bold uppercase tracking-wider">Total Orders</span>
                            <i data-lucide="shopping-bag" class="w-3.5 h-3.5 text-blue-400"></i>
                        </div>
                        <h4 class="text-lg font-black text-white mt-1 tabular-nums" x-text="stats?.metrics?.totalOrders || 0"></h4>
                        <p class="text-[10px] text-zinc-400 mt-0.5" x-text="(stats?.metrics?.activeOrders || 0) + ' In kitchen / on way'"></p>
                    </div>

                    <!-- Successfully Delivered Orders -->
                    <div class="p-3 rounded-2xl cupertino-card flex flex-col justify-between border-emerald-500/20 bg-emerald-950/10">
                        <div class="flex items-center justify-between text-emerald-300">
                            <span class="text-[9.5px] font-bold uppercase tracking-wider">Delivered Orders</span>
                            <i data-lucide="check-circle" class="w-3.5 h-3.5 text-emerald-400"></i>
                        </div>
                        <h4 class="text-lg font-black text-emerald-400 mt-1 tabular-nums" x-text="stats?.metrics?.deliveredOrders || 0"></h4>
                        <p class="text-[10px] text-emerald-300/80 mt-0.5">100% Fulfilled & Paid</p>
                    </div>

                    <!-- Total Customers -->
                    <div class="p-3 rounded-2xl cupertino-card flex flex-col justify-between">
                        <div class="flex items-center justify-between text-zinc-400">
                            <span class="text-[9.5px] font-bold uppercase tracking-wider">Total Customers</span>
                            <i data-lucide="users" class="w-3.5 h-3.5 text-purple-400"></i>
                        </div>
                        <h4 class="text-lg font-black text-purple-300 mt-1 tabular-nums" x-text="stats?.metrics?.totalCustomers || 0"></h4>
                        <p class="text-[10px] text-zinc-400 mt-0.5">Mobile app clients</p>
                    </div>

                    <!-- Total Riders -->
                    <div class="p-3 rounded-2xl cupertino-card flex flex-col justify-between">
                        <div class="flex items-center justify-between text-zinc-400">
                            <span class="text-[9.5px] font-bold uppercase tracking-wider">Delivery Riders</span>
                            <i data-lucide="bike" class="w-3.5 h-3.5 text-sky-400"></i>
                        </div>
                        <h4 class="text-lg font-black text-sky-400 mt-1 tabular-nums" x-text="stats?.metrics?.totalRiders || 0"></h4>
                        <p class="text-[10px] text-zinc-400 mt-0.5">Active field fleet</p>
                    </div>

                    <!-- Pakwan Centers Overview -->
                    <div class="p-3 rounded-2xl cupertino-card flex flex-col justify-between">
                        <div class="flex items-center justify-between text-zinc-400">
                            <span class="text-[9.5px] font-bold uppercase tracking-wider">Pakwan Centers</span>
                            <i data-lucide="store" class="w-3.5 h-3.5 text-amber-400"></i>
                        </div>
                        <h4 class="text-lg font-black text-amber-400 mt-1 tabular-nums" x-text="stats?.metrics?.totalSubAdmins || 0"></h4>
                        <p class="text-[10px] text-zinc-400 mt-0.5" x-text="(stats?.metrics?.totalPakwanCenters || 0) + ' Pakwan Centers • ' + (stats?.metrics?.totalRestaurantOutlets || 0) + ' Restaurants'"></p>
                    </div>
                </div>

                <!-- Pakwan Orders vs Restaurant Orders Split -->
                <div class="cupertino-card rounded-2xl p-3.5 space-y-3 border border-orange-500/20 bg-gradient-to-br from-zinc-950/80 via-zinc-900/60 to-orange-950/20">
                    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-1.5 pb-2 border-b border-white/5">
                        <div class="flex items-center gap-2">
                            <div class="w-7 h-7 rounded-xl bg-orange-500/20 text-[#FF9500] flex items-center justify-center font-bold text-xs">
                                ⚖️
                            </div>
                            <div>
                                <h4 class="text-xs font-bold text-white">Pakwan Daigs vs. Restaurant Food Orders Breakdown</h4>
                                <p class="text-[10.5px] text-zinc-400">Real-time split of Daig ceremonial bookings versus standard restaurant orders</p>
                            </div>
                        </div>
                        <span class="px-2.5 py-0.5 rounded-full text-[10px] font-semibold bg-orange-500/15 text-[#FF9500] border border-orange-500/30">
                            Pakwan vs Fast Food Comparison
                        </span>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                        <!-- Pakwan Daigs -->
                        <div class="p-3.5 rounded-2xl bg-zinc-950/70 border border-orange-500/30 relative overflow-hidden flex flex-col justify-between">
                            <div class="absolute -right-6 -bottom-6 opacity-10 text-7xl select-none pointer-events-none">👑</div>
                            <div>
                                <div class="flex items-center justify-between">
                                    <div class="flex items-center gap-2">
                                        <span class="w-8 h-8 rounded-xl bg-orange-500/20 text-[#FF9500] flex items-center justify-center text-sm font-bold border border-orange-500/30">👑</span>
                                        <div>
                                            <h5 class="text-xs font-bold text-white">Shahi Pakwan Orders (Daigs)</h5>
                                            <p class="text-[10px] text-orange-400 font-semibold">Special Ceremonial & Event Daig Bookings</p>
                                        </div>
                                    </div>
                                    <span class="px-2 py-0.5 rounded text-[10px] font-bold bg-orange-500/20 text-[#FF9500]"
                                        x-text="calculateShare(stats?.metrics?.pakwanOrdersCount, stats?.metrics?.totalOrders) + '% of orders'">
                                    </span>
                                </div>

                                <div class="grid grid-cols-3 gap-2 mt-3 text-center">
                                    <div class="p-2 rounded-xl bg-zinc-900/60 border border-white/5">
                                        <p class="text-[9px] uppercase font-bold text-zinc-400">Total Daig Orders</p>
                                        <p class="text-base font-black text-white mt-0.5 tabular-nums" x-text="stats?.metrics?.pakwanOrdersCount || 0"></p>
                                    </div>
                                    <div class="p-2 rounded-xl bg-zinc-900/60 border border-white/5">
                                        <p class="text-[9px] uppercase font-bold text-zinc-400">Daig Revenue</p>
                                        <p class="text-base font-black text-[#FF9500] mt-0.5 tabular-nums" x-text="'Rs. ' + Number(stats?.metrics?.pakwanRevenue || 0).toLocaleString()"></p>
                                    </div>
                                    <div class="p-2 rounded-xl bg-zinc-900/60 border border-white/5">
                                        <p class="text-[9px] uppercase font-bold text-zinc-400">Avg Daig Ticket</p>
                                        <p class="text-base font-black text-emerald-400 mt-0.5 tabular-nums"
                                            x-text="'Rs. ' + (stats?.metrics?.pakwanOrdersCount ? Math.round((stats?.metrics?.pakwanRevenue || 0) / stats?.metrics?.pakwanOrdersCount).toLocaleString() : 0)">
                                        </p>
                                    </div>
                                </div>
                            </div>
                            <div class="mt-3 pt-2 border-t border-white/5 flex items-center justify-between text-[10.5px] text-zinc-400">
                                <span>Includes 12KG Full & 6KG Half Daigs</span>
                                <span class="text-orange-300 font-semibold" x-text="(stats?.metrics?.totalDaigItems || 0) + ' Active Daig Dishes'"></span>
                            </div>
                        </div>

                        <!-- Restaurant Food Orders -->
                        <div class="p-3.5 rounded-2xl bg-zinc-950/70 border border-amber-500/30 relative overflow-hidden flex flex-col justify-between">
                            <div class="absolute -right-6 -bottom-6 opacity-10 text-7xl select-none pointer-events-none">🍽️</div>
                            <div>
                                <div class="flex items-center justify-between">
                                    <div class="flex items-center gap-2">
                                        <span class="w-8 h-8 rounded-xl bg-amber-500/20 text-amber-400 flex items-center justify-center text-sm font-bold border border-amber-500/30">🍽️</span>
                                        <div>
                                            <h5 class="text-xs font-bold text-white">Restaurant Food Orders</h5>
                                            <p class="text-[10px] text-amber-400 font-semibold">Standard Dishes, Karahi, Biryani & Fast Food</p>
                                        </div>
                                    </div>
                                    <span class="px-2 py-0.5 rounded text-[10px] font-bold bg-amber-500/20 text-amber-400"
                                        x-text="calculateShare(stats?.metrics?.restaurantOrdersCount, stats?.metrics?.totalOrders) + '% of orders'">
                                    </span>
                                </div>

                                <div class="grid grid-cols-3 gap-2 mt-3 text-center">
                                    <div class="p-2 rounded-xl bg-zinc-900/60 border border-white/5">
                                        <p class="text-[9px] uppercase font-bold text-zinc-400">Total Food Orders</p>
                                        <p class="text-base font-black text-white mt-0.5 tabular-nums" x-text="stats?.metrics?.restaurantOrdersCount || 0"></p>
                                    </div>
                                    <div class="p-2 rounded-xl bg-zinc-900/60 border border-white/5">
                                        <p class="text-[9px] uppercase font-bold text-zinc-400">Food Revenue</p>
                                        <p class="text-base font-black text-amber-400 mt-0.5 tabular-nums" x-text="'Rs. ' + Number(stats?.metrics?.restaurantRevenue || 0).toLocaleString()"></p>
                                    </div>
                                    <div class="p-2 rounded-xl bg-zinc-900/60 border border-white/5">
                                        <p class="text-[9px] uppercase font-bold text-zinc-400">Avg Food Ticket</p>
                                        <p class="text-base font-black text-emerald-400 mt-0.5 tabular-nums"
                                            x-text="'Rs. ' + (stats?.metrics?.restaurantOrdersCount ? Math.round((stats?.metrics?.restaurantRevenue || 0) / stats?.metrics?.restaurantOrdersCount).toLocaleString() : 0)">
                                        </p>
                                    </div>
                                </div>
                            </div>
                            <div class="mt-3 pt-2 border-t border-white/5 flex items-center justify-between text-[10.5px] text-zinc-400">
                                <span>Includes Single & Family Portions</span>
                                <span class="text-amber-300 font-semibold" x-text="(stats?.metrics?.totalFoodItems || 0) + ' Active Food Items'"></span>
                            </div>
                        </div>
                    </div>

                    <!-- Split Progress Bar -->
                    <div class="space-y-1.5 pt-1">
                        <div class="flex items-center justify-between text-[11px] text-zinc-300 font-semibold">
                            <span class="flex items-center gap-1.5 text-orange-400">
                                <span class="w-2.5 h-2.5 rounded-full bg-[#FF9500]"></span>
                                <span>Pakwan Daigs: <strong class="text-white" x-text="(stats?.metrics?.pakwanOrdersCount || 0) + ' orders'"></strong></span>
                            </span>
                            <span class="flex items-center gap-1.5 text-amber-400">
                                <span class="w-2.5 h-2.5 rounded-full bg-amber-400"></span>
                                <span>Restaurants: <strong class="text-white" x-text="(stats?.metrics?.restaurantOrdersCount || 0) + ' orders'"></strong></span>
                            </span>
                        </div>
                        <div class="h-3 w-full bg-zinc-800 rounded-full overflow-hidden flex shadow-inner">
                            <div class="h-full bg-gradient-to-r from-amber-500 to-orange-500 transition-all duration-500"
                                :style="'width: ' + calculateShare(stats?.metrics?.pakwanOrdersCount, stats?.metrics?.totalOrders) + '%'"
                                title="Pakwan Orders Share">
                            </div>
                            <div class="h-full bg-gradient-to-r from-yellow-400 to-amber-500 transition-all duration-500"
                                :style="'width: ' + calculateShare(stats?.metrics?.restaurantOrdersCount, stats?.metrics?.totalOrders) + '%'"
                                title="Restaurant Orders Share">
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Order Status Breakdown -->
                <div class="cupertino-card rounded-2xl p-3.5 space-y-2.5">
                    <div class="flex items-center justify-between border-b border-white/5 pb-2">
                        <div>
                            <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                <i data-lucide="activity" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                <span>Order Lifecycle & Status Distribution</span>
                            </h4>
                            <p class="text-[10.5px] text-zinc-400">Distribution across Approval, Cooking/Preparation, On The Way, Delivered and Rejected</p>
                        </div>
                        <span class="text-[10.5px] font-mono text-zinc-400" x-text="(stats?.metrics?.totalOrders || 0) + ' Total Registered'"></span>
                    </div>

                    <div class="grid grid-cols-2 sm:grid-cols-5 gap-2 text-center">
                        <div class="p-2.5 rounded-xl bg-emerald-950/20 border border-emerald-500/30">
                            <p class="text-[9px] uppercase font-bold text-emerald-400">Delivered</p>
                            <h5 class="text-base font-black text-emerald-300 mt-0.5 tabular-nums" x-text="stats?.ordersByStatus?.delivered || 0"></h5>
                            <p class="text-[9.5px] text-zinc-400 mt-0.5">Fulfilled</p>
                        </div>
                        <div class="p-2.5 rounded-xl bg-amber-950/20 border border-amber-500/30">
                            <p class="text-[9px] uppercase font-bold text-amber-400">Preparing / Cooking</p>
                            <h5 class="text-base font-black text-amber-300 mt-0.5 tabular-nums" x-text="stats?.ordersByStatus?.preparing || 0"></h5>
                            <p class="text-[9.5px] text-zinc-400 mt-0.5">In Kitchen</p>
                        </div>
                        <div class="p-2.5 rounded-xl bg-orange-950/20 border border-orange-500/30">
                            <p class="text-[9px] uppercase font-bold text-[#FF9500]">On The Way</p>
                            <h5 class="text-base font-black text-orange-300 mt-0.5 tabular-nums" x-text="stats?.ordersByStatus?.onTheWay || 0"></h5>
                            <p class="text-[9.5px] text-zinc-400 mt-0.5">Dispatched</p>
                        </div>
                        <div class="p-2.5 rounded-xl bg-sky-950/20 border border-sky-500/30">
                            <p class="text-[9px] uppercase font-bold text-sky-400">Accepted</p>
                            <h5 class="text-base font-black text-sky-300 mt-0.5 tabular-nums" x-text="stats?.ordersByStatus?.accepted || 0"></h5>
                            <p class="text-[9.5px] text-zinc-400 mt-0.5">Approved</p>
                        </div>
                        <div class="p-2.5 rounded-xl bg-red-950/20 border border-red-500/30 col-span-2 sm:col-span-1">
                            <p class="text-[9px] uppercase font-bold text-red-400">Rejected / Cancelled</p>
                            <h5 class="text-base font-black text-red-300 mt-0.5 tabular-nums" x-text="stats?.ordersByStatus?.cancelled || 0"></h5>
                            <p class="text-[9.5px] text-zinc-400 mt-0.5">Cancelled</p>
                        </div>
                    </div>
                </div>

                <!-- Top Customers Analytics -->
                <div class="cupertino-card rounded-2xl overflow-hidden shadow-sm">
                    <div class="px-3.5 py-2.5 border-b border-white/5 flex items-center justify-between">
                        <div>
                            <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                <i data-lucide="award" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                <span>Top Ordering Customers & High-Value Clients</span>
                            </h4>
                            <p class="text-[10.5px] text-zinc-400">Order frequency and lifetime platform spend per customer phone</p>
                        </div>
                        <span class="text-[10px] text-zinc-400 tabular-nums" x-text="(stats?.topCustomers || []).length + ' Ranked'"></span>
                    </div>

                    <div class="overflow-x-auto">
                        <table class="w-full text-left text-xs">
                            <thead class="bg-zinc-950/60 text-zinc-400 uppercase font-semibold text-[9.5px] border-b border-white/5">
                                <tr>
                                    <th class="py-2 px-3">Customer</th>
                                    <th class="py-2 px-3">Phone Number</th>
                                    <th class="py-2 px-3">Orders Placed</th>
                                    <th class="py-2 px-3">Total Spend</th>
                                    <th class="py-2 px-3">Avg Order Value</th>
                                    <th class="py-2 px-3">Last Order Date</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-white/5 font-medium text-zinc-300">
                                <template x-for="c in (stats?.topCustomers || [])" :key="c.customerPhone">
                                    <tr class="hover:bg-zinc-800/30 transition-colors">
                                        <td class="py-2 px-3">
                                            <div class="font-bold text-white" x-text="c.customerName"></div>
                                            <div class="text-[9.5px] text-[#FF9500]">VIP Customer ⭐</div>
                                        </td>
                                        <td class="py-2 px-3 font-mono text-zinc-300" x-text="c.customerPhone"></td>
                                        <td class="py-2 px-3 font-bold text-white tabular-nums" x-text="c.orderCount + ' Orders'"></td>
                                        <td class="py-2 px-3 font-black text-emerald-400 tabular-nums" x-text="'Rs. ' + Number(c.totalSpent || 0).toLocaleString()"></td>
                                        <td class="py-2 px-3 font-bold text-[#FF9500] tabular-nums" x-text="'Rs. ' + (c.orderCount ? Math.round(c.totalSpent / c.orderCount).toLocaleString() : 0)"></td>
                                        <td class="py-2 px-3 text-[11px] text-zinc-400" x-text="formatDate(c.lastOrderDate)"></td>
                                    </tr>
                                </template>
                            </tbody>
                        </table>
                    </div>
                </div>

            </div>

            <!-- =============================================================== -->
            <!-- TAB 2: PAKWAN CENTERS (LIST VIEW & COMPREHENSIVE DETAIL VIEW) -->
            <!-- =============================================================== -->
            <div x-show="activeTab === 'pakwan-centers'" class="space-y-3.5">
                
                <!-- =========================================================== -->
                <!-- VIEW A: LIST OF PAKWAN CENTERS IN TABLE FORMAT -->
                <!-- =========================================================== -->
                <div x-show="!viewingCenter" class="space-y-3">
                    
                    <!-- Header Toolbar -->
                    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
                        <div>
                            <h3 class="text-xs sm:text-sm font-bold text-white flex items-center gap-2">
                                <i data-lucide="soup" class="w-4 h-4 text-[#FF9500]"></i>
                                <span>Pakwan Centers</span>
                            </h3>
                            <p class="text-[11px] text-zinc-400">List of all registered Shahi Pakwan Centers, riders fleet, orders analytics & instant messaging</p>
                        </div>
                        <div class="flex items-center gap-2 flex-wrap">
                            <button type="button" @click="openCreateRiderModal()" class="px-3 py-1.5 bg-sky-500/20 hover:bg-sky-500/30 text-sky-300 border border-sky-500/40 rounded-xl text-xs font-semibold flex items-center gap-1.5 shadow-sm active:scale-95 transition-all">
                                <i data-lucide="bike" class="w-3.5 h-3.5"></i>
                                <span>+ Rider Add Karein</span>
                            </button>
                            <button type="button" @click="openCreateSubAdminModal()" class="px-3 py-1.5 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-white rounded-xl text-xs font-semibold flex items-center gap-1.5 shadow-sm active:scale-95 transition-all">
                                <i data-lucide="plus-circle" class="w-3.5 h-3.5"></i>
                                <span>+ Naya Pakwan Center Kholein</span>
                            </button>
                        </div>
                    </div>

                    <!-- Search, 3 Type Buttons (All, Restaurant, Pakwan) & Date-wise Filter Bar -->
                    <div class="space-y-2.5 cupertino-card p-3 rounded-2xl border border-white/5">
                        
                        <!-- Top Row: Search Input & The 3 Main Category Buttons (All, Restaurant, Pakwan) -->
                        <div class="flex flex-col lg:flex-row items-stretch lg:items-center justify-between gap-2.5">
                            
                            <!-- Search Bar (Searches Name, Owner, Email, Phone, City, ID, Date) -->
                            <div class="relative flex-1">
                                <i data-lucide="search" class="w-3.5 h-3.5 text-zinc-500 absolute left-3 top-2.5"></i>
                                <input type="text" x-model="searchPakwanQuery" placeholder="Search by Pakwan Center name, manager, email, phone, city, ID or date..."
                                    class="w-full pl-8 pr-8 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white placeholder-zinc-500 focus:outline-none focus:border-[#FF9500]">
                                <button type="button" x-show="searchPakwanQuery" @click="searchPakwanQuery = ''" class="absolute right-2.5 top-2 text-zinc-500 hover:text-white text-xs">✕</button>
                            </div>

                            <!-- THE 3 REQUIRED TYPE BUTTONS: ALL, RESTAURANT, PAKWAN -->
                            <div class="flex items-center gap-1.5 shrink-0 text-xs font-semibold">
                                <!-- Button 1: All -->
                                <button type="button" @click="selectedBusinessTypeFilter = 'All'"
                                    class="px-3.5 py-1.5 rounded-xl transition-all flex items-center gap-1 active:scale-95"
                                    :class="selectedBusinessTypeFilter === 'All' ? 'bg-[#FF9500] text-black font-bold shadow-sm' : 'bg-zinc-900 text-zinc-400 hover:text-white border border-white/5'">
                                    <span>All</span>
                                    <span class="px-1.5 py-0.2 rounded-full text-[9.5px]" :class="selectedBusinessTypeFilter === 'All' ? 'bg-black/20 text-black' : 'bg-zinc-800 text-zinc-400'" x-text="subAdmins.length"></span>
                                </button>

                                <!-- Button 2: Restaurant -->
                                <button type="button" @click="selectedBusinessTypeFilter = 'restaurant'"
                                    class="px-3.5 py-1.5 rounded-xl transition-all flex items-center gap-1 active:scale-95"
                                    :class="selectedBusinessTypeFilter === 'restaurant' ? 'bg-[#FF9500] text-black font-bold shadow-sm' : 'bg-zinc-900 text-zinc-400 hover:text-white border border-white/5'">
                                    <span>🍽️ Restaurant</span>
                                    <span class="px-1.5 py-0.2 rounded-full text-[9.5px]" :class="selectedBusinessTypeFilter === 'restaurant' ? 'bg-black/20 text-black' : 'bg-zinc-800 text-zinc-400'" x-text="subAdmins.filter(s => s.businessType === 'restaurant' || s.businessType === 'both').length"></span>
                                </button>

                                <!-- Button 3: Pakwan -->
                                <button type="button" @click="selectedBusinessTypeFilter = 'pakwan'"
                                    class="px-3.5 py-1.5 rounded-xl transition-all flex items-center gap-1 active:scale-95"
                                    :class="selectedBusinessTypeFilter === 'pakwan' ? 'bg-[#FF9500] text-black font-bold shadow-sm' : 'bg-zinc-900 text-zinc-400 hover:text-white border border-white/5'">
                                    <span>👑 Pakwan</span>
                                    <span class="px-1.5 py-0.2 rounded-full text-[9.5px]" :class="selectedBusinessTypeFilter === 'pakwan' ? 'bg-black/20 text-black' : 'bg-zinc-800 text-zinc-400'" x-text="subAdmins.filter(s => s.businessType === 'pakwan' || s.businessType === 'both').length"></span>
                                </button>
                            </div>

                        </div>

                        <!-- Bottom Row: Date-wise Filter & Sorting Controls -->
                        <div class="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-white/5 text-xs">
                            
                            <!-- Date-wise Quick Filters & Range Pickers -->
                            <div class="flex flex-wrap items-center gap-2">
                                <div class="flex items-center gap-1.5 text-zinc-400 font-semibold text-[11px]">
                                    <i data-lucide="calendar" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                    <span>Date Filter:</span>
                                </div>

                                <!-- Date Preset Select -->
                                <select x-model="datePresetFilter" class="px-2.5 py-1 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                    <option value="all">All Dates (Lifetime)</option>
                                    <option value="today">Joined Today ⚡</option>
                                    <option value="week">Joined Past 7 Days (New ⭐)</option>
                                    <option value="month">Joined Past 30 Days</option>
                                    <option value="custom">Custom Date Range 📅</option>
                                </select>

                                <!-- Custom Date Range Inputs -->
                                <div x-show="datePresetFilter === 'custom'" class="flex items-center gap-1.5">
                                    <input type="date" x-model="filterDateFrom" title="From Date"
                                        class="px-2 py-0.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                    <span class="text-zinc-500">to</span>
                                    <input type="date" x-model="filterDateTo" title="To Date"
                                        class="px-2 py-0.5 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                    <button type="button" x-show="filterDateFrom || filterDateTo" @click="filterDateFrom = ''; filterDateTo = ''; datePresetFilter = 'all'"
                                        class="p-1 text-zinc-400 hover:text-white rounded text-xs" title="Reset Dates">✕</button>
                                </div>
                            </div>

                            <!-- Vendor Status, Sorting & Results Counter -->
                            <div class="flex flex-wrap items-center gap-2.5">
                                <!-- Vendor Status Filter (All, Active, Banned) -->
                                <div class="flex items-center gap-1.5">
                                    <label class="text-[11px] font-semibold text-zinc-400">Status:</label>
                                    <select x-model="selectedVendorStatusFilter" class="px-2.5 py-1 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                        <option value="all">All Vendors (Active & Banned)</option>
                                        <option value="active">Active Centers Only 🟢</option>
                                        <option value="banned">Suspended / Banned Only 🔴</option>
                                    </select>
                                </div>

                                <!-- Sorting Options -->
                                <div class="flex items-center gap-1.5">
                                    <label class="text-[11px] font-semibold text-zinc-400">Sort by:</label>
                                    <select x-model="sortBy" class="px-2.5 py-1 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                        <option value="newest">Newest Joined First</option>
                                        <option value="oldest">Oldest First</option>
                                        <option value="sales">Highest Sales</option>
                                        <option value="orders">Most Orders</option>
                                    </select>

                                    <span class="text-[10.5px] text-zinc-400 pl-1 font-mono" x-text="filteredPakwanCentersList.length + ' Centers matched'"></span>
                                </div>
                            </div>

                        </div>

                    </div>

                    <!-- KPI Metric Summary (Click to Filter by Status Instantly) -->
                    <div class="grid grid-cols-2 sm:grid-cols-5 gap-2 text-center">
                        <button type="button" @click="selectedVendorStatusFilter = 'all'"
                            class="p-2 rounded-xl cupertino-card transition-all cursor-pointer border text-center active:scale-95"
                            :class="selectedVendorStatusFilter === 'all' ? 'border-[#FF9500]/60 bg-[#FF9500]/10 ring-1 ring-[#FF9500]/30 shadow-sm' : 'border-white/5 hover:border-white/20'">
                            <p class="text-[9px] uppercase font-bold text-zinc-400">Total Pakwan Centers</p>
                            <p class="text-sm font-black text-white mt-0.5 tabular-nums" x-text="subAdmins.length"></p>
                        </button>

                        <button type="button" @click="selectedVendorStatusFilter = 'active'"
                            class="p-2 rounded-xl cupertino-card transition-all cursor-pointer border text-center active:scale-95"
                            :class="selectedVendorStatusFilter === 'active' ? 'border-emerald-500/60 bg-emerald-500/15 ring-1 ring-emerald-500/30 shadow-sm' : 'border-white/5 hover:border-emerald-500/30'">
                            <p class="text-[9px] uppercase font-bold text-emerald-400">Active Centers 🟢</p>
                            <p class="text-sm font-black text-emerald-300 mt-0.5 tabular-nums" x-text="subAdmins.filter(s => !s.banned).length"></p>
                        </button>

                        <button type="button" @click="selectedVendorStatusFilter = 'banned'"
                            class="p-2 rounded-xl cupertino-card transition-all cursor-pointer border text-center active:scale-95"
                            :class="selectedVendorStatusFilter === 'banned' ? 'border-red-500/60 bg-red-500/15 ring-1 ring-red-500/30 shadow-sm' : 'border-white/5 hover:border-red-500/30'">
                            <p class="text-[9px] uppercase font-bold text-red-400">Suspended / Banned 🔴</p>
                            <p class="text-sm font-black text-red-300 mt-0.5 tabular-nums" x-text="subAdmins.filter(s => s.banned).length"></p>
                        </button>

                        <div class="p-2 rounded-xl cupertino-card">
                            <p class="text-[9px] uppercase font-bold text-sky-400">Platform Fleet Riders</p>
                            <p class="text-sm font-black text-sky-300 mt-0.5 tabular-nums" x-text="riders.length"></p>
                        </div>

                        <div class="p-2 rounded-xl cupertino-card col-span-2 sm:col-span-1">
                            <p class="text-[9px] uppercase font-bold text-[#FF9500]">Gross Sales</p>
                            <p class="text-sm font-black text-[#FF9500] mt-0.5 tabular-nums" x-text="'Rs. ' + totalSubAdminSales().toLocaleString()"></p>
                        </div>
                    </div>

                    <!-- PAKWAN CENTERS COMPLETE TABLE (CORE USER REQUIREMENT) -->
                    <div class="cupertino-card rounded-2xl overflow-hidden shadow-sm">
                        <div class="overflow-x-auto">
                            <table class="w-full text-left text-xs">
                                <thead class="bg-zinc-950/70 text-zinc-400 uppercase font-semibold text-[9.5px] border-b border-white/5">
                                    <tr>
                                        <th class="py-2.5 px-3">Pakwan Center & ID</th>
                                        <th class="py-2.5 px-3">Manager & Contact</th>
                                        <th class="py-2.5 px-3">Location & GPS</th>
                                        <th class="py-2.5 px-3 text-center">Joined Date</th>
                                        <th class="py-2.5 px-3 text-center">Riders</th>
                                        <th class="py-2.5 px-3 text-center">Customers</th>
                                        <th class="py-2.5 px-3 text-center">Total Orders</th>
                                        <th class="py-2.5 px-3 text-center">Delivered</th>
                                        <th class="py-2.5 px-3 text-center">Pending</th>
                                        <th class="py-2.5 px-3 text-center">Rejected</th>
                                        <th class="py-2.5 px-3">Gross Sales</th>
                                        <th class="py-2.5 px-3">Status</th>
                                        <th class="py-2.5 px-3 text-right">Actions</th>
                                    </tr>
                                </thead>
                                <tbody class="divide-y divide-white/5 font-medium text-zinc-300">
                                    <template x-for="sa in filteredPakwanCentersList" :key="sa.id">
                                        <tr class="hover:bg-zinc-800/40 transition-colors cursor-pointer" @click="viewCenterDetails(sa)">
                                            
                                            <!-- Center & ID -->
                                            <td class="py-2.5 px-3">
                                                <div class="flex items-center gap-2">
                                                    <div class="w-8 h-8 rounded-xl flex items-center justify-center font-bold text-xs shrink-0 border"
                                                        :class="sa.businessType === 'pakwan' ? 'bg-orange-500/20 border-orange-500/30 text-[#FF9500]' : (sa.businessType === 'restaurant' ? 'bg-amber-500/20 border-amber-500/30 text-amber-300' : 'bg-purple-500/20 border-purple-500/30 text-purple-300')">
                                                        <span x-text="sa.businessType === 'pakwan' ? '👑' : (sa.businessType === 'restaurant' ? '🍽️' : '👑🍽️')"></span>
                                                    </div>
                                                    <div class="min-w-0">
                                                        <div class="font-bold text-white text-xs truncate max-w-[170px]" x-text="sa.businessName || sa.name"></div>
                                                        <div class="flex items-center gap-1 mt-0.5">
                                                            <span class="font-mono text-[9px] text-zinc-400" x-text="sa.id"></span>
                                                            <span class="px-1.5 py-0.2 rounded text-[8px] font-bold uppercase tracking-wider bg-zinc-800 text-zinc-300"
                                                                x-text="sa.businessType">
                                                            </span>
                                                        </div>
                                                    </div>
                                                </div>
                                            </td>

                                            <!-- Manager & Contact -->
                                            <td class="py-2.5 px-3">
                                                <div class="font-semibold text-white" x-text="sa.name"></div>
                                                <div class="text-[10px] text-zinc-400 font-mono" x-text="sa.phone || '—'"></div>
                                            </td>

                                            <!-- Location & GPS Link -->
                                            <td class="py-2.5 px-3" @click.stop>
                                                <div class="text-[11px] text-zinc-300 truncate max-w-[140px]" x-text="(sa.address || 'Lahore') + ' • ' + (sa.city || 'Lahore')"></div>
                                                <a :href="'https://www.google.com/maps/search/?api=1&query=' + (sa.latitude || 31.5204) + ',' + (sa.longitude || 74.3587)" target="_blank" rel="noopener noreferrer" class="text-[10px] text-[#FF9500] hover:underline font-bold inline-flex items-center gap-0.5 mt-0.5">
                                                    <i data-lucide="navigation" class="w-2.5 h-2.5"></i>
                                                    <span>📍 GPS Map</span>
                                                </a>
                                            </td>

                                            <!-- Joined Date & Status -->
                                            <td class="py-2.5 px-3 text-center whitespace-nowrap">
                                                <div class="text-[11px] font-semibold text-zinc-200" x-text="formatDateShort(sa.createdAt)"></div>
                                                <template x-if="isNewJoiner(sa.createdAt)">
                                                    <span class="px-1.5 py-0.2 rounded text-[8px] font-black uppercase bg-[#FF9500]/20 text-[#FF9500] border border-orange-500/30">NEW ⭐</span>
                                                </template>
                                            </td>

                                            <!-- Riders Count -->
                                            <td class="py-2.5 px-3 text-center">
                                                <span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-sky-500/15 text-sky-400 border border-sky-500/25 tabular-nums"
                                                    x-text="(sa.ridersCount || getOutletRiders(sa.id).length) + ' 🛵'">
                                                </span>
                                            </td>

                                            <!-- Customers Count -->
                                            <td class="py-2.5 px-3 text-center">
                                                <span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-purple-500/15 text-purple-300 border border-purple-500/25 tabular-nums"
                                                    x-text="(sa.customersCount || 0) + ' 👤'">
                                                </span>
                                            </td>

                                            <!-- Total Orders -->
                                            <td class="py-2.5 px-3 text-center">
                                                <span class="font-bold text-white tabular-nums text-xs" x-text="sa.totalOrders || 0"></span>
                                            </td>

                                            <!-- Delivered -->
                                            <td class="py-2.5 px-3 text-center">
                                                <span class="font-bold text-emerald-400 tabular-nums text-xs" x-text="sa.deliveredOrders || sa.completedOrders || 0"></span>
                                            </td>

                                            <!-- Pending -->
                                            <td class="py-2.5 px-3 text-center">
                                                <span class="font-bold text-amber-400 tabular-nums text-xs" x-text="sa.pendingOrders || 0"></span>
                                            </td>

                                            <!-- Rejected -->
                                            <td class="py-2.5 px-3 text-center">
                                                <span class="font-bold text-red-400 tabular-nums text-xs" x-text="sa.cancelledOrders || 0"></span>
                                            </td>

                                            <!-- Gross Sales -->
                                            <td class="py-2.5 px-3 font-black text-[#FF9500] tabular-nums whitespace-nowrap" x-text="'Rs. ' + Number(sa.totalSales || 0).toLocaleString()"></td>

                                            <!-- Status (Active / Suspended) -->
                                            <td class="py-2.5 px-3 whitespace-nowrap" @click.stop>
                                                <button type="button" @click="toggleBanSubAdmin(sa)"
                                                    class="px-2 py-0.5 rounded-full text-[9px] font-bold uppercase tracking-wider inline-flex items-center gap-1 transition-transform active:scale-95 border"
                                                    :class="sa.banned ? 'bg-red-500/20 text-red-300 border-red-500/40 hover:bg-red-500/30' : 'bg-emerald-500/20 text-emerald-300 border-emerald-500/40 hover:bg-emerald-500/30'"
                                                    :title="sa.banned ? 'Vendor is BANNED (Click to UNBAN / ACTIVATE)' : 'Vendor is ACTIVE (Click to BAN / SUSPEND)'">
                                                    <span class="w-1.5 h-1.5 rounded-full" :class="sa.banned ? 'bg-red-400 animate-pulse' : 'bg-emerald-400'"></span>
                                                    <span x-text="sa.banned ? 'BANNED' : 'ACTIVE'"></span>
                                                </button>
                                            </td>

                                            <!-- Actions Row Buttons -->
                                            <td class="py-2.5 px-3 text-right whitespace-nowrap" @click.stop>
                                                <div class="inline-flex items-center gap-1">
                                                    <!-- View Button -->
                                                    <button type="button" @click="viewCenterDetails(sa)" class="p-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 rounded-lg transition-all" title="View Detailed Analytics & History">
                                                        <i data-lucide="eye" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                                    </button>

                                                    <!-- Edit Button -->
                                                    <button type="button" @click="openEditSubAdminModal(sa)" class="p-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 rounded-lg transition-all" title="Edit Center Profile & Settings">
                                                        <i data-lucide="edit" class="w-3.5 h-3.5 text-sky-400"></i>
                                                    </button>

                                                    <!-- Notification Button (Opens Slide-over Sheet) -->
                                                    <button type="button" @click="openNotificationSheet(sa)" class="p-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 rounded-lg transition-all" title="Send Official Notification">
                                                        <i data-lucide="bell" class="w-3.5 h-3.5 text-amber-400"></i>
                                                    </button>

                                                    <!-- Ban / Unban Button -->
                                                    <button type="button" @click="toggleBanSubAdmin(sa)" class="p-1.5 rounded-lg transition-all border"
                                                        :class="sa.banned ? 'bg-emerald-500/20 text-emerald-300 hover:bg-emerald-500/30 border-emerald-500/40' : 'bg-red-500/20 text-red-300 hover:bg-red-500/30 border-red-500/40'"
                                                        :title="sa.banned ? 'Unban & Activate Center' : 'Ban & Suspend Center'">
                                                        <i :data-lucide="sa.banned ? 'shield-check' : 'ban'" class="w-3.5 h-3.5"></i>
                                                    </button>

                                                    <!-- Delete Button (Confirmation Prompt) -->
                                                    <button type="button" @click="confirmDeleteSubAdmin(sa)" class="p-1.5 bg-red-950/40 hover:bg-red-900/60 text-red-400 rounded-lg transition-all" title="Delete Pakwan Center">
                                                        <i data-lucide="trash-2" class="w-3.5 h-3.5"></i>
                                                    </button>
                                                </div>
                                            </td>

                                        </tr>
                                    </template>
                                    <template x-if="filteredPakwanCentersList.length === 0">
                                        <tr>
                                            <td colspan="13" class="text-center py-8 text-zinc-500 italic">No Pakwan Centers found matching query.</td>
                                        </tr>
                                    </template>
                                </tbody>
                            </table>
                        </div>
                    </div>

                </div>

                <!-- =========================================================== -->
                <!-- VIEW B: COMPREHENSIVE DEDICATED DETAIL PAGE FOR PAKWAN CENTER -->
                <!-- =========================================================== -->
                <div x-show="viewingCenter" class="space-y-3.5">
                    
                    <!-- Back Button Bar -->
                    <div class="flex items-center justify-between pb-1">
                        <button type="button" @click="viewingCenter = null" class="px-3 py-1.5 bg-zinc-900 hover:bg-zinc-800 text-zinc-300 rounded-xl text-xs font-semibold flex items-center gap-1.5 border border-white/5 transition-all">
                            <i data-lucide="arrow-left" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                            <span>Wapis Pakwan Centers List Par Jayein</span>
                        </button>

                        <div class="flex items-center gap-2">
                            <button type="button" @click="openNotificationSheet(viewingCenter)" class="px-3 py-1.5 bg-amber-500/15 hover:bg-amber-500/25 text-amber-300 rounded-xl text-xs font-semibold flex items-center gap-1.5 border border-amber-500/30 transition-all">
                                <i data-lucide="bell" class="w-3.5 h-3.5"></i>
                                <span>Send Notification</span>
                            </button>
                            <button type="button" @click="openEditSubAdminModal(viewingCenter)" class="px-3 py-1.5 bg-sky-500/15 hover:bg-sky-500/25 text-sky-300 rounded-xl text-xs font-semibold flex items-center gap-1.5 border border-sky-500/30 transition-all">
                                <i data-lucide="edit" class="w-3.5 h-3.5"></i>
                                <span>Edit Center</span>
                            </button>
                        </div>
                    </div>

                    <!-- HERO SECTION FOR THIS PAKWAN CENTER -->
                    <div class="cupertino-card rounded-3xl p-4 sm:p-5 relative overflow-hidden border border-orange-500/30 bg-gradient-to-br from-zinc-950/90 via-zinc-900/80 to-orange-950/20">
                        <div class="absolute -right-8 -bottom-8 opacity-10 text-9xl select-none pointer-events-none">👑</div>
                        
                        <!-- Top Info -->
                        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
                            <div class="flex items-center gap-3.5">
                                <div class="w-14 h-14 rounded-2xl bg-orange-500/20 border border-orange-500/40 text-[#FF9500] flex items-center justify-center font-black text-2xl shadow-xl shrink-0">
                                    <span x-text="viewingCenter?.businessType === 'pakwan' ? '👑' : (viewingCenter?.businessType === 'restaurant' ? '🍽️' : '👑🍽️')"></span>
                                </div>
                                <div>
                                    <div class="flex items-center gap-2 flex-wrap">
                                        <h3 class="text-base sm:text-lg font-black text-white" x-text="viewingCenter?.businessName || viewingCenter?.name"></h3>
                                        <span class="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider"
                                            :class="viewingCenter?.banned ? 'bg-red-500/20 text-red-300 border border-red-500/40' : 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/40'"
                                            x-text="viewingCenter?.banned ? 'SUSPENDED' : 'ACTIVE PAKWAN CENTER'">
                                        </span>
                                        <span class="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-orange-500/20 text-[#FF9500] border border-orange-500/30"
                                            x-text="viewingCenter?.businessType === 'pakwan' ? '👑 Shahi Pakwan Center' : (viewingCenter?.businessType === 'both' ? '👑🍽️ Pakwan + Restaurant' : '🍽️ Restaurant')">
                                        </span>
                                    </div>
                                    <p class="text-xs text-zinc-400 mt-1 flex items-center gap-2 flex-wrap">
                                        <span>Manager: <strong class="text-white" x-text="viewingCenter?.name"></strong></span>
                                        <span>&bull;</span>
                                        <span class="font-mono text-zinc-400" x-text="viewingCenter?.id"></span>
                                        <span>&bull;</span>
                                        <span class="text-zinc-300" x-text="viewingCenter?.email"></span>
                                        <span>&bull;</span>
                                        <span class="text-[#FF9500] font-mono" x-text="viewingCenter?.phone"></span>
                                    </p>
                                    <div class="flex items-center gap-2 text-xs text-zinc-400 mt-1">
                                        <i data-lucide="map-pin" class="w-3.5 h-3.5 text-zinc-500 shrink-0"></i>
                                        <span x-text="(viewingCenter?.address || 'Lahore') + ' • ' + (viewingCenter?.city || 'Lahore')"></span>
                                        <a :href="'https://www.google.com/maps/search/?api=1&query=' + (viewingCenter?.latitude || 31.5204) + ',' + (viewingCenter?.longitude || 74.3587)" target="_blank" rel="noopener noreferrer" class="text-[#FF9500] font-bold hover:underline flex items-center gap-0.5 ml-1">
                                            <i data-lucide="navigation" class="w-3 h-3"></i>
                                            <span>Google Maps GPS Pin</span>
                                        </a>
                                    </div>
                                </div>
                            </div>

                            <!-- Hero Right Actions -->
                            <div class="flex items-center gap-1.5 self-end sm:self-auto">
                                <button type="button" @click="toggleBanSubAdmin(viewingCenter)" class="px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center gap-1.5 border transition-all active:scale-95"
                                    :class="viewingCenter?.banned ? 'bg-emerald-500/20 text-emerald-300 border-emerald-500/40 hover:bg-emerald-500/30' : 'bg-red-500/20 text-red-300 border-red-500/40 hover:bg-red-500/30'"
                                    :title="viewingCenter?.banned ? 'Click to UNBAN & ACTIVATE vendor' : 'Click to BAN & SUSPEND vendor'">
                                    <i :data-lucide="viewingCenter?.banned ? 'shield-check' : 'ban'" class="w-3.5 h-3.5"></i>
                                    <span x-text="viewingCenter?.banned ? 'Unban & Activate Center' : 'Ban & Suspend Center'"></span>
                                </button>
                                <button type="button" @click="confirmDeleteSubAdmin(viewingCenter)" class="px-3 py-1.5 bg-red-950/40 hover:bg-red-900/60 text-red-300 rounded-xl text-xs font-semibold flex items-center gap-1 border border-red-500/30 transition-all">
                                    <i data-lucide="trash-2" class="w-3.5 h-3.5"></i>
                                    <span>Delete</span>
                                </button>
                            </div>
                        </div>

                        <!-- KPI Strip in Hero -->
                        <div class="grid grid-cols-2 sm:grid-cols-6 gap-2 mt-4 pt-4 border-t border-white/5 text-center">
                            <div class="p-2 bg-zinc-950/60 rounded-xl border border-white/5">
                                <p class="text-[9px] uppercase font-bold text-zinc-400">Total Sales</p>
                                <p class="text-sm sm:text-base font-black text-[#FF9500] mt-0.5 tabular-nums" x-text="'Rs. ' + Number(viewingCenter?.totalSales || 0).toLocaleString()"></p>
                            </div>
                            <div class="p-2 bg-zinc-950/60 rounded-xl border border-white/5">
                                <p class="text-[9px] uppercase font-bold text-zinc-400">Total Orders</p>
                                <p class="text-sm sm:text-base font-black text-white mt-0.5 tabular-nums" x-text="viewingCenter?.totalOrders || (viewingCenter?.orders || []).length"></p>
                            </div>
                            <div class="p-2 bg-zinc-950/60 rounded-xl border border-white/5">
                                <p class="text-[9px] uppercase font-bold text-emerald-400">Delivered</p>
                                <p class="text-sm sm:text-base font-black text-emerald-300 mt-0.5 tabular-nums" x-text="viewingCenter?.deliveredOrders || 0"></p>
                            </div>
                            <div class="p-2 bg-zinc-950/60 rounded-xl border border-white/5">
                                <p class="text-[9px] uppercase font-bold text-amber-400">In Kitchen / Pending</p>
                                <p class="text-sm sm:text-base font-black text-amber-300 mt-0.5 tabular-nums" x-text="viewingCenter?.pendingOrders || 0"></p>
                            </div>
                            <div class="p-2 bg-zinc-950/60 rounded-xl border border-white/5">
                                <p class="text-[9px] uppercase font-bold text-red-400">Rejected</p>
                                <p class="text-sm sm:text-base font-black text-red-300 mt-0.5 tabular-nums" x-text="viewingCenter?.cancelledOrders || 0"></p>
                            </div>
                            <div class="p-2 bg-zinc-950/60 rounded-xl border border-white/5">
                                <p class="text-[9px] uppercase font-bold text-sky-400">Riders & Clients</p>
                                <p class="text-sm sm:text-base font-black text-sky-300 mt-0.5 tabular-nums" x-text="(viewingCenter?.riders || []).length + ' R • ' + (viewingCenter?.customers || []).length + ' C'"></p>
                            </div>
                        </div>

                    </div>

                    <!-- DETAIL PAGE SUB-TABS NAVIGATION -->
                    <div class="flex items-center gap-1.5 overflow-x-auto pb-1 text-xs font-semibold border-b border-white/5">
                        <button type="button" @click="detailSubTab = 'orders'"
                            class="px-3.5 py-1.5 rounded-xl transition-all flex items-center gap-1.5"
                            :class="detailSubTab === 'orders' ? 'bg-[#FF9500] text-black font-bold shadow-sm' : 'bg-zinc-900 text-zinc-400 hover:text-white'">
                            <i data-lucide="shopping-bag" class="w-3.5 h-3.5"></i>
                            <span>Orders History (<span x-text="(viewingCenter?.orders || []).length"></span>)</span>
                        </button>

                        <button type="button" @click="detailSubTab = 'riders'"
                            class="px-3.5 py-1.5 rounded-xl transition-all flex items-center gap-1.5"
                            :class="detailSubTab === 'riders' ? 'bg-[#FF9500] text-black font-bold shadow-sm' : 'bg-zinc-900 text-zinc-400 hover:text-white'">
                            <i data-lucide="bike" class="w-3.5 h-3.5"></i>
                            <span>Dedicated Riders (<span x-text="(viewingCenter?.riders || []).length"></span>)</span>
                        </button>

                        <button type="button" @click="detailSubTab = 'customers'"
                            class="px-3.5 py-1.5 rounded-xl transition-all flex items-center gap-1.5"
                            :class="detailSubTab === 'customers' ? 'bg-[#FF9500] text-black font-bold shadow-sm' : 'bg-zinc-900 text-zinc-400 hover:text-white'">
                            <i data-lucide="users" class="w-3.5 h-3.5"></i>
                            <span>Customers Analytics (<span x-text="(viewingCenter?.customers || []).length"></span>)</span>
                        </button>

                        <button type="button" @click="detailSubTab = 'menu'"
                            class="px-3.5 py-1.5 rounded-xl transition-all flex items-center gap-1.5"
                            :class="detailSubTab === 'menu' ? 'bg-[#FF9500] text-black font-bold shadow-sm' : 'bg-zinc-900 text-zinc-400 hover:text-white'">
                            <i data-lucide="soup" class="w-3.5 h-3.5"></i>
                            <span>Menu Dishes & Daigs (<span x-text="((viewingCenter?.foods || []).length) + '/' + ((viewingCenter?.daigs || []).length)"></span>)</span>
                        </button>
                    </div>

                    <!-- ======================================================= -->
                    <!-- SUB-TAB 1: ORDERS HISTORY & DELIVERIES -->
                    <!-- ======================================================= -->
                    <div x-show="detailSubTab === 'orders'" class="cupertino-card rounded-2xl overflow-hidden shadow-sm">
                        <div class="px-3.5 py-2.5 border-b border-white/5 flex items-center justify-between">
                            <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                <i data-lucide="shopping-bag" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                <span>Orders Recorded for <span x-text="viewingCenter?.businessName"></span></span>
                            </h4>
                            <span class="text-[11px] text-zinc-400 tabular-nums" x-text="(viewingCenter?.orders || []).length + ' Total Orders'"></span>
                        </div>

                        <div class="overflow-x-auto">
                            <table class="w-full text-left text-xs">
                                <thead class="bg-zinc-950/70 text-zinc-400 uppercase font-semibold text-[9.5px] border-b border-white/5">
                                    <tr>
                                        <th class="py-2.5 px-3">Order ID & Date</th>
                                        <th class="py-2.5 px-3">Customer Details</th>
                                        <th class="py-2.5 px-3">Items & Booking</th>
                                        <th class="py-2.5 px-3">Delivery Address & GPS</th>
                                        <th class="py-2.5 px-3">Amount</th>
                                        <th class="py-2.5 px-3">Assigned Rider</th>
                                        <th class="py-2.5 px-3">Status</th>
                                    </tr>
                                </thead>
                                <tbody class="divide-y divide-white/5 font-medium text-zinc-300">
                                    <template x-for="o in (viewingCenter?.orders || [])" :key="o.id">
                                        <tr class="hover:bg-zinc-800/30 transition-colors">
                                            <td class="py-2.5 px-3">
                                                <div class="font-mono font-bold text-[#FF9500]" x-text="o.id"></div>
                                                <div class="text-[9.5px] text-zinc-500" x-text="formatDate(o.orderDate)"></div>
                                            </td>
                                            <td class="py-2.5 px-3">
                                                <div class="font-bold text-white" x-text="o.customerName"></div>
                                                <div class="text-[10px] text-zinc-400 font-mono" x-text="o.customerPhone"></div>
                                            </td>
                                            <td class="py-2.5 px-3">
                                                <div class="flex items-center gap-1">
                                                    <span class="px-1.5 py-0.2 rounded text-[8.5px] font-bold uppercase"
                                                        :class="o.isDaigBooking ? 'bg-orange-500/20 text-[#FF9500] border border-orange-500/30' : 'bg-amber-500/20 text-amber-300 border border-amber-500/30'"
                                                        x-text="o.isDaigBooking ? '👑 Daig' : '🍽️ Food'">
                                                    </span>
                                                    <span class="truncate max-w-xs text-zinc-200" x-text="(o.items || []).join(', ')"></span>
                                                </div>
                                            </td>
                                            <td class="py-2.5 px-3">
                                                <div class="text-zinc-300 truncate max-w-[180px]" x-text="o.deliveryAddress || 'Lahore'"></div>
                                                <a :href="'https://www.google.com/maps/search/?api=1&query=' + (o.latitude || 31.5204) + ',' + (o.longitude || 74.3587)" target="_blank" rel="noopener noreferrer" class="text-[10px] text-[#FF9500] hover:underline font-bold inline-flex items-center gap-0.5 mt-0.5">
                                                    <i data-lucide="navigation" class="w-2.5 h-2.5"></i>
                                                    <span>📍 View GPS Location</span>
                                                </a>
                                            </td>
                                            <td class="py-2.5 px-3 font-bold text-white tabular-nums" x-text="'Rs. ' + o.totalAmount"></td>
                                            <td class="py-2.5 px-3 font-medium text-sky-400" x-text="o.riderName || 'Unassigned'"></td>
                                            <td class="py-2.5 px-3">
                                                <span class="px-2 py-0.5 rounded-full text-[10px] font-bold"
                                                    :class="getStatusBadgeClass(o.status)" x-text="o.status">
                                                </span>
                                                <template x-if="o.rejectionReason">
                                                    <div class="text-[9px] text-red-400 mt-0.5 italic" x-text="'Reason: ' + o.rejectionReason"></div>
                                                </template>
                                            </td>
                                        </tr>
                                    </template>
                                    <template x-if="(viewingCenter?.orders || []).length === 0">
                                        <tr>
                                            <td colspan="7" class="text-center py-6 text-zinc-500 italic">Is Pakwan Center par abhi tak koi order place nahi hua.</td>
                                        </tr>
                                    </template>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- ======================================================= -->
                    <!-- SUB-TAB 2: RIDERS PERFORMANCE & ROSTER -->
                    <!-- ======================================================= -->
                    <div x-show="detailSubTab === 'riders'" class="space-y-3">
                        <div class="flex items-center justify-between">
                            <div>
                                <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                    <i data-lucide="bike" class="w-3.5 h-3.5 text-sky-400"></i>
                                    <span>Dedicated Fleet Riders (<span x-text="(viewingCenter?.riders || []).length"></span>)</span>
                                </h4>
                                <p class="text-[10.5px] text-zinc-400">Riders assigned specifically to this Pakwan Center, their delivery records and customers served</p>
                            </div>
                            <button type="button" @click="openCreateRiderModal(viewingCenter)" class="px-3 py-1.5 bg-sky-500/20 hover:bg-sky-500/30 text-sky-300 border border-sky-500/40 rounded-xl text-xs font-semibold flex items-center gap-1.5 shadow-sm active:scale-95 transition-all">
                                <i data-lucide="user-plus" class="w-3.5 h-3.5"></i>
                                <span>+ Is Center Ka Naya Rider Add Karein</span>
                            </button>
                        </div>

                        <!-- Riders Cards Grid -->
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                            <template x-for="r in (viewingCenter?.riders || [])" :key="r.id">
                                <div class="cupertino-card rounded-2xl p-3.5 space-y-3 border border-white/5 hover:border-sky-500/30 transition-all">
                                    <div class="flex items-start justify-between">
                                        <div class="flex items-center gap-2.5">
                                            <div class="w-9 h-9 rounded-xl bg-sky-500/15 border border-sky-500/30 text-sky-400 flex items-center justify-center font-bold text-sm shrink-0">
                                                <i data-lucide="bike" class="w-4 h-4"></i>
                                            </div>
                                            <div>
                                                <h5 class="text-xs font-bold text-white" x-text="r.name"></h5>
                                                <p class="text-[10.5px] font-mono text-zinc-400" x-text="r.phone"></p>
                                                <p class="text-[10px] text-zinc-500 font-mono" x-text="r.email"></p>
                                            </div>
                                        </div>
                                        <span class="px-2 py-0.5 rounded-full text-[9px] font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">Active</span>
                                    </div>

                                    <!-- Rider Stats Strip -->
                                    <div class="grid grid-cols-3 gap-1.5 text-center">
                                        <div class="p-2 rounded-xl bg-zinc-950/60 border border-white/5">
                                            <p class="text-[8.5px] uppercase font-bold text-emerald-400">Delivered</p>
                                            <p class="text-sm font-black text-white mt-0.5 tabular-nums" x-text="r.deliveredCount || 0"></p>
                                        </div>
                                        <div class="p-2 rounded-xl bg-zinc-950/60 border border-white/5">
                                            <p class="text-[8.5px] uppercase font-bold text-amber-400">In Transit</p>
                                            <p class="text-sm font-black text-amber-300 mt-0.5 tabular-nums" x-text="r.pendingCount || 0"></p>
                                        </div>
                                        <div class="p-2 rounded-xl bg-zinc-950/60 border border-white/5">
                                            <p class="text-[8.5px] uppercase font-bold text-red-400">Cancelled</p>
                                            <p class="text-sm font-black text-red-300 mt-0.5 tabular-nums" x-text="r.cancelledCount || 0"></p>
                                        </div>
                                    </div>

                                    <!-- Deliveries list for this rider -->
                                    <div class="pt-2 border-t border-white/5 space-y-1.5">
                                        <p class="text-[10px] font-bold uppercase tracking-wider text-zinc-400">Recent Deliveries Handled:</p>
                                        <template x-for="deliv in (r.recentDeliveries || []).slice(0, 3)" :key="deliv.id">
                                            <div class="p-1.5 rounded-lg bg-zinc-950/40 border border-white/5 flex items-center justify-between text-[10.5px]">
                                                <div>
                                                    <span class="font-bold text-white" x-text="deliv.customerName"></span>
                                                    <span class="text-zinc-500"> &bull; </span>
                                                    <span class="font-mono text-zinc-400" x-text="deliv.id"></span>
                                                </div>
                                                <div class="flex items-center gap-2">
                                                    <span class="font-bold text-emerald-400 tabular-nums" x-text="'Rs. ' + deliv.totalAmount"></span>
                                                    <span class="px-1.5 py-0.2 rounded text-[8.5px] font-bold"
                                                        :class="getStatusBadgeClass(deliv.status)" x-text="deliv.status">
                                                    </span>
                                                </div>
                                            </div>
                                        </template>
                                        <template x-if="(r.recentDeliveries || []).length === 0">
                                            <p class="text-[10px] text-zinc-500 italic py-1">No orders delivered yet.</p>
                                        </template>
                                    </div>
                                </div>
                            </template>
                            <template x-if="(viewingCenter?.riders || []).length === 0">
                                <div class="col-span-2 text-center py-8 text-zinc-500 cupertino-card rounded-2xl italic">
                                    Is Pakwan Center ka koi dedicated rider add nahi hua. Upar diye gaye button se rider add karein.
                                </div>
                            </template>
                        </div>
                    </div>

                    <!-- ======================================================= -->
                    <!-- SUB-TAB 3: CUSTOMERS ANALYTICS -->
                    <!-- ======================================================= -->
                    <div x-show="detailSubTab === 'customers'" class="cupertino-card rounded-2xl overflow-hidden shadow-sm">
                        <div class="px-3.5 py-2.5 border-b border-white/5 flex items-center justify-between">
                            <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                <i data-lucide="users" class="w-3.5 h-3.5 text-purple-400"></i>
                                <span>Customers Who Ordered from <span x-text="viewingCenter?.businessName"></span></span>
                            </h4>
                            <span class="text-[11px] text-zinc-400 tabular-nums" x-text="(viewingCenter?.customers || []).length + ' Registered Clients'"></span>
                        </div>

                        <div class="overflow-x-auto">
                            <table class="w-full text-left text-xs">
                                <thead class="bg-zinc-950/70 text-zinc-400 uppercase font-semibold text-[9.5px] border-b border-white/5">
                                    <tr>
                                        <th class="py-2.5 px-3">Customer</th>
                                        <th class="py-2.5 px-3">Phone Number</th>
                                        <th class="py-2.5 px-3">Orders Placed</th>
                                        <th class="py-2.5 px-3">Delivered</th>
                                        <th class="py-2.5 px-3">Total Spend at this Center</th>
                                        <th class="py-2.5 px-3">Last Order Date</th>
                                    </tr>
                                </thead>
                                <tbody class="divide-y divide-white/5 font-medium text-zinc-300">
                                    <template x-for="c in (viewingCenter?.customers || [])" :key="c.customerPhone">
                                        <tr class="hover:bg-zinc-800/30 transition-colors">
                                            <td class="py-2.5 px-3">
                                                <div class="font-bold text-white" x-text="c.customerName"></div>
                                                <div class="text-[9.5px] text-[#FF9500]">Client ⭐</div>
                                            </td>
                                            <td class="py-2.5 px-3 font-mono text-zinc-300" x-text="c.customerPhone"></td>
                                            <td class="py-2.5 px-3 font-bold text-white tabular-nums" x-text="c.orderCount + ' Orders'"></td>
                                            <td class="py-2.5 px-3 font-bold text-emerald-400 tabular-nums" x-text="(c.deliveredCount || 0) + ' Delivered'"></td>
                                            <td class="py-2.5 px-3 font-black text-[#FF9500] tabular-nums" x-text="'Rs. ' + Number(c.totalSpent || 0).toLocaleString()"></td>
                                            <td class="py-2.5 px-3 text-[11px] text-zinc-400" x-text="formatDate(c.lastOrderDate)"></td>
                                        </tr>
                                    </template>
                                    <template x-if="(viewingCenter?.customers || []).length === 0">
                                        <tr>
                                            <td colspan="6" class="text-center py-6 text-zinc-500 italic">Is Pakwan Center se kisi customer ne order nahi kiya abhi tak.</td>
                                        </tr>
                                    </template>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- ======================================================= -->
                    <!-- SUB-TAB 4: MENU DISHES & SHAHI DAIGS -->
                    <!-- ======================================================= -->
                    <div x-show="detailSubTab === 'menu'" class="space-y-4">
                        <!-- Shahi Daigs Section -->
                        <div class="cupertino-card rounded-2xl p-3.5 space-y-3">
                            <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                <i data-lucide="soup" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                <span>Shahi Daig Pakwans (<span x-text="(viewingCenter?.daigs || []).length"></span>)</span>
                            </h4>
                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                                <template x-for="d in (viewingCenter?.daigs || [])" :key="d.id">
                                    <div class="p-2.5 bg-zinc-950/60 rounded-xl border border-white/5 flex items-center gap-3">
                                        <img :src="d.imageUrl" class="w-12 h-12 rounded-xl object-cover shrink-0 border border-white/5" alt="">
                                        <div class="min-w-0 flex-1">
                                            <p class="text-xs font-bold text-white truncate" x-text="d.name"></p>
                                            <p class="text-[11px] font-bold text-amber-400 mt-0.5 tabular-nums" x-text="'Full (12KG): Rs. ' + Number(d.fullDaigPrice).toLocaleString() + ' • Half: Rs. ' + Number(d.halfDaigPrice).toLocaleString()"></p>
                                            <p class="text-[10px] text-zinc-500 truncate mt-0.5" x-text="(d.includes || []).join(', ')"></p>
                                        </div>
                                    </div>
                                </template>
                                <template x-if="(viewingCenter?.daigs || []).length === 0">
                                    <p class="text-xs text-zinc-500 col-span-2 py-2 italic">Is center ne koi Daig upload nahi ki.</p>
                                </template>
                            </div>
                        </div>

                        <!-- Regular Food Dishes -->
                        <div class="cupertino-card rounded-2xl p-3.5 space-y-3">
                            <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                <i data-lucide="utensils" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                <span>Restaurant & Kitchen Dishes (<span x-text="(viewingCenter?.foods || []).length"></span>)</span>
                            </h4>
                            <div class="grid grid-cols-2 sm:grid-cols-3 gap-2.5">
                                <template x-for="f in (viewingCenter?.foods || [])" :key="f.id">
                                    <div class="p-2.5 bg-zinc-950/60 rounded-xl border border-white/5 flex items-center gap-2.5">
                                        <img :src="f.imageUrl" class="w-10 h-10 rounded-lg object-cover shrink-0 border border-white/5" alt="">
                                        <div class="min-w-0">
                                            <p class="text-xs font-semibold text-white truncate" x-text="f.name"></p>
                                            <p class="text-[11px] font-bold text-emerald-400 tabular-nums mt-0.5" x-text="'Rs. ' + f.price"></p>
                                        </div>
                                    </div>
                                </template>
                                <template x-if="(viewingCenter?.foods || []).length === 0">
                                    <p class="text-xs text-zinc-500 col-span-3 py-2 italic">Is center ne koi food dish upload nahi ki.</p>
                                </template>
                            </div>
                        </div>
                    </div>

                </div>

            </div>

            <!-- =============================================================== -->
            <!-- TAB 3: GLOBAL ORDERS HUB -->
            <!-- =============================================================== -->
            <div x-show="activeTab === 'all-orders'" class="space-y-3">
                <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
                    <div>
                        <h3 class="text-xs font-bold text-white flex items-center gap-1.5">
                            <i data-lucide="shopping-bag" class="w-4 h-4 text-[#FF9500]"></i>
                            <span>All Platform Orders Hub</span>
                        </h3>
                        <p class="text-[11px] text-zinc-400">Filter orders by Pakwan Center, order type, or lifecycle status</p>
                    </div>

                    <div class="flex flex-wrap items-center gap-1.5">
                        <select x-model="selectedSubAdminFilter" class="px-2.5 py-1 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                            <option value="All">All Pakwan Centers</option>
                            <template x-for="sa in subAdmins" :key="sa.id">
                                <option :value="sa.id" x-text="sa.businessName"></option>
                            </template>
                        </select>

                        <select x-model="selectedOrderTypeFilter" class="px-2.5 py-1 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                            <option value="All">All Types (Pakwan & Food)</option>
                            <option value="pakwan">👑 Shahi Daigs Only</option>
                            <option value="restaurant">🍽️ Restaurant Dishes Only</option>
                        </select>

                        <select x-model="selectedOrderStatusFilter" class="px-2.5 py-1 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                            <option value="All">All Statuses</option>
                            <option value="Accepted">Accepted</option>
                            <option value="Preparing">Preparing</option>
                            <option value="On the Way">On the Way</option>
                            <option value="Delivered">Delivered</option>
                            <option value="Cancelled">Cancelled</option>
                        </select>
                    </div>
                </div>

                <!-- Orders Table -->
                <div class="cupertino-card rounded-2xl overflow-hidden shadow-sm">
                    <div class="overflow-x-auto">
                        <table class="w-full text-left text-xs">
                            <thead class="bg-zinc-950/60 text-zinc-400 uppercase font-semibold text-[9.5px] border-b border-white/5">
                                <tr>
                                    <th class="py-2.5 px-3">Order ID & Date</th>
                                    <th class="py-2.5 px-3">Pakwan Center</th>
                                    <th class="py-2.5 px-3">Type</th>
                                    <th class="py-2.5 px-3">Customer Details</th>
                                    <th class="py-2.5 px-3">Items</th>
                                    <th class="py-2.5 px-3">Amount</th>
                                    <th class="py-2.5 px-3">Assigned Rider</th>
                                    <th class="py-2.5 px-3">Status</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-white/5 font-medium text-zinc-300">
                                <template x-for="o in filteredOrdersList" :key="o.id">
                                    <tr class="hover:bg-zinc-800/30 transition-colors">
                                        <td class="py-2.5 px-3">
                                            <div class="font-mono font-bold text-[#FF9500]" x-text="o.id"></div>
                                            <div class="text-[9.5px] text-zinc-500" x-text="formatDate(o.orderDate)"></div>
                                        </td>
                                        <td class="py-2.5 px-3 font-semibold text-white" x-text="o.restaurantName"></td>
                                        <td class="py-2.5 px-3">
                                            <span class="px-2 py-0.5 rounded-full text-[9px] font-bold uppercase"
                                                :class="o.isDaigBooking ? 'bg-orange-500/20 text-[#FF9500] border border-orange-500/30' : 'bg-amber-500/20 text-amber-300 border border-amber-500/30'"
                                                x-text="o.isDaigBooking ? '👑 Daig' : '🍽️ Food'">
                                            </span>
                                        </td>
                                        <td class="py-2.5 px-3">
                                            <div class="font-bold text-white" x-text="o.customerName"></div>
                                            <div class="text-[10px] text-zinc-400 font-mono" x-text="o.customerPhone"></div>
                                        </td>
                                        <td class="py-2.5 px-3 text-zinc-300 truncate max-w-xs" x-text="(o.items || []).join(', ')"></td>
                                        <td class="py-2.5 px-3 font-bold text-white tabular-nums" x-text="'Rs. ' + o.totalAmount"></td>
                                        <td class="py-2.5 px-3 text-sky-400 font-medium" x-text="o.riderName || 'Unassigned'"></td>
                                        <td class="py-2.5 px-3">
                                            <span class="px-2 py-0.5 rounded-full text-[10px] font-bold"
                                                :class="getStatusBadgeClass(o.status)" x-text="o.status">
                                            </span>
                                        </td>
                                    </tr>
                                </template>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- =============================================================== -->
            <!-- TAB 4: DATABASE & SYSTEM SEEDING HUB -->
            <!-- =============================================================== -->
            <div x-show="activeTab === 'settings-db'" class="space-y-3">
                <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                    <div>
                        <h3 class="text-xs font-bold text-white flex items-center gap-1.5">
                            <i data-lucide="database" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                            <span>Database Seeding & Test Credentials Directory</span>
                        </h3>
                        <p class="text-[11px] text-zinc-400">Reset demo records, test rider logins, view all outlet users and clear passwords</p>
                    </div>

                    <button type="button" @click="seedDatabaseDemo()"
                        class="px-3 py-1.5 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-white rounded-xl text-xs font-semibold flex items-center gap-1.5 shadow-sm active:scale-95 transition-all">
                        <i data-lucide="refresh-cw" class="w-3 h-3"></i>
                        <span>Reset & Seed Demo Data</span>
                    </button>
                </div>

                <!-- Database Metrics -->
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-2">
                    <div class="p-2.5 rounded-2xl cupertino-card">
                        <p class="text-[10px] font-semibold uppercase text-zinc-400 tracking-wider">Database Engine</p>
                        <h4 class="text-sm font-bold text-white mt-0.5">SQLite 3 (WAL Mode)</h4>
                        <p class="text-[10px] text-[#FF9500]">Hostinger LiteSpeed Production</p>
                    </div>
                    <div class="p-2.5 rounded-2xl cupertino-card">
                        <p class="text-[10px] font-semibold uppercase text-zinc-400 tracking-wider">Database File</p>
                        <h4 class="text-sm font-bold text-white mt-0.5 font-mono">foodcourt.sqlite</h4>
                        <p class="text-[10px] text-zinc-400">Directory: php-backend/data/</p>
                    </div>
                    <div class="p-2.5 rounded-2xl cupertino-card flex items-center justify-between">
                        <div>
                            <p class="text-[10px] font-semibold uppercase text-zinc-400 tracking-wider">Backup Copy</p>
                            <p class="text-[11px] text-zinc-300">Download .sqlite</p>
                        </div>
                        <a href="../api/database/backup" download class="px-3 py-1 bg-zinc-800 hover:bg-zinc-700 text-zinc-100 rounded-xl text-xs font-semibold flex items-center gap-1 border border-white/10 transition-colors">
                            <i data-lucide="download" class="w-3 h-3 text-[#FF9500]"></i>
                            <span>Download</span>
                        </a>
                    </div>
                </div>

                <!-- Test Credentials Directory -->
                <div class="cupertino-card rounded-2xl p-3 space-y-2.5">
                    <div class="flex items-center justify-between border-b border-white/5 pb-2">
                        <div>
                            <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                <i data-lucide="key" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                <span>Platform Test Logins & Clear Passwords</span>
                            </h4>
                            <p class="text-[10.5px] text-zinc-400">All demo accounts across Super Admin, Pakwan Centers, Restaurants, and Riders</p>
                        </div>
                        <span class="px-2 py-0.5 bg-orange-500/10 border border-orange-500/25 text-[#FF9500] rounded-full text-[9.5px] font-semibold">
                            Default Testing Password: 123456
                        </span>
                    </div>

                    <div class="overflow-x-auto">
                        <table class="w-full text-left text-xs">
                            <thead class="bg-zinc-950/60 text-zinc-400 uppercase font-semibold text-[9.5px] border-b border-white/5">
                                <tr>
                                    <th class="py-2 px-2.5">Role</th>
                                    <th class="py-2 px-2.5">Name</th>
                                    <th class="py-2 px-2.5">Email (Username)</th>
                                    <th class="py-2 px-2.5">Password</th>
                                    <th class="py-2 px-2.5">Assigned Pakwan Center</th>
                                    <th class="py-2 px-2.5">Status</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-white/5 text-zinc-300">
                                <template x-for="u in allAccounts" :key="u.id">
                                    <tr class="hover:bg-zinc-800/30 transition-colors">
                                        <td class="py-2 px-2.5">
                                            <span class="px-1.5 py-0.5 rounded text-[9.5px] font-bold uppercase"
                                                :class="{
                                                    'bg-orange-500/20 text-[#FF9500] border border-orange-500/30': u.role === 'super_admin',
                                                    'bg-amber-500/20 text-amber-300 border border-amber-500/30': u.role === 'sub_admin',
                                                    'bg-sky-500/20 text-sky-300 border border-sky-500/30': u.role === 'rider',
                                                    'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30': u.role === 'client'
                                                }"
                                                x-text="u.role === 'sub_admin' ? (u.businessType === 'pakwan' ? 'Pakwan Admin' : (u.businessType === 'both' ? 'Pakwan + Rest' : 'Rest Admin')) : (u.role === 'super_admin' ? 'Super Admin 👑' : (u.role === 'rider' ? 'Rider 🛵' : 'Customer 👤'))">
                                            </span>
                                        </td>
                                        <td class="py-2 px-2.5 font-semibold text-white" x-text="u.name"></td>
                                        <td class="py-2 px-2.5 font-mono text-[#FF9500] select-all text-[11px]" x-text="u.email"></td>
                                        <td class="py-2 px-2.5 font-mono text-emerald-400 font-bold bg-zinc-950/40 rounded px-1.5 text-[11px]">123456</td>
                                        <td class="py-2 px-2.5 text-[11.5px] text-zinc-300" x-text="u.outlet_name || u.businessName || 'Platform General'"></td>
                                        <td class="py-2 px-2.5">
                                            <span class="px-1.5 py-0.5 rounded text-[9.5px] font-bold"
                                                :class="u.banned || u.status === 'banned' ? 'bg-red-500/20 text-red-400' : 'bg-emerald-500/20 text-emerald-400'"
                                                x-text="u.banned || u.status === 'banned' ? 'Suspended' : 'Active'">
                                            </span>
                                        </td>
                                    </tr>
                                </template>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- =============================================================== -->
            <!-- TAB 5: SUPER ADMIN PROFILE & SECURITY -->
            <!-- =============================================================== -->
            <div x-show="activeTab === 'profile'" class="space-y-3.5">
                
                <!-- Header Title & Subtitle -->
                <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-1 border-b border-white/5">
                    <div>
                        <h3 class="text-sm font-bold text-white flex items-center gap-2">
                            <i data-lucide="user-check" class="w-4 h-4 text-[#FF9500]"></i>
                            <span>Super Administrator Profile & Master Controls</span>
                        </h3>
                        <p class="text-[11px] text-zinc-400">Manage master administrator credentials, login email, password, and head office coordinates</p>
                    </div>

                    <div class="flex items-center gap-2">
                        <span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-orange-500/15 text-[#FF9500] border border-orange-500/30 flex items-center gap-1">
                            <span>👑</span>
                            <span>Super Master Account</span>
                        </span>
                    </div>
                </div>

                <div class="grid grid-cols-1 lg:grid-cols-12 gap-3.5">
                    
                    <!-- Left Column: Master Profile & Password (7 cols) -->
                    <div class="lg:col-span-7 space-y-3.5">
                        
                        <!-- Master Profile Details Card -->
                        <div class="p-4 rounded-2xl cupertino-card space-y-3">
                            <div class="flex items-center justify-between pb-2 border-b border-white/5">
                                <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                    <i data-lucide="shield" class="w-3.5 h-3.5 text-[#FF9500]"></i>
                                    <span>Master Account Information</span>
                                </h4>
                                <span class="text-[10px] text-zinc-500 font-mono">Role: super_admin</span>
                            </div>

                            <form @submit.prevent="saveSuperAdminProfile()" class="space-y-3">
                                <div>
                                    <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Super Admin Full Name</label>
                                    <input type="text" x-model="adminProfileForm.name" required placeholder="e.g. Super Controller"
                                        class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                </div>

                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                                    <div>
                                        <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Login Email Address</label>
                                        <input type="email" x-model="adminProfileForm.email" required placeholder="super@foodcourt.pk"
                                            class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white font-mono focus:outline-none focus:border-[#FF9500]">
                                    </div>
                                    <div>
                                        <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Contact Phone / WhatsApp</label>
                                        <input type="text" x-model="adminProfileForm.phone" placeholder="+92 300 8472910"
                                            class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                    </div>
                                </div>

                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                                    <div>
                                        <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Head Office City</label>
                                        <input type="text" x-model="adminProfileForm.city" placeholder="Lahore"
                                            class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                    </div>
                                    <div>
                                        <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Account Tier</label>
                                        <input type="text" value="Super Administrator (Root Access)" readonly
                                            class="w-full px-3 py-2 bg-zinc-950/60 border border-white/5 rounded-xl text-xs text-[#FF9500] font-semibold cursor-not-allowed">
                                    </div>
                                </div>

                                <div>
                                    <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Central Head Office Physical Address</label>
                                    <input type="text" x-model="adminProfileForm.address" placeholder="14-C Gulberg III, Main Boulevard, Lahore"
                                        class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                </div>

                                <div class="pt-2 flex justify-end">
                                    <button type="submit"
                                        class="px-5 py-2 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-black font-bold rounded-xl text-xs shadow-md transition-all active:scale-[0.98] flex items-center gap-1.5">
                                        <i data-lucide="check" class="w-3.5 h-3.5 text-black"></i>
                                        <span>Save Master Profile</span>
                                    </button>
                                </div>
                            </form>
                        </div>

                        <!-- Change Master Password Card -->
                        <div class="p-4 rounded-2xl cupertino-card space-y-3">
                            <div class="flex items-center justify-between pb-2 border-b border-white/5">
                                <h4 class="text-xs font-bold text-white flex items-center gap-1.5">
                                    <i data-lucide="key" class="w-3.5 h-3.5 text-amber-400"></i>
                                    <span>Update Master Password</span>
                                </h4>
                                <span class="text-[10px] text-zinc-400">Default: 123456</span>
                            </div>

                            <form @submit.prevent="updateSuperAdminPassword()" class="space-y-3">
                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                                    <div>
                                        <label class="block text-[11px] font-semibold text-zinc-300 mb-1">New Password</label>
                                        <input type="password" x-model="adminPasswordForm.newPassword" required placeholder="Minimum 5 characters"
                                            class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                    </div>
                                    <div>
                                        <label class="block text-[11px] font-semibold text-zinc-300 mb-1">Confirm New Password</label>
                                        <input type="password" x-model="adminPasswordForm.confirmPassword" required placeholder="Re-enter password"
                                            class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-[#FF9500]">
                                    </div>
                                </div>

                                <div class="pt-2 flex items-center justify-between">
                                    <p class="text-[10.5px] text-zinc-400">🔒 Password change will take effect across both web & mobile authentications.</p>
                                    <button type="submit"
                                        class="px-4 py-2 bg-zinc-800 hover:bg-zinc-700 text-white font-semibold rounded-xl text-xs border border-white/10 transition-all">
                                        Update Password
                                    </button>
                                </div>
                            </form>
                        </div>

                    </div>

                    <!-- Right Column: System Diagnostics & Head Office Oversight (5 cols) -->
                    <div class="lg:col-span-5 space-y-3.5">
                        
                        <!-- Head Office Helplines & Direct Links -->
                        <div class="p-4 rounded-2xl cupertino-card space-y-3">
                            <h4 class="text-xs font-bold text-white flex items-center gap-1.5 pb-2 border-b border-white/5">
                                <i data-lucide="building-2" class="w-3.5 h-3.5 text-blue-400"></i>
                                <span>Head Office Helplines & Links</span>
                            </h4>

                            <div class="space-y-2 text-xs">
                                <div class="p-2.5 rounded-xl bg-zinc-900/70 border border-white/5 flex items-center justify-between">
                                    <div>
                                        <span class="text-[10px] text-zinc-400 block">Support Phone Hotline</span>
                                        <span class="font-bold text-white text-xs">+92 300 8472910</span>
                                    </div>
                                    <a href="tel:+923008472910" class="px-2 py-1 bg-zinc-800 hover:bg-zinc-700 text-[#FF9500] rounded-lg text-[10.5px] font-bold">Call 📞</a>
                                </div>

                                <div class="p-2.5 rounded-xl bg-zinc-900/70 border border-white/5 flex items-center justify-between">
                                    <div>
                                        <span class="text-[10px] text-zinc-400 block">WhatsApp Emergency Line</span>
                                        <span class="font-bold text-white text-xs">+92 301 5556677</span>
                                    </div>
                                    <a href="https://wa.me/923015556677" target="_blank" class="px-2 py-1 bg-emerald-500/20 hover:bg-emerald-500/30 text-emerald-400 rounded-lg text-[10.5px] font-bold">Chat 💬</a>
                                </div>

                                <div class="p-2.5 rounded-xl bg-zinc-900/70 border border-white/5 flex items-center justify-between">
                                    <div>
                                        <span class="text-[10px] text-zinc-400 block">Vendor Sub-Admin Portal</span>
                                        <span class="font-bold text-white text-xs">https://food.aztemp.com/vendor/</span>
                                    </div>
                                    <a href="../vendor/login.php" target="_blank" class="px-2 py-1 bg-orange-500/20 hover:bg-orange-500/30 text-[#FF9500] rounded-lg text-[10.5px] font-bold">Open ↗</a>
                                </div>
                            </div>
                        </div>

                        <!-- System Diagnostics & Health Status -->
                        <div class="p-4 rounded-2xl cupertino-card space-y-3">
                            <h4 class="text-xs font-bold text-white flex items-center gap-1.5 pb-2 border-b border-white/5">
                                <i data-lucide="activity" class="w-3.5 h-3.5 text-emerald-400"></i>
                                <span>Platform System Diagnostics</span>
                            </h4>

                            <div class="space-y-1.5 text-xs">
                                <div class="flex items-center justify-between py-1 border-b border-white/5">
                                    <span class="text-zinc-400 text-[11px]">Database Engine</span>
                                    <span class="font-mono text-emerald-400 font-bold text-[11px]">SQLite 3 (WAL Mode Active)</span>
                                </div>

                                <div class="flex items-center justify-between py-1 border-b border-white/5">
                                    <span class="text-zinc-400 text-[11px]">Server Environment</span>
                                    <span class="text-zinc-200 font-semibold text-[11px]">Hostinger LiteSpeed / PHP 8.3</span>
                                </div>

                                <div class="flex items-center justify-between py-1 border-b border-white/5">
                                    <span class="text-zinc-400 text-[11px]">Registered Pakwan Outlets</span>
                                    <span class="font-bold text-[#FF9500] text-[11px]" x-text="subAdmins.length + ' Outlets'"></span>
                                </div>

                                <div class="flex items-center justify-between py-1 border-b border-white/5">
                                    <span class="text-zinc-400 text-[11px]">Global Orders Recorded</span>
                                    <span class="font-bold text-white text-[11px]" x-text="orders.length + ' Orders'"></span>
                                </div>

                                <div class="flex items-center justify-between py-1">
                                    <span class="text-zinc-400 text-[11px]">System Status</span>
                                    <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/15 text-emerald-400 border border-emerald-500/30">
                                        <span class="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
                                        <span>100% Operational</span>
                                    </span>
                                </div>
                            </div>
                        </div>

                    </div>

                </div>

            </div>

        </main>
    </div>

    <!-- ======================================================================= -->
    <!-- SLIDE-OVER SHEET: DIRECT NOTIFICATION TO PAKWAN CENTER (USER REQUIREMENT) -->
    <!-- Max width on mobile 90vw, top-right Cross (✕) button -->
    <!-- ======================================================================= -->
    <div x-show="modal.notifySheet" class="fixed inset-0 z-50 overflow-hidden" x-cloak>
        <!-- Backdrop -->
        <div x-show="modal.notifySheet" x-transition:enter="transition-opacity ease-linear duration-300" x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100" x-transition:leave="transition-opacity ease-linear duration-300" x-transition:leave-start="opacity-100" x-transition:leave-end="opacity-0"
            @click="modal.notifySheet = false" class="fixed inset-0 bg-black/75 backdrop-blur-md">
        </div>

        <div class="fixed inset-y-0 right-0 max-w-full flex pl-6">
            <div x-show="modal.notifySheet" x-transition:enter="transform transition ease-in-out duration-300" x-transition:enter-start="translate-x-full" x-transition:enter-end="translate-x-0" x-transition:leave="transform transition ease-in-out duration-300" x-transition:leave-start="translate-x-0" x-transition:leave-end="translate-x-full"
                class="w-[90vw] max-w-md sm:max-w-lg bg-zinc-950/95 border-l border-white/10 shadow-2xl p-5 flex flex-col justify-between overflow-y-auto">
                
                <div>
                    <!-- Sheet Header with Top-Right Cross Icon -->
                    <div class="flex items-center justify-between pb-3 border-b border-white/5">
                        <div class="flex items-center gap-2">
                            <div class="w-8 h-8 rounded-xl bg-orange-500/20 text-[#FF9500] flex items-center justify-center font-bold text-sm">
                                🔔
                            </div>
                            <div>
                                <h3 class="text-sm font-bold text-white">Send Direct Notification</h3>
                                <p class="text-[10px] text-zinc-400">Official announcement to Pakwan Center</p>
                            </div>
                        </div>
                        <!-- Cross Icon -->
                        <button type="button" @click="modal.notifySheet = false" class="p-1.5 text-zinc-400 hover:text-white hover:bg-zinc-800 rounded-xl transition-all" aria-label="Close notification sheet">
                            <i data-lucide="x" class="w-4 h-4"></i>
                        </button>
                    </div>

                    <!-- Target Center Info Capsule -->
                    <div class="mt-3.5 p-3 rounded-2xl bg-zinc-900/60 border border-white/5 space-y-1">
                        <div class="flex items-center justify-between">
                            <span class="text-[10px] font-semibold text-zinc-400 uppercase">Recipient:</span>
                            <span class="text-[9.5px] font-mono text-[#FF9500]" x-text="targetNotifyCenter?.id"></span>
                        </div>
                        <h4 class="text-xs font-bold text-white" x-text="targetNotifyCenter?.businessName || targetNotifyCenter?.name"></h4>
                        <p class="text-[10.5px] text-zinc-400">Manager: <strong class="text-zinc-200" x-text="targetNotifyCenter?.name"></strong> &bull; <span x-text="targetNotifyCenter?.phone"></span></p>
                    </div>

                    <!-- Form -->
                    <form @submit.prevent="submitSendNotification()" class="mt-4 space-y-3 text-xs">
                        <div>
                            <label for="notifTitle" class="block font-semibold text-zinc-300 mb-1">Notification Title</label>
                            <input id="notifTitle" type="text" x-model="newNotification.title" required placeholder="e.g. Urgent: Update Kitchen Daig Availability"
                                class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                        </div>

                        <div>
                            <label for="notifPriority" class="block font-semibold text-zinc-300 mb-1">Priority Level</label>
                            <select id="notifPriority" x-model="newNotification.priority" class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                                <option value="normal">Standard Announcement 📢</option>
                                <option value="important">Important Notification ⚠️</option>
                                <option value="urgent">Urgent / Action Required 🚨</option>
                            </select>
                        </div>

                        <div>
                            <label for="notifMessage" class="block font-semibold text-zinc-300 mb-1">Notification Message / Details</label>
                            <textarea id="notifMessage" rows="5" x-model="newNotification.message" required placeholder="Write the complete notification message or operational guidelines here..."
                                class="w-full px-3 py-2 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500] resize-none"></textarea>
                        </div>

                        <div class="p-2.5 rounded-xl bg-orange-500/10 border border-orange-500/20 text-[10.5px] text-orange-300">
                            💡 Ye notification is Pakwan Center ke Sub-Admin portal par turant deliver hogi aur unke dashboard par alert show hoga.
                        </div>

                        <div class="pt-2 flex justify-end gap-2">
                            <button type="button" @click="modal.notifySheet = false" class="px-3.5 py-2 bg-zinc-800 text-zinc-300 rounded-xl text-xs font-semibold">Cancel</button>
                            <button type="submit" class="px-4 py-2 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-white font-bold rounded-xl text-xs shadow-md active:scale-95 transition-all">
                                <span>Send Notification 🚀</span>
                            </button>
                        </div>
                    </form>
                </div>

                <div class="pt-3 border-t border-white/5 text-center text-[10px] text-zinc-500">
                    FoodCourt Super Admin Notification System
                </div>
            </div>
        </div>
    </div>

    <!-- ======================================================================= -->
    <!-- MODAL: EDIT SUB-ADMIN / PAKWAN CENTER (USER REQUIREMENT) -->
    <!-- ======================================================================= -->
    <div x-show="modal.editSubAdmin" class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-black/75 backdrop-blur-md" style="overscroll-behavior: contain;" x-cloak>
        <div class="w-full max-w-md cupertino-glass rounded-[28px] p-5 shadow-2xl space-y-3 max-h-[90vh] overflow-y-auto" @click.outside="modal.editSubAdmin = false">
            <div class="w-10 h-1 rounded-full bg-zinc-700 mx-auto mb-2"></div>

            <div class="flex items-center justify-between pb-2 border-b border-white/5">
                <div class="flex items-center gap-2">
                    <i data-lucide="edit" class="w-4 h-4 text-sky-400"></i>
                    <h3 class="text-sm font-bold text-white">Edit Pakwan Center Profile</h3>
                </div>
                <button type="button" @click="modal.editSubAdmin = false" class="p-1 text-zinc-400 hover:text-white rounded-lg text-xs">✕</button>
            </div>

            <form @submit.prevent="submitEditSubAdmin()" class="space-y-2.5 text-xs">
                <div>
                    <label class="block font-semibold text-zinc-400 mb-1">Pakwan Center Name</label>
                    <input type="text" x-model="editingSubAdmin.businessName" required class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                </div>

                <div class="grid grid-cols-2 gap-2">
                    <div>
                        <label class="block font-semibold text-zinc-400 mb-1">Manager Name</label>
                        <input type="text" x-model="editingSubAdmin.name" required class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                    </div>
                    <div>
                        <label class="block font-semibold text-zinc-400 mb-1">Category / Type</label>
                        <select x-model="editingSubAdmin.businessType" class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                            <option value="pakwan">👑 Shahi Pakwan Center</option>
                            <option value="both">👑🍽️ Pakwan + Restaurant</option>
                            <option value="restaurant">🍽️ Restaurant Type</option>
                        </select>
                    </div>
                </div>

                <div class="grid grid-cols-2 gap-2">
                    <div>
                        <label class="block font-semibold text-zinc-400 mb-1">Phone Number</label>
                        <input type="tel" x-model="editingSubAdmin.phone" required class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                    </div>
                    <div>
                        <label class="block font-semibold text-zinc-400 mb-1">City</label>
                        <input type="text" x-model="editingSubAdmin.city" class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                    </div>
                </div>

                <div>
                    <label class="block font-semibold text-zinc-400 mb-1">Kitchen / Shop Address</label>
                    <input type="text" x-model="editingSubAdmin.address" class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                </div>

                <div>
                    <label class="block font-semibold text-zinc-400 mb-1">Reset Password (Optional)</label>
                    <input type="password" x-model="editingSubAdmin.newPassword" placeholder="Leave blank to keep current password"
                        class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                </div>

                <div class="pt-2 border-t border-white/5 flex justify-end gap-1.5">
                    <button type="button" @click="modal.editSubAdmin = false" class="px-3 py-1.5 bg-zinc-800 text-zinc-300 rounded-xl text-xs font-semibold">Cancel</button>
                    <button type="submit" class="px-4 py-1.5 bg-sky-500 hover:bg-sky-400 text-white font-bold rounded-xl text-xs shadow-sm">
                        <span>Save Changes</span>
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- ======================================================================= -->
    <!-- MODAL: DELETE CONFIRMATION DIALOG (USER REQUIREMENT) -->
    <!-- ======================================================================= -->
    <div x-show="modal.deleteConfirm" class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-black/80 backdrop-blur-md" style="overscroll-behavior: contain;" x-cloak>
        <div class="w-full max-w-sm cupertino-glass rounded-[28px] p-5 shadow-2xl space-y-3.5 text-center" @click.outside="modal.deleteConfirm = false">
            <div class="w-12 h-12 rounded-2xl bg-red-500/20 border border-red-500/40 text-red-400 flex items-center justify-center text-xl mx-auto shadow-inner">
                ⚠️
            </div>
            <div>
                <h3 class="text-sm font-bold text-white">Pakwan Center Delete Karein?</h3>
                <p class="text-xs text-zinc-400 mt-1">Kya aap waqayi <strong class="text-red-300" x-text="targetDeleteCenter?.businessName"></strong> ko delete karna chahte hain? Is se inka store aur account platform se remove ho jayega.</p>
            </div>
            <div class="pt-2 border-t border-white/5 flex justify-center gap-2">
                <button type="button" @click="modal.deleteConfirm = false" class="px-4 py-2 bg-zinc-800 text-zinc-300 rounded-xl text-xs font-semibold hover:bg-zinc-700 transition-colors">
                    Cancel
                </button>
                <button type="button" @click="executeDeleteSubAdmin()" class="px-4 py-2 bg-red-600 hover:bg-red-500 text-white font-bold rounded-xl text-xs shadow-md transition-colors">
                    Haan, Delete Karein
                </button>
            </div>
        </div>
    </div>

    <!-- ======================================================================= -->
    <!-- MODAL: CREATE NEW SUB-ADMIN -->
    <!-- ======================================================================= -->
    <div x-show="modal.createSubAdmin" class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-black/75 backdrop-blur-md" style="overscroll-behavior: contain;" x-cloak>
        <div class="w-full max-w-md cupertino-glass rounded-[28px] p-5 shadow-2xl space-y-3 max-h-[90vh] overflow-y-auto" @click.outside="modal.createSubAdmin = false">
            <div class="w-10 h-1 rounded-full bg-zinc-700 mx-auto mb-2"></div>

            <div class="flex items-center justify-between pb-2 border-b border-white/5">
                <div class="flex items-center gap-2">
                    <i data-lucide="store" class="w-4 h-4 text-[#FF9500]"></i>
                    <h3 class="text-sm font-bold text-white">Naya Pakwan Center Kholein</h3>
                </div>
                <button type="button" @click="modal.createSubAdmin = false" class="p-1 text-zinc-400 hover:text-white rounded-lg text-xs">✕</button>
            </div>

            <form @submit.prevent="submitCreateSubAdmin()" class="space-y-2.5 text-xs">
                <div>
                    <label class="block font-semibold text-zinc-400 mb-1">Pakwan Center Name</label>
                    <input type="text" x-model="newSubAdmin.businessName" required placeholder="e.g. Al-Madina Shahi Pakwan"
                        class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                </div>

                <div class="grid grid-cols-2 gap-2">
                    <div>
                        <label class="block font-semibold text-zinc-400 mb-1">Manager / Owner Name</label>
                        <input type="text" x-model="newSubAdmin.name" required placeholder="Chaudhry Tariq"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                    </div>
                    <div>
                        <label class="block font-semibold text-zinc-400 mb-1">Category / Type</label>
                        <select x-model="newSubAdmin.businessType" class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                            <option value="pakwan">👑 Shahi Pakwan Center</option>
                            <option value="both">👑🍽️ Pakwan + Restaurant</option>
                            <option value="restaurant">🍽️ Restaurant Type</option>
                        </select>
                    </div>
                </div>

                <div class="grid grid-cols-2 gap-2">
                    <div>
                        <label class="block font-semibold text-zinc-400 mb-1">Email (Login ID)</label>
                        <input type="email" x-model="newSubAdmin.email" required placeholder="manager@outlet.pk" autocomplete="username"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                    </div>
                    <div>
                        <label class="block font-semibold text-zinc-400 mb-1">Password</label>
                        <input type="password" x-model="newSubAdmin.password" required placeholder="123456" autocomplete="new-password"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                    </div>
                </div>

                <div class="grid grid-cols-2 gap-2">
                    <div>
                        <label class="block font-semibold text-zinc-400 mb-1">Phone Number</label>
                        <input type="tel" x-model="newSubAdmin.phone" required placeholder="+92 300 1234567"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                    </div>
                    <div>
                        <label class="block font-semibold text-zinc-400 mb-1">City</label>
                        <input type="text" x-model="newSubAdmin.city" placeholder="Lahore"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                    </div>
                </div>

                <div>
                    <label class="block font-semibold text-zinc-400 mb-1">Kitchen / Shop Address</label>
                    <input type="text" x-model="newSubAdmin.address" placeholder="Main Market, Gulberg III, Lahore"
                        class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                </div>

                <div class="pt-2 border-t border-white/5 flex justify-end gap-1.5">
                    <button type="button" @click="modal.createSubAdmin = false" class="px-3 py-1.5 bg-zinc-800 text-zinc-300 rounded-xl text-xs font-semibold">Cancel</button>
                    <button type="submit" class="px-4 py-1.5 bg-gradient-to-r from-amber-500 to-orange-500 text-white rounded-xl text-xs font-semibold shadow-sm">
                        <span>Save Pakwan Center</span>
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- ======================================================================= -->
    <!-- MODAL: REGISTER DEDICATED DELIVERY RIDER -->
    <!-- ======================================================================= -->
    <div x-show="modal.createRider" class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-black/75 backdrop-blur-md" style="overscroll-behavior: contain;" x-cloak>
        <div class="w-full max-w-md cupertino-glass rounded-[28px] p-5 shadow-2xl space-y-3 max-h-[90vh] overflow-y-auto" @click.outside="modal.createRider = false">
            <div class="w-10 h-1 rounded-full bg-zinc-700 mx-auto mb-2"></div>

            <div class="flex items-center justify-between pb-2 border-b border-white/5">
                <div class="flex items-center gap-2">
                    <div class="w-7 h-7 rounded-xl bg-sky-500/20 text-sky-400 flex items-center justify-center font-bold text-xs">
                        🛵
                    </div>
                    <div>
                        <h3 class="text-sm font-bold text-white">Naya Delivery Rider Register Karein</h3>
                        <p class="text-[10px] text-zinc-400">Pakwan Center ke liye dedicated rider banayein</p>
                    </div>
                </div>
                <button type="button" @click="modal.createRider = false" class="p-1 text-zinc-400 hover:text-white rounded-lg text-xs">✕</button>
            </div>

            <form @submit.prevent="submitCreateRider()" class="space-y-2.5 text-xs">
                <div>
                    <label class="block font-semibold text-zinc-400 mb-1">Assigned Pakwan Center</label>
                    <select x-model="newRider.assigned_sub_admin_id" required class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                        <template x-for="sa in subAdmins" :key="sa.id">
                            <option :value="sa.id" x-text="sa.businessName + ' (' + (sa.businessType === 'pakwan' ? 'Pakwan' : 'Restaurant') + ')'"></option>
                        </template>
                    </select>
                </div>

                <div>
                    <label class="block font-semibold text-zinc-400 mb-1">Rider Full Name</label>
                    <input type="text" x-model="newRider.name" required placeholder="e.g. Aslam Cheema"
                        class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                </div>

                <div class="grid grid-cols-2 gap-2">
                    <div>
                        <label class="block font-semibold text-zinc-400 mb-1">Email (Login ID)</label>
                        <input type="email" x-model="newRider.email" required placeholder="rider@foodcourt.pk" autocomplete="username"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                    </div>
                    <div>
                        <label class="block font-semibold text-zinc-400 mb-1">Password</label>
                        <input type="password" x-model="newRider.password" required placeholder="123456" autocomplete="new-password"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                    </div>
                </div>

                <div class="grid grid-cols-2 gap-2">
                    <div>
                        <label class="block font-semibold text-zinc-400 mb-1">Phone Number</label>
                        <input type="tel" x-model="newRider.phone" required placeholder="+92 301 7778899"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                    </div>
                    <div>
                        <label class="block font-semibold text-zinc-400 mb-1">City</label>
                        <input type="text" x-model="newRider.city" placeholder="Lahore"
                            class="w-full px-3 py-1.5 bg-zinc-900 border border-white/10 rounded-xl text-white text-xs focus:outline-none focus:border-[#FF9500]">
                    </div>
                </div>

                <div class="p-2 rounded-xl bg-orange-500/10 border border-orange-500/20 text-[10.5px] text-orange-300">
                    💡 Ye rider Pakwan Center ke orders pick kar ke Google Map se customer ki location tak navigate karega. Login password default <strong>123456</strong> hai.
                </div>

                <div class="pt-2 border-t border-white/5 flex justify-end gap-1.5">
                    <button type="button" @click="modal.createRider = false" class="px-3 py-1.5 bg-zinc-800 text-zinc-300 rounded-xl text-xs font-semibold">Cancel</button>
                    <button type="submit" class="px-4 py-1.5 bg-gradient-to-r from-sky-500 to-blue-600 text-white rounded-xl text-xs font-semibold shadow-sm">
                        <span>Save Delivery Rider</span>
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- ======================================================================= -->
    <!-- ALPINE CONTROLLER -->
    <!-- ======================================================================= -->
    <script>
        function superAdminApp() {
            return {
                activeTab: 'analytics',
                detailSubTab: 'orders',
                viewingCenter: null,
                loading: false,

                searchPakwanQuery: '',
                selectedSubAdminFilter: 'All',
                selectedOrderTypeFilter: 'All',
                selectedOrderStatusFilter: 'All',
                selectedBusinessTypeFilter: 'All',
                selectedVendorStatusFilter: 'all',
                datePresetFilter: 'all',
                filterDateFrom: '',
                filterDateTo: '',
                sortBy: 'newest',

                stats: null,
                subAdmins: [],
                orders: [],
                riders: [],
                allAccounts: [],
                desktopNotificationPermission: (typeof Notification !== 'undefined') ? Notification.permission : 'default',

                toast: { visible: false, message: '', type: 'success' },
                modal: { createSubAdmin: false, editSubAdmin: false, createRider: false, deleteConfirm: false, notifySheet: false },

                targetNotifyCenter: null,
                targetDeleteCenter: null,

                newNotification: {
                    title: '',
                    message: '',
                    priority: 'normal'
                },

                editingSubAdmin: {
                    id: '',
                    name: '',
                    businessName: '',
                    businessType: 'pakwan',
                    phone: '',
                    city: 'Lahore',
                    address: '',
                    newPassword: ''
                },

                newSubAdmin: {
                    name: '',
                    businessName: '',
                    businessType: 'pakwan',
                    email: '',
                    password: '123456',
                    phone: '',
                    city: 'Lahore',
                    address: ''
                },

                newRider: {
                    name: '',
                    email: '',
                    phone: '',
                    password: '123456',
                    city: 'Lahore',
                    assigned_sub_admin_id: '',
                    outlet_name: ''
                },

                tabs: [
                    { id: 'analytics', label: 'Platform Analytics', icon: 'line-chart' },
                    { id: 'pakwan-centers', label: 'Pakwan Centers', icon: 'soup' },
                    { id: 'all-orders', label: 'Global Orders Hub', icon: 'shopping-bag' },
                    { id: 'settings-db', label: 'Database & Seeding Hub', icon: 'database' },
                    { id: 'profile', label: 'Admin Profile', icon: 'user' }
                ],

                superProfile: <?= json_encode($superUser) ?>,
                adminProfileForm: {
                    name: <?= json_encode($superUser['name'] ?? 'Super Administrator') ?>,
                    email: <?= json_encode($superUser['email'] ?? 'super@foodcourt.pk') ?>,
                    phone: <?= json_encode($superUser['phone'] ?? '+92 300 8472910') ?>,
                    city: <?= json_encode($superUser['city'] ?? 'Lahore') ?>,
                    address: <?= json_encode($superUser['address'] ?? 'FoodCourt Central Headquarters, 14-C Gulberg III, Main Blvd, Lahore') ?>
                },
                adminPasswordForm: {
                    newPassword: '',
                    confirmPassword: ''
                },

                currentTabLabel() {
                    const t = this.tabs.find(x => x.id === this.activeTab);
                    return t ? t.label : 'Platform Analytics';
                },

                setTab(tabId) {
                    this.activeTab = tabId;
                    this.viewingCenter = null;
                    this.$nextTick(() => lucide.createIcons());
                },

                showToast(message, type = 'success') {
                    this.toast = { visible: true, message, type };
                    setTimeout(() => { this.toast.visible = false; }, 3400);
                },

                calculateShare(count, total) {
                    if (!total || total === 0) return 0;
                    return Math.round(((count || 0) / total) * 100);
                },

                getOutletRiders(outletId) {
                    return this.riders.filter(r => r.assigned_sub_admin_id === outletId);
                },

                get filteredPakwanCentersList() {
                    const q = (this.searchPakwanQuery || '').trim().toLowerCase();
                    const typeFilter = this.selectedBusinessTypeFilter;
                    const datePreset = this.datePresetFilter;
                    const fromDate = this.filterDateFrom ? new Date(this.filterDateFrom + 'T00:00:00') : null;
                    const toDate = this.filterDateTo ? new Date(this.filterDateTo + 'T23:59:59') : null;

                    const now = new Date();
                    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
                    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
                    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

                    return this.subAdmins.filter(s => {
                        // 0. Vendor Status Filter (All, Active, Banned)
                        if (this.selectedVendorStatusFilter === 'active' && s.banned) return false;
                        if (this.selectedVendorStatusFilter === 'banned' && !s.banned) return false;

                        // 1. Business Type Filter (All, Restaurant, Pakwan)
                        let matchType = true;
                        if (typeFilter === 'pakwan') {
                            matchType = (s.businessType === 'pakwan' || s.businessType === 'both');
                        } else if (typeFilter === 'restaurant') {
                            matchType = (s.businessType === 'restaurant' || s.businessType === 'both');
                        }

                        // 2. Date-wise Filter
                        let matchDate = true;
                        const createdDate = s.createdAt ? new Date(s.createdAt) : null;
                        if (createdDate && !isNaN(createdDate.getTime())) {
                            if (datePreset === 'today') {
                                matchDate = (createdDate >= startOfToday);
                            } else if (datePreset === 'week') {
                                matchDate = (createdDate >= sevenDaysAgo);
                            } else if (datePreset === 'month') {
                                matchDate = (createdDate >= thirtyDaysAgo);
                            } else if (datePreset === 'custom') {
                                if (fromDate && createdDate < fromDate) matchDate = false;
                                if (toDate && createdDate > toDate) matchDate = false;
                            }
                        }

                        // 3. Search Query Filter (Searches Name, Owner, Email, Phone, City, ID, Address, Created Date)
                        let matchQuery = true;
                        if (q) {
                            matchQuery = (s.businessName || '').toLowerCase().includes(q) ||
                                (s.name || '').toLowerCase().includes(q) ||
                                (s.email || '').toLowerCase().includes(q) ||
                                (s.phone || '').toLowerCase().includes(q) ||
                                (s.city || '').toLowerCase().includes(q) ||
                                (s.id || '').toLowerCase().includes(q) ||
                                (s.address || '').toLowerCase().includes(q) ||
                                (s.createdAt || '').toLowerCase().includes(q);
                        }

                        return matchType && matchDate && matchQuery;
                    }).sort((a, b) => {
                        if (this.sortBy === 'newest') {
                            return new Date(b.createdAt || 0) - new Date(a.createdAt || 0);
                        } else if (this.sortBy === 'oldest') {
                            return new Date(a.createdAt || 0) - new Date(b.createdAt || 0);
                        } else if (this.sortBy === 'sales') {
                            return Number(b.totalSales || 0) - Number(a.totalSales || 0);
                        } else if (this.sortBy === 'orders') {
                            return Number(b.totalOrders || 0) - Number(a.totalOrders || 0);
                        }
                        return 0;
                    });
                },

                formatDateShort(iso) {
                    if (!iso) return '—';
                    const d = new Date(iso);
                    if (isNaN(d.getTime())) return iso;
                    return d.toLocaleDateString([], { day: '2-digit', month: 'short', year: 'numeric' });
                },

                isNewJoiner(iso) {
                    if (!iso) return false;
                    const d = new Date(iso);
                    if (isNaN(d.getTime())) return false;
                    const sevenDaysAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
                    return d.getTime() >= sevenDaysAgo;
                },

                get filteredOrdersList() {
                    return this.orders.filter(o => {
                        const matchOutlet = (this.selectedSubAdminFilter === 'All' || o.sub_admin_id === this.selectedSubAdminFilter);
                        const matchStatus = (this.selectedOrderStatusFilter === 'All' || o.status === this.selectedOrderStatusFilter);
                        let matchType = true;
                        if (this.selectedOrderTypeFilter === 'pakwan') matchType = Boolean(o.isDaigBooking);
                        if (this.selectedOrderTypeFilter === 'restaurant') matchType = !o.isDaigBooking;
                        return matchOutlet && matchStatus && matchType;
                    });
                },

                async viewCenterDetails(sa) {
                    this.loading = true;
                    try {
                        const res = await fetch(`../api/sub-admins/${sa.id}/details`);
                        const data = await res.json();
                        if (data.success) {
                            this.viewingCenter = data.data;
                            this.detailSubTab = 'orders';
                            window.scrollTo({ top: 0, behavior: 'smooth' });
                        } else {
                            this.showToast(data.message || 'Details fetch nahi ho sakein', 'error');
                        }
                    } catch (e) {
                        this.showToast('Error: ' + e.message, 'error');
                    } finally {
                        this.loading = false;
                        this.$nextTick(() => lucide.createIcons());
                    }
                },

                openNotificationSheet(sa) {
                    this.targetNotifyCenter = sa;
                    this.newNotification = {
                        title: '',
                        message: '',
                        priority: 'normal'
                    };
                    this.modal.notifySheet = true;
                    this.$nextTick(() => lucide.createIcons());
                },

                async submitSendNotification() {
                    if (!this.targetNotifyCenter?.id) return;
                    try {
                        const res = await fetch(`../api/sub-admins/${this.targetNotifyCenter.id}/notify`, {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify(this.newNotification)
                        });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast(`🔔 Notification "${this.newNotification.title}" send ho gayi!`);
                            this.modal.notifySheet = false;
                        } else {
                            this.showToast(data.message || 'Notification send nahi ho saki', 'error');
                        }
                    } catch (e) {
                        this.showToast('Notification error: ' + e.message, 'error');
                    }
                },

                openEditSubAdminModal(sa) {
                    this.editingSubAdmin = {
                        id: sa.id,
                        name: sa.name,
                        businessName: sa.businessName || sa.name,
                        businessType: sa.businessType || 'pakwan',
                        phone: sa.phone || '',
                        city: sa.city || 'Lahore',
                        address: sa.address || '',
                        newPassword: ''
                    };
                    this.modal.editSubAdmin = true;
                    this.$nextTick(() => lucide.createIcons());
                },

                async submitEditSubAdmin() {
                    try {
                        const payload = {
                            name: this.editingSubAdmin.name,
                            businessName: this.editingSubAdmin.businessName,
                            businessType: this.editingSubAdmin.businessType,
                            phone: this.editingSubAdmin.phone,
                            city: this.editingSubAdmin.city,
                            address: this.editingSubAdmin.address
                        };
                        if (this.editingSubAdmin.newPassword) {
                            payload.password = this.editingSubAdmin.newPassword;
                        }

                        const res = await fetch(`../api/sub-admins/${this.editingSubAdmin.id}`, {
                            method: 'PUT',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify(payload)
                        });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast('✅ Pakwan Center profile update ho gayi!');
                            this.modal.editSubAdmin = false;
                            await this.refreshAll();
                            if (this.viewingCenter?.id === this.editingSubAdmin.id) {
                                await this.viewCenterDetails({ id: this.editingSubAdmin.id });
                            }
                        } else {
                            this.showToast(data.message || 'Update failed', 'error');
                        }
                    } catch (e) {
                        this.showToast('Error: ' + e.message, 'error');
                    }
                },

                confirmDeleteSubAdmin(sa) {
                    this.targetDeleteCenter = sa;
                    this.modal.deleteConfirm = true;
                },

                async executeDeleteSubAdmin() {
                    if (!this.targetDeleteCenter?.id) return;
                    try {
                        const res = await fetch(`../api/sub-admins/${this.targetDeleteCenter.id}`, {
                            method: 'DELETE'
                        });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast(`🗑️ ${this.targetDeleteCenter.businessName} delete ho gaya!`);
                            this.modal.deleteConfirm = false;
                            this.viewingCenter = null;
                            await this.refreshAll();
                        } else {
                            this.showToast(data.message || 'Delete nahi ho saka', 'error');
                        }
                    } catch (e) {
                        this.showToast('Delete error: ' + e.message, 'error');
                    }
                },

                playOrderChime() {
                    try {
                        const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
                        const osc = audioCtx.createOscillator();
                        const gain = audioCtx.createGain();
                        osc.connect(gain);
                        gain.connect(audioCtx.destination);
                        osc.type = 'triangle';
                        osc.frequency.setValueAtTime(659.25, audioCtx.currentTime);
                        osc.frequency.setValueAtTime(880, audioCtx.currentTime + 0.12);
                        osc.frequency.setValueAtTime(1318.51, audioCtx.currentTime + 0.24);
                        gain.gain.setValueAtTime(0.25, audioCtx.currentTime);
                        gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.7);
                        osc.start();
                        osc.stop(audioCtx.currentTime + 0.7);
                    } catch(e) {}
                },

                async requestDesktopNotificationPermission() {
                    if (!('Notification' in window)) {
                        this.showToast('Desktop notification is not supported in this browser.', 'warning');
                        return;
                    }
                    try {
                        const perm = await Notification.requestPermission();
                        this.desktopNotificationPermission = perm;
                        if (perm === 'granted') {
                            this.showToast('🔔 Super Admin Desktop Notifications Activated!');
                            this.sendDesktopNotification('FoodCourt Platform Notifications Active 🔔', 'You will receive immediate alerts for new orders placed across all Pakwan Centers.');
                        } else {
                            this.showToast('Notification permission: ' + perm, 'warning');
                        }
                    } catch(e) {
                        this.showToast('Notification permission error: ' + e.message, 'error');
                    }
                },

                sendDesktopNotification(title, body, tag = '') {
                    if (typeof Notification !== 'undefined' && Notification.permission === 'granted') {
                        try {
                            const notif = new Notification(title, {
                                body: body,
                                icon: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=128&q=80',
                                badge: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=64&q=80',
                                tag: tag || ('platform_order_' + Date.now())
                            });
                            notif.onclick = () => {
                                window.focus();
                                this.setTab('all-orders');
                            };
                        } catch(e) {
                            console.warn('[Notification] Super Admin Desktop notification error: ', e);
                        }
                    }
                },

                async initApp() {
                    await this.refreshAll();
                    this.$nextTick(() => lucide.createIcons());

                    if (typeof Notification !== 'undefined' && Notification.permission === 'default') {
                        setTimeout(() => {
                            this.requestDesktopNotificationPermission();
                        }, 2500);
                    }

                    setInterval(async () => {
                        const prevOrdersCount = this.orders.length;
                        await this.refreshAll(true);
                        if (this.orders.length > prevOrdersCount) {
                            this.playOrderChime();
                            const latest = this.orders[0];
                            const outlet = latest?.restaurantName || 'FoodCourt Central Kitchen';
                            const items = (latest?.items || []).join(', ') || 'Dishes';
                            this.showToast(`🔔 New Platform Order #${latest?.id || ''} at ${outlet} (Rs. ${latest?.totalAmount || 0})`, 'success');
                            this.sendDesktopNotification(
                                `🔔 New Order #${latest?.id || ''} placed at ${outlet}!`,
                                `${latest?.customerName || 'Customer'} ne order diya: ${items} • Total: Rs. ${latest?.totalAmount || 0}`
                            );
                        }
                    }, 10000);
                },

                async refreshAll(silent = false) {
                    if (!silent) this.loading = true;
                    try {
                        const [saRes, sRes, oRes, accRes, ridRes] = await Promise.all([
                            fetch('../api/sub-admins').then(r => r.json()),
                            fetch('../api/dashboard/stats').then(r => r.json()),
                            fetch('../api/orders').then(r => r.json()),
                            fetch('../api/database/accounts').then(r => r.json()).catch(() => ({ data: [] })),
                            fetch('../api/users?role=rider').then(r => r.json()).catch(() => ({ data: [] }))
                        ]);

                        if (saRes?.data) this.subAdmins = saRes.data;
                        if (sRes?.data) this.stats = sRes.data;
                        if (oRes?.data) this.orders = oRes.data;
                        if (accRes?.data) this.allAccounts = accRes.data;
                        if (ridRes?.data) this.riders = ridRes.data;
                    } catch (e) {
                        if (!silent) this.showToast('Failed to sync live data: ' + e.message, 'error');
                    } finally {
                        if (!silent) this.loading = false;
                        this.$nextTick(() => lucide.createIcons());
                    }
                },

                async seedDatabaseDemo() {
                    if (!confirm('Are you sure you want to reset & seed fresh demo records? This will seed 4 Pakwan Centers, 8 Dedicated Riders, 8 Customers, and Orders across all 5 lifecycle stages.')) return;
                    this.loading = true;
                    try {
                        const res = await fetch('../api/database/seed', { method: 'POST' });
                        const data = await res.json();
                        if (data.success) {
                            const s = data.summary || {};
                            this.showToast(`✅ Seeded: ${s.sub_admins || 4} Pakwan Centers, ${s.riders || 8} Riders, ${s.customers || 8} Customers, ${s.orders || 10} Orders!`);
                            await this.refreshAll();
                        } else {
                            this.showToast('Failed to seed: ' + data.message, 'error');
                        }
                    } catch (e) {
                        this.showToast('Seeding error: ' + e.message, 'error');
                    } finally {
                        this.loading = false;
                        this.$nextTick(() => lucide.createIcons());
                    }
                },

                totalSubAdminSales() {
                    return this.subAdmins.reduce((acc, curr) => acc + Number(curr.totalSales || 0), 0);
                },

                openCreateSubAdminModal() {
                    this.newSubAdmin = {
                        name: '',
                        businessName: '',
                        businessType: 'pakwan',
                        email: '',
                        password: '123456',
                        phone: '',
                        city: 'Lahore',
                        address: ''
                    };
                    this.modal.createSubAdmin = true;
                    this.$nextTick(() => lucide.createIcons());
                },

                async submitCreateSubAdmin() {
                    try {
                        const res = await fetch('../api/sub-admins', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify(this.newSubAdmin)
                        });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast('✅ Pakwan Center kamyabi se ban gaya!');
                            this.modal.createSubAdmin = false;
                            await this.refreshAll();
                        } else {
                            this.showToast(data.message || 'Pakwan Center nahi ban saka', 'error');
                        }
                    } catch (e) {
                        this.showToast('Error: ' + e.message, 'error');
                    }
                },

                openCreateRiderModal(outlet = null) {
                    const defaultOutlet = outlet || this.viewingCenter || this.subAdmins[0] || {};
                    this.newRider = {
                        name: '',
                        email: '',
                        phone: '',
                        password: '123456',
                        city: defaultOutlet.city || 'Lahore',
                        assigned_sub_admin_id: defaultOutlet.id || '',
                        outlet_name: defaultOutlet.businessName || defaultOutlet.name || ''
                    };
                    this.modal.createRider = true;
                    this.$nextTick(() => lucide.createIcons());
                },

                async submitCreateRider() {
                    try {
                        const outlet = this.subAdmins.find(s => s.id === this.newRider.assigned_sub_admin_id);
                        if (outlet) {
                            this.newRider.outlet_name = outlet.businessName || outlet.name;
                        }
                        const res = await fetch('../api/users', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                                ...this.newRider,
                                role: 'rider'
                            })
                        });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast('✅ Naya Delivery Rider kamyabi se register ho gaya!');
                            this.modal.createRider = false;
                            await this.refreshAll();
                            if (this.viewingCenter && this.viewingCenter.id === this.newRider.assigned_sub_admin_id) {
                                await this.viewCenterDetails({ id: this.viewingCenter.id });
                            }
                        } else {
                            this.showToast(data.message || 'Rider register nahi ho saka', 'error');
                        }
                    } catch (e) {
                        this.showToast('Error registering rider: ' + e.message, 'error');
                    }
                },

                async toggleBanSubAdmin(sa) {
                    if (!sa) return;
                    const isBanned = Boolean(sa.banned);
                    const name = sa.businessName || sa.name || 'Pakwan Center';
                    const confirmMsg = isBanned 
                        ? `Kya aap waqayi "${name}" ko UNBAN & ACTIVATE karna chahte hain?\n\n• Inka Sub-Admin portal login restore ho jayega.\n• Food Court customer app mein inka store active ho jayega.`
                        : `Kya aap waqayi "${name}" ko BAN & SUSPEND karna chahte hain?\n\n• Inka Sub-Admin portal login foran block ho jayega.\n• Customer app se inki items hide ho jayengi.\n• Active session expire ho jayega.`;
                    
                    if (!confirm(confirmMsg)) return;

                    try {
                        const res = await fetch(`../api/sub-admins/${sa.id}/ban`, {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ banned: !isBanned })
                        });
                        const data = await res.json();
                        if (data.success) {
                            const newStatusText = isBanned ? 'UNBANNED & ACTIVATED 🟢' : 'BANNED & SUSPENDED 🔴';
                            this.showToast(`✅ "${name}" has been ${newStatusText}!`);
                            await this.refreshAll();
                            if (this.viewingCenter && this.viewingCenter.id === sa.id) {
                                this.viewingCenter.banned = !isBanned;
                                this.viewingCenter.status = !isBanned ? 'banned' : 'active';
                            }
                        } else {
                            this.showToast(data.message || 'Action failed', 'error');
                        }
                    } catch (e) {
                        this.showToast('Action failed: ' + e.message, 'error');
                    }
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

                formatDate(iso) {
                    if (!iso) return '';
                    const d = new Date(iso);
                    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) + ' • ' + d.toLocaleDateString();
                },

                async saveSuperAdminProfile() {
                    try {
                        const res = await fetch('../api/admin/profile', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify(this.adminProfileForm)
                        });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast('✅ Super Admin profile updated successfully!');
                            this.superProfile = { ...this.superProfile, ...this.adminProfileForm };
                        } else {
                            this.showToast(data.message || 'Failed to update profile', 'error');
                        }
                    } catch(e) {
                        this.showToast('Save error: ' + e.message, 'error');
                    }
                },

                async updateSuperAdminPassword() {
                    if (this.adminPasswordForm.newPassword !== this.adminPasswordForm.confirmPassword) {
                        this.showToast('Passwords do not match!', 'error');
                        return;
                    }
                    if (this.adminPasswordForm.newPassword.length < 5) {
                        this.showToast('Password must be at least 5 characters', 'error');
                        return;
                    }
                    try {
                        const res = await fetch('../api/admin/profile', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                                ...this.adminProfileForm,
                                newPassword: this.adminPasswordForm.newPassword
                            })
                        });
                        const data = await res.json();
                        if (data.success) {
                            this.showToast('🔐 Master password updated successfully!');
                            this.adminPasswordForm.newPassword = '';
                            this.adminPasswordForm.confirmPassword = '';
                        } else {
                            this.showToast(data.message || 'Failed to update password', 'error');
                        }
                    } catch(e) {
                        this.showToast('Password error: ' + e.message, 'error');
                    }
                }
            }
        }
    </script>
</body>
</html>