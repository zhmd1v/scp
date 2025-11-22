import 'package:flutter/material.dart';

// Helper functions for type conversion
double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

/// Represents a supplier profile
class ConsumerSupplier {
  ConsumerSupplier({
    required this.id,
    required this.companyName,
    this.city,
    this.isVerified = false,
    this.createdAt,
  });

  factory ConsumerSupplier.fromJson(Map<String, dynamic> json) {
    return ConsumerSupplier(
      id: json['id'] as int,
      companyName: json['company_name'] as String? ?? 'Supplier #${json['id']}',
      city: json['city'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: _toDateTime(json['created_at']),
    );
  }

  final int id;
  final String companyName;
  final String? city;
  final bool isVerified;
  final DateTime? createdAt;
}

/// Represents a consumer-supplier link relationship
class ConsumerSupplierLink {
  ConsumerSupplierLink({
    required this.id,
    required this.supplier,
    required this.status,
    this.consumerId,
    this.requestedAt,
  });

  factory ConsumerSupplierLink.fromJson(Map<String, dynamic> json) {
    final supplierJson = json['supplier'];
    final supplier = supplierJson is Map<String, dynamic>
        ? ConsumerSupplier.fromJson(supplierJson)
        : ConsumerSupplier(
            id: _toInt(supplierJson) ?? 0,
            companyName: 'Supplier #${supplierJson}',
          );

    return ConsumerSupplierLink(
      id: json['id'] as int,
      consumerId: _toInt(json['consumer']),
      supplier: supplier,
      status: json['status'] as String? ?? 'pending',
      requestedAt: _toDateTime(json['requested_at']),
    );
  }

  final int id;
  final int? consumerId;
  final ConsumerSupplier supplier;
  final String status;
  final DateTime? requestedAt;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isBlocked => status == 'blocked';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'blocked':
        return 'Blocked';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
      case 'blocked':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}

/// Represents a product in a supplier's catalog
class ConsumerProduct {
  ConsumerProduct({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.unit,
    this.supplierId,
    this.catalogId,
    this.category,
    this.categoryId,
    this.isAvailable = true,
    this.minOrderQuantity,
    this.stockLevel,
  });

  factory ConsumerProduct.fromJson(Map<String, dynamic> json) {
    final categoryData = json['category'];
    String? categoryName;
    int? categoryId;
    
    if (categoryData is Map<String, dynamic>) {
      categoryId = _toInt(categoryData['id']);
      categoryName = categoryData['name'] as String?;
    } else {
      categoryId = _toInt(categoryData);
    }
    
    return ConsumerProduct(
      id: json['id'] as int,
      supplierId: _toInt(json['supplier']),
      catalogId: _toInt(json['catalog']),
      categoryId: categoryId,
      category: categoryName,
      name: json['name'] as String? ?? 'Product #${json['id']}',
      description: json['description'] as String?,
      price: _toDouble(json['unit_price']) ?? 0,
      unit: json['unit'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      minOrderQuantity: _toDouble(json['minimum_order_quantity']),
      stockLevel: _toInt(json['stock_quantity']),
    );
  }

  final int id;
  final int? supplierId;
  final int? catalogId;
  final int? categoryId;
  final String? category;
  final String name;
  final String? description;
  final double price;
  final String? unit;
  final bool isAvailable;
  final double? minOrderQuantity;
  final int? stockLevel;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier': supplierId,
      'catalog': catalogId,
      'name': name,
      'description': description,
      'unit_price': price,
      'unit': unit,
      'is_available': isAvailable,
      'minimum_order_quantity': minOrderQuantity,
      'stock_quantity': stockLevel,
    };
  }
}

/// Represents a catalog containing products
class ConsumerCatalog {
  ConsumerCatalog({
    required this.id,
    required this.name,
    required this.products,
    this.supplierId,
    this.description,
    this.isActive = true,
  });

  factory ConsumerCatalog.fromJson(Map<String, dynamic> json) {
    final productsJson = (json['products'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return ConsumerCatalog(
      id: json['id'] as int,
      supplierId: _toInt(json['supplier']),
      name: json['name'] as String? ?? 'Catalog #${json['id']}',
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      products: productsJson.map(ConsumerProduct.fromJson).toList(),
    );
  }

  final int id;
  final int? supplierId;
  final String name;
  final String? description;
  final bool isActive;
  final List<ConsumerProduct> products;
}

/// Represents an order made by the consumer
class ConsumerOrder {
  ConsumerOrder({
    required this.id,
    required this.status,
    required this.items,
    required this.supplierId,
    this.supplierName,
    this.deliveryAddress,
    this.totalAmount,
    this.createdAt,
    this.updatedAt,
    this.requestedDeliveryDate,
    this.notes,
  });

  factory ConsumerOrder.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    // Extract supplier info
    final supplierData = json['supplier'];
    int supplierId = 0;
    String? supplierName;

    if (supplierData is Map<String, dynamic>) {
      supplierId = _toInt(supplierData['id']) ?? 0;
      supplierName = supplierData['company_name'] as String?;
    } else {
      supplierId = _toInt(supplierData) ?? 0;
    }

    return ConsumerOrder(
      id: json['id'] as int,
      supplierId: supplierId,
      supplierName: supplierName,
      status: json['status'] as String? ?? 'draft',
      deliveryAddress: json['delivery_address'] as String?,
      totalAmount: _toDouble(json['total_amount']),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
      requestedDeliveryDate: _toDateTime(json['requested_delivery_date']),
      notes: json['notes'] as String?,
      items: itemsJson.map(ConsumerOrderItem.fromJson).toList(),
    );
  }

  final int id;
  final int supplierId;
  final String? supplierName;
  final String status;
  final String? deliveryAddress;
  final double? totalAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? requestedDeliveryDate;
  final String? notes;
  final List<ConsumerOrderItem> items;

  bool get isDraft => status == 'draft';
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isInDelivery => status == 'in_delivery';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isRejected => status == 'rejected';

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'rejected':
        return 'Rejected';
      case 'in_delivery':
        return 'In delivery';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
      case 'draft':
        return Colors.orange;
      case 'confirmed':
      case 'in_delivery':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'supplier_id': supplierId,
      'delivery_address': deliveryAddress,
      'requested_delivery_date': requestedDeliveryDate != null
          ? '${requestedDeliveryDate!.year}-${requestedDeliveryDate!.month.toString().padLeft(2, '0')}-${requestedDeliveryDate!.day.toString().padLeft(2, '0')}'
          : null,
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

/// Represents an item in an order
class ConsumerOrderItem {
  ConsumerOrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.id,
    this.unit,
  });

  factory ConsumerOrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? const {};
    return ConsumerOrderItem(
      id: _toInt(json['id']),
      productId: _toInt(product['id']) ?? _toInt(json['product']) ?? 0,
      productName: product['name']?.toString() ?? 'Product',
      quantity: _toDouble(json['quantity']) ?? 0,
      unitPrice: _toDouble(json['unit_price']) ?? 0,
      lineTotal: _toDouble(json['line_total']) ?? 0,
      unit: product['unit']?.toString() ?? json['unit']?.toString(),
    );
  }

  final int? id;
  final int productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final String? unit;

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }
}

/// Represents a chat conversation
class ConsumerConversation {
  ConsumerConversation({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ConsumerConversation.fromJson(Map<String, dynamic> json) {
    return ConsumerConversation(
      id: json['id'] as int,
      supplierId: _toInt(json['supplier']) ?? 0,
      supplierName: json['supplier_name'] as String? ?? 'Supplier',
      lastMessage: json['last_message'] as String?,
      lastMessageAt: _toDateTime(json['last_message_at']),
      unreadCount: _toInt(json['unread_count']) ?? 0,
    );
  }

  final int id;
  final int supplierId;
  final String supplierName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
}

/// Represents a chat message
class ConsumerMessage {
  ConsumerMessage({
    required this.id,
    required this.text,
    required this.isFromMe,
    required this.createdAt,
    this.senderName,
  });

  factory ConsumerMessage.fromJson(
    Map<String, dynamic> json, {
    required int currentUserId,
  }) {
    final senderId = _toInt(json['sender']) ?? 0;
    return ConsumerMessage(
      id: json['id'] as int,
      text: json['text'] as String? ?? '',
      isFromMe: senderId == currentUserId,
      senderName: json['sender_name'] as String?,
      createdAt: _toDateTime(json['created_at']) ?? DateTime.now(),
    );
  }

  final int id;
  final String text;
  final bool isFromMe;
  final String? senderName;
  final DateTime createdAt;
}
