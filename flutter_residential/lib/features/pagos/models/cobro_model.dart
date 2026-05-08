class CobroModel {
  final int id;
  final int periodoId;
  final int anio;
  final int mes;
  final int propiedadId;
  final String propiedadIdentificador;
  final int? usuarioId;
  final String usuarioNombre;
  final String concepto;
  final String? descripcion;
  final double montoBase;
  final double montoMora;
  final double montoTotal;
  final double montoPagado;
  final double montoPendiente;
  final String fechaGeneracion;
  final String fechaLimitePago;
  final String estado;
  final bool tieneMovimientos;

  const CobroModel({
    required this.id,
    required this.periodoId,
    required this.anio,
    required this.mes,
    required this.propiedadId,
    required this.propiedadIdentificador,
    this.usuarioId,
    required this.usuarioNombre,
    required this.concepto,
    this.descripcion,
    required this.montoBase,
    required this.montoMora,
    required this.montoTotal,
    required this.montoPagado,
    required this.montoPendiente,
    required this.fechaGeneracion,
    required this.fechaLimitePago,
    required this.estado,
    this.tieneMovimientos = false,
  });

  factory CobroModel.fromJson(Map<String, dynamic> json) => CobroModel(
        id: json['id'] as int,
        periodoId: json['periodoId'] as int,
        anio: json['anio'] as int,
        mes: json['mes'] as int,
        propiedadId: json['propiedadId'] as int,
        propiedadIdentificador: json['propiedadIdentificador'] as String? ?? '',
        usuarioId: json['usuarioId'] as int?,
        usuarioNombre: json['usuarioNombre'] as String? ?? 'N/A',
        concepto: json['concepto'] as String,
        descripcion: json['descripcion'] as String?,
        montoBase: (json['montoBase'] as num).toDouble(),
        montoMora: (json['montoMora'] as num? ?? 0).toDouble(),
        montoTotal: (json['montoTotal'] as num).toDouble(),
        montoPagado: (json['montoPagado'] as num? ?? 0).toDouble(),
        montoPendiente: (json['montoPendiente'] as num? ?? json['montoTotal'] as num).toDouble(),
        fechaGeneracion: json['fechaGeneracion'] as String,
        fechaLimitePago: json['fechaLimitePago'] as String,
        estado: json['estado'] as String,
        tieneMovimientos: json['tieneMovimientos'] as bool? ?? false,
      );

  bool get esPendiente => estado == 'PENDIENTE';
  bool get esParcial => estado == 'PARCIAL';
  bool get esVencido => estado == 'VENCIDO';
  bool get esPagado => estado == 'PAGADO';
  bool get esExonerado => estado == 'EXONERADO';
  bool get tieneDeuda => esPendiente || esParcial || esVencido;

  double get porcentajePagado =>
      montoTotal > 0 ? (montoPagado / montoTotal).clamp(0.0, 1.0) : 0.0;
}
