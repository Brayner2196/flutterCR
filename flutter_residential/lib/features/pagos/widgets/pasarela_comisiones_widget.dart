import 'package:flutter/material.dart';
import '../models/pasarela_disponible_model.dart';

// ─── Modelo de tarifa ─────────────────────────────────────────────────────────

class TarifaItem {
  final String metodo;
  final String tarifa;
  final String? detalle;
  final IconData icono;

  const TarifaItem({
    required this.metodo,
    required this.tarifa,
    this.detalle,
    required this.icono,
  });
}

// ─── Datos oficiales de tarifas ───────────────────────────────────────────────
// Fuentes: mercadopago.com.co/ayuda, wompi.com/es/co/planes-tarifas, bold.co/tarifas

const Map<TipoPasarela, List<TarifaItem>> tarifasPorPasarela = {
  TipoPasarela.mercadoPago: [
    TarifaItem(
      metodo: 'Tarjeta (recibir ya)',
      tarifa: '3.29% + \$800 + IVA',
      detalle: 'Acreditación inmediata',
      icono: Icons.credit_card,
    ),
    TarifaItem(
      metodo: 'Tarjeta (7 días)',
      tarifa: '2.99% + \$800 + IVA',
      detalle: 'Crédito y débito Visa / MC / Amex',
      icono: Icons.credit_card_outlined,
    ),
    TarifaItem(
      metodo: 'Tarjeta (14 días)',
      tarifa: '2.79% + \$800 + IVA',
      detalle: 'Tarifa más baja, liberación diferida',
      icono: Icons.credit_card_outlined,
    ),
    TarifaItem(
      metodo: 'PSE',
      tarifa: '2.99% + \$900',
      detalle: 'Transferencia bancaria directa',
      icono: Icons.account_balance_outlined,
    ),
    TarifaItem(
      metodo: 'Efecty / Baloto',
      tarifa: '2.99% + \$900',
      detalle: 'Pago en efectivo en puntos físicos',
      icono: Icons.store_outlined,
    ),
    TarifaItem(
      metodo: 'Nequi / Daviplata',
      tarifa: 'Sin costo adicional',
      detalle: 'Incluida en tarifa de tarjeta',
      icono: Icons.phone_android,
    ),
  ],
  TipoPasarela.wompi: [
    TarifaItem(
      metodo: 'Tarjetas Visa / MC / Amex',
      tarifa: '1.99% + IVA',
      detalle: 'Crédito y débito (plan estándar)',
      icono: Icons.credit_card,
    ),
    TarifaItem(
      metodo: 'Nequi / Bancolombia',
      tarifa: '1.50% + IVA',
      detalle: 'Billeteras digitales y app Bancolombia',
      icono: Icons.phone_android,
    ),
    TarifaItem(
      metodo: 'PSE (otros bancos)',
      tarifa: '2.69% + IVA',
      detalle: 'Transferencia desde cualquier banco',
      icono: Icons.account_balance_outlined,
    ),
    TarifaItem(
      metodo: 'Tarjetas (plan avanzado)',
      tarifa: '2.65% + \$700 + IVA',
      detalle: 'Plan con mayor control y funcionalidades',
      icono: Icons.credit_card_outlined,
    ),
    TarifaItem(
      metodo: 'Bancolombia QR',
      tarifa: '0.99% + IVA',
      detalle: 'Pago con QR de la app Bancolombia',
      icono: Icons.qr_code_outlined,
    ),
  ],
  TipoPasarela.bold: [
    TarifaItem(
      metodo: 'Link de pago',
      tarifa: '3.29% + \$900',
      detalle: 'Incluye retenciones de ley',
      icono: Icons.link,
    ),
    TarifaItem(
      metodo: 'PSE',
      tarifa: '2.89% + \$300',
      detalle: 'Sin retenciones de impuestos',
      icono: Icons.account_balance_outlined,
    ),
    TarifaItem(
      metodo: 'Nequi',
      tarifa: '1.50%',
      detalle: 'Sin retenciones de impuestos de ley',
      icono: Icons.phone_android,
    ),
    TarifaItem(
      metodo: 'Código QR',
      tarifa: 'Sin comisión',
      detalle: 'Pagos con QR en el punto de venta',
      icono: Icons.qr_code_outlined,
    ),
    TarifaItem(
      metodo: 'Tarjetas internacionales',
      tarifa: '+1% sobre tarifa base',
      detalle: 'Recargo adicional aplicado',
      icono: Icons.language_outlined,
    ),
  ],
};

const Map<TipoPasarela, Color> colorPorPasarela = {
  TipoPasarela.mercadoPago: Color(0xFF009EE3),
  TipoPasarela.wompi:       Color(0xFF00C896),
  TipoPasarela.bold:        Color(0xFF5B2D8E),
};

const Map<TipoPasarela, String> urlOficialPorPasarela = {
  TipoPasarela.mercadoPago: 'mercadopago.com.co/ayuda/costos-recibir-pagos-checkout_33399',
  TipoPasarela.wompi:       'wompi.com/es/co/planes-tarifas',
  TipoPasarela.bold:        'bold.co/tarifas',
};

// ─── Widget inline (para embeber dentro de un Card) ───────────────────────────

/// Sección expandible que se coloca dentro del card de una pasarela.
/// Muestra las tarifas oficiales de comisión en forma de lista desplegable.
class PasarelaComisionesInline extends StatefulWidget {
  final TipoPasarela tipo;

  const PasarelaComisionesInline({super.key, required this.tipo});

  @override
  State<PasarelaComisionesInline> createState() =>
      _PasarelaComisionesInlineState();
}

class _PasarelaComisionesInlineState extends State<PasarelaComisionesInline>
    with SingleTickerProviderStateMixin {
  bool _expandido = false;
  late AnimationController _ctrl;
  late Animation<double> _rotacion;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _rotacion = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expandido = !_expandido);
    _expandido ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final cs     = theme.colorScheme;
    final color  = colorPorPasarela[widget.tipo]!;
    final items  = tarifasPorPasarela[widget.tipo]!;
    final urlRef = urlOficialPorPasarela[widget.tipo]!;

    return Column(
      children: [
        // ── Divider + botón disparador ─────────────────────────────────
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.6)),
        InkWell(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.percent_rounded, size: 15, color: color),
                const SizedBox(width: 7),
                Text(
                  'Ver tarifas de comisión',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                RotationTransition(
                  turns: _rotacion,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Panel expandible ───────────────────────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: _expandido
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            child: Column(
              children: [
                // Filas de tarifas
                ...items.asMap().entries.map((e) {
                  final isLast = e.key == items.length - 1;
                  final item   = e.value;
                  final isGratis = item.tarifa.toLowerCase().contains('sin') ||
                      item.tarifa.toLowerCase().contains('gratis');
                  return _TarifaFila(
                    item: item,
                    color: color,
                    isGratis: isGratis,
                    isLast: isLast,
                    cs: cs,
                    theme: theme,
                  );
                }),
                // Disclaimer + enlace fuente
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(10),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: color.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 11,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Tarifas referenciales sujetas a cambio. '
                                'Consulta condiciones vigentes en ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                            children: [
                              TextSpan(
                                text: urlRef,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: color,
                                  fontStyle: FontStyle.italic,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─── Fila individual de tarifa ────────────────────────────────────────────────

class _TarifaFila extends StatelessWidget {
  final TarifaItem item;
  final Color color;
  final bool isGratis;
  final bool isLast;
  final ColorScheme cs;
  final ThemeData theme;

  const _TarifaFila({
    required this.item,
    required this.color,
    required this.isGratis,
    required this.isLast,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: color.withValues(alpha: 0.1),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(item.icono, size: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.metodo,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                if (item.detalle != null)
                  Text(
                    item.detalle!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isGratis
                  ? Colors.green.withValues(alpha: 0.12)
                  : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.tarifa,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isGratis ? Colors.green.shade700 : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widget standalone (para el wizard) ──────────────────────────────────────

/// Muestra tarifas de todas las pasarelas como panel colapsable independiente.
/// Usado en el wizard de creación de tenant.
class PasarelaComisionesWidget extends StatefulWidget {
  final List<TipoPasarela>? pasarelas;
  final String? titulo;

  const PasarelaComisionesWidget({
    super.key,
    this.pasarelas,
    this.titulo,
  });

  @override
  State<PasarelaComisionesWidget> createState() =>
      _PasarelaComisionesWidgetState();
}

class _PasarelaComisionesWidgetState extends State<PasarelaComisionesWidget> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final lista = widget.pasarelas ?? TipoPasarela.values;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.percent_rounded,
                      size: 17,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.titulo ?? 'Tarifas de comisión vigentes',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.amber.shade800,
                          ),
                        ),
                        Text(
                          _expandido
                              ? 'Toca para ocultar'
                              : 'Toca para ver cobros por método de pago',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expandido
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.amber.shade700,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (_expandido) ...[
            Divider(height: 1, color: Colors.amber.withValues(alpha: 0.3)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: lista
                    .map(
                      (tipo) => _StandaloneGatewayCard(tipo: tipo),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StandaloneGatewayCard extends StatelessWidget {
  final TipoPasarela tipo;
  const _StandaloneGatewayCard({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final color = colorPorPasarela[tipo]!;
    final items = tarifasPorPasarela[tipo]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Text(
              tipo.nombreLegible,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          ...items.asMap().entries.map((e) {
            final isGratis = e.value.tarifa.toLowerCase().contains('sin') ||
                e.value.tarifa.toLowerCase().contains('gratis');
            return _TarifaFila(
              item: e.value,
              color: color,
              isGratis: isGratis,
              isLast: e.key == items.length - 1,
              cs: cs,
              theme: theme,
            );
          }),
        ],
      ),
    );
  }
}
