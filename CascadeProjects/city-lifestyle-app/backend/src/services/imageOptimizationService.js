const sharp = require('sharp');
const mongoose = require('mongoose');
const fetch = require('node-fetch');
const path = require('path');
const fs = require('fs').promises;
const crypto = require('crypto');

// Define optimized image schema
const optimizedImageSchema = new mongoose.Schema({
  originalHash: String,
  optimizedVersions: [{
    width: Number,
    height: Number,
    quality: Number,
    format: String,
    size: Number,
    path: String
  }],
  metadata: {
    format: String,
    width: Number,
    height: Number,
    size: Number,
    hasAlpha: Boolean,
    hasProfile: Boolean,
    channels: Number
  },
  createdAt: { type: Date, default: Date.now }
});

const OptimizedImage = mongoose.model('OptimizedImage', optimizedImageSchema);

class ImageOptimizationService {
  constructor() {
    this.supportedFormats = ['jpeg', 'png', 'webp', 'avif'];
    this.cachePath = path.join(process.cwd(), 'cache', 'images');
    this.queue = [];
    this.processing = false;
    this.ensureCacheDirectory();
  }

  // Ensure cache directory exists
  async ensureCacheDirectory() {
    try {
      await fs.mkdir(this.cachePath, { recursive: true });
    } catch (error) {
      console.error('Failed to create cache directory:', error);
    }
  }

  // Get optimized image
  async getOptimizedImage(id, options = {}) {
    try {
      const image = await OptimizedImage.findById(id);
      if (!image) {
        throw new Error('Image not found');
      }

      // Find existing optimized version
      const existingVersion = image.optimizedVersions.find(version =>
        version.width === options.width &&
        version.height === options.height &&
        version.quality === options.quality &&
        version.format === options.format
      );

      if (existingVersion) {
        const imageData = await fs.readFile(existingVersion.path);
        return {
          data: imageData,
          contentType: `image/${existingVersion.format}`,
          metadata: image.metadata
        };
      }

      // Create new optimized version
      const originalPath = image.optimizedVersions[0].path;
      const optimizedVersion = await this.createOptimizedVersion(originalPath, options);
      
      image.optimizedVersions.push(optimizedVersion);
      await image.save();

      const imageData = await fs.readFile(optimizedVersion.path);
      return {
        data: imageData,
        contentType: `image/${optimizedVersion.format}`,
        metadata: image.metadata
      };
    } catch (error) {
      throw new Error(`Failed to get optimized image: ${error.message}`);
    }
  }

  // Get image metadata
  async getImageMetadata(id) {
    try {
      const image = await OptimizedImage.findById(id);
      if (!image) {
        throw new Error('Image not found');
      }
      return image.metadata;
    } catch (error) {
      throw new Error(`Failed to get image metadata: ${error.message}`);
    }
  }

  // Optimize single image
  async optimizeImage(file, options = {}) {
    try {
      const buffer = file.buffer;
      const hash = this.calculateHash(buffer);

      // Check if image already exists
      let image = await OptimizedImage.findOne({ originalHash: hash });
      if (image) {
        return image;
      }

      // Get image metadata
      const metadata = await sharp(buffer).metadata();

      // Create optimized versions
      const originalPath = path.join(this.cachePath, `${hash}_original.${metadata.format}`);
      await fs.writeFile(originalPath, buffer);

      const optimizedVersion = await this.createOptimizedVersion(originalPath, {
        ...options,
        format: options.format || metadata.format
      });

      // Save to database
      image = new OptimizedImage({
        originalHash: hash,
        optimizedVersions: [optimizedVersion],
        metadata: {
          format: metadata.format,
          width: metadata.width,
          height: metadata.height,
          size: buffer.length,
          hasAlpha: metadata.hasAlpha,
          hasProfile: metadata.hasProfile,
          channels: metadata.channels
        }
      });

      await image.save();
      return image;
    } catch (error) {
      throw new Error(`Failed to optimize image: ${error.message}`);
    }
  }

  // Optimize multiple images
  async optimizeBatchImages(files, options = {}) {
    try {
      const results = [];
      for (const file of files) {
        const result = await this.optimizeImage(file, options);
        results.push(result);
      }
      return results;
    } catch (error) {
      throw new Error(`Failed to optimize batch images: ${error.message}`);
    }
  }

  // Optimize image from URL
  async optimizeImageFromUrl(url, options = {}) {
    try {
      const response = await fetch(url);
      const buffer = await response.buffer();
      
      const file = {
        buffer,
        originalname: path.basename(url)
      };

      return await this.optimizeImage(file, options);
    } catch (error) {
      throw new Error(`Failed to optimize image from URL: ${error.message}`);
    }
  }

  // Get optimization statistics
  async getOptimizationStats() {
    try {
      const totalImages = await OptimizedImage.countDocuments();
      const totalVersions = await OptimizedImage.aggregate([
        { $unwind: '$optimizedVersions' },
        { $count: 'total' }
      ]);

      const stats = {
        totalImages,
        totalVersions: totalVersions[0]?.total || 0,
        cacheSize: await this.calculateCacheSize(),
        formats: await this.getFormatStats()
      };

      return stats;
    } catch (error) {
      throw new Error(`Failed to get optimization stats: ${error.message}`);
    }
  }

  // Update optimization settings
  async updateSettings(settings) {
    // Implementation would depend on what settings are configurable
    return settings;
  }

  // Clear image cache
  async clearCache() {
    try {
      await fs.rm(this.cachePath, { recursive: true });
      await this.ensureCacheDirectory();
      await OptimizedImage.deleteMany({});
      return { success: true };
    } catch (error) {
      throw new Error(`Failed to clear cache: ${error.message}`);
    }
  }

  // Get optimization queue status
  async getQueue() {
    return {
      queued: this.queue.length,
      processing: this.processing
    };
  }

  // Helper: Calculate file hash
  calculateHash(buffer) {
    return crypto.createHash('md5').update(buffer).digest('hex');
  }

  // Helper: Create optimized version of image
  async createOptimizedVersion(inputPath, options) {
    const { width, height, quality, format } = options;
    const outputFormat = format || 'jpeg';
    const outputPath = path.join(
      this.cachePath,
      `${path.basename(inputPath, path.extname(inputPath))}_${width}x${height}_q${quality}.${outputFormat}`
    );

    let pipeline = sharp(inputPath);

    if (width || height) {
      pipeline = pipeline.resize(width, height, {
        fit: 'inside',
        withoutEnlargement: true
      });
    }

    pipeline = pipeline.toFormat(outputFormat, {
      quality: quality || 80,
      chromaSubsampling: '4:4:4'
    });

    await pipeline.toFile(outputPath);

    const stats = await fs.stat(outputPath);
    return {
      width,
      height,
      quality,
      format: outputFormat,
      size: stats.size,
      path: outputPath
    };
  }

  // Helper: Calculate total cache size
  async calculateCacheSize() {
    try {
      let totalSize = 0;
      const files = await fs.readdir(this.cachePath);
      
      for (const file of files) {
        const stats = await fs.stat(path.join(this.cachePath, file));
        totalSize += stats.size;
      }

      return totalSize;
    } catch (error) {
      return 0;
    }
  }

  // Helper: Get format statistics
  async getFormatStats() {
    try {
      return await OptimizedImage.aggregate([
        { $unwind: '$optimizedVersions' },
        {
          $group: {
            _id: '$optimizedVersions.format',
            count: { $sum: 1 },
            totalSize: { $sum: '$optimizedVersions.size' }
          }
        }
      ]);
    } catch (error) {
      return [];
    }
  }
}

module.exports = new ImageOptimizationService();
