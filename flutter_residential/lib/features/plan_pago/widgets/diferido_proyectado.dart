import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/utils/format_moneda.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/aviso_card.dart';
import '../models/plan_pago_model.dart';
import '../models/simulacion_acuerdo_model.dart';
import 'cronograma_cuotas.dart';

/// "Diferido en N cuotas" de una solicitud PENDIENTE, con el valor y la fecha
/// de cada cuota si se aprobara hoy.
///
/// Mientras el acuerdo está pendiente sus cuotas no existen: nacen como cobros
/// al aprobar, sobre la deuda de ese día y con vencimientos que corren desde
/// ese día. Por eso se pinta la [proyeccion] del backend (mismo cálculo que la
/// aprobación) rotulada como estimado, y no se calcula nada aquí.
class DiferidoProyectado extends StatelessWidget {
  final PlanPagoModel plan;

  /// null mientras carga o si falló (ver [error]).
  final SimulacionAcuerdoModel? proyeccion;

  /// Motivo por el que no se pudo proyectar (ej.: ya no hay deuda elegible).
  /// Es el mismo que daría el backend al intentar aprobar.
  final String? error;

  const DiferidoProyectado({
    super.key,
    required this.plan,
    this.proyeccion,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final proy = proyeccion;
    final numeroCuotas = proy?.numeroCuotas ?? plan.numeroCuotas;
    final montoDiferido = proy?.montoDiferido ?? plan.montoDiferido;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Diferido en $numeroCuotas cuota${numeroCuotas == 1 ? '' : 's'}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              FormatMoneda.format(montoDiferido),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Estimado si se aprueba hoy · las fechas corren desde la aprobación',
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        if (error != null)
          AvisoCard(
            texto: error!,
            color: AppColors.warning,
            fondo: AppColors.warningSoft,
            icono: Icons.error_outline,
          )
        else
          Skeletonizer(
            enabled: proy == null,
            child: CronogramaCuotas(
              cuotas: (proy ??
                      SimulacionAcuerdoModel.skeleton(
                          numeroCuotas: plan.numeroCuotas))
                  .cuotas,
            ),
          ),
        if (proy != null && _cambioLaDeuda(proy)) ...[
          const SizedBox(height: 8),
          AvisoCard(
            texto: 'Con la deuda de hoy el acuerdo queda en '
                '${FormatMoneda.format(proy.montoTotalAcuerdo)} (se solicitó por '
                '${FormatMoneda.format(plan.montoTotalPlan)}). Las cuotas ya '
                'usan el valor de hoy.',
            color: AppColors.warning,
            fondo: AppColors.warningSoft,
            icono: Icons.info_outline,
          ),
        ],
      ],
    );
  }

  /// Entre la solicitud y hoy pudo correr la mora o entrar un pago; al
  /// aprobar se usa la deuda de hoy. Se compara en pesos enteros.
  bool _cambioLaDeuda(SimulacionAcuerdoModel proy) =>
      (proy.montoTotalAcuerdo - plan.montoTotalPlan).abs() >= 1;
}
