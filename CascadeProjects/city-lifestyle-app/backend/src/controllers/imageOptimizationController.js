const imageOptimizationService = require('../services/imageOptimizationService');

class ImageOptimizationController {
  // Get optimized image
  async getOptimizedImage(req, res) {
    try {
      const { id } = req.params;
      const { width, height, quality, format } = req.query;
      const image = await imageOptimizationService.getOptimizedImage(id, {
        width: parseInt(width),
        height: parseInt(height),
        quality: parseInt(quality),
        format
      });
      res.type(image.contentType);
      res.send(image.data);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get image metadata
  async getImageMetadata(req, res) {
    try {
      const { id } = req.params;
      const metadata = await imageOptimizationService.getImageMetadata(id);
      res.json(metadata);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Optimize single image
  async optimizeImage(req, res) {
    try {
      if (!req.file) {
        return res.status(400).json({ error: 'No image file provided' });
      }

      const options = {
        quality: req.body.quality ? parseInt(req.body.quality) : undefined,
        width: req.body.width ? parseInt(req.body.width) : undefined,
        height: req.body.height ? parseInt(req.body.height) : undefined,
        format: req.body.format,
        preserveExif: req.body.preserveExif === 'true'
      };

      const optimizedImage = await imageOptimizationService.optimizeImage(req.file, options);
      res.json(optimizedImage);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Optimize multiple images
  async optimizeBatchImages(req, res) {
    try {
      if (!req.files || req.files.length === 0) {
        return res.status(400).json({ error: 'No image files provided' });
      }

      const options = {
        quality: req.body.quality ? parseInt(req.body.quality) : undefined,
        width: req.body.width ? parseInt(req.body.width) : undefined,
        height: req.body.height ? parseInt(req.body.height) : undefined,
        format: req.body.format,
        preserveExif: req.body.preserveExif === 'true'
      };

      const optimizedImages = await imageOptimizationService.optimizeBatchImages(req.files, options);
      res.json(optimizedImages);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Optimize image from URL
  async optimizeImageFromUrl(req, res) {
    try {
      const { url } = req.body;
      if (!url) {
        return res.status(400).json({ error: 'No URL provided' });
      }

      const options = {
        quality: req.body.quality ? parseInt(req.body.quality) : undefined,
        width: req.body.width ? parseInt(req.body.width) : undefined,
        height: req.body.height ? parseInt(req.body.height) : undefined,
        format: req.body.format,
        preserveExif: req.body.preserveExif === 'true'
      };

      const optimizedImage = await imageOptimizationService.optimizeImageFromUrl(url, options);
      res.json(optimizedImage);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get optimization statistics
  async getOptimizationStats(req, res) {
    try {
      const stats = await imageOptimizationService.getOptimizationStats();
      res.json(stats);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Update optimization settings
  async updateOptimizationSettings(req, res) {
    try {
      const settings = await imageOptimizationService.updateSettings(req.body);
      res.json(settings);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Clear image cache
  async clearImageCache(req, res) {
    try {
      await imageOptimizationService.clearCache();
      res.json({ message: 'Cache cleared successfully' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  // Get optimization queue status
  async getOptimizationQueue(req, res) {
    try {
      const queue = await imageOptimizationService.getQueue();
      res.json(queue);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = new ImageOptimizationController();
