const express = require('express');
const Conversation = require('../models/Conversation');
const { auth } = require('../middleware/auth');

const router = express.Router();

/**
 * GET /api/conversations
 * List all conversations for current user, sorted by most recent
 */
router.get('/', auth, async (req, res) => {
  try {
    const conversations = await Conversation.find({
      participants: req.userId,
    })
      .populate('participants', 'name email avatar isOnline lastSeen')
      .populate({
        path: 'lastMessage',
        select: 'text type imageUrl sender createdAt',
        populate: {
          path: 'sender',
          select: 'name',
        },
      })
      .sort({ updatedAt: -1 });

    res.json({
      success: true,
      data: { conversations },
    });
  } catch (error) {
    console.error('Get conversations error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error.',
    });
  }
});

/**
 * POST /api/conversations
 * Create or get existing 1-on-1 conversation
 * Body: { participantId: "userId" }
 */
router.post('/', auth, async (req, res) => {
  try {
    const { participantId } = req.body;

    if (!participantId) {
      return res.status(400).json({
        success: false,
        message: 'Participant ID is required.',
      });
    }

    if (participantId === req.userId.toString()) {
      return res.status(400).json({
        success: false,
        message: 'Cannot create conversation with yourself.',
      });
    }

    // Check if conversation already exists between these two users
    let conversation = await Conversation.findOne({
      participants: {
        $all: [req.userId, participantId],
        $size: 2,
      },
    })
      .populate('participants', 'name email avatar isOnline lastSeen')
      .populate({
        path: 'lastMessage',
        select: 'text type imageUrl sender createdAt',
      });

    if (conversation) {
      return res.json({
        success: true,
        data: { conversation },
        message: 'Existing conversation found.',
      });
    }

    // Create new conversation
    conversation = await Conversation.create({
      participants: [req.userId, participantId],
      unreadCount: new Map([
        [req.userId.toString(), 0],
        [participantId, 0],
      ]),
    });

    // Populate participants
    conversation = await Conversation.findById(conversation._id)
      .populate('participants', 'name email avatar isOnline lastSeen');

    res.status(201).json({
      success: true,
      data: { conversation },
      message: 'Conversation created.',
    });
  } catch (error) {
    console.error('Create conversation error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error.',
    });
  }
});

module.exports = router;
