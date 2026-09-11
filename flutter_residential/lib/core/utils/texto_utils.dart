class TextoUtils {
  TextoUtils._();

  //Ejemplo: "Juan Pérez" -> "JP"
  static String getIniciales(String nombre) {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  //Ejemplo: "juan pérez" -> "Juan pérez"
  static String capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1).toLowerCase();
  }

  static const _conTilde = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  static const _sinTilde = 'aaaaaeeeeiiiiooooouuuunc';

  /// Normaliza un texto para compararlo en un buscador: minúsculas, sin tildes
  /// y sin separadores.
  ///
  /// Así "a-101", "A 101" y "a101" encuentran la misma propiedad "A101".
  /// Reutilizable en cualquier filtro de búsqueda de la app.
  static String normalizarBusqueda(String texto) {
    var r = texto.toLowerCase();
    for (var i = 0; i < _conTilde.length; i++) {
      r = r.replaceAll(_conTilde[i], _sinTilde[i]);
    }
    return r.replaceAll(RegExp(r'[\s\-_/.,#]'), '');
  }

  static final _rxTramos = RegExp(r'(\d+)|(\D+)');

  /// Orden natural: "A9" va antes que "A10" (el orden alfabético los invierte).
  /// Compara por tramos alternando número/texto.
  static int compararNatural(String a, String b) {
    final ta = _rxTramos.allMatches(a.toLowerCase()).map((m) => m[0]!).toList();
    final tb = _rxTramos.allMatches(b.toLowerCase()).map((m) => m[0]!).toList();
    for (var i = 0; i < ta.length && i < tb.length; i++) {
      final na = int.tryParse(ta[i]);
      final nb = int.tryParse(tb[i]);
      final c = (na != null && nb != null)
          ? na.compareTo(nb)
          : ta[i].compareTo(tb[i]);
      if (c != 0) return c;
    }
    return ta.length.compareTo(tb.length);
  }
}
