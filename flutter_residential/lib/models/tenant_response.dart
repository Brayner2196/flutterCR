class TenantResponse {
  final int id;
  final String schemaName;
  final String nombre;
  final String codigo;
  final bool activo;
  final String? direccion;

  TenantResponse({
    required this.id,
    required this.schemaName,
    required this.nombre,
    required this.codigo,
    required this.activo,
    this.direccion,
  });

  factory TenantResponse.fromJson(Map<String, dynamic> json) {
    return TenantResponse(
      id: json['id'],
      schemaName: json['schemaName'],
      nombre: json['nombre'],
      codigo: json['codigo'],
      activo: json['activo'],
      direccion: json['direccion'],
    );
  }
}
