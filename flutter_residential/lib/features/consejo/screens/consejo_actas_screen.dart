import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/acta_model.dart';
import '../providers/acta_provider.dart';
import 'acta_detalle_screen.dart';
import 'grabar_acta_screen.dart';

/// Listado de actas de reunión por voz.
/// Todos los consejeros pueden ver; solo el PRESIDENTE puede grabar
/// (el backend valida el cargo contra BD en cada operación).
class ConsejoActasScreen extends StatefulWidget {
  const ConsejoActasScreen({super.key});

  @override
  State<ConsejoActasScreen> createState() => _ConsejoActasScreenState();
}

class _ConsejoActasScreenState extends State<ConsejoActasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActaProvider>().cargar();
    });
  }

  bool get _esPresidente =>
      context.read<AuthProvider>().cargoConsejo == 'PRESIDENTE';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActaProvider>();
    final cs = Theme.of(context).colorScheme;
    final actas = provider.actas;

    return Scaffold(
      appBar: AppBar(title: const Text('Actas de Reunión')),
      floatingActionButton: _esPresidente
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GrabarActaScreen()),
                );
                if (mounted) context.read<ActaProvider>().cargar();
              },
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Grabar acta'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => context.read<ActaProvider>().cargar(),
        child: provider.loading && actas.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : actas.isEmpty
                ? _EmptyState(esPresidente: _esPresidente)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                        AppSpacing.md, AppSpacing.md, AppSpacing.xl * 2),
                    itemCount: actas.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _ActaCard(
                      acta: actas[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ActaDetalleScreen(actaId: actas[i].id),
                        ),
                      ),
                    ),
                  ),
      ),
      backgroundColor: cs.surface,
    );
  }
}

// ─── Card de acta ─────────────────────────────────────────────────────────────

class _ActaCard extends StatelessWidget {
  final ActaModel acta;
  final VoidCallback onTap;

  const _ActaCard({required this.acta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final estado = _estadoVisual(acta);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: estado.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(estado.icono, size: 22, color: estado.color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    acta.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormatter.fechaHoraMinAmPm(acta.fechaReunion)} · ${acta.duracionLegible}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: estado.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                estado.texto,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: estado.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static ({Color color, IconData icono, String texto}) _estadoVisual(
      ActaModel a) {
    if (a.esProcesando) {
      return (
        color: AppColors.orange,
        icono: Icons.hourglass_top_rounded,
        texto: 'Transcribiendo'
      );
    }
    if (a.esBorrador) {
      return (
        color: AppColors.blue,
        icono: Icons.edit_note_rounded,
        texto: 'Borrador'
      );
    }
    if (a.esError) {
      return (
        color: AppColors.danger,
        icono: Icons.error_outline_rounded,
        texto: 'Error'
      );
    }
    return (
      color: AppColors.green,
      icono: Icons.verified_rounded,
      texto: 'Finalizada'
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool esPresidente;
  const _EmptyState({required this.esPresidente});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.mic_none_rounded, size: 56, color: cs.onSurfaceVariant),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            'Aún no hay actas de reunión',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: Text(
            esPresidente
                ? 'Pulsa "Grabar acta" para registrar una reunión'
                : 'El presidente del consejo puede grabarlas',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
