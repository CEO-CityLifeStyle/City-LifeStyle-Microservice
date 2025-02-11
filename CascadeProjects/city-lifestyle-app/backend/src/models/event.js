const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true,
  },
  description: {
    type: String,
    required: true,
  },
  startDate: {
    type: Date,
    required: true,
  },
  endDate: {
    type: Date,
    required: true,
  },
  category: {
    type: String,
    required: true,
    enum: ['music', 'sports', 'art', 'food', 'festival', 'education', 'other'],
  },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      required: true,
    },
    coordinates: {
      type: [Number],
      required: true,
    },
    address: {
      type: String,
      required: true,
    },
  },
  place: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Place',
  },
  images: [{
    type: String,
  }],
  price: {
    amount: {
      type: Number,
      default: 0,
    },
    currency: {
      type: String,
      default: 'SAR',
    },
  },
  capacity: {
    type: Number,
  },
  registeredUsers: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    registeredAt: {
      type: Date,
      default: Date.now,
    },
    status: {
      type: String,
      enum: ['registered', 'waitlist', 'cancelled'],
      default: 'registered',
    },
  }],
  organizer: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  status: {
    type: String,
    enum: ['draft', 'published', 'cancelled'],
    default: 'published',
  },
  tags: [{
    type: String,
  }],
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

// Create a 2dsphere index for location-based queries
eventSchema.index({ location: '2dsphere' });

// Update timestamps
eventSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

// Virtual for checking if event is full
eventSchema.virtual('isFull').get(function() {
  if (!this.capacity) return false;
  return this.registeredUsers.filter(r => r.status === 'registered').length >= this.capacity;
});

// Virtual for number of available spots
eventSchema.virtual('availableSpots').get(function() {
  if (!this.capacity) return null;
  const registeredCount = this.registeredUsers.filter(r => r.status === 'registered').length;
  return Math.max(0, this.capacity - registeredCount);
});

// Virtual for checking if event has ended
eventSchema.virtual('hasEnded').get(function() {
  return new Date() > this.endDate;
});

// Method to register a user for the event
eventSchema.methods.registerUser = async function(userId) {
  if (this.hasEnded) {
    throw new Error('Event has already ended');
  }

  const existingRegistration = this.registeredUsers.find(
    r => r.user.toString() === userId.toString()
  );

  if (existingRegistration) {
    throw new Error('User is already registered for this event');
  }

  const status = this.isFull ? 'waitlist' : 'registered';
  this.registeredUsers.push({ user: userId, status });
  await this.save();
  return status;
};

// Method to cancel user registration
eventSchema.methods.cancelRegistration = async function(userId) {
  const registration = this.registeredUsers.find(
    r => r.user.toString() === userId.toString()
  );

  if (!registration) {
    throw new Error('User is not registered for this event');
  }

  registration.status = 'cancelled';

  // If there's a waitlist and a spot opened up, move someone from waitlist to registered
  if (this.capacity) {
    const waitlistedUser = this.registeredUsers.find(r => r.status === 'waitlist');
    if (waitlistedUser) {
      waitlistedUser.status = 'registered';
    }
  }

  await this.save();
};

const Event = mongoose.model('Event', eventSchema);

module.exports = Event;
