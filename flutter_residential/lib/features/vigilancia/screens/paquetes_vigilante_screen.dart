import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'package:flutter_residential/core/utils/date_formatter.dart';
import '../models/paquete_model.dart';
import '../models/propiedad_opcion_model.dart';
import '../providers/vigilancia_provider.dart';
import 'widgets/propiedad_selector_field.dart';

/// Gestión de paquetería: pendientes por entregar + registro + entrega.
class PaquetesVigilanteScreen extends StatefulWidget {
  const PaquetesVigilanteScreen({super.key});

  @override
  State<PaquetesVigilanteScreen> createState() => _PaquetesVigilanteScreenState();
}

class _PaquetesVigilanteScreenState extends State<PaquetesVigilanteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VigilanciaProvider>().cargarPaquetesPendientes();
    });
  }

  Future<void> _abrirRegistro() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RegistrarPaqueteSheet(),
    );
  }

  Future<void> _entregar(PaqueteModel p) async {
    final ctrl = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Entregar paquete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.descripcion),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: '¿Quién recibe? (opcional)',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Entregar')),
        ],
      ),
    );
    if (confirmar == true) {
      final prov = context.read<VigilanciaProvider>();
      final r = await prov.entregarPaquete(p.id,
          entregadoA: ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
      if (mounted && r != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paquete entregado')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<VigilanciaProvider>();
    final pendientes = prov.paquetesPendientes;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => prov.cargarPaquetesPendientes(),
        child: prov.loading && pendientes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : pendientes.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Icon(Icons.inbox_rounded, size: 64, color: AppColors.textLoLight),
                      SizedBox(height: AppSpacing.md),
                      Center(child: Text('Sin paquetes pendientes')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: pendientes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _PaqueteTile(
                      paquete: pendientes[i],
                      onEntregar: () => _entregar(pendientes[i]),
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirRegistro,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Recibir'),
      ),
    );
  }
}

class _PaqueteTile extends StatelessWidget {
  final PaqueteModel paquete;
  final VoidCallback onEntregar;

  const _PaqueteTile({required this.paquete, required this.onEntregar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              color: AppColors.bgOrange,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: AppColors.orange),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(paquete.descripcion,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'Unidad ${paquete.propiedadIdentificador ?? paquete.propiedadId}'
                  '${paquete.transportadora != null ? ' · ${paquete.transportadora}' : ''}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text('Recibido ${DateFormatter.fechaHora(paquete.recibidoEn)}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          TextButton(onPressed: onEntregar, child: const Text('Entregar')),
        ],
      ),
    );
  }
}

// ─── Hoja de registro de paquete ──────────────────────────────────────────────

class _RegistrarPaqueteSheet extends StatefulWidget {
  const _RegistrarPaqueteSheet();
  @override
  State<_RegistrarPaqueteSheet> createState() => _RegistrarPaqueteSheetState();
}

class _RegistrarPaqueteSheetState extends State<_RegistrarPaqueteSheet> {
  final _descCtrl = TextEditingController();
  final _remitenteCtrl = TextEditingController();
  final _transpCtrl = TextEditingController();
  PropiedadOpcionModel? _propiedad;
  bool _guardando = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _remitenteCtrl.dispose();
    _transpCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_propiedad == null || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona la unidad y describe el paquete')));
      return;
    }
    setState(() => _guardando = true);
    final prov = context.read<VigilanciaProvider>();
    final r = await prov.registrarPaquete(
      propiedadId: _propiedad!.id,
      descripcion: _descCtrl.text.trim(),
      remitente: _remitenteCtrl.text.trim().isEmpty ? null : _remitenteCtrl.text.trim(),
      transportadora: _transpCtrl.text.trim().isEmpty ? null : _transpCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (r != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paquete registrado y residente notificado')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(prov.error ?? 'Error al registrar')));
    }
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
          Text('Recibir paquete',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          PropiedadSelectorField(
            seleccionada: _propiedad,
            onSeleccion: (p) => setState(() => _propiedad = p),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Descripción del paquete',
              prefixIcon: Icon(Icons.description_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _transpCtrl,
            decoration: const InputDecoration(
              labelText: 'Transportadora (opcional)',
              prefixIcon: Icon(Icons.local_shipping_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _remitenteCtrl,
            decoration: const InputDecoration(
              labelText: 'Remitente (opcional)',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_rounded),
            label: const Text('Registrar'),
          ),
        ],
      ),
    );
  }
}
