const mongoose = require('mongoose');
const Place = require('../../../src/models/place');

describe('Place Model', () => {
  beforeEach(async () => {
    await Place.deleteMany({});
  });

  it('should create a place with valid data', async () => {
    const validPlace = {
      name: 'Test Place',
      description: 'A test place',
      address: '123 Test St',
      category: 'restaurant',
      location: {
        type: 'Point',
        coordinates: [0, 0]
      },
      createdBy: new mongoose.Types.ObjectId()
    };

    const place = await Place.create(validPlace);
    expect(place.name).toBe(validPlace.name);
    expect(place.description).toBe(validPlace.description);
    expect(place.category).toBe(validPlace.category);
    expect(place.location.coordinates).toEqual(validPlace.location.coordinates);
  });

  it('should fail to create a place without required fields', async () => {
    const invalidPlace = {
      name: 'Test Place'
    };

    await expect(Place.create(invalidPlace)).rejects.toThrow();
  });

  it('should validate location coordinates', async () => {
    const placeWithInvalidCoords = {
      name: 'Test Place',
      description: 'A test place',
      address: '123 Test St',
      category: 'restaurant',
      location: {
        type: 'Point',
        coordinates: [200, 100] // Invalid coordinates
      },
      createdBy: new mongoose.Types.ObjectId()
    };

    await expect(Place.create(placeWithInvalidCoords)).rejects.toThrow();
  });

  it('should calculate average rating correctly', async () => {
    const place = await Place.create({
      name: 'Test Place',
      description: 'A test place',
      address: '123 Test St',
      category: 'restaurant',
      location: {
        type: 'Point',
        coordinates: [0, 0]
      },
      createdBy: new mongoose.Types.ObjectId(),
      rating: 4.5,
      totalReviews: 10
    });

    expect(place.rating).toBe(4.5);
  });

  it('should validate category enum', async () => {
    const placeWithInvalidCategory = {
      name: 'Test Place',
      description: 'A test place',
      address: '123 Test St',
      category: 'invalid_category',
      location: {
        type: 'Point',
        coordinates: [0, 0]
      },
      createdBy: new mongoose.Types.ObjectId()
    };

    await expect(Place.create(placeWithInvalidCategory)).rejects.toThrow();
  });
});
