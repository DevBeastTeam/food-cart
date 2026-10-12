# 🔥 Firebase Firestore Setup Guide (Food Court)

Aap ke Backend mein **Firebase Firestore** ka mukammal connector lag chuka hai. 

Jab tak aap Firebase key nahi lagatay, backend local fallback (`db.json`) par chalta rahega taake koi error na aaye. Jaisay hi aap Firebase key paste karein ge, **Mobile App aur React Admin Panel ka saara data automatic Firebase Cloud Firestore mein store hona shuru ho jaye ga!**

---

## 🚀 Sirf 3 Simple Steps mein Firebase Connect Karein:

### Step 1: Firebase Project aur Firestore Enable Karein
1. [Firebase Console](https://console.firebase.google.com/) par jayein aur **Add Project** par click karein (e.g. `food-court-delivery`).
2. Left menu mein **Build -> Firestore Database** par click karein aur **Create database** par click karein.
3. Location select karein aur **Start in test mode** select kar ke Done karein.

---

### Step 2: Service Account Key (JSON) Download Karein
1. Firebase Console ke top-left mein **Project Overview** ke sath **⚙️ Settings (Gear icon)** par click karein -> **Project settings**.
2. Top tabs mein **Service accounts** tab par click karein.
3. Node.js select rehne dein aur neeche button **"Generate new private key"** par click karein.
4. Ek JSON file download hogi.

---

### Step 3: File ko Rename aur Paste Karein
1. Download ki hui JSON file ka naam change kar ke **`serviceAccountKey.json`** rakh dein.
2. Is file ko `backend/` folder mein paste kar dein:
   ```
   e:\food delivery\backend\serviceAccountKey.json
   ```
3. Backend restart karein:
   ```powershell
   cd "e:\food delivery\backend"
   npm start
   ```

Aap ko terminal mein yeh message nazar aayega:
```
🔥 [Firebase] Successfully connected to Firebase Cloud Firestore!
🔥 [Firebase] Firestore empty or new. Pushing initial dataset to Cloud Firestore...
✅ [Firebase] All records synchronized to Cloud Firestore.
```

---

## 📦 Firestore Collections Structure:
Firebase console mein aap ko automatic yeh collections nazar aayen gi:
- `orders`: Mobile app se aane walay tamam orders (Live status, items, address, phone)
- `restaurants`: Tamam outlets aur pakwan centers
- `food_items`: Menu dishes
- `daig_items`: Shahi Daigs & Cauldrons
- `banners`: Promotional banners jo React panel se edit hotay hain
- `deals`: Active discount coupons & vouchers
- `app_config`:
  - `doc: settings`: App fee, minimum order, emergency weather alert
  - `doc: content`: Hero title, banner toggle, cuisines headings
