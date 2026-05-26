class CuotaPlanModel {
  final int id;
  final int planId;
  final int numeroCuota;
  final double monto;
  final String fechaVencimiento;
  final String estado; // PENDIENTE | PAGADA | VENCIDA
  final String? fechaPago;
  final String? notaPago;
  final bool vencida;

  const CuotaPlanModel({
    required this.id,
    required this.planId,
    required this.numeroCuota,
    required this.monto,
    required this.fechaVencimiento,
    required this.estado,
    this.fechaPago,
    this.notaPago,
    required this.vencida,
  });

  factory CuotaPlanModel.fromJson(Map<String, dynamic> json) => CuotaPlanModel(
        id: json['id'] as int,
        planId: json['planId'] as int,
        numeroCuota: json['numeroCuota'] as int,
        monto: (json['monto'] as num).toDouble(),
        fechaVencimiento: json['fechaVencimiento'] as String,
        estado: json['estado'] as String,
        fechaPago: json['fechaPago'] as String?,
        notaPago: json['notaPago'] as String?,
        vencida: json['vencida'] as bool? ?? false,
      );

  bool get esPendiente => estado == 'PENDIENTE';
  bool get esPagada => estado == 'PAGADA';
}
