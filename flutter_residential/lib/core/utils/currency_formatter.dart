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

  /// Ej: $6,5M · $850K
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

  /// Ej: 6.0 -> "6" · 6.5 -> "6,5"
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
  
  /// Formatea un double como pesos colombianos, Ej: 1234567.89 -> $1.234.568
  static String fmt(double v) =>
    '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';


  /// Separador de miles SIN símbolo — para inicializar campos de texto.
  static String miles(num value) => value.toInt().abs().toString()
      .replaceAllMapped(_sepMiles, (m) => '${m[1]}.');

  /// Parsea texto formateado ("$ 1.234.567") a double. null si no es válido.
  static double? parse(String? text) {
    if (text == null) return null;
    final limpio = text.replaceAll(RegExp(r'[^\d,]'), '').replaceAll(',', '.');
    return limpio.isEmpty ? null : double.tryParse(limpio);
  }
}
