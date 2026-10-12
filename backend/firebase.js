const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let firestore = null;
let isInitialized = false;

// Path to Service Account Key JSON
const SERVICE_ACCOUNT_PATH = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || path.join(__dirname, 'serviceAccountKey.json');

function initFirebase() {
  if (isInitialized) return firestore;

  try {
    if (fs.existsSync(SERVICE_ACCOUNT_PATH)) {
      const serviceAccount = require(SERVICE_ACCOUNT_PATH);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      firestore = admin.firestore();
      isInitialized = true;
      console.log('🔥 [Firebase] Successfully connected to Firebase Cloud Firestore!');
      return firestore;
    } else if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      firestore = admin.firestore();
      isInitialized = true;
      console.log('🔥 [Firebase] Connected to Firebase Firestore using env variable credentials!');
      return firestore;
    } else {
      console.log('ℹ️ [Firebase] serviceAccountKey.json not detected. Running with local storage fallback.');
      console.log('👉 To enable live Firebase cloud storage: place serviceAccountKey.json in the backend/ folder.');
      return null;
    }
  } catch (err) {
    console.error('⚠️ [Firebase] Failed to initialize Firebase:', err.message);
    return null;
  }
}

// Check connection status
function isFirebaseConnected() {
  return isInitialized && firestore !== null;
}

function getFirestore() {
  if (!isInitialized) {
    initFirebase();
  }
  return firestore;
}

// Sync specific collection/document to Firestore
async function syncDocToFirestore(collection, id, data) {
  const db = getFirestore();
  if (!db) return false;

  try {
    await db.collection(collection).doc(String(id)).set(data, { merge: true });
    return true;
  } catch (err) {
    console.error(`[Firebase] Error syncing ${collection}/${id}:`, err.message);
    return false;
  }
}

// Sync entire database collections to Firestore in background
async function syncAllToFirestore(fullDb) {
  const db = getFirestore();
  if (!db) return false;

  try {
    const batch = db.batch();

    // 1. Core single docs in 'app_config' collection
    if (fullDb.settings) {
      batch.set(db.collection('app_config').doc('settings'), fullDb.settings, { merge: true });
    }
    if (fullDb.content) {
      batch.set(db.collection('app_config').doc('content'), fullDb.content, { merge: true });
    }

    // 2. Orders collection
    if (Array.isArray(fullDb.orders)) {
      fullDb.orders.forEach(order => {
        if (order.id) {
          batch.set(db.collection('orders').doc(String(order.id)), order, { merge: true });
        }
      });
    }

    // 3. Restaurants collection
    if (Array.isArray(fullDb.restaurants)) {
      fullDb.restaurants.forEach(rest => {
        if (rest.id) {
          batch.set(db.collection('restaurants').doc(String(rest.id)), rest, { merge: true });
        }
      });
    }

    // 4. Food Items collection
    if (Array.isArray(fullDb.foodItems)) {
      fullDb.foodItems.forEach(item => {
        if (item.id) {
          batch.set(db.collection('food_items').doc(String(item.id)), item, { merge: true });
        }
      });
    }

    // 5. Daig Items collection
    if (Array.isArray(fullDb.daigItems)) {
      fullDb.daigItems.forEach(item => {
        if (item.id) {
          batch.set(db.collection('daig_items').doc(String(item.id)), item, { merge: true });
        }
      });
    }

    // 6. Banners & Deals
    if (Array.isArray(fullDb.banners)) {
      fullDb.banners.forEach(b => {
        if (b.id) {
          batch.set(db.collection('banners').doc(String(b.id)), b, { merge: true });
        }
      });
    }
    if (Array.isArray(fullDb.deals)) {
      fullDb.deals.forEach(d => {
        if (d.id) {
          batch.set(db.collection('deals').doc(String(d.id)), d, { merge: true });
        }
      });
    }

    await batch.commit();
    console.log('✅ [Firebase] All records synchronized to Cloud Firestore.');
    return true;
  } catch (err) {
    console.error('⚠️ [Firebase] Batch sync failed:', err.message);
    return false;
  }
}

// Load data from Firestore into local memory on boot
async function loadFromFirestore() {
  const db = getFirestore();
  if (!db) return null;

  try {
    const loaded = {};

    // Load app_config
    const settingsDoc = await db.collection('app_config').doc('settings').get();
    if (settingsDoc.exists) loaded.settings = settingsDoc.data();

    const contentDoc = await db.collection('app_config').doc('content').get();
    if (contentDoc.exists) loaded.content = contentDoc.data();

    // Load collections
    const ordersSnap = await db.collection('orders').get();
    if (!ordersSnap.empty) {
      loaded.orders = ordersSnap.docs.map(doc => doc.data());
    }

    const restSnap = await db.collection('restaurants').get();
    if (!restSnap.empty) {
      loaded.restaurants = restSnap.docs.map(doc => doc.data());
    }

    const foodSnap = await db.collection('food_items').get();
    if (!foodSnap.empty) {
      loaded.foodItems = foodSnap.docs.map(doc => doc.data());
    }

    const daigSnap = await db.collection('daig_items').get();
    if (!daigSnap.empty) {
      loaded.daigItems = daigSnap.docs.map(doc => doc.data());
    }

    const bannerSnap = await db.collection('banners').get();
    if (!bannerSnap.empty) {
      loaded.banners = bannerSnap.docs.map(doc => doc.data());
    }

    const dealsSnap = await db.collection('deals').get();
    if (!dealsSnap.empty) {
      loaded.deals = dealsSnap.docs.map(doc => doc.data());
    }

    return loaded;
  } catch (err) {
    console.error('⚠️ [Firebase] Could not fetch remote collections:', err.message);
    return null;
  }
}

// Initialize on require
initFirebase();

module.exports = {
  getFirestore,
  isFirebaseConnected,
  syncDocToFirestore,
  syncAllToFirestore,
  loadFromFirestore
};
