import 'package:flutter/material.dart';

import 'supplier_chat_page.dart';
import 'supplier_home_shell.dart';

class SupplierChatListPage extends StatefulWidget {
  const SupplierChatListPage({super.key});

  @override
  State<SupplierChatListPage> createState() => _SupplierChatListPageState();
}

class _SupplierChatListPageState extends State<SupplierChatListPage> {
  int _selectedTab = 0;

  final List<_ChatSummary> _activeChats = [
    _ChatSummary(
      name: 'Restaurant A',
      lastMessage: 'Can you deliver 5kg salmon?',
      time: '12:45',
      role: 'Consumer',
    ),
    _ChatSummary(
      name: 'Hotel SunRise',
      lastMessage: 'Thank you! Waiting for delivery.',
      time: '11:10',
      role: 'Consumer',
    ),
    _ChatSummary(
      name: 'Aigerim • Manager',
      lastMessage: 'Sales rep escalated complaint #145',
      time: 'Yesterday',
      role: 'Manager',
    ),
  ];

  final List<_Contact> _linkedContacts = [
    _Contact(name: 'Grand Plaza Hotel', role: 'Consumer'),
    _Contact(name: 'Bistro Nomad', role: 'Consumer'),
    _Contact(name: 'Aidyn • Owner', role: 'Owner'),
  ];

  @override
  Widget build(BuildContext context) {
    return SupplierHomeShell(
      title: 'Chats',
      section: SupplierSection.chats,
      child: Column(
        children: [
          const SizedBox(height: 16),
          _ChatTabs(
            selectedIndex: _selectedTab,
            onChanged: (value) => setState(() => _selectedTab = value),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _selectedTab == 0
                ? _buildActiveChats(context)
                : _buildLinkedConsumers(context),
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
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SupplierChatPage(
                  customerName: chat.name,
                  subtitle: chat.role,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLinkedConsumers(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _linkedContacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final contact = _linkedContacts[index];
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
                  contact.name.substring(0, 1),
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
                      contact.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3E46),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${contact.role} • No conversation yet',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SupplierChatPage(
                        customerName: contact.name,
                        subtitle: contact.role,
                      ),
                    ),
                  );
                },
                child: const Text('Say hi'),
              ),
            ],
          ),
        );
      },
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
            label: 'All Consumers',
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
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
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
  _ChatSummary({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.role,
  });

  final String name;
  final String lastMessage;
  final String time;
  final String role;
}

class _Contact {
  _Contact({required this.name, required this.role});

  final String name;
  final String role;
}
