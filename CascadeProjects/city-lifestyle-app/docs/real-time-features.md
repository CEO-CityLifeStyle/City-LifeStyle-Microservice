# Real-time Features Documentation

## Overview
The real-time features system provides instant updates, live notifications, and real-time communication capabilities across the application using WebSocket connections and event-driven architecture.

## Current Implementation

### 1. WebSocket Service

```javascript
// backend/src/services/webSocketService.js
class WebSocketService {
  constructor(server, authService) {
    this.io = new Server(server, {
      cors: {
        origin: process.env.CLIENT_URL,
        methods: ['GET', 'POST']
      }
    });
    
    this.authService = authService;
    this.connections = new Map();
    
    this.initialize();
  }

  initialize() {
    this.io.use(async (socket, next) => {
      try {
        const token = socket.handshake.auth.token;
        const user = await this.authService.verifyToken(token);
        socket.user = user;
        next();
      } catch (error) {
        next(new Error('Authentication error'));
      }
    });

    this.io.on('connection', (socket) => {
      this.handleConnection(socket);
    });
  }

  handleConnection(socket) {
    const userId = socket.user.id;
    
    // Store connection
    this.connections.set(userId, socket);
    
    // Join user's room
    socket.join(`user:${userId}`);
    
    // Handle disconnection
    socket.on('disconnect', () => {
      this.connections.delete(userId);
      this.broadcastUserStatus(userId, 'offline');
    });
    
    // Handle room joining
    socket.on('join_room', (roomId) => {
      socket.join(`room:${roomId}`);
    });
    
    // Handle room leaving
    socket.on('leave_room', (roomId) => {
      socket.leave(`room:${roomId}`);
    });
    
    // Broadcast user's online status
    this.broadcastUserStatus(userId, 'online');
  }

  broadcastUserStatus(userId, status) {
    this.io.emit('user_status', {
      userId,
      status,
      timestamp: new Date()
    });
  }

  sendToUser(userId, event, data) {
    this.io.to(`user:${userId}`).emit(event, data);
  }

  sendToRoom(roomId, event, data) {
    this.io.to(`room:${roomId}`).emit(event, data);
  }

  broadcastEvent(event, data) {
    this.io.emit(event, data);
  }
}
```

### 2. Real-time Notification Service

```javascript
// backend/src/services/notificationService.js
class NotificationService {
  constructor(db, webSocket, cache) {
    this.db = db;
    this.webSocket = webSocket;
    this.cache = cache;
  }

  async notify(userId, notification) {
    // Create notification
    const newNotification = await this.db.notifications.create({
      userId,
      ...notification,
      read: false,
      createdAt: new Date()
    });

    // Send real-time notification
    this.webSocket.sendToUser(userId, 'notification', newNotification);

    // Update unread count in cache
    const cacheKey = `notifications:unread:${userId}`;
    await this.cache.incr(cacheKey);

    return newNotification;
  }

  async getUnreadCount(userId) {
    const cacheKey = `notifications:unread:${userId}`;
    
    // Try cache first
    let count = await this.cache.get(cacheKey);
    
    if (count === null) {
      // Get from database
      count = await this.db.notifications.countDocuments({
        userId,
        read: false
      });
      
      // Cache the count
      await this.cache.set(cacheKey, count, 3600);
    }
    
    return parseInt(count);
  }

  async markAsRead(userId, notificationIds) {
    await this.db.notifications.updateMany(
      {
        _id: { $in: notificationIds },
        userId
      },
      {
        $set: {
          read: true,
          readAt: new Date()
        }
      }
    );

    // Update unread count in cache
    const cacheKey = `notifications:unread:${userId}`;
    const count = await this.getUnreadCount(userId);
    await this.cache.set(cacheKey, Math.max(0, count - notificationIds.length));

    // Send real-time update
    this.webSocket.sendToUser(userId, 'notifications_read', {
      notificationIds
    });
  }

  async getNotifications(userId, page = 1, limit = 20) {
    return this.db.notifications
      .find({ userId })
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit);
  }
}
```

### 3. Chat Service

```javascript
// backend/src/services/chatService.js
class ChatService {
  constructor(db, webSocket, cache) {
    this.db = db;
    this.webSocket = webSocket;
    this.cache = cache;
  }

  async createRoom(data) {
    const room = await this.db.chatRooms.create({
      ...data,
      createdAt: new Date()
    });

    // Add participants to room
    await Promise.all(
      data.participants.map(userId =>
        this.addParticipant(room._id, userId)
      )
    );

    return room;
  }

  async addParticipant(roomId, userId) {
    await this.db.chatRooms.updateOne(
      { _id: roomId },
      { $addToSet: { participants: userId } }
    );

    // Join WebSocket room
    const socket = this.webSocket.connections.get(userId);
    if (socket) {
      socket.join(`room:${roomId}`);
    }
  }

  async sendMessage(roomId, userId, content) {
    // Create message
    const message = await this.db.chatMessages.create({
      roomId,
      userId,
      content,
      createdAt: new Date()
    });

    // Update room's last message
    await this.db.chatRooms.updateOne(
      { _id: roomId },
      {
        $set: {
          lastMessage: message._id,
          lastMessageAt: message.createdAt
        }
      }
    );

    // Send real-time message
    this.webSocket.sendToRoom(roomId, 'new_message', message);

    // Update unread counts for other participants
    const room = await this.db.chatRooms.findById(roomId);
    const otherParticipants = room.participants.filter(
      p => p.toString() !== userId
    );

    await Promise.all(
      otherParticipants.map(participantId =>
        this.incrementUnreadCount(roomId, participantId)
      )
    );

    return message;
  }

  async getMessages(roomId, page = 1, limit = 50) {
    return this.db.chatMessages
      .find({ roomId })
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .populate('userId', 'name avatar');
  }

  async markAsRead(roomId, userId) {
    await this.db.chatRooms.updateOne(
      { _id: roomId },
      { $set: { [`readStatus.${userId}`]: new Date() } }
    );

    // Reset unread count
    const cacheKey = `chat:unread:${roomId}:${userId}`;
    await this.cache.set(cacheKey, 0);

    // Notify other participants
    this.webSocket.sendToRoom(roomId, 'messages_read', {
      roomId,
      userId
    });
  }

  private async incrementUnreadCount(roomId, userId) {
    const cacheKey = `chat:unread:${roomId}:${userId}`;
    await this.cache.incr(cacheKey);
  }
}
```

### 4. Presence Service

```javascript
// backend/src/services/presenceService.js
class PresenceService {
  constructor(db, webSocket, cache) {
    this.db = db;
    this.webSocket = webSocket;
    this.cache = cache;
    this.heartbeatInterval = 30000; // 30 seconds
  }

  async updatePresence(userId, status = 'online') {
    const presence = {
      userId,
      status,
      lastSeen: new Date(),
      device: this.getCurrentDevice()
    };

    // Update cache
    const cacheKey = `presence:${userId}`;
    await this.cache.set(cacheKey, JSON.stringify(presence), 60);

    // Broadcast to connections
    this.broadcastPresence(userId, presence);

    return presence;
  }

  async getPresence(userId) {
    const cacheKey = `presence:${userId}`;
    const cached = await this.cache.get(cacheKey);
    
    if (cached) {
      return JSON.parse(cached);
    }

    return {
      userId,
      status: 'offline',
      lastSeen: null
    };
  }

  async broadcastPresence(userId, presence) {
    // Get user's connections
    const connections = await this.db.connections
      .find({ userId, status: 'accepted' })
      .select('connectionId');

    // Broadcast to each connection
    connections.forEach(({ connectionId }) => {
      this.webSocket.sendToUser(connectionId, 'presence_update', presence);
    });
  }

  startHeartbeat(userId) {
    const intervalId = setInterval(
      () => this.updatePresence(userId),
      this.heartbeatInterval
    );

    return () => clearInterval(intervalId);
  }

  private getCurrentDevice() {
    // Implementation to detect current device/platform
    return {
      type: 'web',
      userAgent: navigator.userAgent
    };
  }
}
```

## Remaining Implementation

### 1. Live Collaboration

```javascript
// backend/src/services/collaborationService.js
class CollaborationService {
  constructor(webSocket, db) {
    this.webSocket = webSocket;
    this.db = db;
    this.sessions = new Map();
  }

  async startSession(documentId, userId) {
    let session = this.sessions.get(documentId);
    
    if (!session) {
      session = {
        documentId,
        participants: new Set(),
        operations: [],
        version: 0
      };
      this.sessions.set(documentId, session);
    }

    session.participants.add(userId);
    
    // Join collaboration room
    this.webSocket.sendToUser(userId, 'join_session', {
      documentId,
      initialState: await this.getDocumentState(documentId)
    });
  }

  async applyOperation(documentId, userId, operation) {
    const session = this.sessions.get(documentId);
    
    if (!session) {
      throw new Error('Session not found');
    }

    // Transform operation against concurrent operations
    const transformedOp = this.transformOperation(operation, session.operations);
    
    // Apply operation
    session.operations.push(transformedOp);
    session.version++;

    // Broadcast to all participants
    this.webSocket.sendToRoom(documentId, 'operation', {
      userId,
      operation: transformedOp,
      version: session.version
    });
  }

  private transformOperation(operation, concurrent) {
    // Operational transformation logic
    return operation;
  }
}
```

### 2. Real-time Analytics

```javascript
// backend/src/services/realTimeAnalyticsService.js
class RealTimeAnalyticsService {
  constructor(webSocket, cache) {
    this.webSocket = webSocket;
    this.cache = cache;
    this.metricsInterval = 5000; // 5 seconds
  }

  async trackEvent(event) {
    const timestamp = Date.now();
    const bucket = Math.floor(timestamp / this.metricsInterval);
    
    // Increment event counter in current time bucket
    const key = `analytics:${event.type}:${bucket}`;
    await this.cache.incr(key);
    
    // Set expiry for bucket
    await this.cache.expire(key, 3600); // 1 hour
  }

  async getMetrics(eventType, duration) {
    const now = Date.now();
    const buckets = Math.ceil(duration / this.metricsInterval);
    const currentBucket = Math.floor(now / this.metricsInterval);
    
    const metrics = [];
    
    for (let i = 0; i < buckets; i++) {
      const bucket = currentBucket - i;
      const key = `analytics:${eventType}:${bucket}`;
      const count = await this.cache.get(key) || 0;
      
      metrics.push({
        timestamp: bucket * this.metricsInterval,
        count: parseInt(count)
      });
    }
    
    return metrics;
  }

  startMetricsStream(eventTypes) {
    setInterval(async () => {
      const metrics = {};
      
      for (const type of eventTypes) {
        metrics[type] = await this.getMetrics(type, 300000); // Last 5 minutes
      }
      
      this.webSocket.broadcastEvent('metrics_update', metrics);
    }, this.metricsInterval);
  }
}
```

## Implementation Timeline

### Week 1: Live Collaboration
- Implement collaboration service
- Add operational transformation
- Create real-time cursors
- Add presence indicators

### Week 2: Real-time Analytics
- Build analytics service
- Add metrics streaming
- Create live dashboards
- Implement event tracking

## Success Metrics
- WebSocket connection stability > 99.9%
- Message delivery rate > 99.99%
- Real-time update latency < 100ms
- Collaboration conflicts < 0.1%

## Real-time Features Checklist
- [x] WebSocket infrastructure
- [x] Real-time notifications
- [x] Chat system
- [x] Presence tracking
- [ ] Live collaboration
- [ ] Real-time analytics
- [ ] Metrics streaming
- [ ] Performance monitoring
- [ ] Load balancing
- [ ] Failover handling
