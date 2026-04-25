class PeriodoCobroModel {
  final int id;
  final int anio;
  final int mes;
  final String fechaInicio;
  final String fechaFin;
  final String fechaLimitePago;
  final String estado;
  final String creadoEn;

  const PeriodoCobroModel({
    required this.id,
    required this.anio,
    required this.mes,
    required this.fechaInicio,
    required this.fechaFin,
    required this.fechaLimitePago,
    required this.estado,
    required this.creadoEn,
  });

  factory PeriodoCobroModel.fromJson(Map<String, dynamic> json) =>
      PeriodoCobroModel(
        id: json['id'] as int,
        anio: json['anio'] as int,
        mes: json['mes'] as int,
        fechaInicio: json['fechaInicio'] as String,
        fechaFin: json['fechaFin'] as String,
        fechaLimitePago: json['fechaLimitePago'] as String,
        estado: json['estado'] as String,
        creadoEn: json['creadoEn'] as String,
      );

  static const _meses = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  String get nombreMes => '${_meses[mes]} $anio';
  bool get estaAbierto => estado == 'ABIERTO';
}
