# 🚀 Automated Deployment & Verification System

This folder contains the complete, one-command automated deployment pipeline for **FoodCourt & Pakwan Center**.

---

## ⚡ Quick Start: One-Command Deployment

Run either of these commands from anywhere in the project root:

```bash
# Method 1: Direct script with custom commit message
./deploy/deploy.sh "Your update message here"

# Method 2: Via npm script
npm run deploy
```

---

## 🛠️ What Happens Automatically:
1. **Pre-flight Code Quality & Syntax Check**:
   - Runs `php -l` on every single PHP file in `php-backend/`.
   - Halts immediately if any fatal syntax error exists, preventing broken code from reaching production.
2. **Offline Package Rebuild**:
   - Re-generates `php-backend-deploy.zip` in root for 1-click manual upload fallback.
3. **Git Stage, Commit & Remote Push**:
   - Stages all modified files.
   - Commits with your message (or an auto-generated timestamp).
   - Pushes to GitHub `origin/main` (which triggers Hostinger Webhook / Git Auto-Deployment).
4. **Live Server Health Verification**:
   - Pings live endpoints (`https://food.aztemp.com/`, `/vendor/login.php`, `/admin/login.php`, `/api/`).
   - Checks HTTP status codes (200 / 302), server response times, and detects potential server glitches.
   - Prints a formatted colored summary with direct test links.

---

## 🔑 Optional Direct SSH / FTP Deployment
If you want files uploaded directly via SSH/rsync or FTP in addition to Git:
1. Copy `deploy/.env.deploy.example` to `deploy/.env.deploy`.
2. Fill in your Hostinger SSH details (Hostinger hPanel -> Advanced -> SSH Access).
3. The script will automatically detect and sync files via SSH/Rsync.
