import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Use localhost:8080 for your ADB reverse setup
  static const String baseUrl = 'http://localhost:8080/api/users';
  final _storage = const FlutterSecureStorage();

  // Login Method
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save the JWT token securely to persist login
        await _storage.write(key: 'jwt_token', value: data['token']);

        return {
          'success': true,
          'username': data['username'],
          'token': data['token']
        };
      } else {
        return {'success': false, 'message': 'Invalid Email or Password'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Server unreachable. Check ADB reverse or Firewall.'};
    }
  }

  // Registration Method
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
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
    } catch (e) {
      return {'success': false, 'message': 'Registration failed: $e'};
    }
  }

  // Check if user is already logged in (Use this in main.dart)
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Logout Method
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }
}