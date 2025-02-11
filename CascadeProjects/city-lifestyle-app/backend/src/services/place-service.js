const Place = require('../models/place');

class PlaceService {
  async createPlace(placeData, userId) {
    const place = new Place({
      ...placeData,
      createdBy: userId
    });
    return await place.save();
  }

  async updatePlace(placeId, updateData, userId) {
    const place = await Place.findById(placeId);
    if (!place) {
      throw new Error('Place not found');
    }

    if (place.createdBy.toString() !== userId) {
      throw new Error('Not authorized to update this place');
    }

    Object.assign(place, updateData);
    return await place.save();
  }

  async getPlaces(filters = {}, options = {}) {
    return await Place.find(filters)
      .sort(options.sort || '-createdAt')
      .limit(options.limit || 50)
      .skip(options.skip || 0);
  }

  async getPlaceById(placeId) {
    const place = await Place.findById(placeId);
    if (!place) {
      throw new Error('Place not found');
    }
    return place;
  }

  async deletePlace(placeId, userId) {
    const place = await Place.findById(placeId);
    if (!place) {
      throw new Error('Place not found');
    }

    if (place.createdBy.toString() !== userId) {
      throw new Error('Not authorized to delete this place');
    }

    await place.deleteOne();
    return place;
  }
}

module.exports = { PlaceService };
