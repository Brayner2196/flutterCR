class FormatMoneda {
  FormatMoneda._();

  //Ejemplo: 1000000 -> "$ 1.000.000"
  static String format(double v){ 
    return '\$ ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}


