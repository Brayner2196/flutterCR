import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'package:flutter_residential/core/utils/date_formatter.dart';
import '../models/detalle_visita_model.dart';
import '../services/vigilancia_service.dart';

/// Resultado del escaneo de una visita: muestra los datos y permite al vigilante
/// Aprobar o Rechazar (con motivo) mediante una barra de acciones inferior.
class VisitaResultadoScreen extends StatefulWidget {
  final DetalleVisitaModel detalle;

  const VisitaResultadoScreen({super.key, required this.detalle});

  @override
  State<VisitaResultadoScreen> createState() => _VisitaResultadoScreenState();
}

class _VisitaResultadoScreenState extends State<VisitaResultadoScreen> {
  late DetalleVisitaModel _d = widget.detalle;
  bool _procesando = false;
  bool _decidido = false;

  Future<void> _aprobar() async {
    setState(() => _procesando = true);
    try {
      final r = await VigilanciaService.aprobarVisita(_d.id);
      setState(() {
        _d = r;
        _decidido = true;
      });
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _rechazar() async {
    final motivo = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _MotivoRechazoSheet(),
    );
    if (motivo == null || motivo.trim().isEmpty) return;
    setState(() => _procesando = true);
    try {
      final r = await VigilanciaService.rechazarVisita(_d.id, motivo.trim());
      setState(() {
        _d = r;
        _decidido = true;
      });
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _error(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = _d;

    // Color de cabecera según estado.
    final Color fg;
    final Color bg;
    final IconData icono;
    if (d.esIngreso) {
      fg = AppColors.ok;
      bg = AppColors.okSoft;
      icono = Icons.check_circle_rounded;
    } else if (d.esRechazada) {
      fg = AppColors.danger;
      bg = AppColors.dangerSoft;
      icono = Icons.cancel_rounded;
    } else if (!d.puedeDecidir) {
      fg = AppColors.warning;
      bg = AppColors.warningSoft;
      icono = Icons.info_outline_rounded;
    } else {
      fg = AppColors.blue;
      bg = AppColors.bgBlue;
      icono = Icons.qr_code_2_rounded;
    }

    final mostrarBotones = d.puedeDecidir && !_decidido;

    return Scaffold(
      appBar: AppBar(title: const Text('Visita')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera de estado
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: fg.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(icono, color: fg, size: 30),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      d.mensaje ?? 'Visita',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: fg, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _fila('Visitante', d.nombreVisitante),
            _fila('Personas', '${d.cantidadPersonas}'),
            if (d.acompanantes != null && d.acompanantes!.isNotEmpty)
              _fila('Acompañantes', d.acompanantes!),
            if (d.documento != null && d.documento!.isNotEmpty)
              _fila('Documento', d.documento!),
            if (d.placa != null && d.placa!.isNotEmpty) _fila('Placa', d.placa!),
            _fila('Unidad', d.propiedadIdentificador ?? '${d.propiedadId}'),
            if (d.motivo != null && d.motivo!.isNotEmpty) _fila('Motivo', d.motivo!),
            if (d.franjaDesde != null)
              _fila('Horario',
                  '${DateFormatter.fechaHora(d.franjaDesde)}${d.franjaHasta != null ? ' a ${DateFormatter.fechaHora(d.franjaHasta)}' : ''}'),
            if (d.motivoRechazo != null && d.motivoRechazo!.isNotEmpty)
              _fila('Motivo rechazo', d.motivoRechazo!),

            // Aviso de cartera
            if (d.carteraRestringida) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        color: AppColors.warning),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        d.carteraMensaje ?? 'Unidad con restricción de cartera',
                        style: const TextStyle(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_decidido) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Cerrar'),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: mostrarBotones
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Rechazar'),
                        onPressed: _procesando ? null : _rechazar,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.ok,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: _procesando
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_rounded),
                        label: const Text('Aprobar'),
                        onPressed: (_procesando || !d.puedeAprobar) ? null : _aprobar,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _fila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textMidLight, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(valor,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ─── Bottomsheet de motivo de rechazo ─────────────────────────────────────────

class _MotivoRechazoSheet extends StatefulWidget {
  const _MotivoRechazoSheet();
  @override
  State<_MotivoRechazoSheet> createState() => _MotivoRechazoSheetState();
}

class _MotivoRechazoSheetState extends State<_MotivoRechazoSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Motivo del rechazo',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _ctrl,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Ej: no autorizado por el residente',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Rechazar ingreso'),
            onPressed: () {
              final m = _ctrl.text.trim();
              if (m.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Indica el motivo')));
                return;
              }
              Navigator.pop(context, m);
            },
          ),
        ],
      ),
    );
  }
}
