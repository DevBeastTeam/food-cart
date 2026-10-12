const express = require('express');
const router = express.Router();
const { getDb, saveDb } = require('../database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET /api/restaurants - Public / Flutter app and Admin
router.get('/', (req, res) => {
  const db = getDb();
  const includeHidden = req.query.all === 'true';
  const list = includeHidden ? db.restaurants : db.restaurants.filter(r => r.isVisible !== false);
  res.json({ success: true, count: list.length, data: list });
});

// GET /api/restaurants/:id
router.get('/:id', (req, res) => {
  const db = getDb();
  const restaurant = db.restaurants.find(r => r.id === req.params.id);
  if (!restaurant) {
    return res.status(404).json({ success: false, message: 'Restaurant not found' });
  }
  // Include menu items for this restaurant
  const menu = db.foodItems.filter(item => item.restaurantId === restaurant.id && item.isVisible !== false);
  res.json({ success: true, data: { ...restaurant, menu } });
});

// POST /api/restaurants - Admin only
router.post('/', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const {
    name,
    cuisine,
    imageUrl,
    rating = 4.9,
    reviewCount = 100,
    deliveryTime = '25-35 min',
    deliveryFee = 49,
    minOrder = 300,
    distance = '2.0 km',
    address,
    badge = '',
    isFeatured = false,
    isVisible = true,
    categories = ['All']
  } = req.body;

  if (!name || !cuisine) {
    return res.status(400).json({ success: false, message: 'Name and cuisine are required' });
  }

  const newRestaurant = {
    id: `rest_${Date.now()}`,
    name: name.trim(),
    cuisine: cuisine.trim(),
    imageUrl: imageUrl || 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&q=80',
    rating: Number(rating) || 4.9,
    reviewCount: Number(reviewCount) || 100,
    deliveryTime: deliveryTime.trim(),
    deliveryFee: Number(deliveryFee) || 0,
    minOrder: Number(minOrder) || 0,
    distance: distance.trim(),
    address: address ? address.trim() : 'Gulberg III, Lahore',
    badge: badge.trim(),
    isFeatured: Boolean(isFeatured),
    isVisible: Boolean(isVisible),
    categories: Array.isArray(categories) && categories.length > 0 ? categories : ['All']
  };

  db.restaurants.push(newRestaurant);
  saveDb();
  res.status(201).json({ success: true, message: 'Restaurant created successfully', data: newRestaurant });
});

// PUT /api/restaurants/:id - Admin only
router.put('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.restaurants.findIndex(r => r.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Restaurant not found' });
  }

  const existing = db.restaurants[index];
  const updated = {
    ...existing,
    ...req.body,
    id: existing.id // protect ID
  };

  db.restaurants[index] = updated;
  saveDb();
  res.json({ success: true, message: 'Restaurant updated successfully', data: updated });
});

// PATCH /api/restaurants/:id/visibility - Admin only
router.patch('/:id/visibility', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const restaurant = db.restaurants.find(r => r.id === req.params.id);
  if (!restaurant) {
    return res.status(404).json({ success: false, message: 'Restaurant not found' });
  }

  restaurant.isVisible = req.body.isVisible !== undefined ? Boolean(req.body.isVisible) : !restaurant.isVisible;
  saveDb();
  res.json({ success: true, message: `Restaurant ${restaurant.isVisible ? 'unhidden' : 'hidden'}`, isVisible: restaurant.isVisible });
});

// DELETE /api/restaurants/:id - Admin only
router.delete('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.restaurants.findIndex(r => r.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Restaurant not found' });
  }

  const deleted = db.restaurants.splice(index, 1)[0];
  saveDb();
  res.json({ success: true, message: 'Restaurant deleted successfully', data: deleted });
});

module.exports = router;
