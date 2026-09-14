import '../../pagos/utils/concepto_cobro_ui.dart';

/// Una fila del módulo de cobranza: un cobro que sigue debiéndose.
///
/// No reutiliza `CobroModel` porque son cosas distintas: aquel describe lo que
/// se facturó (incluye pagados y exonerados), este describe deuda viva y trae
/// además los días de vencimiento y la fase de cartera ya resueltos por el
/// backend. El endpoint que lo alimenta nunca devuelve EXONERADO ni PAGADO.
class CobroCobranzaModel {
  final int cobroId;
  final int? periodoId;
  final int? anio;
  final int? mes;
  final int propiedadId;
  final String propiedadIdentificador;
  final String propiedadPathCorto;
  final String concepto;
  final String? descripcion;
  final DateTime? fechaLimitePago;

  /// Días transcurridos desde la fecha límite. 0 si aún no vence.
  final int diasVencido;

  /// Días que faltan para la fecha límite. 0 si ya venció.
  final int diasParaVencer;

  final double montoPendiente;
  final double montoMora;
  final double montoTotal;
  final String estado;

  final String? faseCodigo;
  final String? faseNombre;
  final String? faseColor;

  /// SISTEMA o MIGRADO (cartera del sistema contable anterior).
  final String? origen;

  const CobroCobranzaModel({
    required this.cobroId,
    this.periodoId,
    this.anio,
    this.mes,
    required this.propiedadId,
    required this.propiedadIdentificador,
    required this.propiedadPathCorto,
    required this.concepto,
    this.descripcion,
    this.fechaLimitePago,
    required this.diasVencido,
    required this.diasParaVencer,
    required this.montoPendiente,
    required this.montoMora,
    required this.montoTotal,
    required this.estado,
    this.faseCodigo,
    this.faseNombre,
    this.faseColor,
    this.origen,
  });

  factory CobroCobranzaModel.fromJson(Map<String, dynamic> j) => CobroCobranzaModel(
        cobroId: j['cobroId'] as int,
        periodoId: j['periodoId'] as int?,
        anio: j['anio'] as int?,
        mes: j['mes'] as int?,
        propiedadId: j['propiedadId'] as int,
        propiedadIdentificador: j['propiedadIdentificador'] as String? ?? '',
        propiedadPathCorto: j['propiedadPathCorto'] as String? ?? '',
        concepto: j['concepto'] as String? ?? 'OTRO',
        descripcion: j['descripcion'] as String?,
        fechaLimitePago: DateTime.tryParse(j['fechaLimitePago'] as String? ?? ''),
        diasVencido: j['diasVencido'] as int? ?? 0,
        diasParaVencer: j['diasParaVencer'] as int? ?? 0,
        montoPendiente: (j['montoPendiente'] as num? ?? 0).toDouble(),
        montoMora: (j['montoMora'] as num? ?? 0).toDouble(),
        montoTotal: (j['montoTotal'] as num? ?? 0).toDouble(),
        estado: j['estado'] as String? ?? 'PENDIENTE',
        faseCodigo: j['estadoCarteraCodigo'] as String?,
        faseNombre: j['estadoCarteraNombre'] as String?,
        faseColor: j['estadoCarteraColor'] as String?,
        origen: j['origen'] as String?,
      );

  // ── Lógica derivada (aquí y no en la UI: la usan la tarjeta, las métricas
  //    y el agrupador, y así el criterio es uno solo) ─────────────────────

  bool get vencido => diasVencido > 0;
  bool get porVencer => !vencido;
  bool get enMora => montoMora > 0;
  bool get venceHoy => diasVencido == 0 && diasParaVencer == 0;
  bool get migrado => origen == 'MIGRADO';
  bool get tieneFase => faseNombre != null && faseNombre!.isNotEmpty;

  String get conceptoLabel => ConceptoCobroUi.label(concepto);

  /// Mes al que se imputa el cobro en la lista: el del período si lo tiene y,
  /// para los cobros especiales (multas, zonas comunes, que no tienen período),
  /// el de su fecha límite — que es la fecha por la que se cobran.
  int get anioAgrupacion => anio ?? fechaLimitePago?.year ?? 0;
  int get mesAgrupacion => mes ?? fechaLimitePago?.month ?? 0;

  /// Texto corto de estado temporal para la tarjeta.
  String get etiquetaVencimiento {
    if (venceHoy) return 'Vence hoy';
    if (vencido) {
      return diasVencido == 1 ? 'Vencido hace 1 día' : 'Vencido hace $diasVencido días';
    }
    return diasParaVencer == 1 ? 'Vence mañana' : 'Vence en $diasParaVencer días';
  }

  String get fechaLimiteCorta {
    final f = fechaLimitePago;
    if (f == null) return 'Sin fecha';
    return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
  }
}
