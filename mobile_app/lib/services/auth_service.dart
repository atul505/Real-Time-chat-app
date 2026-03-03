import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Use 10.0.2.2 for Android Emulator, or your Local IP for physical devices
  static const String baseUrl = 'http://localhost:8080/api/users';
  final _storage = const FlutterSecureStorage();

  // Login Method
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10)); // Stop waiting after 10 seconds

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'jwt_token', value: data['token']);
        return {'success': true, 'username': data['username']};
      } else {
        return {'success': false, 'message': 'Invalid Email or Password'};
      }
    } catch (e) {
      // This will now catch timeouts and connection errors
      return {'success': false, 'message': 'Server unreachable. Check IP or Firewall.'};
    }
  }

  // Registration Method
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {'success': false, 'message': response.body};
    }
  }
}