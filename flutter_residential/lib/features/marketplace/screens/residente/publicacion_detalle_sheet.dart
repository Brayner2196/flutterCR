import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/publicacion_model.dart';
import 'confirmar_pedido_sheet.dart';

class PublicacionDetalleSheet extends StatelessWidget {
  final PublicacionModel publicacion;

  const PublicacionDetalleSheet({super.key, required this.publicacion});

  static Future<void> mostrar(
      BuildContext context, PublicacionModel publicacion) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PublicacionDetalleSheet(publicacion: publicacion),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = publicacion;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, ctrl) => SingleChildScrollView(
          controller: ctrl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle ───────────────────────────────────────
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

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Cabecera: categoría + fecha ───────────
                    Row(
                      children: [
                        _CategoriaBadge(categoria: p.categoriaLegible),
                        const Spacer(),
                        Text(p.fechaCorta,
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ── Título ────────────────────────────────
                    Text(
                      p.titulo,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    // ── Marca ─────────────────────────────────
                    if (p.marca != null && p.marca!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        p.marca!,
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 10),

                    // ── Precio + stock ────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          p.precioFormateado,
                          style: theme.textTheme.headlineSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 10),
                        if (p.stock != null) _StockBadge(stock: p.stock!),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Chips informativos (proximidad + delivery) ──
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (p.distanciaProximidad != null)
                          _ProximidadBadge(
                              distancia: p.distanciaProximidad!,
                              ubicacion: p.ubicacionVendedor),
                        _DeliveryBadge(acepta: p.aceptaDomicilio),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── Descripción ───────────────────────────
                    if (p.descripcion != null &&
                        p.descripcion!.isNotEmpty) ...[
                      Text('Descripción',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(color: cs.primary)),
                      const SizedBox(height: 6),
                      Text(p.descripcion!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 18),
                    ],

                    // ── Vendedor ──────────────────────────────
                    _SeccionVendedor(publicacion: p),
                    const SizedBox(height: 18),

                    // ── Métodos de pago ───────────────────────
                    if (p.metodosPago.isNotEmpty) ...[
                      Text('Métodos de pago',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(color: cs.primary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: p.metodosPago
                            .map((m) => _MetodoPagoChip(metodo: m))
                            .toList(),
                      ),
                      const SizedBox(height: 18),
                    ],

                    const Divider(height: 1),
                    const SizedBox(height: 18),

                    // ── Botones de acción ─────────────────────
                    _BotonesAccion(publicacion: p),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sección vendedor ──────────────────────────────────────────────────────────

class _SeccionVendedor extends StatelessWidget {
  final PublicacionModel publicacion;
  const _SeccionVendedor({required this.publicacion});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = publicacion;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primaryContainer,
            child: Text(
              p.vendedorNombre.isNotEmpty
                  ? p.vendedorNombre[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.vendedorNombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                if (p.ubicacionVendedor != null &&
                    p.ubicacionVendedor!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: cs.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          p.ubicacionVendedor!,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botones de acción dinámicos ───────────────────────────────────────────────

class _BotonesAccion extends StatelessWidget {
  final PublicacionModel publicacion;
  const _BotonesAccion({required this.publicacion});

  Future<void> _abrirConfirmacion(
      BuildContext context, String tipo) async {
    final confirmo = await ConfirmarPedidoSheet.mostrar(
      context,
      publicacion: publicacion,
      tipo: tipo,
    );
    if (confirmo == true && context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                  child: Text('Solicitud enviada. El vendedor recibirá la notificación.')),
            ],
          ),
          backgroundColor: AppColors.ok,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = publicacion;
    final cs = Theme.of(context).colorScheme;

    if (p.agotado) {
      return _InfoBanner(
        icon: Icons.remove_shopping_cart_outlined,
        mensaje:
            'Este producto está agotado. Puedes volver a revisarlo más tarde.',
        color: AppColors.dangerSoft,
        textColor: AppColors.danger,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botón domicilio — solo si acepta delivery
        if (p.aceptaDomicilio)
          FilledButton.icon(
            onPressed: () => _abrirConfirmacion(context, 'DOMICILIO'),
            icon: Icon(Icons.delivery_dining_outlined, color: cs.onPrimaryContainer),
            label: Text('Solicitar a domicilio', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onPrimaryContainer)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),

        if (p.aceptaDomicilio) const SizedBox(height: 10),

        // Botón recogida — siempre disponible
        p.aceptaDomicilio
            ? OutlinedButton.icon(
                onPressed: () => _abrirConfirmacion(context, 'RECOGIDA'),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Coordinar recogida'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              )
            : FilledButton.icon(
                onPressed: () => _abrirConfirmacion(context, 'RECOGIDA'),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Coordinar recogida en punto'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
      ],
    );
  }
}

// ── Badges y chips ────────────────────────────────────────────────────────────

class _CategoriaBadge extends StatelessWidget {
  final String categoria;
  const _CategoriaBadge({required this.categoria});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        categoria,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.onPrimaryContainer),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stock;
  const _StockBadge({required this.stock});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;
    final String label;

    if (stock <= 0) {
      bg = AppColors.dangerSoft;
      fg = AppColors.danger;
      icon = Icons.remove_circle_outline;
      label = 'Agotado';
    } else if (stock == 1) {
      bg = AppColors.warningSoft;
      fg = AppColors.warning;
      icon = Icons.warning_amber_outlined;
      label = 'Último disponible';
    } else {
      bg = AppColors.bgGreen;
      fg = AppColors.ok;
      icon = Icons.check_circle_outline;
      label = '$stock disponibles';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

class _ProximidadBadge extends StatelessWidget {
  final int distancia;
  final String? ubicacion;
  const _ProximidadBadge({required this.distancia, this.ubicacion});

  String get _texto {
    if (distancia == 0) return 'Tu misma propiedad';
    if (distancia <= 2) return 'Mismo piso';
    if (distancia <= 4) return 'Mismo edificio / torre';
    return 'En el conjunto';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgTeal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me_outlined, size: 13, color: AppColors.teal),
          const SizedBox(width: 5),
          Text(
            ubicacion ?? _texto,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.teal),
          ),
        ],
      ),
    );
  }
}

class _DeliveryBadge extends StatelessWidget {
  final bool acepta;
  const _DeliveryBadge({required this.acepta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: acepta ? AppColors.bgBlue : AppColors.neutralSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            acepta
                ? Icons.delivery_dining_outlined
                : Icons.delivery_dining_outlined,
            size: 13,
            color: acepta ? AppColors.blue : AppColors.textLoLight,
          ),
          const SizedBox(width: 5),
          Text(
            acepta ? 'Hace domicilio' : 'Sin domicilio',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: acepta ? AppColors.blue : AppColors.textLoLight),
          ),
        ],
      ),
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
      case 'TRANSFERENCIA': return Icons.swap_horiz_outlined;
      default:              return Icons.account_balance_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 13, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(_label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String mensaje;
  final Color color;
  final Color textColor;

  const _InfoBanner({
    required this.icon,
    required this.mensaje,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(mensaje,
                style:
                    TextStyle(fontSize: 13, color: textColor)),
          ),
        ],
      ),
    );
  }
}
