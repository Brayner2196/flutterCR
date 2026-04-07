import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  static Future<Map<String, String>> _headers({bool requiresAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (requiresAuth) {
      final sesion = await TokenStorage.leerSesion();
      final token = sesion['token'];
      final tenantId = sesion['tenantId'];
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      if (tenantId != null && tenantId.isNotEmpty) {
        headers['X-Tenant-ID'] = tenantId;
      }
    }
    return headers;
  }

  static Future<http.Response> get(String path) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = await _headers();
    return http.get(uri, headers: headers);
  }

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = await _headers(requiresAuth: requiresAuth);
    return http.post(uri, headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = await _headers();
    return http.put(uri, headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> delete(String path) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = await _headers();
    return http.delete(uri, headers: headers);
  }

  static Future<http.Response> patch(String path) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = await _headers();
    return http.patch(uri, headers: headers);
  }
}
