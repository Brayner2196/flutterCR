class UsuarioResponse {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final String? apto;
  final String? torre;
  final String? telefono;
  final String estado;
  final String creadoEn;

  UsuarioResponse({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.apto,
    this.torre,
    this.telefono,
    required this.estado,
    required this.creadoEn,
  });

  factory UsuarioResponse.fromJson(Map<String, dynamic> json) {
    return UsuarioResponse(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
      rol: json['rol'],
      apto: json['apto'],
      torre: json['torre'],
      telefono: json['telefono'],
      estado: json['estado'],
      creadoEn: json['creadoEn'],
    );
  }
}
