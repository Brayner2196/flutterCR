class PaqueteModel {
  final int id;
  final int propiedadId;
  final String? propiedadIdentificador;
  final String descripcion;
  final String? remitente;
  final String? transportadora;
  final String estado;
  final String? recibidoEn;
  final String? entregadoEn;
  final String? entregadoA;

  const PaqueteModel({
    required this.id,
    required this.propiedadId,
    this.propiedadIdentificador,
    required this.descripcion,
    this.remitente,
    this.transportadora,
    required this.estado,
    this.recibidoEn,
    this.entregadoEn,
    this.entregadoA,
  });

  factory PaqueteModel.fromJson(Map<String, dynamic> json) => PaqueteModel(
        id: (json['id'] as num).toInt(),
        propiedadId: (json['propiedadId'] as num).toInt(),
        propiedadIdentificador: json['propiedadIdentificador'] as String?,
        descripcion: json['descripcion'] as String? ?? '',
        remitente: json['remitente'] as String?,
        transportadora: json['transportadora'] as String?,
        estado: json['estado'] as String? ?? 'RECIBIDO',
        recibidoEn: json['recibidoEn'] as String?,
        entregadoEn: json['entregadoEn'] as String?,
        entregadoA: json['entregadoA'] as String?,
      );

  bool get esRecibido => estado == 'RECIBIDO';
  bool get esEntregado => estado == 'ENTREGADO';
}
