import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';
import '../../data/supplier_api_service.dart';
import '../../data/supplier_models.dart';
import 'supplier_home_shell.dart';

class SupplierOrdersPage extends StatefulWidget {
  const SupplierOrdersPage({super.key});

  @override
  State<SupplierOrdersPage> createState() => _SupplierOrdersPageState();
}

class _SupplierOrdersPageState extends State<SupplierOrdersPage> {
  final SupplierApiService _api = SupplierApiService();
  late Future<List<SupplierOrder>> _ordersFuture;
  List<SupplierOrder> _orders = [];
  _OrderFilter _filter = _OrderFilter.all;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<SupplierOrder>> _loadOrders() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      throw const AuthException('You are not authenticated.');
    }
    final orders = await _api.fetchOrders(token: token);
    if (orders.isNotEmpty) {
      auth.hydrateSupplierId(orders.first.supplierId);
    }
    _orders = orders;
    return orders;
  }

  Future<void> _refresh() async {
    setState(() {
      _ordersFuture = _loadOrders();
    });
    await _ordersFuture;
  }


  List<SupplierOrder> get _filteredOrders {
    switch (_filter) {
      case _OrderFilter.pending:
        return _orders.where((order) => order.isPending).toList();
      case _OrderFilter.active:
        return _orders.where((order) => order.isActive).toList();
      case _OrderFilter.completed:
        return _orders.where((order) => order.isCompleted).toList();
      case _OrderFilter.all:
        return _orders;
    }
    return _orders;
  }

  @override
  Widget build(BuildContext context) {
    return SupplierHomeShell(
      title: 'Orders',
      section: SupplierSection.orders,
      child: Column(
        children: [
          const SizedBox(height: 16),
          _StatusTabs(
            currentFilter: _filter,
            onChanged: (filter) => setState(() => _filter = filter),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<SupplierOrder>>(
              future: _ordersFuture,
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
                if (_orders.isEmpty) {
                  return const _EmptyState(
                    message: 'No orders found for your supplier account yet.',
                  );
                }
                final orders = _filteredOrders;
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final order = orders[index];
                      return _OrderCard(
                        order: order,
                      );
                    },
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

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.currentFilter,
    required this.onChanged,
  });

  final _OrderFilter currentFilter;
  final ValueChanged<_OrderFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (_OrderFilter.all, 'All'),
      (_OrderFilter.pending, 'Pending'),
      (_OrderFilter.active, 'Active'),
      (_OrderFilter.completed, 'Completed'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE8EB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: tabs.map((entry) {
          final isSelected = entry.$1 == currentFilter;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
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
                  entry.$2,
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
        }).toList(),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
  });

  final SupplierOrder order;

  @override
  Widget build(BuildContext context) {
    final consumerLabel = order.consumerName ??
        (order.consumerId != null ? 'Consumer #${order.consumerId}' : 'Consumer');
    final total = order.totalAmount ?? 0;
    final createdAt = order.createdAt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                  consumerLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3E46),
                  ),
                ),
              ),
              _StatusChip(order: order),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Order #${order.id}',
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          if (createdAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Placed on: ${_formatDate(createdAt)}',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _IconDetail(
                icon: Icons.inventory_2_outlined,
                label: '${order.items.length} items',
              ),
              const SizedBox(width: 16),
              _IconDetail(
                icon: Icons.attach_money,
                label: '${total.toStringAsFixed(0)} ₸',
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _openDetails(context, order),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF21545F),
              side: const BorderSide(color: Color(0xFF21545F)),
              minimumSize: const Size(double.infinity, 44),
            ),
            child: const Text('View order'),
          ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context, SupplierOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${order.id}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3E46),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.deliveryAddress?.isNotEmpty == true
                    ? order.deliveryAddress!
                    : 'No delivery address provided',
              ),
              const SizedBox(height: 16),
              const Text(
                'Items',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3E46),
                ),
              ),
              const SizedBox(height: 8),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '• ${item.productName} — '
                    '${item.quantity.toStringAsFixed(2)} ${item.unit ?? ''} '
                    'x ${item.unitPrice.toStringAsFixed(0)} ₸',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF21545F),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.order});

  final SupplierOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: order.statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        order.statusLabel,
        style: TextStyle(
          color: order.statusColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _IconDetail extends StatelessWidget {
  const _IconDetail({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF21545F)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
      ],
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
        style: const TextStyle(color: Colors.black54),
        textAlign: TextAlign.center,
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

enum _OrderFilter { all, pending, active, completed }

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.'
    '${date.month.toString().padLeft(2, '0')}.'
    '${date.year}';
