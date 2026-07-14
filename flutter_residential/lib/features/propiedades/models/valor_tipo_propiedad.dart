/// Valor permitido del catálogo de un tipo de propiedad.
///
/// Modelo híbrido:
///   - [parentValorId] null  → plantilla global del tipo.
///   - [parentValorId] != null → excepción contextual bajo ese valor padre.
class ValorTipoPropiedad {
  final int id;
  final int tipoId;
  final String valor;
  final int? parentValorId;
  final int orden;
  final bool activo;

  const ValorTipoPropiedad({
    required this.id,
    required this.tipoId,
    required this.valor,
    this.parentValorId,
    this.orden = 0,
    this.activo = true,
  });

  factory ValorTipoPropiedad.fromJson(Map<String, dynamic> json) {
    return ValorTipoPropiedad(
      id: json['id'],
      tipoId: json['tipoId'],
      valor: json['valor'],
      parentValorId: json['parentValorId'],
      orden: json['orden'] ?? 0,
      activo: json['activo'] ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ValorTipoPropiedad && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
