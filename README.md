# FoodCourt & Shahi Pakwan — Full-Stack Food Delivery & Daig Catering Platform

A multi-tier food delivery, restaurant ordering, and Shahi Daig catering ecosystem consisting of a Flutter mobile application and a standalone PHP + SQLite 3 production backend deployed on Hostinger.

---

## 🌐 Live Production Endpoints

| Portal / Service | Production URL | Description |
| :--- | :--- | :--- |
| **Vendor Portal** | `https://food.aztemp.com/vendor/login.php` | Store Managers & Pakwan Centers management (Menu, Offers, Orders, Riders) |
| **Super Admin** | `https://food.aztemp.com/admin/login.php` | Central platform oversight, vendor blocking, sales metrics |
| **🌱 Seeding Hub** | `https://food.aztemp.com/seeding` | Dedicated SQLite3 Dummy Data Import & Snapshot Hub |
| **REST API** | `https://food.aztemp.com/api/` | Real-time JSON API for mobile application & portals |
| **Android APK** | `https://food.aztemp.com/uploads/foodcourt-app.apk` | Latest live debug APK build |

---

## 🌱 Database Seeding & External Dataset Architecture (`/seeding`)

### ⚠️ Crucial Architectural Rule:
> **The database dummy seeding data is ALWAYS stored externally outside the codebase in the root directory (`seed_data.sql` and `seed_data.json`).**

### Why is it kept outside?
1. **Zero Code Dependency**: Developers, QA testers, and administrators can customize, add, or alter dummy records (dishes, daigs, restaurants, customers, riders, categories) directly in `seed_data.sql` without touching any PHP backend code.
2. **One-Click Import**: When opening the **`/seeding`** route (`https://food.aztemp.com/seeding`), the system reads this external file and imports the complete dataset directly into SQLite 3 (`data/foodcourt.sqlite`) inside a safe database transaction.
3. **Live DB Snapshot / Export**: The `/seeding` dashboard also allows exporting current live database changes back into `seed_data.sql` and `seed_data.json` at any time so updates made via the web portals are permanently saved outside.

### How to use the Seeding Tool:
1. Navigate to: `https://food.aztemp.com/seeding` (or `http://localhost:5000/seeding`).
2. Click **"⚡ Import External seed_data.sql to Database"** to import all dummy tables and records into SQLite3.
3. Review the live record counts grid to verify updated rows across all tables.

---

## 🔑 Standard Demo Test Credentials (Password: `123456`)

| Role | Account Name | Login Email | Access Portal |
| :--- | :--- | :--- | :--- |
| **Super Admin** | Super Administrator (FoodCourt HQ) | `super@foodcourt.pk` | `/admin` |
| **Vendor (Restaurant)** | Bannu Beef Pulao & Nalli Nihari | `bannu.admin@foodcourt.pk` | `/vendor` |
| **Vendor (Pakwan)** | Shahi Pakwan Center | `shahi.pakwan@foodcourt.pk` | `/vendor` |
| **Vendor (Both)** | Dawat Khana Desi Heritage | `dawat.admin@foodcourt.pk` | `/vendor` |
| **Vendor (Pakwan)** | Madina Pakwan & Catering Service | `madina.pakwan@foodcourt.pk` | `/vendor` |
| **Rider Captain** | Captain Bilal Khan (Bannu Pulao) | `rider.bannu@foodcourt.pk` | Mobile App |
| **Rider Captain** | Captain Ali Raza (Shahi Pakwan) | `rider@foodcourt.pk` | Mobile App |
| **Customer** | Hassan Raza (DHA Lahore) | `client@foodcourt.pk` | Mobile App |
| **Customer** | Ayesha Khan (Gulberg Lahore) | `ayesha.client@foodcourt.pk` | Mobile App |

---

## 🚀 One-Command Deployment

Whenever local modifications are made to Flutter or PHP backend:
```bash
bash deploy/deploy.sh "Brief description of changes"
```
The automated script validates PHP syntax, re-bundles packages, pushes to Git, syncs via direct SSH/Rsync, flushes server OPcache, and runs live health checks.
