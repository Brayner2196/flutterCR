import '../../../core/providers/base_provider.dart';
import '../models/auditoria_model.dart';
import '../services/auditoria_service.dart';

/// Bandeja de auditoría financiera del administrador, con scroll infinito.
///
/// Acumula páginas en vez de reemplazarlas: la lista puede tener miles de filas
/// y el admin normalmente busca algo puntual bajando desde lo más reciente.
class AuditoriaProvider extends BaseProvider {
  final List<RegistroAuditoria> _registros = [];
  FiltroAuditoria _filtro = const FiltroAuditoria();
  List<String> _entidades = [];
  List<String> _acciones = [];

  int _pagina = 0;
  bool _hayMas = true;
  bool _cargandoMas = false;

  List<RegistroAuditoria> get registros => List.unmodifiable(_registros);
  FiltroAuditoria get filtro => _filtro;
  List<String> get entidades => _entidades;
  List<String> get acciones => _acciones;
  bool get hayMas => _hayMas;
  bool get cargandoMas => _cargandoMas;
  bool get vacio => _registros.isEmpty && !loading;

  /// Carga los valores de los desplegables. Se llama una vez al abrir.
  Future<void> cargarFiltros() async {
    final r = await ejecutar(() => AuditoriaService.filtros());
    if (r != null) {
      _entidades = r.entidades;
      _acciones = r.acciones;
      notifyListeners();
    }
  }

  /// Primera página con el filtro actual. Reinicia la lista.
  Future<void> cargar() async {
    _pagina = 0;
    _hayMas = true;
    _registros.clear();
    notifyListeners();
    await _traerPagina();
  }

  /// Siguiente página. No hace nada si ya se está trayendo una o si no quedan.
  Future<void> cargarMas() async {
    if (_cargandoMas || !_hayMas) return;
    _cargandoMas = true;
    notifyListeners();
    _pagina++;
    await _traerPagina();
    _cargandoMas = false;
    notifyListeners();
  }

  Future<void> aplicarFiltro(FiltroAuditoria nuevo) async {
    _filtro = nuevo;
    await cargar();
  }

  Future<void> limpiarFiltro() async {
    _filtro = const FiltroAuditoria();
    await cargar();
  }

  Future<void> _traerPagina() async {
    final r = await ejecutar(
        () => AuditoriaService.buscar(filtro: _filtro, page: _pagina));
    if (r == null) {
      _hayMas = false;
      return;
    }
    _registros.addAll(r.filas);
    _hayMas = r.hayMas;
    notifyListeners();
  }

  void limpiarDatos() {
    _registros.clear();
    _filtro = const FiltroAuditoria();
    _pagina = 0;
    _hayMas = true;
    limpiarError();
    setLoading(false);
    notifyListeners();
  }
}
