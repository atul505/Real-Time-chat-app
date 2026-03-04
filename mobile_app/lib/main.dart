import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'services/auth_service.dart';

void main() async {
  // 1. Ensure Flutter is ready to handle async calls before runApp
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();

  // 2. Check the secure storage for an existing JWT token
  final String? token = await authService.getToken();

  // 3. Decide which page to show based on the token
  runApp(MyApp(
    initialWidget: token != null ? const HomePage() : const LoginPage(),
  ));
}

class MyApp extends StatelessWidget {
  final Widget initialWidget;
  const MyApp({super.key, required this.initialWidget});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Real-Time Chat',
      theme: ThemeData(
        primaryColor: const Color(0xFF1e3c72),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1e3c72)),
      ),
      // 4. Load the determined page (Home if logged in, Login if not)
      home: initialWidget,
    );
  }
}