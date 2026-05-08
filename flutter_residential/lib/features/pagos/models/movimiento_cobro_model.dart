/// Representa un movimiento de pago sobre un cobro específico.
/// Puede ser un Pago directo (tipo = PAGO) o un movimiento
/// distribuido desde un Abono (tipo = ABONO).
class MovimientoCobroModel {
  final int id;
  final String tipo;           // "PAGO" | "ABONO"
  final double monto;
  final String estado;         // PENDIENTE_VERIFICACION | VERIFICADO | RECHAZADO
  final String? fecha;
  final String? metodoPago;
  final String? referencia;
  final String? motivoRechazo;
  final String? creadoEn;

  const MovimientoCobroModel({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.estado,
    this.fecha,
    this.metodoPago,
    this.referencia,
    this.motivoRechazo,
    this.creadoEn,
  });

  factory MovimientoCobroModel.fromJson(Map<String, dynamic> json) =>
      MovimientoCobroModel(
        id: json['id'] as int,
        tipo: json['tipo'] as String,
        monto: (json['monto'] as num).toDouble(),
        estado: json['estado'] as String,
        fecha: json['fecha'] as String?,
        metodoPago: json['metodoPago'] as String?,
        referencia: json['referencia'] as String?,
        motivoRechazo: json['motivoRechazo'] as String?,
        creadoEn: json['creadoEn'] as String?,
      );

  bool get esPago => tipo == 'PAGO';
  bool get esAbono => tipo == 'ABONO';
  bool get esPendiente => estado == 'PENDIENTE_VERIFICACION';
  bool get esVerificado => estado == 'VERIFICADO';
  bool get esRechazado => estado == 'RECHAZADO';
}
