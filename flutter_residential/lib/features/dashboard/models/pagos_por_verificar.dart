class PagosPorVerificar {
  final int cantidad;

  const PagosPorVerificar({required this.cantidad});

  factory PagosPorVerificar.fromJson(Map<String, dynamic> json) =>
      PagosPorVerificar(cantidad: (json['cantidad'] as num).toInt());
}
