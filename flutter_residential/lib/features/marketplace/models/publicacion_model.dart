class PublicacionModel {
  final int id;
  final int vendedorId;
  final String vendedorNombre;
  final int? propiedadId;
  final String titulo;
  final String? descripcion;
  final double precio;
  final String categoria;
  final String? contacto;
  final String estado;
  final String creadoEn;
  final String? actualizadoEn;
  final int? distanciaProximidad;

  // ── Nuevos campos ──────────────────────────────────────────
  /// null = no maneja stock | 0 = agotado | >0 = disponible
  final int? stock;
  final bool aceptaDomicilio;
  final List<String> metodosPago;
  final String? marca;
  /// Texto descriptivo de la ubicación del vendedor: "Torre A · Piso 3"
  final String? ubicacionVendedor;

  const PublicacionModel({
    required this.id,
    required this.vendedorId,
    required this.vendedorNombre,
    this.propiedadId,
    required this.titulo,
    this.descripcion,
    required this.precio,
    required this.categoria,
    this.contacto,
    required this.estado,
    required this.creadoEn,
    this.actualizadoEn,
    this.distanciaProximidad,
    this.stock,
    this.aceptaDomicilio = false,
    this.metodosPago = const [],
    this.marca,
    this.ubicacionVendedor,
  });

  factory PublicacionModel.fromJson(Map<String, dynamic> json) => PublicacionModel(
        id: (json['id'] as num).toInt(),
        vendedorId: (json['vendedorId'] as num).toInt(),
        vendedorNombre: json['vendedorNombre'] as String? ?? 'N/A',
        propiedadId: (json['propiedadId'] as num?)?.toInt(),
        titulo: json['titulo'] as String,
        descripcion: json['descripcion'] as String?,
        precio: (json['precio'] as num).toDouble(),
        categoria: json['categoria'] as String,
        contacto: json['contacto'] as String?,
        estado: json['estado'] as String,
        creadoEn: json['creadoEn'] as String,
        actualizadoEn: json['actualizadoEn'] as String?,
        distanciaProximidad: (json['distanciaProximidad'] as num?)?.toInt(),
        stock: (json['stock'] as num?)?.toInt(),
        aceptaDomicilio: json['aceptaDomicilio'] as bool? ?? false,
        metodosPago: (json['metodosPago'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        marca: json['marca'] as String?,
        ubicacionVendedor: json['ubicacionVendedor'] as String?,
      );

  bool get esActiva => estado == 'ACTIVA';
  bool get esPausada => estado == 'PAUSADA';
  bool get esVendida => estado == 'VENDIDA';

  /// true si maneja stock y ya está agotado
  bool get agotado => stock != null && stock! <= 0;

  /// true si queda solo 1 unidad
  bool get ultimaUnidad => stock != null && stock! == 1;

  String get estadoLegible {
    switch (estado) {
      case 'ACTIVA': return 'Activa';
      case 'PAUSADA': return 'Pausada';
      case 'VENDIDA': return 'Vendida';
      case 'ELIMINADA': return 'Eliminada';
      default: return estado;
    }
  }

  String get categoriaLegible {
    switch (categoria) {
      case 'ELECTRONICA': return 'Electrónica';
      case 'MUEBLES': return 'Muebles';
      case 'ROPA': return 'Ropa';
      case 'ALIMENTOS': return 'Alimentos';
      case 'SERVICIOS': return 'Servicios';
      case 'MASCOTAS': return 'Mascotas';
      case 'OTROS': return 'Otros';
      default: return categoria;
    }
  }

  String get precioFormateado => '\$${precio.toStringAsFixed(precio.truncateToDouble() == precio ? 0 : 2)}';

  /// Fecha legible "dd/MM/yyyy"
  String get fechaCorta {
    try {
      final partes = creadoEn.split('T').first.split('-');
      return '${partes[2]}/${partes[1]}/${partes[0]}';
    } catch (_) {
      return creadoEn;
    }
  }
}

/// Categorías disponibles para formularios y filtros
const kCategorias = [
  ('ALIMENTOS', 'Alimentos'),
  ('SERVICIOS', 'Servicios'),
  ('MASCOTAS', 'Mascotas'),
  ('ELECTRONICA', 'Electrónica'),
  ('MUEBLES', 'Muebles'),
  ('ROPA', 'Ropa'),
  ('OTROS', 'Otros'),
];
