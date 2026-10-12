const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { getDb, saveDb } = require('../database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET /api/users - Admin only
router.get('/', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  let users = [...db.users];

  if (req.query.role && req.query.role !== 'All') {
    users = users.filter(u => u.role === req.query.role);
  }

  // Remove passwords before returning
  const safeUsers = users.map(({ passwordHash, ...safe }) => safe);
  res.json({ success: true, count: safeUsers.length, data: safeUsers });
});

// POST /api/users - Admin creates user
router.post('/', authenticateToken, requireAdmin, (req, res) => {
  const { name, email, phone, city = 'Lahore', role = 'client', walletBalance = 0, password = 'password' } = req.body;
  if (!name || !email) {
    return res.status(400).json({ success: false, message: 'Name and email are required' });
  }

  const db = getDb();
  const cleanEmail = email.trim().toLowerCase();
  if (db.users.some(u => u.email.toLowerCase() === cleanEmail)) {
    return res.status(400).json({ success: false, message: 'User with this email already exists' });
  }

  const newUser = {
    id: `usr_${Date.now()}`,
    name: name.trim(),
    email: cleanEmail,
    passwordHash: bcrypt.hashSync(password, 10),
    phone: phone ? phone.trim() : '+92 300 0000000',
    city: city.trim(),
    role: role.trim(),
    status: 'active',
    membershipTier: role === 'admin' ? 'Administrator 🛠️' : (role === 'rider' ? 'Delivery Captain 🛵' : 'FoodCourt Member ⭐'),
    walletBalance: Number(walletBalance) || 0,
    loyaltyCoins: 100,
    createdAt: new Date().toISOString()
  };

  db.users.push(newUser);
  saveDb();

  const { passwordHash, ...safeUser } = newUser;
  res.status(201).json({ success: true, message: 'User created successfully', data: safeUser });
});

// PUT /api/users/:id - Admin updates user
router.put('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const user = db.users.find(u => u.id === req.params.id);
  if (!user) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }

  const { name, phone, city, role, status, membershipTier, walletBalance, loyaltyCoins } = req.body;
  if (name) user.name = name.trim();
  if (phone) user.phone = phone.trim();
  if (city) user.city = city.trim();
  if (role) user.role = role.trim();
  if (status) user.status = status.trim();
  if (membershipTier) user.membershipTier = membershipTier.trim();
  if (walletBalance !== undefined) user.walletBalance = Number(walletBalance);
  if (loyaltyCoins !== undefined) user.loyaltyCoins = Number(loyaltyCoins);

  saveDb();
  const { passwordHash, ...safeUser } = user;
  res.json({ success: true, message: 'User updated successfully', data: safeUser });
});

// PATCH /api/users/:id/status - Block / unblock user
router.patch('/:id/status', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const user = db.users.find(u => u.id === req.params.id);
  if (!user) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }

  user.status = user.status === 'active' ? 'blocked' : 'active';
  saveDb();
  res.json({ success: true, message: `User status changed to ${user.status}`, status: user.status });
});

// PATCH /api/users/:id/wallet - Add funds
router.patch('/:id/wallet', authenticateToken, requireAdmin, (req, res) => {
  const { amount } = req.body;
  const db = getDb();
  const user = db.users.find(u => u.id === req.params.id);
  if (!user) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }

  user.walletBalance = (user.walletBalance || 0) + Number(amount || 0);
  saveDb();
  res.json({ success: true, message: `Wallet updated: Rs. ${user.walletBalance}`, walletBalance: user.walletBalance });
});

// DELETE /api/users/:id - Delete user
router.delete('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.users.findIndex(u => u.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }

  const deleted = db.users.splice(index, 1)[0];
  saveDb();
  res.json({ success: true, message: 'User deleted successfully', data: { id: deleted.id, email: deleted.email } });
});

module.exports = router;
