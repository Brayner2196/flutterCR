import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  static const _timeout = Duration(seconds: 15);

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
    try {
      return await http.get(uri, headers: headers).timeout(_timeout);
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = await _headers(requiresAuth: requiresAuth);
    try {
      return await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = await _headers();
    try {
      return await http
          .put(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }

  static Future<http.Response> delete(String path) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = await _headers();
    try {
      return await http.delete(uri, headers: headers).timeout(_timeout);
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }

  static Future<http.Response> patch(String path) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = await _headers();
    try {
      return await http.patch(uri, headers: headers).timeout(_timeout);
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }
}
