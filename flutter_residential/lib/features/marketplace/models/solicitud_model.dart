class SolicitudModel {
  final int id;
  final int publicacionId;
  final String publicacionTitulo;
  final double publicacionPrecio;
  final int compradorId;
  final String compradorNombre;
  final int vendedorId;
  final String vendedorNombre;

  /// DOMICILIO | RECOGIDA
  final String tipo;

  final int cantidad;
  final String? notas;

  /// PENDIENTE | ACEPTADA | RECHAZADA | CANCELADA
  final String estado;
  final String creadoEn;

  const SolicitudModel({
    required this.id,
    required this.publicacionId,
    required this.publicacionTitulo,
    required this.publicacionPrecio,
    required this.compradorId,
    required this.compradorNombre,
    required this.vendedorId,
    required this.vendedorNombre,
    required this.tipo,
    required this.cantidad,
    this.notas,
    required this.estado,
    required this.creadoEn,
  });

  factory SolicitudModel.fromJson(Map<String, dynamic> json) => SolicitudModel(
        id: (json['id'] as num).toInt(),
        publicacionId: (json['publicacionId'] as num).toInt(),
        publicacionTitulo: json['publicacionTitulo'] as String? ?? '',
        publicacionPrecio: (json['publicacionPrecio'] as num).toDouble(),
        compradorId: (json['compradorId'] as num).toInt(),
        compradorNombre: json['compradorNombre'] as String? ?? 'N/A',
        vendedorId: (json['vendedorId'] as num).toInt(),
        vendedorNombre: json['vendedorNombre'] as String? ?? 'N/A',
        tipo: json['tipo'] as String,
        cantidad: (json['cantidad'] as num).toInt(),
        notas: json['notas'] as String?,
        estado: json['estado'] as String,
        creadoEn: json['creadoEn'] as String,
      );

  bool get esDomicilio => tipo == 'DOMICILIO';
  bool get esPendiente => estado == 'PENDIENTE';
  bool get esAceptada => estado == 'ACEPTADA';
  bool get esRechazada => estado == 'RECHAZADA';

  double get totalPrecio => publicacionPrecio * cantidad;

  String get tipoLegible => esDomicilio ? 'A domicilio' : 'Recogida en punto';

  String get estadoLegible {
    switch (estado) {
      case 'PENDIENTE':   return 'Pendiente';
      case 'ACEPTADA':    return 'Aceptada';
      case 'RECHAZADA':   return 'Rechazada';
      case 'CANCELADA':   return 'Cancelada';
      default:            return estado;
    }
  }

  String get precioTotalFormateado =>
      '\$${totalPrecio.toStringAsFixed(totalPrecio.truncateToDouble() == totalPrecio ? 0 : 2)}';
}
