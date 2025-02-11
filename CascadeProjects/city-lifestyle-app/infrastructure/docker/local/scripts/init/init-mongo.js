// MongoDB initialization script for local development

// Create admin user for local development
db.createUser({
  user: 'admin',
  pwd: 'dev_password',  // Development password only
  roles: [{ role: 'readWrite', db: 'city-lifestyle' }]
});

// Switch to application database
db = db.getSiblingDB('city-lifestyle');

// Create collections with schemas
db.createCollection('users', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['email', 'password', 'role'],
      properties: {
        email: {
          bsonType: 'string',
          pattern: '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$'
        },
        password: { bsonType: 'string' },
        role: { enum: ['user', 'admin'] },
        name: { bsonType: 'string' },
        avatar: { bsonType: 'string' },
        createdAt: { bsonType: 'date' },
        updatedAt: { bsonType: 'date' }
      }
    }
  }
});

// Create indexes
db.users.createIndex({ "email": 1 }, { unique: true });
db.users.createIndex({ "role": 1 });

db.createCollection('places', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['name', 'location', 'category'],
      properties: {
        name: { bsonType: 'string' },
        description: { bsonType: 'string' },
        category: { enum: ['restaurant', 'park', 'shopping', 'entertainment', 'other'] },
        location: {
          bsonType: 'object',
          required: ['type', 'coordinates'],
          properties: {
            type: { enum: ['Point'] },
            coordinates: {
              bsonType: 'array',
              minItems: 2,
              maxItems: 2,
              items: { bsonType: 'double' }
            }
          }
        },
        rating: { bsonType: 'double' },
        reviews: { bsonType: 'array' },
        images: { bsonType: 'array' },
        createdAt: { bsonType: 'date' },
        updatedAt: { bsonType: 'date' }
      }
    }
  }
});

// Create geospatial index for location-based queries
db.places.createIndex({ "location": "2dsphere" });
db.places.createIndex({ "category": 1 });
db.places.createIndex({ "rating": -1 });

// Create test data for development
db.users.insertOne({
  email: 'test@example.com',
  password: '$2b$10$test_hash',  // Development password hash
  role: 'admin',
  name: 'Test User',
  createdAt: new Date(),
  updatedAt: new Date()
});
