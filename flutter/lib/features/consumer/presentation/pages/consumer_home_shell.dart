import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import 'consumer_catalog_page_v2.dart';
import 'consumer_chat_list_page.dart';
import 'consumer_dashboard.dart';
import 'consumer_orders_page_v2.dart';
import 'consumer_profile_edit_page.dart';
import 'consumer_supplier_search_page_v2.dart';

enum ConsumerSection {
  dashboard,
  suppliers,
  catalog,
  orders,
  chats,
}

String consumerSectionTitle(ConsumerSection section) {
  switch (section) {
    case ConsumerSection.dashboard:
      return 'Consumer Home';
    case ConsumerSection.suppliers:
      return 'Supplier Search';
    case ConsumerSection.catalog:
      return 'Catalog';
    case ConsumerSection.orders:
      return 'Orders';
    case ConsumerSection.chats:
      return 'Chats';
  }
}

class ConsumerHomeShell extends StatelessWidget {
  const ConsumerHomeShell({
    super.key,
    required this.child,
    required this.title,
    required this.section,
  });

  final Widget child;
  final String title;
  final ConsumerSection section;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF21545F),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(title),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(context, auth),
      body: child,
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: const BoxDecoration(color: Color(0xFF21545F)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFDDE8EB),
                  child: Text(
                    'C',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF21545F),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  auth.currentUser?['username'] as String? ?? 'Consumer',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Consumer',
                  style: TextStyle(
                    color: Color(0xFFC8E9EF),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _DrawerItem(
            icon: Icons.dashboard_outlined,
            label: 'Home Page',
            isActive: section == ConsumerSection.dashboard,
            onTap: () => _navigateToSection(context, ConsumerSection.dashboard),
          ),
          _DrawerItem(
            icon: Icons.link_outlined,
            label: 'Supplier Search',
            isActive: section == ConsumerSection.suppliers,
            onTap: () => _navigateToSection(context, ConsumerSection.suppliers),
          ),
          _DrawerItem(
            icon: Icons.inventory_2_outlined,
            label: 'Catalog',
            isActive: section == ConsumerSection.catalog,
            onTap: () => _navigateToSection(context, ConsumerSection.catalog),
          ),
          _DrawerItem(
            icon: Icons.receipt_long_outlined,
            label: 'Orders',
            isActive: section == ConsumerSection.orders,
            onTap: () => _navigateToSection(context, ConsumerSection.orders),
          ),
          _DrawerItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Chats',
            isActive: section == ConsumerSection.chats,
            onTap: () => _navigateToSection(context, ConsumerSection.chats),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ConsumerProfileEditPage(),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF21545F),
                side: const BorderSide(color: Color(0xFF21545F)),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ElevatedButton.icon(
              onPressed: () {
                auth.clearRole();
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSection(BuildContext context, ConsumerSection targetSection) {
    Navigator.pop(context);
    if (section == targetSection) return;

    Widget destination;
    switch (targetSection) {
      case ConsumerSection.dashboard:
        destination = const ConsumerDashboard();
        break;
      case ConsumerSection.suppliers:
        destination = const ConsumerSupplierSearchPageV2();
        break;
      case ConsumerSection.catalog:
        destination = const ConsumerCatalogPageV2();
        break;
      case ConsumerSection.orders:
        destination = const ConsumerOrdersPageV2();
        break;
      case ConsumerSection.chats:
        destination = const ConsumerChatListPage();
        break;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? const Color(0xFF21545F) : const Color(0xFF1E3E46),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? const Color(0xFF21545F) : const Color(0xFF1E3E46),
        ),
      ),
      onTap: onTap,
    );
  }
}

