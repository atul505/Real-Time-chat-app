import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/main.dart';
import 'package:mobile_app/pages/login_page.dart';

void main() {
  testWidgets('App should show login page when no token', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(initialWidget: LoginPage()));
    await tester.pumpAndSettle();

    // Verify login page renders
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });
}
