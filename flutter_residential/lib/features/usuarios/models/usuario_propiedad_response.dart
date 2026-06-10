class UsuarioPropiedadResponse {
  final int id;
  final int propiedadId;
  final String pathTexto;
  final String pathCorto;
  final String nombreTipoRaiz;
  final String estadoPropiedad;
  final bool esPrincipal;
  final bool esParqueadero;

  const UsuarioPropiedadResponse({
    required this.id,
    required this.propiedadId,
    required this.pathTexto,
    this.pathCorto = '',
    required this.nombreTipoRaiz,
    required this.estadoPropiedad,
    required this.esPrincipal,
    this.esParqueadero = false,
  });

  factory UsuarioPropiedadResponse.fromJson(Map<String, dynamic> json) {
    return UsuarioPropiedadResponse(
      id: json['id'],
      propiedadId: json['propiedadId'],
      pathTexto: json['pathTexto'] ?? '',
      pathCorto: json['pathCorto'] ?? '',
      nombreTipoRaiz: json['nombreTipoRaiz'] ?? '',
      estadoPropiedad: json['estadoPropiedad'] ?? 'desconocido',
      esPrincipal: json['esPrincipal'] ?? false,
      esParqueadero: json['esParqueadero'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'propiedadId': propiedadId,
        'pathTexto': pathTexto,
        'pathCorto': pathCorto,
        'nombreTipoRaiz': nombreTipoRaiz,
        'esPrincipal': esPrincipal,
        'esParqueadero': esParqueadero,
      };
}
