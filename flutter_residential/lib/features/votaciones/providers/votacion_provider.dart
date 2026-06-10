import '../../../core/providers/base_provider.dart';
import '../models/votacion_model.dart';
import '../services/votacion_service.dart';

class VotacionProvider extends BaseProvider {
  List<VotacionModel> _votaciones = [];
  VotacionModel? _seleccionada;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Getters públicos (loading y error heredados de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<VotacionModel> get votaciones => _votaciones;
  VotacionModel? get seleccionada => _seleccionada;
  int get pendientesDeVotar =>
      _votaciones.where((v) => !v.yaVote && v.estado == 'ABIERTA').length;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Cargar datos (usando ejecutar() de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> cargarAdmin({String? estado}) async {
    final resultado = await ejecutar(
      () => VotacionService.listarAdmin(estado: estado),
    );
    if (resultado != null) {
      _votaciones = resultado;
    }
  }

  Future<void> cargarResidente() async {
    final resultado = await ejecutar(() => VotacionService.listarResidente());
    if (resultado != null) {
      _votaciones = resultado;
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Acciones (usando helpers de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<VotacionModel?> crear(Map<String, dynamic> body) async {
    final nueva = await ejecutar(() => VotacionService.crear(body));
    if (nueva != null) {
      agregarAlInicio(_votaciones, nueva);
    }
    return nueva;
  }

  Future<VotacionModel?> actualizar(int id, Map<String, dynamic> body) async {
    final actualizada = await ejecutar(
      () => VotacionService.actualizar(id, body),
    );
    if (actualizada != null) {
      _reemplazar(actualizada);
    }
    return actualizada;
  }

  Future<VotacionModel?> cambiarEstado(int id, String estado) async {
    final actualizada = await ejecutar(
      () => VotacionService.cambiarEstado(id, estado),
    );
    if (actualizada != null) {
      _reemplazar(actualizada);
    }
    return actualizada;
  }

  Future<VotacionModel?> cargarResultados(int id) async {
    final resultado = await ejecutar(() => VotacionService.resultados(id));
    if (resultado != null) {
      _seleccionada = resultado;
      _reemplazar(resultado);
    }
    return resultado;
  }

  Future<VotacionModel?> cargarDetalle(int id) async {
    final detalle = await ejecutar(
      () => VotacionService.detalleResidente(id),
    );
    if (detalle != null) {
      _seleccionada = detalle;
      notifyListeners();
    }
    return detalle;
  }

  Future<VotacionModel?> votar(int id, Map<String, dynamic> body) async {
    final resultado = await ejecutar(
      () => VotacionService.votar(id, body),
    );
    if (resultado != null) {
      _seleccionada = resultado;
      _reemplazar(resultado);
    }
    return resultado;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Helpers privados
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _reemplazar(VotacionModel v) {
    reemplazar(_votaciones, v, (x) => x.id);
  }
}
