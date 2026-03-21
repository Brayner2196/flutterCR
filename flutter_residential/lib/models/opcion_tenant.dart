class OpcionTenant {
  final String tenantId;
  final String nombre;

  OpcionTenant({required this.tenantId, required this.nombre});

  factory OpcionTenant.fromJson(Map<String, dynamic> json) {
    return OpcionTenant(
      tenantId: json['tenantId'],
      nombre: json['nombre'],
    );
  }
}
