import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'package:flutter_residential/core/utils/date_formatter.dart';
import '../../propiedades/providers/propiedad_provider.dart';
import '../../usuarios/models/usuario_propiedad_response.dart';
import '../../vigilancia/models/visita_model.dart';
import '../providers/visita_provider.dart';
import 'visita_qr_screen.dart';

/// Pantalla del residente para generar QR de visitas y gestionarlas.
class MisVisitasScreen extends StatefulWidget {
  const MisVisitasScreen({super.key});

  @override
  State<MisVisitasScreen> createState() => _MisVisitasScreenState();
}

class _MisVisitasScreenState extends State<MisVisitasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitaProvider>().cargar();
      context.read<PropiedadProvider>().cargarMisPropiedades();
    });
  }

  Future<void> _crear() async {
    final visita = await showModalBottomSheet<VisitaModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CrearVisitaSheet(),
    );
    if (visita != null && mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => VisitaQrScreen(visita: visita)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<VisitaProvider>();
    final visitas = prov.visitas;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis visitas')),
      body: RefreshIndicator(
        onRefresh: () => prov.cargar(),
        child: prov.loading && visitas.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : visitas.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Icon(Icons.qr_code_2_rounded, size: 64, color: AppColors.textLoLight),
                      SizedBox(height: AppSpacing.md),
                      Center(child: Text('Aún no has creado visitas')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: visitas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _VisitaTile(
                      visita: visitas[i],
                      onVerQr: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => VisitaQrScreen(visita: visitas[i])),
                      ),
                      onCancelar: visitas[i].esPendiente
                          ? () => prov.cancelar(visitas[i].id)
                          : null,
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crear,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva visita'),
      ),
    );
  }
}

class _VisitaTile extends StatelessWidget {
  final VisitaModel visita;
  final VoidCallback onVerQr;
  final VoidCallback? onCancelar;

  const _VisitaTile({
    required this.visita,
    required this.onVerQr,
    this.onCancelar,
  });

  Color _estadoColor() {
    if (visita.esIngreso) return AppColors.ok;
    if (visita.esCancelada || visita.esVencida) return AppColors.danger;
    return AppColors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _estadoColor();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.person_rounded, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(visita.nombreVisitante,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${visita.estadoLegible}'
                  '${visita.expiraEn != null ? ' · vence ${DateFormatter.fechaHora(visita.expiraEn)}' : ''}',
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
          if (visita.esPendiente)
            IconButton(
              icon: const Icon(Icons.qr_code_2_rounded),
              tooltip: 'Ver QR',
              onPressed: onVerQr,
            ),
          if (onCancelar != null)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Cancelar',
              color: AppColors.danger,
              onPressed: onCancelar,
            ),
        ],
      ),
    );
  }
}

// ─── Hoja de creación de visita ───────────────────────────────────────────────

class _CrearVisitaSheet extends StatefulWidget {
  const _CrearVisitaSheet();
  @override
  State<_CrearVisitaSheet> createState() => _CrearVisitaSheetState();
}

class _CrearVisitaSheetState extends State<_CrearVisitaSheet> {
  final _nombreCtrl = TextEditingController();
  final _docCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  UsuarioPropiedadResponse? _propiedad;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final props = context.read<PropiedadProvider>();
    _propiedad = props.propiedadActual ??
        (props.misPropiedades.isNotEmpty ? props.misPropiedades.first : null);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _docCtrl.dispose();
    _placaCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_propiedad == null || _nombreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona la unidad e indica el nombre')));
      return;
    }
    setState(() => _guardando = true);
    final prov = context.read<VisitaProvider>();
    final r = await prov.crear(
      propiedadId: _propiedad!.propiedadId,
      nombreVisitante: _nombreCtrl.text.trim(),
      documento: _docCtrl.text.trim().isEmpty ? null : _docCtrl.text.trim(),
      placa: _placaCtrl.text.trim().isEmpty ? null : _placaCtrl.text.trim(),
      motivo: _motivoCtrl.text.trim().isEmpty ? null : _motivoCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (r != null) {
      Navigator.pop(context, r);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(prov.error ?? 'Error al crear la visita')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final props = context.watch<PropiedadProvider>().misPropiedades;
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
          Text('Nueva visita',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          if (props.length > 1)
            DropdownButtonFormField<UsuarioPropiedadResponse>(
              value: _propiedad,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Unidad',
                prefixIcon: Icon(Icons.home_work_outlined),
              ),
              items: props
                  .map((p) =>
                      DropdownMenuItem(value: p, child: Text(p.pathTexto)))
                  .toList(),
              onChanged: (v) => setState(() => _propiedad = v),
            ),
          if (props.length > 1) const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre del visitante',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _docCtrl,
            decoration: const InputDecoration(
              labelText: 'Documento (opcional)',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _placaCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Placa del vehículo (opcional)',
              prefixIcon: Icon(Icons.directions_car_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _motivoCtrl,
            decoration: const InputDecoration(
              labelText: 'Motivo (opcional)',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.qr_code_2_rounded),
            label: const Text('Generar QR'),
          ),
        ],
      ),
    );
  }
}
