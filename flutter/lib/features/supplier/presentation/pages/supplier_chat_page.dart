import 'package:flutter/material.dart';

class SupplierChatPage extends StatefulWidget {
  const SupplierChatPage({
    super.key,
    required this.customerName,
    this.subtitle = 'Linked consumer',
  });

  final String customerName;
  final String subtitle;

  @override
  State<SupplierChatPage> createState() => _SupplierChatPageState();
}

class _SupplierChatPageState extends State<SupplierChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(text: 'Good morning! We need to reorder salmon.', isMe: false),
    _ChatMessage(text: 'Absolutely. How many kilos do you need?', isMe: true),
    _ChatMessage(text: 'Can we get 10kg delivered tomorrow?', isMe: false),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isMe: true));
    });
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE9EEF0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF21545F),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.customerName),
            const SizedBox(height: 2),
            Text(
              widget.subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFFC8E9EF)),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, index) {
                final message = _messages[index];
                final isMe = message.isMe;
                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFFA7E1D5) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1E3E46),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _handleEscalation,
              icon: const Icon(Icons.priority_high_rounded),
              label: const Text('Escalate to manager/owner'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF21545F),
                side: const BorderSide(color: Color(0xFF21545F)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.attach_file_outlined),
                  color: const Color(0xFF21545F),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.photo_camera_outlined),
                  color: const Color(0xFF21545F),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _handleSend,
                  icon: const Icon(Icons.send_rounded),
                  color: const Color(0xFF21545F),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleEscalation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SupplierChatPage(
          customerName: 'Manager Aigerim',
          subtitle: 'Escalation chat',
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isMe});

  final String text;
  final bool isMe;
}
