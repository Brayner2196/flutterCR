import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_toast.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/acta_model.dart';
import '../providers/acta_provider.dart';

/// Detalle de un acta: ver, editar (borrador), finalizar, reintentar o eliminar.
/// Las acciones de escritura solo aparecen para el PRESIDENTE y además el
/// backend las vuelve a validar contra BD.
class ActaDetalleScreen extends StatefulWidget {
  final int actaId;
  const ActaDetalleScreen({super.key, required this.actaId});

  @override
  State<ActaDetalleScreen> createState() => _ActaDetalleScreenState();
}

class _ActaDetalleScreenState extends State<ActaDetalleScreen> {
  final _tituloCtrl = TextEditingController();
  final _contenidoCtrl = TextEditingController();
  bool _controllersListos = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _contenidoCtrl.dispose();
    super.dispose();
  }

  ActaModel? _actaActual(ActaProvider provider) {
    for (final a in provider.actas) {
      if (a.id == widget.actaId) return a;
    }
    return null;
  }

  void _sincronizarControllers(ActaModel acta) {
    if (_controllersListos) return;
    _tituloCtrl.text = acta.titulo;
    _contenidoCtrl.text = acta.contenido ?? '';
    _controllersListos = true;
  }

  // ─── Acciones ─────────────────────────────────────────────────

  Future<void> _guardar() async {
    final acta = await context.read<ActaProvider>().guardarEdicion(
          widget.actaId,
          titulo: _tituloCtrl.text.trim(),
          contenido: _contenidoCtrl.text,
        );
    if (!mounted) return;
    if (acta != null) {
      AppToast.success(context, 'Acta guardada');
    } else {
      AppToast.error(
          context, context.read<ActaProvider>().error ?? 'Error al guardar');
    }
  }

  Future<void> _finalizar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar acta'),
        content: const Text(
            'Una vez finalizada, el acta queda cerrada y no podrá editarse. ¿Continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Finalizar')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    // Guarda los últimos cambios antes de cerrar el acta.
    final guardada = await context.read<ActaProvider>().guardarEdicion(
          widget.actaId,
          titulo: _tituloCtrl.text.trim(),
          contenido: _contenidoCtrl.text,
        );
    if (guardada == null) {
      if (mounted) {
        AppToast.error(context,
            context.read<ActaProvider>().error ?? 'Error al guardar');
      }
      return;
    }
    if (!mounted) return;

    final acta = await context.read<ActaProvider>().finalizar(widget.actaId);
    if (!mounted) return;
    if (acta != null) {
      AppToast.success(context, 'Acta finalizada');
    } else {
      AppToast.error(
          context, context.read<ActaProvider>().error ?? 'Error al finalizar');
    }
  }

  Future<void> _reintentar() async {
    final acta = await context.read<ActaProvider>().reintentar(widget.actaId);
    if (!mounted) return;
    if (acta != null) {
      AppToast.success(context, 'Transcripción reintentada',
          description: 'Whisper está procesando el audio nuevamente.');
    } else {
      AppToast.error(
          context, context.read<ActaProvider>().error ?? 'Error al reintentar');
    }
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar acta'),
        content: const Text('Se eliminará el acta y su audio. ¿Continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final ok = await context.read<ActaProvider>().eliminarActa(widget.actaId);
    if (!mounted) return;
    if (ok) {
      AppToast.success(context, 'Acta eliminada');
      Navigator.pop(context);
    } else {
      AppToast.error(
          context, context.read<ActaProvider>().error ?? 'Error al eliminar');
    }
  }

  // ─── UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActaProvider>();
    final esPresidente =
        context.read<AuthProvider>().cargoConsejo == 'PRESIDENTE';
    final acta = _actaActual(provider);
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (acta == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acta')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (acta.esBorrador && esPresidente) _sincronizarControllers(acta);

    final puedeEditar = acta.esBorrador && esPresidente;

    return Scaffold(
      appBar: AppBar(
        title: Text(acta.esFinalizada ? 'Acta Finalizada' : 'Acta'),
        actions: [
          if (esPresidente && (acta.esBorrador || acta.esError))
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: provider.loading ? null : _eliminar,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _CabeceraEstado(acta: acta),
          const SizedBox(height: AppSpacing.md),

          // ── PROCESANDO ──
          if (acta.esProcesando) ...[
            const SizedBox(height: AppSpacing.xl),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'Whisper está transcribiendo la grabación.\nEsto puede tardar varios minutos según la duración.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],

          // ── ERROR ──
          if (acta.esError) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                acta.errorMensaje ?? 'La transcripción falló',
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
            if (esPresidente) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: provider.loading ? null : _reintentar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar transcripción'),
              ),
            ],
          ],

          // ── BORRADOR (editable por presidente) ──
          if (puedeEditar) ...[
            TextField(
              controller: _tituloCtrl,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Título',
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _contenidoCtrl,
              maxLines: null,
              minLines: 12,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                labelText: 'Contenido del acta',
                alignLabelWithHint: true,
                helperText:
                    'Texto generado por Whisper — edítalo antes de finalizar',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: provider.loading ? null : _guardar,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: provider.loading ? null : _finalizar,
                    icon: const Icon(Icons.verified_rounded),
                    label: const Text('Finalizar'),
                  ),
                ),
              ],
            ),
          ],

          // ── Lectura (finalizada, o borrador visto por otro consejero) ──
          if (!puedeEditar && (acta.esFinalizada || acta.esBorrador)) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: SelectableText(
                acta.contenido?.isNotEmpty == true
                    ? acta.contenido!
                    : 'Sin contenido',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Cabecera con metadatos ───────────────────────────────────────────────────

class _CabeceraEstado extends StatelessWidget {
  final ActaModel acta;
  const _CabeceraEstado({required this.acta});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            acta.titulo,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          _fila(context, Icons.event_rounded,
              'Reunión: ${DateFormatter.fechaHoraMinAmPm(acta.fechaReunion)}'),
          _fila(context, Icons.timer_outlined,
              'Duración: ${acta.duracionLegible}'),
          if (acta.creadoPorNombre != null)
            _fila(context, Icons.person_outline_rounded,
                'Grabada por: ${acta.creadoPorNombre}'),
          if (acta.finalizadaEn != null)
            _fila(context, Icons.verified_outlined,
                'Finalizada: ${DateFormatter.fechaHoraMinAmPm(acta.finalizadaEn)}'),
        ],
      ),
    );
  }

  Widget _fila(BuildContext context, IconData icono, String texto) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icono, size: 15, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
