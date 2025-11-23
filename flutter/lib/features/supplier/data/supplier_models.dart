import 'package:flutter/material.dart';

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

class SupplierOrder {
  SupplierOrder({
    required this.id,
    required this.status,
    required this.items,
    this.consumerId,
    this.supplierId,
    this.deliveryAddress,
    this.totalAmount,
    this.createdAt,
    this.updatedAt,
    this.requestedDeliveryDate,
  });

  factory SupplierOrder.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return SupplierOrder(
      id: json['id'] as int,
      consumerId: _toInt(json['consumer']),
      supplierId: _toInt(json['supplier']),
      status: (json['status'] as String?) ?? 'pending',
      deliveryAddress: json['delivery_address'] as String?,
      totalAmount: _toDouble(json['total_amount']),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
      requestedDeliveryDate: _toDateTime(json['requested_delivery_date']),
      items: itemsJson.map(SupplierOrderItem.fromJson).toList(),
    );
  }

  final int id;
  final int? consumerId;
  final int? supplierId;
  final String status;
  final String? deliveryAddress;
  final double? totalAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? requestedDeliveryDate;
  final List<SupplierOrderItem> items;

  bool get isPending => status == 'pending' || status == 'draft';
  bool get isActive => status == 'confirmed' || status == 'in_delivery';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected' || status == 'cancelled';

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
}

class SupplierOrderItem {
  SupplierOrderItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.unit,
    this.remark,
  });

  factory SupplierOrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? const {};
    return SupplierOrderItem(
      id: json['id'] as int? ?? 0,
      productName: product['name']?.toString() ?? 'Product #${json['id']}',
      quantity: _toDouble(json['quantity']) ?? 0,
      unitPrice: _toDouble(json['unit_price']) ?? 0,
      lineTotal: _toDouble(json['line_total']) ?? 0,
      unit: product['unit']?.toString() ?? json['unit']?.toString(),
      remark: json['remark'] as String?,
    );
  }

  final int id;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final String? unit;
  final String? remark;
}

class SupplierComplaint {
  SupplierComplaint({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.consumerId,
    this.orderId,
    this.severity,
    this.complaintType,
    this.escalationLevel,
    this.canEscalate = false,
    this.createdAt,
    this.updatedAt,
  });

  factory SupplierComplaint.fromJson(Map<String, dynamic> json) {
    return SupplierComplaint(
      id: json['id'] as int,
      consumerId: _toInt(json['consumer']),
      orderId: _toInt(json['order']),
      title: json['title'] as String? ?? 'Complaint #${json['id']}',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      severity: json['severity'] as String?,
      complaintType: json['complaint_type'] as String?,
      escalationLevel: json['escalation_level'] as String?,
      canEscalate: json['can_escalate'] as bool? ?? false,
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  final int id;
  final int? consumerId;
  final int? orderId;
  final String title;
  final String description;
  final String status;
  final String? severity;
  final String? complaintType;
  final String? escalationLevel;
  final bool canEscalate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved' || status == 'closed';

  String get statusLabel {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'open':
        return Colors.redAccent;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
      case 'closed':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }
}

class SupplierConversation {
  SupplierConversation({
    required this.id,
    required this.conversationType,
    this.supplierId,
    this.consumerId,
    this.consumerName,
    this.orderId,
    this.updatedAt,
    this.createdAt,
  });

  factory SupplierConversation.fromJson(Map<String, dynamic> json) {
    return SupplierConversation(
      id: json['id'] as int,
      supplierId: _toInt(json['supplier']),
      consumerId: _toInt(json['consumer']),
      consumerName: json['consumer_name'] as String?,
      orderId: _toInt(json['order']),
      conversationType: json['conversation_type'] as String? ?? 'supplier_consumer',
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  final int id;
  final int? supplierId;
  final int? consumerId;
  final String? consumerName;
  final int? orderId;
  final String conversationType;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  String get displayName {
    if (consumerName != null) {
      return consumerName!;
    }
    if (consumerId != null) {
      return 'Consumer #$consumerId';
    }
    if (orderId != null) {
      return 'Order chat #$orderId';
    }
    return 'Conversation #$id';
  }

  String get subtitle {
    switch (conversationType) {
      case 'supplier_consumer':
        return 'Consumer chat';
      case 'internal':
        return 'Internal chat';
      default:
        return conversationType;
    }
  }
}

class SupplierMessage {
  SupplierMessage({
    required this.id,
    required this.text,
    required this.isMine,
    this.senderId,
    this.senderName,
    this.sentAt,
    this.isRead = false,
    this.attachmentUrl,
  });

  factory SupplierMessage.fromJson(
    Map<String, dynamic> json, {
    int? currentUserId,
  }) {
    final senderId = _toInt(json['sender']);
    return SupplierMessage(
      id: json['id'] as int,
      text: json['text'] as String? ?? '',
      senderId: senderId,
      senderName: json['sender_username'] as String?,
      sentAt: _toDateTime(json['sent_at']),
      isRead: json['is_read'] == true,
      isMine: currentUserId != null && senderId == currentUserId,
      attachmentUrl: json['attachment'] as String?,
    );
  }

  final int id;
  final String text;
  final int? senderId;
  final String? senderName;
  final DateTime? sentAt;
  final bool isRead;
  final bool isMine;
  final String? attachmentUrl;
}

class SupplierProduct {
  SupplierProduct({
    required this.id,
    required this.name,
    this.description,
    this.unit,
    this.unitPrice,
    this.stockQuantity,
    this.isAvailable,
    this.categoryLabel = 'General',
    this.imageUrl,
  });

  factory SupplierProduct.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    String? categoryLabel;
    if (category is Map<String, dynamic>) {
      categoryLabel = category['name'] as String?;
    } else if (category != null) {
      categoryLabel = 'Category #$category';
    }

    return SupplierProduct(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Product #${json['id']}',
      description: json['description'] as String?,
      unit: json['unit'] as String?,
      unitPrice: _toDouble(json['unit_price']),
      stockQuantity: _toDouble(json['stock_quantity']),
      isAvailable: json['is_available'] as bool?,
      categoryLabel: categoryLabel ?? 'General',
      imageUrl: json['image'] as String?,
    );
  }

  final int id;
  final String name;
  final String? description;
  final String? unit;
  final double? unitPrice;
  final double? stockQuantity;
  final bool? isAvailable;
  final String categoryLabel;
  final String? imageUrl;

  bool get isOutOfStock => (stockQuantity ?? 0) <= 0;
  bool get isLowStock => (stockQuantity ?? 0) > 0 && (stockQuantity ?? 0) < 5;
}

class SupplierLink {
  SupplierLink({
    required this.id,
    required this.status,
    this.consumerId,
    this.consumerName,
    this.supplierId,
    this.requestedAt,
  });

  factory SupplierLink.fromJson(Map<String, dynamic> json) {
    // Extract consumer info
    final consumerData = json['consumer'];
    int? consumerId;
    String? consumerName;

    if (consumerData is Map<String, dynamic>) {
      consumerId = _toInt(consumerData['id']);
      // Try to get business_name directly (if it's a profile) or from consumer_profile (if it's a user)
      consumerName = consumerData['business_name'] as String?;
      
      if (consumerName == null) {
        final profile = consumerData['consumer_profile'];
        if (profile is Map<String, dynamic>) {
          consumerName = profile['business_name'] as String?;
        }
      }
      consumerName ??= consumerData['username'] as String?;
    } else {
      consumerId = _toInt(consumerData);
    }

    return SupplierLink(
      id: json['id'] as int,
      consumerId: consumerId,
      consumerName: consumerName,
      supplierId: _toInt(json['supplier']),
      status: json['status'] as String? ?? 'pending',
      requestedAt: _toDateTime(json['requested_at']),
    );
  }

  final int id;
  final int? consumerId;
  final String? consumerName;
  final int? supplierId;
  final String status;
  final DateTime? requestedAt;

  String get label => consumerName ?? 'Consumer #${consumerId ?? '-'}';

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
