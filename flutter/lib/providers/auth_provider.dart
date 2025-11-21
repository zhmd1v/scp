import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../features/auth/data/auth_api_service.dart';
import '../services/api_service.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => 'AuthException: $message';
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthApiService? apiService,
  }) : _authApi = apiService ?? AuthApiService();

  final AuthApiService _authApi;

  String? _selectedRole;
  String? _token;
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  int? _activeSupplierId = kDefaultSupplierId;

  String? get selectedRole => _selectedRole;
  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String get apiBaseUrl => _authApi.baseUrl;
  int? get supplierId => _activeSupplierId;

  void chooseRole(String role) {
    if (_selectedRole == role) return;
    _selectedRole = role;
    notifyListeners();
  }

  void clearRole() {
    final needsNotify = _selectedRole != null || _token != null || _activeSupplierId != kDefaultSupplierId;
    _selectedRole = null;
    _token = null;
    _currentUser = null;
    _activeSupplierId = kDefaultSupplierId;
    if (needsNotify) notifyListeners();
  }

  Future<void> updateBaseUrl(String newBaseUrl) async {
    if (newBaseUrl.isEmpty || newBaseUrl == _authApi.baseUrl) return;
    _authApi.updateBaseUrl(newBaseUrl);
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  int? _extractSupplierId(Map<String, dynamic>? userData) {
    if (userData == null) return null;

    final staff = userData['supplier_staff'];
    if (staff is Map<String, dynamic>) {
      final directId = _parseInt(staff['supplier_id']);
      if (directId != null) return directId;

      final supplier = staff['supplier'];
      if (supplier is Map<String, dynamic>) {
        final nestedId = _parseInt(supplier['id']);
        if (nestedId != null) return nestedId;
      }
    }
    return null;
  }

  void _hydrateSupplierFromUser(Map<String, dynamic>? userData) {
    final supplierIdFromProfile = _extractSupplierId(userData);
    if (supplierIdFromProfile != null) {
      _activeSupplierId = supplierIdFromProfile;
    } else if (_selectedRole == 'supplier' && _activeSupplierId == null) {
      _activeSupplierId = kDefaultSupplierId;
    }
  }

  String _roleFromUserType(String? userType) {
    if (userType == null) return 'consumer';
    if (userType.startsWith('supplier')) return 'supplier';
    if (userType.contains('admin')) return 'admin';
    return 'consumer';
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final token = await _authApi.obtainToken(
        username: identifier,
        password: password,
        role: _selectedRole,
      );
      final userData = await _authApi.fetchCurrentUser(token);

      _token = token;
      _currentUser = userData;
      _selectedRole = _roleFromUserType(userData['user_type'] as String?);
      _hydrateSupplierFromUser(userData);
      notifyListeners();
    } on ApiServiceException catch (e) {
      throw AuthException(e.message);
    } on Exception catch (e) {
      throw AuthException(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> registerConsumer({
    required String businessName,
    required String contactName,
    required String email,
    required String phone,
    required String city,
    required String address,
    required String businessType,
    required String password,
    required String confirmPassword,
    String? registrationNumber,
  }) async {
    _setLoading(true);
    try {
      final data = await _authApi.registerConsumer({
        'username': email,
        'email': email,
        'password': password,
        'password_confirm': confirmPassword,
        'first_name': contactName,
        'phone': phone,
        'user_type': 'consumer',
        'business_name': businessName,
        'business_type': businessType,
        'city': city,
        'address': address,
        'registration_number': registrationNumber ?? '',
      });

      final token = data['token'] as String?;
      if (token == null) {
        throw const AuthException('Server did not return an auth token.');
      }

      _token = token;
      _selectedRole = 'consumer';
      _currentUser = {
        'id': data['user_id'],
        'username': data['username'],
        'email': data['email'],
        'user_type': 'consumer',
        'consumer_profile': data['consumer_profile'],
      };
      _activeSupplierId = kDefaultSupplierId;
      notifyListeners();
    } on ApiServiceException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void setSupplierId(int? supplierId) {
    if (_activeSupplierId == supplierId) return;
    _activeSupplierId = supplierId;
    notifyListeners();
  }

  void hydrateSupplierId(int? supplierId) {
    if (supplierId == null) return;
    if (_activeSupplierId != null) return;
    _activeSupplierId = supplierId;
    notifyListeners();
  }
}
