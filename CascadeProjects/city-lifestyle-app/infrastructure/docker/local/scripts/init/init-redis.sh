#!/bin/sh

# Redis initialization script for local development

# Wait for Redis to be ready
until redis-cli ping; do
  echo "Waiting for Redis to be ready..."
  sleep 1
done

# Development-specific settings
redis-cli CONFIG SET protected-mode no
redis-cli CONFIG SET maxmemory 256mb
redis-cli CONFIG SET maxmemory-policy allkeys-lru

# Set up rate limiting for development
redis-cli SADD ratelimit:endpoints "/api/v1/places" "/api/v1/reviews" "/api/v1/events"
redis-cli SET ratelimit:window 3600
redis-cli SET ratelimit:max_requests 10000  # Higher limit for development

# Cache configuration
redis-cli CONFIG SET notify-keyspace-events "Ex"
redis-cli SET cache:default_ttl 300

# Set up key prefixes
redis-cli SADD key_prefixes:all "user:" "place:" "review:" "event:" "cache:" "session:" "ratelimit:"

# Development-specific TTLs
redis-cli SET ttl:session 86400     # 24 hours for development
redis-cli SET ttl:cache 300         # 5 minutes
redis-cli SET ttl:ratelimit 3600    # 1 hour

# Create pub/sub channels for development
redis-cli SADD pubsub:channels "notifications" "events" "system" "dev_logs"

# Add some test data for development
redis-cli SET "cache:test" "test_value"
redis-cli EXPIRE "cache:test" 300

echo "Redis initialization for development completed successfully!"
