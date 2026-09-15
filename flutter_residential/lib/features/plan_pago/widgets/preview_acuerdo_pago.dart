import 'package:flutter/material.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/format_moneda.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/plan_pago_model.dart';
import '../models/simulacion_acuerdo_model.dart';

/// Desglose del acuerdo: deuda, recargo, abono inicial y cuotas diferidas.
///
/// Un solo widget para los dos momentos en que hay que mostrar lo mismo: la
/// previsualización del residente (antes de comprometerse) y la revisión del
/// admin (antes de aprobar). Los datos siempre vienen calculados del backend;
/// este widget no hace aritmética de montos, solo los pinta.
class PreviewAcuerdoPago extends StatelessWidget {
  final double montoDeuda;
  final int cantidadCobros;
  final bool aplicaRecargo;
  final double porcentajeRecargo;
  final double montoRecargo;
  final double montoTotalAcuerdo;
  final double porcentajeAbonoInicial;
  final double montoAbonoInicial;
  final int diasGraciaInicial;
  final String fechaLimiteAbonoInicial;
  final double montoDiferido;
  final int numeroCuotas;
  final List<_FilaCuota> _cuotas;
  final bool moraCongelada;

  const PreviewAcuerdoPago._({
    required this.montoDeuda,
    required this.cantidadCobros,
    required this.aplicaRecargo,
    required this.porcentajeRecargo,
    required this.montoRecargo,
    required this.montoTotalAcuerdo,
    required this.porcentajeAbonoInicial,
    required this.montoAbonoInicial,
    required this.diasGraciaInicial,
    required this.fechaLimiteAbonoInicial,
    required this.montoDiferido,
    required this.numeroCuotas,
    required List<_FilaCuota> cuotas,
    required this.moraCongelada,
  }) : _cuotas = cuotas;

  /// Previsualización antes de solicitar.
  factory PreviewAcuerdoPago.deSimulacion(SimulacionAcuerdoModel s) =>
      PreviewAcuerdoPago._(
        montoDeuda: s.montoDeuda,
        cantidadCobros: s.cantidadCobros,
        aplicaRecargo: s.aplicaRecargo,
        porcentajeRecargo: s.porcentajeRecargo,
        montoRecargo: s.montoRecargo,
        montoTotalAcuerdo: s.montoTotalAcuerdo,
        porcentajeAbonoInicial: s.porcentajeAbonoInicial,
        montoAbonoInicial: s.montoAbonoInicial,
        diasGraciaInicial: s.diasGraciaInicial,
        fechaLimiteAbonoInicial: s.fechaLimiteAbonoInicial,
        montoDiferido: s.montoDiferido,
        numeroCuotas: s.numeroCuotas,
        cuotas: s.cuotas
            .map((c) => _FilaCuota(c.numero, c.monto, c.fechaVencimiento))
            .toList(),
        moraCongelada: s.moraCongelada,
      );

  /// Condiciones de un acuerdo ya creado (bandeja del admin, detalle).
  factory PreviewAcuerdoPago.deAcuerdo(PlanPagoModel p) => PreviewAcuerdoPago._(
        montoDeuda: p.montoTotalDeuda,
        cantidadCobros: (p.cobrosIncluidos ?? '').isEmpty
            ? 0
            : p.cobrosIncluidos!.split(',').length,
        aplicaRecargo: p.montoRecargo > 0,
        porcentajeRecargo: p.porcentajeRecargo,
        montoRecargo: p.montoRecargo,
        montoTotalAcuerdo: p.montoTotalPlan,
        porcentajeAbonoInicial: p.porcentajeAbonoInicial,
        montoAbonoInicial: p.montoAbonoInicial,
        diasGraciaInicial: p.diasGraciaInicial,
        fechaLimiteAbonoInicial: p.fechaLimiteInicial ?? '',
        montoDiferido: p.montoDiferido,
        numeroCuotas: p.numeroCuotas,
        cuotas: p.cuotasDiferidas
            .map((c) => _FilaCuota(
                c.numeroCuota ?? 0, c.monto, c.fechaLimitePago ?? ''))
            .toList(),
        moraCongelada: false,
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Deuda y total ────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _Fila(
                'Deuda a reestructurar',
                FormatMoneda.format(montoDeuda),
                sub: cantidadCobros > 0
                    ? '$cantidadCobros cobro${cantidadCobros == 1 ? '' : 's'}'
                    : null,
              ),
              if (aplicaRecargo && montoRecargo > 0)
                _Fila(
                  'Recargo por fraccionar (${_pct(porcentajeRecargo)})',
                  FormatMoneda.format(montoRecargo),
                  color: AppColors.warning,
                ),
              const Divider(height: 18),
              _Fila('Total del acuerdo', FormatMoneda.format(montoTotalAcuerdo),
                  bold: true),
            ],
          ),
        ),

        // ── Abono inicial ────────────────────────────────────
        if (montoAbonoInicial > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgBlue,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.blue.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payments_outlined,
                        size: 16, color: AppColors.blue),
                    const SizedBox(width: 6),
                    Text(
                      'Pago inicial (${_pct(porcentajeAbonoInicial)})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  FormatMoneda.format(montoAbonoInicial),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  diasGraciaInicial == 0
                      ? 'Se paga el mismo día en que se aprueba el acuerdo'
                      : 'Tienes $diasGraciaInicial día(s) para pagarlo'
                          '${fechaLimiteAbonoInicial.isEmpty ? '' : ' — hasta el ${DateFormatter.fecha(fechaLimiteAbonoInicial)}'}',
                  style: const TextStyle(fontSize: 11, color: AppColors.blue),
                ),
              ],
            ),
          ),
        ],

        // ── Saldo diferido ───────────────────────────────────
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Fila(
                'Saldo diferido',
                FormatMoneda.format(montoDiferido),
                bold: true,
                sub: 'en $numeroCuotas cuota${numeroCuotas == 1 ? '' : 's'}',
              ),
              const SizedBox(height: 8),
              ..._cuotas.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cuota ${c.numero}  ·  ${DateFormatter.fecha(c.fecha)}',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                        Text(
                          FormatMoneda.format(c.monto),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )),
              if (moraCongelada) ...[
                const SizedBox(height: 8),
                Text(
                  'La mora queda congelada mientras el acuerdo esté vigente',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 40.00 -> "40%", 5.50 -> "5.5%"
  static String _pct(double v) {
    final s = v.toStringAsFixed(2);
    return '${s.endsWith('.00') ? s.substring(0, s.length - 3) : s.replaceAll(RegExp(r'0$'), '')}%';
  }
}

class _FilaCuota {
  final int numero;
  final double monto;
  final String fecha;
  const _FilaCuota(this.numero, this.monto, this.fecha);
}

class _Fila extends StatelessWidget {
  final String label;
  final String valor;
  final String? sub;
  final Color? color;
  final bool bold;

  const _Fila(this.label, this.valor, {this.sub, this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                if (sub != null)
                  Text(sub!,
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: color ?? cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
