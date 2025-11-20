import 'package:flutter/material.dart';

import 'supplier_chat_page.dart';
import 'supplier_home_shell.dart';

class SupplierComplaintsPage extends StatefulWidget {
  const SupplierComplaintsPage({super.key});

  @override
  State<SupplierComplaintsPage> createState() => _SupplierComplaintsPageState();
}

class _SupplierComplaintsPageState extends State<SupplierComplaintsPage> {
  final List<_Complaint> _complaints = [
    _Complaint(
      id: 'CMP-001',
      orderId: 'ORD-12345',
      customer: 'Restaurant A',
      type: 'Delivery delay',
      status: ComplaintStatus.open,
      priority: ComplaintPriority.high,
      date: DateTime(2025, 2, 12),
      description: 'Order arrived two hours late, affected lunch service.',
    ),
    _Complaint(
      id: 'CMP-002',
      orderId: 'ORD-12340',
      customer: 'Hotel SunRise',
      type: 'Low quality',
      status: ComplaintStatus.inProgress,
      priority: ComplaintPriority.medium,
      date: DateTime(2025, 2, 11),
      description: 'Vegetables were not fresh, several items bruised.',
    ),
    _Complaint(
      id: 'CMP-003',
      orderId: 'ORD-12338',
      customer: 'Cafe Aroma',
      type: 'Wrong quantity',
      status: ComplaintStatus.resolved,
      priority: ComplaintPriority.low,
      date: DateTime(2025, 2, 9),
      description: 'Received 10 kg instead of ordered 15 kg of flour.',
    ),
  ];

  final List<ComplaintStatus?> _tabs = [
    null,
    ComplaintStatus.open,
    ComplaintStatus.inProgress,
    ComplaintStatus.resolved,
  ];

  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final filtered = _tabs[_selectedTab] == null
        ? _complaints
        : _complaints
              .where((complaint) => complaint.status == _tabs[_selectedTab])
              .toList();

    return SupplierHomeShell(
      title: 'Complaints',
      section: SupplierSection.complaints,
      child: Column(
        children: [
          const SizedBox(height: 16),
          _ComplaintTabs(
            currentIndex: _selectedTab,
            onChanged: (index) => setState(() => _selectedTab = index),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final complaint = filtered[index];
                return _ComplaintCard(
                  complaint: complaint,
                  onView: () => _openDetails(complaint),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openDetails(_Complaint complaint) {
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint.customer,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3E46),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complaint ID: ${complaint.id}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow(
                icon: Icons.receipt_long,
                label: 'Order',
                value: complaint.orderId,
              ),
              _DetailRow(
                icon: Icons.category_outlined,
                label: 'Type',
                value: complaint.type,
              ),
              _DetailRow(
                icon: Icons.flag_outlined,
                label: 'Priority',
                value: complaint.priority.label,
              ),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value:
                    '${complaint.date.day}.${complaint.date.month}.${complaint.date.year}',
              ),
              const SizedBox(height: 16),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3E46),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  complaint.description,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SupplierChatPage(
                              customerName: complaint.customer,
                              subtitle: 'Complaint chat',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Message consumer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF21545F),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SupplierChatPage(
                              customerName: 'Manager Aigerim',
                              subtitle: 'Escalation chat',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.priority_high),
                      label: const Text('Escalate to manager'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ComplaintTabs extends StatelessWidget {
  const _ComplaintTabs({required this.currentIndex, required this.onChanged});

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = ['All', 'Open', 'In progress', 'Resolved'];

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

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.complaint, required this.onView});

  final _Complaint complaint;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final descriptor = _StatusDescriptor.fromStatus(complaint.status);
    final priorityColor = complaint.priority.color;

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
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFA7E1D5),
                child: Text(
                  complaint.customer.substring(0, 1),
                  style: const TextStyle(
                    color: Color(0xFF21545F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.customer,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3E46),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint.type,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(descriptor: descriptor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _IconDetail(
                icon: Icons.receipt_long_outlined,
                label: complaint.orderId,
              ),
              const SizedBox(width: 16),
              _IconDetail(
                icon: Icons.flag_outlined,
                label: complaint.priority.label,
                color: priorityColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            complaint.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onView,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF21545F),
              side: const BorderSide(color: Color(0xFF21545F)),
              minimumSize: const Size(double.infinity, 44),
            ),
            child: const Text('View complaint'),
          ),
        ],
      ),
    );
  }
}

class _IconDetail extends StatelessWidget {
  const _IconDetail({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.black54),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: color ?? Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.descriptor});

  final _StatusDescriptor descriptor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _Complaint {
  const _Complaint({
    required this.id,
    required this.orderId,
    required this.customer,
    required this.type,
    required this.status,
    required this.priority,
    required this.date,
    required this.description,
  });

  final String id;
  final String orderId;
  final String customer;
  final String type;
  final ComplaintStatus status;
  final ComplaintPriority priority;
  final DateTime date;
  final String description;
}

enum ComplaintStatus { open, inProgress, resolved }

enum ComplaintPriority { high, medium, low }

extension on ComplaintPriority {
  String get label {
    switch (this) {
      case ComplaintPriority.high:
        return 'High';
      case ComplaintPriority.medium:
        return 'Medium';
      case ComplaintPriority.low:
        return 'Low';
    }
  }

  Color get color {
    switch (this) {
      case ComplaintPriority.high:
        return Colors.red;
      case ComplaintPriority.medium:
        return Colors.orange;
      case ComplaintPriority.low:
        return Colors.blue;
    }
  }
}

class _StatusDescriptor {
  const _StatusDescriptor({required this.label, required this.color});

  final String label;
  final Color color;

  static _StatusDescriptor fromStatus(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.open:
        return const _StatusDescriptor(label: 'Open', color: Colors.red);
      case ComplaintStatus.inProgress:
        return const _StatusDescriptor(
          label: 'In progress',
          color: Colors.orange,
        );
      case ComplaintStatus.resolved:
        return const _StatusDescriptor(label: 'Resolved', color: Colors.green);
    }
  }
}
