import 'cobro_acuerdo_model.dart';

/// Acuerdo de pago. Los saldos salen de los cobros que generó, no de campos
/// propios: la deuda vive en `cobros` y el acuerdo solo guarda las condiciones.
class PlanPagoModel {
  final int id;
  final int propiedadId;
  final int residenteId;
  final String residenteNombre;
  final String propiedadIdentificador;

  // Montos
  final double montoTotalDeuda;
  final double porcentajeRecargo;
  final double montoRecargo;
  final double montoTotalPlan;

  // Abono inicial
  final double porcentajeAbonoInicial;
  final String baseCalculoAbono;
  final double montoAbonoInicial;
  final int diasGraciaInicial;
  final String? fechaLimiteInicial;
  final int? cobroInicialId;
  final bool abonoInicialPagado;

  // Diferido
  final double montoDiferido;
  final int numeroCuotas;

  // Seguimiento
  final String estado;
  final double montoPagadoAcuerdo;
  final double saldoPendienteAcuerdo;
  final int cuotasPagadas;

  final String? cobrosIncluidos;
  final String? cobrosGenerados;
  final String? observaciones;
  final String? motivoRechazo;
  final String? notaAdmin;
  final String? fechaDecision;
  final String? fechaIncumplimiento;
  final String creadoEn;

  final List<CobroAcuerdoModel> cobros;

  const PlanPagoModel({
    required this.id,
    required this.propiedadId,
    required this.residenteId,
    required this.residenteNombre,
    required this.propiedadIdentificador,
    required this.montoTotalDeuda,
    required this.porcentajeRecargo,
    required this.montoRecargo,
    required this.montoTotalPlan,
    required this.porcentajeAbonoInicial,
    required this.baseCalculoAbono,
    required this.montoAbonoInicial,
    required this.diasGraciaInicial,
    this.fechaLimiteInicial,
    this.cobroInicialId,
    required this.abonoInicialPagado,
    required this.montoDiferido,
    required this.numeroCuotas,
    required this.estado,
    required this.montoPagadoAcuerdo,
    required this.saldoPendienteAcuerdo,
    required this.cuotasPagadas,
    this.cobrosIncluidos,
    this.cobrosGenerados,
    this.observaciones,
    this.motivoRechazo,
    this.notaAdmin,
    this.fechaDecision,
    this.fechaIncumplimiento,
    required this.creadoEn,
    this.cobros = const [],
  });

  factory PlanPagoModel.fromJson(Map<String, dynamic> json) => PlanPagoModel(
        id: json['id'] as int,
        propiedadId: json['propiedadId'] as int? ?? 0,
        residenteId: json['residenteId'] as int? ?? 0,
        residenteNombre: json['residenteNombre'] as String? ?? 'N/A',
        propiedadIdentificador:
            json['propiedadIdentificador'] as String? ?? 'N/A',
        montoTotalDeuda: (json['montoTotalDeuda'] as num? ?? 0).toDouble(),
        porcentajeRecargo: (json['porcentajeRecargo'] as num? ?? 0).toDouble(),
        montoRecargo: (json['montoRecargo'] as num? ?? 0).toDouble(),
        montoTotalPlan: (json['montoTotalPlan'] as num? ?? 0).toDouble(),
        porcentajeAbonoInicial:
            (json['porcentajeAbonoInicial'] as num? ?? 0).toDouble(),
        baseCalculoAbono: json['baseCalculoAbono'] as String? ?? 'DEUDA',
        montoAbonoInicial: (json['montoAbonoInicial'] as num? ?? 0).toDouble(),
        diasGraciaInicial: json['diasGraciaInicial'] as int? ?? 0,
        fechaLimiteInicial: json['fechaLimiteInicial'] as String?,
        cobroInicialId: json['cobroInicialId'] as int?,
        abonoInicialPagado: json['abonoInicialPagado'] as bool? ?? false,
        montoDiferido: (json['montoDiferido'] as num? ?? 0).toDouble(),
        numeroCuotas: json['numeroCuotas'] as int? ?? 0,
        estado: json['estado'] as String? ?? 'PENDIENTE',
        montoPagadoAcuerdo:
            (json['montoPagadoAcuerdo'] as num? ?? 0).toDouble(),
        saldoPendienteAcuerdo:
            (json['saldoPendienteAcuerdo'] as num? ?? 0).toDouble(),
        cuotasPagadas: json['cuotasPagadas'] as int? ?? 0,
        cobrosIncluidos: json['cobrosIncluidos'] as String?,
        cobrosGenerados: json['cobrosGenerados'] as String?,
        observaciones: json['observaciones'] as String?,
        motivoRechazo: json['motivoRechazo'] as String?,
        notaAdmin: json['notaAdmin'] as String?,
        fechaDecision: json['fechaDecision'] as String?,
        fechaIncumplimiento: json['fechaIncumplimiento'] as String?,
        creadoEn: json['creadoEn'] as String? ?? '',
        cobros: (json['cobros'] as List<dynamic>? ?? [])
            .map((e) => CobroAcuerdoModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // ── Estado ───────────────────────────────────────────────────────

  bool get esPendiente => estado == 'PENDIENTE';
  bool get esActivo => estado == 'ACTIVO';
  bool get esRechazado => estado == 'RECHAZADO';
  bool get esCompletado => estado == 'COMPLETADO';
  bool get esCancelado => estado == 'CANCELADO';
  bool get esIncumplido => estado == 'INCUMPLIDO';
  bool get estaVigente => esPendiente || esActivo;

  String get estadoLegible {
    switch (estado) {
      case 'PENDIENTE':
        return 'Pendiente aprobación';
      case 'ACTIVO':
        return 'Activo';
      case 'RECHAZADO':
        return 'Rechazado';
      case 'COMPLETADO':
        return 'Completado';
      case 'CANCELADO':
        return 'Cancelado';
      case 'INCUMPLIDO':
        return 'Incumplido';
      default:
        return estado;
    }
  }

  // ── Derivados de los cobros ──────────────────────────────────────

  /// Cobro del abono inicial, si el acuerdo lo exige.
  CobroAcuerdoModel? get cobroInicial {
    for (final c in cobros) {
      if (c.esAbonoInicial) return c;
    }
    return null;
  }

  List<CobroAcuerdoModel> get cuotasDiferidas =>
      cobros.where((c) => !c.esAbonoInicial).toList();

  /// Cuota o abono que el residente debe pagar ahora: la más próxima sin pagar.
  CobroAcuerdoModel? get proximoPago {
    for (final c in cobros) {
      if (c.sePuedePagar) return c;
    }
    return null;
  }

  bool get tieneCobrosVencidos => cobros.any((c) => c.vencido);

  /// Porcentaje del acuerdo ya cubierto (0..1), para la barra de progreso.
  double get progreso {
    if (montoTotalPlan <= 0) return 0;
    final p = montoPagadoAcuerdo / montoTotalPlan;
    return p.clamp(0, 1).toDouble();
  }

  bool get exigeAbonoInicial => montoAbonoInicial > 0;
}
