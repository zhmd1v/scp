import 'package:http/http.dart' as http;

import '../../../services/api_service.dart';

class AuthApiService extends ApiService {
  AuthApiService({
    http.Client? client,
    String? baseUrl,
    Duration? timeout,
  }) : super(client: client, baseUrl: baseUrl, timeout: timeout);

  Future<String> obtainToken({
    required String username,
    required String password,
    String? role,
  }) async {
    final response = await post(
      '/api/auth/token/',
      body: {
        'username': username,
        'password': password,
        if (role != null) 'role': role,
      },
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Invalid credentials.',
      );
    }

    final data = decodeToMap(response.body);
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const ApiServiceException('Token is missing in the response.');
    }
    return token;
  }

  Future<Map<String, dynamic>> fetchCurrentUser(String token) async {
    final response = await get(
      '/api/accounts/me/',
      token: token,
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Unable to fetch user profile.',
      );
    }

    return decodeToMap(response.body);
  }

  Future<Map<String, dynamic>> registerConsumer(Map<String, dynamic> payload) async {
    final response = await post(
      '/api/accounts/register/',
      body: payload,
    );

    if (response.statusCode >= 400) {
      throw ApiServiceException(
        extractErrorMessage(response.body) ?? 'Registration failed.',
      );
    }

    return decodeToMap(response.body);
  }
}

