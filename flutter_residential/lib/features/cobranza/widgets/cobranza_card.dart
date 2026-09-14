import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/cobro_cobranza_model.dart';
import '../utils/urgencia_cobranza_ui.dart';

/// Tarjeta de un cobro moroso.
///
/// Muestra lo que el administrador necesita para decidir a quién llamar:
/// propiedad, fase de cartera, qué se debe, cuándo venció y hace cuántos días.
/// La casilla permite armar un envío masivo sin perder el botón "Avisar" de la
/// tarjeta, que sigue sirviendo para el caso de uno en uno.
class CobranzaCard extends StatelessWidget {
  final CobroCobranzaModel cobro;
  final bool seleccionado;
  final VoidCallback onAlternar;
  final VoidCallback? onAvisar;
  final VoidCallback? onDetalle;
  final int diasCritico;

  /// False cuando el usuario no puede enviar avisos: se oculta la casilla y la
  /// tarjeta queda de solo consulta (el backend lo rechazaría con 403 igual).
  final bool seleccionable;

  const CobranzaCard({
    super.key,
    required this.cobro,
    required this.seleccionado,
    required this.onAlternar,
    this.onAvisar,
    this.onDetalle,
    this.diasCritico = 30,
    this.seleccionable = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ui = UrgenciaCobranzaUi.de(cobro, diasCritico: diasCritico);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: seleccionado ? cs.primary.withValues(alpha: 0.06) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: seleccionado ? cs.primary : ui.color.withValues(alpha: 0.45),
          width: seleccionado ? 1.6 : 1.2,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: seleccionable ? onAlternar : onDetalle,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.card),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 12, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (seleccionable)
                    Checkbox(
                      value: seleccionado,
                      onChanged: (_) => onAlternar(),
                      visualDensity: VisualDensity.compact,
                    )
                  else
                    const SizedBox(width: 6),
                  Expanded(child: _datos(context, ui)),
                  const SizedBox(width: 8),
                  _montos(context),
                ],
              ),
            ),
          ),
          _acciones(context, ui),
        ],
      ),
    );
  }

  Widget _datos(BuildContext context, UrgenciaCobranzaUi ui) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cobro.propiedadPathCorto.isEmpty
              ? cobro.propiedadIdentificador
              : '${cobro.propiedadPathCorto}  ·  ${cobro.propiedadIdentificador}',
          style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Text(
                cobro.conceptoLabel,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
            if (cobro.migrado) ...[
              const SizedBox(width: 6),
              _Etiqueta(
                texto: 'Cartera anterior',
                color: cs.onSurfaceVariant,
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(ui.icono, size: 13, color: ui.color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '${cobro.etiquetaVencimiento}  ·  ${cobro.fechaLimiteCorta}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: ui.color,
                ),
              ),
            ),
          ],
        ),
        if (cobro.tieneFase) ...[
          const SizedBox(height: 6),
          _FaseChip(nombre: cobro.faseNombre!, hex: cobro.faseColor),
        ],
      ],
    );
  }

  Widget _montos(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          CurrencyFormatter.cop(cobro.montoPendiente),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        if (cobro.enMora)
          Text(
            'Mora ${CurrencyFormatter.cop(cobro.montoMora)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.orange,
            ),
          ),
      ],
    );
  }

  Widget _acciones(BuildContext context, UrgenciaCobranzaUi ui) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onDetalle != null)
            TextButton.icon(
              onPressed: onDetalle,
              icon: const Icon(Icons.receipt_long_outlined, size: 16),
              label: const Text('Detalle', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          if (onAvisar != null) ...[
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: onAvisar,
              icon: const Icon(Icons.notifications_active_outlined, size: 16),
              label: const Text('Avisar', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: ui.color,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FaseChip extends StatelessWidget {
  final String nombre;
  final String? hex;

  const _FaseChip({required this.nombre, this.hex});

  @override
  Widget build(BuildContext context) {
    final color = _colorDeHex(hex, Theme.of(context).colorScheme.outline);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            nombre,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  /// Mismo criterio que `CarteraLabels.colorDeHex`, sin arrastrar la
  /// dependencia del módulo de configuración de cartera hasta la tarjeta.
  static Color _colorDeHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    var h = hex.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    final value = int.tryParse(h, radix: 16);
    return value != null ? Color(value) : fallback;
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color color;

  const _Etiqueta({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }
}
