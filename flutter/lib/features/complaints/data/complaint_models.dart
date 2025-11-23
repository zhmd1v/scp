// Complaint Models for Flutter App

class Complaint {
  final int id;
  final int consumer;
  final String consumerName;
  final int supplier;
  final String supplierName;
  final int? order;
  final String title;
  final String description;
  final String complaintType;
  final String severity;
  final String status;
  final String escalationLevel;
  final String? escalationReason;
  final int? createdBy;
  final String? createdByEmail;
  final int? assignedTo;
  final String? assignedToEmail;
  final int? escalatedBy;
  final String? escalatedByEmail;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? escalatedAt;
  final bool canEscalate;
  final String? nextEscalationLevel;
  final List<ComplaintResponse>? responses;
  final List<ComplaintEscalation>? escalationHistory;

  Complaint({
    required this.id,
    required this.consumer,
    required this.consumerName,
    required this.supplier,
    required this.supplierName,
    this.order,
    required this.title,
    required this.description,
    required this.complaintType,
    required this.severity,
    required this.status,
    required this.escalationLevel,
    this.escalationReason,
    this.createdBy,
    this.createdByEmail,
    this.assignedTo,
    this.assignedToEmail,
    this.escalatedBy,
    this.escalatedByEmail,
    required this.createdAt,
    required this.updatedAt,
    this.escalatedAt,
    required this.canEscalate,
    this.nextEscalationLevel,
    this.responses,
    this.escalationHistory,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      consumer: json['consumer'],
      consumerName: json['consumer_name'] ?? '',
      supplier: json['supplier'],
      supplierName: json['supplier_name'] ?? '',
      order: json['order'],
      title: json['title'],
      description: json['description'],
      complaintType: json['complaint_type'],
      severity: json['severity'],
      status: json['status'],
      escalationLevel: json['escalation_level'],
      escalationReason: json['escalation_reason'],
      createdBy: json['created_by'],
      createdByEmail: json['created_by_email'],
      assignedTo: json['assigned_to'],
      assignedToEmail: json['assigned_to_email'],
      escalatedBy: json['escalated_by'],
      escalatedByEmail: json['escalated_by_email'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      escalatedAt: json['escalated_at'] != null 
          ? DateTime.parse(json['escalated_at']) 
          : null,
      canEscalate: json['can_escalate'] ?? false,
      nextEscalationLevel: json['next_escalation_level'],
      responses: json['responses'] != null
          ? (json['responses'] as List)
              .map((r) => ComplaintResponse.fromJson(r))
              .toList()
          : null,
      escalationHistory: json['escalation_history'] != null
          ? (json['escalation_history'] as List)
              .map((e) => ComplaintEscalation.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consumer': consumer,
      'supplier': supplier,
      'order': order,
      'title': title,
      'description': description,
      'complaint_type': complaintType,
      'severity': severity,
      'status': status,
      'escalation_level': escalationLevel,
      'escalation_reason': escalationReason,
    };
  }

  String get severityLabel {
    switch (severity) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'critical':
        return 'Critical';
      default:
        return severity;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  String get escalationLevelLabel {
    switch (escalationLevel) {
      case 'sales':
        return 'Sales Representative';
      case 'manager':
        return 'Manager';
      case 'owner':
        return 'Owner';
      default:
        return escalationLevel;
    }
  }

  String get complaintTypeLabel {
    switch (complaintType) {
      case 'product':
        return 'Product Quality';
      case 'delivery':
        return 'Delivery Issue';
      case 'billing':
        return 'Billing/Price';
      case 'service':
        return 'Service/Communication';
      case 'other':
        return 'Other';
      default:
        return complaintType;
    }
  }
}

class ComplaintResponse {
  final int id;
  final int complaint;
  final int? user;
  final String? userEmail;
  final String? userType;
  final String message;
  final bool isInternal;
  final String? attachment;
  final DateTime createdAt;

  ComplaintResponse({
    required this.id,
    required this.complaint,
    this.user,
    this.userEmail,
    this.userType,
    required this.message,
    required this.isInternal,
    this.attachment,
    required this.createdAt,
  });

  factory ComplaintResponse.fromJson(Map<String, dynamic> json) {
    return ComplaintResponse(
      id: json['id'],
      complaint: json['complaint'],
      user: json['user'],
      userEmail: json['user_email'],
      userType: json['user_type'],
      message: json['message'],
      isInternal: json['is_internal'] ?? false,
      attachment: json['attachment'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'complaint': complaint,
      'message': message,
      'is_internal': isInternal,
    };
  }
}

class ComplaintEscalation {
  final int id;
  final int complaint;
  final String fromLevel;
  final String toLevel;
  final String reason;
  final int? escalatedBy;
  final String? escalatedByEmail;
  final DateTime escalatedAt;

  ComplaintEscalation({
    required this.id,
    required this.complaint,
    required this.fromLevel,
    required this.toLevel,
    required this.reason,
    this.escalatedBy,
    this.escalatedByEmail,
    required this.escalatedAt,
  });

  factory ComplaintEscalation.fromJson(Map<String, dynamic> json) {
    return ComplaintEscalation(
      id: json['id'],
      complaint: json['complaint'],
      fromLevel: json['from_level'],
      toLevel: json['to_level'],
      reason: json['reason'],
      escalatedBy: json['escalated_by'],
      escalatedByEmail: json['escalated_by_email'],
      escalatedAt: DateTime.parse(json['escalated_at']),
    );
  }
}

class CreateComplaintRequest {
  final int supplier;
  final int? order;
  final String title;
  final String description;
  final String complaintType;
  final String severity;

  CreateComplaintRequest({
    required this.supplier,
    this.order,
    required this.title,
    required this.description,
    required this.complaintType,
    required this.severity,
  });

  Map<String, dynamic> toJson() {
    return {
      'supplier': supplier,
      if (order != null) 'order': order,
      'title': title,
      'description': description,
      'complaint_type': complaintType,
      'severity': severity,
    };
  }
}

class UpdateComplaintStatusRequest {
  final String status;
  final String? internalNote;

  UpdateComplaintStatusRequest({
    required this.status,
    this.internalNote,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      if (internalNote != null && internalNote!.isNotEmpty)
        'internal_note': internalNote,
    };
  }
}

class EscalateComplaintRequest {
  final String reason;

  EscalateComplaintRequest({required this.reason});

  Map<String, dynamic> toJson() {
    return {'reason': reason};
  }
}

class CreateComplaintResponseRequest {
  final String message;
  final bool isInternal;

  CreateComplaintResponseRequest({
    required this.message,
    this.isInternal = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'is_internal': isInternal,
    };
  }
}

// Incident Models

class Incident {
  final int id;
  final int supplier;
  final String supplierName;
  final int? order;
  final int? complaint;
  final String? complaintTitle;
  final String title;
  final String description;
  final String severity;
  final String status;
  final int? createdBy;
  final String? createdByEmail;
  final DateTime createdAt;
  final DateTime updatedAt;

  Incident({
    required this.id,
    required this.supplier,
    required this.supplierName,
    this.order,
    this.complaint,
    this.complaintTitle,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    this.createdBy,
    this.createdByEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'],
      supplier: json['supplier'],
      supplierName: json['supplier_name'] ?? '',
      order: json['order'],
      complaint: json['complaint'],
      complaintTitle: json['complaint_title'],
      title: json['title'],
      description: json['description'],
      severity: json['severity'],
      status: json['status'],
      createdBy: json['created_by'],
      createdByEmail: json['created_by_email'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String get severityLabel {
    switch (severity) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'critical':
        return 'Critical';
      default:
        return severity;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'open':
        return 'Open';
      case 'investigating':
        return 'Investigating';
      case 'mitigated':
        return 'Mitigated';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }
}
