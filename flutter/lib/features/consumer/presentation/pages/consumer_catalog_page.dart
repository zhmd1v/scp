import 'package:flutter/material.dart';

import 'consumer_home_shell.dart';

class ConsumerCatalogPage extends StatefulWidget {
  const ConsumerCatalogPage({super.key});

  @override
  State<ConsumerCatalogPage> createState() => _ConsumerCatalogPageState();
}

class _ConsumerCatalogPageState extends State<ConsumerCatalogPage> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey _filterFieldKey = GlobalKey();
  late final List<_LinkedSupplier> _suppliers = [
    _LinkedSupplier(
      name: 'Almaty Produce Hub',
      location: 'Almaty • Daily deliveries',
      categories: ['Leafy greens', 'Root vegetables', 'Herbs'],
      fulfillment: 'Cut-off 20:00 • arrives next morning',
      products: const [
        _SupplierProduct(
          name: 'Baby spinach',
          description: 'Washed • 3kg bag',
          options: [
            _ProductOption(label: '3 kg', price: 18000),
            _ProductOption(label: '6 kg', price: 34000),
          ],
        ),
        _SupplierProduct(
          name: 'Heirloom tomatoes',
          description: 'Grade A • 5kg crate',
          options: [
            _ProductOption(label: '5 kg crate', price: 22000),
            _ProductOption(label: '10 kg crate', price: 41000),
          ],
        ),
        _SupplierProduct(
          name: 'Thai basil',
          description: 'Bundles of 500g',
          options: [
            _ProductOption(label: '0.5 kg bundle', price: 6000),
            _ProductOption(label: '1 kg bundle', price: 11000),
          ],
        ),
      ],
    ),
    _LinkedSupplier(
      name: 'Caspi Seafood Group',
      location: 'Aktau • Cold-chain',
      categories: ['Salmon', 'Crustaceans', 'Caviar'],
      fulfillment: 'Lead time 48h • min order ₸120,000',
      products: const [
        _SupplierProduct(
          name: 'Atlantic salmon fillet',
          description: 'Trim D • 6kg average',
          options: [
            _ProductOption(label: '6 kg case', price: 98000),
            _ProductOption(label: '12 kg case', price: 189000),
          ],
        ),
        _SupplierProduct(
          name: 'Tiger prawns',
          description: '16/20 • 2kg frozen pack',
          options: [
            _ProductOption(label: '2 kg pack', price: 46000),
            _ProductOption(label: '6 kg pack', price: 129000),
          ],
        ),
        _SupplierProduct(
          name: 'Sturgeon caviar',
          description: '50g tins',
          options: [
            _ProductOption(label: '50 g tin', price: 35000),
            _ProductOption(label: '100 g tin', price: 67000),
          ],
        ),
      ],
    ),
    _LinkedSupplier(
      name: 'Steppe Dairy Collective',
      location: 'Astana • Refrigerated',
      categories: ['Cheese', 'Butter', 'Milk'],
      fulfillment: 'Delivery windows Tue / Fri',
      products: const [
        _SupplierProduct(
          name: 'Buffalo mozzarella',
          description: '2 x 125g bags',
          options: [
            _ProductOption(label: '1 kg case', price: 28000),
            _ProductOption(label: '3 kg case', price: 81000),
          ],
        ),
        _SupplierProduct(
          name: 'Cultured butter',
          description: '82% • 1kg blocks',
          options: [
            _ProductOption(label: '1 kg block', price: 14000),
            _ProductOption(label: '5 kg case', price: 65000),
          ],
        ),
        _SupplierProduct(
          name: 'Kefir',
          description: '12 x 1L cases',
          options: [
            _ProductOption(label: '12 L case', price: 18000),
            _ProductOption(label: '24 L case', price: 34000),
          ],
        ),
      ],
    ),
  ];

  late final List<String> _categories = [
    'All categories',
    ...{
      for (final supplier in _suppliers) ...supplier.categories,
    }.toList()
  ];

  String _selectedCategory = 'All categories';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _suppliers.where(_matchesFilters).toList();

    return ConsumerHomeShell(
      title: consumerSectionTitle(ConsumerSection.catalog),
      section: ConsumerSection.catalog,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Linked suppliers only. Tap to open their detailed catalogs.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search supplier or category',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _FilterField(
              key: _filterFieldKey,
              label: 'Filter by category',
              value: _selectedCategory,
              onTap: _openCategoryPicker,
            ),
            const SizedBox(height: 20),
            if (filtered.isEmpty)
              _CatalogEmptyState(query: _controller.text)
            else
              ...filtered.map(
                (supplier) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _SupplierCatalogCard(
                    supplier: supplier,
                    onViewCatalog: () => _openSupplierCatalog(supplier),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _matchesFilters(_LinkedSupplier supplier) {
    final query = _controller.text.trim().toLowerCase();
    final matchesQuery = query.isEmpty ||
        supplier.name.toLowerCase().contains(query) ||
        supplier.categories.any(
          (category) => category.toLowerCase().contains(query),
        );

    final matchesCategory = _selectedCategory == 'All categories' ||
        supplier.categories.contains(_selectedCategory);

    return matchesQuery && matchesCategory;
  }

  void _openSupplierCatalog(_LinkedSupplier supplier) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SupplierCatalogDetailPage(supplier: supplier),
      ),
    );
  }

  Future<void> _openCategoryPicker() async {
    final renderObject =
        _filterFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderObject == null) return;
    final offset = renderObject.localToGlobal(Offset.zero);

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + renderObject.size.height + 4,
        offset.dx + renderObject.size.width,
        offset.dy,
      ),
      items: _categories
          .map(
            (category) => PopupMenuItem<String>(
              value: category,
              child: Text(category),
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

class _SupplierCatalogCard extends StatelessWidget {
  const _SupplierCatalogCard({
    required this.supplier,
    required this.onViewCatalog,
  });

  final _LinkedSupplier supplier;
  final VoidCallback onViewCatalog;

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
                  supplier.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3E46),
                  ),
                ),
              ),
              Text(
                '${supplier.products.length} items',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            supplier.location,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: -6,
            children: supplier.categories
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
            supplier.fulfillment,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onViewCatalog,
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('View catalog'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF21545F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierCatalogDetailPage extends StatefulWidget {
  const _SupplierCatalogDetailPage({required this.supplier});

  final _LinkedSupplier supplier;

  @override
  State<_SupplierCatalogDetailPage> createState() =>
      _SupplierCatalogDetailPageState();
}

class _SupplierCatalogDetailPageState
    extends State<_SupplierCatalogDetailPage> {
  final Map<_SupplierProduct, _ProductOption> _lineItems = {};

  double get _orderTotal => _lineItems.values.fold(
      0, (previousValue, option) => previousValue + option.price);

  void _handleProductTap(_SupplierProduct product) async {
    final option = await showModalBottomSheet<_ProductOption>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _MassPickerSheet(product: product),
    );

    if (option != null) {
      setState(() => _lineItems[product] = option);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supplier = widget.supplier;

    return Scaffold(
      appBar: AppBar(
        title: Text(supplier.name),
        backgroundColor: const Color(0xFF21545F),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${supplier.products.length} products • ${supplier.fulfillment}',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                ...supplier.products.map(
                  (product) => _CatalogProductTile(
                    product: product,
                    onTap: () => _handleProductTap(product),
                  ),
                ),
              ],
            ),
          ),
          if (_lineItems.isNotEmpty)
            _OrderSummaryCard(
              total: _orderTotal,
              items: _lineItems,
            ),
        ],
      ),
    );
  }
}

class _CatalogProductTile extends StatelessWidget {
  const _CatalogProductTile({
    required this.product,
    required this.onTap,
  });

  final _SupplierProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE3EDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  color: Color(0xFF21545F)),
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
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E3E46),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'from ₸${product.startingPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF21545F),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}

class _MassPickerSheet extends StatelessWidget {
  const _MassPickerSheet({required this.product});

  final _SupplierProduct product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add ${product.name}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3E46),
            ),
          ),
          const SizedBox(height: 12),
          ...product.options.map(
            (option) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(option.label),
              subtitle:
                  Text('₸${option.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.add_circle_outline),
              onTap: () => Navigator.of(context).pop(option),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.total,
    required this.items,
  });

  final double total;
  final Map<_SupplierProduct, _ProductOption> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3E46),
            ),
          ),
          const SizedBox(height: 8),
          ...items.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entry.key.name} • ${entry.value.label}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    '₸${entry.value.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3E46),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total to pay',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '₸${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF21545F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order draft created')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF21545F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Place order request'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogEmptyState extends StatelessWidget {
  const _CatalogEmptyState({required this.query});

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
              Icon(Icons.store_mall_directory_outlined,
                  color: Color(0xFF21545F)),
              SizedBox(width: 10),
              Text(
                'No linked suppliers match your filters',
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
                ? 'Adjust categories to see all linked supplier catalogs.'
                : 'Try a different keyword or reset filters.',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _LinkedSupplier {
  _LinkedSupplier({
    required this.name,
    required this.location,
    required this.categories,
    required this.fulfillment,
    required this.products,
  });

  final String name;
  final String location;
  final List<String> categories;
  final String fulfillment;
  final List<_SupplierProduct> products;
}

class _SupplierProduct {
  const _SupplierProduct({
    required this.name,
    required this.description,
    required this.options,
  });

  final String name;
  final String description;
  final List<_ProductOption> options;

  double get startingPrice => options.first.price;
}

class _ProductOption {
  const _ProductOption({
    required this.label,
    required this.price,
  });

  final String label;
  final double price;
}

