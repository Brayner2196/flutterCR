import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/enums/estado_carga.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/base_provider.dart';
import '../../../core/providers/carga_resoluble.dart';

/// Permisos que el propietario le concedió a su inquilino.
///
/// Segunda capa del control de acceso, independiente de los módulos del
/// conjunto ([ModulosProvider]): el módulo dice qué contrató el conjunto, el
/// permiso dice qué le dejó ver el propietario. Ambas deben pasar.
///
/// [tienePermiso] es fail-closed siempre (sin dato → false). A diferencia de
/// los módulos acá no hay fail-open al fallar: mostrarle a un inquilino algo
/// que su propietario no le habilitó es peor que no mostrárselo. Lo que evita
/// el parpadeo es el gate, que no construye la pantalla hasta que
/// [resuelto] sea true.
class InquilinoPermisosProvider extends BaseProvider implements CargaResoluble {
  Set<String> _permisos = {};
  EstadoCarga _estado = EstadoCarga.inicial;

  Set<String> get permisos => _permisos;

  @override
  EstadoCarga get estadoCarga => _estado;

  @override
  bool get resuelto => _estado.resuelto;

  bool tienePermiso(String permiso) => _permisos.contains(permiso);

  Future<void> cargar() async {
    _estado = EstadoCarga.cargando;
    try {
      setLoading(true);
      final res = await ApiClient.get(ApiConstants.misPermisos);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        _permisos = Set<String>.from(body['permisos'] ?? []);
        _estado = EstadoCarga.listo;
        limpiarError();
      } else {
        _permisos = {};
        _estado = EstadoCarga.error;
        setError('Error cargando permisos');
      }
    } catch (e) {
      _permisos = {};
      _estado = EstadoCarga.error;
      setError('Error cargando permisos');
    } finally {
      setLoading(false);
    }
  }

  /// Marca los permisos como resueltos SIN pedirlos al backend.
  ///
  /// Necesario para todo rol que no es inquilino (propietario, admin,
  /// vigilante): nunca llama a [cargar], así que sin esto el estado se quedaría
  /// en `inicial` para siempre y el gate se colgaría mostrando el esqueleto.
  /// El set vacío no les quita nada: esos roles ni consultan [tienePermiso], o
  /// lo hacen detrás de un `esPropietario ||`.
  void marcarNoAplica() {
    _permisos = {};
    _estado = EstadoCarga.listo;
    limpiarError();
    setLoading(false);
  }

  void limpiarDatos() {
    _permisos = {};
    _estado = EstadoCarga.inicial;
    limpiarError();
    setLoading(false);
  }
}
