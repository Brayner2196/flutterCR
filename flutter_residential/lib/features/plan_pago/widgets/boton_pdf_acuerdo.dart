import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/boton_exportar_pdf.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/plan_pago_model.dart';
import '../models/simulacion_acuerdo_model.dart';
import '../pdf/acuerdo_pago_pdf.dart';

/// Botón de AppBar que exporta un acuerdo de pago a PDF.
///
/// Lo usan el detalle del admin y "Mi acuerdo de pago" del residente: aquí se
/// resuelve el nombre del conjunto y el nombre del archivo para que las
/// pantallas solo pongan `BotonPdfAcuerdo(plan: plan)`.
class BotonPdfAcuerdo extends StatelessWidget {
  final PlanPagoModel plan;

  /// Cronograma estimado de una solicitud pendiente. Solo lo tiene el admin
  /// (detalle); sin ella el PDF de una pendiente no trae fechas de cuotas.
  final SimulacionAcuerdoModel? proyeccion;

  const BotonPdfAcuerdo({super.key, required this.plan, this.proyeccion});

  @override
  Widget build(BuildContext context) {
    final conjunto =
        context.select<AuthProvider, String?>((a) => a.nombreConjunto) ??
            'Conjunto Residencial';

    return BotonExportarPdf(
      nombreArchivo: AcuerdoPagoPdf.nombreArchivo(plan),
      textoCompartir:
          'Acuerdo de pago #${plan.id} — ${plan.propiedadIdentificador}',
      generar: () => AcuerdoPagoPdf.generar(
        plan,
        conjunto: conjunto,
        proyeccion: proyeccion,
      ),
    );
  }
}
