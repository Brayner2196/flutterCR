import '../../../core/providers/base_provider.dart';
import '../models/anuncio_model.dart';
import '../services/anuncio_service.dart';

class AnuncioProvider extends BaseProvider {
  List<AnuncioModel> _anuncios = [];
  List<AnuncioVistaModel> _vistas = [];

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Getters públicos (loading y error heredados de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<AnuncioModel> get anuncios => _anuncios;
  List<AnuncioVistaModel> get vistas => _vistas;
  int get noVistos => _anuncios.where((a) => !a.vistoPorMi).length;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Cargar datos (usando ejecutar() de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> cargarAdmin({String? estado}) async {
    _anuncios = await ejecutar(
      () => AnuncioService.listarAdmin(estado: estado),
    ) ?? [];
  }

  Future<List<AnuncioVistaModel>> cargarVistas(int id) async {
    _vistas = await ejecutar(() => AnuncioService.listarVistas(id)) ?? [];
    notifyListeners();
    return _vistas;
  }

  Future<void> cargarResidente() async {
    _anuncios = await ejecutar(() => AnuncioService.listarResidente()) ?? [];
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Acciones (usando helpers de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<AnuncioModel> crear(Map<String, dynamic> body) async {
    final nuevo = await ejecutar(() => AnuncioService.crear(body));
    if (nuevo == null) throw Exception(error ?? 'Error al crear anuncio');
    agregarAlInicio(_anuncios, nuevo);
    return nuevo;
  }

  Future<AnuncioModel> actualizar(int id, Map<String, dynamic> body) async {
    final actualizado = await ejecutar(
      () => AnuncioService.actualizar(id, body),
    );
    if (actualizado == null) throw Exception(error ?? 'Error al actualizar anuncio');
    _reemplazarOAgregar(actualizado);
    return actualizado;
  }

  Future<AnuncioModel> cambiarEstado(int id, String estado) async {
    final actualizado = await ejecutar(
      () => AnuncioService.cambiarEstado(id, estado),
    );
    if (actualizado == null) throw Exception(error ?? 'Error al cambiar estado');
    _reemplazarOAgregar(actualizado);
    return actualizado;
  }

  /// Renombrado de eliminar() para evitar colisión con BaseProvider.eliminar<T>()
  Future<void> eliminarAnuncio(int id) async {
    await ejecutar(() => AnuncioService.eliminar(id));
    super.eliminar(_anuncios, (a) => a.id == id);
  }

  Future<void> marcarVisto(int id) async {
    try {
      final actualizado = await ejecutar(
        () => AnuncioService.marcarVisto(id),
      );
      if (actualizado != null) _reemplazarOAgregar(actualizado);
    } catch (_) {
      // idempotente: si falla no es crítico
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Helpers privados
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _reemplazarOAgregar(AnuncioModel a) {
    final idx = _anuncios.indexWhere((x) => x.id == a.id);
    if (idx != -1) {
      _anuncios[idx] = a;
    } else {
      _anuncios.add(a);
    }
    notifyListeners();
  }
}
