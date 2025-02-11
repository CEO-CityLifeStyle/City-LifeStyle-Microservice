const WebSocket = require('ws');
const jwt = require('jsonwebtoken');
const User = require('../models/user');

class WebSocketService {
  constructor() {
    this.clients = new Map(); // userId -> WebSocket
    this.wss = null;
  }

  initialize(server) {
    this.wss = new WebSocket.Server({ server });

    this.wss.on('connection', async (ws, req) => {
      try {
        // Extract token from query string
        const token = new URL(req.url, 'ws://localhost').searchParams.get('token');
        if (!token) {
          ws.close(4001, 'Authentication required');
          return;
        }

        // Verify token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded._id);
        if (!user) {
          ws.close(4002, 'User not found');
          return;
        }

        // Store client connection
        this.clients.set(user._id.toString(), ws);

        // Handle client messages
        ws.on('message', (message) => this.handleMessage(user._id, message));

        // Handle client disconnection
        ws.on('close', () => {
          this.clients.delete(user._id.toString());
        });

        // Send initial connection success message
        ws.send(JSON.stringify({
          type: 'connection',
          status: 'connected',
          userId: user._id,
        }));

      } catch (error) {
        console.error('WebSocket connection error:', error);
        ws.close(4003, 'Authentication failed');
      }
    });
  }

  handleMessage(userId, message) {
    try {
      const data = JSON.parse(message);
      switch (data.type) {
        case 'ping':
          this.sendToUser(userId, {
            type: 'pong',
            timestamp: new Date(),
          });
          break;
        // Add more message handlers as needed
      }
    } catch (error) {
      console.error('Error handling WebSocket message:', error);
    }
  }

  // Send message to specific user
  sendToUser(userId, data) {
    const ws = this.clients.get(userId.toString());
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify(data));
    }
  }

  // Send message to multiple users
  sendToUsers(userIds, data) {
    userIds.forEach(userId => this.sendToUser(userId, data));
  }

  // Broadcast message to all connected users
  broadcast(data, excludeUserId = null) {
    this.clients.forEach((ws, userId) => {
      if (userId !== excludeUserId && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify(data));
      }
    });
  }

  // Send real-time notification
  sendNotification(userId, notification) {
    this.sendToUser(userId, {
      type: 'notification',
      data: notification,
    });
  }

  // Send event update
  sendEventUpdate(eventId, update, recipientIds) {
    const message = {
      type: 'event_update',
      eventId,
      ...update,
    };
    if (recipientIds) {
      this.sendToUsers(recipientIds, message);
    } else {
      this.broadcast(message);
    }
  }

  // Send place update
  sendPlaceUpdate(placeId, update, recipientIds) {
    const message = {
      type: 'place_update',
      placeId,
      ...update,
    };
    if (recipientIds) {
      this.sendToUsers(recipientIds, message);
    } else {
      this.broadcast(message);
    }
  }

  // Send typing indicator
  sendTypingIndicator(userId, targetId, isTyping) {
    this.sendToUser(targetId, {
      type: 'typing_indicator',
      userId,
      isTyping,
    });
  }

  // Get connected user count
  getConnectedUserCount() {
    return this.clients.size;
  }

  // Check if user is connected
  isUserConnected(userId) {
    const ws = this.clients.get(userId.toString());
    return ws && ws.readyState === WebSocket.OPEN;
  }
}

module.exports = new WebSocketService();
