const Event = require('../models/event');
const User = require('../models/user');

// Get all events with filtering and pagination
const getEvents = async (req, res) => {
  try {
    const {
      category,
      search,
      near,
      radius = 5000,
      startDate,
      endDate,
      status = 'published',
      page = 1,
      limit = 10,
    } = req.query;

    const query = { status };

    // Category filter
    if (category) {
      query.category = category;
    }

    // Search filter
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
      ];
    }

    // Date filter
    if (startDate || endDate) {
      query.startDate = {};
      if (startDate) query.startDate.$gte = new Date(startDate);
      if (endDate) query.startDate.$lte = new Date(endDate);
    }

    // Location filter
    if (near) {
      const [lng, lat] = near.split(',').map(Number);
      query.location = {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [lng, lat],
          },
          $maxDistance: radius,
        },
      };
    }

    const events = await Event.find(query)
      .populate('organizer', 'name avatar')
      .populate('place', 'name location')
      .skip((page - 1) * limit)
      .limit(limit)
      .sort('startDate');

    const total = await Event.countDocuments(query);

    res.json({
      events,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      total,
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Get single event by ID
const getEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)
      .populate('organizer', 'name avatar')
      .populate('place', 'name location')
      .populate('registeredUsers.user', 'name avatar');

    if (!event) {
      return res.status(404).json({ error: 'Event not found' });
    }

    res.json(event);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Create new event
const createEvent = async (req, res) => {
  try {
    const event = new Event({
      ...req.body,
      organizer: req.user._id,
    });

    await event.save();
    res.status(201).json(event);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Update event
const updateEvent = async (req, res) => {
  const updates = Object.keys(req.body);
  const allowedUpdates = [
    'title',
    'description',
    'startDate',
    'endDate',
    'category',
    'location',
    'place',
    'images',
    'price',
    'capacity',
    'status',
    'tags',
  ];
  const isValidOperation = updates.every((update) =>
    allowedUpdates.includes(update)
  );

  if (!isValidOperation) {
    return res.status(400).json({ error: 'Invalid updates' });
  }

  try {
    const event = await Event.findOne({
      _id: req.params.id,
      organizer: req.user._id,
    });

    if (!event) {
      return res.status(404).json({ error: 'Event not found' });
    }

    updates.forEach((update) => {
      event[update] = req.body[update];
    });

    await event.save();
    res.json(event);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Delete event
const deleteEvent = async (req, res) => {
  try {
    const event = await Event.findOneAndDelete({
      _id: req.params.id,
      organizer: req.user._id,
    });

    if (!event) {
      return res.status(404).json({ error: 'Event not found' });
    }

    res.json(event);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Register for event
const registerForEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);

    if (!event) {
      return res.status(404).json({ error: 'Event not found' });
    }

    const status = await event.registerUser(req.user._id);
    res.json({ status });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Cancel event registration
const cancelRegistration = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);

    if (!event) {
      return res.status(404).json({ error: 'Event not found' });
    }

    await event.cancelRegistration(req.user._id);
    res.json({ message: 'Registration cancelled successfully' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Toggle event favorite status
const toggleFavorite = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);

    if (!event) {
      return res.status(404).json({ error: 'Event not found' });
    }

    const user = await User.findById(req.user._id);
    const isFavorite = user.favoriteEvents.includes(event._id);

    if (isFavorite) {
      await user.removeEventFromFavorites(event._id);
      res.json({ isFavorite: false });
    } else {
      await user.addEventToFavorites(event._id);
      res.json({ isFavorite: true });
    }
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

module.exports = {
  getEvents,
  getEvent,
  createEvent,
  updateEvent,
  deleteEvent,
  registerForEvent,
  cancelRegistration,
  toggleFavorite,
};
