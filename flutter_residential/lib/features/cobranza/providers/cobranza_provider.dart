import '../../../core/providers/base_provider.dart';
import '../../cartera/models/estado_cartera_config_model.dart';
import '../../cartera/services/cartera_config_service.dart';
import '../../pagos/models/aviso_cobranza_resultado.dart';
import '../../pagos/services/gestion_cartera_service.dart';
import '../models/aviso_lote_resumen.dart';
import '../models/cobro_cobranza_model.dart';
import '../services/cobranza_service.dart';
import '../utils/agrupador_cobranza.dart';

/// Estado del módulo de cobranza.
///
/// Deliberadamente separado de `CobrosProvider`. Las dos pestañas del hub viven
/// a la vez dentro del `IndexedStack` y las dos escuchan a su provider; cuando
/// compartían la misma lista `_cobros`, entrar a Cobranza reescribía los cobros
/// del mes que Cobros tenía en pantalla y viceversa. Con estado propio cada una
/// manda sobre lo suyo, incluido su `loading`.
class CobranzaProvider extends BaseProvider {
  // ── Datos ────────────────────────────────────────────────────────────
  List<CobroCobranzaModel> _cobros = [];
  List<GrupoMesCobranza> _grupos = [];
  List<EstadoCarteraConfig> _fases = [];

  // ── Filtros ──────────────────────────────────────────────────────────
  /// Clave del mes ('2026-09'). Null = todos los meses.
  String? _mes;

  /// Código de la fase de cartera. Null = todas.
  String? _fase;

  /// VENCIDO | POR_VENCER | MORA | CRITICO. Null = sin filtro.
  String? _urgencia;

  /// Ventana de meses hacia atrás que se pide al backend.
  int _mesesVentana = 12;

  // ── Selección múltiple ───────────────────────────────────────────────
  final Set<int> _seleccion = {};
  bool _enviando = false;

  /// Días vencidos a partir de los cuales un cobro se considera crítico.
  static const int diasCritico = 30;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Getters
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<CobroCobranzaModel> get cobros => _cobros;
  List<GrupoMesCobranza> get grupos => _grupos;
  List<EstadoCarteraConfig> get fases => _fases;
  String? get mes => _mes;
  String? get fase => _fase;
  String? get urgencia => _urgencia;
  int get mesesVentana => _mesesVentana;
  bool get enviando => _enviando;
  Set<int> get seleccion => _seleccion;
  bool get haySeleccion => _seleccion.isNotEmpty;

  /// Cobros del mes y la fase activos, antes del filtro de urgencia. Es la base
  /// sobre la que se cuentan las métricas, para que al tocar una tarjeta del
  /// grid los demás contadores no se vayan a cero.
  List<CobroCobranzaModel> get _delContexto => _cobros.where((c) {
        if (_mes != null &&
            AgrupadorCobranza.clave(c.anioAgrupacion, c.mesAgrupacion) != _mes) {
          return false;
        }
        if (_fase != null && c.faseCodigo != _fase) return false;
        return true;
      }).toList();

  /// Lo que finalmente se lista.
  List<CobroCobranzaModel> get visibles {
    final base = _delContexto;
    switch (_urgencia) {
      case 'VENCIDO':
        return base.where((c) => c.vencido).toList();
      case 'POR_VENCER':
        return base.where((c) => c.porVencer).toList();
      case 'MORA':
        return base.where((c) => c.enMora).toList();
      case 'CRITICO':
        return base.where((c) => c.diasVencido >= diasCritico).toList();
      default:
        return base;
    }
  }

  /// Visibles agrupadas por mes (la lista se pinta con encabezado por mes).
  List<GrupoMesCobranza> get gruposVisibles => AgrupadorCobranza.porMes(visibles);

  /// Conteos del grid de métricas.
  Map<String, int> get metricas {
    final base = _delContexto;
    return {
      'POR_VENCER': base.where((c) => c.porVencer).length,
      'VENCIDO': base.where((c) => c.vencido).length,
      'MORA': base.where((c) => c.enMora).length,
      'CRITICO': base.where((c) => c.diasVencido >= diasCritico).length,
    };
  }

  double get totalDeuda =>
      _delContexto.fold<double>(0, (s, c) => s + c.montoPendiente);
  double get totalMora =>
      _delContexto.fold<double>(0, (s, c) => s + c.montoMora);
  int get propiedadesMorosas =>
      _delContexto.map((c) => c.propiedadId).toSet().length;

  /// Conteo de morosos por fase, para los chips.
  Map<String, int> get conteoPorFase {
    final counts = <String, int>{};
    for (final c in _cobros) {
      if (_mes != null &&
          AgrupadorCobranza.clave(c.anioAgrupacion, c.mesAgrupacion) != _mes) {
        continue;
      }
      final codigo = c.faseCodigo;
      if (codigo == null) continue;
      counts[codigo] = (counts[codigo] ?? 0) + 1;
    }
    return counts;
  }

  /// Propiedades distintas de la selección: a cada una le llega un solo aviso
  /// aunque se hayan marcado varios de sus cobros.
  List<int> get propiedadesSeleccionadas => _cobros
      .where((c) => _seleccion.contains(c.cobroId))
      .map((c) => c.propiedadId)
      .toSet()
      .toList();

  bool estaSeleccionado(int cobroId) => _seleccion.contains(cobroId);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Carga
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> cargar({int? meses}) async {
    if (meses != null) _mesesVentana = meses;
    final datos = await ejecutar(
      () => CobranzaService.listar(meses: _mesesVentana),
    );
    _cobros = datos ?? [];
    _grupos = AgrupadorCobranza.porMes(_cobros);
    _seleccion.removeWhere(
      (id) => !_cobros.any((c) => c.cobroId == id),
    );
    // Si el mes filtrado se quedó sin deuda (se pagó todo), vuelve a "Todos"
    // en vez de dejar la pantalla vacía sin explicación.
    if (_mes != null && !_grupos.any((g) => g.clave == _mes)) _mes = null;
    notifyListeners();
  }

  /// Fases de cartera negativas, de la más severa a la menos. Degradación
  /// segura: si el conjunto no tiene cartera configurada, la pantalla funciona
  /// igual, solo sin chips ni aviso por fase.
  Future<void> cargarFases() async {
    try {
      final fases = await CarteraConfigService.listar();
      _fases = fases.where((f) => f.activo && !f.esPositivo).toList()
        ..sort((a, b) => b.severidad.compareTo(a.severidad));
      notifyListeners();
    } catch (_) {
      _fases = [];
    }
  }

  String nombreFase(String codigo) =>
      _fases.where((f) => f.codigo == codigo).firstOrNull?.nombre ?? codigo;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Filtros
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Cambiar de mes o de fase limpia la selección a propósito: dejar marcados
  /// cobros que ya no se ven y enviarles el aviso es el peor error posible acá.
  void seleccionarMes(String? clave) {
    if (_mes == clave) return;
    _mes = clave;
    _seleccion.clear();
    notifyListeners();
  }

  void seleccionarFase(String? codigo) {
    if (_fase == codigo) return;
    _fase = codigo;
    _seleccion.clear();
    notifyListeners();
  }

  void seleccionarUrgencia(String? codigo) {
    _urgencia = _urgencia == codigo ? null : codigo;
    notifyListeners();
  }

  void limpiarFiltros() {
    _mes = null;
    _fase = null;
    _urgencia = null;
    _seleccion.clear();
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Selección
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void alternar(int cobroId) {
    if (!_seleccion.remove(cobroId)) _seleccion.add(cobroId);
    notifyListeners();
  }

  /// Marca (o desmarca, si ya estaban todos) los cobros indicados.
  void alternarVarios(List<int> cobroIds) {
    final todos = cobroIds.every(_seleccion.contains);
    if (todos) {
      _seleccion.removeAll(cobroIds);
    } else {
      _seleccion.addAll(cobroIds);
    }
    notifyListeners();
  }

  void limpiarSeleccion() {
    if (_seleccion.isEmpty) return;
    _seleccion.clear();
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Avisos
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //
  // No usan `ejecutar()` a propósito: ese helper enciende el `loading` general
  // y la lista entera se iría a esqueleto por enviar un aviso. Devuelven el
  // resumen o null, y en null el motivo queda en [error] — el llamador tiene
  // que mirarlo, un try/catch alrededor nunca se dispara.

  Future<AvisoLoteResumen?> avisarPropiedad(int propiedadId, {String? mensaje}) =>
      _enviar(() async => [
            await GestionCarteraService.notificarPropiedad(propiedadId, mensaje: mensaje)
          ]);

  Future<AvisoLoteResumen?> avisarSeleccion({String? mensaje}) {
    final propiedades = propiedadesSeleccionadas;
    if (propiedades.isEmpty) {
      setError('No hay propiedades seleccionadas');
      return Future.value(null);
    }
    return _enviar(
      () => CobranzaService.notificarLote(propiedades, mensaje: mensaje),
      limpiarSeleccionAlTerminar: true,
    );
  }

  Future<AvisoLoteResumen?> avisarPorFase(int faseId, {String? mensaje}) => _enviar(
        () => GestionCarteraService.notificarMasivoPorEstado(faseId, mensaje: mensaje),
      );

  Future<AvisoLoteResumen?> _enviar(
    Future<List<AvisoCobranzaResultado>> Function() operacion, {
    bool limpiarSeleccionAlTerminar = false,
  }) async {
    if (_enviando) return null;
    _enviando = true;
    limpiarError();
    notifyListeners();
    try {
      final resultados = await operacion();
      if (limpiarSeleccionAlTerminar) _seleccion.clear();
      return AvisoLoteResumen.de(resultados);
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
      return null;
    } finally {
      _enviando = false;
      notifyListeners();
    }
  }

  void limpiarDatos() {
    _cobros = [];
    _grupos = [];
    _fases = [];
    _seleccion.clear();
    _mes = null;
    _fase = null;
    _urgencia = null;
    limpiarError();
    notifyListeners();
  }
}
