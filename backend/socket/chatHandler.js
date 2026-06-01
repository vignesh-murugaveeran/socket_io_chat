const Message = require('../models/Message');
const Conversation = require('../models/Conversation');
const User = require('../models/User');

/**
 * Socket.IO Chat Handler
 * Manages realtime messaging, typing indicators, online status, and read receipts
 */
module.exports = (io) => {
  // Track online users: { userId: socketId }
  const onlineUsers = new Map();

  io.on('connection', async (socket) => {
    const userId = socket.userId;
    console.log(`🟢 User connected: ${userId} (socket: ${socket.id})`);

    // Mark user online
    onlineUsers.set(userId, socket.id);
    await User.findByIdAndUpdate(userId, {
      isOnline: true,
      socketId: socket.id,
      lastSeen: new Date(),
    });

    // Broadcast online status to all connected clients
    io.emit('user_status', {
      userId,
      isOnline: true,
      lastSeen: new Date().toISOString(),
    });

    // ─── Join Conversation Room ───────────────────────────────────────
    socket.on('join_conversation', ({ conversationId }) => {
      socket.join(conversationId);
      console.log(`📌 User ${userId} joined room: ${conversationId}`);
    });

    // ─── Leave Conversation Room ──────────────────────────────────────
    socket.on('leave_conversation', ({ conversationId }) => {
      socket.leave(conversationId);
      console.log(`📌 User ${userId} left room: ${conversationId}`);
    });

    // ─── Send Message ─────────────────────────────────────────────────
    socket.on('send_message', async (data) => {
      try {
        const { conversationId, text, type = 'text', imageUrl = '' } = data;

        // Save message to database
        let message = await Message.create({
          conversationId,
          sender: userId,
          text: type === 'text' ? text : '',
          imageUrl: type === 'image' ? imageUrl : '',
          type,
          readBy: [userId],
        });

        // Populate sender info
        message = await Message.findById(message._id).populate(
          'sender',
          'name email avatar'
        );

        // Update conversation
        const conversation = await Conversation.findById(conversationId);
        if (conversation) {
          conversation.lastMessage = message._id;
          conversation.updatedAt = new Date();

          // Increment unread count for other participants
          conversation.participants.forEach((participantId) => {
            const pid = participantId.toString();
            if (pid !== userId) {
              const currentCount =
                conversation.unreadCount.get(pid) || 0;
              conversation.unreadCount.set(pid, currentCount + 1);
            }
          });

          await conversation.save();
        }

        // Broadcast to everyone in the room (including sender for confirmation)
        io.to(conversationId).emit('receive_message', {
          message: message.toJSON(),
          conversationId,
        });

        // Also emit to participants not in the room (for chat list updates)
        if (conversation) {
          conversation.participants.forEach((participantId) => {
            const pid = participantId.toString();
            if (pid !== userId) {
              const participantSocketId = onlineUsers.get(pid);
              if (participantSocketId) {
                io.to(participantSocketId).emit('new_message_notification', {
                  conversationId,
                  message: message.toJSON(),
                });
              }
            }
          });
        }
      } catch (error) {
        console.error('Send message socket error:', error);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // ─── Typing Indicators ────────────────────────────────────────────
    socket.on('typing', ({ conversationId }) => {
      socket.to(conversationId).emit('typing', {
        conversationId,
        userId,
      });
    });

    socket.on('stop_typing', ({ conversationId }) => {
      socket.to(conversationId).emit('stop_typing', {
        conversationId,
        userId,
      });
    });

    // ─── Mark Messages as Read ────────────────────────────────────────
    socket.on('mark_read', async ({ conversationId }) => {
      try {
        // Update messages
        await Message.updateMany(
          {
            conversationId,
            sender: { $ne: userId },
            readBy: { $nin: [userId] },
          },
          { $addToSet: { readBy: userId } }
        );

        // Reset unread count
        const conversation = await Conversation.findById(conversationId);
        if (conversation) {
          conversation.unreadCount.set(userId, 0);
          await conversation.save();
        }

        // Notify the other user that messages were read
        socket.to(conversationId).emit('message_read', {
          conversationId,
          userId,
        });
      } catch (error) {
        console.error('Mark read socket error:', error);
      }
    });

    // ─── Disconnect ───────────────────────────────────────────────────
    socket.on('disconnect', async () => {
      console.log(`🔴 User disconnected: ${userId}`);
      onlineUsers.delete(userId);

      await User.findByIdAndUpdate(userId, {
        isOnline: false,
        socketId: '',
        lastSeen: new Date(),
      });

      // Broadcast offline status
      io.emit('user_status', {
        userId,
        isOnline: false,
        lastSeen: new Date().toISOString(),
      });
    });
  });
};
