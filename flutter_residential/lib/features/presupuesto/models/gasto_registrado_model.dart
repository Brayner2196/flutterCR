class GastoRegistradoModel {
  final int id;
  final int categoriaId;
  final String descripcion;
  final double monto;
  final String fecha;
  final String? comprobante;
  final int registradoPor;
  final String creadoEn;

  const GastoRegistradoModel({
    required this.id,
    required this.categoriaId,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    this.comprobante,
    required this.registradoPor,
    required this.creadoEn,
  });

  factory GastoRegistradoModel.fromJson(Map<String, dynamic> j) =>
      GastoRegistradoModel(
        id: j['id'] as int,
        categoriaId: j['categoriaId'] as int,
        descripcion: j['descripcion'] as String,
        monto: (j['monto'] as num).toDouble(),
        fecha: j['fecha'] as String,
        comprobante: j['comprobante'] as String?,
        registradoPor: j['registradoPor'] as int,
        creadoEn: j['creadoEn'] as String? ?? '',
      );
}
