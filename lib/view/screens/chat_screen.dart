import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/chat_view_model.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String requestId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.requestId,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to listen safely after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatViewModel>().listenToMessages(widget.requestId);
    });
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;

    final currentUserId = context.read<AuthViewModel>().currentUser?.uid;
    if (currentUserId == null) return;

    context.read<ChatViewModel>().sendMessage(
      senderId: currentUserId,
      receiverId: widget.otherUserId,
      text: _textController.text.trim(),
      requestId: widget.requestId,
    );

    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthViewModel>().currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatViewModel>(
              builder: (context, chatVM, child) {
                if (chatVM.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Determine empty state
                if (chatVM.messages.isEmpty) {
                  return const Center(child: Text('No messages yet. Say hi!'));
                }

                return ListView.builder(
                  reverse: true, // Show newest at the bottom
                  itemCount: chatVM.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatVM.messages[index];
                    final isMe = msg.senderId == currentUserId;
                    
                    return _buildMessageBubble(msg, isMe, context);
                  },
                );
              },
            ),
          ),
          
          // Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe, BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(msg.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
