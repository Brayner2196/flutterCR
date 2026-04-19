class PropiedadPathItem {
  final int tipoId;
  final String valor;

  const PropiedadPathItem({required this.tipoId, required this.valor});

  Map<String, dynamic> toJson() => {'tipoId': tipoId, 'valor': valor};
}
