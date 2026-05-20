class ConjuntoModel {
  final String nombre;
  final String codigo;
  final String? direccion;
  final bool activo;

  const ConjuntoModel({
    required this.nombre,
    required this.codigo,
    this.direccion,
    required this.activo,
  });

  factory ConjuntoModel.fromJson(Map<String, dynamic> json) => ConjuntoModel(
        nombre: json['nombre'] as String,
        codigo: json['codigo'] as String,
        direccion: json['direccion'] as String?,
        activo: json['activo'] as bool? ?? true,
      );
}
