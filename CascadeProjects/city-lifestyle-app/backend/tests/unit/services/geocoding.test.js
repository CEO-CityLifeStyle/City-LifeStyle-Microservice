const geocodingService = require('../../../src/services/geocodingService');
const axios = require('axios');

jest.mock('axios');

// Mock environment variables
process.env.GOOGLE_MAPS_API_KEY = 'test-api-key';
process.env.NODE_ENV = 'test';

describe('Geocoding Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should return mock data in test environment', async () => {
    const result = await geocodingService.geocodeAddress('123 Test St');
    expect(result).toEqual({
      coordinates: {
        type: 'Point',
        coordinates: [-74.0060, 40.7128]
      },
      formattedAddress: '123 Test St, New York, NY 10001',
      placeId: 'test_place_id',
      components: []
    });
    expect(axios.get).not.toHaveBeenCalled();
  });

  it('should handle geocoding error in production', async () => {
    // Temporarily set NODE_ENV to production
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';

    const mockResponse = {
      data: {
        results: [],
        status: 'ZERO_RESULTS'
      }
    };

    axios.get.mockResolvedValueOnce(mockResponse);

    await expect(geocodingService.geocodeAddress('invalid address'))
      .rejects
      .toThrow('Geocoding failed: ZERO_RESULTS');

    // Restore NODE_ENV
    process.env.NODE_ENV = originalEnv;
  });

  it('should handle API error in production', async () => {
    // Temporarily set NODE_ENV to production
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';

    axios.get.mockRejectedValueOnce(new Error('API Error'));

    await expect(geocodingService.geocodeAddress('123 Test St'))
      .rejects
      .toThrow('Geocoding error: API Error');

    // Restore NODE_ENV
    process.env.NODE_ENV = originalEnv;
  });
});
