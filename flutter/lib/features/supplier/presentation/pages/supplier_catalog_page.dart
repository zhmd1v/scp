import 'package:flutter/material.dart';

import 'supplier_home_shell.dart';

class SupplierCatalogPage extends StatefulWidget {
  const SupplierCatalogPage({super.key});

  @override
  State<SupplierCatalogPage> createState() => _SupplierCatalogPageState();
}

class _SupplierCatalogPageState extends State<SupplierCatalogPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _products = [
    {
      'name': 'Fresh Salmon',
      'category': 'Fish',
      'price': 4500.0,
      'stock': 12,
      'description': 'High-quality Norwegian salmon.',
    },
    {
      'name': 'Premium Beef Steak',
      'category': 'Beef',
      'price': 6000.0,
      'stock': 3,
      'description': 'Grass-fed beef steak.',
    },
    {
      'name': 'Gouda Cheese',
      'category': 'Cheese',
      'price': 2500.0,
      'stock': 0,
      'description': 'Imported Dutch Gouda cheese.',
    },
  ];

  final List<String> _categories = ['All', 'Fish', 'Beef', 'Cheese'];
  String _selectedCategory = 'All';
  String _sortOption = 'None';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _composeProductList();

    return SupplierHomeShell(
      title: 'Catalog',
      section: SupplierSection.catalog,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchAndFilters(),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
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
                                  product['name'],
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E3E46),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _StockBadge(stock: product['stock']),
                                const SizedBox(height: 4),
                                Text(
                                  '${product['price']} ₸ / кг',
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
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _composeProductList() {
    final query = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> items = _products.where((product) {
      final matchesName = product['name'].toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == 'All' ||
          product['category'] == _selectedCategory;
      return matchesName && matchesCategory;
    }).toList();

    switch (_sortOption) {
      case 'Price ↑':
        items.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
        break;
      case 'Price ↓':
        items.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
        break;
      case 'A–Z':
        items.sort((a, b) => a['name'].compareTo(b['name']));
        break;
    }
    return items;
  }

  Widget _buildSearchAndFilters() {
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
                items: _categories
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
                items: const ['None', 'Price ↑', 'Price ↓', 'A–Z'].map((
                  option,
                ) {
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

  void _openProductDetails(Map<String, dynamic> product) {
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
                product['name'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product['category'],
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(product['description'] ?? ''),
              const SizedBox(height: 12),
              Text('Price: ${product['price']} ₸ / кг'),
              const SizedBox(height: 4),
              Text('Stock: ${product['stock']} кг'),
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

  final num stock;

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
