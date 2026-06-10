import '../../../core/providers/base_provider.dart';
import '../models/tipo_propiedad_nodo.dart';
import '../../usuarios/models/usuario_propiedad_response.dart';
import '../services/propiedad_service.dart';

class PropiedadProvider extends BaseProvider {
  List<TipoPropiedadNodo> _tiposArbol = [];
  List<UsuarioPropiedadResponse> _misPropiedades = [];
  UsuarioPropiedadResponse? _propiedadActual;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Getters públicos (loading y error heredados de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<TipoPropiedadNodo> get tiposArbol => _tiposArbol;
  List<UsuarioPropiedadResponse> get misPropiedades => _misPropiedades;
  UsuarioPropiedadResponse? get propiedadActual => _propiedadActual;

  /// true cuando la propiedad seleccionada es un parqueadero
  bool get propiedadActualEsParqueadero => _propiedadActual?.esParqueadero ?? false;

  /// true cuando el usuario tiene más de una propiedad asignada
  bool get tieneMultiplesPropiedades => _misPropiedades.length > 1;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Cargar datos (usando ejecutar() de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> cargarTiposAdmin() async {
    _tiposArbol = await ejecutar(() => PropiedadService.getTiposArbolAdmin()) ?? [];
  }

  Future<List<TipoPropiedadNodo>> cargarTipos(String codigo) async {
    _tiposArbol = await ejecutar(() => PropiedadService.getTiposArbol(codigo)) ?? [];
    return _tiposArbol;
  }

  Future<void> cargarMisPropiedades() async {
    try {
      _misPropiedades = await ejecutar(
        () => PropiedadService.getMisPropiedades(),
      ) ?? [];
      _propiedadActual = _misPropiedades.firstWhere(
        (p) => p.esPrincipal,
        orElse: () => _misPropiedades.isNotEmpty ? _misPropiedades.first : _propiedadActual!,
      );
      notifyListeners();
    } catch (_) {
      // silently fail — no propiedades asignadas aún
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Acciones
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void seleccionarPropiedad(UsuarioPropiedadResponse propiedad) {
    _propiedadActual = propiedad;
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Limpiar estado
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void limpiarDatos() {
    limpiar(_tiposArbol);
    limpiar(_misPropiedades);
    _propiedadActual = null;
    limpiarError();
    notifyListeners();
  }
}
