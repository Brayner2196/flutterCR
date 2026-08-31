import '../../../core/enums/modulo.dart';

/// Estado de un módulo dentro de un conjunto, tal como lo entrega
/// `GET /api/tenants/{id}/modulos`. Es el modelo que pinta el panel del
/// SUPER_ADMIN; la app de residentes/admin solo necesita la lista de códigos
/// activos y no usa esta clase.
class ModuloEstado {
  /// Código crudo del backend. Se conserva aunque [modulo] sea null, para que
  /// una app desactualizada siga mostrando el switch sin romperse.
  final String codigo;
  final Modulo? modulo;
  final String nombre;
  final String descripcion;

  /// Estado efectivo: ya considera la dependencia del módulo padre.
  final bool activo;

  /// Código del módulo del que depende, o null.
  final String? requiere;

  /// True si su fila dice activo pero el padre está apagado. Sirve para
  /// mostrar "requiere Vigilancia" en la UI en vez de un switch mudo.
  final bool bloqueadoPorPadre;

  final DateTime? actualizadoEn;
  final String? actualizadoPor;

  const ModuloEstado({
    required this.codigo,
    required this.modulo,
    required this.nombre,
    required this.descripcion,
    required this.activo,
    required this.requiere,
    required this.bloqueadoPorPadre,
    this.actualizadoEn,
    this.actualizadoPor,
  });

  factory ModuloEstado.fromJson(Map<String, dynamic> json) {
    final codigo = json['codigo'] as String? ?? '';
    return ModuloEstado(
      codigo: codigo,
      modulo: Modulo.desdeCodigo(codigo),
      nombre: json['nombre'] as String? ?? codigo,
      descripcion: json['descripcion'] as String? ?? '',
      activo: json['activo'] as bool? ?? false,
      requiere: json['requiere'] as String?,
      bloqueadoPorPadre: json['bloqueadoPorPadre'] as bool? ?? false,
      actualizadoEn: json['actualizadoEn'] != null
          ? DateTime.tryParse(json['actualizadoEn'].toString())
          : null,
      actualizadoPor: json['actualizadoPor'] as String?,
    );
  }
}
