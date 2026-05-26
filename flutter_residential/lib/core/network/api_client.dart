import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../exceptions/session_expired_exception.dart';
import '../storage/token_storage.dart';

class ApiClient {
  static const _timeout = Duration(seconds: 15);
  static final _connectivity = Connectivity();

  /// Emite evento cuando el refresh falla y la sesión debe cerrarse.
  static final _sessionExpiredController = StreamController<void>.broadcast();
  static Stream<void> get sessionExpiredStream => _sessionExpiredController.stream;

  // ─── Mutex de refresh ────────────────────────────────────────────────────
  // Evita que múltiples peticiones simultáneas (ej: dashboard) lancen varias
  // solicitudes de refresh al mismo tiempo, invalidando el token recién emitido.

  static Future<bool>? _refreshInFlight;

  // ─── Verificación de red ────────────────────────────────────────────────

  static Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    final online = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
    if (!online) {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    }
  }

  // ─── Refresh token interno ──────────────────────────────────────────────

  /// Intenta renovar el access token usando el refresh token guardado.
  /// Solo hay una solicitud de refresh en vuelo a la vez (mutex).
  static Future<bool> _tryRefresh() async {
    // Si ya hay un refresh en curso, espera el mismo Future en lugar de lanzar otro.
    _refreshInFlight ??= _executeRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
    return _refreshInFlight!;
  }

  static Future<bool> _executeRefresh() async {
    try {
      final refreshToken = await TokenStorage.leerRefreshToken();
      if (refreshToken == null) return false;

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refresh}');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final rawBody = res.body.trim();
        if (rawBody.isEmpty) return false;
        final data = jsonDecode(rawBody) as Map<String, dynamic>;
        final newToken = data['token'] as String?;
        final newRefresh = data['refreshToken'] as String?;
        if (newToken == null || newRefresh == null) return false;
        await TokenStorage.actualizarTokens(
          token: newToken,
          refreshToken: newRefresh,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Verifica si la respuesta es 401 y en ese caso intenta refresh.
  /// - Devuelve `null` si la respuesta no era 401 (el caller usa `?? res`).
  /// - Devuelve la nueva respuesta si el refresh fue exitoso y se reintentó.
  /// - Lanza [SessionExpiredException] si el refresh falló (nunca devuelve la 401 vacía).
  static Future<http.Response?> _handleUnauthorized(
    http.Response res,
    Future<http.Response> Function() retry,
  ) async {
    if (res.statusCode != 401) return null; // no era 401, el caller maneja res

    final refreshed = await _tryRefresh();
    if (refreshed) return await retry();

    // Refresh falló — avisar al SessionGuard y lanzar excepción tipada.
    // Nunca devolvemos null aquí para que el caller no intente parsear
    // la respuesta 401 (que puede tener body vacío → FormatException).
    _sessionExpiredController.add(null);
    throw const SessionExpiredException();
  }

  // ─── Headers ────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers({bool requiresAuth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
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

  // ─── HTTP methods ────────────────────────────────────────────────────────

  static Future<http.Response> get(String path, {bool requiresAuth = true}) async {
    await _checkConnectivity();
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    try {
      final res = await http
          .get(uri, headers: await _headers(requiresAuth: requiresAuth))
          .timeout(_timeout);

      return await _handleUnauthorized(
            res,
            () async => http
                .get(uri, headers: await _headers(requiresAuth: requiresAuth))
                .timeout(_timeout),
          ) ??
          res;
    } on SessionExpiredException {
      rethrow;
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
    await _checkConnectivity();
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final encodedBody = jsonEncode(body);
    try {
      final res = await http
          .post(uri, headers: await _headers(requiresAuth: requiresAuth), body: encodedBody)
          .timeout(_timeout);

      if (!requiresAuth) return res; // login/registro no necesitan retry
      return await _handleUnauthorized(
            res,
            () async => http
                .post(uri, headers: await _headers(requiresAuth: requiresAuth), body: encodedBody)
                .timeout(_timeout),
          ) ??
          res;
    } on SessionExpiredException {
      rethrow;
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body) async {
    await _checkConnectivity();
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final encodedBody = jsonEncode(body);
    try {
      final res = await http
          .put(uri, headers: await _headers(), body: encodedBody)
          .timeout(_timeout);

      return await _handleUnauthorized(
            res,
            () async =>
                http.put(uri, headers: await _headers(), body: encodedBody).timeout(_timeout),
          ) ??
          res;
    } on SessionExpiredException {
      rethrow;
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }

  static Future<http.Response> delete(String path) async {
    await _checkConnectivity();
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    try {
      final res = await http.delete(uri, headers: await _headers()).timeout(_timeout);

      return await _handleUnauthorized(
            res,
            () async => http.delete(uri, headers: await _headers()).timeout(_timeout),
          ) ??
          res;
    } on SessionExpiredException {
      rethrow;
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }

  static Future<http.Response> patch(String path, [Map<String, dynamic>? body]) async {
    await _checkConnectivity();
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final encodedBody = body != null ? jsonEncode(body) : null;
    try {
      final res = await http
          .patch(uri, headers: await _headers(), body: encodedBody)
          .timeout(_timeout);

      return await _handleUnauthorized(
            res,
            () async =>
                http.patch(uri, headers: await _headers(), body: encodedBody).timeout(_timeout),
          ) ??
          res;
    } on SessionExpiredException {
      rethrow;
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }
}
