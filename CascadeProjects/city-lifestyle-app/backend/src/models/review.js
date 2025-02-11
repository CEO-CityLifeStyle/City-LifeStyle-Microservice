const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  place: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Place',
    required: true,
  },
  rating: {
    type: Number,
    required: true,
    min: 1,
    max: 5,
  },
  comment: {
    type: String,
    required: true,
    trim: true,
    maxlength: 1000,
  },
  images: [{
    url: String,
    caption: String,
  }],
  likes: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  }],
  replies: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    comment: {
      type: String,
      required: true,
      trim: true,
      maxlength: 500,
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
  }],
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending',
  },
  flags: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    reason: {
      type: String,
      required: true,
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
  }],
  helpful: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
  }],
  visitDate: {
    type: Date,
  },
  categories: [{
    type: String,
    trim: true,
  }],
  verified: {
    type: Boolean,
    default: false,
  },
}, {
  timestamps: true,
});

// Indexes
reviewSchema.index({ place: 1, user: 1 }, { unique: true });
reviewSchema.index({ place: 1, createdAt: -1 });
reviewSchema.index({ rating: -1 });
reviewSchema.index({ status: 1 });

// Virtual for helpfulness score
reviewSchema.virtual('helpfulnessScore').get(function() {
  return this.helpful.length;
});

// Methods
reviewSchema.methods.like = async function(userId) {
  if (!this.likes.includes(userId)) {
    this.likes.push(userId);
    await this.save();
  }
};

reviewSchema.methods.unlike = async function(userId) {
  this.likes = this.likes.filter(id => !id.equals(userId));
  await this.save();
};

reviewSchema.methods.addReply = async function(userId, comment) {
  this.replies.push({ user: userId, comment });
  await this.save();
};

reviewSchema.methods.markHelpful = async function(userId) {
  if (!this.helpful.find(h => h.user.equals(userId))) {
    this.helpful.push({ user: userId });
    await this.save();
  }
};

reviewSchema.methods.flag = async function(userId, reason) {
  if (!this.flags.find(f => f.user.equals(userId))) {
    this.flags.push({ user: userId, reason });
    await this.save();
  }
};

// Statics
reviewSchema.statics.getAverageRating = async function(placeId) {
  const result = await this.aggregate([
    { $match: { place: placeId, status: 'approved' } },
    {
      $group: {
        _id: '$place',
        averageRating: { $avg: '$rating' },
        totalReviews: { $sum: 1 },
      },
    },
  ]);
  return result[0] || { averageRating: 0, totalReviews: 0 };
};

reviewSchema.statics.getTopReviews = async function(placeId, limit = 5) {
  return this.find({
    place: placeId,
    status: 'approved',
  })
    .sort('-helpful.length -createdAt')
    .limit(limit)
    .populate('user', 'name avatar')
    .select('-flags');
};

const Review = mongoose.model('Review', reviewSchema);

module.exports = Review;
