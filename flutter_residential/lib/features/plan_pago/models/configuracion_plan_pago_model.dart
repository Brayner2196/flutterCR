class ConfiguracionPlanPagoModel {
  final int? id;
  final bool activo;
  final int maxCuotas;
  final bool recargoFraccionamiento;
  final double porcentajeRecargo;
  final bool moraCongeladaDurantePlan;
  final bool aprobacionAutomatica;
  final String? actualizadoEn;

  const ConfiguracionPlanPagoModel({
    this.id,
    required this.activo,
    required this.maxCuotas,
    required this.recargoFraccionamiento,
    required this.porcentajeRecargo,
    required this.moraCongeladaDurantePlan,
    required this.aprobacionAutomatica,
    this.actualizadoEn,
  });

  factory ConfiguracionPlanPagoModel.fromJson(Map<String, dynamic> json) =>
      ConfiguracionPlanPagoModel(
        id: json['id'] as int?,
        activo: json['activo'] as bool? ?? false,
        maxCuotas: json['maxCuotas'] as int? ?? 3,
        recargoFraccionamiento: json['recargoFraccionamiento'] as bool? ?? false,
        porcentajeRecargo:
            (json['porcentajeRecargo'] as num? ?? 0).toDouble(),
        moraCongeladaDurantePlan:
            json['moraCongeladaDurantePlan'] as bool? ?? false,
        aprobacionAutomatica: json['aprobacionAutomatica'] as bool? ?? false,
        actualizadoEn: json['actualizadoEn'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'activo': activo,
        'maxCuotas': maxCuotas,
        'recargoFraccionamiento': recargoFraccionamiento,
        'porcentajeRecargo': porcentajeRecargo,
        'moraCongeladaDurantePlan': moraCongeladaDurantePlan,
        'aprobacionAutomatica': aprobacionAutomatica,
      };

  ConfiguracionPlanPagoModel copyWith({
    bool? activo,
    int? maxCuotas,
    bool? recargoFraccionamiento,
    double? porcentajeRecargo,
    bool? moraCongeladaDurantePlan,
    bool? aprobacionAutomatica,
  }) =>
      ConfiguracionPlanPagoModel(
        id: id,
        activo: activo ?? this.activo,
        maxCuotas: maxCuotas ?? this.maxCuotas,
        recargoFraccionamiento:
            recargoFraccionamiento ?? this.recargoFraccionamiento,
        porcentajeRecargo: porcentajeRecargo ?? this.porcentajeRecargo,
        moraCongeladaDurantePlan:
            moraCongeladaDurantePlan ?? this.moraCongeladaDurantePlan,
        aprobacionAutomatica: aprobacionAutomatica ?? this.aprobacionAutomatica,
        actualizadoEn: actualizadoEn,
      );

  /// Configuración por defecto (módulo desactivado)
  static const defaultConfig = ConfiguracionPlanPagoModel(
    activo: false,
    maxCuotas: 3,
    recargoFraccionamiento: false,
    porcentajeRecargo: 0,
    moraCongeladaDurantePlan: false,
    aprobacionAutomatica: false,
  );
}
