import '../../../core/providers/base_provider.dart';
import '../models/propiedad_admin.dart';
import '../services/propiedad_service.dart';

/// Provider del módulo de gestión de propiedades (unidades) del admin.
/// Mantiene la lista completa y expone filtros/estadísticas derivadas.
class GestionPropiedadesProvider extends BaseProvider {
  List<PropiedadAdmin> _propiedades = [];

  List<PropiedadAdmin> get propiedades => _propiedades;

  // ── Filtros por estado / residentes ────────────────────────────────────────
  List<PropiedadAdmin> get ocupadas =>
      _propiedades.where((p) => p.estado == EstadoPropiedad.ocupado).toList();
  List<PropiedadAdmin> get disponibles =>
      _propiedades.where((p) => p.estado == EstadoPropiedad.disponible).toList();
  List<PropiedadAdmin> get enMantenimiento => _propiedades
      .where((p) => p.estado == EstadoPropiedad.enMantenimiento)
      .toList();
  List<PropiedadAdmin> get vendidas =>
      _propiedades.where((p) => p.estado == EstadoPropiedad.vendido).toList();
  List<PropiedadAdmin> get sinResidentes =>
      _propiedades.where((p) => p.sinResidentes).toList();

  // ── Estadísticas ────────────────────────────────────────────────────────────
  int get total => _propiedades.length;
  int get totalOcupadas => ocupadas.length;
  int get totalDisponibles => disponibles.length;
  int get totalMantenimiento => enMantenimiento.length;
  int get totalSinResidentes => sinResidentes.length;

  PropiedadAdmin? porId(int id) {
    for (final p in _propiedades) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ── Carga ────────────────────────────────────────────────────────────────────
  Future<void> cargarTodas() async {
    final res = await ejecutar(() => PropiedadService.getPropiedadesAdmin());
    if (res != null) {
      // El backend devuelve TODOS los nodos del árbol (Torre, Piso, Apartamento).
      // En el listado solo interesan las HOJAS (la unidad final, ej. el
      // Apartamento), es decir, las propiedades que no son padre de ninguna otra.
      final idsPadre = res
          .where((p) => p.parentId != null)
          .map((p) => p.parentId!)
          .toSet();
      _propiedades = res.where((p) => !idsPadre.contains(p.id)).toList();
    }
  }

  // ── Acciones (recargan la lista tras éxito; propagan errores a la UI) ─────────
  Future<void> cambiarEstado(int propiedadId, String estado) async {
    await PropiedadService.actualizarEstadoPropiedad(propiedadId, estado);
    await cargarTodas();
  }

  Future<void> asignarResidente(int propiedadId, int usuarioId) async {
    await PropiedadService.asignarUsuario(propiedadId, usuarioId);
    await cargarTodas();
  }

  Future<void> quitarResidente(int propiedadId, int usuarioId) async {
    await PropiedadService.quitarUsuario(propiedadId, usuarioId);
    await cargarTodas();
  }

  Future<void> marcarPrincipal(int propiedadId, int usuarioId) async {
    await PropiedadService.marcarComoPrincipal(propiedadId, usuarioId);
    await cargarTodas();
  }

  void limpiarDatos() {
    _propiedades = [];
    limpiarError();
    setLoading(false);
  }
}
