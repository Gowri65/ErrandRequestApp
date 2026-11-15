
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:3000';

  static String? token;

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
  }

  static Future<void> saveSession(
    String accessToken,
    Map<String, dynamic> user,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', accessToken);
    await prefs.setString('user', jsonEncode(user));
    token = accessToken;
  }

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');

    if (userString == null) return null;

    return jsonDecode(userString) as Map<String, dynamic>;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    token = null;
  }

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static dynamic handleResponse(http.Response response) {
    final body = response.body.isEmpty
        ? null
        : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body is Map
        ? body['message']?.toString() ?? 'Something went wrong'
        : 'Something went wrong';

    throw Exception(message);
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return Map<String, dynamic>.from(handleResponse(response));
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    return Map<String, dynamic>.from(handleResponse(response));
  }

  static Future<List<dynamic>> getErrands(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl/errands/$endpoint'),
      headers: headers,
    );

    return List<dynamic>.from(handleResponse(response));
  }

  static Future<Map<String, dynamic>> createErrand(
    Map<String, String> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/errands'),
      headers: headers,
      body: jsonEncode(data),
    );

    return Map<String, dynamic>.from(handleResponse(response));
  }

  static Future<Map<String, dynamic>> acceptErrand(String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/errands/$id/accept'),
      headers: headers,
    );

    return Map<String, dynamic>.from(handleResponse(response));
  }

  static Future<Map<String, dynamic>> cancelErrand(String id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/errands/$id/cancel'),
      headers: headers,
    );

    return Map<String, dynamic>.from(handleResponse(response));
  }

  static Future<Map<String, dynamic>> updateStatus(
    String id,
    String status,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/errands/$id/status'),
      headers: headers,
      body: jsonEncode({'status': status}),
    );

    return Map<String, dynamic>.from(handleResponse(response));
  }
}
