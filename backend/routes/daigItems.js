const express = require('express');
const router = express.Router();
const { getDb, saveDb } = require('../database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET /api/daig-items - Public & Admin
router.get('/', (req, res) => {
  const db = getDb();
  const includeHidden = req.query.all === 'true';
  const list = includeHidden ? db.daigDishes : db.daigDishes.filter(d => d.isVisible !== false);
  res.json({ success: true, count: list.length, data: list });
});

// GET /api/daig-items/:id
router.get('/:id', (req, res) => {
  const db = getDb();
  const daig = db.daigDishes.find(d => d.id === req.params.id);
  if (!daig) {
    return res.status(404).json({ success: false, message: 'Daig item not found' });
  }
  res.json({ success: true, data: daig });
});

// POST /api/daig-items - Admin only
router.post('/', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const {
    name,
    urduName,
    description,
    category = 'Biryani & Pulao',
    fullDaigPrice,
    halfDaigPrice,
    fullDaigWeight = '12 KG (Serves 35-40 Persons)',
    halfDaigWeight = '6 KG (Serves 18-20 Persons)',
    imageUrl,
    rating = 4.9,
    badge = '👑 Special Deg',
    deliveryNotice = 'Order 3-4 hours in advance for fresh dum cooking',
    isVisible = true,
    includes = ['Atta-sealed Hot Daig', 'Zeera Raita Tub (2 Litre)', 'Fresh Salad']
  } = req.body;

  if (!name || fullDaigPrice === undefined || halfDaigPrice === undefined) {
    return res.status(400).json({ success: false, message: 'Name, fullDaigPrice, and halfDaigPrice are required' });
  }

  const newDaig = {
    id: `daig_${Date.now()}`,
    name: name.trim(),
    urduName: urduName ? urduName.trim() : '',
    description: description ? description.trim() : '',
    category: category.trim(),
    fullDaigPrice: Number(fullDaigPrice),
    halfDaigPrice: Number(halfDaigPrice),
    fullDaigWeight: fullDaigWeight.trim(),
    halfDaigWeight: halfDaigWeight.trim(),
    imageUrl: imageUrl || 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80',
    rating: Number(rating) || 4.9,
    badge: badge.trim(),
    deliveryNotice: deliveryNotice.trim(),
    isVisible: Boolean(isVisible),
    includes: Array.isArray(includes) ? includes : ['Atta-sealed Hot Daig', 'Raita Tub', 'Salad']
  };

  db.daigDishes.push(newDaig);
  saveDb();
  res.status(201).json({ success: true, message: 'Daig item created', data: newDaig });
});

// PUT /api/daig-items/:id - Admin only
router.put('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.daigDishes.findIndex(d => d.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Daig item not found' });
  }

  const existing = db.daigDishes[index];
  const updated = {
    ...existing,
    ...req.body,
    id: existing.id
  };

  db.daigDishes[index] = updated;
  saveDb();
  res.json({ success: true, message: 'Daig item updated', data: updated });
});

// PATCH /api/daig-items/:id/visibility - Admin only
router.patch('/:id/visibility', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const item = db.daigDishes.find(d => d.id === req.params.id);
  if (!item) {
    return res.status(404).json({ success: false, message: 'Daig item not found' });
  }

  item.isVisible = req.body.isVisible !== undefined ? Boolean(req.body.isVisible) : !item.isVisible;
  saveDb();
  res.json({ success: true, message: `Daig item ${item.isVisible ? 'unhidden' : 'hidden'}`, isVisible: item.isVisible });
});

// DELETE /api/daig-items/:id - Admin only
router.delete('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.daigDishes.findIndex(d => d.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Daig item not found' });
  }

  const deleted = db.daigDishes.splice(index, 1)[0];
  saveDb();
  res.json({ success: true, message: 'Daig item deleted', data: deleted });
});

module.exports = router;
