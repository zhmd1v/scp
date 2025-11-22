import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import 'supplier_catalog_page.dart';
import 'supplier_chat_list_page.dart';
import 'supplier_complaints_page.dart';
import 'supplier_dashboard.dart';
import 'supplier_orders_page.dart';

enum SupplierSection { dashboard, chats, catalog, orders, complaints }

class SupplierHomeShell extends StatelessWidget {
  const SupplierHomeShell({
    super.key,
    required this.child,
    required this.title,
    required this.section,
  });

  final Widget child;
  final String title;
  final SupplierSection section;

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
                    'S',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF21545F),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  auth.currentUser?['username'] as String? ?? 'Supplier',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sales Representative',
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
            isActive: section == SupplierSection.dashboard,
            onTap: () {
              Navigator.pop(context);
              if (section != SupplierSection.dashboard) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SupplierDashboard()),
                );
              }
            },
          ),
          _DrawerItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Chats',
            isActive: section == SupplierSection.chats,
            onTap: () {
              Navigator.pop(context);
              if (section != SupplierSection.chats) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const SupplierChatListPage(),
                  ),
                );
              }
            },
          ),
          _DrawerItem(
            icon: Icons.inventory_2_rounded,
            label: 'Catalog',
            isActive: section == SupplierSection.catalog,
            onTap: () {
              Navigator.pop(context);
              if (section != SupplierSection.catalog) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const SupplierCatalogPage(),
                  ),
                );
              }
            },
          ),
          _DrawerItem(
            icon: Icons.receipt_long_rounded,
            label: 'Orders',
            isActive: section == SupplierSection.orders,
            onTap: () {
              Navigator.pop(context);
              if (section != SupplierSection.orders) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SupplierOrdersPage()),
                );
              }
            },
          ),
          _DrawerItem(
            icon: Icons.report_problem_outlined,
            label: 'Complaints',
            isActive: section == SupplierSection.complaints,
            onTap: () {
              Navigator.pop(context);
              if (section != SupplierSection.complaints) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const SupplierComplaintsPage(),
                  ),
                );
              }
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: () {
                auth.clearRole();
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
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
