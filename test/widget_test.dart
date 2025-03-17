import 'package:flutter_test/flutter_test.dart';
import 'package:green_pay/services/auth_service.dart';

import 'package:green_pay/main.dart';

void main() {
  testWidgets('App can be created', (WidgetTester tester) async {
    // Create a real AuthService instance
    final authService = AuthService();

    // Build our app and trigger a frame
    await tester.pumpWidget(MyApp(authService: authService));

    // Verify the app was created successfully
    expect(find.byType(MyApp), findsOneWidget);
  });
}
