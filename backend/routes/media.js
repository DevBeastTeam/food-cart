const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { getDb, saveDb } = require('../database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const UPLOADS_DIR = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Multer storage configuration
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, UPLOADS_DIR);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    const baseName = path.basename(file.originalname, ext).replace(/[^a-zA-Z0-9]/g, '_');
    cb(null, `${baseName}_${Date.now()}${ext}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|webp|gif|svg/;
    const ext = path.extname(file.originalname).toLowerCase();
    if (allowed.test(ext)) {
      cb(null, true);
    } else {
      cb(new Error('Only image files (JPEG, PNG, WEBP, GIF, SVG) are allowed'));
    }
  }
});

// GET /api/media - Get all media assets
router.get('/', (req, res) => {
  const db = getDb();
  res.json({ success: true, count: db.media.length, data: db.media });
});

// POST /api/media/upload - Upload file
router.post('/upload', authenticateToken, requireAdmin, upload.single('image'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'No file uploaded' });
  }

  const host = req.get('host');
  const protocol = req.protocol;
  const fileUrl = `${protocol}://${host}/uploads/${req.file.filename}`;

  const db = getDb();
  const newMedia = {
    id: `med_${Date.now()}`,
    name: req.body.name || req.file.originalname,
    url: fileUrl,
    filename: req.file.filename,
    type: 'image',
    category: req.body.category || 'general',
    sizeBytes: req.file.size,
    uploadedAt: new Date().toISOString()
  };

  db.media.unshift(newMedia);
  saveDb();

  res.status(201).json({ success: true, message: 'Image uploaded successfully', data: newMedia });
});

// POST /api/media/url - Add external image URL
router.post('/url', authenticateToken, requireAdmin, (req, res) => {
  const { name, url, category = 'general' } = req.body;
  if (!url) {
    return res.status(400).json({ success: false, message: 'URL is required' });
  }

  const db = getDb();
  const newMedia = {
    id: `med_${Date.now()}`,
    name: name || 'External Media',
    url: url.trim(),
    type: 'image',
    category,
    uploadedAt: new Date().toISOString()
  };

  db.media.unshift(newMedia);
  saveDb();

  res.status(201).json({ success: true, message: 'Media URL added successfully', data: newMedia });
});

// DELETE /api/media/:id - Delete media
router.delete('/:id', authenticateToken, requireAdmin, (req, res) => {
  const db = getDb();
  const index = db.media.findIndex(m => m.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ success: false, message: 'Media not found' });
  }

  const item = db.media[index];
  if (item.filename) {
    const filePath = path.join(UPLOADS_DIR, item.filename);
    if (fs.existsSync(filePath)) {
      try {
        fs.unlinkSync(filePath);
      } catch (err) {
        console.error('Failed to delete physical file:', err);
      }
    }
  }

  db.media.splice(index, 1);
  saveDb();
  res.json({ success: true, message: 'Media removed successfully', data: item });
});

module.exports = router;
