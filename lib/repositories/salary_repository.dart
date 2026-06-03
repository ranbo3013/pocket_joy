import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Repository for sensitive salary data stored in platform keychain/keystore.
class SalaryRepository {
  static const _key = 'salary_after_tax';

  final FlutterSecureStorage _storage;

  SalaryRepository({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  /// Returns the stored salary, or null if not set.
  Future<double?> getSalary() async {
    try {
      final value = await _storage.read(key: _key);
      if (value == null) return null;
      return double.tryParse(value);
    } catch (_) {
      // Silent fallback on read error (PRD §11)
      return null;
    }
  }

  /// Persists the after-tax salary.
  Future<bool> setSalary(double value) async {
    try {
      await _storage.write(key: _key, value: value.toString());
      return true;
    } catch (_) {
      // Retry once on write failure (PRD §11)
      try {
        await _storage.write(key: _key, value: value.toString());
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  /// Removes stored salary.
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Best effort
    }
  }
}
