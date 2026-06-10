class MiembroConsejoModel {
  final int id;
  final int usuarioId;
  final String nombreUsuario;
  final String cargo;
  final String fechaInicio;
  final String? fechaFin;
  final bool activo;
  final String creadoEn;

  const MiembroConsejoModel({
    required this.id,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.cargo,
    required this.fechaInicio,
    this.fechaFin,
    required this.activo,
    required this.creadoEn,
  });

  factory MiembroConsejoModel.fromJson(Map<String, dynamic> json) {
    return MiembroConsejoModel(
      id: json['id'] as int,
      usuarioId: json['usuarioId'] as int,
      nombreUsuario: json['nombreUsuario'] as String? ?? '',
      cargo: json['cargo'] as String? ?? '',
      fechaInicio: json['fechaInicio'] as String? ?? '',
      fechaFin: json['fechaFin'] as String?,
      activo: json['activo'] as bool? ?? false,
      creadoEn: json['creadoEn'] as String? ?? '',
    );
  }

  /// Cargo en texto legible (PRESIDENTE → Presidente)
  String get cargoTexto {
    if (cargo.isEmpty) return cargo;
    return cargo[0].toUpperCase() + cargo.substring(1).toLowerCase();
  }
}
