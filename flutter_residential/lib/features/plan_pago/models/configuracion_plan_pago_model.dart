/// Parametrización del módulo de acuerdos de pago.
///
/// Las condiciones de elegibilidad son pares toggle + valor, igual que en el
/// backend: el valor solo se evalúa si su toggle está encendido.
class ConfiguracionPlanPagoModel {
  final int? id;
  final bool activo;
  final int maxCuotas;

  // ── Abono inicial ───────────────────────────────────────────────
  final double porcentajeAbonoInicial;
  final int diasGraciaInicial;

  /// DEUDA | DEUDA_MAS_RECARGO
  final String baseCalculoAbono;

  // ── Recargo por fraccionar ──────────────────────────────────────
  final bool recargoFraccionamiento;
  final double porcentajeRecargo;

  // ── Comportamiento ──────────────────────────────────────────────
  final bool moraCongeladaDurantePlan;
  final bool aprobacionAutomatica;

  // ── Condiciones de elegibilidad ─────────────────────────────────
  final bool exigeDeudaMinima;
  final double montoDeudaMinima;
  final bool exigeMoraMinima;
  final int diasMoraMinima;
  final bool bloqueaConAcuerdoVigente;
  final bool bloqueaTrasIncumplimiento;
  final int diasEsperaTrasIncumplimiento;
  final bool limitaAcuerdosPorAnio;
  final int maxAcuerdosPorAnio;
  final bool restringeConceptos;
  final List<String> conceptosElegibles;

  final String? actualizadoEn;

  const ConfiguracionPlanPagoModel({
    this.id,
    required this.activo,
    required this.maxCuotas,
    required this.porcentajeAbonoInicial,
    required this.diasGraciaInicial,
    required this.baseCalculoAbono,
    required this.recargoFraccionamiento,
    required this.porcentajeRecargo,
    required this.moraCongeladaDurantePlan,
    required this.aprobacionAutomatica,
    required this.exigeDeudaMinima,
    required this.montoDeudaMinima,
    required this.exigeMoraMinima,
    required this.diasMoraMinima,
    required this.bloqueaConAcuerdoVigente,
    required this.bloqueaTrasIncumplimiento,
    required this.diasEsperaTrasIncumplimiento,
    required this.limitaAcuerdosPorAnio,
    required this.maxAcuerdosPorAnio,
    required this.restringeConceptos,
    required this.conceptosElegibles,
    this.actualizadoEn,
  });

  factory ConfiguracionPlanPagoModel.fromJson(Map<String, dynamic> json) =>
      ConfiguracionPlanPagoModel(
        id: json['id'] as int?,
        activo: json['activo'] as bool? ?? false,
        maxCuotas: json['maxCuotas'] as int? ?? 3,
        porcentajeAbonoInicial:
            (json['porcentajeAbonoInicial'] as num? ?? 0).toDouble(),
        diasGraciaInicial: json['diasGraciaInicial'] as int? ?? 0,
        baseCalculoAbono: json['baseCalculoAbono'] as String? ?? 'DEUDA',
        recargoFraccionamiento: json['recargoFraccionamiento'] as bool? ?? false,
        porcentajeRecargo: (json['porcentajeRecargo'] as num? ?? 0).toDouble(),
        moraCongeladaDurantePlan:
            json['moraCongeladaDurantePlan'] as bool? ?? false,
        aprobacionAutomatica: json['aprobacionAutomatica'] as bool? ?? false,
        exigeDeudaMinima: json['exigeDeudaMinima'] as bool? ?? false,
        montoDeudaMinima: (json['montoDeudaMinima'] as num? ?? 0).toDouble(),
        exigeMoraMinima: json['exigeMoraMinima'] as bool? ?? false,
        diasMoraMinima: json['diasMoraMinima'] as int? ?? 0,
        bloqueaConAcuerdoVigente:
            json['bloqueaConAcuerdoVigente'] as bool? ?? true,
        bloqueaTrasIncumplimiento:
            json['bloqueaTrasIncumplimiento'] as bool? ?? false,
        diasEsperaTrasIncumplimiento:
            json['diasEsperaTrasIncumplimiento'] as int? ?? 0,
        limitaAcuerdosPorAnio: json['limitaAcuerdosPorAnio'] as bool? ?? false,
        maxAcuerdosPorAnio: json['maxAcuerdosPorAnio'] as int? ?? 1,
        restringeConceptos: json['restringeConceptos'] as bool? ?? false,
        conceptosElegibles: (json['conceptosElegibles'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        actualizadoEn: json['actualizadoEn'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'activo': activo,
        'maxCuotas': maxCuotas,
        'porcentajeAbonoInicial': porcentajeAbonoInicial,
        'diasGraciaInicial': diasGraciaInicial,
        'baseCalculoAbono': baseCalculoAbono,
        'recargoFraccionamiento': recargoFraccionamiento,
        'porcentajeRecargo': porcentajeRecargo,
        'moraCongeladaDurantePlan': moraCongeladaDurantePlan,
        'aprobacionAutomatica': aprobacionAutomatica,
        'exigeDeudaMinima': exigeDeudaMinima,
        'montoDeudaMinima': montoDeudaMinima,
        'exigeMoraMinima': exigeMoraMinima,
        'diasMoraMinima': diasMoraMinima,
        'bloqueaConAcuerdoVigente': bloqueaConAcuerdoVigente,
        'bloqueaTrasIncumplimiento': bloqueaTrasIncumplimiento,
        'diasEsperaTrasIncumplimiento': diasEsperaTrasIncumplimiento,
        'limitaAcuerdosPorAnio': limitaAcuerdosPorAnio,
        'maxAcuerdosPorAnio': maxAcuerdosPorAnio,
        'restringeConceptos': restringeConceptos,
        'conceptosElegibles': conceptosElegibles,
      };

  ConfiguracionPlanPagoModel copyWith({
    bool? activo,
    int? maxCuotas,
    double? porcentajeAbonoInicial,
    int? diasGraciaInicial,
    String? baseCalculoAbono,
    bool? recargoFraccionamiento,
    double? porcentajeRecargo,
    bool? moraCongeladaDurantePlan,
    bool? aprobacionAutomatica,
    bool? exigeDeudaMinima,
    double? montoDeudaMinima,
    bool? exigeMoraMinima,
    int? diasMoraMinima,
    bool? bloqueaConAcuerdoVigente,
    bool? bloqueaTrasIncumplimiento,
    int? diasEsperaTrasIncumplimiento,
    bool? limitaAcuerdosPorAnio,
    int? maxAcuerdosPorAnio,
    bool? restringeConceptos,
    List<String>? conceptosElegibles,
  }) =>
      ConfiguracionPlanPagoModel(
        id: id,
        activo: activo ?? this.activo,
        maxCuotas: maxCuotas ?? this.maxCuotas,
        porcentajeAbonoInicial:
            porcentajeAbonoInicial ?? this.porcentajeAbonoInicial,
        diasGraciaInicial: diasGraciaInicial ?? this.diasGraciaInicial,
        baseCalculoAbono: baseCalculoAbono ?? this.baseCalculoAbono,
        recargoFraccionamiento:
            recargoFraccionamiento ?? this.recargoFraccionamiento,
        porcentajeRecargo: porcentajeRecargo ?? this.porcentajeRecargo,
        moraCongeladaDurantePlan:
            moraCongeladaDurantePlan ?? this.moraCongeladaDurantePlan,
        aprobacionAutomatica: aprobacionAutomatica ?? this.aprobacionAutomatica,
        exigeDeudaMinima: exigeDeudaMinima ?? this.exigeDeudaMinima,
        montoDeudaMinima: montoDeudaMinima ?? this.montoDeudaMinima,
        exigeMoraMinima: exigeMoraMinima ?? this.exigeMoraMinima,
        diasMoraMinima: diasMoraMinima ?? this.diasMoraMinima,
        bloqueaConAcuerdoVigente:
            bloqueaConAcuerdoVigente ?? this.bloqueaConAcuerdoVigente,
        bloqueaTrasIncumplimiento:
            bloqueaTrasIncumplimiento ?? this.bloqueaTrasIncumplimiento,
        diasEsperaTrasIncumplimiento:
            diasEsperaTrasIncumplimiento ?? this.diasEsperaTrasIncumplimiento,
        limitaAcuerdosPorAnio:
            limitaAcuerdosPorAnio ?? this.limitaAcuerdosPorAnio,
        maxAcuerdosPorAnio: maxAcuerdosPorAnio ?? this.maxAcuerdosPorAnio,
        restringeConceptos: restringeConceptos ?? this.restringeConceptos,
        conceptosElegibles: conceptosElegibles ?? this.conceptosElegibles,
        actualizadoEn: actualizadoEn,
      );

  /// true si el conjunto exige abono inicial para celebrar el acuerdo.
  bool get exigeAbonoInicial => porcentajeAbonoInicial > 0;

  /// Texto de la base de cálculo, para mostrarlo sin repetir el switch.
  String get baseCalculoLegible => baseCalculoAbono == 'DEUDA_MAS_RECARGO'
      ? 'Deuda + recargo'
      : 'Solo la deuda';

  /// Configuración por defecto (módulo desactivado).
  static const defaultConfig = ConfiguracionPlanPagoModel(
    activo: false,
    maxCuotas: 3,
    porcentajeAbonoInicial: 0,
    diasGraciaInicial: 0,
    baseCalculoAbono: 'DEUDA',
    recargoFraccionamiento: false,
    porcentajeRecargo: 0,
    moraCongeladaDurantePlan: false,
    aprobacionAutomatica: false,
    exigeDeudaMinima: false,
    montoDeudaMinima: 0,
    exigeMoraMinima: false,
    diasMoraMinima: 0,
    bloqueaConAcuerdoVigente: true,
    bloqueaTrasIncumplimiento: false,
    diasEsperaTrasIncumplimiento: 0,
    limitaAcuerdosPorAnio: false,
    maxAcuerdosPorAnio: 1,
    restringeConceptos: false,
    conceptosElegibles: [],
  );
}
