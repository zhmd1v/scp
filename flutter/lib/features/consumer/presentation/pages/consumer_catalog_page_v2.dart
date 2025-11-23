import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/api_config.dart';
import '../../../../providers/auth_provider.dart';
import '../../data/consumer_api_service.dart';
import '../../data/consumer_models.dart';
import 'consumer_home_shell.dart';

class ConsumerCatalogPageV2 extends StatefulWidget {
  const ConsumerCatalogPageV2({super.key});

  @override
  State<ConsumerCatalogPageV2> createState() => _ConsumerCatalogPageV2State();
}

class _ConsumerCatalogPageV2State extends State<ConsumerCatalogPageV2> {
  final ConsumerApiService _api = ConsumerApiService();
  final TextEditingController _searchController = TextEditingController();
  
  late Future<List<ConsumerSupplierLink>> _linksFuture;
  List<ConsumerSupplierLink> _links = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _linksFuture = _loadLinks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ConsumerSupplierLink>> _loadLinks() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      throw const AuthException('You are not authenticated.');
    }
    
    final links = await _api.fetchLinks(token: token);
    print("[CATALOG DEBUG] Total links: ${links.length}");
    for (var link in links) {
      print("[CATALOG DEBUG] Link: ${link.supplier.companyName}, Status: ${link.status}, isAccepted: ${link.isAccepted}");
    }
    _links = links.where((link) => link.isAccepted).toList();
    print("[CATALOG DEBUG] Accepted links: ${_links.length}");
    return _links;
  }

  Future<void> _refresh() async {
    setState(() {
      _linksFuture = _loadLinks();
    });
    await _linksFuture;
  }

  List<ConsumerSupplierLink> get _filteredLinks {
    if (_searchQuery.isEmpty) return _links;
    
    final query = _searchQuery.toLowerCase();
    return _links.where((link) {
      return link.supplier.companyName.toLowerCase().contains(query) ||
             (link.supplier.city?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ConsumerHomeShell(
      title: consumerSectionTitle(ConsumerSection.catalog),
      section: ConsumerSection.catalog,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search supplier or city',
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
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ConsumerSupplierLink>>(
              future: _linksFuture,
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

                if (_links.isEmpty) {
                  return const _EmptyState(
                    message: 'No linked suppliers yet. Request access to suppliers first.',
                  );
                }

                final filteredLinks = _filteredLinks;
                if (filteredLinks.isEmpty) {
                  return const _EmptyState(
                    message: 'No suppliers match your search.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filteredLinks.length,
                    itemBuilder: (context, index) {
                      final link = filteredLinks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SupplierCard(
                          link: link,
                          onTap: () => _openSupplierCatalog(link),
                        ),
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

  void _openSupplierCatalog(ConsumerSupplierLink link) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SupplierCatalogPage(
          supplierId: link.supplier.id,
          supplierName: link.supplier.companyName,
        ),
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.link,
    required this.onTap,
  });

  final ConsumerSupplierLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E3E45).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront,
                  color: Color(0xFF0E3E45),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: link.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        link.statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: link.statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupplierCatalogPage extends StatefulWidget {
  const _SupplierCatalogPage({
    required this.supplierId,
    required this.supplierName,
  });

  final int supplierId;
  final String supplierName;

  @override
  State<_SupplierCatalogPage> createState() => _SupplierCatalogPageState();
}

class _SupplierCatalogPageState extends State<_SupplierCatalogPage> {
  final ConsumerApiService _api = ConsumerApiService();
  late Future<List<ConsumerProduct>> _productsFuture;
  List<ConsumerProduct> _products = [];
  final Map<int, int> _cart = {}; // productId -> quantity
  String? _selectedCategory;
  DateTime? _requestedDate;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productsFuture = _loadProducts();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<List<ConsumerProduct>> _loadProducts() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      throw const AuthException('You are not authenticated.');
    }

    final products = await _api.fetchSupplierProducts(
      token: token,
      supplierId: widget.supplierId,
    );
    _products = products;
    return products;
  }

  Future<void> _refresh() async {
    setState(() {
      _productsFuture = _loadProducts();
    });
    await _productsFuture;
  }

  List<ConsumerProduct> get _filteredProducts {
    if (_selectedCategory == null) return _products;
    return _products.where((p) => p.category == _selectedCategory).toList();
  }

  List<String> get _availableCategories {
    final categories = _products
        .where((p) => p.category != null)
        .map((p) => p.category!)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  void _updateCart(int productId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cart.remove(productId);
      } else {
        _cart[productId] = quantity;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.supplierName),
        actions: [
          if (_cart.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${_cart.length}'),
                child: const Icon(Icons.shopping_cart),
              ),
              onPressed: _showCart,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_availableCategories.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryChip(
                    label: 'All',
                    isSelected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 8),
                  ..._availableCategories.map((category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CategoryChip(
                      label: category,
                      isSelected: _selectedCategory == category,
                      onTap: () => setState(() => _selectedCategory = category),
                    ),
                  )),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<ConsumerProduct>>(
        future: _productsFuture,
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

          if (_products.isEmpty) {
            return const _EmptyState(
              message: 'No products available from this supplier yet.',
            );
          }

          final displayProducts = _filteredProducts;
          
          if (displayProducts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No products in this category',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displayProducts.length,
              itemBuilder: (context, index) {
                final product = displayProducts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProductCard(
                    product: product,
                    quantity: _cart[product.id] ?? 0,
                    onQuantityChanged: (qty) => _updateCart(product.id, qty),
                  ),
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

  void _showCart() {
    final cartProducts = _products
        .where((p) => _cart.containsKey(p.id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Your Cart',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...cartProducts.map((product) {
                      final quantity = _cart[product.id]!;
                      final total = product.price * quantity;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                            '${product.price.toStringAsFixed(0)} ₸ × $quantity ${product.unit ?? ''}',
                          ),
                          trailing: Text(
                            '${total.toStringAsFixed(0)} ₸',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    const Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0E3E45),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) {
                          setState(() => _requestedDate = date);
                          // Rebuild the bottom sheet to show selected date
                          Navigator.pop(context);
                          _showCart();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Color(0xFF0E3E45)),
                            const SizedBox(width: 12),
                            Text(
                              _requestedDate == null
                                  ? 'Select requested delivery date'
                                  : '${_requestedDate!.day}/${_requestedDate!.month}/${_requestedDate!.year}',
                              style: TextStyle(
                                color: _requestedDate == null
                                    ? Colors.grey.shade600
                                    : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add notes for the supplier...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0E3E45)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _createOrder();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Create Order'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createOrder() async {
    final cartItems = _cart.entries
        .where((e) => e.value > 0)
        .toList();

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token ?? '';

      // Build order items
      final orderItems = cartItems.map((entry) {
        final productId = entry.key;
        final quantity = entry.value;
        final product = _products.firstWhere((p) => p.id == productId);
        
        return ConsumerOrderItem(
          productId: product.id,
          productName: product.name,
          quantity: quantity.toDouble(),
          unitPrice: product.price,
          lineTotal: product.price * quantity,
        );
      }).toList();

      // Get address from profile
      final userProfile = authProvider.currentUser?['consumer_profile'] as Map<String, dynamic>?;
      final address = userProfile?['address'] as String? ?? 'Address not provided';

      // Create order
      final order = ConsumerOrder(
        id: 0, // Will be set by backend
        supplierId: widget.supplierId,
        supplierName: widget.supplierName,
        status: 'pending',
        deliveryAddress: address,
        requestedDeliveryDate: _requestedDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        items: orderItems,
      );

      print('Creating order with payload: ${order.toJson()}');

      await _api.createOrder(token: token, order: order);

      if (mounted) {
        // Clear cart
        setState(() {
          _cart.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
  });

  final ConsumerProduct product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    // Build full image URL if imageUrl is provided
    String? fullImageUrl;
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      // If the URL is already absolute, use it as is
      if (product.imageUrl!.startsWith('http')) {
        fullImageUrl = product.imageUrl;
      } else {
        // Otherwise, prepend the backend base URL
        const baseUrl = kBackendBaseUrl;
        final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
        final normalizedPath = product.imageUrl!.startsWith('/') ? product.imageUrl : '/${product.imageUrl}';
        fullImageUrl = '$normalizedBase$normalizedPath';
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: fullImageUrl != null
                      ? Image.network(
                          fullImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade400,
                              size: 40,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            );
                          },
                        )
                      : Icon(
                          Icons.inventory_2,
                          color: Colors.grey.shade400,
                          size: 40,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (product.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${product.price.toStringAsFixed(0)} ₸',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0E3E45),
                      ),
                    ),
                    if (product.unit != null)
                      Text(
                        'per ${product.unit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!product.isAvailable)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Out of stock',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else if (product.minOrderQuantity != null)
                  Text(
                    'Min order: ${product.minOrderQuantity} ${product.unit ?? ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                const Spacer(),
                if (product.isAvailable) ...[
                  if (quantity == 0)
                    OutlinedButton.icon(
                      onPressed: () => onQuantityChanged(1),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => onQuantityChanged(quantity - 1),
                          icon: const Icon(Icons.remove),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$quantity',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => onQuantityChanged(quantity + 1),
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF0E3E45),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0E3E45) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
