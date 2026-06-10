import 'dart:convert';
import '../../../core/providers/base_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class InquilinoPermisosProvider extends BaseProvider {
  Set<String> _permisos = {};

  Set<String> get permisos => _permisos;
  bool tienePermiso(String permiso) => _permisos.contains(permiso);

  Future<void> cargar() async {
    try {
      setLoading(true);
      final res = await ApiClient.get(ApiConstants.misPermisos);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        _permisos = Set<String>.from(body['permisos'] ?? []);
      } else {
        _permisos = {};
      }
      limpiarError();
    } catch (e) {
      _permisos = {};
      setError('Error cargando permisos');
    } finally {
      setLoading(false);
    }
  }

  void limpiarDatos() {
    _permisos.clear();
    limpiarError();
    setLoading(false);
  }
}
