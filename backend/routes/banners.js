const express = require('express');
const router = express.Router();
const { getDb, saveDb } = require('../database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET /api/banners - Public & Admin
router.get('/', (req, res) => {
  const db = getDb();
  const includeHidden = req.query.all === 'true';
  const list = includeHidden ? db.banners : db.banners.filter(b => b.isVisible !== false);
  res.json({ success: true, count: list.length, data: list });
});

// POST /api/banners - Admin only
router.post('/', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const {
    tagText = 'SPECIAL OFFER',
    title,
    dishesText,
    buttonText = 'Order Now',
    bgGradient = ['#6C3CE9', '#8B5CF6', '#A855F7'],
    imageUrl,
    isVisible = true,
    linkCategory = 'All'
  } = req.body;

  if (!title) {
    return res.status(400).json({ success: false, message: 'Title is required' });
  }

  const newBanner = {
    id: `banner_${Date.now()}`,
    tagText: tagText.trim(),
    title: title.trim(),
    dishesText: dishesText ? dishesText.trim() : '',
    buttonText: buttonText.trim(),
    bgGradient: Array.isArray(bgGradient) ? bgGradient : ['#6C3CE9', '#8B5CF6', '#A855F7'],
    imageUrl: imageUrl || 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&q=80',
    isVisible: Boolean(isVisible),
    linkCategory: linkCategory.trim()
  };

  db.banners.push(newBanner);
  saveDb();
  res.status(201).json({ success: true, message: 'Banner created', data: newBanner });
});

// PUT /api/banners/:id - Admin only
router.put('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.banners.findIndex(b => b.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Banner not found' });
  }

  const existing = db.banners[index];
  const updated = {
    ...existing,
    ...req.body,
    id: existing.id
  };

  db.banners[index] = updated;
  saveDb();
  res.json({ success: true, message: 'Banner updated', data: updated });
});

// PATCH /api/banners/:id/visibility - Admin only
router.patch('/:id/visibility', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const banner = db.banners.find(b => b.id === req.params.id);
  if (!banner) {
    return res.status(404).json({ success: false, message: 'Banner not found' });
  }

  banner.isVisible = req.body.isVisible !== undefined ? Boolean(req.body.isVisible) : !banner.isVisible;
  saveDb();
  res.json({ success: true, message: `Banner ${banner.isVisible ? 'unhidden' : 'hidden'}`, isVisible: banner.isVisible });
});

// DELETE /api/banners/:id - Admin only
router.delete('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.banners.findIndex(b => b.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Banner not found' });
  }

  const deleted = db.banners.splice(index, 1)[0];
  saveDb();
  res.json({ success: true, message: 'Banner deleted', data: deleted });
});

module.exports = router;
