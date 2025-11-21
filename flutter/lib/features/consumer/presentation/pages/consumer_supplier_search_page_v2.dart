import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../data/consumer_api_service.dart';
import '../../data/consumer_models.dart';
import 'consumer_home_shell.dart';

class ConsumerSupplierSearchPageV2 extends StatefulWidget {
  const ConsumerSupplierSearchPageV2({super.key});

  @override
  State<ConsumerSupplierSearchPageV2> createState() =>
      _ConsumerSupplierSearchPageV2State();
}

class _ConsumerSupplierSearchPageV2State
    extends State<ConsumerSupplierSearchPageV2> {
  final ConsumerApiService _api = ConsumerApiService();
  final TextEditingController _searchController = TextEditingController();
  
  late Future<_PageData> _dataFuture;
  List<ConsumerSupplier> _allSuppliers = [];
  List<ConsumerSupplierLink> _links = [];
  String _searchQuery = '';
  int _selectedSection = 0; // 0 = Available, 1 = My Links

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_PageData> _loadData() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      throw const AuthException('You are not authenticated.');
    }

    final suppliers = await _api.fetchSuppliers(token: token);
    final links = await _api.fetchLinks(token: token);

    print("[DEMO] Data fetched: ${suppliers} suppliers, ${links} links");

    _allSuppliers = suppliers;
    _links = links;

    return _PageData(suppliers: suppliers, links: links);
  }

  Future<void> _refresh() async {
    setState(() {
      _dataFuture = _loadData();
    });
    await _dataFuture;
  }

  List<ConsumerSupplier> get _availableSuppliers {
    print("[DEMO] _availableSuppliers1: $_links");
    // Suppliers that are verified and don't have any link (pending or accepted)
    final linkedSupplierIds = _links.map((l) => l.supplier.id).toSet();
    
    print("[DEMO] _availableSuppliers2: $linkedSupplierIds");
    return _allSuppliers.where((supplier) {
      print("[DEMO] Checking supplier: ${supplier.companyName} ${!supplier.isVerified}, ${linkedSupplierIds.contains(supplier.id)}");
      if (!supplier.isVerified) return false;
      if (linkedSupplierIds.contains(supplier.id)) return false;
      
      if (_searchQuery.isEmpty) return true;
      
      final query = _searchQuery.toLowerCase();
      return supplier.companyName.toLowerCase().contains(query) ||
             (supplier.city?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<ConsumerSupplierLink> get _pendingLinks {
    final pending = _links.where((link) => link.isPending).toList();
    if (_searchQuery.isEmpty) return pending;
    
    final query = _searchQuery.toLowerCase();
    return pending.where((link) {
      return link.supplier.companyName.toLowerCase().contains(query) ||
             (link.supplier.city?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ConsumerHomeShell(
      title: consumerSectionTitle(ConsumerSection.suppliers),
      section: ConsumerSection.suppliers,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search suppliers by name or city',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTabs(
                  selectedIndex: _selectedSection,
                  onChanged: (value) => setState(() => _selectedSection = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<_PageData>(
              future: _dataFuture,
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

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: _selectedSection == 0
                      ? _buildAvailableSuppliers()
                      : _buildPendingLinks(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableSuppliers() {
    final suppliers = _availableSuppliers;

    if (suppliers.isEmpty) {
      return const _EmptyState(
        message: 'No available suppliers found. Try adjusting your search.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: suppliers.length,
      itemBuilder: (context, index) {
        final supplier = suppliers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SupplierCard(
            supplier: supplier,
            onTap: () => _requestLink(supplier),
          ),
        );
      },
    );
  }

  Widget _buildPendingLinks() {
    final links = _pendingLinks;

    if (links.isEmpty) {
      return const _EmptyState(
        message: 'No pending requests. Request access to suppliers first.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: links.length,
      itemBuilder: (context, index) {
        final link = links[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _LinkCard(link: link),
        );
      },
    );
  }

  Future<void> _requestLink(ConsumerSupplier supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Supplier Access'),
        content: Text(
          'Send a request to ${supplier.companyName} for catalog access?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null) {
        throw const AuthException('You are not authenticated.');
      }

      await _api.requestLink(token: token, supplierId: supplier.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent to ${supplier.companyName}'),
          ),
        );
        setState(() {
          _selectedSection = 1; // Switch to Pending Requests tab
        });
        await _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}

class _PageData {
  const _PageData({
    required this.suppliers,
    required this.links,
  });

  final List<ConsumerSupplier> suppliers;
  final List<ConsumerSupplierLink> links;
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
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: 'Available',
            isSelected: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TabButton(
            label: 'Pending Requests',
            isSelected: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0E3E45) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.supplier,
    required this.onTap,
  });

  final ConsumerSupplier supplier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E3E45).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: Color(0xFF0E3E45),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplier.companyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (supplier.city != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          supplier.city!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (supplier.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Request Access'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.link});

  final ConsumerSupplierLink link;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E3E45).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: Color(0xFF0E3E45),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.supplier.companyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (link.supplier.city != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          link.supplier.city!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: link.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(link.status),
                    size: 16,
                    color: link.statusColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    link.statusLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: link.statusColor,
                    ),
                  ),
                ],
              ),
            ),
            if (link.requestedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Requested ${_formatDate(link.requestedAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'blocked':
        return Icons.block;
      default:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
