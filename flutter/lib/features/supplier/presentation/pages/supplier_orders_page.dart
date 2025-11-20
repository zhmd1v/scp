import 'package:flutter/material.dart';

import 'supplier_home_shell.dart';

class SupplierOrdersPage extends StatefulWidget {
  const SupplierOrdersPage({super.key});

  @override
  State<SupplierOrdersPage> createState() => _SupplierOrdersPageState();
}

class _SupplierOrdersPageState extends State<SupplierOrdersPage> {
  final List<_Order> _orders = [
    _Order(
      id: 'ORD-001',
      customer: 'Restaurant A',
      phone: '+7 777 111 2233',
      status: OrderStatus.newOrder,
      category: 'Fish',
      date: DateTime(2025, 2, 12),
      items: const [
        _OrderItem(name: 'Salmon Fillet', quantity: 5, unit: 'kg', price: 4500),
        _OrderItem(name: 'Shrimp', quantity: 2, unit: 'kg', price: 3500),
      ],
    ),
    _Order(
      id: 'ORD-002',
      customer: 'Hotel SunRise',
      phone: '+7 701 555 8888',
      status: OrderStatus.inProgress,
      category: 'Beef',
      date: DateTime(2025, 2, 11),
      items: const [
        _OrderItem(name: 'Beef Steak', quantity: 4, unit: 'kg', price: 6000),
      ],
    ),
    _Order(
      id: 'ORD-003',
      customer: 'Cafe Aroma',
      phone: '+7 747 900 2244',
      status: OrderStatus.completed,
      category: 'Cheese',
      date: DateTime(2025, 2, 10),
      items: const [
        _OrderItem(name: 'Gouda Cheese', quantity: 3, unit: 'kg', price: 2500),
      ],
    ),
  ];

  final List<OrderStatus?> _filterTabs = [
    null,
    OrderStatus.newOrder,
    OrderStatus.inProgress,
    OrderStatus.completed,
  ];

  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _filterTabs[_selectedTab] == null
        ? _orders
        : _orders.where((order) => order.status == _filterTabs[_selectedTab]);

    return SupplierHomeShell(
      title: 'Orders',
      section: SupplierSection.orders,
      child: Column(
        children: [
          const SizedBox(height: 16),
          _StatusTabs(
            currentIndex: _selectedTab,
            onChanged: (index) => setState(() => _selectedTab = index),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final order = filteredOrders.elementAt(index);
                return _OrderCard(order: order);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({required this.currentIndex, required this.onChanged});

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = ['All', 'New', 'In progress', 'Completed'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE8EB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
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
                  tabs[index],
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
        }),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final _Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = order.items.fold<double>(
      0,
      (sum, item) => sum + (item.quantity * item.price),
    );

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
                  order.customer,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3E46),
                  ),
                ),
              ),
              _StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Order ID: ${order.id}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
          Text(
            'Category: ${order.category}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _IconDetail(
                icon: Icons.inventory_2_outlined,
                label: '${order.items.length} items',
              ),
              const SizedBox(width: 16),
              _IconDetail(
                icon: Icons.calendar_today_outlined,
                label:
                    '${order.date.day}.${order.date.month}.${order.date.year}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Total: ${total.toStringAsFixed(0)} ₸',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF21545F),
            ),
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

  void _openDetails(BuildContext context, _Order order) {
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
                order.customer,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3E46),
                ),
              ),
              const SizedBox(height: 4),
              Text('Phone: ${order.phone}'),
              Text(
                'Order ID: ${order.id}',
                style: const TextStyle(color: Colors.black54),
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
                    '• ${item.name} — ${item.quantity}${item.unit} x ${item.price} ₸',
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final descriptor = _StatusDescriptor.fromStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: descriptor.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        descriptor.label,
        style: TextStyle(
          color: descriptor.color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Order {
  const _Order({
    required this.id,
    required this.customer,
    required this.phone,
    required this.status,
    required this.category,
    required this.date,
    required this.items,
  });

  final String id;
  final String customer;
  final String phone;
  final OrderStatus status;
  final String category;
  final DateTime date;
  final List<_OrderItem> items;
}

class _OrderItem {
  const _OrderItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
  });

  final String name;
  final double quantity;
  final String unit;
  final double price;
}

enum OrderStatus { newOrder, inProgress, completed }

class _StatusDescriptor {
  const _StatusDescriptor({required this.label, required this.color});

  final String label;
  final Color color;

  static _StatusDescriptor fromStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return const _StatusDescriptor(label: 'New', color: Colors.blue);
      case OrderStatus.inProgress:
        return const _StatusDescriptor(
          label: 'In progress',
          color: Colors.orange,
        );
      case OrderStatus.completed:
        return const _StatusDescriptor(label: 'Completed', color: Colors.green);
    }
  }
}
