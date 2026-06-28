class VisitaModel {
  final int id;
  final String codigo;
  final String nombreVisitante;
  final String? documento;
  final String? placa;
  final String? motivo;
  final int propiedadId;
  final String? propiedadIdentificador;
  final String estado;
  final String? expiraEn;
  final String? ingresoEn;
  final String? creadoEn;

  const VisitaModel({
    required this.id,
    required this.codigo,
    required this.nombreVisitante,
    this.documento,
    this.placa,
    this.motivo,
    required this.propiedadId,
    this.propiedadIdentificador,
    required this.estado,
    this.expiraEn,
    this.ingresoEn,
    this.creadoEn,
  });

  factory VisitaModel.fromJson(Map<String, dynamic> json) => VisitaModel(
        id: (json['id'] as num).toInt(),
        codigo: json['codigo'] as String? ?? '',
        nombreVisitante: json['nombreVisitante'] as String? ?? '',
        documento: json['documento'] as String?,
        placa: json['placa'] as String?,
        motivo: json['motivo'] as String?,
        propiedadId: (json['propiedadId'] as num).toInt(),
        propiedadIdentificador: json['propiedadIdentificador'] as String?,
        estado: json['estado'] as String? ?? 'PENDIENTE',
        expiraEn: json['expiraEn'] as String?,
        ingresoEn: json['ingresoEn'] as String?,
        creadoEn: json['creadoEn'] as String?,
      );

  bool get esPendiente => estado == 'PENDIENTE';
  bool get esIngreso => estado == 'INGRESO';
  bool get esCancelada => estado == 'CANCELADA';
  bool get esVencida => estado == 'VENCIDA';

  String get estadoLegible => switch (estado) {
        'PENDIENTE' => 'Pendiente',
        'INGRESO' => 'Ingresó',
        'FINALIZADA' => 'Finalizada',
        'VENCIDA' => 'Vencida',
        'CANCELADA' => 'Cancelada',
        _ => estado,
      };
}
