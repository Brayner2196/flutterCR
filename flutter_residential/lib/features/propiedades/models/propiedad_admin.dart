import 'package:flutter/material.dart';

/// Resumen de un residente asociado a una propiedad (viene en PropiedadResponse).
class ResidenteResumen {
  final int usuarioId;
  final String nombre;
  final String email;
  final bool esPrincipal;

  const ResidenteResumen({
    required this.usuarioId,
    required this.nombre,
    required this.email,
    this.esPrincipal = false,
  });

  factory ResidenteResumen.fromJson(Map<String, dynamic> json) {
    return ResidenteResumen(
      usuarioId: (json['usuarioId'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      esPrincipal: (json['esPrincipal'] as bool?) ?? false,
    );
  }
}

/// Estados posibles de una propiedad. Coinciden con el enum EstadoPropiedad del
/// backend. Se centraliza aquí etiqueta/color/icono para reutilizarlos en toda
/// la UI (tarjeta, hoja de detalle, filtros).
class EstadoPropiedad {
  static const String disponible = 'DISPONIBLE';
  static const String ocupado = 'OCUPADO';
  static const String enMantenimiento = 'EN_MANTENIMIENTO';
  static const String vendido = 'VENDIDO';

  static const List<String> todos = [
    disponible,
    ocupado,
    enMantenimiento,
    vendido,
  ];

  static String etiqueta(String estado) {
    switch (estado) {
      case disponible:
        return 'Disponible';
      case ocupado:
        return 'Ocupado';
      case enMantenimiento:
        return 'En mantenimiento';
      case vendido:
        return 'Vendido';
      default:
        return estado;
    }
  }

  static Color color(String estado) {
    switch (estado) {
      case disponible:
        return const Color(0xFF16A34A); // verde
      case ocupado:
        return const Color(0xFF2563EB); // azul
      case enMantenimiento:
        return const Color(0xFFF97316); // naranja
      case vendido:
        return const Color(0xFF6B7280); // gris
      default:
        return const Color(0xFF6B7280);
    }
  }

  static IconData icono(String estado) {
    switch (estado) {
      case disponible:
        return Icons.check_circle_outline;
      case ocupado:
        return Icons.person_outline;
      case enMantenimiento:
        return Icons.build_outlined;
      case vendido:
        return Icons.sell_outlined;
      default:
        return Icons.home_outlined;
    }
  }
}

/// Propiedad (unidad) para la gestión del admin. Mapea PropiedadResponse.
class PropiedadAdmin {
  final int id;
  final int tipoId;
  final String nombreTipo;
  final int? parentId;
  final String identificador;
  final String pathTexto;
  final String pathTextoCorto;
  final bool esFacturable;
  final bool esParqueadero;
  final String estado;
  final List<ResidenteResumen> residentes;

  const PropiedadAdmin({
    required this.id,
    required this.tipoId,
    required this.nombreTipo,
    this.parentId,
    required this.identificador,
    required this.pathTexto,
    required this.pathTextoCorto,
    this.esFacturable = false,
    this.esParqueadero = false,
    required this.estado,
    this.residentes = const [],
  });

  int get totalResidentes => residentes.length;
  bool get sinResidentes => residentes.isEmpty;

  /// Título corto para la tarjeta; cae al path completo si no hay corto.
  String get titulo =>
      pathTextoCorto.isNotEmpty ? pathTextoCorto : pathTexto;

  factory PropiedadAdmin.fromJson(Map<String, dynamic> json) {
    final resList = (json['residentes'] as List?) ?? const [];
    return PropiedadAdmin(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tipoId: (json['tipoId'] as num?)?.toInt() ?? 0,
      nombreTipo: (json['nombreTipo'] as String?) ?? '',
      parentId: (json['parentId'] as num?)?.toInt(),
      identificador: (json['identificador'] as String?) ?? '',
      pathTexto: (json['pathTexto'] as String?) ?? '',
      pathTextoCorto: (json['pathTextoCorto'] as String?) ?? '',
      esFacturable: (json['esFacturable'] as bool?) ?? false,
      esParqueadero: (json['esParqueadero'] as bool?) ?? false,
      estado: (json['estado'] as String?) ?? EstadoPropiedad.disponible,
      residentes: resList
          .map((e) => ResidenteResumen.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
