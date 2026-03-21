class OpcionTenant {
  final String tenantId;
  final String nombre;
  final String? direccion;

  OpcionTenant({required this.tenantId, required this.nombre, this.direccion});

  factory OpcionTenant.fromJson(Map<String, dynamic> json) {
    return OpcionTenant(
      tenantId: json['tenantId'],
      nombre: json['nombre'],
      direccion: json['direccion'] as String?,
    );
  }
}
