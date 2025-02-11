const express = require('express');
const {
  getEvents,
  getEvent,
  createEvent,
  updateEvent,
  deleteEvent,
  registerForEvent,
  cancelRegistration,
  toggleFavorite,
} = require('../controllers/eventController');
const auth = require('../middleware/auth');

const router = express.Router();

// Public routes
router.get('/', getEvents);
router.get('/:id', getEvent);

// Protected routes
router.post('/', auth, createEvent);
router.put('/:id', auth, updateEvent);
router.delete('/:id', auth, deleteEvent);
router.post('/:id/register', auth, registerForEvent);
router.post('/:id/cancel', auth, cancelRegistration);
router.post('/:id/favorite', auth, toggleFavorite);

module.exports = router;
