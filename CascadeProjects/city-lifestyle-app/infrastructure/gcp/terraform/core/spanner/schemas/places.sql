CREATE TABLE places (
  place_id STRING(36) NOT NULL,
  name STRING(MAX) NOT NULL,
  description STRING(MAX),
  address STRING(MAX),
  location GEOGRAPHY NOT NULL,
  created_at TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
  updated_at TIMESTAMP OPTIONS (allow_commit_timestamp=true),
  category STRING(50),
  status STRING(20),
  business_hours JSON,
  contact_info JSON,
  amenities ARRAY<STRING(50)>,
  metadata JSON,
) PRIMARY KEY(place_id);

CREATE INDEX places_by_location ON places(location);
CREATE INDEX places_by_category ON places(category);

CREATE TABLE place_reviews (
  place_id STRING(36) NOT NULL,
  user_id STRING(36) NOT NULL,
  rating INT64 NOT NULL,
  review STRING(MAX),
  created_at TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
  updated_at TIMESTAMP OPTIONS (allow_commit_timestamp=true),
  photos ARRAY<STRING(255)>,
) PRIMARY KEY(place_id, user_id),
  INTERLEAVE IN PARENT places ON DELETE CASCADE;
