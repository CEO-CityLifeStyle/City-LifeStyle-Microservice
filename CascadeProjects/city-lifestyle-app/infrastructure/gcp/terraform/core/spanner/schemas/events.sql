CREATE TABLE events (
  event_id STRING(36) NOT NULL,
  title STRING(MAX) NOT NULL,
  description STRING(MAX),
  location_id STRING(36) NOT NULL,
  organizer_id STRING(36) NOT NULL,
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
  updated_at TIMESTAMP OPTIONS (allow_commit_timestamp=true),
  status STRING(20),
  category STRING(50),
  tags ARRAY<STRING(50)>,
  metadata JSON,
) PRIMARY KEY(event_id);

CREATE INDEX events_by_location ON events(location_id);
CREATE INDEX events_by_organizer ON events(organizer_id);
CREATE INDEX events_by_date ON events(start_time);

CREATE TABLE event_attendees (
  event_id STRING(36) NOT NULL,
  user_id STRING(36) NOT NULL,
  rsvp_status STRING(20) NOT NULL,
  created_at TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
  updated_at TIMESTAMP OPTIONS (allow_commit_timestamp=true),
  notification_preferences JSON,
) PRIMARY KEY(event_id, user_id),
  INTERLEAVE IN PARENT events ON DELETE CASCADE;
