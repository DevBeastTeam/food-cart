# 📜 FoodCourt & Pakwan Multi-Vendor Architecture & Rules

This document specifies the complete functional architecture, workflows, operational rules, and development guidelines for the FoodCourt & Pakwan project. Any AI assistant or developer working on this codebase must strictly adhere to these rules.

---

## 1. 🌐 Core Tech Stack & Zero-Firebase Architecture
- **Mobile Application**: Flutter (Android/iOS).
- **Backend API & Portals**: Pure PHP (`php-backend/`) with SQLite database (`php-backend/database/foodcourt.db`).
- **Web Portals**:
  - Admin Portal: `https://food.aztemp.com/admin/` (`admin/index.php`, `admin/login.php`)
  - Vendor Portal: `https://food.aztemp.com/vendor/` (`vendor/index.php`, `vendor/login.php`)
  - REST API: `https://food.aztemp.com/api/` (`api/index.php`)
- **Strict Rule on Firebase**: **NO FIREBASE** is allowed in this project. All authentications, real-time syncs, notifications, and storage are served directly through the PHP REST backend (`ApiService`).

---

## 2. 🔐 Guest Mode & Authentication Flow
- **Guest Browsing**:
  - Users can browse restaurants, food dishes, and shahi daigs without logging in.
  - Users can see full dish descriptions, ingredients, cut prices, and discounts.
  - Users can add items to cart and view/edit their cart (`CartScreen`).
- **Checkout Interception**:
  - When a guest clicks **"Submit Order" / Checkout**, the app must intercept with a dialog/popup:
    `"Please login first to submit order"` (`پلیز لاگ ان فرسٹ ٹو سبمٹ ارڈر`).
  - The dialog provides a direct action to redirect to the **Auth/Login Screen** (`AuthScreen`).
- **Auth Screen Specifications**:
  - Two role tabs at the top:
    - **Customer Tab** (Left side, default selected).
    - **Rider Tab** (Right side).
  - Both Customer and Rider sections support toggle between **Login** and **Sign Up**.
  - Once logged in, the user state is preserved and they can complete the order checkout.

---

## 3. 📍 Home Location Dropdown & Vendor Bottom Sheet
- **Header Dropdown**:
  - In `HomeScreen`, the top deliver-to header displays `Deliver to:` with `Location: All` by default.
  - Tapping this dropdown opens an animated Modal Bottom Sheet.
- **Bottom Sheet Features**:
  - **Search Bar**: Live search filter for restaurant/vendor names and addresses.
  - **Shimmer Loading**: Shimmer effect when loading/refreshing vendor lists.
  - **"All Locations" Option**: Displays all food items, daigs, and offers from all vendors across the platform.
  - **Vendor List Tiles**: Displays registered restaurants and pakwan centers with their name, type, and kitchen/outlet location address.
- **Location Filtering Behavior**:
  - When "All" is selected:
    - Food items from all vendors are displayed.
    - Shahi Daigs from all pakwan vendors are displayed.
    - The top Promo Offer card automatically cycles (auto-swiping carousel every 5-10 seconds) displaying active offers from all vendors.
  - When a specific vendor/location is selected:
    - Only that vendor's restaurant/pakwan dishes and daigs are displayed.
    - The top promo banner displays only that specific vendor's active offer.

---

## 4. 🏷️ Vendor Promo Offers System
- **Vendor Portal (`vendor/index.php`)**:
  - Each vendor can add and manage their own promo banners/offers:
    - **Offer Title** (e.g. "Special Weekend Deal", "Karahi Dhamaka")
    - **Discount Percentage (%)** (e.g. 20%, 40%)
    - **Subtitle / Included Items** (e.g. "Free Naan & Drink on orders above Rs. 1000")
    - **Banner Image**: File upload or Image URL.
    - Stored in SQLite `banners` table with `sub_admin_id` identifying the vendor.
- **Admin Portal (`admin/index.php`)**:
  - Master control to view, approve, edit, or remove promo offers of all vendors.
- **Mobile Display**:
  - Banners are fetched from `/api/index.php?endpoint=banners`.
  - Carousel auto-slides every 5-8 seconds when viewing "All".

---

## 5. 🍲 Food Items & Pakwan Daigs Specifications
- **Restaurant Dishes**:
  - Fields: Title, description, category, actual price, cut price (original price before discount), discount percentage, `showCutPrice` flag, image upload/URL, and `sub_admin_id`.
- **Pakwan Daigs**:
  - Specialized for large catering/daig orders (12kg, 10kg, etc.).
  - Includes daig weight variations, servicing count, spicy level, kitchen location address, cut prices, and meat selection.

---

## 6. 🚀 Mandatory Deployment Rules
- **Automatic Deployment Command**:
  Whenever code changes are made to the PHP backend, admin, or vendor portal:
  ```bash
  bash deploy/deploy.sh "Brief description of changes made"
  ```
- **Flutter APK Builds**:
  - APK build command:
    ```bash
    flutter build apk --debug --android-skip-build-dependency-validation
    ```
  - APK uploaded to server: `https://food.aztemp.com/uploads/foodcourt-app.apk`
- **Communication Rule**:
  - **ALWAYS RESPOND IN ROMAN URDU** when communicating with the user.
