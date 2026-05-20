class FormatMoneda {
  FormatMoneda._();

  static String format(double v){
    return '\$ ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}


