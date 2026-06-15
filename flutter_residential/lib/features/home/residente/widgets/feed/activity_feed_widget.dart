import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../anuncios/models/anuncio_model.dart';
import '../../../../anuncios/providers/anuncio_provider.dart';
import '../../../../anuncios/screens/residente/detalle_anuncio_screen.dart';
import '../../../../pagos/models/pago_model.dart';
import '../../../../pqr/models/pqr_model.dart';
import '../../../../pqr/providers/pqr_provider.dart';
import '../../../../pqr/screens/residente/detalle_pqr_screen.dart';
import '../../../../votaciones/models/votacion_model.dart';
import '../../../../votaciones/providers/votacion_provider.dart';
import '../../../../votaciones/screens/residente/mis_votaciones_screen.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../shared/theme/app_theme.dart';

/// Feed de actividad reciente del residente.
/// Consolida: último pago, anuncios no leídos, PQRs activos y votaciones abiertas.
class ActivityFeedWidget extends StatelessWidget {
  final PagoModel? ultimoPago;
  final String Function(double) formatMonto;

  const ActivityFeedWidget({
    super.key,
    this.ultimoPago,
    required this.formatMonto,
  });

  @override
  Widget build(BuildContext context) {
    final anuncioProvider = context.watch<AnuncioProvider>();
    final pqrProvider = context.watch<PqrProvider>();
    final votacionProvider = context.watch<VotacionProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final items = _buildItems(
      context,
      anuncioProvider: anuncioProvider,
      pqrProvider: pqrProvider,
      votacionProvider: votacionProvider,
    );

    if (items.isEmpty && ultimoPago == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Último pago ──
          if (ultimoPago != null) ...[
            _FeedItem(
              icono: Icons.check_circle_rounded,
              iconoBg: AppColors.okSoft,
              iconoColor: AppColors.ok,
              titulo: _labelPago(ultimoPago!),
              subtitulo: _fechaRelativa(ultimoPago!.creadoEn),
              trailing: formatMonto(ultimoPago!.montoPagado),
              trailingColor: AppColors.ok,
              onTap: null,
            ),
          ],

          // ── Ítems dinámicos ──
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1 && ultimoPago == null
                ? true
                : entry.key == items.length - 1;
            return Column(
              children: [
                entry.value,
                if (!isLast) const Divider(height: 1),
              ],
            );
          }),

          // ── Sin actividad ──
          if (items.isEmpty && ultimoPago == null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(
                  'Sin actividad reciente',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Construye ítems de anuncios, PQRs y votaciones ──────────────────────

  List<Widget> _buildItems(
    BuildContext context, {
    required AnuncioProvider anuncioProvider,
    required PqrProvider pqrProvider,
    required VotacionProvider votacionProvider,
  }) {
    final items = <_FeedEntry>[];

    // Anuncios no leídos (máx 2)
    final noLeidos =
        anuncioProvider.anuncios.where((a) => !a.vistoPorMi).take(2);
    for (final a in noLeidos) {
      items.add(_FeedEntry(
        fecha: a.creadoEn ?? '',
        widget: _AnuncioItem(anuncio: a),
      ));
    }

    // PQRs pendientes / en proceso (máx 2)
    final pqrsActivos = pqrProvider.pqrs
        .where((p) => p.esPendiente || p.esEnProceso)
        .take(2);
    for (final p in pqrsActivos) {
      items.add(_FeedEntry(
        fecha: p.creadoEn ?? '',
        widget: _PqrItem(pqr: p),
      ));
    }

    // Votaciones abiertas sin votar (máx 2)
    final votacionesPendientes = votacionProvider.votaciones
        .where((v) => v.estado == 'ABIERTA' && !v.yaVote)
        .take(2);
    for (final v in votacionesPendientes) {
      items.add(_FeedEntry(
        fecha: v.creadoEn ?? '',
        widget: _VotacionItem(votacion: v),
      ));
    }

    // Ordenar por fecha descendente
    items.sort((a, b) => b.fecha.compareTo(a.fecha));

    return items.take(5).map((e) => e.widget).toList();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _labelPago(PagoModel p) {
    if (p.esVerificado) return 'Pago verificado';
    if (p.esPendiente) return 'Pago en verificación';
    if (p.esRechazado) return 'Pago rechazado';
    return 'Pago registrado';
  }

  String _fechaRelativa(String iso) {
    try {
      final fecha = DateFormatter.instanteEnZona(iso);
      final diff = DateFormatter.ahoraEnZona().difference(fecha);
      if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'hace ${diff.inHours} h';
      if (diff.inDays == 1) return 'ayer';
      if (diff.inDays < 7) return 'hace ${diff.inDays} días';
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ─── Entrada de feed con fecha para ordenar ──────────────────────────────────

class _FeedEntry {
  final String fecha;
  final Widget widget;
  _FeedEntry({required this.fecha, required this.widget});
}

// ─── Ítem de anuncio ─────────────────────────────────────────────────────────

class _AnuncioItem extends StatelessWidget {
  final AnuncioModel anuncio;
  const _AnuncioItem({required this.anuncio});

  @override
  Widget build(BuildContext context) {
    return _FeedItem(
      icono: Icons.campaign_rounded,
      iconoBg: AppColors.bgYellow,
      iconoColor: AppColors.yellow,
      titulo: anuncio.titulo,
      subtitulo: 'Anuncio nuevo',
      trailing: 'Ver →',
      trailingColor: AppColors.yellow,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalleAnuncioScreen(anuncio: anuncio),
        ),
      ),
    );
  }
}

// ─── Ítem de PQR ─────────────────────────────────────────────────────────────

class _PqrItem extends StatelessWidget {
  final PqrModel pqr;
  const _PqrItem({required this.pqr});

  @override
  Widget build(BuildContext context) {
    final color = pqr.esEnProceso ? AppColors.blue : AppColors.warning;
    final bgColor = pqr.esEnProceso ? AppColors.bgBlue : AppColors.warningSoft;
    return _FeedItem(
      icono: Icons.support_agent_rounded,
      iconoBg: bgColor,
      iconoColor: color,
      titulo: pqr.asunto,
      subtitulo: 'PQR · ${pqr.estadoLegible}',
      trailing: 'Ver →',
      trailingColor: color,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetallePqrScreen(pqr: pqr)),
      ),
    );
  }
}

// ─── Ítem de votación ────────────────────────────────────────────────────────

class _VotacionItem extends StatelessWidget {
  final VotacionModel votacion;
  const _VotacionItem({required this.votacion});

  @override
  Widget build(BuildContext context) {
    return _FeedItem(
      icono: Icons.how_to_vote_rounded,
      iconoBg: AppColors.bgPurple,
      iconoColor: AppColors.purple,
      titulo: votacion.titulo,
      subtitulo: 'Votación abierta · pendiente tu voto',
      trailing: 'Votar →',
      trailingColor: AppColors.purple,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MisVotacionesScreen()),
      ),
    );
  }
}

// ─── Ítem base del feed ──────────────────────────────────────────────────────

class _FeedItem extends StatelessWidget {
  final IconData icono;
  final Color iconoBg;
  final Color iconoColor;
  final String titulo;
  final String subtitulo;
  final String? trailing;
  final Color? trailingColor;
  final VoidCallback? onTap;

  const _FeedItem({
    required this.icono,
    required this.iconoBg,
    required this.iconoColor,
    required this.titulo,
    required this.subtitulo,
    this.trailing,
    this.trailingColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            // Ícono
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconoBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, size: 18, color: iconoColor),
            ),
            const SizedBox(width: AppSpacing.md),

            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitulo,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                trailing!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: trailingColor ?? theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
