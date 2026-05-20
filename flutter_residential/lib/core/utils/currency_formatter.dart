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

  /// Igual que [cop] pero acepta String (null-safe, devuelve '\$0' si inválido).
  static String copFromString(String? value) {
    if (value == null || value.isEmpty) return '\$0';
    final n = num.tryParse(value.replaceAll(',', '.'));
    return n != null ? cop(n) : '\$0';
  }

  /// Parsea un String con puntos/comas a double. Retorna null si no es válido.
  static double? parse(String text) =>
      double.tryParse(text.replaceAll('.', '').replaceAll(',', '.').trim());
}
