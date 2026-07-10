import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/publicacion_model.dart';
import '../../services/solicitud_service.dart';

/// BottomSheet de confirmación de pedido.
/// [tipo] DOMICILIO | RECOGIDA
class ConfirmarPedidoSheet extends StatefulWidget {
  final PublicacionModel publicacion;
  final String tipo;

  const ConfirmarPedidoSheet({
    super.key,
    required this.publicacion,
    required this.tipo,
  });

  static Future<bool?> mostrar(
    BuildContext context, {
    required PublicacionModel publicacion,
    required String tipo,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConfirmarPedidoSheet(publicacion: publicacion, tipo: tipo),
    );
  }

  @override
  State<ConfirmarPedidoSheet> createState() => _ConfirmarPedidoSheetState();
}

class _ConfirmarPedidoSheetState extends State<ConfirmarPedidoSheet> {
  int _cantidad = 1;
  final _notasCtrl = TextEditingController();
  bool _enviando = false;

  bool get esDomicilio => widget.tipo == 'DOMICILIO';
  PublicacionModel get pub => widget.publicacion;

  int get _maxCantidad => pub.stock ?? 99;
  double get _total => pub.precio * _cantidad;

  String get _totalFormateado =>
      '\$${_total.toStringAsFixed(_total.truncateToDouble() == _total ? 0 : 2)}';

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    try {
      await SolicitudService.crear(
        publicacionId: pub.id,
        tipo: widget.tipo,
        cantidad: _cantidad,
        notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Encabezado ────────────────────────────────────────
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: esDomicilio ? AppColors.bgBlue : AppColors.bgTeal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      esDomicilio
                          ? Icons.delivery_dining_outlined
                          : Icons.storefront_outlined,
                      size: 14,
                      color: esDomicilio ? AppColors.blue : AppColors.teal,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      esDomicilio ? 'A domicilio' : 'Recogida en punto',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: esDomicilio ? AppColors.blue : AppColors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            'Confirmar pedido',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            pub.titulo,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // ── Selector de cantidad ──────────────────────────────
          Row(
            children: [
              Text('Cantidad',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: cs.onSurface)),
              const Spacer(),
              _CantidadControl(
                cantidad: _cantidad,
                max: _maxCantidad,
                onChanged: (v) => setState(() => _cantidad = v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Notas ─────────────────────────────────────────────
          TextField(
            controller: _notasCtrl,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText:
                  'Notas para el vendedor (opcional)\nEj: sin azúcar, dejar en portería…',
              hintStyle:
                  TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              isDense: true,
            ),
          ),
          const SizedBox(height: 20),

          // ── Resumen de precio ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _ResumenRow(
                  label: 'Precio unitario',
                  valor: pub.precioFormateado,
                ),
                const SizedBox(height: 6),
                _ResumenRow(
                  label: 'Cantidad',
                  valor: '$_cantidad',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _ResumenRow(
                  label: 'Total estimado',
                  valor: _totalFormateado,
                  destacado: true,
                  color: cs.primary,
                ),
              ],
            ),
          ),

          if (pub.metodosPago.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Métodos de pago aceptados',
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: pub.metodosPago
                  .map((m) => _MetodoPagoChip(metodo: m))
                  .toList(),
            ),
          ],

          const SizedBox(height: 20),

          // ── Botón enviar ──────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              icon: _enviando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(esDomicilio
                      ? Icons.delivery_dining_outlined
                      : Icons.storefront_outlined),
              label: Text(_enviando
                  ? 'Enviando…'
                  : esDomicilio
                      ? 'Enviar solicitud de domicilio'
                      : 'Solicitar recogida'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────────

class _CantidadControl extends StatelessWidget {
  final int cantidad;
  final int max;
  final ValueChanged<int> onChanged;

  const _CantidadControl({
    required this.cantidad,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BotonCantidad(
          icon: Icons.remove,
          onTap: cantidad > 1 ? () => onChanged(cantidad - 1) : null,
          cs: cs,
        ),
        Container(
          width: 44,
          alignment: Alignment.center,
          child: Text(
            '$cantidad',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        _BotonCantidad(
          icon: Icons.add,
          onTap: cantidad < max ? () => onChanged(cantidad + 1) : null,
          cs: cs,
        ),
      ],
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final ColorScheme cs;

  const _BotonCantidad({required this.icon, this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap == null
              ? cs.surfaceContainerHighest
              : cs.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? cs.onSurfaceVariant : cs.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _ResumenRow extends StatelessWidget {
  final String label;
  final String valor;
  final bool destacado;
  final Color? color;

  const _ResumenRow({
    required this.label,
    required this.valor,
    this.destacado = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(label,
            style: TextStyle(
              fontSize: destacado ? 14 : 13,
              fontWeight:
                  destacado ? FontWeight.w700 : FontWeight.normal,
              color: destacado ? (color ?? cs.onSurface) : cs.onSurfaceVariant,
            )),
        const Spacer(),
        Text(valor,
            style: TextStyle(
              fontSize: destacado ? 16 : 13,
              fontWeight:
                  destacado ? FontWeight.w800 : FontWeight.w500,
              color: destacado ? (color ?? cs.onSurface) : cs.onSurface,
            )),
      ],
    );
  }
}

class _MetodoPagoChip extends StatelessWidget {
  final String metodo;
  const _MetodoPagoChip({required this.metodo});

  String get _label {
    switch (metodo.toUpperCase()) {
      case 'EFECTIVO':      return 'Efectivo';
      case 'NEQUI':         return 'Nequi';
      case 'DAVIPLATA':     return 'Daviplata';
      case 'TRANSFERENCIA': return 'Transferencia';
      case 'BANCOLOMBIA':   return 'Bancolombia';
      default:              return metodo;
    }
  }

  IconData get _icon {
    switch (metodo.toUpperCase()) {
      case 'EFECTIVO':      return Icons.payments_outlined;
      case 'NEQUI':
      case 'DAVIPLATA':
      case 'BANCOLOMBIA':   return Icons.account_balance_outlined;
      case 'TRANSFERENCIA': return Icons.swap_horiz_outlined;
      default:              return Icons.credit_card_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(_label,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
