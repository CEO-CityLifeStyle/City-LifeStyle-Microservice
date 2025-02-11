CREATE TABLE users (
  user_id STRING(36) NOT NULL,
  email STRING(255) NOT NULL,
  name STRING(MAX) NOT NULL,
  created_at TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
  updated_at TIMESTAMP OPTIONS (allow_commit_timestamp=true),
  preferences JSON,
  status STRING(20),
) PRIMARY KEY(user_id);

CREATE UNIQUE INDEX users_by_email ON users(email);

CREATE TABLE user_sessions (
  session_id STRING(36) NOT NULL,
  user_id STRING(36) NOT NULL,
  created_at TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
  expires_at TIMESTAMP NOT NULL,
  device_info JSON,
  last_activity TIMESTAMP OPTIONS (allow_commit_timestamp=true),
) PRIMARY KEY(session_id),
  INTERLEAVE IN PARENT users ON DELETE CASCADE;
