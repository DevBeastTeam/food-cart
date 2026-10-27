# 🤖 AI Assistant Rules & Instructions for FoodCourt & Pakwan Project

## 🚨 MANDATORY AUTOMATIC DEPLOYMENT INSTRUCTION

Whenever you (the AI assistant) make local code changes (frontend Flutter, PHP backend, or admin/vendor portals) and:
1. The user mentions words like **"deploy"**, **"server per upload kro"**, **"upload to server"**, **"live kro"**, **"push"**, OR
2. You complete a requested task and need to sync to production:

### 👉 YOU MUST RUN THIS SINGLE COMMAND:
```bash
bash deploy/deploy.sh "Brief description of changes made"
```

### ⚡ What this command handles automatically:
1. **PHP Syntax Validation**: Runs `php -l` on all PHP files to guarantee zero fatal syntax errors.
2. **Offline Package**: Rebuilds `php-backend-deploy.zip` in root for 1-click fallback.
3. **Git Stage & Commit**: Commits all modified files with your concise description.
4. **Git Push**: Pushes to `origin/main` which triggers Hostinger / GitHub Webhook auto-deployment.
5. **Direct Sync (Optional)**: If `deploy/.env.deploy` is configured with SSH or FTP, it syncs files directly.
6. **Live Health Checks**: Tests live endpoints (`https://food.aztemp.com/`, `/vendor/login.php`, `/admin/login.php`, `/api/`) and reports HTTP codes (200 / 302) and response times.

### 📋 Post-Deployment Response:
After running the command, check the terminal output and report the live status, health verification, and clickable test URLs to the user:
- Vendor Portal: https://food.aztemp.com/vendor/login.php
- Admin Portal: https://food.aztemp.com/admin/login.php
- API Service: https://food.aztemp.com/api/
