class PqrHistorialModel {
  final int id;
  final int pqrId;
  final String? estadoAnterior;
  final String estadoNuevo;
  final int? cambiadoPor;
  final String? cambiadoPorNombre;
  final String? cambiadoPorRol;
  final String? comentario;
  final String? fechaCambio;

  const PqrHistorialModel({
    required this.id,
    required this.pqrId,
    this.estadoAnterior,
    required this.estadoNuevo,
    this.cambiadoPor,
    this.cambiadoPorNombre,
    this.cambiadoPorRol,
    this.comentario,
    this.fechaCambio,
  });

  /// Instancia ficticia para usar como placeholder en Skeletonizer
  factory PqrHistorialModel.skeleton() => const PqrHistorialModel(
        id: 0,
        pqrId: 0,
        estadoNuevo: 'RADICADA',
        cambiadoPorNombre: 'Nombre Apellido',
        cambiadoPorRol: 'PROPIETARIO',
        comentario: 'Comentario de ejemplo para skeleton',
        fechaCambio: '01/01/2025 08:00',
      );

  factory PqrHistorialModel.fromJson(Map<String, dynamic> json) =>
      PqrHistorialModel(
        id: (json['id'] as num).toInt(),
        pqrId: (json['pqrId'] as num).toInt(),
        estadoAnterior: json['estadoAnterior'] as String?,
        estadoNuevo: json['estadoNuevo'] as String,
        cambiadoPor: (json['cambiadoPor'] as num?)?.toInt(),
        cambiadoPorNombre: json['cambiadoPorNombre'] as String?,
        cambiadoPorRol: json['cambiadoPorRol'] as String?,
        comentario: json['comentario'] as String?,
        fechaCambio: json['fechaCambio'] as String?,
      );

  /// Etiqueta visible del actor que realizó el cambio. Formato: "Rol / Nombre"
  String get actorLabel {
    final nombre = cambiadoPorNombre?.trim();
    final rol = _rolLegible(cambiadoPorRol?.trim() ?? '');
    if (nombre == null || nombre.isEmpty) return 'Sistema';
    if (rol.isEmpty) return nombre;
    return '$rol / $nombre';
  }

  String get estadoNuevoLegible => _estadoLabel(estadoNuevo);
  String? get estadoAnteriorLegible =>
      estadoAnterior != null ? _estadoLabel(estadoAnterior!) : null;

  static String _estadoLabel(String e) {
    switch (e) {
      case 'RADICADA':
        return 'Radicada';
      case 'EN_PROCESO':
        return 'En proceso';
      case 'RESUELTO':
        return 'Resuelta';
      case 'CERRADO':
        return 'Cerrada';
      case 'RECHAZADA':
        return 'Rechazada';
      default:
        return e;
    }
  }

  static String _rolLegible(String rol) {
    switch (rol) {
      case 'TENANT_ADMIN':
        return 'Administrador';
      case 'SUPER_ADMIN':
        return 'Super Admin';
      case 'PROPIETARIO':
        return 'Propietario';
      case 'INQUILINO':
        return 'Inquilino';
      case 'RESIDENTE':
        return 'Residente';
      case 'VIGILANTE':
        return 'Vigilante';
      case 'PORTERO':
        return 'Portero';
      case 'PISCINERO':
        return 'Piscinero';
      case 'CONTADOR':
        return 'Contador';
      default:
        return rol;
    }
  }
}
