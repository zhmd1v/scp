/// Central place to define the backend base URL used by API calls.
/// Override at runtime with:
///   flutter run --dart-define=API_BASE_URL=http://<host>:<port>
const String kBackendBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

/// Optional supplier ID hint for supplier-specific endpoints.
/// Set with:
///   flutter run --dart-define=SUPPLIER_ID=1
const String _supplierIdEnv = String.fromEnvironment('SUPPLIER_ID', defaultValue: '');

int? get kDefaultSupplierId =>
    _supplierIdEnv.isEmpty ? null : int.tryParse(_supplierIdEnv);
