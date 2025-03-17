import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:green_pay/services/biometric_auth_service.dart';
import 'package:green_pay/utils/secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BiometricAuthService', () {
    test('BiometricAuthService can be instantiated', () {
      final service = BiometricAuthService();
      expect(service, isNotNull);
    });

    // Add more integration tests as needed that don't rely on mocks
    // These tests will use the actual implementation
  });
}
