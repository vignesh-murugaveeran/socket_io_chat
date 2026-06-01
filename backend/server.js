require('dotenv').config();

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const { socketAuth } = require('./middleware/auth');
const chatHandler = require('./socket/chatHandler');

// Import routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const conversationRoutes = require('./routes/conversations');
const messageRoutes = require('./routes/messages');

const app = express();
const server = http.createServer(app);

// Socket.IO setup with CORS
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
  pingTimeout: 60000,
  pingInterval: 25000,
});

// ─── Middleware ────────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Serve uploaded files statically
app.use('/uploads', express.static(uploadsDir));

// ─── REST API Routes ──────────────────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/conversations', conversationRoutes);
app.use('/api/messages', messageRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Chat API is running',
    timestamp: new Date().toISOString(),
  });
});

// ─── Socket.IO ────────────────────────────────────────────────────────────────
io.use(socketAuth); // Authenticate socket connections
chatHandler(io); // Register chat event handlers

// ─── Error Handling ───────────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error.',
  });
});

// ─── MongoDB Connection & Server Start ────────────────────────────────────────
const PORT = process.env.PORT || 3000;
const MONGODB_URI =
  process.env.MONGODB_URI || 'mongodb://localhost:27017/chat_app';

mongoose
  .connect(MONGODB_URI)
  .then(() => {
    console.log('✅ MongoDB connected successfully');

    server.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📡 Socket.IO ready for connections`);
      console.log(`📁 Uploads served at /uploads`);
    });
  })
  .catch((err) => {
    console.error('❌ MongoDB connection error:', err);
    process.exit(1);
  });

module.exports = { app, server, io };
