// MongoDB initialization script for production

// Create admin user with secure password from environment variable
db.createUser({
  user: process.env.MONGO_ADMIN_USER,
  pwd: process.env.MONGO_ADMIN_PASSWORD,
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

// Create indexes with partial filter expressions for better performance
db.users.createIndex(
  { "email": 1 },
  { 
    unique: true,
    partialFilterExpression: { "email": { $exists: true } }
  }
);
db.users.createIndex(
  { "role": 1 },
  { partialFilterExpression: { "role": { $exists: true } } }
);

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

// Create optimized indexes for production workload
db.places.createIndex(
  { "location": "2dsphere" },
  { background: true }
);
db.places.createIndex(
  { "category": 1, "rating": -1 },
  { background: true }
);

// Enable sharding for better scalability
sh.enableSharding("city-lifestyle");
sh.shardCollection("city-lifestyle.places", { "location": "2dsphere" });
