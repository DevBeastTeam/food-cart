# 📜 FoodCourt & Pakwan Multi-Vendor Architecture & Client Rules

This document specifies the complete functional architecture, workflows, operational rules, and client requirements for the FoodCourt & Pakwan platform. Any AI assistant or developer working on this codebase must strictly adhere to these rules.

---

## 1. 🌐 Core Tech Stack & Zero-Firebase Architecture
- **Mobile Application**: Flutter (Android/iOS).
- **Backend API & Portals**: Pure PHP (`php-backend/`) with SQLite 3 database (`php-backend/data/foodcourt.sqlite`).
- **Web Portals**:
  - Super Admin Portal: `https://food.aztemp.com/admin/` (`admin/index.php`, `admin/login.php`)
  - Vendor Portal: `https://food.aztemp.com/vendor/` (`vendor/index.php`, `vendor/login.php`)
  - Database Seeding Hub: `https://food.aztemp.com/seeding` (`seeding/index.php`, `seeding.php`)
  - REST API: `https://food.aztemp.com/api/` (`api/index.php`)
- **Strict Rule on Firebase**: **NO FIREBASE** is allowed in this project. All authentications, real-time syncs, notifications, and storage are served directly through the PHP REST backend (`ApiService`).

---

## 2. 👑 Super Admin Platform Control
- **Super Administrator**:
  - Master authority over the entire platform.
  - Can view all registered vendors, restaurant managers, and Pakwan centers.
  - Inspects full financial revenue, active orders, and vendor performance.
  - Can **approve, edit, or block/unblock (ban)** any vendor outlet (`POST /api/sub-admins/{id}/ban`). If banned, the vendor's portal login access is immediately revoked.

---

## 3. 🏪 Multi-Vendor Architecture & Business Types
- **Vendor Categories**:
  Vendors represent independent physical shops, kitchens, or outlets across different chauks, neighborhoods, and cities:
  1. **🍽️ Restaurant Only**: Fast food, biryanis, karahis, BBQ, platters, pizzas, burgers, desserts.
  2. **🍲 Shahi Pakwan Only**: Ceremonial catering daigs (12 KG / 6 KG wood-fire cauldrons, wedding & event catering).
  3. **👑 Both (Restaurant + Shahi Pakwan)**: An outlet operating both a dine-in/takeaway restaurant and a catering Pakwan center.
- **Vendor Onboarding & Account Registration**:
  When a vendor account is created (or registered), the system **mandatorily collects**:
  - **Vendor Manager Name** (e.g. *Haji Rashid Ahmad*)
  - **Shop / Business Name** (e.g. *Al-Madina Shahi Pakwan Center*)
  - **Business Type** (*Restaurant*, *Pakwan*, or *Both*)
  - **Physical Kitchen / Shop Location Address** (e.g. *Commercial Plaza 8, Johar Town, Lahore*)
  - **GPS Coordinates** (Latitude & Longitude for radius & distance calculation)
  - **Contact Phone & WhatsApp**
  - **Email & Password**

---

## 4. 🍱 Food Listings & Categorization (Restaurant vs Pakwan)
- **Partitioned Listings**:
  When a vendor uploads or manages items, they select whether the item is for:
  - **Restaurant Dishes** (Standard menu items, pricing per plate/serving, calories, spicy/prep tags)
  - **Shahi Pakwan (Degs)** (Full 12 KG / Half 6 KG pricing, servings weight, wood-fire notice, includes list)
- **Full CRUD & Live Preview**:
  Vendors can Create, Read, Update, and Delete both Restaurant dishes and Shahi daigs, toggle live in-stock availability, and view instant live previews.
- **Automatic Location & Shop Name Binding**:
  The vendor's registered shop name and physical kitchen location address are **automatically attached** to every food item and daig uploaded. Customers can always see exactly which physical kitchen prepares their food.
- **Customer Mobile App Presentation**:
  - Customer app features dedicated tabs: **🍽️ Restaurants (ریسٹورنٹ)** and **🍲 Shahi Pakwan (شاہی پکوان)**.
  - Items uploaded under Pakwan automatically appear under the Pakwan tab; restaurant items appear under the Restaurant tab.
  - When **"Location: All"** is selected: Items from all vendors across all locations are displayed with pagination.
  - When a **Specific Location / Vendor** is selected: Listings filter strictly to that specific vendor's dishes, daigs, and active promotions.

---

## 5. 🛵 Rider Account Creation & Assignment Flow (Client Golden Rule)
- **⚠️ STRICT RULE: Riders CANNOT register via the Mobile App**:
  - Riders do **NOT** have a Sign-Up option in the mobile application.
  - A Rider account is created **EXCLUSIVELY by the Vendor** inside the Vendor Portal (`/vendor`).
- **Vendor Creates & Issues Rider Accounts**:
  - The Vendor opens the "Riders Fleet" tab in their dashboard.
  - Vendor clicks "Add Dedicated Rider" and sets:
    - Rider Full Name (e.g. *Captain Bilal Khan*)
    - Phone Number
    - Login Email
    - Password
    - City & Service Area
  - The Vendor physically or digitally shares these login credentials with their hired rider.
- **Rider Login in App**:
  - The rider opens the FoodCourt mobile app, switches to the **Rider (رائیڈر)** tab, and **logs in directly** using the credentials given by their vendor.
- **Vendor Scoping & Privacy**:
  - Each vendor strictly manages **their own dedicated riders**.
  - A vendor can view, edit, and **block/unblock** their own riders.
  - Riders belong exclusively to the vendor who created them.

---

## 6. 📦 Orders Management & Dispatch Lifecycle
- **Incoming Orders Hub**:
  - A vendor receives orders placed by customers for their kitchen/outlet.
  - The order display shows:
    - Customer Name & ID
    - Contact Phone
    - Exact Delivery Address & GPS Coordinates
    - Items Ordered (with quantities, portion size, and special notes)
    - Total Order Amount & Payment Method
- **Vendor Assigns Dedicated Rider**:
  - The vendor inspects the order and opens the "Assign Rider" selector.
  - The selector lists only the vendor's own active dedicated riders.
  - The vendor selects the chosen rider and confirms assignment.
- **Order Lifecycle Stages**:
  Vendors update order progress through official stages:
  1. **Pending / New Order**: Incoming, awaiting kitchen acceptance.
  2. **Accepted / Processing**: Order acknowledged by vendor.
  3. **Preparing**: Chef/Ustaad cooking in kitchen or dum cauldrons.
  4. **On the Way**: Dispatched with assigned rider (rider name & phone attached).
  5. **Delivered / Completed**: Handed over to customer.
  6. **Cancelled / Rejected**: Vendor can reject with mandatory reason (e.g. *Out of delivery radius*, *Kitchen rush*, *Ingredients out of stock*).
- **Real-Time Customer Sync**:
  - Every status change updates live on the customer's mobile app (`OrdersScreen`).
  - Customer can see which stage their food is in, rider contact info, and kitchen dispatch address.

---

## 7. 🎁 Vendor Offers & Promotional Banners
- Vendors can create, edit, enable, or disable promotional offers from their portal.
- Active offers appear as an animated, collapsible promo strip on dish cards in the mobile app.
- Collapsed: Shows discount badge, promo title, and chevron.
- Expanded: Reveals full offer breakdown, percentage off, promo details, and voucher code.

---

## 8. 📄 Dual Top & Bottom Pagination
- Food item listings and Daig listings in the mobile app must provide page navigation controls at **both the TOP and the BOTTOM** of the list (`< Previous`, `Page X of Y`, `Next >`).

---

## 9. 🔍 Real-Time Live API Search with AppBar Toggle
- Top header provides a search icon button.
- Tap expands search input with real-time live API query (`/api/food-items?search=...` and `/api/daig-items?search=...`).
- Clear / Close (`X`) button resets query and collapses the search bar.

---

## 10. 🌱 Database Seeding & External Dataset (`/seeding`)
- **Dedicated Seeding Route**:
  - Accessible directly at `/seeding` (`https://food.aztemp.com/seeding`).
- **External Dataset Rule**:
  - The complete dummy seeding dataset is **ALWAYS kept externally outside the codebase** in the root directory (`seed_data.sql` and `seed_data.json`).
  - Stored outside so developers, QA testers, and administrators can customize, add, or alter dummy records from the outside without modifying PHP source code.
  - The `/seeding` route reads this external file and imports the entire dataset directly into SQLite3 (`data/foodcourt.sqlite`) in a safe transaction.

---

## 11. 🚀 Mandatory Deployment Rules
- **Automatic Deployment Command**:
  Whenever code changes are made:
  ```bash
  bash deploy/deploy.sh "Brief description of changes made"
  ```
- **Flutter APK Builds**:
  - Build command:
    ```bash
    flutter build apk --debug --android-skip-build-dependency-validation
    ```
  - APK URL: `https://food.aztemp.com/uploads/foodcourt-app.apk`
- **Communication Rule**:
  - **ALWAYS RESPOND IN ROMAN URDU** when communicating with the user.
