import 'cobro_model.dart';

class EstadoCuentaModel {
  final double totalPendiente;
  final double totalVencido;
  final int cobrosVencidos;
  final int cobrosPendientes;
  final String? ultimoPago;
  final List<CobroModel> cobrosActivos;

  const EstadoCuentaModel({
    required this.totalPendiente,
    required this.totalVencido,
    required this.cobrosVencidos,
    required this.cobrosPendientes,
    this.ultimoPago,
    required this.cobrosActivos,
  });

  factory EstadoCuentaModel.fromJson(Map<String, dynamic> json) =>
      EstadoCuentaModel(
        totalPendiente: (json['totalPendiente'] as num).toDouble(),
        totalVencido: (json['totalVencido'] as num).toDouble(),
        cobrosVencidos: json['cobrosVencidos'] as int,
        cobrosPendientes: json['cobrosPendientes'] as int,
        ultimoPago: json['ultimoPago'] as String?,
        cobrosActivos: (json['cobrosActivos'] as List)
            .map((e) => CobroModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  bool get alDia => totalPendiente == 0 && totalVencido == 0;
  double get totalDeuda => totalPendiente + totalVencido;
}
