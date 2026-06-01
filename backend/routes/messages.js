const express = require('express');
const multer = require('multer');
const path = require('path');
const Message = require('../models/Message');
const Conversation = require('../models/Conversation');
const { auth } = require('../middleware/auth');

const router = express.Router();

// Multer config for image uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '..', 'uploads'));
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    cb(null, `chat-${uniqueSuffix}${ext}`);
  },
});

const fileFilter = (req, file, cb) => {
  const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
});

/**
 * GET /api/messages/:conversationId?page=1&limit=20
 * Get paginated messages for a conversation (newest first)
 */
router.get('/:conversationId', auth, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    // Verify user is a participant
    const conversation = await Conversation.findOne({
      _id: conversationId,
      participants: req.userId,
    });

    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found.',
      });
    }

    const totalMessages = await Message.countDocuments({ conversationId });
    const totalPages = Math.ceil(totalMessages / limit);

    const messages = await Message.find({ conversationId })
      .populate('sender', 'name email avatar')
      .sort({ createdAt: -1 }) // Newest first
      .skip(skip)
      .limit(limit);

    // Reverse so they appear in chronological order on the client
    messages.reverse();

    res.json({
      success: true,
      data: {
        messages,
        pagination: {
          currentPage: page,
          totalPages,
          totalMessages,
          hasMore: page < totalPages,
        },
      },
    });
  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error.',
    });
  }
});

/**
 * POST /api/messages
 * Send a text message (REST fallback — primary path is via socket)
 */
router.post('/', auth, async (req, res) => {
  try {
    const { conversationId, text } = req.body;

    if (!conversationId || !text) {
      return res.status(400).json({
        success: false,
        message: 'Conversation ID and text are required.',
      });
    }

    // Verify user is a participant
    const conversation = await Conversation.findOne({
      _id: conversationId,
      participants: req.userId,
    });

    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found.',
      });
    }

    const message = await Message.create({
      conversationId,
      sender: req.userId,
      text,
      type: 'text',
      readBy: [req.userId],
    });

    // Update conversation's last message
    conversation.lastMessage = message._id;
    conversation.updatedAt = new Date();

    // Increment unread count for other participants
    conversation.participants.forEach((participantId) => {
      if (participantId.toString() !== req.userId.toString()) {
        const currentCount =
          conversation.unreadCount.get(participantId.toString()) || 0;
        conversation.unreadCount.set(
          participantId.toString(),
          currentCount + 1
        );
      }
    });

    await conversation.save();

    // Populate sender info
    await message.populate('sender', 'name email avatar');

    res.status(201).json({
      success: true,
      data: { message },
    });
  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error.',
    });
  }
});

/**
 * POST /api/messages/upload
 * Upload an image message
 */
router.post('/upload', auth, upload.single('image'), async (req, res) => {
  try {
    const { conversationId } = req.body;

    if (!conversationId || !req.file) {
      return res.status(400).json({
        success: false,
        message: 'Conversation ID and image file are required.',
      });
    }

    // Verify user is a participant
    const conversation = await Conversation.findOne({
      _id: conversationId,
      participants: req.userId,
    });

    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found.',
      });
    }

    const imageUrl = `/uploads/${req.file.filename}`;

    const message = await Message.create({
      conversationId,
      sender: req.userId,
      imageUrl,
      type: 'image',
      readBy: [req.userId],
    });

    // Update conversation's last message
    conversation.lastMessage = message._id;
    conversation.updatedAt = new Date();

    // Increment unread for others
    conversation.participants.forEach((participantId) => {
      if (participantId.toString() !== req.userId.toString()) {
        const currentCount =
          conversation.unreadCount.get(participantId.toString()) || 0;
        conversation.unreadCount.set(
          participantId.toString(),
          currentCount + 1
        );
      }
    });

    await conversation.save();
    await message.populate('sender', 'name email avatar');

    res.status(201).json({
      success: true,
      data: { message },
    });
  } catch (error) {
    console.error('Upload image error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error.',
    });
  }
});

/**
 * PUT /api/messages/read/:conversationId
 * Mark all messages in a conversation as read
 */
router.put('/read/:conversationId', auth, async (req, res) => {
  try {
    const { conversationId } = req.params;

    // Update all unread messages in this conversation
    await Message.updateMany(
      {
        conversationId,
        sender: { $ne: req.userId },
        readBy: { $nin: [req.userId] },
      },
      {
        $addToSet: { readBy: req.userId },
      }
    );

    // Reset unread count for this user
    const conversation = await Conversation.findById(conversationId);
    if (conversation) {
      conversation.unreadCount.set(req.userId.toString(), 0);
      await conversation.save();
    }

    res.json({
      success: true,
      message: 'Messages marked as read.',
    });
  } catch (error) {
    console.error('Mark read error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error.',
    });
  }
});

module.exports = router;
