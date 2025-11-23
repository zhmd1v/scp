import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../data/supplier_api_service.dart';
import '../../data/supplier_models.dart';
import 'supplier_chat_page.dart';
import 'supplier_home_shell.dart';

class SupplierChatListPage extends StatefulWidget {
  const SupplierChatListPage({super.key});

  @override
  State<SupplierChatListPage> createState() => _SupplierChatListPageState();
}

class _SupplierChatListPageState extends State<SupplierChatListPage> {
  final SupplierApiService _api = SupplierApiService();
  late Future<_ChatLists> _chatFuture;
  _ChatTab _tab = _ChatTab.conversations;

  @override
  void initState() {
    super.initState();
    _chatFuture = _loadData();
  }

  Future<_ChatLists> _loadData() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      throw const AuthException('You are not authenticated.');
    }
    final conversations = await _api.fetchConversations(token: token);
    final links = await _api.fetchConsumerLinks(token: token);
    return _ChatLists(conversations: conversations, links: links);
  }

  Future<void> _refresh() async {
    setState(() {
      _chatFuture = _loadData();
    });
    await _chatFuture;
  }

  Future<void> _handleLinkTap(SupplierLink link) async {
    if (link.consumerId == null) return;

    try {
      final data = await _chatFuture;
      // Check if conversation exists
      final existing = data.conversations.firstWhere(
        (c) => c.consumerId == link.consumerId,
        orElse: () => SupplierConversation(
          id: -1,
          conversationType: '',
          createdAt: DateTime.now(),
        ),
      );

      if (existing.id != -1) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SupplierChatPage(
              conversationId: existing.id,
              customerName: link.consumerName ?? 'Consumer #${link.consumerId}',
              subtitle: 'Consumer chat',
            ),
          ),
        );
        return;
      }

      // Create new conversation
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null) return;

      final newConv = await _api.startConversation(
        token: token,
        consumerId: link.consumerId!,
      );

      if (!mounted) return;
      // Refresh list to include new conversation
      _refresh();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SupplierChatPage(
            conversationId: newConv.id,
            customerName: link.consumerName ?? 'Consumer #${link.consumerId}',
            subtitle: 'Consumer chat',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SupplierHomeShell(
      title: 'Chats',
      section: SupplierSection.chats,
      child: Column(
        children: [
          const SizedBox(height: 16),
          _ChatTabs(
            currentTab: _tab,
            onChanged: (value) => setState(() => _tab = value),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<_ChatLists>(
              future: _chatFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(
                    message: snapshot.error.toString(),
                    onRetry: _refresh,
                  );
                }
                final data = snapshot.data;
                if (data == null) {
                  return const _EmptyState(message: 'No chat data yet.');
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: _tab == _ChatTab.conversations
                      ? _ConversationList(conversations: data.conversations)
                      : _LinkList(
                          links: data.links,
                          onTap: _handleLinkTap,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({required this.conversations});

  final List<SupplierConversation> conversations;

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          _EmptyState(message: 'No active conversations yet.'),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: conversations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final conversation = conversations[index];
        return _ConversationTile(conversation: conversation);
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final SupplierConversation conversation;

  @override
  Widget build(BuildContext context) {
    final updatedAt = conversation.updatedAt;
    final subtitle = updatedAt != null
        ? '${conversation.subtitle} • ${_formatDateTime(updatedAt)}'
        : conversation.subtitle;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SupplierChatPage(
              conversationId: conversation.id,
              customerName: conversation.displayName,
              subtitle: conversation.subtitle,
            ),
          ),
        );
      },
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
                conversation.displayName.substring(0, 1),
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
                    conversation.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3E46),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF21545F)),
          ],
        ),
      ),
    );
  }
}

class _LinkList extends StatelessWidget {
  const _LinkList({
    required this.links,
    required this.onTap,
  });

  final List<SupplierLink> links;
  final ValueChanged<SupplierLink> onTap;

  @override
  Widget build(BuildContext context) {
    final acceptedLinks = links.where((l) => l.isAccepted).toList();

    if (acceptedLinks.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          _EmptyState(message: 'No linked consumers yet.'),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: acceptedLinks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final link = acceptedLinks[index];
        return GestureDetector(
          onTap: () => onTap(link),
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
                    (link.consumerId ?? link.id).toString().substring(0, 1),
                    style: const TextStyle(
                      color: Color(0xFF21545F),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.consumerName ?? 'Consumer #${link.consumerId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3E46),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.people_outline, color: Color(0xFF21545F)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatTabs extends StatelessWidget {
  const _ChatTabs({required this.currentTab, required this.onChanged});

  final _ChatTab currentTab;
  final ValueChanged<_ChatTab> onChanged;

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
            label: 'Conversations',
            tab: _ChatTab.conversations,
            current: currentTab,
            onTap: onChanged,
          ),
          _TabButton(
            label: 'Linked consumers',
            tab: _ChatTab.links,
            current: currentTab,
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
    required this.tab,
    required this.current,
    required this.onTap,
  });

  final String label;
  final _ChatTab tab;
  final _ChatTab current;
  final ValueChanged<_ChatTab> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = tab == current;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
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
              color: isSelected
                  ? const Color(0xFF21545F)
                  : Colors.black.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ChatLists {
  const _ChatLists({
    required this.conversations,
    required this.links,
  });

  final List<SupplierConversation> conversations;
  final List<SupplierLink> links;
}

enum _ChatTab { conversations, links }

String _formatDateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.'
    '${value.month.toString().padLeft(2, '0')} '
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
