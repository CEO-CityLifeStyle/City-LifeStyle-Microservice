const axios = require('axios');

class GeocodingService {
  constructor() {
    this.apiKey = process.env.GOOGLE_MAPS_API_KEY;
    this.baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
  }

  async geocodeAddress(address) {
    // Return mock data in test environment
    if (process.env.NODE_ENV === 'test') {
      return {
        coordinates: {
          type: 'Point',
          coordinates: [-74.0060, 40.7128], // New York coordinates
        },
        formattedAddress: '123 Test St, New York, NY 10001',
        placeId: 'test_place_id',
        components: []
      };
    }

    try {
      const response = await axios.get(this.baseUrl, {
        params: {
          address,
          key: this.apiKey,
        },
      });

      if (response.data.status !== 'OK') {
        throw new Error(`Geocoding failed: ${response.data.status}`);
      }

      const result = response.data.results[0];
      return {
        coordinates: {
          type: 'Point',
          coordinates: [
            result.geometry.location.lng,
            result.geometry.location.lat,
          ],
        },
        formattedAddress: result.formatted_address,
        placeId: result.place_id,
        components: result.address_components,
      };
    } catch (error) {
      throw new Error(`Geocoding error: ${error.message}`);
    }
  }

  async reverseGeocode(lat, lng) {
    // Return mock data in test environment
    if (process.env.NODE_ENV === 'test') {
      return {
        formattedAddress: '123 Test St, New York, NY 10001',
        placeId: 'test_place_id',
        components: []
      };
    }

    try {
      const response = await axios.get(this.baseUrl, {
        params: {
          latlng: `${lat},${lng}`,
          key: this.apiKey,
        },
      });

      if (response.data.status !== 'OK') {
        throw new Error(`Reverse geocoding failed: ${response.data.status}`);
      }

      const result = response.data.results[0];
      return {
        formattedAddress: result.formatted_address,
        placeId: result.place_id,
        components: result.address_components,
      };
    } catch (error) {
      throw new Error(`Reverse geocoding error: ${error.message}`);
    }
  }

  async getPlaceDetails(placeId) {
    // Return mock data in test environment
    if (process.env.NODE_ENV === 'test') {
      return {
        name: 'Test Place',
        formatted_address: '123 Test St, New York, NY 10001',
        geometry: {
          location: {
            lat: 40.7128,
            lng: -74.0060
          }
        },
        type: ['restaurant'],
        business_status: 'OPERATIONAL'
      };
    }

    try {
      const response = await axios.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        {
          params: {
            place_id: placeId,
            key: this.apiKey,
            fields: 'name,formatted_address,geometry,type,business_status',
          },
        }
      );

      if (response.data.status !== 'OK') {
        throw new Error(`Place details failed: ${response.data.status}`);
      }

      return response.data.result;
    } catch (error) {
      throw new Error(`Place details error: ${error.message}`);
    }
  }

  async searchNearby(lat, lng, radius = 5000, type = '') {
    // Return mock data in test environment
    if (process.env.NODE_ENV === 'test') {
      return {
        results: [
          {
            name: 'Test Place 1',
            vicinity: '123 Test St, New York',
            geometry: {
              location: {
                lat: 40.7128,
                lng: -74.0060
              }
            },
            types: ['restaurant'],
            rating: 4.5
          },
          {
            name: 'Test Place 2',
            vicinity: '456 Test Ave, New York',
            geometry: {
              location: {
                lat: 40.7129,
                lng: -74.0061
              }
            },
            types: ['cafe'],
            rating: 4.0
          }
        ]
      };
    }

    try {
      const response = await axios.get(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
        {
          params: {
            location: `${lat},${lng}`,
            radius,
            type,
            key: this.apiKey,
          },
        }
      );

      if (response.data.status !== 'OK' && response.data.status !== 'ZERO_RESULTS') {
        throw new Error(`Nearby search failed: ${response.data.status}`);
      }

      return response.data;
    } catch (error) {
      throw new Error(`Nearby search error: ${error.message}`);
    }
  }

  // Helper method to extract specific component from address_components
  static extractAddressComponent(components, type, short = false) {
    const component = components.find(comp => comp.types.includes(type));
    return component ? (short ? component.short_name : component.long_name) : '';
  }
}

module.exports = new GeocodingService();
