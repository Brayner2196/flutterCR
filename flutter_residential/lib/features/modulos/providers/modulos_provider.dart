import '../../../core/enums/modulo.dart';
import '../../../core/providers/base_provider.dart';
import '../models/modulo_estado.dart';
import '../services/modulo_service.dart';

/// Módulos habilitados del conjunto en sesión.
///
/// Misma forma de uso que [InquilinoPermisosProvider], a propósito: los dos se
/// consultan igual y se combinan sin fricción.
///
/// ```dart
/// if (modulos.activo(Modulo.pqr) && permisos.tienePermiso('PQRS')) { ... }
/// ```
///
/// Los dos son capas distintas y AMBAS deben pasar:
/// - módulo  → qué contrató el conjunto (lo decide el SUPER_ADMIN)
/// - permiso → qué le dejó ver el propietario a su inquilino
///
/// Mientras no se hayan cargado ([cargado] == false) se responde `true`: así la
/// UI no parpadea ocultando accesos en el primer frame para volver a mostrarlos
/// medio segundo después.
class ModulosProvider extends BaseProvider {
  Set<String> _activos = {};
  bool _cargado = false;

  /// Códigos crudos habilitados (útil para depurar).
  Set<String> get activos => _activos;

  /// True cuando ya hubo una respuesta del backend.
  bool get cargado => _cargado;

  /// ¿El conjunto tiene este módulo habilitado?
  bool activo(Modulo modulo) {
    if (!_cargado) return true;
    return _activos.contains(modulo.codigo);
  }

  /// ¿Están habilitados TODOS estos módulos?
  bool activosTodos(List<Modulo> modulos) => modulos.every(activo);

  /// ¿Está habilitado AL MENOS UNO?
  bool activoAlguno(List<Modulo> modulos) => modulos.any(activo);

  /// Carga los módulos del conjunto. Se llama justo después del login, en el
  /// mismo punto donde ya se cargan los permisos de inquilino.
  Future<void> cargar() async {
    try {
      setLoading(true);
      _activos = await ModuloService.misModulos();
      _cargado = true;
      limpiarError();
    } catch (e) {
      // Falla abierta a propósito: si el backend no responde, es preferible
      // mostrar de más (y que el 403 corte en el servidor, que es la
      // autoridad real) a dejar al usuario con una app vacía sin explicación.
      _cargado = false;
      setError('No se pudieron cargar los módulos del conjunto');
    } finally {
      setLoading(false);
    }
  }

  /// Aplica en caliente el catálogo que devuelve el panel del SUPER_ADMIN,
  /// sin una llamada extra.
  void aplicarDesdeCatalogo(List<ModuloEstado> catalogo) {
    _activos = catalogo.where((m) => m.activo).map((m) => m.codigo).toSet();
    _cargado = true;
    notifyListeners();
  }

  /// Se llama en el logout y al cambiar de conjunto.
  void limpiarDatos() {
    _activos = {};
    _cargado = false;
    limpiarError();
    setLoading(false);
  }
}
