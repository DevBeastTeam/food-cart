const express = require('express');
const router = express.Router();
const { getDb, saveDb } = require('../database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET /api/categories - Public & Admin
router.get('/', (req, res) => {
  const db = getDb();
  const includeHidden = req.query.all === 'true';
  let list = includeHidden ? db.categories : db.categories.filter(c => c.isVisible !== false);
  list = [...list].sort((a, b) => (a.order || 0) - (b.order || 0));
  res.json({ success: true, count: list.length, data: list });
});

// POST /api/categories - Admin only
router.post('/', authenticateToken, requireAdmin, (req, res) => {
  const { name, icon = '🍲', image, order } = req.body;
  if (!name) {
    return res.status(400).json({ success: false, message: 'Name is required' });
  }

  const db = getDb();
  const newCat = {
    id: `cat_${Date.now()}`,
    name: name.trim(),
    icon: icon.trim(),
    image: image || 'https://images.unsplash.com/photo-1544025162-d76694265947?w=200&q=80',
    order: Number(order) || db.categories.length + 1,
    isVisible: true
  };

  db.categories.push(newCat);
  saveDb();
  res.status(201).json({ success: true, message: 'Category created', data: newCat });
});

// PUT /api/categories/:id - Admin only
router.put('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.categories.findIndex(c => c.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Category not found' });
  }

  const existing = db.categories[index];
  const updated = {
    ...existing,
    ...req.body,
    id: existing.id
  };

  db.categories[index] = updated;
  saveDb();
  res.json({ success: true, message: 'Category updated', data: updated });
});

// PATCH /api/categories/:id/visibility - Admin only
router.patch('/:id/visibility', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const cat = db.categories.find(c => c.id === req.params.id);
  if (!cat) {
    return res.status(404).json({ success: false, message: 'Category not found' });
  }

  cat.isVisible = req.body.isVisible !== undefined ? Boolean(req.body.isVisible) : !cat.isVisible;
  saveDb();
  res.json({ success: true, message: `Category ${cat.isVisible ? 'unhidden' : 'hidden'}`, isVisible: cat.isVisible });
});

// DELETE /api/categories/:id - Admin only
router.delete('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.categories.findIndex(c => c.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Category not found' });
  }

  const deleted = db.categories.splice(index, 1)[0];
  saveDb();
  res.json({ success: true, message: 'Category deleted', data: deleted });
});

module.exports = router;
