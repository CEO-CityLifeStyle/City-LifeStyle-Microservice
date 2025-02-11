const Place = require('../models/place');
const User = require('../models/user');
const geocodingService = require('../services/geocodingService');

// Get all places with filtering and pagination
const getPlaces = async (req, res) => {
  try {
    const {
      category,
      search,
      near,
      radius = 5000,
      rating,
      openNow,
      page = 1,
      limit = 10,
      sort = 'rating',
    } = req.query;

    const query = {};

    // Category filter
    if (category) {
      query.category = category;
    }

    // Search filter
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
      ];
    }

    // Rating filter
    if (rating) {
      query.rating = { $gte: parseFloat(rating) };
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
          $maxDistance: parseInt(radius),
        },
      };
    }

    // Open now filter
    if (openNow === 'true') {
      const now = new Date();
      const day = now.getDay();
      const time = now.toTimeString().slice(0, 5);
      
      query[`openingHours.${day}.isOpen`] = true;
      query[`openingHours.${day}.open`] = { $lte: time };
      query[`openingHours.${day}.close`] = { $gte: time };
    }

    // Build sort object
    const sortObj = {};
    if (sort === 'rating') {
      sortObj.rating = -1;
    } else if (sort === 'distance' && near) {
      // MongoDB will automatically sort by distance when using $near
    } else {
      sortObj.createdAt = -1;
    }

    const places = await Place.find(query)
      .populate('createdBy', 'name avatar')
      .skip((page - 1) * limit)
      .limit(limit)
      .sort(sortObj);

    // If near coordinates provided, calculate distance for each place
    if (near) {
      const [lng, lat] = near.split(',').map(Number);
      places.forEach(place => {
        const [placeLng, placeLat] = place.location.coordinates;
        place._doc.distance = calculateDistance(lat, lng, placeLat, placeLng);
      });
    }

    res.json(places.map(place => place.toObject()));
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Get single place
const getPlace = async (req, res) => {
  try {
    if (!req.params.id.match(/^[0-9a-fA-F]{24}$/)) {
      return res.status(400).json({ error: 'Invalid place ID' });
    }

    const place = await Place.findById(req.params.id)
      .populate('createdBy', 'name avatar');

    if (!place) {
      return res.status(404).json({ error: 'Place not found' });
    }

    // If near coordinates provided, calculate distance
    const { near } = req.query;
    if (near) {
      const [lng, lat] = near.split(',').map(Number);
      const [placeLng, placeLat] = place.location.coordinates;
      place._doc.distance = calculateDistance(lat, lng, placeLat, placeLng);
    }

    res.json(place.toObject());
  } catch (error) {
    if (error.name === 'CastError') {
      return res.status(400).json({ error: 'Invalid place ID' });
    }
    res.status(500).json({ error: 'Server error' });
  }
};

// Create new place
const createPlace = async (req, res) => {
  try {
    // Geocode the address if provided
    if (req.body.address && !req.body.location) {
      const geoData = await geocodingService.geocodeAddress(req.body.address);
      req.body.location = geoData.coordinates;
      req.body.formattedAddress = geoData.formattedAddress;
    }

    const place = new Place({
      ...req.body,
      createdBy: req.user._id,
    });

    await place.save();
    res.status(201).json(place.toObject());
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Update place
const updatePlace = async (req, res) => {
  const updates = Object.keys(req.body);
  const allowedUpdates = [
    'name',
    'description',
    'category',
    'address',
    'location',
    'images',
    'openingHours',
    'contact',
    'amenities',
    'tags',
  ];

  const isValidOperation = updates.every((update) =>
    allowedUpdates.includes(update)
  );

  if (!isValidOperation) {
    return res.status(400).json({ error: 'Invalid updates' });
  }

  try {
    if (!req.params.id.match(/^[0-9a-fA-F]{24}$/)) {
      return res.status(400).json({ error: 'Invalid place ID' });
    }

    // Geocode new address if provided
    if (req.body.address) {
      const geoData = await geocodingService.geocodeAddress(req.body.address);
      req.body.location = geoData.coordinates;
      req.body.formattedAddress = geoData.formattedAddress;
    }

    const place = await Place.findOne({
      _id: req.params.id,
    });

    if (!place) {
      return res.status(404).json({ error: 'Place not found' });
    }

    if (place.createdBy.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: 'Not authorized to update this place' });
    }

    updates.forEach((update) => {
      place[update] = req.body[update];
    });

    await place.save();
    res.json(place.toObject());
  } catch (error) {
    if (error.name === 'CastError') {
      return res.status(400).json({ error: 'Invalid place ID' });
    }
    if (error.name === 'ValidationError') {
      return res.status(400).json({ error: error.message });
    }
    res.status(500).json({ error: 'Server error' });
  }
};

// Delete place
const deletePlace = async (req, res) => {
  try {
    const place = await Place.findOne({
      _id: req.params.id,
    });

    if (!place) {
      return res.status(404).json({ error: 'Place not found' });
    }

    if (place.createdBy.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: 'Not authorized to delete this place' });
    }

    await Place.findByIdAndDelete(place._id);
    res.json(place.toObject());
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Toggle place favorite status
const toggleFavorite = async (req, res) => {
  try {
    const place = await Place.findById(req.params.id);

    if (!place) {
      return res.status(404).json({ error: 'Place not found' });
    }

    const user = await User.findById(req.user._id);
    const isFavorite = user.favoritePlaces.includes(place._id);

    if (isFavorite) {
      await user.removeFromFavorites(place._id);
      res.json({ isFavorite: false });
    } else {
      await user.addToFavorites(place._id);
      res.json({ isFavorite: true });
    }
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Search nearby places using Google Places API
const searchNearby = async (req, res) => {
  try {
    const { lat, lng, radius, type } = req.query;
    const places = await geocodingService.searchNearby(lat, lng, radius, type);
    res.json(places);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Helper function to calculate distance between two points in kilometers
const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371; // Earth's radius in kilometers
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

const toRad = (value) => {
  return (value * Math.PI) / 180;
};

module.exports = {
  getPlaces,
  getPlace,
  createPlace,
  updatePlace,
  deletePlace,
  toggleFavorite,
  searchNearby,
};
