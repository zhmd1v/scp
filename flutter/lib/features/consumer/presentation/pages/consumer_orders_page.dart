import 'package:flutter/material.dart';

import 'consumer_home_shell.dart';

class ConsumerOrdersPage extends StatefulWidget {
  const ConsumerOrdersPage({super.key});

  @override
  State<ConsumerOrdersPage> createState() => _ConsumerOrdersPageState();
}

class _ConsumerOrdersPageState extends State<ConsumerOrdersPage> {
  final List<_OrderSummary> _orders = const [
    _OrderSummary(
      id: 'ORD-1024',
      supplier: 'Almaty Produce Hub',
      category: 'Produce',
      status: OrderStatus.enRoute,
      placedAt: 'Sep 17, 07:45',
      eta: 'Today 10:30',
      shippingAddress: 'Gagarin 12, Almaty',
      items: [
        _OrderItem(name: 'Baby spinach', quantity: '6 kg'),
        _OrderItem(name: 'Cherry tomatoes', quantity: '8 kg'),
      ],
    ),
    _OrderSummary(
      id: 'ORD-0998',
      supplier: 'Caspi Seafood Group',
      category: 'Seafood',
      status: OrderStatus.preparing,
      placedAt: 'Sep 16, 18:10',
      eta: 'Sep 18, 09:00',
      shippingAddress: 'Auezov 77, Almaty',
      items: [
        _OrderItem(name: 'Salmon fillet', quantity: '12 kg'),
        _OrderItem(name: 'Tiger prawns', quantity: '6 kg'),
      ],
    ),
    _OrderSummary(
      id: 'ORD-0955',
      supplier: 'Steppe Dairy Collective',
      category: 'Dairy',
      status: OrderStatus.delivered,
      placedAt: 'Sep 14, 09:15',
      eta: 'Delivered Sep 15, 11:05',
      shippingAddress: 'Baitursynov 40, Almaty',
      items: [
        _OrderItem(name: 'Buffalo mozzarella', quantity: '10 kg'),
      ],
    ),
  ];

  OrderStatusFilter _selectedFilter = OrderStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _orders.where(_matchesFilter).toList();

    return ConsumerHomeShell(
      title: consumerSectionTitle(ConsumerSection.orders),
      section: ConsumerSection.orders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Monitor fulfillment and dive into details with one tap.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: OrderStatusFilter.values
                .map(
                  (filter) => ChoiceChip(
                    label: Text(filter.label),
                    selected: _selectedFilter == filter,
                    onSelected: (_) =>
                        setState(() => _selectedFilter = filter),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          ...filteredOrders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _OrderCard(
                order: order,
                onTap: () => _openOrderDetails(order),
              ),
            ),
          ),
          if (filteredOrders.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE3EDF4)),
              ),
              child: const Text(
                'No orders match this filter.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }

  bool _matchesFilter(_OrderSummary order) {
    switch (_selectedFilter) {
      case OrderStatusFilter.all:
        return true;
      case OrderStatusFilter.inProgress:
        return order.status == OrderStatus.preparing ||
            order.status == OrderStatus.enRoute;
      case OrderStatusFilter.delivered:
        return order.status == OrderStatus.delivered;
    }
  }

  void _openOrderDetails(_OrderSummary order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _OrderDetailsPage(order: order),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  final _OrderSummary order;
  final VoidCallback onTap;

  Color _statusColor() {
    switch (order.status) {
      case OrderStatus.preparing:
        return const Color(0xFFF39C12);
      case OrderStatus.enRoute:
        return const Color(0xFF1E88E5);
      case OrderStatus.delivered:
        return const Color(0xFF1E9E70);
    }
  }

  String _statusLabel() {
    switch (order.status) {
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.enRoute:
        return 'On the way';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 8),
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
                    order.supplier,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E3E46),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${order.category} • ${order.id}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              'ETA: ${order.eta}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailsPage extends StatelessWidget {
  const _OrderDetailsPage({required this.order});

  final _OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(order.id),
        backgroundColor: const Color(0xFF21545F),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailRow(label: 'Supplier', value: order.supplier),
          _DetailRow(label: 'Category', value: order.category),
          _DetailRow(label: 'Status', value: order.status.name.toUpperCase()),
          _DetailRow(label: 'Placed', value: order.placedAt),
          _DetailRow(label: 'ETA', value: order.eta),
          _DetailRow(label: 'Delivery address', value: order.shippingAddress),
          const SizedBox(height: 18),
          const Text(
            'Items',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3E46),
            ),
          ),
          const SizedBox(height: 8),
          ...order.items.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(entry.name),
              trailing: Text(entry.quantity),
            ),
          ),
          const SizedBox(height: 20),
          if (order.status == OrderStatus.delivered) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order duplicated to draft')),
                  );
                },
                icon: const Icon(Icons.repeat),
                label: const Text('Reorder this delivery'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton.icon(
            onPressed: () => _openComplaintSheet(context),
            icon: const Icon(Icons.report_gmailerrorred_outlined),
            label: const Text('Submit complaint'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openComplaintSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final TextEditingController descController = TextEditingController();
        String selectedCategory = 'Delayed delivery';

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Log complaint',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Complaint category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Delayed delivery',
                        child: Text('Delayed delivery'),
                      ),
                      DropdownMenuItem(
                        value: 'Bad quality',
                        child: Text('Bad product quality'),
                      ),
                      DropdownMenuItem(
                        value: 'Missing items',
                        child: Text('Missing items'),
                      ),
                      DropdownMenuItem(
                        value: 'Other',
                        child: Text('Other'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => selectedCategory = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Describe the issue',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Complaint submitted ($selectedCategory)',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF21545F),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Submit to supplier'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF1E3E46)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSummary {
  const _OrderSummary({
    required this.id,
    required this.supplier,
    required this.category,
    required this.status,
    required this.placedAt,
    required this.eta,
    required this.shippingAddress,
    required this.items,
  });

  final String id;
  final String supplier;
  final String category;
  final OrderStatus status;
  final String placedAt;
  final String eta;
  final String shippingAddress;
  final List<_OrderItem> items;
}

class _OrderItem {
  const _OrderItem({required this.name, required this.quantity});

  final String name;
  final String quantity;
}

enum OrderStatus { preparing, enRoute, delivered }

enum OrderStatusFilter { all, inProgress, delivered }

extension on OrderStatusFilter {
  String get label {
    switch (this) {
      case OrderStatusFilter.all:
        return 'All';
      case OrderStatusFilter.inProgress:
        return 'In progress';
      case OrderStatusFilter.delivered:
        return 'Delivered';
    }
  }
}

