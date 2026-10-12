const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const { getDb } = require('./database');

const authRoutes = require('./routes/auth');
const dashboardRoutes = require('./routes/dashboard');
const restaurantRoutes = require('./routes/restaurants');
const foodItemRoutes = require('./routes/foodItems');
const daigItemRoutes = require('./routes/daigItems');
const martProductRoutes = require('./routes/martProducts');
const categoryRoutes = require('./routes/categories');
const dealRoutes = require('./routes/deals');
const bannerRoutes = require('./routes/banners');
const contentRoutes = require('./routes/content');
const navigationRoutes = require('./routes/navigation');
const orderRoutes = require('./routes/orders');
const userRoutes = require('./routes/users');
const settingRoutes = require('./routes/settings');
const mediaRoutes = require('./routes/media');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '20mb' }));
app.use(express.urlencoded({ extended: true, limit: '20mb' }));

// Static uploads folder
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}
app.use('/uploads', express.static(uploadsDir));

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/restaurants', restaurantRoutes);
app.use('/api/food-items', foodItemRoutes);
app.use('/api/daig-items', daigItemRoutes);
app.use('/api/mart-products', martProductRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/deals', dealRoutes);
app.use('/api/banners', bannerRoutes);
app.use('/api/content', contentRoutes);
app.use('/api/navigation', navigationRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/users', userRoutes);
app.use('/api/settings', settingRoutes);
app.use('/api/media', mediaRoutes);

// Health check / API Index
app.get('/api', (req, res) => {
  res.json({
    status: 'online',
    app: 'Food Court Backend API',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    endpoints: [
      '/api/auth',
      '/api/dashboard/stats',
      '/api/restaurants',
      '/api/food-items',
      '/api/daig-items',
      '/api/mart-products',
      '/api/categories',
      '/api/deals',
      '/api/banners',
      '/api/content',
      '/api/navigation',
      '/api/orders',
      '/api/users',
      '/api/settings',
      '/api/media'
    ]
  });
});

// Serve Admin Panel build if present
const adminDistPath = path.join(__dirname, '..', 'admin-panel', 'dist');
if (fs.existsSync(adminDistPath)) {
  app.use(express.static(adminDistPath));
  app.get('*', (req, res, next) => {
    if (req.path.startsWith('/api') || req.path.startsWith('/uploads')) {
      return next();
    }
    res.sendFile(path.join(adminDistPath, 'index.html'));
  });
} else {
  app.get('/', (req, res) => {
    res.send(`
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <title>Food Court Backend API</title>
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #f8fafc; padding: 40px; }
          .card { max-width: 600px; margin: 0 auto; background: #1e293b; border-radius: 16px; padding: 32px; box-shadow: 0 10px 25px rgba(0,0,0,0.3); border: 1px solid #334155; }
          h1 { color: #a855f7; margin-top: 0; }
          .badge { display: inline-block; background: #22c55e; color: #000; font-weight: 700; padding: 4px 10px; border-radius: 999px; font-size: 12px; }
          a { color: #38bdf8; text-decoration: none; font-weight: 600; }
          a:hover { text-decoration: underline; }
          ul { line-height: 1.8; color: #94a3b8; }
        </style>
      </head>
      <body>
        <div class="card">
          <h1>⚡ Food Court Backend API</h1>
          <p><span class="badge">ACTIVE</span> Running smoothly on port ${PORT}</p>
          <p>The backend is fully operational and servicing both the Flutter Mobile App and React Admin Panel.</p>
          <h3>Useful Links:</h3>
          <ul>
            <li><a href="/api">API Documentation & Endpoints Index</a></li>
            <li><a href="http://localhost:5173" target="_blank">React Admin Panel (Dev Server)</a></li>
          </ul>
        </div>
      </body>
      </html>
    `);
  });
}

// Global error handler
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({ success: false, message: err.message || 'Internal server error' });
});

// Start listening
app.listen(PORT, '0.0.0.0', () => {
  console.log(`===============================================`);
  console.log(`🚀 Food Court Backend listening on port ${PORT}`);
  console.log(`📍 Local:   http://localhost:${PORT}`);
  console.log(`📍 API:     http://localhost:${PORT}/api`);
  console.log(`===============================================`);
});
