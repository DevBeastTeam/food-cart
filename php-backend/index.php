<?php
// php-backend/index.php
// Universal Router for Local PHP Built-in Server & Apache / Hostinger hPanel

$rawUri = $_SERVER['REQUEST_URI'] ?? '/';
$uri = parse_url($rawUri, PHP_URL_PATH);

// 1. Built-in PHP CLI Server static files check
if (php_sapi_name() === 'cli-server') {
    $targetFile = __DIR__ . $uri;
    if ($uri !== '/' && file_exists($targetFile) && !is_dir($targetFile)) {
        return false;
    }
}

// Static Image Uploads serving fallback
if (strpos($uri, '/uploads/') !== false) {
    $rel = substr($uri, strpos($uri, '/uploads/'));
    $targetFile = __DIR__ . $rel;
    if (file_exists($targetFile) && !is_dir($targetFile)) {
        $ext = strtolower(pathinfo($targetFile, PATHINFO_EXTENSION));
        $mimes = [
            'jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg',
            'png' => 'image/png', 'webp' => 'image/webp',
            'gif' => 'image/gif', 'svg' => 'image/svg+xml'
        ];
        header('Content-Type: ' . ($mimes[$ext] ?? 'application/octet-stream'));
        header('Content-Length: ' . filesize($targetFile));
        header('Cache-Control: public, max-age=86400');
        readfile($targetFile);
        exit;
    }
}

// 2. API Routes (/api/...)
if (strpos($uri, '/api') === 0 || strpos($uri, '/api') !== false) {
    require_once __DIR__ . '/api/index.php';
    exit;
}

// 3. Super Admin Routes (/admin, /admin/, /admin/login, etc.)
if (preg_match('#^/admin(/.*)?$#', $uri, $matches)) {
    $sub = trim($matches[1] ?? '', '/');
    if ($sub === '' || $sub === 'index.php') {
        require_once __DIR__ . '/admin/index.php';
        exit;
    } elseif ($sub === 'login' || $sub === 'login.php') {
        require_once __DIR__ . '/admin/login.php';
        exit;
    } elseif ($sub === 'logout' || $sub === 'logout.php') {
        require_once __DIR__ . '/admin/logout.php';
        exit;
    }
}

// 4. Sub-Admin & Vendor Routes (/vendor, /vendor/, /vendor/login, etc.)
if (preg_match('#^/vendor(/.*)?$#', $uri, $matches)) {
    $sub = trim($matches[1] ?? '', '/');
    if ($sub === '' || $sub === 'index.php') {
        require_once __DIR__ . '/vendor/index.php';
        exit;
    } elseif ($sub === 'login' || $sub === 'login.php') {
        require_once __DIR__ . '/vendor/login.php';
        exit;
    } elseif ($sub === 'logout' || $sub === 'logout.php') {
        require_once __DIR__ . '/vendor/logout.php';
        exit;
    }
}

// 5. Backward Compatibility: /super redirects to /admin
if (preg_match('#^/super(/.*)?$#', $uri, $matches)) {
    $sub = trim($matches[1] ?? '', '/');
    $target = '/admin/' . ($sub ? $sub : '');
    header('Location: ' . $target, true, 301);
    exit;
}

// 6. Root Base URL redirects to Vendor Login
if ($uri === '/' || $uri === '' || $uri === '/index.php') {
    header('Location: /vendor/login.php', true, 302);
    exit;
}

// 7. Portal Hub Fallback (if specifically requested via ?hub=1)
?>
<!DOCTYPE html>
<html lang="en" class="h-full bg-[#09090b] text-zinc-100 dark" style="color-scheme: dark;">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="theme-color" content="#09090b">
    <title>Food Court & Daig Catering — iOS Management Hub</title>
    <link rel="preconnect" href="https://cdn.tailwindcss.com">
    <link rel="preconnect" href="https://unpkg.com">
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
                            cardHover: '#27272a',
                            border: 'rgba(255, 255, 255, 0.08)',
                            separator: 'rgba(255, 255, 255, 0.06)'
                        }
                    },
                    fontFamily: {
                        sans: ['-apple-system', 'BlinkMacSystemFont', '"SF Pro Display"', '"SF Pro Text"', 'Helvetica Neue', 'sans-serif']
                    }
                }
            }
        }
    </script>
    <script src="https://unpkg.com/lucide@latest"></script>
    <style>
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
    </style>
</head>
<body class="h-full flex items-center justify-center p-3 sm:p-5 bg-[#09090b] text-zinc-100 relative overflow-hidden">
    <!-- Subtle Cupertino Orange Ambient Aura -->
    <div class="absolute -top-24 -right-24 w-80 h-80 bg-orange-500/15 rounded-full blur-[100px] pointer-events-none" aria-hidden="true"></div>
    <div class="absolute -bottom-24 -left-24 w-80 h-80 bg-orange-600/10 rounded-full blur-[100px] pointer-events-none" aria-hidden="true"></div>

    <main class="w-full max-w-xl cupertino-glass rounded-[28px] p-5 sm:p-6 shadow-2xl relative">
        <!-- Compact iOS Navigation Header -->
        <header class="text-center mb-5">
            <div class="inline-flex items-center justify-center w-12 h-12 rounded-2xl bg-orange-500/15 border border-orange-500/30 text-[#FF9500] mb-2.5 shadow-sm">
                <i data-lucide="utensils-crossed" class="w-6 h-6" aria-hidden="true"></i>
            </div>
            <h1 class="text-xl sm:text-2xl font-bold tracking-tight text-white text-balance">Food Court & Shahi Daig Hub</h1>
            <p class="text-[12px] text-zinc-400 mt-0.5">Cupertino Multi-Tier Administration & Live Dispatch</p>
        </header>

        <!-- Compact Inset Grouped Action Cards -->
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
            <!-- Super Admin Card (/admin) -->
            <a href="admin/login.php" class="p-4 rounded-2xl bg-zinc-900/70 border border-white/5 hover:border-orange-500/40 hover:bg-zinc-800/60 active:scale-[0.98] transition-all group flex flex-col justify-between shadow-sm">
                <div>
                    <div class="flex items-center justify-between mb-3">
                        <div class="w-9 h-9 rounded-xl bg-orange-500/15 text-[#FF9500] border border-orange-500/20 flex items-center justify-center group-hover:scale-105 transition-transform">
                            <i data-lucide="shield-check" class="w-4 h-4" aria-hidden="true"></i>
                        </div>
                        <span class="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-orange-500/15 text-[#FF9500] border border-orange-500/20">Control</span>
                    </div>
                    <h2 class="text-base font-bold text-white">Super Admin (/admin)</h2>
                    <p class="text-[11.5px] text-zinc-400 mt-1 line-clamp-2 leading-relaxed">Platform analytics, Pakwan Centers vendor management, bans, riders aur settings control karein.</p>
                </div>
                <div class="mt-3.5 pt-2.5 border-t border-white/5 text-[11.5px] font-semibold text-[#FF9500] flex items-center justify-between">
                    <span>Super Admin Login</span>
                    <i data-lucide="chevron-right" class="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" aria-hidden="true"></i>
                </div>
            </a>

            <!-- Sub Admin / Vendor Card (/vendor) -->
            <a href="vendor/login.php" class="p-4 rounded-2xl bg-zinc-900/70 border border-white/5 hover:border-orange-500/40 hover:bg-zinc-800/60 active:scale-[0.98] transition-all group flex flex-col justify-between shadow-sm">
                <div>
                    <div class="flex items-center justify-between mb-3">
                        <div class="w-9 h-9 rounded-xl bg-orange-500/15 text-[#FF9500] border border-orange-500/20 flex items-center justify-center group-hover:scale-105 transition-transform">
                            <i data-lucide="store" class="w-4 h-4" aria-hidden="true"></i>
                        </div>
                        <span class="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-orange-500/15 text-[#FF9500] border border-orange-500/20">Vendor</span>
                    </div>
                    <h2 class="text-base font-bold text-white">Sub-Admin Vendor (/vendor)</h2>
                    <p class="text-[11.5px] text-zinc-400 mt-1 line-clamp-2 leading-relaxed">Khane upload karein, pakwan daig manage karein aur orders dispatch karein.</p>
                </div>
                <div class="mt-3.5 pt-2.5 border-t border-white/5 text-[11.5px] font-semibold text-[#FF9500] flex items-center justify-between">
                    <span>Vendor Portal Login</span>
                    <i data-lucide="chevron-right" class="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" aria-hidden="true"></i>
                </div>
            </a>
        </div>

        <!-- Compact Bottom Inset Bar -->
        <footer class="mt-4 pt-3.5 border-t border-white/5 flex items-center justify-between text-[11px] text-zinc-500">
            <span class="flex items-center gap-1.5 font-medium">
                <span class="w-1.5 h-1.5 rounded-full bg-[#FF9500] animate-pulse"></span>
                <span>SQLite 3 &bull; Production LiteSpeed</span>
            </span>
            <a href="api/dashboard/stats" target="_blank" class="text-zinc-400 hover:text-[#FF9500] font-medium flex items-center gap-1 transition-colors">
                <span>Live REST API</span>
                <i data-lucide="external-link" class="w-3 h-3" aria-hidden="true"></i>
            </a>
        </footer>
    </main>

    <script>
        lucide.createIcons();
    </script>
</body>
</html>
