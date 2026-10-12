const express = require('express');
const router = express.Router();
const { getDb, saveDb } = require('../database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET /api/navigation - Public & Admin
router.get('/', (req, res) => {
  const db = getDb();
  const includeHidden = req.query.all === 'true';
  let nav = includeHidden ? db.navigation : db.navigation.filter(n => n.isVisible !== false);
  nav = [...nav].sort((a, b) => (a.order || 0) - (b.order || 0));
  res.json({ success: true, count: nav.length, data: nav });
});

// POST /api/navigation - Admin only
router.post('/', authenticateToken, requireAdmin, (req, res) => {
  const { label, icon, screen, order = 1, isVisible = true } = req.body;
  if (!label) {
    return res.status(400).json({ success: false, message: 'Label is required' });
  }

  const db = getDb();
  const newItem = {
    id: `nav_${Date.now()}`,
    label: label.trim(),
    icon: icon ? icon.trim() : 'explore',
    screen: screen ? screen.trim() : 'custom',
    order: Number(order) || db.navigation.length + 1,
    isVisible: Boolean(isVisible)
  };

  db.navigation.push(newItem);
  saveDb();
  res.status(201).json({ success: true, message: 'Nav item created', data: newItem });
});

// PUT /api/navigation/:id - Admin only
router.put('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.navigation.findIndex(n => n.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Nav item not found' });
  }

  const existing = db.navigation[index];
  const updated = {
    ...existing,
    ...req.body,
    id: existing.id
  };

  db.navigation[index] = updated;
  saveDb();
  res.json({ success: true, message: 'Nav item updated', data: updated });
});

// PATCH /api/navigation/:id/visibility - Admin only
router.patch('/:id/visibility', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const item = db.navigation.find(n => n.id === req.params.id);
  if (!item) {
    return res.status(404).json({ success: false, message: 'Nav item not found' });
  }

  item.isVisible = req.body.isVisible !== undefined ? Boolean(req.body.isVisible) : !item.isVisible;
  saveDb();
  res.json({ success: true, message: `Nav item ${item.isVisible ? 'unhidden' : 'hidden'}`, isVisible: item.isVisible });
});

// DELETE /api/navigation/:id - Admin only
router.delete('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.navigation.findIndex(n => n.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Nav item not found' });
  }

  const deleted = db.navigation.splice(index, 1)[0];
  saveDb();
  res.json({ success: true, message: 'Nav item deleted', data: deleted });
});

module.exports = router;
