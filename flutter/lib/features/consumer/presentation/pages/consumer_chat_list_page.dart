import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../data/consumer_api_service.dart';
import '../../data/consumer_models.dart';
import 'consumer_chat_page.dart';
import 'consumer_home_shell.dart';

class ConsumerChatListPage extends StatefulWidget {
  const ConsumerChatListPage({super.key});

  @override
  State<ConsumerChatListPage> createState() => _ConsumerChatListPageState();
}

class _ConsumerChatListPageState extends State<ConsumerChatListPage> {
  final ConsumerApiService _api = ConsumerApiService();
  int _selectedTab = 0;
  late Future<_ChatData> _dataFuture;
  List<ConsumerConversation> _conversations = [];
  List<ConsumerSupplierLink> _links = [];

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_ChatData> _loadData() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      throw const AuthException('You are not authenticated.');
    }

    final conversations = await _api.fetchConversations(token: token);
    final links = await _api.fetchLinks(token: token);
    
    // Filter out empty chats and duplicates
    final uniqueConversations = <int, ConsumerConversation>{};
    for (final conv in conversations) {
      if (conv.lastMessage != null && conv.lastMessage!.isNotEmpty) {
        // Keep the most recent one if duplicates exist (though backend should handle this)
        if (!uniqueConversations.containsKey(conv.supplierId)) {
          uniqueConversations[conv.supplierId] = conv;
        }
      }
    }

    _conversations = uniqueConversations.values.toList();
    _links = links.where((l) => l.isAccepted).toList();

    return _ChatData(conversations: conversations, links: _links);
  }

  Future<void> _refresh() async {
    setState(() {
      _dataFuture = _loadData();
    });
    await _dataFuture;
  }

  @override
  Widget build(BuildContext context) {
    return ConsumerHomeShell(
      title: consumerSectionTitle(ConsumerSection.chats),
      section: ConsumerSection.chats,
      child: FutureBuilder<_ChatData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                const SizedBox(height: 12),
                _ChatTabs(
                  selectedIndex: _selectedTab,
                  onChanged: (value) => setState(() => _selectedTab = value),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _selectedTab == 0
                      ? _buildActiveChats(context)
                      : _buildLinkedSuppliers(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveChats(BuildContext context) {
    if (_conversations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No active chats yet. Start a conversation with a linked supplier.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _conversations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final conversation = _conversations[index];
        return _ConversationTile(
          conversation: conversation,
          onTap: () => _openChat(context, conversation),
        );
      },
    );
  }

  Widget _buildLinkedSuppliers(BuildContext context) {
    if (_links.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No linked suppliers yet. Request access to suppliers first.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _links.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final link = _links[index];
        return GestureDetector(
          onTap: () => _openChatWithSupplier(context, link.supplier),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFDDE8EB),
                child: Text(
                  link.supplier.companyName.substring(0, 1),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF21545F),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.supplier.companyName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3E46),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${link.supplier.city ?? "Supplier"} ',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _openChatWithSupplier(context, link.supplier),
                child: const Text('Say hi'),
              ),
            ],
          ),
        ));
      },
    );
  }

  void _openChat(BuildContext context, ConsumerConversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConsumerChatPage(
          supplier: conversation.supplierName,
          conversationId: conversation.id,
          supplierId: conversation.supplierId,
        ),
      ),
    );
  }

  void _openChatWithSupplier(BuildContext context, ConsumerSupplier supplier) {
    // Check if we already have a conversation with this supplier
    int? conversationId;
    try {
      final existing = _conversations.firstWhere(
        (c) => c.supplierId == supplier.id,
      );
      conversationId = existing.id;
    } catch (_) {
      // No existing conversation found
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConsumerChatPage(
          supplier: supplier.companyName,
          supplierId: supplier.id,
          conversationId: conversationId,
        ),
      ),
    );
  }
}

class _ChatData {
  const _ChatData({required this.conversations, required this.links});
  
  final List<ConsumerConversation> conversations;
  final List<ConsumerSupplierLink> links;
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final ConsumerConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFA7E1D5),
              child: Text(
                conversation.supplierName.substring(0, 1),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF21545F),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.supplierName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3E46),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Text(
              _formatTimestamp(conversation.lastMessageAt ?? DateTime.now()),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}

class _ChatTabs extends StatelessWidget {
  const _ChatTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE8EB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Active',
            index: 0,
            selectedIndex: selectedIndex,
            onTap: onChanged,
          ),
          _TabButton(
            label: 'Linked Suppliers',
            index: 1,
            selectedIndex: selectedIndex,
            onTap: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color:
                  isSelected ? const Color(0xFF21545F) : Colors.black.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}
