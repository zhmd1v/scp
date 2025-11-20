import 'package:flutter/material.dart';

import 'consumer_home_shell.dart';

class ConsumerSupplierSearchPage extends StatefulWidget {
  const ConsumerSupplierSearchPage({super.key});

  @override
  State<ConsumerSupplierSearchPage> createState() =>
      _ConsumerSupplierSearchPageState();
}

class _ConsumerSupplierSearchPageState
    extends State<ConsumerSupplierSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey _filterFieldKey = GlobalKey();
  String _selectedCategory = 'All categories';
  int _selectedSection = 0;

  final List<_SupplierInfo> _suppliers = const [
    _SupplierInfo(
      name: 'Almaty Produce Hub',
      status: SupplierStatus.linked,
      location: 'Almaty • Fresh produce',
      leadTime: 'Next delivery: Tomorrow 08:00 - 11:00',
      note: 'Linked via approval • 24 orders fulfilled',
      categories: ['Leafy greens', 'Tomatoes', 'Herbs'],
    ),
    _SupplierInfo(
      name: 'Steppe Dairy Collective',
      status: SupplierStatus.pending,
      location: 'Astana • Dairy & cheese',
      leadTime: 'Awaiting supplier approval',
      note: 'Request sent 2 days ago',
      categories: ['Mozzarella', 'Butter', 'Yoghurt'],
      requestSentAt: 'Sep 14, 10:20',
    ),
    _SupplierInfo(
      name: 'Caspi Seafood Group',
      status: SupplierStatus.available,
      location: 'Aktau • Seafood & frozen',
      leadTime: 'Lead time: 48h, minimum order ₸120,000',
      note: 'Recommended for coastal menus',
      categories: ['Salmon', 'Shrimp', 'Caviar'],
    ),
    _SupplierInfo(
      name: 'Nomad Grain Partners',
      status: SupplierStatus.available,
      location: 'Karaganda • Grains & flour',
      leadTime: 'Deliveries every Mon / Thu',
      note: 'Verified catalog • ISO certified',
      categories: ['Flour', 'Buckwheat', 'Barley'],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableSuppliers = _suppliers
        .where((s) => s.status == SupplierStatus.available)
        .where(_matchesFilter)
        .toList();
    final pendingRequests =
        _suppliers.where((s) => s.status == SupplierStatus.pending).where(_matchesFilter).toList();

    return ConsumerHomeShell(
      title: consumerSectionTitle(ConsumerSection.suppliers),
      section: ConsumerSection.suppliers,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            _SearchField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            _FilterField(
              key: _filterFieldKey,
              label: 'Filter by category',
              value: _selectedCategory,
              onTap: _openCategoryPicker,
            ),
            const SizedBox(height: 18),
            _SectionTabs(
              selectedIndex: _selectedSection,
              onChanged: (value) => setState(() => _selectedSection = value),
            ),
            const SizedBox(height: 14),
            if (_selectedSection == 0)
              _SectionCard(
                title: 'Available suppliers',
                child: availableSuppliers.isEmpty
                    ? _EmptyState(query: _controller.text)
                    : Column(
                        children: [
                          ...availableSuppliers
                              .map(
                                (supplier) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _SupplierCard(info: supplier),
                                ),
                              )
                              .toList(),
                        ],
                      ),
              )
            else
              _SectionCard(
                title: 'Waiting for approval',
                child: pendingRequests.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE3EDF4)),
                        ),
                        child: const Text(
                          'No open approvals. Send link requests from the list above.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      )
                    : Column(
                        children: pendingRequests
                            .map(
                              (supplier) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _PendingRequestTile(info: supplier),
                              ),
                            )
                            .toList(),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  bool _matchesFilter(_SupplierInfo info) {
    final query = _controller.text.trim().toLowerCase();
    final matchesQuery = query.isEmpty ||
        info.name.toLowerCase().contains(query) ||
        info.location.toLowerCase().contains(query) ||
        info.categories.join(' ').toLowerCase().contains(query);

    final matchesCategory =
        _selectedCategory == 'All categories' || info.categories.contains(_selectedCategory);

    return matchesQuery && matchesCategory;
  }

  List<String> get _categoryOptions {
    final set = <String>{};
    for (final supplier in _suppliers) {
      set.addAll(supplier.categories);
    }
    return ['All categories', ...set.toList()];
  }
  Future<void> _openCategoryPicker() async {
    final RenderBox box =
        _filterFieldKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height + 4,
        offset.dx + box.size.width,
        offset.dy,
      ),
      items: _categoryOptions
          .map(
            (option) => PopupMenuItem<String>(
              value: option,
              child: Text(option),
            ),
          )
          .toList(),
    );

    if (selected != null && selected != _selectedCategory) {
      setState(() => _selectedCategory = selected);
    }
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search suppliers, products, or cities',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3E46),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE8EB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Available',
            index: 0,
            selectedIndex: selectedIndex,
            onTap: onChanged,
          ),
          _TabButton(
            label: 'Pending requests',
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
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
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

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({required this.info});

  final _SupplierInfo info;

  Color _statusColor() {
    switch (info.status) {
      case SupplierStatus.linked:
        return const Color(0xFF1E9E70);
      case SupplierStatus.pending:
        return const Color(0xFFF39C12);
      case SupplierStatus.available:
        return const Color(0xFF21545F);
    }
  }

  String _statusLabel() {
    switch (info.status) {
      case SupplierStatus.linked:
        return 'Linked';
      case SupplierStatus.pending:
        return 'Pending approval';
      case SupplierStatus.available:
        return 'Available to link';
    }
  }

  String _ctaLabel() {
    switch (info.status) {
      case SupplierStatus.linked:
        return 'View catalog';
      case SupplierStatus.pending:
        return 'Awaiting approval';
      case SupplierStatus.available:
        return 'Send link request';
    }
  }

  bool get _ctaEnabled => info.status != SupplierStatus.pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
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
                  info.name,
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
                  borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 8),
          Text(
            info.location,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            info.leadTime,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: -6,
            children: info.categories
                .map(
                  (category) => Chip(
                    label: Text(category),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Text(
            info.note,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _ctaEnabled ? () {} : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _ctaEnabled ? const Color(0xFF21545F) : Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_ctaLabel()),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EDF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.hourglass_empty, color: Color(0xFF21545F)),
              SizedBox(width: 10),
              Text(
                'No suppliers match your search',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3E46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            query.isEmpty
                ? 'Adjust filters to discover available suppliers you can connect with.'
                : 'Try a different keyword or expand filters to find more suppliers.',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _SupplierInfo {
  const _SupplierInfo({
    required this.name,
    required this.status,
    required this.location,
    required this.leadTime,
    required this.note,
    required this.categories,
    this.requestSentAt,
  });

  final String name;
  final SupplierStatus status;
  final String location;
  final String leadTime;
  final String note;
  final List<String> categories;
  final String? requestSentAt;
}

enum SupplierStatus { linked, pending, available }

class _PendingRequestTile extends StatelessWidget {
  const _PendingRequestTile({required this.info});

  final _SupplierInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.pending_actions, color: Color(0xFFF39C12)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.location,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                if (info.requestSentAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Sent ${info.requestSentAt}',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('View request'),
          ),
        ],
      ),
    );
  }
}

