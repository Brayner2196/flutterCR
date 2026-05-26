import 'cuota_plan_model.dart';

class PlanPagoModel {
  final int id;
  final int propiedadId;
  final int residenteId;
  final String residenteNombre;
  final String propiedadIdentificador;
  final double montoTotalDeuda;
  final int numeroCuotas;
  final double montoRecargo;
  final double montoTotalPlan;
  final String estado; // PENDIENTE | ACTIVO | RECHAZADO | COMPLETADO | CANCELADO
  final String? cobrosIncluidos;
  final String? observaciones;
  final String? motivoRechazo;
  final String? notaAdmin;
  final String? fechaDecision;
  final String creadoEn;
  final List<CuotaPlanModel> cuotas;

  const PlanPagoModel({
    required this.id,
    required this.propiedadId,
    required this.residenteId,
    required this.residenteNombre,
    required this.propiedadIdentificador,
    required this.montoTotalDeuda,
    required this.numeroCuotas,
    required this.montoRecargo,
    required this.montoTotalPlan,
    required this.estado,
    this.cobrosIncluidos,
    this.observaciones,
    this.motivoRechazo,
    this.notaAdmin,
    this.fechaDecision,
    required this.creadoEn,
    this.cuotas = const [],
  });

  factory PlanPagoModel.fromJson(Map<String, dynamic> json) => PlanPagoModel(
        id: json['id'] as int,
        propiedadId: json['propiedadId'] as int? ?? 0,
        residenteId: json['residenteId'] as int,
        residenteNombre: json['residenteNombre'] as String? ?? 'N/A',
        propiedadIdentificador:
            json['propiedadIdentificador'] as String? ?? 'N/A',
        montoTotalDeuda: (json['montoTotalDeuda'] as num).toDouble(),
        numeroCuotas: json['numeroCuotas'] as int,
        montoRecargo: (json['montoRecargo'] as num? ?? 0).toDouble(),
        montoTotalPlan: (json['montoTotalPlan'] as num).toDouble(),
        estado: json['estado'] as String,
        cobrosIncluidos: json['cobrosIncluidos'] as String?,
        observaciones: json['observaciones'] as String?,
        motivoRechazo: json['motivoRechazo'] as String?,
        notaAdmin: json['notaAdmin'] as String?,
        fechaDecision: json['fechaDecision'] as String?,
        creadoEn: json['creadoEn'] as String? ?? '',
        cuotas: (json['cuotas'] as List<dynamic>? ?? [])
            .map((e) => CuotaPlanModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // ── Getters de utilidad ──────────────────────────────────────────

  bool get esPendiente => estado == 'PENDIENTE';
  bool get esActivo => estado == 'ACTIVO';
  bool get esRechazado => estado == 'RECHAZADO';
  bool get esCompletado => estado == 'COMPLETADO';
  bool get esCancelado => estado == 'CANCELADO';

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
      default:
        return estado;
    }
  }

  int get cuotasPagadas => cuotas.where((c) => c.esPagada).length;
  int get cuotasPendientes => cuotas.where((c) => c.esPendiente).length;
  double get montoPagado =>
      cuotas.where((c) => c.esPagada).fold(0, (s, c) => s + c.monto);
  double get montoPendiente => montoTotalPlan - montoPagado;
}
