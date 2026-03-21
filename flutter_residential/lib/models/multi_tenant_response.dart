import 'opcion_tenant.dart';

class MultiTenantResponse {
  final bool requiereSeleccion;
  final List<OpcionTenant> conjuntos;

  MultiTenantResponse({
    required this.requiereSeleccion,
    required this.conjuntos,
  });

  factory MultiTenantResponse.fromJson(Map<String, dynamic> json) {
    return MultiTenantResponse(
      requiereSeleccion: json['requiereSeleccion'],
      conjuntos: (json['conjuntos'] as List)
          .map((e) => OpcionTenant.fromJson(e))
          .toList(),
    );
  }
}
