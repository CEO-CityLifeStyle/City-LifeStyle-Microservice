# Local Deployment Guide Using Docker Desktop

## Prerequisites

1. **Required Software**
   - Docker Desktop
   - Node.js >= 18.0.0
   - Git

2. **Docker Desktop Setup**
   - Download and install from [Docker Desktop](https://www.docker.com/products/docker-desktop)
   - Ensure Docker Desktop is running
   - Recommended resources:
     - CPUs: 4+
     - Memory: 8GB+
     - Disk: 60GB+

## Local Development Setup

### 1. Environment Configuration

Create a `.env` file in the backend directory:
```bash
cp backend/.env.example backend/.env
```

Edit `.env` with local configurations:
```env
# Server
NODE_ENV=development
PORT=3000

# Database
MONGODB_URI=mongodb://mongodb:27017/city-lifestyle
REDIS_URL=redis://redis:6379

# JWT
JWT_SECRET=your-local-secret-key

# Storage (local)
STORAGE_PATH=./storage

# Other Services
PUBSUB_EMULATOR_HOST=pubsub:8085
```

### 2. Docker Compose Setup

Create `docker-compose.local.yml`:
```yaml
version: '3.8'

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
      target: development
    ports:
      - "3000:3000"
    volumes:
      - ./backend:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
    depends_on:
      - mongodb
      - redis
      - pubsub
    networks:
      - city-lifestyle

  mongodb:
    image: mongo:latest
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    networks:
      - city-lifestyle

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - city-lifestyle

  pubsub:
    image: gcr.io/google.com/cloudsdktool/cloud-sdk:latest
    command: gcloud beta emulators pubsub start --host-port=0.0.0.0:8085
    ports:
      - "8085:8085"
    networks:
      - city-lifestyle

networks:
  city-lifestyle:
    driver: bridge

volumes:
  mongodb_data:
  redis_data:
```

## Running the Application

### 1. Start the Services
```bash
# Build and start all services
docker-compose -f docker-compose.local.yml up --build

# Start in detached mode
docker-compose -f docker-compose.local.yml up -d

# View logs
docker-compose -f docker-compose.local.yml logs -f
```

### 2. Access the Services
- Backend API: http://localhost:3000
- MongoDB: mongodb://localhost:27017
- Redis: redis://localhost:6379
- Pub/Sub Emulator: localhost:8085

### 3. Development Commands
```bash
# Stop all services
docker-compose -f docker-compose.local.yml down

# Rebuild a specific service
docker-compose -f docker-compose.local.yml build backend

# Restart a specific service
docker-compose -f docker-compose.local.yml restart backend

# View service logs
docker-compose -f docker-compose.local.yml logs -f backend

# Access container shell
docker-compose -f docker-compose.local.yml exec backend sh
```

## Development Workflow

### 1. Code Changes
- Edit code in the `backend` directory
- Changes will be reflected immediately (hot-reload enabled)
- Node modules are preserved in a Docker volume

### 2. Database Management
```bash
# Access MongoDB shell
docker-compose -f docker-compose.local.yml exec mongodb mongosh

# Create database backup
docker-compose -f docker-compose.local.yml exec mongodb mongodump --out /data/backup

# Restore database
docker-compose -f docker-compose.local.yml exec mongodb mongorestore /data/backup
```

### 3. Redis Management
```bash
# Access Redis CLI
docker-compose -f docker-compose.local.yml exec redis redis-cli

# Monitor Redis commands
docker-compose -f docker-compose.local.yml exec redis redis-cli monitor
```

## Troubleshooting

### Common Issues

1. **Port Conflicts**
```bash
# Check for port usage
netstat -ano | findstr "3000"
netstat -ano | findstr "27017"
netstat -ano | findstr "6379"
```

2. **Container Issues**
```bash
# Check container status
docker ps
docker ps -a  # includes stopped containers

# Check container logs
docker logs [container_id]

# Restart Docker Desktop
```

3. **Volume Issues**
```bash
# Remove volumes and rebuild
docker-compose -f docker-compose.local.yml down -v
docker-compose -f docker-compose.local.yml up --build
```

### Performance Optimization

1. **Docker Desktop Settings**
   - Increase CPU allocation
   - Increase memory allocation
   - Enable disk cache

2. **Volume Performance**
   - Use named volumes instead of bind mounts
   - Consider using Docker Desktop WSL 2 backend

## Switching to Production

When ready to deploy to GCP:
1. Update environment variables for production
2. Follow the GCP deployment guide in `DEPLOYMENT.md`
3. Ensure all secrets are properly configured in GCP Secret Manager

## Local Testing

### 1. API Testing
```bash
# Install testing dependencies
npm install --save-dev jest supertest

# Run tests
docker-compose -f docker-compose.local.yml exec backend npm test
```

### 2. Load Testing
```bash
# Install k6
npm install --save-dev k6

# Run load tests
k6 run tests/load/main.js
```

### 3. Security Testing
```bash
# Run security audit
docker-compose -f docker-compose.local.yml exec backend npm audit

# Run OWASP ZAP scan
docker run -t owasp/zap2docker-stable zap-baseline.py -t http://localhost:3000
```
