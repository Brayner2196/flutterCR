class AccesoVehicularModel {
  final bool permitido;
  final String placa;
  final int? propiedadId;
  final String propiedad;
  final String? estadoCodigo;
  final String? estadoNombre;
  final String? mensaje;

  const AccesoVehicularModel({
    required this.permitido,
    required this.placa,
    this.propiedadId,
    required this.propiedad,
    this.estadoCodigo,
    this.estadoNombre,
    this.mensaje,
  });

  factory AccesoVehicularModel.fromJson(Map<String, dynamic> json) =>
      AccesoVehicularModel(
        permitido: json['permitido'] as bool? ?? false,
        placa: json['placa'] as String? ?? '',
        propiedadId: (json['propiedadId'] as num?)?.toInt(),
        propiedad: json['propiedad'] as String? ?? 'N/A',
        estadoCodigo: json['estadoCodigo'] as String?,
        estadoNombre: json['estadoNombre'] as String?,
        mensaje: json['mensaje'] as String?,
      );
}
