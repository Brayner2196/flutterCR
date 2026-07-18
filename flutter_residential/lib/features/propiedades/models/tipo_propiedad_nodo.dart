class TipoPropiedadNodo {
  final int id;
  final String nombre;
  final String? descripcion;
  final int? parentId;
  final int orden;
  final bool activo;
  final bool esFacturable;

  /// Si true, crear una propiedad de este tipo auto-genera un Parqueadero
  /// con ModeloParqueaderoPrivado.INDEPENDIENTE vinculado a esa propiedad.
  final bool esParqueadero;

  final List<TipoPropiedadNodo> hijos;

  TipoPropiedadNodo({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.parentId,
    this.orden = 0,
    this.activo = true,
    this.esFacturable = false,
    this.esParqueadero = false,
    this.hijos = const [],
  });

  factory TipoPropiedadNodo.fromJson(Map<String, dynamic> json) {
    return TipoPropiedadNodo(
      id:           json['id'],
      nombre:       json['nombre'],
      descripcion:  json['descripcion'],
      parentId:     json['parentId'],
      orden:        json['orden'] ?? 0,
      activo:       json['activo'] ?? true,
      esFacturable: json['esFacturable'] ?? false,
      esParqueadero: json['esParqueadero'] ?? false,
      hijos: (json['hijos'] as List<dynamic>? ?? [])
          .map((h) => TipoPropiedadNodo.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre':       nombre,
    if (descripcion != null) 'descripcion': descripcion,
    'orden':        orden,
    'esFacturable': esFacturable,
    'esParqueadero': esParqueadero,
    'hijos':        hijos.map((h) => h.toJson()).toList(),
  };

  bool get esHoja => hijos.isEmpty;

  /// Recorre el árbol y devuelve, por cada HOJA (tipo final, ej. Apartamento),
  /// su ruta completa raíz→hoja (ej. [Torre, Piso, Apartamento]).
  ///
  /// Reutilizable en cualquier flujo que deba crear la unidad final del árbol:
  /// las hojas son `rutas.map((r) => r.last)`, y cada ruta da los niveles cuyos
  /// valores hay que pedir.
  static List<List<TipoPropiedadNodo>> rutasHoja(
      List<TipoPropiedadNodo> raices) {
    final rutas = <List<TipoPropiedadNodo>>[];
    void recorrer(TipoPropiedadNodo nodo, List<TipoPropiedadNodo> acumulado) {
      final ruta = [...acumulado, nodo];
      if (nodo.esHoja) {
        rutas.add(ruta);
      } else {
        for (final hijo in nodo.hijos) {
          recorrer(hijo, ruta);
        }
      }
    }

    for (final raiz in raices) {
      recorrer(raiz, const []);
    }
    return rutas;
  }

  /// Recorre el árbol y devuelve, por cada nodo FACTURABLE (la unidad final
  /// asignable, ej. Apartamento), su ruta completa raíz→nodo
  /// (ej. [Torre, Piso, Apartamento]).
  ///
  /// Reutilizable en cualquier flujo que deba elegir/crear la unidad asignable:
  /// las hojas mostrables son `rutas.map((r) => r.last)`, y cada ruta da los
  /// niveles cuyos valores hay que pedir.
  static List<List<TipoPropiedadNodo>> rutasFacturables(
      List<TipoPropiedadNodo> raices) {
    final rutas = <List<TipoPropiedadNodo>>[];
    void recorrer(TipoPropiedadNodo nodo, List<TipoPropiedadNodo> acumulado) {
      final ruta = [...acumulado, nodo];
      if (nodo.esFacturable) rutas.add(ruta);
      for (final hijo in nodo.hijos) {
        recorrer(hijo, ruta);
      }
    }

    for (final raiz in raices) {
      recorrer(raiz, const []);
    }
    return rutas;
  }
}
