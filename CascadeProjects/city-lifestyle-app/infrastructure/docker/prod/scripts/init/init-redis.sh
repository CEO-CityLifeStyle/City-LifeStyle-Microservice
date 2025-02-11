#!/bin/sh

# Redis initialization script for production

# Wait for Redis to be ready
until redis-cli -a "${REDIS_PASSWORD}" ping; do
  echo "Waiting for Redis to be ready..."
  sleep 1
done

# Security settings
redis-cli -a "${REDIS_PASSWORD}" CONFIG SET protected-mode yes
redis-cli -a "${REDIS_PASSWORD}" CONFIG SET maxmemory 1gb
redis-cli -a "${REDIS_PASSWORD}" CONFIG SET maxmemory-policy volatile-lru

# Disable dangerous commands
redis-cli -a "${REDIS_PASSWORD}" RENAME-COMMAND FLUSHDB ""
redis-cli -a "${REDIS_PASSWORD}" RENAME-COMMAND FLUSHALL ""
redis-cli -a "${REDIS_PASSWORD}" RENAME-COMMAND DEBUG ""

# Performance settings
redis-cli -a "${REDIS_PASSWORD}" CONFIG SET activerehashing yes
redis-cli -a "${REDIS_PASSWORD}" CONFIG SET lazyfree-lazy-eviction yes
redis-cli -a "${REDIS_PASSWORD}" CONFIG SET lazyfree-lazy-expire yes

# Set up rate limiting for production
redis-cli -a "${REDIS_PASSWORD}" SADD ratelimit:endpoints "/api/v1/places" "/api/v1/reviews" "/api/v1/events"
redis-cli -a "${REDIS_PASSWORD}" SET ratelimit:window 3600
redis-cli -a "${REDIS_PASSWORD}" SET ratelimit:max_requests 1000  # Stricter limit for production

# Cache configuration
redis-cli -a "${REDIS_PASSWORD}" CONFIG SET notify-keyspace-events "Ex"
redis-cli -a "${REDIS_PASSWORD}" SET cache:default_ttl 300

# Set up key prefixes
redis-cli -a "${REDIS_PASSWORD}" SADD key_prefixes:all "user:" "place:" "review:" "event:" "cache:" "session:" "ratelimit:"

# Production TTLs
redis-cli -a "${REDIS_PASSWORD}" SET ttl:session 3600      # 1 hour
redis-cli -a "${REDIS_PASSWORD}" SET ttl:cache 300         # 5 minutes
redis-cli -a "${REDIS_PASSWORD}" SET ttl:ratelimit 3600    # 1 hour

# Create pub/sub channels for production
redis-cli -a "${REDIS_PASSWORD}" SADD pubsub:channels "notifications" "events" "system"

echo "Redis initialization for production completed successfully!"
