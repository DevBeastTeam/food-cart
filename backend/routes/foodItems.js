const express = require('express');
const router = express.Router();
const { getDb, saveDb } = require('../database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET /api/food-items - Public / App and Admin
router.get('/', (req, res) => {
  const db = getDb();
  const includeHidden = req.query.all === 'true';
  let items = includeHidden ? db.foodItems : db.foodItems.filter(item => item.isVisible !== false);

  if (req.query.restaurantId) {
    items = items.filter(item => item.restaurantId === req.query.restaurantId);
  }
  if (req.query.category && req.query.category !== 'All') {
    items = items.filter(item => item.category.toLowerCase() === req.query.category.toLowerCase());
  }
  if (req.query.popular === 'true') {
    items = items.filter(item => item.isPopular);
  }
  if (req.query.search || req.query.q) {
    const query = (req.query.search || req.query.q).toString().toLowerCase().trim();
    if (query) {
      items = items.filter(item =>
        item.name.toLowerCase().includes(query) ||
        (item.description && item.description.toLowerCase().includes(query)) ||
        (item.category && item.category.toLowerCase().includes(query))
      );
    }
  }

  res.json({ success: true, count: items.length, data: items });
});

// GET /api/food-items/:id
router.get('/:id', (req, res) => {
  const db = getDb();
  const item = db.foodItems.find(i => i.id === req.params.id);
  if (!item) {
    return res.status(404).json({ success: false, message: 'Item not found' });
  }
  res.json({ success: true, data: item });
});

// POST /api/food-items - Admin only
router.post('/', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const {
    restaurantId = 'rest_1',
    name,
    description,
    price,
    imageUrl,
    category,
    rating = 4.9,
    calories = 450,
    isPopular = false,
    isVegetarian = false,
    isVisible = true,
    badges = []
  } = req.body;

  if (!name || price === undefined || !category) {
    return res.status(400).json({ success: false, message: 'Name, price, and category are required' });
  }

  const newItem = {
    id: `item_${Date.now()}`,
    restaurantId,
    name: name.trim(),
    description: description ? description.trim() : '',
    price: Number(price),
    imageUrl: imageUrl || 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&q=80',
    category: category.trim(),
    rating: Number(rating) || 4.9,
    calories: Number(calories) || 400,
    isPopular: Boolean(isPopular),
    isVegetarian: Boolean(isVegetarian),
    isVisible: Boolean(isVisible),
    badges: Array.isArray(badges) ? badges : ['Special']
  };

  db.foodItems.push(newItem);
  saveDb();
  res.status(201).json({ success: true, message: 'Food item created', data: newItem });
});

// PUT /api/food-items/:id - Admin only
router.put('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.foodItems.findIndex(i => i.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Item not found' });
  }

  const existing = db.foodItems[index];
  const updated = {
    ...existing,
    ...req.body,
    id: existing.id // preserve ID
  };

  db.foodItems[index] = updated;
  saveDb();
  res.json({ success: true, message: 'Food item updated', data: updated });
});

// PATCH /api/food-items/:id/visibility - Admin only
router.patch('/:id/visibility', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const item = db.foodItems.find(i => i.id === req.params.id);
  if (!item) {
    return res.status(404).json({ success: false, message: 'Item not found' });
  }

  item.isVisible = req.body.isVisible !== undefined ? Boolean(req.body.isVisible) : !item.isVisible;
  saveDb();
  res.json({ success: true, message: `Item ${item.isVisible ? 'unhidden' : 'hidden'}`, isVisible: item.isVisible });
});

// PATCH /api/food-items/:id/popular - Admin only
router.patch('/:id/popular', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const item = db.foodItems.find(i => i.id === req.params.id);
  if (!item) {
    return res.status(404).json({ success: false, message: 'Item not found' });
  }

  item.isPopular = req.body.isPopular !== undefined ? Boolean(req.body.isPopular) : !item.isPopular;
  saveDb();
  res.json({ success: true, message: `Item popular status: ${item.isPopular}`, isPopular: item.isPopular });
});

// DELETE /api/food-items/:id - Admin only
router.delete('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.foodItems.findIndex(i => i.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Item not found' });
  }

  const deleted = db.foodItems.splice(index, 1)[0];
  saveDb();
  res.json({ success: true, message: 'Food item deleted', data: deleted });
});

module.exports = router;
