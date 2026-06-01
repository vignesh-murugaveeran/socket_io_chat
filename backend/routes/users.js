const express = require('express');
const User = require('../models/User');
const { auth } = require('../middleware/auth');

const router = express.Router();

/**
 * GET /api/users
 * List all users (excluding current user)
 */
router.get('/', auth, async (req, res) => {
  try {
    const users = await User.find({ _id: { $ne: req.userId } })
      .select('name email avatar isOnline lastSeen')
      .sort({ name: 1 });

    res.json({
      success: true,
      data: { users },
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error.',
    });
  }
});

/**
 * GET /api/users/search?q=searchTerm
 * Search users by name or email
 */
router.get('/search', auth, async (req, res) => {
  try {
    const { q } = req.query;

    if (!q || q.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required.',
      });
    }

    const users = await User.find({
      _id: { $ne: req.userId },
      $or: [
        { name: { $regex: q, $options: 'i' } },
        { email: { $regex: q, $options: 'i' } },
      ],
    })
      .select('name email avatar isOnline lastSeen')
      .limit(20);

    res.json({
      success: true,
      data: { users },
    });
  } catch (error) {
    console.error('Search users error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error.',
    });
  }
});

module.exports = router;
