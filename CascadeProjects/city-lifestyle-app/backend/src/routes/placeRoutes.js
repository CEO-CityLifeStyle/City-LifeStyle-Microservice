const express = require('express');
const { 
  getPlaces,
  getPlace,
  createPlace,
  updatePlace,
  deletePlace,
  toggleFavorite,
  searchNearby,
} = require('../controllers/placeController');
const auth = require('../middleware/auth');

const router = express.Router();

/**
 * @swagger
 * components:
 *   schemas:
 *     Place:
 *       type: object
 *       required:
 *         - name
 *         - location
 *         - category
 *       properties:
 *         _id:
 *           type: string
 *           description: Auto-generated MongoDB ID
 *         name:
 *           type: string
 *           description: Name of the place
 *         description:
 *           type: string
 *           description: Detailed description of the place
 *         location:
 *           type: object
 *           properties:
 *             type:
 *               type: string
 *               enum: [Point]
 *             coordinates:
 *               type: array
 *               items:
 *                 type: number
 *               minItems: 2
 *               maxItems: 2
 *         category:
 *           type: string
 *           enum: [restaurant, cafe, park, museum, shopping]
 *         rating:
 *           type: number
 *           minimum: 0
 *           maximum: 5
 *         images:
 *           type: array
 *           items:
 *             type: string
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 */

/**
 * @swagger
 * /api/places:
 *   get:
 *     summary: Get all places
 *     description: Retrieve a list of all places with optional filtering
 *     tags: [Places]
 *     parameters:
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *         description: Filter by place category
 *       - in: query
 *         name: rating
 *         schema:
 *           type: number
 *         description: Filter by minimum rating
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: Number of places to return
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number for pagination
 *     responses:
 *       200:
 *         description: List of places
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 places:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Place'
 *                 total:
 *                   type: integer
 *                 page:
 *                   type: integer
 *                 pages:
 *                   type: integer
 *       500:
 *         description: Server error
 */
router.get('/', getPlaces);

/**
 * @swagger
 * /api/places/nearby:
 *   get:
 *     summary: Search nearby places
 *     description: Find places near a specific location
 *     tags: [Places]
 *     parameters:
 *       - in: query
 *         name: lat
 *         required: true
 *         schema:
 *           type: number
 *         description: Latitude of the center point
 *       - in: query
 *         name: lng
 *         required: true
 *         schema:
 *           type: number
 *         description: Longitude of the center point
 *       - in: query
 *         name: radius
 *         schema:
 *           type: number
 *           default: 5000
 *         description: Search radius in meters
 *     responses:
 *       200:
 *         description: List of nearby places
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Place'
 *       400:
 *         description: Invalid coordinates
 *       500:
 *         description: Server error
 */
router.get('/nearby', searchNearby);

/**
 * @swagger
 * /api/places/{id}:
 *   get:
 *     summary: Get a place by ID
 *     description: Retrieve detailed information about a specific place
 *     tags: [Places]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Place ID
 *     responses:
 *       200:
 *         description: Place details
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Place'
 *       404:
 *         description: Place not found
 *       500:
 *         description: Server error
 */
router.get('/:id', getPlace);

/**
 * @swagger
 * /api/places:
 *   post:
 *     summary: Create a new place
 *     description: Add a new place to the database
 *     tags: [Places]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - location
 *               - category
 *             properties:
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *               location:
 *                 type: object
 *                 properties:
 *                   type:
 *                     type: string
 *                     enum: [Point]
 *                   coordinates:
 *                     type: array
 *                     items:
 *                       type: number
 *               category:
 *                 type: string
 *                 enum: [restaurant, cafe, park, museum, shopping]
 *               images:
 *                 type: array
 *                 items:
 *                   type: string
 *     responses:
 *       201:
 *         description: Place created successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Place'
 *       400:
 *         description: Invalid input data
 *       401:
 *         description: Unauthorized
 *       500:
 *         description: Server error
 */
router.post('/', auth, createPlace);

/**
 * @swagger
 * /api/places/{id}:
 *   put:
 *     summary: Update a place
 *     description: Modify an existing place
 *     tags: [Places]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Place ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Place'
 *     responses:
 *       200:
 *         description: Place updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Place'
 *       400:
 *         description: Invalid input data
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Place not found
 *       500:
 *         description: Server error
 */
router.put('/:id', auth, updatePlace);

/**
 * @swagger
 * /api/places/{id}:
 *   delete:
 *     summary: Delete a place
 *     description: Remove a place from the database
 *     tags: [Places]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Place ID
 *     responses:
 *       200:
 *         description: Place deleted successfully
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Place not found
 *       500:
 *         description: Server error
 */
router.delete('/:id', auth, deletePlace);

/**
 * @swagger
 * /api/places/{id}/favorite:
 *   post:
 *     summary: Toggle favorite status
 *     description: Add or remove a place from user's favorites
 *     tags: [Places]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Place ID
 *     responses:
 *       200:
 *         description: Favorite status toggled successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 isFavorite:
 *                   type: boolean
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Place not found
 *       500:
 *         description: Server error
 */
router.post('/:id/favorite', auth, toggleFavorite);

module.exports = router;
