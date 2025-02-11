const mongoose = require('mongoose');
const { PlaceService } = require('../../../src/services/place-service');
const Place = require('../../../src/models/place');
const { createTestPlaces, generateObjectId } = require('../../utils/test-utils');

describe('PlaceService', () => {
  const placeService = new PlaceService();
  const userId = generateObjectId();

  describe('createPlace', () => {
    it('should create a new place', async () => {
      const placeData = createTestPlaces(1, userId)[0];
      const place = await placeService.createPlace(placeData, userId);

      expect(place).toBeTruthy();
      expect(place.name).toBe(placeData.name);
      expect(place.description).toBe(placeData.description);
      expect(place.category).toBe(placeData.category);
      expect(place.createdBy.toString()).toBe(userId);

      const savedPlace = await Place.findById(place._id);
      expect(savedPlace).toBeTruthy();
    });

    it('should validate required fields', async () => {
      const invalidPlace = {};
      await expect(placeService.createPlace(invalidPlace, userId))
        .rejects.toThrow();
    });
  });

  describe('updatePlace', () => {
    it('should update place fields', async () => {
      const place = await Place.create(createTestPlaces(1, userId)[0]);

      const updateData = {
        name: 'Updated Place Name',
        description: 'Updated description'
      };

      const updatedPlace = await placeService.updatePlace(place._id, updateData, userId);
      expect(updatedPlace.name).toBe(updateData.name);
      expect(updatedPlace.description).toBe(updateData.description);
    });

    it('should not update place if user is not owner', async () => {
      const otherUserId = generateObjectId();
      const place = await Place.create(createTestPlaces(1, otherUserId)[0]);

      const updateData = { name: 'Updated Name' };

      await expect(placeService.updatePlace(place._id, updateData, userId))
        .rejects.toThrow('Not authorized to update this place');
    });
  });

  describe('getPlaces', () => {
    it('should get places with filters', async () => {
      const testPlaces = [
        { ...createTestPlaces(1, userId)[0], category: 'restaurant' },
        { ...createTestPlaces(1, userId)[0], category: 'restaurant' },
        { ...createTestPlaces(1, userId)[0], category: 'cafe' }
      ];
      await Place.insertMany(testPlaces);

      const places = await placeService.getPlaces({ category: 'restaurant' });
      expect(places).toHaveLength(2);
      expect(places[0].category).toBe('restaurant');
    });

    it('should sort places by rating', async () => {
      const testPlaces = [
        { ...createTestPlaces(1, userId)[0], rating: 3.5 },
        { ...createTestPlaces(1, userId)[0], rating: 4.5 },
        { ...createTestPlaces(1, userId)[0], rating: 4.0 }
      ];
      await Place.insertMany(testPlaces);

      const places = await placeService.getPlaces({}, { sort: '-rating' });
      expect(places[0].rating).toBe(4.5);
      expect(places[1].rating).toBe(4.0);
      expect(places[2].rating).toBe(3.5);
    });
  });

  describe('deletePlace', () => {
    it('should delete place', async () => {
      const place = await Place.create(createTestPlaces(1, userId)[0]);

      await placeService.deletePlace(place._id, userId);
      const deletedPlace = await Place.findById(place._id);
      expect(deletedPlace).toBeNull();
    });

    it('should not delete place if user is not owner', async () => {
      const otherUserId = generateObjectId();
      const place = await Place.create(createTestPlaces(1, otherUserId)[0]);

      await expect(placeService.deletePlace(place._id, userId))
        .rejects.toThrow('Not authorized to delete this place');
    });
  });
});
