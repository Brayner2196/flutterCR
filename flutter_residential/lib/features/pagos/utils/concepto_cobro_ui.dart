/// Etiquetas legibles de los conceptos de cobro del backend.
///
/// El enum llega crudo desde la API (`ADMINISTRACION`, `ZONA_COMUN`…) y hasta
/// ahora se pintaba tal cual en las tarjetas. Centralizarlo evita que cada
/// pantalla invente su propia traducción.
class ConceptoCobroUi {
  ConceptoCobroUi._();

  static const Map<String, String> _mapa = {
    'ADMINISTRACION': 'Administración',
    'ACUERDO_PAGO': 'Acuerdo de pago',
    'PARQUEADERO': 'Parqueadero',
    'ZONA_COMUN': 'Zona común',
    'MULTA': 'Multa',
    'SANCION': 'Sanción',
    'OTRO': 'Otro',
  };

  /// Nunca lanza: si el backend agrega un concepto nuevo, se muestra el código.
  static String label(String? codigo) {
    if (codigo == null || codigo.isEmpty) return 'Cobro';
    return _mapa[codigo] ?? codigo;
  }
}
