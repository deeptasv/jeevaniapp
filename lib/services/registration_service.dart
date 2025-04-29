import 'dart:convert';
import 'package:http/http.dart' as http;

class RegistrationService {
  final String baseUrl = 'http://10.40.12.14:3000'; // Update with your local IP

  Future<Map<String, dynamic>> registerUser({
    required String role,
    required String name,
    required String phone,
    required String location,
    required String password, // Added password parameter
  }) async {
    final url = Uri.parse('$baseUrl/api/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'role': role,
        'name': name,
        'phone': phone,
        'location': location,
        'password': password, // Include password in the request
      }),
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }
}