const mongoose = require('mongoose');
const Review = require('./review');
const { withTransaction } = require('../utils/db');

const placeSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  address: {
    type: String,
    required: true
  },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      required: true
    },
    coordinates: {
      type: [Number],
      required: true
    }
  },
  category: {
    type: String,
    required: true,
    enum: ['restaurant', 'cafe', 'bar', 'park', 'museum', 'shopping', 'hotel', 'other']
  },
  rating: {
    type: Number,
    min: 0,
    max: 5,
    default: 0
  },
  reviews: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Review'
  }],
  photos: [{
    type: String
  }],
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  openingHours: {
    monday: {
      open: String,
      close: String
    },
    tuesday: {
      open: String,
      close: String
    },
    wednesday: {
      open: String,
      close: String
    },
    thursday: {
      open: String,
      close: String
    },
    friday: {
      open: String,
      close: String
    }
  },
  amenities: [{
    type: String,
    enum: ['wifi', 'parking', 'outdoor_seating', 'delivery', 'takeout', 'reservations', 'wheelchair_accessible']
  }],
  priceRange: {
    type: String,
    enum: ['budget', 'moderate', 'expensive', 'luxury']
  },
  contactInfo: {
    phone: String,
    email: String,
    website: String
  }
}, {
  timestamps: true
});

// Update rating when reviews change
placeSchema.methods.updateRating = async function() {
  const { withTransaction } = require('../utils/db');

  return withTransaction(async (session) => {
    // Reload the place to get the latest state
    const place = await this.constructor.findById(this._id).session(session);
    
    if (!place.reviews || place.reviews.length === 0) {
      place.rating = 0;
      await place.save({ session });
      return place;
    }

    const stats = await Review.aggregate([
      { 
        $match: { 
          _id: { $in: place.reviews.map(id => new mongoose.Types.ObjectId(id)) } 
        } 
      },
      { 
        $group: {
          _id: null,
          averageRating: { $avg: '$rating' }
        } 
      }
    ]);

    if (stats.length > 0) {
      place.rating = stats[0].averageRating;
    } else {
      place.rating = 0;
    }

    await place.save({ session });
    return place;
  });
};

// Add review
placeSchema.methods.addReview = async function(reviewId) {
  const { withTransaction } = require('../utils/db');

  return withTransaction(async (session) => {
    // Reload the place to get the latest state
    const place = await this.constructor.findById(this._id).session(session);
    if (!place.reviews.includes(reviewId)) {
      place.reviews.push(reviewId);
      await place.save({ session });
      await place.updateRating();
    }
    return place;
  });
};

// Remove review
placeSchema.methods.removeReview = async function(reviewId) {
  const { withTransaction } = require('../utils/db');

  return withTransaction(async (session) => {
    // Reload the place to get the latest state
    const place = await this.constructor.findById(this._id).session(session);
    place.reviews = place.reviews.filter(id => !id.equals(reviewId));
    await place.save({ session });
    await place.updateRating();
    return place;
  });
};

// Create geospatial index on location
placeSchema.index({ location: '2dsphere' });

const Place = mongoose.model('Place', placeSchema);

module.exports = Place;
