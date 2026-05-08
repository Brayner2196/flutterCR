class LoginResponse {
  final String token;
  final String email;
  final String rol;
  final String tenantId;
  final String? nombreConjunto;
  final String? nombre;

  LoginResponse({
    required this.token,
    required this.email,
    required this.rol,
    required this.tenantId,
    this.nombreConjunto,
    this.nombre,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      email: json['email'],
      rol: json['rol'],
      tenantId: json['tenantId'],
      nombreConjunto: json['nombreConjunto'],
      nombre: json['nombre'],
    );
  }
}
