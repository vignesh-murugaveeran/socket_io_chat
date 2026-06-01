import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Chat input bar with text field, send button, and image attachment
/// Emits typing events via callback
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String) onTyping;
  final Function(ImageSource) onPickImage;
  final bool isSending;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onTyping,
    required this.onPickImage,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment button
          _buildIconButton(
            icon: Icons.image_outlined,
            onTap: () => _showImagePicker(context),
          ),

          const SizedBox(width: 4),

          // Text input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D3E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: controller,
                onChanged: onTyping,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: isSending ? null : onSend,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: const Color(0xFF6C63FF),
            size: 26,
          ),
        ),
      ),
    );
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Send Image',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Color(0xFF6C63FF)),
                ),
                title: const Text('Camera',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  onPickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library,
                      color: Color(0xFF4ECDC4)),
                ),
                title: const Text('Gallery',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  onPickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
