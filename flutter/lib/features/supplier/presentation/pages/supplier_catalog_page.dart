import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../data/supplier_api_service.dart';
import '../../data/supplier_models.dart';
import 'supplier_home_shell.dart';

class SupplierCatalogPage extends StatefulWidget {
  const SupplierCatalogPage({super.key});

  @override
  State<SupplierCatalogPage> createState() => _SupplierCatalogPageState();
}

class _SupplierCatalogPageState extends State<SupplierCatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  final SupplierApiService _api = SupplierApiService();

  Future<List<SupplierProduct>>? _productsFuture;
  List<SupplierProduct> _products = [];
  int? _lastSupplierId;
  String _selectedCategory = 'All';
  String _sortOption = 'None';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<SupplierProduct>> _loadProducts(int supplierId) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      throw const AuthException('You are not authenticated.');
    }
    final products = await _api.fetchSupplierProducts(
      token: token,
      supplierId: supplierId,
    );
    _products = products;
    return products;
  }

  List<SupplierProduct> _composeProductList() {
    final query = _searchController.text.toLowerCase();
    List<SupplierProduct> items = _products.where((product) {
      final matchesName = product.name.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == 'All' || product.categoryLabel == _selectedCategory;
      return matchesName && matchesCategory;
    }).toList();

    switch (_sortOption) {
      case 'Price ↑':
        items.sort((a, b) => (a.unitPrice ?? 0).compareTo(b.unitPrice ?? 0));
        break;
      case 'Price ↓':
        items.sort((a, b) => (b.unitPrice ?? 0).compareTo(a.unitPrice ?? 0));
        break;
      case 'A–Z':
        items.sort((a, b) => a.name.compareTo(b.name));
        break;
      default:
        break;
    }
    return items;
  }

  List<String> get _categoryFilters {
    final categories = _products.map((p) => p.categoryLabel).toSet().toList()
      ..sort();
    return ['All', ...categories];
  }

  Future<void> _refresh(int supplierId) async {
    setState(() {
      _productsFuture = _loadProducts(supplierId);
    });
    await _productsFuture;
  }

  Future<void> _promptSupplierId() async {
    final controller = TextEditingController();
    final id = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set supplier ID'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter supplier ID'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                Navigator.pop(context, parsed);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (id != null) {
      context.read<AuthProvider>().setSupplierId(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supplierId = context.watch<AuthProvider>().supplierId;
    if (_lastSupplierId != supplierId) {
      _lastSupplierId = supplierId;
      if (supplierId != null) {
        _productsFuture = _loadProducts(supplierId);
      } else {
        _productsFuture = null;
        _products = [];
      }
    }

    return SupplierHomeShell(
      title: 'Catalog',
      section: SupplierSection.catalog,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: supplierId == null
            ? _MissingSupplierState(onSetSupplierId: _promptSupplierId)
            : FutureBuilder<List<SupplierProduct>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                      message: snapshot.error.toString(),
                      onRetry: () => _refresh(supplierId),
                    );
                  }
                  if (_products.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => _refresh(supplierId),
                      child: ListView(
                        children: const [
                          SizedBox(height: 120),
                          _EmptyState(message: 'No products found in your catalog yet.'),
                        ],
                      ),
                    );
                  }
                  final filteredProducts = _composeProductList();
                  return Column(
                    children: [
                      _buildSearchAndFilters(),
                      const SizedBox(height: 12),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => _refresh(supplierId),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return GestureDetector(
                                onTap: () => _openProductDetails(product),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFA7E1D5),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.inventory_2_rounded,
                                          color: Color(0xFF21545F),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1E3E46),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            _StockBadge(
                                              stock: product.stockQuantity ?? 0,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${product.unitPrice?.toStringAsFixed(0) ?? '—'} ₸ / ${product.unit ?? 'unit'}',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Color(0xFF21545F),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final categories = _categoryFilters;
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'All';
    }

    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search products...',
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedCategory = value);
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDE8EB)),
              ),
              child: DropdownButton<String>(
                value: _sortOption,
                underline: const SizedBox(),
                items: const ['None', 'Price ↑', 'Price ↓', 'A–Z'].map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _sortOption = value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openProductDetails(SupplierProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.categoryLabel,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(product.description ?? 'No description provided'),
              const SizedBox(height: 12),
              Text('Price: ${product.unitPrice?.toStringAsFixed(0) ?? '—'} ₸ / ${product.unit ?? 'unit'}'),
              const SizedBox(height: 4),
              Text('Stock: ${(product.stockQuantity ?? 0).toStringAsFixed(2)} ${product.unit ?? ''}'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF21545F),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock});

  final double stock;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;

    if (stock <= 0) {
      color = Colors.redAccent;
      label = 'Out of stock';
    } else if (stock < 5) {
      color = Colors.orangeAccent;
      label = 'Low stock';
    } else {
      color = Colors.green;
      label = 'In stock';
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
}

class _MissingSupplierState extends StatelessWidget {
  const _MissingSupplierState({required this.onSetSupplierId});

  final VoidCallback onSetSupplierId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Set your supplier ID to load catalog products.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onSetSupplierId,
            child: const Text('Set supplier ID'),
          ),
        ],
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
