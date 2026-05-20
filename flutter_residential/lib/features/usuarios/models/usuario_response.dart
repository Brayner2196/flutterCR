class UsuarioResponse {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final String? telefono;
  final String estado;
  final bool activo;
  final String creadoEn;

  UsuarioResponse({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.telefono,
    required this.estado,
    this.activo = true,
    required this.creadoEn,
  });

  factory UsuarioResponse.fromJson(Map<String, dynamic> json) {
    return UsuarioResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      rol: (json['rol'] as String?) ?? '',
      telefono: json['telefono'] as String?,
      estado: (json['estado'] as String?) ?? '',
      activo: (json['activo'] as bool?) ?? true,
      creadoEn: (json['creadoEn'] as String?) ?? '',
    );
  }
}
