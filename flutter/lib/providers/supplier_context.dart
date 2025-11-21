import 'package:flutter/material.dart';

class SupplierContext extends ChangeNotifier {
  int? _supplierId;
  String? _supplierName;

  int? get supplierId => _supplierId;
  String? get supplierName => _supplierName;
  bool get hasSelection => _supplierId != null;

  void setSupplier({
    required int supplierId,
    String? supplierName,
  }) {
    if (_supplierId == supplierId && _supplierName == supplierName) return;
    _supplierId = supplierId;
    _supplierName = supplierName;
    notifyListeners();
  }

  void clear() {
    if (_supplierId == null && _supplierName == null) return;
    _supplierId = null;
    _supplierName = null;
    notifyListeners();
  }
}

