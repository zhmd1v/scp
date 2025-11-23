import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../config/api_config.dart';
import '../../data/consumer_api_service.dart';
import '../../data/consumer_models.dart';
import '../../../../providers/auth_provider.dart';

class ConsumerChatPage extends StatefulWidget {
  const ConsumerChatPage({
    super.key,
    required this.supplier,
    this.conversationId,
    this.supplierId,
  });

  final String supplier;
  final int? conversationId;
  final int? supplierId;

  @override
  State<ConsumerChatPage> createState() => _ConsumerChatPageState();
}

class _ConsumerChatPageState extends State<ConsumerChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ConsumerApiService _api = ConsumerApiService();
  List<ConsumerMessage> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (widget.conversationId == null) {
      setState(() {
        _isLoading = false;
        _messages = [];
      });
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token ?? '';
      final userId = authProvider.currentUser?['id'] as int? ?? 0;

      final messages = await _api.fetchMessages(
        token: token,
        conversationId: widget.conversationId!,
        currentUserId: userId,
      );

      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.supplier),
        backgroundColor: const Color(0xFF21545F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: _openCatalogQuickPick,
            tooltip: 'Open catalog',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Error: $_error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      )
                    : _messages.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'No messages yet. Start the conversation!',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (_, index) {
                              final message = _messages[index];
                              final isMe = message.isFromMe;
                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(12),
                                  constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.7),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color(0xFF21545F)
                                        : const Color(0xFFE3EDF4),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      if (message.attachmentUrl != null) ...[
                                        _buildAttachmentWidget(message.attachmentUrl!, isMe),
                                        if (message.text.isNotEmpty) const SizedBox(height: 8),
                                      ],
                                      if (message.text.isNotEmpty)
                                        Text(
                                          message.text,
                                          style: TextStyle(
                                            color:
                                                isMe ? Colors.white : const Color(0xFF1E3E46),
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTimestamp(message.createdAt),
                                        style: TextStyle(
                                          color: isMe ? Colors.white70 : Colors.black45,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          _MessageInput(
            controller: _controller,
            onSend: _handleSendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendMessage(String text) async {
    if (text.trim().isEmpty) return;

    if (widget.conversationId == null && widget.supplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send message: No conversation or supplier info')),
      );
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token ?? '';

      // If no conversation exists, create one with the supplier
      int conversationId = widget.conversationId ?? 0;
      
      if (conversationId == 0 && widget.supplierId != null) {
        // Create new conversation
        final response = await _api.post(
          '/api/chat/conversations/',
          token: token,
          body: {
            'supplier': widget.supplierId,
            'conversation_type': 'supplier_consumer',
          },
        );
        
        if (response.statusCode >= 400) {
          throw Exception('Failed to create conversation');
        }
        
        final data = _api.decodeToMap(response.body);
        conversationId = data['id'] as int;
        
        // Now send the message to the newly created conversation
        await _api.sendMessage(
          token: token,
          conversationId: conversationId,
          text: text.trim(),
        );
        
        // Reload the page with the new conversation ID
        if (mounted) {
          _controller.clear();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ConsumerChatPage(
                supplier: widget.supplier,
                conversationId: conversationId,
                supplierId: widget.supplierId,
              ),
            ),
          );
        }
        return;
      }

      await _api.sendMessage(
        token: token,
        conversationId: conversationId,
        text: text.trim(),
      );

      _controller.clear();
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  String _formatTimestamp(DateTime dateTime) {
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

  Future<void> _openCatalogQuickPick() async {
    if (widget.supplierId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please open this chat from your linked suppliers to view products')),
        );
      }
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token ?? '';

      final products = await _api.fetchSupplierProducts(
        token: token,
        supplierId: widget.supplierId!,
      );

      if (!mounted) return;

      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No products available')),
        );
        return;
      }

      // Show cart snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: _QuickOrderCart(
            products: products,
            supplierId: widget.supplierId!,
            supplierName: widget.supplier,
          ),
          duration: const Duration(days: 1), // Keep it open
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
          elevation: 8,
          padding: EdgeInsets.zero,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
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
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 150,
                alignment: Alignment.center,
                child: Icon(
                  Icons.broken_image,
                  color: isMe ? Colors.white70 : Colors.grey,
                ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File: $fileName')),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                fileIcon,
                color: isMe ? Colors.white : const Color(0xFF21545F),
                size: 32,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  fileName,
                  style: TextStyle(
                    color: isMe ? Colors.white : const Color(0xFF1E3E46),
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

class _MessageInput extends StatelessWidget {
  const _MessageInput({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            color: const Color(0xFF21545F),
            onPressed: () => _pickImage(context),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Message supplier',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            color: const Color(0xFF21545F),
            onPressed: () => onSend(controller.text),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to get file path')),
          );
        }
        return;
      }

      if (context.mounted) {
        await _sendImage(context, file.path!);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  Future<void> _sendImage(BuildContext context, String imagePath) async {
    final chatPageState = context.findAncestorStateOfType<_ConsumerChatPageState>();
    if (chatPageState == null) return;

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token ?? '';
      
      if (chatPageState.widget.conversationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot send image: No conversation')),
        );
        return;
      }

      await chatPageState._api.sendMessageWithImage(
        token: token,
        conversationId: chatPageState.widget.conversationId!,
        imagePath: imagePath,
        text: controller.text.trim().isEmpty ? null : controller.text.trim(),
      );

      controller.clear();
      await chatPageState._loadMessages();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    }
  }
}

class _QuickOrderCart extends StatefulWidget {
  const _QuickOrderCart({
    required this.products,
    required this.supplierId,
    required this.supplierName,
  });

  final List<ConsumerProduct> products;
  final int supplierId;
  final String supplierName;

  @override
  State<_QuickOrderCart> createState() => _QuickOrderCartState();
}

class _QuickOrderCartState extends State<_QuickOrderCart> {
  final Map<int, int> _cart = {}; // productId -> quantity
  final ConsumerApiService _api = ConsumerApiService();
  DateTime? _requestedDate;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _total {
    double sum = 0;
    for (var entry in _cart.entries) {
      final product = widget.products.firstWhere((p) => p.id == entry.key);
      sum += product.price * entry.value;
    }
    return sum;
  }

  void _updateQuantity(int productId, int delta) {
    setState(() {
      final current = _cart[productId] ?? 0;
      final newQuantity = current + delta;
      if (newQuantity <= 0) {
        _cart.remove(productId);
      } else {
        _cart[productId] = newQuantity;
      }
    });
  }

  Future<void> _placeOrder(BuildContext context) async {
    if (_cart.isEmpty) return;

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token ?? '';

      // Build order items
      final orderItems = _cart.entries.map((entry) {
        final product = widget.products.firstWhere((p) => p.id == entry.key);
        return ConsumerOrderItem(
          productId: product.id,
          productName: product.name,
          quantity: entry.value.toDouble(),
          unitPrice: product.price,
          lineTotal: product.price * entry.value,
        );
      }).toList();

      // Get address from profile
      final userProfile = authProvider.currentUser?['consumer_profile'] as Map<String, dynamic>?;
      final address = userProfile?['address'] as String? ?? 'Address not provided';

      // Create order
      final order = ConsumerOrder(
        id: 0,
        supplierId: widget.supplierId,
        supplierName: widget.supplierName,
        status: 'pending',
        deliveryAddress: address,
        requestedDeliveryDate: _requestedDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        items: orderItems,
      );

      print('Creating order with payload: ${order.toJson()}');

      await _api.createOrder(token: token, order: order);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 600),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quick Order',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF21545F),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ],
            ),
          ),
          // Products list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.products.length,
              itemBuilder: (context, index) {
                final product = widget.products[index];
                final quantity = _cart[product.id] ?? 0;
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF21545F),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: quantity > 0
                                ? () => _updateQuantity(product.id, -1)
                                : null,
                            color: const Color(0xFF21545F),
                            iconSize: 24,
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '$quantity',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF21545F),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _updateQuantity(product.id, 1),
                            color: const Color(0xFF21545F),
                            iconSize: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Date and Notes
          if (_cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null) {
                        setState(() => _requestedDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF21545F)),
                          const SizedBox(width: 12),
                          Text(
                            _requestedDate == null
                                ? 'Select requested delivery date'
                                : '${_requestedDate!.day}/${_requestedDate!.month}/${_requestedDate!.year}',
                            style: TextStyle(
                              color: _requestedDate == null
                                  ? Colors.grey.shade600
                                  : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Add notes...',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF21545F)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Order button
          if (_cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _placeOrder(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF21545F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Order • \$${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
