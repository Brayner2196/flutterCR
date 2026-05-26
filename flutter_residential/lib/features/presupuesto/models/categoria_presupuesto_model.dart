import 'gasto_registrado_model.dart';

class CategoriaPresupuestoModel {
  final int id;
  final int presupuestoId;
  final String nombre;
  final String? descripcion;
  final double montoAsignado;
  final double montoEjecutado;
  final double montoPendiente;
  final double porcentajeEjecucion;
  final String? color;
  final String? icono;
  final List<GastoRegistradoModel> gastos;

  const CategoriaPresupuestoModel({
    required this.id,
    required this.presupuestoId,
    required this.nombre,
    this.descripcion,
    required this.montoAsignado,
    required this.montoEjecutado,
    required this.montoPendiente,
    required this.porcentajeEjecucion,
    this.color,
    this.icono,
    this.gastos = const [],
  });

  /// Verdadero si el gasto ejecutado supera el presupuesto asignado
  bool get excedida => montoEjecutado > montoAsignado;

  factory CategoriaPresupuestoModel.fromJson(Map<String, dynamic> j) =>
      CategoriaPresupuestoModel(
        id: j['id'] as int,
        presupuestoId: j['presupuestoId'] as int,
        nombre: j['nombre'] as String,
        descripcion: j['descripcion'] as String?,
        montoAsignado: (j['montoAsignado'] as num).toDouble(),
        montoEjecutado: (j['montoEjecutado'] as num).toDouble(),
        montoPendiente: (j['montoPendiente'] as num).toDouble(),
        porcentajeEjecucion: (j['porcentajeEjecucion'] as num).toDouble(),
        color: j['color'] as String?,
        icono: j['icono'] as String?,
        gastos: (j['gastos'] as List<dynamic>? ?? [])
            .map((e) => GastoRegistradoModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
