const express = require('express');
const router = express.Router();
const { getDb, saveDb, evaluateDeals } = require('../database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET /api/deals - Public & Admin
router.get('/', (req, res) => {
  evaluateDeals(); // ensure up-to-date schedule status
  const db = getDb();
  const includeHidden = req.query.all === 'true';
  const list = includeHidden ? db.deals : db.deals.filter(d => d.isVisible !== false && d.status === 'active');
  res.json({ success: true, count: list.length, data: list });
});

// GET /api/deals/:id
router.get('/:id', (req, res) => {
  evaluateDeals();
  const db = getDb();
  const deal = db.deals.find(d => d.id === req.params.id);
  if (!deal) {
    return res.status(404).json({ success: false, message: 'Deal not found' });
  }
  res.json({ success: true, data: deal });
});

// POST /api/deals - Admin only
router.post('/', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const {
    code,
    title,
    discountPercent,
    description,
    imageUrl,
    category = 'All',
    startDate,
    endDate,
    startTime = '00:00',
    endTime = '23:59',
    minOrder = 0,
    maxDiscount = 1000,
    isVisible = true
  } = req.body;

  if (!code || !title || discountPercent === undefined) {
    return res.status(400).json({ success: false, message: 'Code, title, and discountPercent are required' });
  }

  const newDeal = {
    id: `deal_${Date.now()}`,
    code: code.trim().toUpperCase(),
    title: title.trim(),
    discountPercent: Number(discountPercent),
    description: description ? description.trim() : '',
    imageUrl: imageUrl || 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80',
    category: category.trim(),
    startDate: startDate || new Date().toISOString().split('T')[0],
    endDate: endDate || '2026-12-31',
    startTime: startTime.trim(),
    endTime: endTime.trim(),
    minOrder: Number(minOrder) || 0,
    maxDiscount: Number(maxDiscount) || 1000,
    isVisible: Boolean(isVisible),
    status: 'active'
  };

  db.deals.push(newDeal);
  saveDb();
  evaluateDeals();

  res.status(201).json({ success: true, message: 'Deal created', data: newDeal });
});

// PUT /api/deals/:id - Admin only
router.put('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.deals.findIndex(d => d.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Deal not found' });
  }

  const existing = db.deals[index];
  const updated = {
    ...existing,
    ...req.body,
    id: existing.id
  };

  if (updated.code) {
    updated.code = updated.code.trim().toUpperCase();
  }

  db.deals[index] = updated;
  saveDb();
  evaluateDeals();

  res.json({ success: true, message: 'Deal updated', data: updated });
});

// PATCH /api/deals/:id/visibility - Admin only
router.patch('/:id/visibility', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const deal = db.deals.find(d => d.id === req.params.id);
  if (!deal) {
    return res.status(404).json({ success: false, message: 'Deal not found' });
  }

  deal.isVisible = req.body.isVisible !== undefined ? Boolean(req.body.isVisible) : !deal.isVisible;
  saveDb();
  evaluateDeals();

  res.json({ success: true, message: `Deal ${deal.isVisible ? 'unhidden' : 'hidden'}`, isVisible: deal.isVisible });
});

// DELETE /api/deals/:id - Admin only
router.delete('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.deals.findIndex(d => d.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Deal not found' });
  }

  const deleted = db.deals.splice(index, 1)[0];
  saveDb();
  res.json({ success: true, message: 'Deal deleted', data: deleted });
});

module.exports = router;
