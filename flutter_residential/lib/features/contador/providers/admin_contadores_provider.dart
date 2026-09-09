import '../../../core/providers/base_provider.dart';
import '../models/contador_model.dart';
import '../services/contador_service.dart';

/// Gestion de los contadores del conjunto. Lo usa SOLO el TENANT_ADMIN.
///
/// Separado de [PermisosContablesProvider] a proposito: aquel es "que puedo
/// hacer yo" y lo carga toda sesion al arrancar; este es "que puede hacer
/// aquel" y solo se carga cuando el admin abre la pantalla.
class AdminContadoresProvider extends BaseProvider {
  List<Contador> _contadores = [];
  Contador? _seleccionado;

  List<Contador> get contadores => _contadores;
  Contador? get seleccionado => _seleccionado;

  /// Contadores que existen pero a los que nadie les dio permisos todavia.
  /// La pantalla los destaca: son cuentas creadas a medias.
  List<Contador> get sinAlcance =>
      _contadores.where((c) => c.sinAlcance).toList();

  Future<void> cargar() async {
    final resultado = await ejecutar(() => ContadorService.listar());
    if (resultado != null) _contadores = resultado;
    notifyListeners();
  }

  Future<void> seleccionar(int usuarioId) async {
    _seleccionado = await ejecutar(() => ContadorService.detalle(usuarioId));
    notifyListeners();
  }

  /// Guarda el alcance completo. Devuelve true si el backend lo acepto.
  ///
  /// Al volver, actualiza tambien la fila de la lista para que el contador de
  /// permisos no quede desfasado sin tener que recargar todo.
  Future<bool> guardarPermisos(int usuarioId, List<String> permisos) async {
    final actualizado =
        await ejecutar(() => ContadorService.guardarPermisos(usuarioId, permisos));
    if (actualizado == null) return false;

    _seleccionado = actualizado;
    _reemplazarEnLista(actualizado);
    notifyListeners();
    return true;
  }

  Future<bool> revocarTodo(int usuarioId) async {
    final actualizado = await ejecutar(() => ContadorService.revocarTodo(usuarioId));
    if (actualizado == null) return false;

    _seleccionado = actualizado;
    _reemplazarEnLista(actualizado);
    notifyListeners();
    return true;
  }

  void _reemplazarEnLista(Contador actualizado) {
    final i = _contadores.indexWhere((c) => c.usuarioId == actualizado.usuarioId);
    if (i >= 0) _contadores[i] = actualizado;
  }

  void limpiarDatos() {
    _contadores = [];
    _seleccionado = null;
    limpiarError();
    setLoading(false);
    notifyListeners();
  }
}
