const express = require('express');
const router = express.Router();
const { getDb, saveDb } = require('../database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET /api/content - Public & Admin
router.get('/', (req, res) => {
  const db = getDb();
  res.json({ success: true, data: db.content });
});

// PUT /api/content - Admin only
router.put('/', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  db.content = {
    ...db.content,
    ...req.body
  };
  saveDb();
  res.json({ success: true, message: 'Content updated successfully', data: db.content });
});

// POST /api/content/addresses - Add delivery address
router.post('/addresses', authenticateToken, requireAdmin, (req, res) => {
  const { address } = req.body;
  if (!address || !address.trim()) {
    return res.status(400).json({ success: false, message: 'Address is required' });
  }

  const db = getDb();
  db.content.addresses.push(address.trim());
  saveDb();
  res.json({ success: true, message: 'Address added', data: db.content.addresses });
});

// DELETE /api/content/addresses/:index - Delete delivery address
router.delete('/addresses/:index', authenticateToken, requireAdmin, (req, res) => {
  const index = parseInt(req.params.index, 10);
  const db = getDb();

  if (isNaN(index) || index < 0 || index >= db.content.addresses.length) {
    return res.status(400).json({ success: false, message: 'Invalid address index' });
  }

  db.content.addresses.splice(index, 1);
  saveDb();
  res.json({ success: true, message: 'Address removed', data: db.content.addresses });
});

// PATCH /api/content/toggle-section - Toggle section visibility
router.patch('/toggle-section', authenticateToken, requireAdmin, (req, res) => {
  const { sectionKey, isVisible } = req.body;
  const db = getDb();

  if (!(sectionKey in db.content)) {
    return res.status(400).json({ success: false, message: 'Invalid section key' });
  }

  db.content[sectionKey] = isVisible !== undefined ? Boolean(isVisible) : !db.content[sectionKey];
  saveDb();
  res.json({
    success: true,
    message: `Section ${sectionKey} set to ${db.content[sectionKey]}`,
    sectionKey,
    isVisible: db.content[sectionKey]
  });
});

module.exports = router;
