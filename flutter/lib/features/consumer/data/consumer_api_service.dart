import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../services/api_service.dart';
import 'consumer_models.dart';

class ConsumerApiService extends ApiService {
  ConsumerApiService({
    http.Client? client,
    String? baseUrl,
    Duration? timeout,
  }) : super(client: client, baseUrl: baseUrl, timeout: timeout);

  /// Fetch all verified suppliers
  Future<List<ConsumerSupplier>> fetchSuppliers({required String token}) async {
    final response = await get('/api/accounts/suppliers/', token: token);
    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to load suppliers.',
      );
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .whereType<Map<String, dynamic>>()
        .map(ConsumerSupplier.fromJson)
        .toList();
  }

  /// Fetch consumer-supplier links
  Future<List<ConsumerSupplierLink>> fetchLinks({required String token}) async {
    final response = await get('/api/accounts/links/', token: token);
    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to load supplier links.',
      );
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    print("[DEMO] Data fetched: ${response.body}");
    return payload
        .whereType<Map<String, dynamic>>()
        .map(ConsumerSupplierLink.fromJson)
        .toList();
  }

  /// Request a new link to a supplier
  Future<ConsumerSupplierLink> requestLink({
    required String token,
    required int supplierId,
  }) async {
    final response = await post(
      '/api/accounts/links/',
      token: token,
      body: {'supplier_id': supplierId},
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to request supplier link.',
      );
    }

    final data = decodeToMap(response.body);
    return ConsumerSupplierLink.fromJson(data);
  }

  /// Fetch products for a specific supplier
  Future<List<ConsumerProduct>> fetchSupplierProducts({
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
        .map(ConsumerProduct.fromJson)
        .toList();
  }

  /// Fetch catalogs for a specific supplier
  Future<List<ConsumerCatalog>> fetchSupplierCatalogs({
    required String token,
    required int supplierId,
  }) async {
    final response = await get(
      '/api/catalog/suppliers/$supplierId/catalogs/',
      token: token,
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to load catalogs.',
      );
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .whereType<Map<String, dynamic>>()
        .map(ConsumerCatalog.fromJson)
        .toList();
  }

  /// Fetch catalog details by ID
  Future<ConsumerCatalog> fetchCatalogDetails({
    required String token,
    required int catalogId,
  }) async {
    final response = await get(
      '/api/catalog/catalogs/$catalogId/',
      token: token,
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to load catalog details.',
      );
    }

    final data = decodeToMap(response.body);
    return ConsumerCatalog.fromJson(data);
  }

  /// Fetch all consumer orders
  Future<List<ConsumerOrder>> fetchOrders({required String token}) async {
    final response = await get('/api/orders/my/consumer/', token: token);
    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to load orders.',
      );
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .whereType<Map<String, dynamic>>()
        .map(ConsumerOrder.fromJson)
        .toList();
  }

  /// Fetch order details by ID
  Future<ConsumerOrder> fetchOrderDetails({
    required String token,
    required int orderId,
  }) async {
    final response = await get('/api/orders/$orderId/', token: token);
    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to load order details.',
      );
    }

    final data = decodeToMap(response.body);
    return ConsumerOrder.fromJson(data);
  }

  /// Create a new order
  Future<ConsumerOrder> createOrder({
    required String token,
    required ConsumerOrder order,
  }) async {
    final response = await post(
      '/api/orders/',
      token: token,
      body: order.toJson(),
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to create order.',
      );
    }

    final data = decodeToMap(response.body);
    return ConsumerOrder.fromJson(data);
  }

  /// Cancel an order
  Future<void> cancelOrder({
    required String token,
    required int orderId,
  }) async {
    final response = await post(
      '/api/orders/$orderId/cancel/',
      token: token,
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to cancel order.',
      );
    }
  }

  /// Complete an order
  Future<void> completeOrder({
    required String token,
    required int orderId,
  }) async {
    final response = await post(
      '/api/orders/$orderId/complete/',
      token: token,
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to complete order.',
      );
    }
  }

  /// Fetch conversations
  Future<List<ConsumerConversation>> fetchConversations({
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
        .map(ConsumerConversation.fromJson)
        .toList();
  }

  /// Fetch messages for a conversation
  Future<List<ConsumerMessage>> fetchMessages({
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
        .map((json) => ConsumerMessage.fromJson(json, currentUserId: currentUserId))
        .toList();
  }

  /// Send a message
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

  /// Mark conversation as read
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

  /// Fetch current user information
  Future<Map<String, dynamic>> fetchCurrentUser({required String token}) async {
    final response = await get('/api/accounts/me/', token: token);
    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to load user information.',
      );
    }

    return decodeToMap(response.body);
  }

  /// Update user profile (username, phone)
  Future<void> updateUserProfile({
    required String token,
    String? username,
    String? phone,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (phone != null) body['phone'] = phone;

    final response = await http.patch(
      buildUri('/api/accounts/profile/user/'),
      headers: defaultHeaders(token: token),
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to update user profile.',
      );
    }
  }

  /// Update consumer profile
  Future<void> updateConsumerProfile({
    required String token,
    String? businessName,
    String? businessType,
    String? address,
    String? city,
    String? registrationNumber,
  }) async {
    final body = <String, dynamic>{};
    if (businessName != null) body['business_name'] = businessName;
    if (businessType != null) body['business_type'] = businessType;
    if (address != null) body['address'] = address;
    if (city != null) body['city'] = city;
    if (registrationNumber != null) body['registration_number'] = registrationNumber;

    final response = await http.patch(
      buildUri('/api/accounts/profile/consumer/'),
      headers: defaultHeaders(token: token),
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to update consumer profile.',
      );
    }
  }
}
