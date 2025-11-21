import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../data/supplier_api_service.dart';
import '../../data/supplier_models.dart';
import 'supplier_catalog_page.dart';
import 'supplier_chat_list_page.dart';
import 'supplier_complaints_page.dart';
import 'supplier_home_shell.dart';
import 'supplier_orders_page.dart';

class SupplierDashboard extends StatefulWidget {
  const SupplierDashboard({super.key});

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  final SupplierApiService _api = SupplierApiService();
  Future<_DashboardSnapshot>? _dashboardFuture;
  int? _lastSupplierId;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final supplierId = context.watch<AuthProvider>().supplierId;
    if (_lastSupplierId != supplierId) {
      _lastSupplierId = supplierId;
      _dashboardFuture = _loadDashboard();
    }
  }

  Future<_DashboardSnapshot> _loadDashboard() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      throw const AuthException('You are not authenticated.');
    }

    // Orders hydrate supplier ID for catalog/product stats.
    final orders = await _api.fetchOrders(token: token);
    if (orders.isNotEmpty) {
      auth.hydrateSupplierId(orders.first.supplierId);
    }
    final supplierId = auth.supplierId;

    final productsFuture = supplierId == null
        ? Future.value(<SupplierProduct>[])
        : _api.fetchSupplierProducts(token: token, supplierId: supplierId);
    final complaintsFuture = _api.fetchComplaints(token: token);
    final conversationsFuture = _api.fetchConversations(token: token);

    final products = await productsFuture;
    final complaints = await complaintsFuture;
    final conversations = await conversationsFuture;

    return _DashboardSnapshot(
      orders: orders,
      products: products,
      complaints: complaints,
      conversations: conversations,
      supplierId: supplierId,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
    await _dashboardFuture;
  }

  Future<void> _promptSupplierId() async {
    final controller = TextEditingController(
      text: context.read<AuthProvider>().supplierId?.toString() ?? '',
    );
    final newId = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set supplier ID'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter supplier ID from backend',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                Navigator.pop(ctx, parsed);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newId != null) {
      context.read<AuthProvider>().setSupplierId(newId);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SupplierHomeShell(
      title: 'Supplier Home Page',
      section: SupplierSection.dashboard,
      child: FutureBuilder<_DashboardSnapshot>(
        future: _dashboardFuture,
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
            return _ErrorState(
              message: 'Unable to load dashboard data.',
              onRetry: _refresh,
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Welcome back! 👋',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3E46),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Here's what's happening today",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Pending Orders',
                        value: data.pendingOrders.toString(),
                        bgColor: const Color(0xFFE3EDF4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Low Stock',
                        value: data.lowStockCount.toString(),
                        bgColor: const Color(0xFFFFEFE2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Active Chats',
                        value: data.activeChats.toString(),
                        bgColor: const Color(0xFFDDF3F1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Complaints',
                        value: data.openComplaintsCount.toString(),
                        bgColor: const Color(0xFFFFF4DB),
                      ),
                    ),
                  ],
                ),
                if (data.supplierId == null) ...[
                  const SizedBox(height: 18),
                  _MissingSupplierBanner(onSetSupplierId: _promptSupplierId),
                ],
                const SizedBox(height: 28),
                const Text(
                  'Low stock alerts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3E46),
                  ),
                ),
                const SizedBox(height: 12),
                if (data.lowStockProducts.isEmpty)
                  const _EmptyState(
                    message: 'Great! None of your catalog items are running low.',
                  )
                else
                  ...data.lowStockProducts.take(3).map(
                        (product) => _LowStockTile(product: product),
                      ),
                const SizedBox(height: 28),
                const Text(
                  'Pending orders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3E46),
                  ),
                ),
                const SizedBox(height: 12),
                if (data.pendingOrders == 0)
                  const _EmptyState(message: 'No pending orders right now.')
                else
                  ...data.pendingOrderSamples.map(
                    (order) => _PendingOrderTile(order: order),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3E46),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _QuickButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chats',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SupplierChatListPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickButton(
                        icon: Icons.inventory_2_rounded,
                        label: 'Catalog',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SupplierCatalogPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickButton(
                        icon: Icons.receipt_long_rounded,
                        label: 'Orders',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SupplierOrdersPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickButton(
                        icon: Icons.report_problem_outlined,
                        label: 'Complaints',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SupplierComplaintsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
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

class _QuickButton extends StatelessWidget {
  const _QuickButton({
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

class _LowStockTile extends StatelessWidget {
  const _LowStockTile({required this.product});

  final SupplierProduct product;

  @override
  Widget build(BuildContext context) {
    final stock = product.stockQuantity ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
          const Icon(Icons.inventory_2_outlined, color: Color(0xFF21545F)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3E46),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stock.toStringAsFixed(2)} ${product.unit ?? ''} left',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          _buildStockBadge(stock),
        ],
      ),
    );
  }
}

Widget _buildStockBadge(double stock) {
  late final Color color;
  late final String label;

  if (stock <= 0) {
    color = Colors.redAccent;
    label = 'Out';
  } else if (stock < 5) {
    color = Colors.orangeAccent;
    label = 'Low';
  } else {
    color = Colors.green;
    label = 'OK';
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _PendingOrderTile extends StatelessWidget {
  const _PendingOrderTile({required this.order});

  final SupplierOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3E46),
                  ),
                ),
              ),
              Text(
                '${order.items.length} items',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.deliveryAddress ?? 'No delivery address provided',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            '${order.totalAmount?.toStringAsFixed(0) ?? '—'} ₸ total',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF21545F),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingSupplierBanner extends StatelessWidget {
  const _MissingSupplierBanner({required this.onSetSupplierId});

  final VoidCallback onSetSupplierId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Supplier ID needed',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7A4E00),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Set your supplier ID so we can load catalog and stock data from the backend.',
            style: TextStyle(
              color: Color(0xFF7A4E00),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onSetSupplierId,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7A4E00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Set supplier ID'),
          ),
        ],
      ),
    );
  }
}

class _DashboardSnapshot {
  const _DashboardSnapshot({
    required this.orders,
    required this.products,
    required this.complaints,
    required this.conversations,
    required this.supplierId,
  });

  final List<SupplierOrder> orders;
  final List<SupplierProduct> products;
  final List<SupplierComplaint> complaints;
  final List<SupplierConversation> conversations;
  final int? supplierId;

  int get pendingOrders => orders.where((order) => order.isPending).length;

  int get lowStockCount =>
      products.where((product) => product.isLowStock || product.isOutOfStock).length;

  List<SupplierProduct> get lowStockProducts =>
      (products.where((product) => product.isLowStock || product.isOutOfStock).toList()
            ..sort(
              (a, b) => (a.stockQuantity ?? 0).compareTo(b.stockQuantity ?? 0),
            ))
          .take(6)
          .toList();

  int get activeChats => conversations.length;

  int get openComplaintsCount =>
      complaints.where((complaint) => !complaint.isResolved).length;

  List<SupplierOrder> get pendingOrderSamples =>
      orders.where((order) => order.isPending).take(3).toList();
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.black54, fontSize: 13),
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
