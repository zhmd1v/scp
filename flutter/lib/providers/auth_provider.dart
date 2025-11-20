import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? _selectedRole;

  String? get selectedRole => _selectedRole;

  void chooseRole(String role) {
    if (_selectedRole == role) return;
    _selectedRole = role;
    notifyListeners();
  }

  void clearRole() {
    if (_selectedRole == null) return;
    _selectedRole = null;
    notifyListeners();
  }
}
