import '../../../core/utils/format_moneda.dart';
import '../models/plan_pago_model.dart';
import '../models/simulacion_acuerdo_model.dart';

/// Reglas y textos de la proyección de una solicitud PENDIENTE (lo que se
/// generaría si se aprobara hoy). Los comparten la pantalla de detalle y el
/// PDF para que digan exactamente lo mismo.
class ProyeccionAcuerdoUi {
  ProyeccionAcuerdoUi._();

  static const String rotulo =
      'Estimado si se aprueba hoy · las fechas corren desde la aprobación';

  /// Fecha límite del pago inicial a mostrar. En una solicitud pendiente la
  /// guardada se calculó el día de la solicitud; la real corre desde la
  /// aprobación, así que se usa la de la proyección (null mientras no llega).
  static String? fechaLimiteAbono(
          PlanPagoModel plan, SimulacionAcuerdoModel? proyeccion) =>
      plan.esPendiente
          ? proyeccion?.fechaLimiteAbonoInicial
          : plan.fechaLimiteInicial;

  /// Entre la solicitud y hoy pudo correr la mora o entrar un pago; al
  /// aprobar se usa la deuda de hoy. Se compara en pesos enteros.
  static bool cambioLaDeuda(
          PlanPagoModel plan, SimulacionAcuerdoModel proyeccion) =>
      (proyeccion.montoTotalAcuerdo - plan.montoTotalPlan).abs() >= 1;

  static String textoCambioDeuda(
          PlanPagoModel plan, SimulacionAcuerdoModel proyeccion) =>
      'Con la deuda de hoy el acuerdo queda en '
      '${FormatMoneda.format(proyeccion.montoTotalAcuerdo)} (se solicitó por '
      '${FormatMoneda.format(plan.montoTotalPlan)}). Las cuotas ya usan el '
      'valor de hoy.';
}
