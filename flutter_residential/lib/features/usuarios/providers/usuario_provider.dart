import '../../../core/providers/base_provider.dart';
import '../models/usuario_response.dart';
import '../services/usuario_service.dart';

class UsuarioProvider extends BaseProvider {
  List<UsuarioResponse> _todos = [];

  List<UsuarioResponse> get usuarios => _todos;
  List<UsuarioResponse> get activos =>
      _todos.where((u) => u.estado == 'ACTIVO').toList();
  List<UsuarioResponse> get pendientes =>
      _todos.where((u) => u.estado == 'PENDIENTE').toList();
  List<UsuarioResponse> get inactivos =>
      _todos.where((u) => u.estado == 'INACTIVO').toList();
  List<UsuarioResponse> get rechazados =>
      _todos.where((u) => u.estado == 'RECHAZADO').toList();

  Future<void> cargarTodos() async {
    final resultado = await ejecutar(() => UsuarioService.listarTodos());
    if (resultado != null) {
      _todos = resultado;
    }
  }

  /// Devuelve true si el backend lo aceptó. En false, el motivo real queda en
  /// [error] — `ejecutar` lo atrapa y NO relanza, así que el llamador tiene que
  /// mirar este booleano; un `try/catch` alrededor nunca se dispara.
  Future<bool> crear(Map<String, dynamic> data) async {
    final nuevo = await ejecutar(() => UsuarioService.crear(data));
    if (nuevo == null) return false;
    agregarAlFinal(_todos, nuevo);
    return true;
  }

  /// Devuelve true si el backend lo aceptó. En false, el motivo real queda en
  /// [error] — `ejecutar` lo atrapa y NO relanza, así que el llamador tiene que
  /// mirar este booleano; un `try/catch` alrededor nunca se dispara.
  Future<bool> aprobar(int id, {String rolDestino = 'PROPIETARIO'}) async {
    final actualizado = await ejecutar(
      () => UsuarioService.aprobar(id, rolDestino: rolDestino),
    );
    if (actualizado == null) return false;
    _reemplazar(actualizado);
    return true;
  }

  /// Devuelve true si el backend lo aceptó. En false, el motivo real queda en
  /// [error] — `ejecutar` lo atrapa y NO relanza, así que el llamador tiene que
  /// mirar este booleano; un `try/catch` alrededor nunca se dispara.
  Future<bool> rechazar(int id) async {
    final actualizado = await ejecutar(() => UsuarioService.rechazar(id));
    if (actualizado == null) return false;
    _reemplazar(actualizado);
    return true;
  }

  /// Devuelve true si el backend lo aceptó. En false, el motivo real queda en
  /// [error] — `ejecutar` lo atrapa y NO relanza, así que el llamador tiene que
  /// mirar este booleano; un `try/catch` alrededor nunca se dispara.
  Future<bool> actualizar(int id, Map<String, dynamic> data) async {
    final actualizado = await ejecutar(
      () => UsuarioService.actualizar(id, data),
    );
    if (actualizado == null) return false;
    _reemplazar(actualizado);
    return true;
  }

  void limpiarDatos() {
    _todos.clear();
    limpiarError();
    setLoading(false);
  }

  void _reemplazar(UsuarioResponse actualizado) {
    reemplazar(_todos, actualizado, (u) => u.id);
  }
}
