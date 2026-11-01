<?php
// php-backend/download.php
// FoodCourt & Shahi Pakwan — Official Android App Download Portal

$apkPath = __DIR__ . '/uploads/foodcourt-app.apk';
$apkSize = file_exists($apkPath) ? round(filesize($apkPath) / (1024 * 1024), 1) . ' MB' : '58 MB';
$lastUpdated = file_exists($apkPath) ? date('F d, Y - h:i A', filemtime($apkPath)) : date('F d, Y');
?>
<!DOCTYPE html>
<html lang="en" class="h-full bg-slate-950 text-slate-100">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Download FoodCourt & Shahi Pakwan Android App</title>
    <meta name="description" content="Download the latest FoodCourt & Shahi Pakwan Mobile App APK for testing and deployment.">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['"Plus Jakarta Sans"', 'system-ui', 'sans-serif'],
                    },
                    colors: {
                        brand: {
                            50: '#fff7ed',
                            500: '#f97316',
                            600: '#ea580c',
                            700: '#c2410c',
                        }
                    }
                }
            }
        }
    </script>
</head>
<body class="min-h-full flex flex-col justify-between antialiased selection:bg-orange-500 selection:text-white bg-[radial-gradient(ellipse_80%_80%_at_50%_-20%,rgba(249,115,22,0.15),rgba(255,255,255,0))]">

    <!-- Top Navigation Bar -->
    <header class="border-b border-slate-800/80 bg-slate-950/80 backdrop-blur-md sticky top-0 z-50">
        <div class="max-w-5xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
            <div class="flex items-center space-x-3">
                <div class="w-10 h-10 rounded-xl bg-gradient-to-tr from-orange-600 to-amber-500 flex items-center justify-center shadow-lg shadow-orange-500/20 font-black text-white text-lg">
                    FC
                </div>
                <div>
                    <span class="font-extrabold text-slate-100 tracking-tight text-base sm:text-lg">FoodCourt & Pakwan</span>
                    <span class="hidden sm:inline-block ml-2 px-2 py-0.5 text-[10px] font-black rounded-full bg-orange-500/10 text-orange-400 border border-orange-500/20">TEST BUILD</span>
                </div>
            </div>
            <div class="flex items-center space-x-2">
                <a href="/vendor/login.php" class="text-xs font-semibold px-3 py-1.5 rounded-lg text-slate-300 hover:text-white hover:bg-slate-800 transition">Vendor Portal</a>
                <a href="/admin/login.php" class="text-xs font-semibold px-3 py-1.5 rounded-lg bg-slate-800 text-orange-400 border border-slate-700 hover:bg-slate-700 transition">Admin</a>
            </div>
        </div>
    </header>

    <!-- Main Content -->
    <main class="flex-1 max-w-4xl mx-auto px-4 sm:px-6 py-12 flex flex-col items-center text-center">
        
        <!-- Status Pill -->
        <div class="inline-flex items-center space-x-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-bold mb-6 animate-pulse">
            <span class="w-2 h-2 rounded-full bg-emerald-400"></span>
            <span>Latest Client Release Ready for Testing</span>
        </div>

        <!-- Heading -->
        <h1 class="text-3xl sm:text-5xl font-black tracking-tight text-slate-100 max-w-2xl mb-4 leading-tight">
            Download the <span class="bg-gradient-to-r from-orange-400 via-amber-400 to-yellow-300 bg-clip-text text-transparent">FoodCourt App</span>
        </h1>
        <p class="text-slate-400 text-sm sm:text-base max-w-xl mb-8 leading-relaxed">
            Multi-restaurant food delivery, authentic Shahi Daig catering, customer live order tracking, and rider navigation suite.
        </p>

        <!-- Download Card -->
        <div class="w-full max-w-md bg-gradient-to-b from-slate-900 to-slate-900/90 border border-slate-800 rounded-3xl p-6 sm:p-8 shadow-2xl shadow-orange-500/5 relative overflow-hidden mb-10">
            <div class="absolute -top-24 -right-24 w-48 h-48 bg-orange-500/10 rounded-full blur-3xl pointer-events-none"></div>
            
            <!-- App Icon & Meta -->
            <div class="flex items-center space-x-4 mb-6 text-left">
                <div class="w-16 h-16 rounded-2xl bg-gradient-to-tr from-orange-600 to-amber-500 flex items-center justify-center shadow-md font-black text-white text-2xl shrink-0">
                    🍱
                </div>
                <div>
                    <h3 class="font-extrabold text-lg text-white">foodcourt-app.apk</h3>
                    <p class="text-xs text-slate-400">Version 1.0.0 (Release Build)</p>
                    <div class="flex items-center space-x-2 mt-1">
                        <span class="text-[11px] font-semibold text-emerald-400 bg-emerald-950/60 border border-emerald-800/50 px-2 py-0.5 rounded">✓ Clean APK</span>
                        <span class="text-[11px] font-medium text-slate-400"><?= $apkSize ?></span>
                    </div>
                </div>
            </div>

            <!-- Primary Download Button -->
            <a href="/uploads/foodcourt-app.apk" download="foodcourt-app.apk" class="w-full inline-flex items-center justify-center space-x-3 bg-gradient-to-r from-orange-500 to-amber-500 hover:from-orange-600 hover:to-amber-600 text-white font-extrabold py-3.5 px-6 rounded-2xl shadow-lg shadow-orange-500/25 transition-all duration-200 transform active:scale-95 text-base mb-3">
                <svg class="w-5 h-5 fill-current" viewBox="0 0 24 24">
                    <path d="M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96zM17 13l-5 5-5-5h3V9h4v4h3z"/>
                </svg>
                <span>Download APK (<?= $apkSize ?>)</span>
            </a>

            <!-- Direct URL Link copy -->
            <div class="flex items-center space-x-2 bg-slate-950/70 border border-slate-800/80 rounded-xl px-3 py-2 text-xs">
                <input id="apkUrl" type="text" readonly value="https://food.aztemp.com/uploads/foodcourt-app.apk" class="bg-transparent flex-1 text-slate-400 outline-none select-all text-[11px] font-mono">
                <button onclick="navigator.clipboard.writeText(document.getElementById('apkUrl').value); alert('Direct APK link copied to clipboard!');" class="text-orange-400 hover:text-orange-300 font-bold px-2 py-0.5 rounded text-[11px]">
                    Copy Link
                </button>
            </div>

            <!-- Metadata specs -->
            <div class="mt-6 pt-6 border-t border-slate-800/80 grid grid-cols-2 gap-3 text-left text-xs">
                <div>
                    <span class="text-slate-500 block text-[10px] font-bold uppercase tracking-wider">Updated On</span>
                    <span class="text-slate-300 font-semibold text-[11px]"><?= $lastUpdated ?></span>
                </div>
                <div>
                    <span class="text-slate-500 block text-[10px] font-bold uppercase tracking-wider">Compatibility</span>
                    <span class="text-slate-300 font-semibold text-[11px]">Android 8.0+ (ARM64 & x86)</span>
                </div>
            </div>
        </div>

        <!-- Installation Instructions Step-by-Step -->
        <div class="w-full max-w-md text-left bg-slate-900/40 border border-slate-800/60 rounded-2xl p-5 mb-8">
            <h4 class="text-xs font-bold text-slate-300 uppercase tracking-wider mb-3 flex items-center space-x-2">
                <svg class="w-4 h-4 text-orange-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                <span>How to Install on Android</span>
            </h4>
            <ol class="space-y-2 text-xs text-slate-400 list-decimal list-inside leading-relaxed">
                <li>Tap <strong class="text-slate-200">Download APK</strong> above.</li>
                <li>When prompted with <em class="text-slate-300">"File might be harmful"</em>, tap <strong class="text-slate-200">Download anyway</strong>.</li>
                <li>Open the downloaded file and enable <strong class="text-slate-200">"Install from unknown sources"</strong> if prompted.</li>
                <li>Tap <strong class="text-slate-200">Install</strong> and enjoy testing the app!</li>
            </ol>
        </div>

    </main>

    <!-- Footer -->
    <footer class="border-t border-slate-800/80 bg-slate-950 py-6 text-center text-xs text-slate-500">
        <div class="max-w-5xl mx-auto px-4 flex flex-col sm:flex-row items-center justify-between gap-2">
            <span>© <?= date('Y') ?> FoodCourt & Shahi Pakwan. All rights reserved.</span>
            <div class="flex items-center space-x-4">
                <a href="/vendor/login.php" class="hover:text-slate-400">Vendor Login</a>
                <a href="/admin/login.php" class="hover:text-slate-400">Admin Portal</a>
                <a href="/api/" class="hover:text-slate-400">REST API</a>
            </div>
        </div>
    </footer>

</body>
</html>
