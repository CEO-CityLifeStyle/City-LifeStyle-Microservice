#!/bin/sh

# Health check script for local development

# Function to check HTTP endpoint
check_http() {
  local url=$1
  local expected_status=$2
  local timeout=$3

  response=$(curl -s -w "%{http_code}" -o /dev/null --max-time $timeout $url)
  if [ "$response" = "$expected_status" ]; then
    return 0
  else
    return 1
  fi
}

# Function to check TCP port
check_tcp() {
  local host=$1
  local port=$2
  local timeout=$3

  nc -z -w$timeout $host $port
  return $?
}

# Function to check MongoDB
check_mongodb() {
  mongosh --eval "db.runCommand('ping').ok" mongodb://localhost:27017/city-lifestyle --quiet
  return $?
}

# Function to check Redis
check_redis() {
  redis-cli ping > /dev/null
  return $?
}

# Function to check disk space
check_disk_space() {
  local mount=$1
  local threshold=$2
  
  usage=$(df $mount | tail -1 | awk '{print $5}' | sed 's/%//')
  if [ "$usage" -lt "$threshold" ]; then
    return 0
  else
    return 1
  fi
}

# Function to check memory usage
check_memory() {
  local threshold=90
  
  usage=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
  if [ "$usage" -lt "$threshold" ]; then
    return 0
  else
    return 1
  fi
}

# Main health check logic based on service type
SERVICE_TYPE=$1

case $SERVICE_TYPE in
  "api")
    check_http "http://localhost:8080/health" "200" "5"
    ;;
  "auth")
    check_http "http://localhost:8081/health" "200" "5"
    ;;
  "frontend")
    check_http "http://localhost:3000/health" "200" "5"
    ;;
  "mongodb")
    check_mongodb
    ;;
  "redis")
    check_redis
    ;;
  "system")
    check_disk_space "/" "90" && check_memory
    ;;
  *)
    echo "Unknown service type: $SERVICE_TYPE"
    exit 1
    ;;
esac
