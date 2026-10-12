const express = require('express');
const router = express.Router();
const { getDb, saveDb } = require('../database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET /api/mart-products - Public & Admin
router.get('/', (req, res) => {
  const db = getDb();
  const includeHidden = req.query.all === 'true';
  const list = includeHidden ? db.martProducts : db.martProducts.filter(m => m.isVisible !== false);
  res.json({ success: true, count: list.length, data: list });
});

// POST /api/mart-products - Admin only
router.post('/', authenticateToken, requireAdmin, (req, res) => {
  const { name, description, price, imageUrl, category = 'General', rating = 4.8, isPopular = false, inStock = true } = req.body;
  if (!name || price === undefined) {
    return res.status(400).json({ success: false, message: 'Name and price are required' });
  }

  const db = getDb();
  const newProduct = {
    id: `mart_${Date.now()}`,
    restaurantId: 'foodcourt_mart',
    name: name.trim(),
    description: description ? description.trim() : '',
    price: Number(price),
    imageUrl: imageUrl || 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500&q=80',
    category: category.trim(),
    rating: Number(rating) || 4.8,
    isPopular: Boolean(isPopular),
    inStock: inStock !== undefined ? Boolean(inStock) : true,
    isVisible: true
  };

  db.martProducts.push(newProduct);
  saveDb();
  res.status(201).json({ success: true, message: 'Mart product created', data: newProduct });
});

// PUT /api/mart-products/:id - Admin only
router.put('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.martProducts.findIndex(m => m.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Mart product not found' });
  }

  const existing = db.martProducts[index];
  const updated = {
    ...existing,
    ...req.body,
    id: existing.id
  };

  db.martProducts[index] = updated;
  saveDb();
  res.json({ success: true, message: 'Mart product updated', data: updated });
});

// PATCH /api/mart-products/:id/visibility - Admin only
router.patch('/:id/visibility', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const product = db.martProducts.find(m => m.id === req.params.id);
  if (!product) {
    return res.status(404).json({ success: false, message: 'Mart product not found' });
  }

  product.isVisible = req.body.isVisible !== undefined ? Boolean(req.body.isVisible) : !product.isVisible;
  saveDb();
  res.json({ success: true, message: `Product ${product.isVisible ? 'unhidden' : 'hidden'}`, isVisible: product.isVisible });
});

// PATCH /api/mart-products/:id/stock - Admin only
router.patch('/:id/stock', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const product = db.martProducts.find(m => m.id === req.params.id);
  if (!product) {
    return res.status(404).json({ success: false, message: 'Mart product not found' });
  }

  product.inStock = req.body.inStock !== undefined ? Boolean(req.body.inStock) : !product.inStock;
  saveDb();
  res.json({ success: true, message: `Product stock status: ${product.inStock}`, inStock: product.inStock });
});

// DELETE /api/mart-products/:id - Admin only
router.delete('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.martProducts.findIndex(m => m.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Mart product not found' });
  }

  const deleted = db.martProducts.splice(index, 1)[0];
  saveDb();
  res.json({ success: true, message: 'Mart product deleted', data: deleted });
});

module.exports = router;
