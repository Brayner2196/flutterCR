import '../../../core/enums/estado_carga.dart';
import '../../../core/enums/modulo.dart';
import '../../../core/providers/base_provider.dart';
import '../../../core/providers/carga_resoluble.dart';
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
/// ## Qué responde mientras no ha cargado
///
/// Tres estados, no dos ([EstadoCarga]):
///
/// - `inicial`/`cargando` → **false**: se oculta. Mostrar de más para quitarlo
///   medio segundo después es el peor de los mundos — el usuario alcanza a ver
///   un acceso que después desaparece. Quien espera la respuesta es
///   `SesionListaGate`, que pinta un esqueleto en vez de la pantalla a medias.
/// - `error` → **true**: fail-open a propósito. Si el backend no responde es
///   preferible mostrar de más (y que el 403 corte en el servidor, que es la
///   autoridad real) a dejar al usuario con una app vacía sin explicación.
class ModulosProvider extends BaseProvider implements CargaResoluble {
  Set<String> _activos = {};
  EstadoCarga _estado = EstadoCarga.inicial;

  /// Códigos crudos habilitados (útil para depurar).
  Set<String> get activos => _activos;

  @override
  EstadoCarga get estadoCarga => _estado;

  @override
  bool get resuelto => _estado.resuelto;

  /// ¿El conjunto tiene este módulo habilitado?
  bool activo(Modulo modulo) {
    switch (_estado) {
      case EstadoCarga.inicial:
      case EstadoCarga.cargando:
        return false;
      case EstadoCarga.error:
        return true;
      case EstadoCarga.listo:
        return _activos.contains(modulo.codigo);
    }
  }

  /// ¿Están habilitados TODOS estos módulos?
  bool activosTodos(List<Modulo> modulos) => modulos.every(activo);

  /// ¿Está habilitado AL MENOS UNO?
  bool activoAlguno(List<Modulo> modulos) => modulos.any(activo);

  /// Carga los módulos del conjunto. La dispara [SesionContextoLoader] apenas
  /// hay tenant en sesión, junto con los permisos.
  Future<void> cargar() async {
    _estado = EstadoCarga.cargando;
    try {
      setLoading(true);
      _activos = await ModuloService.misModulos();
      _estado = EstadoCarga.listo;
      limpiarError();
    } catch (e) {
      _estado = EstadoCarga.error;
      setError('No se pudieron cargar los módulos del conjunto');
    } finally {
      setLoading(false);
    }
  }

  /// Aplica en caliente el catálogo que devuelve el panel del SUPER_ADMIN,
  /// sin una llamada extra.
  void aplicarDesdeCatalogo(List<ModuloEstado> catalogo) {
    _activos = catalogo.where((m) => m.activo).map((m) => m.codigo).toSet();
    _estado = EstadoCarga.listo;
    notifyListeners();
  }

  /// Sesión iniciada pero sin conjunto asignado: caso anómalo (una sesión
  /// guardada vieja, un token sin `X-Tenant-ID`).
  ///
  /// Se marca como RESUELTO y fail-open en vez de dejarlo en `inicial`, porque
  /// `inicial` significa "todavía no sé" y el gate esperaría una respuesta que
  /// nadie va a pedir: el usuario se quedaría mirando el esqueleto para
  /// siempre. Un esqueleto eterno es peor que el parpadeo que vinimos a
  /// arreglar. Degradamos al comportamiento de antes: se muestra todo y el
  /// backend corta con 403 lo que no corresponda.
  void marcarSinConjunto() {
    _activos = {};
    _estado = EstadoCarga.error;
    setLoading(false);
  }

  /// Se llama en el logout y al cambiar de conjunto. Vuelve a `inicial`, así el
  /// gate muestra el esqueleto otra vez en vez de los módulos del conjunto
  /// anterior.
  void limpiarDatos() {
    _activos = {};
    _estado = EstadoCarga.inicial;
    limpiarError();
    setLoading(false);
  }
}
