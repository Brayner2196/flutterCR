/// Cuota diferida dentro de la previsualización.
class CuotaSimuladaModel {
  final int numero;
  final double monto;
  final String fechaVencimiento;

  const CuotaSimuladaModel({
    required this.numero,
    required this.monto,
    required this.fechaVencimiento,
  });

  factory CuotaSimuladaModel.fromJson(Map<String, dynamic> json) =>
      CuotaSimuladaModel(
        numero: json['numero'] as int,
        monto: (json['monto'] as num? ?? 0).toDouble(),
        fechaVencimiento: json['fechaVencimiento'] as String? ?? '',
      );
}

/// Previsualización del acuerdo calculada por el backend.
///
/// La app NO recalcula nada de esto: antes el resumen se calculaba en Flutter y
/// el backend lo volvía a calcular al guardar, o sea dos fórmulas para el mismo
/// número. Aquí solo se pinta lo que llega.
class SimulacionAcuerdoModel {
  final double montoDeuda;
  final int cantidadCobros;

  final bool aplicaRecargo;
  final double porcentajeRecargo;
  final double montoRecargo;
  final double montoTotalAcuerdo;

  final double porcentajeAbonoInicial;
  final String baseCalculoAbono;
  final double montoAbonoInicial;
  final int diasGraciaInicial;
  final String fechaLimiteAbonoInicial;

  final double montoDiferido;
  final int numeroCuotas;
  final double montoPorCuota;
  final List<CuotaSimuladaModel> cuotas;

  final int maxCuotas;
  final bool requiereAprobacion;
  final bool moraCongelada;

  const SimulacionAcuerdoModel({
    required this.montoDeuda,
    required this.cantidadCobros,
    required this.aplicaRecargo,
    required this.porcentajeRecargo,
    required this.montoRecargo,
    required this.montoTotalAcuerdo,
    required this.porcentajeAbonoInicial,
    required this.baseCalculoAbono,
    required this.montoAbonoInicial,
    required this.diasGraciaInicial,
    required this.fechaLimiteAbonoInicial,
    required this.montoDiferido,
    required this.numeroCuotas,
    required this.montoPorCuota,
    required this.cuotas,
    required this.maxCuotas,
    required this.requiereAprobacion,
    required this.moraCongelada,
  });

  factory SimulacionAcuerdoModel.fromJson(Map<String, dynamic> json) =>
      SimulacionAcuerdoModel(
        montoDeuda: (json['montoDeuda'] as num? ?? 0).toDouble(),
        cantidadCobros: json['cantidadCobros'] as int? ?? 0,
        aplicaRecargo: json['aplicaRecargo'] as bool? ?? false,
        porcentajeRecargo: (json['porcentajeRecargo'] as num? ?? 0).toDouble(),
        montoRecargo: (json['montoRecargo'] as num? ?? 0).toDouble(),
        montoTotalAcuerdo: (json['montoTotalAcuerdo'] as num? ?? 0).toDouble(),
        porcentajeAbonoInicial:
            (json['porcentajeAbonoInicial'] as num? ?? 0).toDouble(),
        baseCalculoAbono: json['baseCalculoAbono'] as String? ?? 'DEUDA',
        montoAbonoInicial: (json['montoAbonoInicial'] as num? ?? 0).toDouble(),
        diasGraciaInicial: json['diasGraciaInicial'] as int? ?? 0,
        fechaLimiteAbonoInicial:
            json['fechaLimiteAbonoInicial'] as String? ?? '',
        montoDiferido: (json['montoDiferido'] as num? ?? 0).toDouble(),
        numeroCuotas: json['numeroCuotas'] as int? ?? 0,
        montoPorCuota: (json['montoPorCuota'] as num? ?? 0).toDouble(),
        cuotas: (json['cuotas'] as List<dynamic>? ?? [])
            .map((e) => CuotaSimuladaModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        maxCuotas: json['maxCuotas'] as int? ?? 0,
        requiereAprobacion: json['requiereAprobacion'] as bool? ?? true,
        moraCongelada: json['moraCongelada'] as bool? ?? false,
      );

  /// Relleno para `Skeletonizer` mientras llega la simulación.
  ///
  /// Copia la forma de [base] (si trae recargo, si exige abono inicial) y solo
  /// cambia el número de filas: así el esqueleto ocupa lo mismo que el desglose
  /// real y el contenido de abajo no salta. Los montos son de relleno y nunca
  /// se ven, porque Skeletonizer los tapa.
  factory SimulacionAcuerdoModel.skeleton({
    required int numeroCuotas,
    SimulacionAcuerdoModel? base,
  }) {
    const monto = 1000000.0;
    const fecha = '2026-01-01';
    return SimulacionAcuerdoModel(
      montoDeuda: monto,
      cantidadCobros: base?.cantidadCobros ?? 1,
      aplicaRecargo: base?.aplicaRecargo ?? false,
      porcentajeRecargo: base?.porcentajeRecargo ?? 0,
      montoRecargo: base?.montoRecargo ?? 0,
      montoTotalAcuerdo: monto,
      porcentajeAbonoInicial: base?.porcentajeAbonoInicial ?? 30,
      baseCalculoAbono: base?.baseCalculoAbono ?? 'DEUDA',
      montoAbonoInicial: base?.montoAbonoInicial ?? monto,
      diasGraciaInicial: base?.diasGraciaInicial ?? 5,
      fechaLimiteAbonoInicial: base?.fechaLimiteAbonoInicial ?? fecha,
      montoDiferido: monto,
      numeroCuotas: numeroCuotas,
      montoPorCuota: monto,
      cuotas: List.generate(
        numeroCuotas,
        (i) => CuotaSimuladaModel(
            numero: i + 1, monto: monto, fechaVencimiento: fecha),
      ),
      maxCuotas: base?.maxCuotas ?? numeroCuotas,
      requiereAprobacion: base?.requiereAprobacion ?? true,
      moraCongelada: base?.moraCongelada ?? false,
    );
  }

  bool get exigeAbonoInicial => montoAbonoInicial > 0;
}
