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

  Future<void> crear(Map<String, dynamic> data) async {
    final nuevo = await ejecutar(() => UsuarioService.crear(data));
    if (nuevo != null) {
      agregarAlFinal(_todos, nuevo);
    }
  }

  Future<void> aprobar(int id, {String rolDestino = 'PROPIETARIO'}) async {
    final actualizado = await ejecutar(
      () => UsuarioService.aprobar(id, rolDestino: rolDestino),
    );
    if (actualizado != null) {
      _reemplazar(actualizado);
    }
  }

  Future<void> rechazar(int id) async {
    final actualizado = await ejecutar(() => UsuarioService.rechazar(id));
    if (actualizado != null) {
      _reemplazar(actualizado);
    }
  }

  Future<void> actualizar(int id, Map<String, dynamic> data) async {
    final actualizado = await ejecutar(
      () => UsuarioService.actualizar(id, data),
    );
    if (actualizado != null) {
      _reemplazar(actualizado);
    }
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
