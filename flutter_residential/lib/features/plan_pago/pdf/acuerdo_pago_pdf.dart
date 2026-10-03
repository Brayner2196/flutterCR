import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/format_moneda.dart';
import '../../../shared/pdf/pdf_base.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/cobro_acuerdo_model.dart';
import '../models/plan_pago_model.dart';
import '../utils/estado_acuerdo_ui.dart';

/// Convierte el detalle de un acuerdo de pago en un PDF.
///
/// Solo pinta lo que trae [PlanPagoModel]: no recalcula montos, porque el
/// cálculo vive en el backend (CalculadoraAcuerdoPago) y el PDF debe decir lo
/// mismo que la pantalla.
///
/// Es puro (sin BuildContext ni providers): recibe el modelo y devuelve bytes.
/// Así lo usan igual la vista del admin y la del residente, y se puede probar
/// sin levantar widgets.
class AcuerdoPagoPdf {
  AcuerdoPagoPdf._();

  /// Ej.: "acuerdo_pago_15_Torre_2_Apto_301.pdf".
  static String nombreArchivo(PlanPagoModel plan) {
    final propiedad = plan.propiedadIdentificador
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return propiedad.isEmpty
        ? 'acuerdo_pago_${plan.id}.pdf'
        : 'acuerdo_pago_${plan.id}_$propiedad.pdf';
  }

  static Future<Uint8List> generar(
    PlanPagoModel plan, {
    required String conjunto,
  }) async {
    final tema = await PdfBase.tema();
    final logo = await PdfBase.logo();
    final generadoEl =
        DateFormatter.fechaHoraMinAmPm(DateTime.now().toUtc().toIso8601String());
    final (fondoEstado, colorEstado) = EstadoAcuerdoUi.colores(plan.estado);

    final doc = pw.Document(
      title: 'Acuerdo de pago #${plan.id}',
      author: conjunto,
      creator: 'My CR',
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 28),
          theme: tema,
        ),
        header: (_) => PdfBase.encabezado(
          logo: logo,
          organizacion: conjunto,
          titulo: 'Acuerdo de pago #${plan.id}',
          etiqueta: PdfBase.chip(
            plan.estadoLegible,
            fondo: PdfBase.color(fondoEstado),
            color: PdfBase.color(colorEstado),
          ),
        ),
        footer: (ctx) => PdfBase.pie(
          ctx,
          nota: 'Generado el $generadoEl. Documento informativo: los saldos '
              'corresponden a esa fecha y cambian con cada pago.',
        ),
        build: (_) => [
          _datos(plan),
          ..._resumen(plan),
          if (plan.cobros.isNotEmpty) ...[
            ..._seguimiento(plan),
            ..._cronograma(plan.cobros),
          ] else if (plan.esPendiente)
            ..._sinCobros(),
          ..._notas(plan),
        ],
      ),
    );

    return doc.save();
  }

  // ── Secciones ──────────────────────────────────────────────────────────────

  static pw.Widget _datos(PlanPagoModel plan) => PdfBase.rejillaDatos([
        ('Residente', plan.residenteNombre),
        ('Propiedad', plan.propiedadIdentificador),
        ('Solicitado el', DateFormatter.fechaHoraMinAmPm(plan.creadoEn)),
        if (plan.fechaDecision != null)
          ('Fecha de decisión', DateFormatter.fechaHoraMinAmPm(plan.fechaDecision)),
        if (plan.fechaIncumplimiento != null)
          ('Incumplido el', DateFormatter.fechaHoraMinAmPm(plan.fechaIncumplimiento)),
      ]);

  static List<pw.Widget> _resumen(PlanPagoModel plan) => [
        PdfBase.tituloSeccion('Resumen financiero'),
        PdfBase.caja([
          PdfBase.filaDato(
              'Deuda total', FormatMoneda.format(plan.montoTotalDeuda)),
          if (plan.montoRecargo > 0)
            PdfBase.filaDato(
              'Recargo por fraccionamiento (${_pct(plan.porcentajeRecargo)})',
              FormatMoneda.format(plan.montoRecargo),
              color: PdfBase.color(AppColors.warning),
            ),
          PdfBase.filaDato(
            'Total del acuerdo',
            FormatMoneda.format(plan.montoTotalPlan),
            negrita: true,
          ),
          PdfBase.divisor(),
          if (plan.exigeAbonoInicial)
            PdfBase.filaDato(
              _etiquetaAbono(plan),
              FormatMoneda.format(plan.montoAbonoInicial),
              color: PdfBase.primario,
            ),
          PdfBase.filaDato(
            'Diferido en ${plan.numeroCuotas} '
            'cuota${plan.numeroCuotas == 1 ? '' : 's'}',
            FormatMoneda.format(plan.montoDiferido),
          ),
        ]),
      ];

  static List<pw.Widget> _seguimiento(PlanPagoModel plan) => [
        PdfBase.tituloSeccion('Seguimiento'),
        PdfBase.caja([
          PdfBase.barraProgreso(plan.progreso),
          pw.SizedBox(height: 8),
          PdfBase.filaDato(
            'Pagado',
            FormatMoneda.format(plan.montoPagadoAcuerdo),
            color: PdfBase.color(AppColors.ok),
          ),
          PdfBase.filaDato(
            'Saldo pendiente',
            FormatMoneda.format(plan.saldoPendienteAcuerdo),
            negrita: true,
          ),
          PdfBase.filaDato(
            'Cuotas pagadas',
            '${plan.cuotasPagadas} de ${plan.numeroCuotas}',
          ),
        ]),
      ];

  static List<pw.Widget> _cronograma(List<CobroAcuerdoModel> cobros) {
    final hayVencidos = cobros.any((c) => c.vencido);
    return [
      PdfBase.tituloSeccion('Cronograma de pagos'),
      PdfBase.tabla(
        encabezados: const [
          'Concepto',
          'Vence',
          'Valor',
          'Pagado',
          'Pendiente',
          'Estado',
        ],
        anchos: {
          0: pw.FlexColumnWidth(2.1),
          1: pw.FlexColumnWidth(2),
          2: pw.FlexColumnWidth(2),
          3: pw.FlexColumnWidth(2),
          4: pw.FlexColumnWidth(2),
          5: pw.FlexColumnWidth(2),
        },
        alinearDerecha: const {2, 3, 4},
        filas: [
          for (final c in cobros)
            [
              c.titulo,
              DateFormatter.fecha(c.fechaLimitePago),
              FormatMoneda.format(c.monto),
              FormatMoneda.format(c.montoPagado),
              FormatMoneda.format(c.montoPendiente),
              c.estadoLegible,
            ],
        ],
        fondoFila: (i) => cobros[i].vencido
            ? PdfBase.color(AppColors.warningSoft)
            : null,
      ),
      if (hayVencidos)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Text(
            'Las filas resaltadas están vencidas.',
            style: PdfBase.estilo(tamano: 8, color: PdfBase.colorTextoSuave),
          ),
        ),
    ];
  }

  static List<pw.Widget> _sinCobros() => [
        PdfBase.tituloSeccion('Cronograma de pagos'),
        pw.Text(
          'Los cobros del acuerdo se generan cuando la administración lo aprueba.',
          style: PdfBase.estilo(color: PdfBase.colorTextoSuave),
        ),
      ];

  static List<pw.Widget> _notas(PlanPagoModel plan) => [
        if (_tieneTexto(plan.observaciones))
          PdfBase.bloqueTexto('Observaciones', plan.observaciones!),
        if (_tieneTexto(plan.motivoRechazo))
          PdfBase.bloqueTexto(
            'Motivo del rechazo',
            plan.motivoRechazo!,
            fondo: PdfBase.color(AppColors.dangerSoft),
            colorTitulo: PdfBase.color(AppColors.danger),
          ),
        if (_tieneTexto(plan.notaAdmin))
          PdfBase.bloqueTexto('Nota de la administración', plan.notaAdmin!),
      ];

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// "Pago inicial (30% de la deuda) — hasta el 15 oct 2026". La base de
  /// cálculo solo se aclara cuando hay recargo, que es cuando cambia algo.
  static String _etiquetaAbono(PlanPagoModel plan) {
    final base = plan.montoRecargo <= 0
        ? ''
        : plan.baseCalculoAbono == 'DEUDA_MAS_RECARGO'
            ? ' de deuda + recargo'
            : ' de la deuda';
    final limite = plan.fechaLimiteInicial == null
        ? ''
        : ' — hasta el ${DateFormatter.fecha(plan.fechaLimiteInicial)}';
    return 'Pago inicial (${_pct(plan.porcentajeAbonoInicial)}$base)$limite';
  }

  /// 30 → "30%", 2.5 → "2.5%".
  static String _pct(double v) =>
      '${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1)}%';

  static bool _tieneTexto(String? s) => s != null && s.trim().isNotEmpty;
}
