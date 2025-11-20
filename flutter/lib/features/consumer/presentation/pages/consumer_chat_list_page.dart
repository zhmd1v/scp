import 'package:flutter/material.dart';

import 'consumer_chat_page.dart';
import 'consumer_home_shell.dart';

class ConsumerChatListPage extends StatefulWidget {
  const ConsumerChatListPage({super.key});

  @override
  State<ConsumerChatListPage> createState() => _ConsumerChatListPageState();
}

class _ConsumerChatListPageState extends State<ConsumerChatListPage> {
  int _selectedTab = 0;

  final List<_ChatSummary> _activeChats = const [
    _ChatSummary(
      name: 'Almaty Produce Hub',
      role: 'Primary supplier',
      lastMessage: 'We can deliver before lunch.',
      time: '09:42',
    ),
    _ChatSummary(
      name: 'Caspi Seafood Group',
      role: 'Seafood partner',
      lastMessage: 'New price list shared.',
      time: 'Yesterday',
    ),
    _ChatSummary(
      name: 'Steppe Dairy Collective',
      role: 'Dairy supplier',
      lastMessage: 'Sample invoice attached.',
      time: 'Mon',
    ),
  ];

  final List<_SupplierContact> _linkedSuppliers = const [
    _SupplierContact(name: 'Almaty Produce Hub', focus: 'Produce'),
    _SupplierContact(name: 'Caspi Seafood Group', focus: 'Seafood'),
    _SupplierContact(name: 'Steppe Dairy Collective', focus: 'Dairy'),
    _SupplierContact(name: 'Nomad Grain Partners', focus: 'Dry goods'),
  ];

  @override
  Widget build(BuildContext context) {
    return ConsumerHomeShell(
      title: consumerSectionTitle(ConsumerSection.chats),
      section: ConsumerSection.chats,
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chat with active suppliers or reach out to a new one.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
          ),
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
  }

  Widget _buildActiveChats(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _activeChats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final chat = _activeChats[index];
        return _ChatTile(
          summary: chat,
          onTap: () => _openChat(context, chat.name),
        );
      },
    );
  }

  Widget _buildLinkedSuppliers(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _linkedSuppliers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final supplier = _linkedSuppliers[index];
        return Container(
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
                  supplier.name.substring(0, 1),
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
                      supplier.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3E46),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${supplier.focus} • No active chat',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _openChat(context, supplier.name),
                child: const Text('Say hi'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openChat(BuildContext context, String supplier) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConsumerChatPage(supplier: supplier),
      ),
    );
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

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.summary, required this.onTap});

  final _ChatSummary summary;
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
                summary.name.substring(0, 1),
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
                    summary.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3E46),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary.role,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Text(
              summary.time,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatSummary {
  const _ChatSummary({
    required this.name,
    required this.role,
    required this.lastMessage,
    required this.time,
  });

  final String name;
  final String role;
  final String lastMessage;
  final String time;
}

class _SupplierContact {
  const _SupplierContact({required this.name, required this.focus});

  final String name;
  final String focus;
}

