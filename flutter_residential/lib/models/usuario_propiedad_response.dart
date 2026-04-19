class UsuarioPropiedadResponse {
  final int id;
  final int propiedadId;
  final String pathTexto;
  final String nombreTipoRaiz;
  final bool esPrincipal;

  const UsuarioPropiedadResponse({
    required this.id,
    required this.propiedadId,
    required this.pathTexto,
    required this.nombreTipoRaiz,
    required this.esPrincipal,
  });

  factory UsuarioPropiedadResponse.fromJson(Map<String, dynamic> json) {
    return UsuarioPropiedadResponse(
      id: json['id'],
      propiedadId: json['propiedadId'],
      pathTexto: json['pathTexto'] ?? '',
      nombreTipoRaiz: json['nombreTipoRaiz'] ?? '',
      esPrincipal: json['esPrincipal'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'propiedadId': propiedadId,
        'pathTexto': pathTexto,
        'nombreTipoRaiz': nombreTipoRaiz,
        'esPrincipal': esPrincipal,
      };
}
