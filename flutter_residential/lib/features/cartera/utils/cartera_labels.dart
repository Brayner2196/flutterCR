import 'package:flutter/material.dart';

/// Catálogos y etiquetas legibles para la configuración de cartera.
/// Las claves coinciden con los enums del backend.
class CarteraLabels {
  CarteraLabels._();

  static const campos = <String, String>{
    'DIAS_VENCIDO_MAX': 'Días vencidos (máx.)',
    'MONTO_ADEUDADO': 'Monto adeudado',
    'NUM_PERIODOS_VENCIDOS': 'N.º periodos vencidos',
    'NUM_COBROS_VENCIDOS': 'N.º cobros vencidos',
  };

  static const operadores = <String, String>{
    'MAYOR_QUE': '>',
    'MAYOR_IGUAL': '≥',
    'MENOR_QUE': '<',
    'MENOR_IGUAL': '≤',
    'IGUAL': '=',
    'DIFERENTE': '≠',
  };

  static const operadoresLogicos = <String, String>{
    'AND': 'Todas (Y)',
    'OR': 'Alguna (O)',
  };

  static const acciones = <String, String>{
    'RESERVAR_ZONA_COMUN': 'Reservar zona común',
    'ACCESO_VEHICULAR': 'Acceso vehicular',
    'ACCESO_PEATONAL_VISITANTE': 'Acceso peatonal visitantes',
    'DESCARGAR_PAZ_Y_SALVO': 'Descargar paz y salvo',
    'VOTAR_ASAMBLEA': 'Votar en asamblea',
    'PUBLICAR_MARKETPLACE': 'Publicar en marketplace',
  };

  /// Paleta sugerida para estados (hex).
  static const coloresSugeridos = <String>[
    '#3F7A4F', // verde
    '#9A6B00', // ámbar
    '#B45000', // naranja
    '#A34A4A', // granate
    '#6E2891', // morado
    '#515F74', // gris azulado
  ];

  static Color colorDeHex(String? hex, {Color fallback = const Color(0xFF515F74)}) {
    if (hex == null || hex.isEmpty) return fallback;
    var h = hex.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    final value = int.tryParse(h, radix: 16);
    return value != null ? Color(value) : fallback;
  }
}
