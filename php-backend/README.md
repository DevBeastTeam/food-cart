# Food Court & Shahi Daig — PHP + SQLite 3 Multi-Tier Architecture

A complete, standalone, zero-external-database, zero-npm-build PHP + SQLite 3 solution designed specifically for **Hostinger hPanel**, cPanel, and standard PHP web hosting.

---

## 🏛️ Multi-Tier Architecture Overview

### 1. 👑 Super Admin Control Center (`/super`)
- **URL Path:** `https://yourdomain.com/super` (or `http://localhost:5000/super`)
- **Credentials:** `super@foodcourt.pk` / `123456`
- **Key Features:**
  - **Sub-Admin Oversight:** Real-time directory of all store vendors, restaurant managers & Pakwan centers.
  - **Full Store Profiles:** View store manager name, email, phone, business type (*Restaurant*, *Pakwan*, *Both*), and street address.
  - **Live Financial & Operational Metrics:** Real-time calculated store sales revenue, total orders, completed orders, uploaded dishes count, uploaded daigs count, and active riders count.
  - **Instant Ban / Unban Toggle:** One-click instant suspension. If banned, the Sub-Admin's login access to `/admin` is immediately blocked and active sessions are terminated.
  - **Store Inspector Modal:** Super Admin can inspect every dish, 12kg/6kg Daig, and order history uploaded by any Sub-Admin.
  - **Add New Sub-Admin:** Form to register new outlets with custom business type.

---

### 2. 🏪 Sub-Admin Store Portal (`/admin`)
- **URL Path:** `https://yourdomain.com/admin` (or `http://localhost:5000/admin`)
- **Demo Logins (Password: `123456`):**
  - **Restaurant Outlet:** `bannu.admin@foodcourt.pk` (*Bannu Beef Pulao & Nalli Nihari*)
  - **Pakwan Center:** `shahi.pakwan@foodcourt.pk` (*Shahi Pakwan Center*)
  - **Both (Rest + Pakwan):** `dawat.admin@foodcourt.pk` (*Dawat Khana Desi Heritage*)
- **Key Features:**
  - **Khana & Menu Upload:** Upload dishes with title, description, category, price, calories, popular highlight, and photo.
  - **👑 Shahi Daig Upload (Pakwan):** Upload 12 KG and 6 KG event cauldrons with Urdu title, full/half pricing, weight/servings, includes, and delivery notice.
  - **Live Orders Hub:** Real-time incoming kitchen queue with status lifecycle: *Accepted* &rarr; *Preparing* &rarr; *On the Way* &rarr; *Delivered*.
  - **Order Rejection with Reason:** Dedicated rejection modal prompting for rejection reasons (e.g. *Out of stock*, *Kitchen rush*, *Out of delivery radius*), sets status to *Cancelled* and stores the reason.
  - **Rider Assignment:** Assign available delivery captains with phone numbers to orders in 1-click.
  - **Offers & Deals:** Toggle store discounts on/off or generate custom voucher codes.
  - **Store Profile:** Edit address, contact numbers, and store timings.

---

### 3. 📱 Mobile App (Flutter) Alignment
- **Customer Role:** Two primary tabs:
  - **Pakwan Centers:** Shows ceremonial 12kg/6kg Daigs uploaded by Pakwan Sub-Admins.
  - **Restaurants:** Shows dining platters and dishes uploaded by Restaurant Sub-Admins.
- **Rider Role:** Active orders delivery dispatch and customer dropoff.

---

## 🚀 How to Deploy on Hostinger hPanel

### Step 1: Upload Files
1. Open **Hostinger hPanel** & go to **File Manager**.
2. Navigate to your website's **`public_html/`** folder.
3. Upload all contents of this `php-backend/` folder into `public_html/`:
   ```text
   public_html/
   ├── .htaccess
   ├── index.php
   ├── config/
   │   └── database.php
   ├── api/
   │   └── index.php
   ├── super/
   │   ├── index.php
   │   ├── login.php
   │   └── logout.php
   ├── admin/
   │   ├── index.php
   │   ├── login.php
   │   └── logout.php
   └── data/
       ├── .htaccess
       └── foodcourt.sqlite
   ```

### Step 2: Permissions Check
Ensure the `data/` folder has write permissions (`755` or `775`) so PHP can write to `foodcourt.sqlite`.

### Step 3: Access Portals
- Hub Landing Page: `https://yourdomain.com/`
- Super Admin: `https://yourdomain.com/super`
- Sub-Admin: `https://yourdomain.com/admin`
- REST API: `https://yourdomain.com/api/dashboard/stats`

---

## 💻 Local Testing
Run the built-in PHP server inside `php-backend`:
```bash
cd php-backend
php -S 127.0.0.1:5000 index.php
```
Open in browser:
- `http://localhost:5000/super` (Super Admin)
- `http://localhost:5000/admin` (Sub-Admin)
