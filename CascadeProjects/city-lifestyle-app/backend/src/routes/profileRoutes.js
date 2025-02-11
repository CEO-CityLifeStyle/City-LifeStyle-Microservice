const express = require('express');
const multer = require('multer');
const router = express.Router();
const profileController = require('../controllers/profileController');
const { authenticate } = require('../middleware/auth');
const { asyncHandler } = require('../utils/asyncHandler');
const rateLimit = require('express-rate-limit');

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
});

// Rate limiting configuration
const profileUpdateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // limit each IP to 10 requests per windowMs
  message: 'Too many profile updates, please try again later',
});

const avatarUploadLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5, // limit each IP to 5 avatar uploads per hour
  message: 'Too many avatar uploads, please try again later',
});

// Profile routes
router.get(
  '/profile',
  authenticate,
  asyncHandler(profileController.getProfile)
);

router.put(
  '/profile',
  authenticate,
  profileUpdateLimiter,
  asyncHandler(profileController.updateProfile)
);

// Avatar routes
router.post(
  '/profile/avatar',
  authenticate,
  avatarUploadLimiter,
  upload.single('avatar'),
  asyncHandler(profileController.updateAvatar)
);

router.delete(
  '/profile/avatar',
  authenticate,
  asyncHandler(profileController.deleteAvatar)
);

// Privacy routes
router.get(
  '/profile/privacy',
  authenticate,
  asyncHandler(profileController.getPrivacySettings)
);

router.put(
  '/profile/privacy',
  authenticate,
  profileUpdateLimiter,
  asyncHandler(profileController.updatePrivacySettings)
);

// Stats route
router.get(
  '/profile/stats',
  authenticate,
  asyncHandler(async (req, res) => {
    const stats = await profileController.getUserStats(req.user.id);
    res.json(stats);
  })
);

module.exports = router;
