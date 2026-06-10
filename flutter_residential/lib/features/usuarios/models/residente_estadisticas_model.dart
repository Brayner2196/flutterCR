import '../../pagos/models/cobro_model.dart';
import '../../pagos/models/pago_model.dart';

/// Modelo que agrega estadísticas financieras del residente
/// calculadas a partir de sus cobros y pagos.
class ResidenteEstadisticasModel {
  // ─── Resumen de deuda ─────────────────────────────────
  final double totalPendiente;
  final double totalVencido;
  final double totalMora;
  final int cobrosPendientes;
  final int cobrosVencidos;

  // ─── Historial ────────────────────────────────────────
  final double totalPagadoHistorico;
  final int totalCobrosHistoricos;
  final int cobrosPagados;
  final double porcentajeCumplimiento;

  // ─── Pagos ────────────────────────────────────────────
  final int pagosVerificados;
  final int pagosPendientesVerificacion;
  final int pagosRechazados;
  final Map<String, int> pagosPorMetodo;
  final PagoModel? ultimoPago;

  // ─── Próximo vencimiento ──────────────────────────────
  final CobroModel? proximoVencimiento;
  final int? diasParaVencimiento;

  // ─── Mora ─────────────────────────────────────────────
  final int mesesEnMora;

  const ResidenteEstadisticasModel({
    required this.totalPendiente,
    required this.totalVencido,
    required this.totalMora,
    required this.cobrosPendientes,
    required this.cobrosVencidos,
    required this.totalPagadoHistorico,
    required this.totalCobrosHistoricos,
    required this.cobrosPagados,
    required this.porcentajeCumplimiento,
    required this.pagosVerificados,
    required this.pagosPendientesVerificacion,
    required this.pagosRechazados,
    required this.pagosPorMetodo,
    this.ultimoPago,
    this.proximoVencimiento,
    this.diasParaVencimiento,
    required this.mesesEnMora,
  });

  double get totalDeuda => totalPendiente + totalVencido;
  bool get alDia => totalDeuda == 0;
  bool get enMora => cobrosVencidos > 0;
  int get totalPagos =>
      pagosVerificados + pagosPendientesVerificacion + pagosRechazados;

  String get estadoTexto {
    if (alDia) return 'Al día';
    if (enMora) return 'En mora';
    return 'Pendiente';
  }

  /// Construye las estadísticas a partir de las listas de cobros y pagos.
  factory ResidenteEstadisticasModel.fromData({
    required List<CobroModel> todosLosCobros,
    required List<PagoModel> todosLosPagos,
  }) {
    // ── Cobros por estado ──
    final pendientes =
        todosLosCobros.where((c) => c.esPendiente).toList();
    final parciales =
        todosLosCobros.where((c) => c.esParcial).toList();
    final vencidos = todosLosCobros.where((c) => c.esVencido).toList();
    final pagados = todosLosCobros.where((c) => c.esPagado).toList();

    // Los parciales usan montoPendiente (saldo restante), no montoTotal
    final totalPendiente =
        pendientes.fold<double>(0, (s, c) => s + c.montoTotal) +
        parciales.fold<double>(0, (s, c) => s + c.montoPendiente);
    final totalVencido =
        vencidos.fold<double>(0, (s, c) => s + c.montoTotal);
    final totalMora =
        vencidos.fold<double>(0, (s, c) => s + c.montoMora);

    // ── Historial ──
    final totalPagado =
        pagados.fold<double>(0, (s, c) => s + c.montoTotal);
    final totalCobros = todosLosCobros.length;
    final porcentaje =
        totalCobros > 0 ? (pagados.length / totalCobros) * 100 : 100.0;

    // ── Pagos por estado ──
    final pVerificados =
        todosLosPagos.where((p) => p.esVerificado).length;
    final pPendientes =
        todosLosPagos.where((p) => p.esPendiente).length;
    final pRechazados =
        todosLosPagos.where((p) => p.esRechazado).length;

    // ── Distribución por método ──
    final metodos = <String, int>{};
    for (final p in todosLosPagos) {
      metodos[p.metodoPago] = (metodos[p.metodoPago] ?? 0) + 1;
    }

    // ── Último pago ──
    PagoModel? ultimo;
    if (todosLosPagos.isNotEmpty) {
      final ordenados = [...todosLosPagos]
        ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
      ultimo = ordenados.first;
    }

    // ── Próximo vencimiento ──
    CobroModel? proximo;
    int? diasVenc;
    final activos = [...pendientes, ...parciales, ...vencidos];
    if (activos.isNotEmpty) {
      activos.sort(
          (a, b) => a.fechaLimitePago.compareTo(b.fechaLimitePago));
      proximo = activos.first;
      try {
        final fecha = DateTime.parse(proximo.fechaLimitePago);
        diasVenc = fecha.difference(DateTime.now()).inDays;
      } catch (_) {}
    }

    return ResidenteEstadisticasModel(
      totalPendiente: totalPendiente,
      totalVencido: totalVencido,
      totalMora: totalMora,
      cobrosPendientes: pendientes.length + parciales.length,
      cobrosVencidos: vencidos.length,
      totalPagadoHistorico: totalPagado,
      totalCobrosHistoricos: totalCobros,
      cobrosPagados: pagados.length,
      porcentajeCumplimiento: porcentaje,
      pagosVerificados: pVerificados,
      pagosPendientesVerificacion: pPendientes,
      pagosRechazados: pRechazados,
      pagosPorMetodo: metodos,
      ultimoPago: ultimo,
      proximoVencimiento: proximo,
      diasParaVencimiento: diasVenc,
      mesesEnMora: vencidos.length,
    );
  }

  /// Serializa a JSON para persistir en cache local.
  Map<String, dynamic> toJson() => {
        'totalPendiente': totalPendiente,
        'totalVencido': totalVencido,
        'totalMora': totalMora,
        'cobrosPendientes': cobrosPendientes,
        'cobrosVencidos': cobrosVencidos,
        'totalPagadoHistorico': totalPagadoHistorico,
        'totalCobrosHistoricos': totalCobrosHistoricos,
        'cobrosPagados': cobrosPagados,
        'porcentajeCumplimiento': porcentajeCumplimiento,
        'pagosVerificados': pagosVerificados,
        'pagosPendientesVerificacion': pagosPendientesVerificacion,
        'pagosRechazados': pagosRechazados,
        'pagosPorMetodo': pagosPorMetodo,
        if (ultimoPago != null) 'ultimoPago': ultimoPago!.toJson(),
        if (proximoVencimiento != null)
          'proximoVencimiento': proximoVencimiento!.toJson(),
        if (diasParaVencimiento != null)
          'diasParaVencimiento': diasParaVencimiento,
        'mesesEnMora': mesesEnMora,
      };

  /// Deserializa desde cache local (campos ya calculados).
  factory ResidenteEstadisticasModel.fromJson(Map<String, dynamic> json) =>
      ResidenteEstadisticasModel(
        totalPendiente: (json['totalPendiente'] as num).toDouble(),
        totalVencido: (json['totalVencido'] as num).toDouble(),
        totalMora: (json['totalMora'] as num).toDouble(),
        cobrosPendientes: json['cobrosPendientes'] as int,
        cobrosVencidos: json['cobrosVencidos'] as int,
        totalPagadoHistorico: (json['totalPagadoHistorico'] as num).toDouble(),
        totalCobrosHistoricos: json['totalCobrosHistoricos'] as int,
        cobrosPagados: json['cobrosPagados'] as int,
        porcentajeCumplimiento:
            (json['porcentajeCumplimiento'] as num).toDouble(),
        pagosVerificados: json['pagosVerificados'] as int,
        pagosPendientesVerificacion:
            json['pagosPendientesVerificacion'] as int,
        pagosRechazados: json['pagosRechazados'] as int,
        pagosPorMetodo:
            Map<String, int>.from(json['pagosPorMetodo'] as Map),
        ultimoPago: json['ultimoPago'] != null
            ? PagoModel.fromJson(
                json['ultimoPago'] as Map<String, dynamic>)
            : null,
        proximoVencimiento: json['proximoVencimiento'] != null
            ? CobroModel.fromJson(
                json['proximoVencimiento'] as Map<String, dynamic>)
            : null,
        diasParaVencimiento: json['diasParaVencimiento'] as int?,
        mesesEnMora: json['mesesEnMora'] as int,
      );
}
