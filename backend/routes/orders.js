const express = require('express');
const router = express.Router();
const { getDb, saveDb } = require('../database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET /api/orders - All orders (for admin or user filter)
router.get('/', (req, res) => {
  const db = getDb();
  let orders = [...db.orders];

  if (req.query.status && req.query.status !== 'All') {
    orders = orders.filter(o => o.status.toLowerCase() === req.query.status.toLowerCase());
  }

  if (req.query.customerPhone) {
    orders = orders.filter(o => o.customerPhone === req.query.customerPhone);
  }

  // Sort latest first
  orders.sort((a, b) => new Date(b.orderDate) - new Date(a.orderDate));

  res.json({ success: true, count: orders.length, data: orders });
});

// GET /api/orders/:id
router.get('/:id', (req, res) => {
  const db = getDb();
  const order = db.orders.find(o => o.id === req.params.id);
  if (!order) {
    return res.status(404).json({ success: false, message: 'Order not found' });
  }
  res.json({ success: true, data: order });
});

// POST /api/orders - Create new order (From Mobile App or Admin)
router.post('/', (req, res) => {
  const db = getDb();
  const {
    restaurantName,
    restaurantImage,
    items,
    totalAmount,
    originalAmount,
    discountInfo,
    deliveryAddress,
    prepTime = '25-35 mins',
    customerName = 'Customer',
    customerPhone = '+92 300 0000000',
    isDaigBooking = false,
    occasion,
    notes
  } = req.body;

  if (!items || !totalAmount) {
    return res.status(400).json({ success: false, message: 'Items and totalAmount are required' });
  }

  const generatedNum = (Date.now() % 10000).toString().padStart(4, '0');
  const newOrder = {
    id: `FC-${generatedNum}`,
    restaurantName: restaurantName || 'FoodCourt Central Kitchen',
    restaurantImage: restaurantImage || 'https://images.unsplash.com/photo-1544025162-d76694265947?w=300&q=80',
    items: Array.isArray(items) ? items : [items],
    totalAmount: Number(totalAmount),
    originalAmount: originalAmount ? Number(originalAmount) : Number(totalAmount),
    discountInfo: discountInfo || null,
    orderDate: new Date().toISOString(),
    status: 'Accepted',
    prepTime,
    customerName,
    customerPhone,
    deliveryAddress: deliveryAddress || 'Gulberg III, Lahore',
    isDaigBooking: Boolean(isDaigBooking),
    occasion: occasion || null,
    notes: notes || ''
  };

  db.orders.unshift(newOrder);
  saveDb();

  res.status(201).json({ success: true, message: 'Order placed successfully', data: newOrder });
});

// PATCH /api/orders/:id/status - Update order status (Admin & Rider)
router.patch('/:id/status', (req, res) => {
  const { status, prepTime, notes } = req.body;
  const db = getDb();
  const order = db.orders.find(o => o.id === req.params.id);

  if (!order) {
    return res.status(404).json({ success: false, message: 'Order not found' });
  }

  const validStatuses = ['Accepted', 'Preparing', 'On the Way', 'Delivered', 'Cancelled'];
  if (status && !validStatuses.includes(status)) {
    return res.status(400).json({ success: false, message: 'Invalid order status' });
  }

  if (status) order.status = status;
  if (prepTime) order.prepTime = prepTime;
  if (notes !== undefined) order.notes = notes;

  saveDb();
  res.json({ success: true, message: `Order status updated to ${order.status}`, data: order });
});

// PATCH /api/orders/:id/assign-rider - Assign delivery rider
router.patch('/:id/assign-rider', authenticateToken, requireAdmin, (req, res) => {
  const { riderName = 'Captain Ali Raza', riderPhone = '+92 302 9988776' } = req.body;
  const db = getDb();
  const order = db.orders.find(o => o.id === req.params.id);

  if (!order) {
    return res.status(404).json({ success: false, message: 'Order not found' });
  }

  order.riderName = riderName;
  order.riderPhone = riderPhone;
  order.status = 'On the Way';
  order.prepTime = 'Rider on route';

  saveDb();
  res.json({ success: true, message: `Rider assigned: ${riderName}`, data: order });
});

// DELETE /api/orders/:id - Admin only
router.delete('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.orders.findIndex(o => o.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Order not found' });
  }

  const deleted = db.orders.splice(index, 1)[0];
  saveDb();
  res.json({ success: true, message: 'Order deleted', data: deleted });
});

module.exports = router;
