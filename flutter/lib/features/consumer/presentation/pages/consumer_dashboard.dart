import 'package:flutter/material.dart';

import 'consumer_catalog_page.dart';
import 'consumer_chat_list_page.dart';
import 'consumer_home_shell.dart';
import 'consumer_orders_page.dart';
import 'consumer_supplier_search_page.dart';

class ConsumerDashboard extends StatelessWidget {
  const ConsumerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ConsumerHomeShell(
      title: 'Consumer Home',
      section: ConsumerSection.dashboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good morning, Chef 👋',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E3E46),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Track supplier links, deliveries, and open requests.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            const _SectionTitle(label: 'Link status'),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(
                  child: _MetricCard(
                    label: 'Approved suppliers',
                    value: '0',
                    bgColor: Color(0xFFDDF3F1),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: 'Pending approvals',
                    value: '0',
                    bgColor: Color(0xFFFFEFE2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(
                  child: _MetricCard(
                    label: 'Open orders',
                    value: '0',
                    bgColor: Color(0xFFE3EDF4),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: 'Active complaints',
                    value: '0',
                    bgColor: Color(0xFFFFF4DB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const _SectionTitle(label: 'Upcoming deliveries'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'No deliveries scheduled yet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3E46),
                          ),
                        ),
                      ),
                      Icon(Icons.delivery_dining, color: Color(0xFF21545F)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const _SectionTitle(label: 'Quick actions'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.search,
                    label: 'Supplier Search',
                    onTap: () => _openSupplierSearch(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.inventory_2_outlined,
                    label: 'Catalog',
                    onTap: () => _openCatalog(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.receipt_long_outlined,
                    label: 'Orders',
                    onTap: () => _openOrders(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Chats',
                    onTap: () => _openChats(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _openSupplierSearch(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const ConsumerSupplierSearchPage(),
    ),
  );
}

void _openCatalog(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const ConsumerCatalogPage(),
    ),
  );
}

void _openOrders(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const ConsumerOrdersPage(),
    ),
  );
}

void _openChats(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const ConsumerChatListPage(),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E3E46),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.bgColor,
  });

  final String label;
  final String value;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3E46),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: const Color(0xFF21545F)),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3E46),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

