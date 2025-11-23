import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../config/api_config.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';
import '../../data/supplier_api_service.dart';
import '../../data/supplier_models.dart';

class SupplierChatPage extends StatefulWidget {
  const SupplierChatPage({
    super.key,
    required this.conversationId,
    required this.customerName,
    this.subtitle = 'Linked consumer',
  });

  final int conversationId;
  final String customerName;
  final String subtitle;

  @override
  State<SupplierChatPage> createState() => _SupplierChatPageState();
}

class _SupplierChatPageState extends State<SupplierChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final SupplierApiService _api = SupplierApiService();

  List<SupplierMessage> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final auth = context.read<AuthProvider>();
    final token = auth.token;
    final userId = auth.currentUser?['id'] as int?;
    if (token == null || userId == null) {
      setState(() {
        _error = 'You are not authenticated.';
        _isLoading = false;
      });
      return;
    }

    try {
      final messages = await _api.fetchMessages(
        token: token,
        conversationId: widget.conversationId,
        currentUserId: userId,
      );
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      await _api.markConversationRead(
        token: token,
        conversationId: widget.conversationId,
      );
    } on ApiServiceException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      setState(() => _error = 'You are not authenticated.');
      return;
    }

    _messageController.clear();

    try {
      await _api.sendMessage(
        token: token,
        conversationId: widget.conversationId,
        text: text,
      );
      await _loadMessages(silent: true);
    } on ApiServiceException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMessages),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file_outlined),
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

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_messages.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'No messages yet. Say hi to start the conversation!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      );
    }

    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (_, index) {
        final message = _messages[index];
        final isMe = message.isMine;
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.attachmentUrl != null) ...[
                  _buildAttachmentWidget(message.attachmentUrl!, isMe),
                  if (message.text.isNotEmpty) const SizedBox(height: 8),
                ],
                if (message.text.isNotEmpty)
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF1E3E46),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(message.sentAt),
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) {
        if (mounted) {
          setState(() => _error = 'Failed to get file path');
        }
        return;
      }

      await _sendImage(file.path!);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to pick file: $e');
      }
    }
  }

  Future<void> _sendImage(String imagePath) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      setState(() => _error = 'You are not authenticated.');
      return;
    }

    try {
      await _api.sendMessageWithImage(
        token: token,
        conversationId: widget.conversationId,
        imagePath: imagePath,
        text: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
      );
      
      _messageController.clear();
      await _loadMessages(silent: true);
    } on ApiServiceException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Failed to send image: $e');
    }
  }

  String _buildImageUrl(String attachmentUrl) {
    if (attachmentUrl.startsWith('http')) {
      return attachmentUrl;
    }
    const baseUrl = kBackendBaseUrl;
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = attachmentUrl.startsWith('/') ? attachmentUrl : '/$attachmentUrl';
    return '$normalizedBase$normalizedPath';
  }

  Widget _buildAttachmentWidget(String attachmentUrl, bool isMe) {
    final extension = attachmentUrl.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(extension);

    if (isImage) {
      return GestureDetector(
        onTap: () => _showFullScreenImage(attachmentUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _buildImageUrl(attachmentUrl),
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 150,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 150,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        ),
      );
    } else {
      // For PDFs, DOCs, etc., show a file icon with name
      final fileName = attachmentUrl.split('/').last;
      IconData fileIcon;
      if (extension == 'pdf') {
        fileIcon = Icons.picture_as_pdf;
      } else if (extension == 'doc' || extension == 'docx') {
        fileIcon = Icons.description;
      } else {
        fileIcon = Icons.insert_drive_file;
      }

      return GestureDetector(
        onTap: () {
          // TODO: Implement file download/viewing
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('File: $fileName')),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF21545F).withOpacity(0.3) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                fileIcon,
                color: const Color(0xFF21545F),
                size: 32,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  fileName,
                  style: const TextStyle(
                    color: Color(0xFF1E3E46),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                _buildImageUrl(imageUrl),
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, color: Colors.white, size: 64);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
