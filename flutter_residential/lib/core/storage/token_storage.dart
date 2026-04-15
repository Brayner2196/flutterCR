import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'jwt_token';
  static const _keyEmail = 'user_email';
  static const _keyRol = 'user_rol';
  static const _keyTenantId = 'tenant_id';
  static const _keyNombreConjunto = 'nombre_conjunto';
  static const _keyNombre = 'user_nombre';

  static Future<void> guardarSesion({
    required String token,
    required String email,
    required String rol,
    required String tenantId,
    String? nombreConjunto,
    String? nombre,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyRol, value: rol);
    await _storage.write(key: _keyTenantId, value: tenantId);
    if (nombreConjunto != null) {
      await _storage.write(key: _keyNombreConjunto, value: nombreConjunto);
    }
    if (nombre != null) {
      await _storage.write(key: _keyNombre, value: nombre);
    }
  }

  static Future<String?> leerToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<Map<String, String?>> leerSesion() async {
    return {
      'token': await _storage.read(key: _keyToken),
      'email': await _storage.read(key: _keyEmail),
      'rol': await _storage.read(key: _keyRol),
      'tenantId': await _storage.read(key: _keyTenantId),
      'nombreConjunto': await _storage.read(key: _keyNombreConjunto),
      'nombre': await _storage.read(key: _keyNombre),
    };
  }

  static Future<void> borrarSesion() async {
    await _storage.deleteAll();
  }
}
