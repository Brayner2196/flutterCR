class BitacoraAccesoModel {
  final int id;
  final String tipoEvento;
  final String resultado;
  final String? descripcion;
  final int? propiedadId;
  final String? propiedadIdentificador;
  final String? placa;
  final String? documento;
  final String? nombreVisitante;
  final int? vigilanteId;
  final String? creadoEn;

  const BitacoraAccesoModel({
    required this.id,
    required this.tipoEvento,
    required this.resultado,
    this.descripcion,
    this.propiedadId,
    this.propiedadIdentificador,
    this.placa,
    this.documento,
    this.nombreVisitante,
    this.vigilanteId,
    this.creadoEn,
  });

  factory BitacoraAccesoModel.fromJson(Map<String, dynamic> json) =>
      BitacoraAccesoModel(
        id: (json['id'] as num).toInt(),
        tipoEvento: json['tipoEvento'] as String? ?? '',
        resultado: json['resultado'] as String? ?? '',
        descripcion: json['descripcion'] as String?,
        propiedadId: (json['propiedadId'] as num?)?.toInt(),
        propiedadIdentificador: json['propiedadIdentificador'] as String?,
        placa: json['placa'] as String?,
        documento: json['documento'] as String?,
        nombreVisitante: json['nombreVisitante'] as String?,
        vigilanteId: (json['vigilanteId'] as num?)?.toInt(),
        creadoEn: json['creadoEn'] as String?,
      );

  bool get esPermitido => resultado == 'PERMITIDO';
  bool get esDenegado => resultado == 'DENEGADO';

  String get tipoLegible => switch (tipoEvento) {
        'ACCESO_VEHICULAR' => 'Acceso vehicular',
        'ACCESO_PEATONAL' => 'Acceso peatonal',
        'VISITA_VALIDADA' => 'Visita',
        'PAQUETE_RECIBIDO' => 'Paquete recibido',
        'PAQUETE_ENTREGADO' => 'Paquete entregado',
        _ => tipoEvento,
      };
}
