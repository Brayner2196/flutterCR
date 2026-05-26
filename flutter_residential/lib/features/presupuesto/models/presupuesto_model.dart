import 'categoria_presupuesto_model.dart';

class PresupuestoModel {
  final int id;
  final int anio;
  final String? titulo;
  final double montoTotalPresupuestado;
  final double montoTotalEjecutado;
  final double montoTotalPendiente;
  final double porcentajeEjecucionGeneral;
  final bool activo;
  final String? creadoEn;
  final String? actualizadoEn;
  final List<CategoriaPresupuestoModel> categorias;

  const PresupuestoModel({
    required this.id,
    required this.anio,
    this.titulo,
    required this.montoTotalPresupuestado,
    required this.montoTotalEjecutado,
    required this.montoTotalPendiente,
    required this.porcentajeEjecucionGeneral,
    required this.activo,
    this.creadoEn,
    this.actualizadoEn,
    this.categorias = const [],
  });

  /// true si alguna categoría está excedida
  bool get tieneExcedidos => categorias.any((c) => c.excedida);

  factory PresupuestoModel.fromJson(Map<String, dynamic> j) => PresupuestoModel(
        id: j['id'] as int,
        anio: j['anio'] as int,
        titulo: j['titulo'] as String?,
        montoTotalPresupuestado: (j['montoTotalPresupuestado'] as num).toDouble(),
        montoTotalEjecutado: (j['montoTotalEjecutado'] as num).toDouble(),
        montoTotalPendiente: (j['montoTotalPendiente'] as num).toDouble(),
        porcentajeEjecucionGeneral: (j['porcentajeEjecucionGeneral'] as num).toDouble(),
        activo: j['activo'] as bool? ?? false,
        creadoEn: j['creadoEn'] as String?,
        actualizadoEn: j['actualizadoEn'] as String?,
        categorias: (j['categorias'] as List<dynamic>? ?? [])
            .map((e) => CategoriaPresupuestoModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
