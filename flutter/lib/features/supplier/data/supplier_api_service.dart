import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../services/api_service.dart';
import 'supplier_models.dart';

enum SupplierOrderAction { confirm, reject, cancel }

class SupplierApiService extends ApiService {
  SupplierApiService({
    http.Client? client,
    String? baseUrl,
    Duration? timeout,
  }) : super(client: client, baseUrl: baseUrl, timeout: timeout);

  Future<List<SupplierOrder>> fetchOrders({required String token}) async {
    final response = await get('/api/orders/my/supplier/', token: token);
    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to load supplier orders.',
      );
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .whereType<Map<String, dynamic>>()
        .map(SupplierOrder.fromJson)
        .toList();
  }

  Future<void> updateOrderStatus({
    required String token,
    required int orderId,
    required SupplierOrderAction action,
  }) async {
    final suffix = switch (action) {
      SupplierOrderAction.confirm => 'confirm',
      SupplierOrderAction.reject => 'reject',
      SupplierOrderAction.cancel => 'cancel',
    };

    final response = await post(
      '/api/orders/$orderId/$suffix/',
      token: token,
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Failed to update order status.',
      );
    }
  }

  Future<List<SupplierComplaint>> fetchComplaints({required String token}) async {
    final response = await get('/api/complaints/', token: token);
    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to load complaints.',
      );
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .whereType<Map<String, dynamic>>()
        .map(SupplierComplaint.fromJson)
        .toList();
  }

  Future<void> updateComplaintStatus({
    required String token,
    required int complaintId,
    required String newStatus,
  }) async {
    final response = await post(
      '/api/complaints/$complaintId/status/',
      token: token,
      body: {'status': newStatus},
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Failed to update complaint.',
      );
    }
  }

  Future<List<SupplierProduct>> fetchSupplierProducts({
    required String token,
    required int supplierId,
  }) async {
    final response = await get(
      '/api/catalog/suppliers/$supplierId/products/',
      token: token,
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to load products.',
      );
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .whereType<Map<String, dynamic>>()
        .map(SupplierProduct.fromJson)
        .toList();
  }

  Future<List<SupplierConversation>> fetchConversations({
    required String token,
  }) async {
    final response = await get('/api/chat/conversations/', token: token);
    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to load conversations.',
      );
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .whereType<Map<String, dynamic>>()
        .map(SupplierConversation.fromJson)
        .toList();
  }

  Future<List<SupplierMessage>> fetchMessages({
    required String token,
    required int conversationId,
    required int currentUserId,
  }) async {
    final response = await get(
      '/api/chat/conversations/$conversationId/messages/',
      token: token,
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to load messages.',
      );
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .whereType<Map<String, dynamic>>()
        .map((json) => SupplierMessage.fromJson(json, currentUserId: currentUserId))
        .toList();
  }

  Future<void> sendMessage({
    required String token,
    required int conversationId,
    required String text,
  }) async {
    final response = await post(
      '/api/chat/conversations/$conversationId/messages/',
      token: token,
      body: {'text': text},
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to send message.',
      );
    }
  }

  Future<SupplierConversation> startConversation({
    required String token,
    required int consumerId,
  }) async {
    final response = await post(
      '/api/chat/conversations/',
      token: token,
      body: {
        'consumer': consumerId,
        'conversation_type': 'supplier_consumer',
      },
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to start conversation.',
      );
    }

    final data = decodeToMap(response.body);
    return SupplierConversation.fromJson(data);
  }

  Future<void> markConversationRead({
    required String token,
    required int conversationId,
  }) async {
    final response = await post(
      '/api/chat/conversations/$conversationId/read/',
      token: token,
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to mark conversation read.',
      );
    }
  }

  Future<List<SupplierLink>> fetchConsumerLinks({required String token}) async {
    final response = await get('/api/accounts/links/', token: token);
    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to load consumer links.',
      );
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .whereType<Map<String, dynamic>>()
        .map(SupplierLink.fromJson)
        .toList();
  }

  Future<void> approveLinkRequest({
    required String token,
    required int linkId,
  }) async {
    final response = await post(
      '/api/accounts/links/$linkId/approve/',
      token: token,
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to approve link.',
      );
    }
  }

  Future<void> rejectLinkRequest({
    required String token,
    required int linkId,
  }) async {
    final response = await post(
      '/api/accounts/links/$linkId/reject/',
      token: token,
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to reject link.',
      );
    }
  }

  Future<void> blockConsumer({
    required String token,
    required int linkId,
  }) async {
    final response = await post(
      '/api/accounts/links/$linkId/block/',
      token: token,
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to block consumer.',
      );
    }
  }
}