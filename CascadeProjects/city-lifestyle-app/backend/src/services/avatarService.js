const sharp = require('sharp');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const {
  bucket,
  generateUploadUrl,
  generateDownloadUrl,
  deleteFile,
} = require('../config/storage');
const { HttpException } = require('../utils/errors');

class AvatarService {
  constructor() {
    this.allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];
    this.maxFileSize = 5 * 1024 * 1024; // 5MB
  }

  async validateImage(file) {
    if (!file) {
      throw new HttpException(400, 'No file provided');
    }

    if (!this.allowedMimeTypes.includes(file.mimetype)) {
      throw new HttpException(400, 'Invalid file type. Only JPEG, PNG and WebP are allowed');
    }

    if (file.size > this.maxFileSize) {
      throw new HttpException(400, 'File size exceeds 5MB limit');
    }
  }

  async optimizeImage(buffer) {
    // Create different sizes for responsive loading
    const sizes = {
      thumbnail: 150,
      medium: 300,
      large: 600,
    };

    const optimizedImages = {};

    for (const [size, width] of Object.entries(sizes)) {
      optimizedImages[size] = await sharp(buffer)
        .resize(width, width, {
          fit: 'cover',
          position: 'center',
        })
        .webp({ quality: 80 })
        .toBuffer();
    }

    return optimizedImages;
  }

  async uploadAvatar(userId, imageBuffer) {
    const optimizedImages = await this.optimizeImage(imageBuffer);
    const avatarId = uuidv4();
    const urls = {};

    for (const [size, buffer] of Object.entries(optimizedImages)) {
      const fileName = `avatars/${userId}/${avatarId}-${size}.webp`;
      const file = bucket.file(fileName);
      
      await file.save(buffer, {
        metadata: {
          contentType: 'image/webp',
          cacheControl: 'public, max-age=31536000',
        },
      });

      urls[size] = await generateDownloadUrl(fileName);
    }

    return {
      avatarId,
      urls,
    };
  }

  async deleteAvatar(userId, avatarId) {
    const sizes = ['thumbnail', 'medium', 'large'];
    const deletionPromises = sizes.map(size => {
      const fileName = `avatars/${userId}/${avatarId}-${size}.webp`;
      return deleteFile(fileName).catch(err => {
        console.error(`Failed to delete ${fileName}:`, err);
      });
    });

    await Promise.all(deletionPromises);
  }

  async getUploadUrl(userId, contentType) {
    if (!this.allowedMimeTypes.includes(contentType)) {
      throw new HttpException(400, 'Invalid content type');
    }

    const fileName = `tmp/${userId}/${uuidv4()}`;
    return generateUploadUrl(fileName, contentType);
  }
}

module.exports = new AvatarService();
