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
- **Order Alert Ringtone (Vendor Portal Audio Bell)**:
  - Whenever a new customer order is placed, the vendor dashboard starts a repetitive synthesized doorbell chime ("Ding-Dong!") and displays a pulsing top alert banner with order details.
  - Keeps ringing until the vendor mutes or acknowledges the order.
  - A test alert bell button is available in the top header.
- **WhatsApp Dispatch Alert (Direct Rider Details to Customer)**:
  - When the vendor assigns a dedicated rider to an order, a 1-click WhatsApp shortcut triggers with an auto-formatted message containing:
    - Customer Name & Order ID
    - Assigned Dedicated Rider Name & Contact Phone
    - Cash on Delivery (COD) Amount to pay
    - Delivery Address
  - Accessible directly upon rider assignment, in the orders tables, and inside the order details modal.

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

## 12. 🛒 Customer Cart & Guest Checkout Flow
- **Floating Action Button (FAB) on Home**:
  - Whenever the customer adds an item to cart, a prominent Floating Action Button appears at the bottom-right showing the item count badge and subtotal (`View Cart • Rs. X`).
  - Clicking the FAB directly takes the customer into the Cart screen.
- **Cart Categorization & Vendor Transparency**:
  - In the Cart page, every item displays its origin vendor name (e.g. *FoodCourt Central* or *Al-Madina Shahi Pakwan*) and its category badge (*🍽️ فوڈ ریسٹورنٹ* or *🍲 شاہی پکوان*).
  - Shows clear Cash on Delivery (COD) payment badge.
- **Guest Checkout Interception (Toast with Direct Login Button)**:
  - Guest users can freely browse categories, restaurants, and food items, and add items to cart without logging in.
  - When a Guest user clicks **"Send Order" / "Submit Order"**:
    - The action is intercepted with an immediate floating **Toast / SnackBar**.
    - Inside this Toast, a direct **"لاگ ان کریں (Login)"** text/action button is displayed with the message: *"پلیز لاگ ان فرسٹ ٹو سبمٹ ارڈر (Please login first to submit your order)"*.
    - Clicking the button directly opens the `AuthScreen`.
- **Auth Screen Tab Structure**:
  - Top tab switcher with two roles: **Customer (کسٹمر)** [left, default] and **Rider (رائیڈر)** [right].
  - **Customer**: Can freely log in or toggle to sign up to register a new account.
  - **Rider**: Strictly **Login only** (no sign up). Shows an informative notice that rider accounts are exclusively issued by their vendor.
- **Return to Cart & Cash on Delivery (COD)**:
  - Once logged in, the customer returns smoothly to the Cart with all items preserved and can complete checkout.
  - All orders are processed under **Cash on Delivery (COD)** payment mode.

---

## 13. 📋 Customer Orders Screen & Order Detail Hero Architecture
- **Orders Listing (`OrdersScreen`)**:
  - Displays all orders placed by the customer.
  - Each order card prominently labels whether it belongs to **"🍲 شاہی پکوان (Shahi Pakwan)"** or **"🍽️ فوڈ ریسٹورنٹ (Restaurant)"**.
  - Shows dish title, restaurant name, actual price, cut-off / original price (with discount badge), and live status badge.
- **Order Detail Page / Sheet**:
  - Tapping any order item opens a comprehensive **Order Details View**:
    1. **Hero Section**:
       - Prominent top Hero banner with vendor image.
       - Vendor / Outlet Name (e.g. *Al-Madina Shahi Pakwan* or *FoodCourt Central*).
       - Business Category badge (*شاہی پکوان* or *فوڈ ریسٹورنٹ*).
       - Physical Kitchen / Shop Location Address.
       - Active discounts / offers applied.
    2. **Rider Status Section**:
       - Assigned Rider Name and Contact Phone (with a one-tap phone call button).
       - Dedicated vehicle details (e.g. *Honda CG 125*).
       - Live delivery status badge (*Accepted*, *Preparing*, *Rider on the Way*, *Rider Arrived 📍*, *Delivered ✅*).
    3. **Food Items Section**:
       - Item thumbnail image, dish title, quantity, actual price, and cut-off price (original price with line-through).
       - Special cooking notes or occasion (for Daig catering).
    4. **Visual Timeline Stepper**:
       - 4-step progressive timeline:
         1. *Order Placed (آرڈر درج کر دیا گیا)*
         2. *Vendor Confirmed & Kitchen Preparing (وینڈر نے تصدیق کی اور تیاری شروع)*
         3. *Rider Dispatched & On the Way (رائیڈر آرڈر لے کر روانہ ہے)*
         4. *Delivered to Customer (کامیابی سے ڈیلیور ہو گیا)*
    5. **Bill & COD Information**:
       - Explicitly specifies **"Cash on Delivery (کیش آن ڈیلیوری - COD)"**.
       - Detailed breakdown of subtotal, delivery fee, and net payable amount.

---

## 14. 🛵 Dedicated Rider Flow & 4-Tab Dashboard Architecture
- **Rider Access**:
  - Rider accounts are created by vendors and distributed to riders.
  - Riders log into the mobile app via the Rider tab.
- **4 Mandatory Bottom Navigation Tabs**:
  1. **Tab 1: Analytics (`اینالیٹکس` / `Analytics`)**:
     - Key Metrics Grid: Total Assigned Orders, Completed Orders, In-Process Orders, Pending Orders, and Rejected/Cancelled Orders.
     - Total Cash Collected Card: Total COD amount collected by the rider.
     - Visual Chart: Interactive or visual bar chart showing weekly/daily order progression and delivery distribution.
     - Recent Assigned Order preview card with one-click jump to active deliveries.
  2. **Tab 2: Recent / Active Orders (`ریسنت آرڈرز` / `Recent Orders`)**:
     - List tiles of active orders assigned to the rider (Accepted, Preparing, On the Way, Arrived).
     - Each card displays Customer Name, Phone, Delivery Address, Vendor/Restaurant Name, **Cash on Delivery (COD)** badge, and Total Payable.
     - Tapping opens the Order Dispatch & Navigation Sheet:
       - Customer Info & One-Tap Direct Call Button (`tel:...`).
       - Restaurant / Vendor Info & Kitchen Location.
       - Ordered items list.
       - **"Ride by Google Map" (`Ride by Google Map` / `گوگل میپ پر لوکیشن کھولیں`)** Button: Launches native Google Maps turn-by-turn navigation directly to the customer's delivery destination without API costs.
       - Visual Timeline Stepper.
       - Rider Status Switcher Action Buttons:
         - *Mark In-Process / Picked Up*
         - *Mark Arrived (📍 At Doorstep)*
         - *Mark Delivered (✅ Handed over & COD cash received)*
         - *Reject / Cancel Order* (prompts for cancellation reason and notifies vendor/customer).
  3. **Tab 3: Completed Orders (`مکمل شدہ آرڈرز` / `Completed Orders`)**:
     - Top Summary Cards:
       - Total Completed Count & Total COD Delivered Cash (Rs.).
       - Total Rejected / Cancelled Count & Lost Amount (Rs.).
     - Complete list of Delivered and Rejected orders showing customer name, vendor name, time of delivery/rejection, and COD amount.
     - Tapping any tile opens full delivery receipt details.
  4. **Tab 4: Profile (`پروفائل` / `Profile`)**:
     - Rider identity card: Name, Phone, Email, Vehicle Type & Plate Number, Assigned Vendor/Kitchen Outlet.
     - Shift Toggle: Online / Offline status switch.
     - "Edit Profile" button to update Name, Phone, and Vehicle details.
     - Switch to Customer App / Logout buttons.

---

## 16. 🌟 Real-time Tracking & Event Scheduling Upgrades (2026)
- **Pakwan Event Date & Time Scheduling**:
  - When customer adds Shahi Pakwan (Daig) dishes or orders from Pakwan centers, Cart screen displays a dedicated **Delivery Schedule Card** (`تقریب کی تاریخ اور وقت`).
  - Allows selecting Date (`Today`, `Tomorrow (کل)`, or Custom Date via Calendar Picker), Time Slot (`Lunch 1:30 PM`, `2:00 PM (دوپہر ۲ بجے)`, `Dinner 8:30 PM`, or Custom Clock Picker), and Occasion (`Dawat`, `Niaz / Khatam`, `Walima`, `Party`).
  - Saved to SQLite DB (`orders.event_date` & `orders.event_time`), forwarded to Vendor & Rider portals, and included in WhatsApp dispatch alert.
- **Rider Direct Google Maps Button**:
  - In `rider_dashboard_screen.dart`, every order destination card features a prominent **"Open in Google Maps 🗺️"** button beside the customer's drop-off address.
  - Handled by `MapLauncherService.launchRiderNavigation`: automatically switches between precise GPS coordinates and street address strings so navigation never fails.
- **Auto-Refresh Order Status**:
  - `OrdersScreen` and `RiderDashboardScreen` automatically refresh order statuses in the background every 12-15 seconds via lightweight `ApiService.syncOrdersOnly()`.
  - When vendor or rider updates an order status, customer screen animates to the new status immediately without needing manual pull-to-refresh, triggering in-app notifications.

- **Item "Out of Stock" Switch**:
  - In Vendor Portal Dishes and Shahi Daigs tables, every food item has a 1-click **"In Stock / Out of Stock"** toggle switch with green/red status indicator.
  - When marked Out of Stock, the Flutter customer app displays a prominent `🔴 Out of Stock (ختم ہے)` badge over the image, disables the Add button (showing "SOLD OUT" / "Out of Stock"), blocks adding to cart with a warning snackbar, and blocks checkout if already in cart until removed.

---

## 17. 👑 Admin Portal: Commission, Vendor Payout & Sales Reports (2026)
- **Vendor Commission & Net Payout Management**:
  - In the Super Admin Portal (`php-backend/admin/index.php`), opening any Vendor Detail page features a dedicated **💰 Commission & Payout** sub-tab and metric cards.
  - Admins can set custom platform commission cuts (default 10%, fully configurable per vendor).
  - Displays Total Delivered Sales, Platform Commission Cut (Rs.), Net Vendor Payable Share (Rs.), Paid Settlements, and Outstanding Balance Due.
  - **Record Payout / Settlement**: Admin can mark vendor balance as paid with 1-click settlement recording.
- **1-Click Daily / Monthly Sales Report Downloads**:
  - Admin can export formatted reports instantly:
    - **📅 Today's Report (CSV)**: Delivered orders, customer details, gross amount, commission cut, and net vendor share for today.
    - **📆 This Month's Report (CSV)**: Complete monthly sales breakdown.
    - **📊 All-Time Ledger (CSV)**: Entire historical statement.
    - **🖨️ Printable PDF Statement**: Print-ready official accounting invoice with platform logo, date stamp, vendor details, and clean ledger table (`window.print()`).

---

## 15. 🚀 Mandatory Deployment Rules
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
