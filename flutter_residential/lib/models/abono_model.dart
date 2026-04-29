import 'movimiento_abono_model.dart';

class AbonoModel {
  final int id;
  final int propiedadId;
  final int usuarioId;
  final String usuarioNombre;
  final double montoTotal;
  final String fechaPago;
  final String metodoPago;
  final String? referencia;
  final String? urlComprobante;
  final String? notas;
  final String estado;
  final String? motivoRechazo;
  final String? fechaVerificacion;
  final String creadoEn;
  final List<MovimientoAbonoModel> movimientos;

  const AbonoModel({
    required this.id,
    required this.propiedadId,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.montoTotal,
    required this.fechaPago,
    required this.metodoPago,
    this.referencia,
    this.urlComprobante,
    this.notas,
    required this.estado,
    this.motivoRechazo,
    this.fechaVerificacion,
    required this.creadoEn,
    required this.movimientos,
  });

  factory AbonoModel.fromJson(Map<String, dynamic> json) => AbonoModel(
        id: json['id'] as int,
        propiedadId: json['propiedadId'] as int,
        usuarioId: json['usuarioId'] as int,
        usuarioNombre: json['usuarioNombre'] as String? ?? 'N/A',
        montoTotal: (json['montoTotal'] as num).toDouble(),
        fechaPago: json['fechaPago'] as String,
        metodoPago: json['metodoPago'] as String,
        referencia: json['referencia'] as String?,
        urlComprobante: json['urlComprobante'] as String?,
        notas: json['notas'] as String?,
        estado: json['estado'] as String,
        motivoRechazo: json['motivoRechazo'] as String?,
        fechaVerificacion: json['fechaVerificacion'] as String?,
        creadoEn: json['creadoEn'] as String,
        movimientos: (json['movimientos'] as List? ?? [])
            .map((e) => MovimientoAbonoModel.fromJson(e))
            .toList(),
      );

  bool get esPendiente => estado == 'PENDIENTE_VERIFICACION';
  bool get esVerificado => estado == 'VERIFICADO';
  bool get esRechazado => estado == 'RECHAZADO';
}
