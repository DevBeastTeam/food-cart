# 📜 FoodCourt & Pakwan Multi-Vendor Architecture & Rules

This document specifies the complete functional architecture, workflows, operational rules, and development guidelines for the FoodCourt & Pakwan project. Any AI assistant or developer working on this codebase must strictly adhere to these rules.

---

## 1. 🌐 Core Tech Stack & Zero-Firebase Architecture
- **Mobile Application**: Flutter (Android/iOS).
- **Backend API & Portals**: Pure PHP (`php-backend/`) with SQLite database (`php-backend/data/foodcourt.sqlite`).
- **Web Portals**:
  - Admin Portal: `https://food.aztemp.com/admin/` (`admin/index.php`, `admin/login.php`)
  - Vendor Portal: `https://food.aztemp.com/vendor/` (`vendor/index.php`, `vendor/login.php`)
  - REST API: `https://food.aztemp.com/api/` (`api/index.php`)
- **Strict Rule on Firebase**: **NO FIREBASE** is allowed in this project. All authentications, real-time syncs, notifications, and storage are served directly through the PHP REST backend (`ApiService`).

---

## 2. 🏪 Multi-Branch Vendor Architecture & Entity Scoping
- **Multiple Physical Branches & Chauks**:
  - Vendors represent distinct physical outlets, restaurants, or Pakwan catering centers located at different chauks, neighborhoods, or cities.
- **Vendor Autonomy & Privacy**:
  - Each vendor strictly manages **their own assigned riders** and **their own customers**.
  - Vendors cannot access or modify riders or customer histories of other vendors.
- **Block & Unblock Authority**:
  - **Vendor Authority**:
    - A vendor can view, add, manage, and **block/unblock** their assigned delivery riders (`POST /api/users/{id}/ban`).
    - A vendor can view, manage, and **block/unblock** customers ordering from their outlet (`POST /api/vendor/customers/ban`).
  - **Super Admin Authority**:
    - Super Administrator has master control over the platform and can view, edit, approve, and **block/unblock vendors** (`POST /api/sub-admins/{id}/ban`).

---

## 3. 🍱 Food Listings & Categorization (Restaurant vs Pakwan)
- **Partitioned Listing Tabs**:
  - In the customer mobile application, listings are split into two primary category modes:
    1. **🍽️ Restaurant Dishes Tab**: Displays restaurant items, fast food, biryanis, karahis, BBQ, platters, and desserts.
    2. **🍲 Shahi Pakwan Tab**: Displays ceremonial Shahi Daigs (Full/Half/Medium sizes, wood-fire dum, kg weights, catering packages).
- **Location Filtering Matrix**:
  - When **"Location: All"** is selected at the top:
    - Displays food items / daigs from **all registered vendors across all cities & chauks**.
    - Top promo banner acts as an auto-scrolling carousel (5-8s interval) cycling through offers from all vendors.
  - When a **Specific Vendor / Location** is selected:
    - Filters both restaurant dishes and Shahi daigs strictly to **that specific vendor**.
    - Displays only that specific vendor's active promotional offer card.

---

## 4. 📄 Dual Top & Bottom Pagination
- **Mandatory Dual Pagination**:
  - Food item listings and Daig listings must provide page navigation controls at **both the TOP and the BOTTOM** of the list.
  - Controls include:
    - `< Previous Page` button
    - Current page badge: `Page X of Y` (with total item count)
    - `Next Page >` button
  - Top pagination allows fast switching without having to scroll to the bottom, while bottom pagination enables seamless continuation after browsing the page.

---

## 5. 🔍 Real-Time Live API Search with AppBar Toggle
- **AppBar Search Icon & Field**:
  - AppBar / Top Bar contains a dedicated search action button.
  - Tapping the search icon smoothly reveals an inline search input field.
  - Inside the search field, an active **Cross (X) button** clears the search query and closes/hides the search bar.
- **100% Live API Driven (Zero Hardcoded Data)**:
  - As the user types, real-time live search queries are sent to the PHP backend (`/api/food-items?search=...` and `/api/daig-items?search=...`).
  - No static or mock fallback overrides live API data. Everything syncs live with production database.

---

## 6. ℹ️ Item Detail Screen & Collapsible Vendor Offer Strip
- **Shop / Kitchen Location**:
  - Tapping any food dish or Shahi daig opens the comprehensive item detail view.
  - Displays the exact physical shop / kitchen location address with a map pin icon (e.g. *Main Boulevard, Gulberg III, Lahore*).
- **Collapsible Promo Offer Strip**:
  - If the item's vendor has an active promotional offer or banner:
    - A **collapsible offer strip** is rendered inside the item detail screen.
    - **Collapsed State**: A sleek, compact colored banner showing discount percentage tag (e.g. `🏷️ 40% OFF`) and offer title with an expand chevron (`Tap to view offer ▼`).
    - **Expanded State**: Clicking un-collapses the strip into full offer details with promo banner image, discount badge, eligible items/freebies, and terms.
- **Design Preservation**:
  - Retains all existing rich Cupertino and Material design styling, portion selectors, spice adjustments, and add-to-cart buttons.

---

## 7. 🔐 Guest Mode & Authentication Flow
- **Guest Browsing**:
  - Users can browse restaurants, food dishes, and shahi daigs without logging in.
  - Users can add items to cart and view/edit their cart (`CartScreen`).
- **Checkout Interception**:
  - Clicking "Submit Order" intercepts unauthenticated users with a dialog:
    `"Please login first to submit order"` (`پلیز لاگ ان فرسٹ ٹو سبمٹ ارڈر`).
- **Auth Screen**:
  - Two role tabs: **Customer (Left, Default)** and **Rider (Right)**.
  - Bottom toggle to switch between Login and Sign Up.

---

## 8. 🚀 Mandatory Deployment Rules
- **Automatic Deployment Command**:
  Whenever code changes are made to the PHP backend, admin, or vendor portal:
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
