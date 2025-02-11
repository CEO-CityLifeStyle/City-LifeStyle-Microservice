const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { withTransaction } = require('../utils/db');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
    minlength: 2,
    maxlength: 50,
  },
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
  },
  password: {
    type: String,
    required: true,
    minlength: 6
  },
  bio: {
    type: String,
    trim: true,
    maxlength: 500
  },
  avatar: {
    thumbnail: String,
    medium: String,
    large: String,
  },
  avatarId: String,
  privacy: {
    profileVisibility: {
      type: String,
      enum: ['public', 'private', 'friends'],
      default: 'public',
    },
    activityVisibility: {
      type: String,
      enum: ['public', 'private', 'friends'],
      default: 'public',
    },
    emailVisibility: {
      type: String,
      enum: ['public', 'private', 'friends'],
      default: 'private',
    },
  },
  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user'
  },
  isVerified: {
    type: Boolean,
    default: false,
  },
  lastActive: {
    type: Date,
    default: Date.now,
  },
  favoritePlaces: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Place'
  }],
  favoriteEvents: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Event'
  }],
  reviews: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Review'
  }],
  reviewStats: {
    totalReviews: {
      type: Number,
      default: 0
    },
    averageRating: {
      type: Number,
      default: 0
    }
  }
}, {
  timestamps: true
});

// Update review stats
userSchema.methods.updateReviewStats = async function() {
  return withTransaction(async (session) => {
    const user = await this.constructor.findById(this._id).session(session);
    const Review = mongoose.model('Review');
    
    if (!user.reviews || user.reviews.length === 0) {
      user.reviewStats = {
        totalReviews: 0,
        averageRating: 0
      };
      await user.save({ session });
      return user;
    }

    const reviewIds = user.reviews.map(id => new mongoose.Types.ObjectId(id));
    const stats = await Review.aggregate([
      {
        $match: {
          _id: { $in: reviewIds }
        }
      },
      {
        $group: {
          _id: null,
          totalReviews: { $sum: 1 },
          averageRating: { $avg: '$rating' }
        }
      }
    ]).exec();

    if (stats.length > 0) {
      user.reviewStats = {
        totalReviews: stats[0].totalReviews,
        averageRating: stats[0].averageRating
      };
    } else {
      user.reviewStats = {
        totalReviews: 0,
        averageRating: 0
      };
    }

    await user.save({ session });
    return user;
  });
};

// Add review
userSchema.methods.addReview = async function(reviewId) {
  return withTransaction(async (session) => {
    const user = await this.constructor.findById(this._id).session(session);
    if (!user.reviews.includes(reviewId)) {
      user.reviews.push(reviewId);
      await user.save({ session });
      await user.updateReviewStats();
    }
    return user;
  });
};

// Remove review
userSchema.methods.removeReview = async function(reviewId) {
  return withTransaction(async (session) => {
    const user = await this.constructor.findById(this._id).session(session);
    user.reviews = user.reviews.filter(id => !id.equals(reviewId));
    await user.save({ session });
    await user.updateReviewStats();
    return user;
  });
};

// Get reviews with pagination
userSchema.methods.getReviews = async function({ skip = 0, limit = 10 } = {}) {
  const Review = mongoose.model('Review');
  const reviews = await Review.find({
    _id: { $in: this.reviews }
  })
  .sort({ createdAt: -1 })
  .skip(skip)
  .limit(limit)
  .populate('place');
  
  return reviews;
};

// Add to favorites
userSchema.methods.addToFavorites = async function(placeId) {
  if (!this.favoritePlaces.includes(placeId)) {
    this.favoritePlaces.push(placeId);
    await this.save();
  }
  return this;
};

// Remove from favorites
userSchema.methods.removeFromFavorites = async function(placeId) {
  this.favoritePlaces = this.favoritePlaces.filter(id => !id.equals(placeId));
  await this.save();
  return this;
};

// Add event to favorites
userSchema.methods.addEventToFavorites = async function(eventId) {
  if (!this.favoriteEvents.includes(eventId)) {
    this.favoriteEvents.push(eventId);
    await this.save();
  }
  return this;
};

// Remove event from favorites
userSchema.methods.removeEventFromFavorites = async function(eventId) {
  this.favoriteEvents = this.favoriteEvents.filter(id => !id.equals(eventId));
  await this.save();
  return this;
};

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Compare password
userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Update lastActive timestamp
userSchema.methods.updateLastActive = function () {
  this.lastActive = new Date();
  return this.save();
};

// Generate auth token
userSchema.methods.generateAuthToken = function() {
  return jwt.sign(
    { _id: this._id.toString(), role: this.role },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );
};

// Remove sensitive info when converting to JSON
userSchema.methods.toJSON = function() {
  const user = this.toObject();
  delete user.password;
  return user;
};

const User = mongoose.model('User', userSchema);

module.exports = User;
