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

  // ─── Persistir claims de consejo desde JWT ──────────────────────────────

  /// Decodifica el payload del JWT (base64url) y persiste esConsejero + cargoConsejo.
  /// Fire-and-forget: no afecta el flujo de refresh si falla.
  static void _persistirClaimsConsejo(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return;
      // base64url → base64 estándar
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) payload += '=';
      final decoded = utf8.decode(base64Decode(payload));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;
      final esConsejero = claims['esConsejero'] as bool? ?? false;
      final cargo = claims['cargoConsejo'] as String?;
      // Actualiza solo las claves de consejo (no toca token ni otros campos)
      TokenStorage.guardarClaimsConsejo(esConsejero: esConsejero, cargoConsejo: cargo);
    } catch (_) {
      // Falla silenciosamente — el user verá el estado correcto en el próximo login
    }
  }

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
        // Persiste claims de consejo extraídos del nuevo JWT
        _persistirClaimsConsejo(newToken);
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
  /// - Si [suppressSessionExpiry] es true, NO dispara el sessionExpiredStream ni
  ///   lanza excepción; simplemente relanza el 401 como respuesta normal.
  ///   Usar en llamadas best-effort (ej: confirmar pago desde WebView) donde
  ///   una 401 no debe cerrar la sesión del usuario.
  static Future<http.Response?> _handleUnauthorized(
    http.Response res,
    Future<http.Response> Function() retry, {
    bool suppressSessionExpiry = false,
  }) async {
    if (res.statusCode != 401) return null; // no era 401, el caller maneja res

    final refreshed = await _tryRefresh();
    if (refreshed) return await retry();

    // Refresh falló.
    if (suppressSessionExpiry) {
      // Llamada best-effort: devolver la 401 sin disparar logout.
      return res;
    }

    // Refresh falló — avisar al SessionGuard y lanzar excepción tipada.
    // Nunca devolvemos null aquí para que el caller no intente parsear
    // la respuesta 401 (que puede tener body vacío → FormatException).
    _sessionExpiredController.add(null);
    throw const SessionExpiredException();
  }

  // ─── Headers ────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers({
    bool requiresAuth = true,
    String? token,
    String? tenantId,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (requiresAuth) {
      // Si se pasan explícitamente (ej: logout) los usa directamente sin leer storage.
      // Esto evita el race condition entre el DELETE de notificaciones y borrarSesion().
      String? resolvedToken = token;
      String? resolvedTenant = tenantId;

      if (resolvedToken == null || resolvedTenant == null) {
        final sesion = await TokenStorage.leerSesion();
        resolvedToken ??= sesion['token'];
        resolvedTenant ??= sesion['tenantId'];
      }

      if (resolvedToken != null) {
        headers['Authorization'] = 'Bearer $resolvedToken';
      }
      if (resolvedTenant != null && resolvedTenant.isNotEmpty) {
        headers['X-Tenant-ID'] = resolvedTenant;
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
    /// Si es true y el refresh falla, NO dispara sessionExpiredStream ni hace logout.
    /// Usar para llamadas best-effort como confirmar pago desde WebView.
    bool suppressSessionExpiry = false,
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
            suppressSessionExpiry: suppressSessionExpiry,
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

  static Future<http.Response> delete(
    String path, {
    String? token,
    String? tenantId,
  }) async {
    await _checkConnectivity();
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    try {
      final res = await http
          .delete(uri, headers: await _headers(token: token, tenantId: tenantId))
          .timeout(_timeout);

      return await _handleUnauthorized(
            res,
            () async => http
                .delete(uri, headers: await _headers(token: token, tenantId: tenantId))
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

  /// POST multipart/form-data reutilizable (subida de archivos).
  /// [filePath] es la ruta local del archivo; [fileField] el nombre del part.
  /// Maneja auth, tenant y refresh 401 igual que el resto de métodos.
  static Future<http.Response> postMultipart(
    String path, {
    required String fileField,
    required String filePath,
    Map<String, String> fields = const {},
    Duration timeout = const Duration(minutes: 5),
  }) async {
    await _checkConnectivity();
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');

    Future<http.Response> enviar() async {
      final headers = await _headers();
      // MultipartRequest define su propio Content-Type (boundary)
      headers.remove('Content-Type');

      final req = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
        ..fields.addAll(fields);
      req.files.add(await http.MultipartFile.fromPath(fileField, filePath));

      final streamed = await req.send().timeout(timeout);
      return http.Response.fromStream(streamed);
    }

    try {
      final res = await enviar();
      return await _handleUnauthorized(res, enviar) ?? res;
    } on SessionExpiredException {
      rethrow;
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('La subida tardó demasiado. Inténtalo de nuevo.');
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
