require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();

// Middleware
app.use(express.json());
app.use(cors());
app.use(helmet());
app.use(morgan('dev'));

// Database connection
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('Connected to MongoDB'))
.catch((err) => console.error('MongoDB connection error:', err));

// Routes (to be implemented)
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to City Lifestyle App API' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!' });
});

module.exports = app;
```

```javascript
const app = require('./index');
const http = require('http');
const websocketService = require('./services/websocketService');

const PORT = process.env.PORT || 3000;

const server = http.createServer(app);

// Initialize WebSocket server
websocketService.initialize(server);

server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
