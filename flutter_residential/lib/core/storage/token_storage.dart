import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'jwt_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyEmail = 'user_email';
  static const _keyRol = 'user_rol';
  static const _keyTenantId = 'tenant_id';
  static const _keyNombreConjunto = 'nombre_conjunto';
  static const _keyNombre = 'user_nombre';
  static const _keyTimezone = 'tenant_timezone';

  static Future<void> guardarSesion({
    required String token,
    required String refreshToken,
    required String email,
    required String rol,
    required String tenantId,
    String? nombreConjunto,
    String? nombre,
    String? timezone,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyRol, value: rol);
    await _storage.write(key: _keyTenantId, value: tenantId);
    if (nombreConjunto != null) {
      await _storage.write(key: _keyNombreConjunto, value: nombreConjunto);
    }
    if (nombre != null) {
      await _storage.write(key: _keyNombre, value: nombre);
    }
    await _storage.write(
        key: _keyTimezone, value: timezone ?? 'America/Bogota');
  }

  /// Actualiza solo los tokens (usado por el interceptor de refresh).
  static Future<void> actualizarTokens({
    required String token,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _keyToken, value: token),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
    ]);
  }

  static Future<String?> leerToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<String?> leerRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  static Future<String?> leerTimezone() async {
    return await _storage.read(key: _keyTimezone);
  }

  static Future<Map<String, String?>> leerSesion() async {
    return {
      'token': await _storage.read(key: _keyToken),
      'refreshToken': await _storage.read(key: _keyRefreshToken),
      'email': await _storage.read(key: _keyEmail),
      'rol': await _storage.read(key: _keyRol),
      'tenantId': await _storage.read(key: _keyTenantId),
      'nombreConjunto': await _storage.read(key: _keyNombreConjunto),
      'nombre': await _storage.read(key: _keyNombre),
      'timezone': await _storage.read(key: _keyTimezone),
    };
  }

  /// Borra cada clave en paralelo (más rápido que deleteAll() en Android KeyStore).
  static Future<void> borrarSesion() async {
    await Future.wait([
      _storage.delete(key: _keyToken),
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keyEmail),
      _storage.delete(key: _keyRol),
      _storage.delete(key: _keyTenantId),
      _storage.delete(key: _keyNombreConjunto),
      _storage.delete(key: _keyNombre),
      _storage.delete(key: _keyTimezone),
    ]);
  }
}
