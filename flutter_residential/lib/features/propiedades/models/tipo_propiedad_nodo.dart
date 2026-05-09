class TipoPropiedadNodo {
  final int id;
  final String nombre;
  final String? descripcion;
  final int? parentId;
  final int orden;
  final bool activo;
  final List<TipoPropiedadNodo> hijos;

  TipoPropiedadNodo({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.parentId,
    this.orden = 0,
    this.activo = true,
    this.hijos = const [],
  });

  factory TipoPropiedadNodo.fromJson(Map<String, dynamic> json) {
    return TipoPropiedadNodo(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      parentId: json['parentId'],
      orden: json['orden'] ?? 0,
      activo: json['activo'] ?? true,
      hijos: (json['hijos'] as List<dynamic>? ?? [])
          .map((h) => TipoPropiedadNodo.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        'orden': orden,
        'hijos': hijos.map((h) => h.toJson()).toList(),
      };

  bool get esHoja => hijos.isEmpty;
}
