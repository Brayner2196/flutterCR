/// Una entrada del catalogo de permisos contables.
///
/// El backend manda etiqueta, descripcion y grupo desde el enum
/// `PermisoContable`, asi que esta pantalla NO tiene textos propios: agregar un
/// permiso en Java lo hace aparecer aca sin tocar Flutter.
class PermisoContable {
  final String nombre;
  final String etiqueta;
  final String descripcion;
  final String grupo;

  /// Acciones dificiles de revertir (exonerar, verificar pagos, configurar
  /// cuotas...). La pantalla las separa y nunca vienen activas por defecto.
  final bool sensible;

  final bool otorgado;

  const PermisoContable({
    required this.nombre,
    required this.etiqueta,
    required this.descripcion,
    required this.grupo,
    required this.sensible,
    required this.otorgado,
  });

  factory PermisoContable.fromJson(Map<String, dynamic> json) => PermisoContable(
        nombre: json['nombre'] ?? '',
        etiqueta: json['etiqueta'] ?? json['nombre'] ?? '',
        descripcion: json['descripcion'] ?? '',
        grupo: json['grupo'] ?? 'OTROS',
        sensible: json['sensible'] == true,
        otorgado: json['otorgado'] == true,
      );

  PermisoContable copyWith({bool? otorgado}) => PermisoContable(
        nombre: nombre,
        etiqueta: etiqueta,
        descripcion: descripcion,
        grupo: grupo,
        sensible: sensible,
        otorgado: otorgado ?? this.otorgado,
      );

  /// Titulo legible del grupo. Unico texto que vive en la app, porque el
  /// backend manda el grupo como identificador del enum.
  static String etiquetaGrupo(String grupo) => switch (grupo) {
        'CONSULTA' => 'Consulta',
        'CICLO_COBRO' => 'Ciclo de cobro',
        'RECAUDO' => 'Recaudo',
        'PARAMETRIZACION' => 'Parametrizacion',
        'ACUERDOS' => 'Acuerdos de pago',
        'PRESUPUESTO' => 'Presupuesto',
        'CARTERA_HISTORICA' => 'Cartera historica',
        'COBRANZA' => 'Cobranza',
        _ => grupo,
      };
}
