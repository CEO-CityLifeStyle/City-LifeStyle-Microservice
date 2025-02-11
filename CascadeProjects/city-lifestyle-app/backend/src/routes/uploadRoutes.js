const express = require('express');
const { upload, uploadToGCS, deleteFromGCS } = require('../services/uploadService');
const auth = require('../middleware/auth');

const router = express.Router();

// Upload single image
router.post('/single', auth, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const imageUrl = await uploadToGCS(req.file);
    res.json({ imageUrl });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Upload multiple images
router.post('/multiple', auth, upload.array('images', 5), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ error: 'No files uploaded' });
    }

    const uploadPromises = req.files.map(file => uploadToGCS(file));
    const imageUrls = await Promise.all(uploadPromises);
    
    res.json({ imageUrls });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Delete image
router.delete('/', auth, async (req, res) => {
  try {
    const { imageUrl } = req.body;
    if (!imageUrl) {
      return res.status(400).json({ error: 'Image URL is required' });
    }

    await deleteFromGCS(imageUrl);
    res.json({ message: 'Image deleted successfully' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;
