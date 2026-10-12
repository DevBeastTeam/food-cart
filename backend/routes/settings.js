const express = require('express');
const router = express.Router();
const { getDb, saveDb } = require('../database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET /api/settings - Public & Admin
router.get('/', (req, res) => {
  const db = getDb();
  res.json({ success: true, data: db.settings });
});

// PUT /api/settings - Admin only
router.put('/', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  db.settings = {
    ...db.settings,
    ...req.body
  };
  saveDb();
  res.json({ success: true, message: 'Settings saved successfully', data: db.settings });
});

// PATCH /api/settings/store-status - Toggle store open/closed
router.patch('/store-status', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  db.settings.storeOpen = req.body.storeOpen !== undefined ? Boolean(req.body.storeOpen) : !db.settings.storeOpen;
  saveDb();
  res.json({ success: true, message: `Store is now ${db.settings.storeOpen ? 'Open' : 'Closed'}`, storeOpen: db.settings.storeOpen });
});

// PATCH /api/settings/emergency-alert - Update alert
router.patch('/emergency-alert', authenticateToken, requireAdmin, (req, res) => {
  const { enabled, message, type } = req.body;
  const db = getDb();
  db.settings.emergencyAlert = {
    enabled: enabled !== undefined ? Boolean(enabled) : db.settings.emergencyAlert.enabled,
    message: message !== undefined ? String(message) : db.settings.emergencyAlert.message,
    type: type || db.settings.emergencyAlert.type || 'warning'
  };
  saveDb();
  res.json({ success: true, message: 'Emergency alert updated', emergencyAlert: db.settings.emergencyAlert });
});

module.exports = router;
