/// Resultado de una operación destructiva sobre un conjunto
/// (eliminarlo por completo, o vaciar sus datos).
///
/// El backend devuelve el detalle y no un simple 204 porque son operaciones
/// irreversibles: quien las ejecuta necesita ver exactamente qué pasó.
class OperacionDestructivaResponse {
  /// ELIMINAR_CONJUNTO | VACIAR_DATOS
  final String operacion;
  final String schemaName;
  final String nombre;

  /// Tablas vaciadas. Vacío al eliminar: se cae el schema entero.
  final List<String> tablasAfectadas;

  /// Filas borradas por tabla del schema público.
  final Map<String, int> filasBorradas;

  /// Qué sobrevivió a la operación.
  final List<String> conservado;

  final String? ejecutadoPor;
  final DateTime? ejecutadoEn;

  const OperacionDestructivaResponse({
    required this.operacion,
    required this.schemaName,
    required this.nombre,
    required this.tablasAfectadas,
    required this.filasBorradas,
    required this.conservado,
    this.ejecutadoPor,
    this.ejecutadoEn,
  });

  bool get esEliminacion => operacion == 'ELIMINAR_CONJUNTO';

  /// Total de filas borradas en el schema público (identidades, tokens...).
  int get totalFilasBorradas =>
      filasBorradas.values.fold(0, (suma, valor) => suma + valor);

  /// Resumen de una línea, listo para un SnackBar.
  String get resumen => esEliminacion
      ? 'Conjunto "$nombre" eliminado · $totalFilasBorradas registro(s) de acceso borrados'
      : 'Datos de "$nombre" borrados · ${tablasAfectadas.length} tabla(s) vaciada(s)';

  factory OperacionDestructivaResponse.fromJson(Map<String, dynamic> json) {
    return OperacionDestructivaResponse(
      operacion: json['operacion'] as String? ?? '',
      schemaName: json['schemaName'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      tablasAfectadas:
          ((json['tablasAfectadas'] as List?) ?? const []).map((e) => e.toString()).toList(),
      filasBorradas: ((json['filasBorradas'] as Map?) ?? const {}).map(
        (clave, valor) => MapEntry(clave.toString(), (valor as num?)?.toInt() ?? 0),
      ),
      conservado:
          ((json['conservado'] as List?) ?? const []).map((e) => e.toString()).toList(),
      ejecutadoPor: json['ejecutadoPor'] as String?,
      ejecutadoEn: json['ejecutadoEn'] != null
          ? DateTime.tryParse(json['ejecutadoEn'].toString())
          : null,
    );
  }
}
