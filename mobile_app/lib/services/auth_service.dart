import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Use localhost:8080 for your ADB reverse setup
  static const String baseUrl = 'http://localhost:8080/api/users';
  final _storage = const FlutterSecureStorage();

  // 1. Updated Login: Correctly saves the username for the Home Page preview
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save both JWT and Username from the server response
        await _storage.write(key: 'jwt_token', value: data['token']);
        await _storage.write(key: 'username', value: data['username']);

        return {'success': true};
      } else {
        return {'success': false, 'message': 'Invalid Email or Password'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Server unreachable. Check ADB reverse or Firewall.'};
    }
  }

  // 2. Added Getter: Allows Home Page to fetch messages from Neon based on this user
  Future<String?> getUsername() async {
    return await _storage.read(key: 'username');
  }

  // 3. Registration: Uses the defined baseUrl
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

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // 4. Improved Logout: Deletes ALL keys (token and username) to ensure a clean exit
  Future<void> logout() async {
    await _storage.deleteAll();
  }
}