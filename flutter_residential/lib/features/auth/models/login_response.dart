class LoginResponse {
  final String token;
  final String refreshToken;
  final String email;
  final String rol;
  final String tenantId;
  final String? nombreConjunto;
  final String? nombre;
  /// Ej: "America/Bogota". Null si el usuario es SUPER_ADMIN.
  final String? timezone;
  /// Verdadero si el usuario tiene membresía activa en el consejo comunal.
  final bool esConsejero;
  /// Cargo en el consejo: PRESIDENTE, VICEPRESIDENTE, etc. Null si no es consejero.
  final String? cargoConsejo;

  LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.email,
    required this.rol,
    required this.tenantId,
    this.nombreConjunto,
    this.nombre,
    this.timezone,
    this.esConsejero = false,
    this.cargoConsejo,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String? ?? '',
      email: json['email'] as String,
      rol: json['rol'] as String,
      tenantId: json['tenantId'] as String,
      nombreConjunto: json['nombreConjunto'] as String?,
      nombre: json['nombre'] as String?,
      timezone: json['timezone'] as String?,
      esConsejero: json['esConsejero'] as bool? ?? false,
      cargoConsejo: json['cargoConsejo'] as String?,
    );
  }
}
