import 'package:flutter/services.dart';

/// Formatea el monto con separador de miles mientras se digita: 1234567 → 1.234.567
/// Trabaja solo con enteros (COP no maneja centavos) y conserva la posición del cursor.
class MonedaInputFormatter extends TextInputFormatter {
  const MonedaInputFormatter({this.maxDigitos = 12});

  /// Tope de dígitos: evita montos absurdos y desbordes al parsear.
  final int maxDigitos;

  static final _sepMiles = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
  static final _noDigito = RegExp(r'[^0-9]');
  static final _cerosIzquierda = RegExp(r'^0+(?=\d)');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    var texto = nuevo.text;
    var cursor = nuevo.selection.end < 0 ? texto.length : nuevo.selection.end;

    // 1. Backspace sobre un separador: borra también el dígito que lo precede.
    //    Sin esto, la primera pulsación no hace nada visible y se siente trabado.
    final esBorrado = texto.length < anterior.text.length;
    if (esBorrado &&
        cursor > 0 &&
        cursor < anterior.text.length &&
        anterior.text[cursor] == '.') {
      texto = texto.substring(0, cursor - 1) + texto.substring(cursor);
      cursor -= 1;
    }

    // 2. Normaliza: solo dígitos, sin ceros a la izquierda, con tope.
    final digitos =
        texto.replaceAll(_noDigito, '').replaceFirst(_cerosIzquierda, '');
    if (digitos.isEmpty) return const TextEditingValue();
    if (digitos.length > maxDigitos) return anterior; // rechaza la tecla

    // 3. El cursor se ancla a "cuántos dígitos quedan a su izquierda", no al
    //    índice del string: los puntos cambian de posición al reformatear.
    final digitosIzquierda =
        texto.substring(0, cursor).replaceAll(_noDigito, '').length;

    // 4. Reinserta separadores y reubica el cursor tras ese mismo dígito.
    final formateado = digitos.replaceAllMapped(_sepMiles, (m) => '${m[1]}.');
    var offset = 0;
    var vistos = 0;
    while (offset < formateado.length && vistos < digitosIzquierda) {
      if (formateado[offset] != '.') vistos++;
      offset++;
    }

    return TextEditingValue(
      text: formateado,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}