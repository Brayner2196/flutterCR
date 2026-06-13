// Modelos de configuración de estados de cartera.
// Los enums se manejan como String (el backend serializa/acepta el nombre del enum).

class CondicionCartera {
  String campo;
  String operador;
  double valor;

  CondicionCartera({
    required this.campo,
    required this.operador,
    required this.valor,
  });

  factory CondicionCartera.fromJson(Map<String, dynamic> j) => CondicionCartera(
        campo: j['campo'] ?? 'DIAS_VENCIDO_MAX',
        operador: j['operador'] ?? 'MAYOR_IGUAL',
        valor: (j['valor'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'campo': campo,
        'operador': operador,
        'valor': valor,
      };
}

class ReglaCartera {
  int? id;
  String nombre;
  String operadorLogico; // AND | OR
  int? orden;
  List<CondicionCartera> condiciones;

  ReglaCartera({
    this.id,
    required this.nombre,
    this.operadorLogico = 'AND',
    this.orden,
    List<CondicionCartera>? condiciones,
  }) : condiciones = condiciones ?? [];

  factory ReglaCartera.fromJson(Map<String, dynamic> j) => ReglaCartera(
        id: j['id'],
        nombre: j['nombre'] ?? 'Regla',
        operadorLogico: j['operadorLogico'] ?? 'AND',
        orden: j['orden'],
        condiciones: (j['condiciones'] as List? ?? [])
            .map((e) => CondicionCartera.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nombre': nombre,
        'operadorLogico': operadorLogico,
        if (orden != null) 'orden': orden,
        'condiciones': condiciones.map((c) => c.toJson()).toList(),
      };
}

class RestriccionCartera {
  String accion;
  String? mensaje;

  RestriccionCartera({required this.accion, this.mensaje});

  factory RestriccionCartera.fromJson(Map<String, dynamic> j) => RestriccionCartera(
        accion: j['accion'],
        mensaje: j['mensaje'],
      );

  Map<String, dynamic> toJson() => {
        'accion': accion,
        if (mensaje != null && mensaje!.isNotEmpty) 'mensaje': mensaje,
      };
}

class EstadoCarteraConfig {
  int? id;
  String codigo;
  String nombre;
  String? descripcion;
  int severidad;
  String? color;
  bool esPositivo;
  bool activo;
  List<ReglaCartera> reglas;
  List<RestriccionCartera> restricciones;

  EstadoCarteraConfig({
    this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.severidad = 0,
    this.color,
    this.esPositivo = false,
    this.activo = true,
    List<ReglaCartera>? reglas,
    List<RestriccionCartera>? restricciones,
  })  : reglas = reglas ?? [],
        restricciones = restricciones ?? [];

  factory EstadoCarteraConfig.fromJson(Map<String, dynamic> j) => EstadoCarteraConfig(
        id: j['id'],
        codigo: j['codigo'] ?? '',
        nombre: j['nombre'] ?? '',
        descripcion: j['descripcion'],
        severidad: j['severidad'] ?? 0,
        color: j['color'],
        esPositivo: j['esPositivo'] ?? false,
        activo: j['activo'] ?? true,
        reglas: (j['reglas'] as List? ?? [])
            .map((e) => ReglaCartera.fromJson(e))
            .toList(),
        restricciones: (j['restricciones'] as List? ?? [])
            .map((e) => RestriccionCartera.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'codigo': codigo,
        'nombre': nombre,
        'descripcion': descripcion,
        'severidad': severidad,
        'color': color,
        'esPositivo': esPositivo,
        'activo': activo,
        'reglas': reglas.map((r) => r.toJson()).toList(),
        'restricciones': restricciones.map((r) => r.toJson()).toList(),
      };
}
