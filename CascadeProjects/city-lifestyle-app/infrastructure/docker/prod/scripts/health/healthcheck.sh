#!/bin/sh

# Health check script for production

# Function to check HTTP endpoint with authentication
check_http() {
  local url=$1
  local expected_status=$2
  local timeout=$3
  local auth_header="${API_KEY:-}"

  if [ -n "$auth_header" ]; then
    response=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $auth_header" -o /dev/null --max-time $timeout $url)
  else
    response=$(curl -s -w "%{http_code}" -o /dev/null --max-time $timeout $url)
  fi

  if [ "$response" = "$expected_status" ]; then
    return 0
  else
    return 1
  fi
}

# Function to check TCP port with timeout
check_tcp() {
  local host=$1
  local port=$2
  local timeout=$3

  nc -z -w$timeout $host $port
  return $?
}

# Function to check MongoDB with authentication
check_mongodb() {
  local uri="${MONGODB_URI:-mongodb://localhost:27017/city-lifestyle}"
  mongosh --eval "db.runCommand('ping').ok" "$uri" --quiet
  return $?
}

# Function to check Redis with authentication
check_redis() {
  local host="${REDIS_HOST:-localhost}"
  local port="${REDIS_PORT:-6379}"
  local auth="${REDIS_PASSWORD:-}"

  if [ -n "$auth" ]; then
    redis-cli -h "$host" -p "$port" -a "$auth" ping > /dev/null
  else
    redis-cli -h "$host" -p "$port" ping > /dev/null
  fi
  return $?
}

# Function to check disk space with alerts
check_disk_space() {
  local mount=$1
  local threshold=$2
  local critical_threshold=95
  
  usage=$(df $mount | tail -1 | awk '{print $5}' | sed 's/%//')
  
  if [ "$usage" -ge "$critical_threshold" ]; then
    echo "CRITICAL: Disk usage is at $usage%"
    return 2
  elif [ "$usage" -ge "$threshold" ]; then
    echo "WARNING: Disk usage is at $usage%"
    return 1
  else
    return 0
  fi
}

# Function to check memory usage with alerts
check_memory() {
  local threshold=80
  local critical_threshold=90
  
  usage=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
  
  if [ "$usage" -ge "$critical_threshold" ]; then
    echo "CRITICAL: Memory usage is at $usage%"
    return 2
  elif [ "$usage" -ge "$threshold" ]; then
    echo "WARNING: Memory usage is at $usage%"
    return 1
  else
    return 0
  fi
}

# Function to check service dependencies
check_dependencies() {
  local service=$1
  
  case $service in
    "api")
      check_mongodb && check_redis
      ;;
    "auth")
      check_redis
      ;;
    *)
      return 0
      ;;
  esac
}

# Main health check logic based on service type
SERVICE_TYPE=$1

case $SERVICE_TYPE in
  "api")
    check_http "${API_URL:-http://localhost:8080}/health" "200" "5" && check_dependencies "api"
    ;;
  "auth")
    check_http "${AUTH_URL:-http://localhost:8081}/health" "200" "5" && check_dependencies "auth"
    ;;
  "frontend")
    check_http "${FRONTEND_URL:-http://localhost:3000}/health" "200" "5"
    ;;
  "mongodb")
    check_mongodb
    ;;
  "redis")
    check_redis
    ;;
  "system")
    check_disk_space "/" "80" && check_memory
    ;;
  *)
    echo "Unknown service type: $SERVICE_TYPE"
    exit 1
    ;;
esac

# Exit with appropriate status code
exit_code=$?
case $exit_code in
  0) echo "Health check passed for $SERVICE_TYPE" ;;
  1) echo "Warning: Health check issues for $SERVICE_TYPE" ;;
  2) echo "Critical: Health check failed for $SERVICE_TYPE" ;;
esac
exit $exit_code
