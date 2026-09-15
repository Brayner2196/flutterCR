/// Un cobro del acuerdo: el abono inicial (numeroCuota 0) o una cuota diferida.
///
/// Reemplaza al antiguo CuotaPlanModel: las cuotas dejaron de ser una tabla
/// aparte y son cobros reales, así que se pagan por la pasarela y se verifican
/// como cualquier otro cobro.
class CobroAcuerdoModel {
  final int id;
  final int? numeroCuota;
  final bool esAbonoInicial;
  final String? descripcion;
  final double monto;
  final double montoPagado;
  final double montoPendiente;
  final String? fechaLimitePago;
  final String estado;
  final bool vencido;

  const CobroAcuerdoModel({
    required this.id,
    this.numeroCuota,
    required this.esAbonoInicial,
    this.descripcion,
    required this.monto,
    required this.montoPagado,
    required this.montoPendiente,
    this.fechaLimitePago,
    required this.estado,
    required this.vencido,
  });

  factory CobroAcuerdoModel.fromJson(Map<String, dynamic> json) =>
      CobroAcuerdoModel(
        id: json['id'] as int,
        numeroCuota: json['numeroCuota'] as int?,
        esAbonoInicial: json['esAbonoInicial'] as bool? ?? false,
        descripcion: json['descripcion'] as String?,
        monto: (json['monto'] as num? ?? 0).toDouble(),
        montoPagado: (json['montoPagado'] as num? ?? 0).toDouble(),
        montoPendiente: (json['montoPendiente'] as num? ?? 0).toDouble(),
        fechaLimitePago: json['fechaLimitePago'] as String?,
        estado: json['estado'] as String? ?? 'PENDIENTE',
        vencido: json['vencido'] as bool? ?? false,
      );

  bool get esPagado => estado == 'PAGADO';
  bool get esParcial => estado == 'PARCIAL';
  bool get enVerificacion => estado == 'EN_VERIFICACION';
  bool get esAnulado => estado == 'ANULADO';
  bool get sePuedePagar =>
      !esPagado && !esAnulado && !enVerificacion && estado != 'EXONERADO';

  String get titulo => esAbonoInicial
      ? 'Abono inicial'
      : 'Cuota ${numeroCuota ?? ''}';
}
