const express = require('express');
const router = express.Router();
const { getDb } = require('../database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET /api/dashboard/stats
router.get('/stats', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const orders = db.orders || [];
  const users = db.users || [];
  const restaurants = db.restaurants || [];
  const foodItems = db.foodItems || [];
  const daigDishes = db.daigDishes || [];
  const deals = db.deals || [];

  const totalOrders = orders.length;
  const totalRevenue = orders.reduce((sum, o) => sum + (Number(o.totalAmount) || 0), 0);
  const activeOrders = orders.filter(o => o.status !== 'Delivered' && o.status !== 'Cancelled').length;
  const deliveredOrders = orders.filter(o => o.status === 'Delivered').length;
  const daigBookings = orders.filter(o => o.isDaigBooking).length;
  const avgOrderValue = totalOrders > 0 ? Math.round(totalRevenue / totalOrders) : 0;

  // Breakdown by status
  const ordersByStatus = {
    Accepted: orders.filter(o => o.status === 'Accepted').length,
    Preparing: orders.filter(o => o.status === 'Preparing').length,
    'On the Way': orders.filter(o => o.status === 'On the Way').length,
    Delivered: deliveredOrders,
    Cancelled: orders.filter(o => o.status === 'Cancelled').length
  };

  // User stats
  const totalUsers = users.length;
  const totalRiders = users.filter(u => u.role === 'rider').length;
  const totalCustomers = users.filter(u => u.role === 'client').length;

  // Recent 6 orders
  const recentOrders = [...orders]
    .sort((a, b) => new Date(b.orderDate) - new Date(a.orderDate))
    .slice(0, 6);

  // Active deals count
  const activeDealsCount = deals.filter(d => d.status === 'active' && d.isVisible).length;

  res.json({
    success: true,
    data: {
      metrics: {
        totalRevenue,
        totalOrders,
        activeOrders,
        deliveredOrders,
        daigBookings,
        avgOrderValue,
        totalUsers,
        totalRiders,
        totalCustomers,
        totalRestaurants: restaurants.length,
        totalMenuItems: foodItems.length,
        totalDaigItems: daigDishes.length,
        activeDealsCount
      },
      ordersByStatus,
      recentOrders,
      systemAlert: db.settings.emergencyAlert
    }
  });
});

module.exports = router;
