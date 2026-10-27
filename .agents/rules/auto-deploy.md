---
description: Auto Deployment Rule for FoodCourt & Pakwan Center
globs: *
---

# Auto Deployment Directive

Whenever code changes are made and deployment is requested (e.g., "deploy", "server per upload kro", "upload to server", "live kro"):

1. **Execute the unified deployment script**:
   ```bash
   bash deploy/deploy.sh "<concise commit message>"
   ```
2. **Review Terminal Output**:
   - Verify all 5 steps passed:
     - [1/5] PHP Syntax Validation
     - [2/5] Standalone Deployment Package (php-backend-deploy.zip)
     - [3/5] Git Remote Push (origin/main)
     - [4/5] Direct Server Sync
     - [5/5] Real-Time Live Health Checks
3. **Notify User**:
   - Confirm deployment status, provide commit reference, and give direct links to the live portals for immediate verification.
