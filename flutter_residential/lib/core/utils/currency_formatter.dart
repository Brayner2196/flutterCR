/// Formateador centralizado de moneda.
/// Elimina los métodos `_fmt()` locales duplicados en múltiples pantallas de pagos.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final _sepMiles = RegExp(r'(\d)(?=(\d{3})+(?!\d))');

  /// Formatea un número como pesos colombianos: $1.234.567
  static String cop(num value) {
    final entero = value.toInt();
    final str = entero.abs().toString().replaceAllMapped(
          _sepMiles,
          (m) => '${m[1]}.',
        );
    return entero < 0 ? '-\$$str' : '\$$str';
  }

  /// Formato compacto para montos grandes: $6,5M · $850K · $1.234.
  /// Útil en tarjetas/resúmenes donde el ancho es limitado.
  static String copCompacto(num value) {
    final v = value.toInt();
    final abs = v.abs();
    String cuerpo;
    if (abs >= 1000000) {
      cuerpo = '\$${_decimal(abs / 1000000)}M';
    } else if (abs >= 10000) {
      cuerpo = '\$${_decimal(abs / 1000)}K';
    } else {
      cuerpo = cop(abs);
    }
    return v < 0 ? '-$cuerpo' : cuerpo;
  }

  /// Un decimal con coma; oculta el ",0" (6.0 -> "6", 6.5 -> "6,5").
  static String _decimal(double n) {
    final s = n.toStringAsFixed(n >= 100 ? 0 : 1);
    return s.replaceAll('.', ',').replaceAll(RegExp(r',0$'), '');
  }

  /// Igual que [cop] pero acepta String (null-safe, devuelve '\$0' si inválido).
  static String copFromString(String? value) {
    if (value == null || value.isEmpty) return '\$0';
    final n = num.tryParse(value.replaceAll(',', '.'));
    return n != null ? cop(n) : '\$0';
  }

  /// Parsea un String con puntos/comas a double. Retorna null si no es válido.
  static double? parse(String text) =>
      double.tryParse(text.replaceAll('.', '').replaceAll(',', '.').trim());

  //este método es para formatear el valor de un double a un string con formato de moneda, sin decimales y con separador de miles. Ejemplo: 1234567.89 -> $1.234.568
  static String fmt(double v) =>
    '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

}
