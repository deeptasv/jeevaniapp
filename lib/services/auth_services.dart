import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'http://10.40.12.14:3000'; // Update with your local IP

  // Registration method
  Future<Map<String, dynamic>> registerUser({
    required String role,
    required String name,
    required String phone,
    required String location,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/register');
    print('AuthService: Registering user with role: $role, phone: $phone');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'role': role,
        'name': name,
        'phone': phone,
        'location': location,
        'password': password,
      }),
    );

    print('AuthService: Register Response Status: ${response.statusCode}');
    print('AuthService: Register Response Body: ${response.body}');

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  // Login method
  Future<Map<String, dynamic>> login({
    required String role,
    required String phone,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/login');
    print('AuthService: Logging in with role: $role, phone: $phone');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'role': role.toLowerCase(),
        'phone': phone,
        'password': password,
      }),
    );

    print('AuthService: Login Response Status: ${response.statusCode}');
    print('AuthService: Login Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }
}