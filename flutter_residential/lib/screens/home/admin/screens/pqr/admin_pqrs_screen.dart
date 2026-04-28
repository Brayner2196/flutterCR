import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../../models/pqr_model.dart';
import '../../../../../providers/pqr_provider.dart';
import '../../widgets/dashboard/dashboard_tokens.dart';

class AdminPqrsScreen extends StatefulWidget {
  const AdminPqrsScreen({super.key});

  @override
  State<AdminPqrsScreen> createState() => _AdminPqrsScreenState();
}

class _AdminPqrsScreenState extends State<AdminPqrsScreen> {
  String? _filtro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PqrProvider>().cargarAdmin(estado: _filtro);
    });
  }

  Future<void> _aplicarFiltro(String? estado) async {
    setState(() => _filtro = estado);
    await context.read<PqrProvider>().cargarAdmin(estado: estado);
  }

  Future<void> _abrirResponder(PqrModel pqr) async {
    final controller = TextEditingController(text: pqr.respuestaAdmin ?? '');
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ResponderSheet(pqr: pqr, controller: controller),
    );
    if (guardado == true) {
      try {
        await context.read<PqrProvider>().responder(pqr.id, controller.text.trim());
        if (!mounted) return;
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: const Text('PQR respondida'),
          autoCloseDuration: const Duration(seconds: 3),
        );
      } catch (e) {
        if (!mounted) return;
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: Text(e.toString()),
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PqrProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('PQRs')),
      body: RefreshIndicator(
        onRefresh: () => context.read<PqrProvider>().cargarAdmin(estado: _filtro),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FiltroChip(
                      label: 'Todas',
                      activo: _filtro == null,
                      onTap: () => _aplicarFiltro(null),
                    ),
                    const SizedBox(width: 6),
                    _FiltroChip(
                      label: 'Pendientes',
                      activo: _filtro == 'PENDIENTE',
                      onTap: () => _aplicarFiltro('PENDIENTE'),
                    ),
                    const SizedBox(width: 6),
                    _FiltroChip(
                      label: 'En proceso',
                      activo: _filtro == 'EN_PROCESO',
                      onTap: () => _aplicarFiltro('EN_PROCESO'),
                    ),
                    const SizedBox(width: 6),
                    _FiltroChip(
                      label: 'Resueltas',
                      activo: _filtro == 'RESUELTO',
                      onTap: () => _aplicarFiltro('RESUELTO'),
                    ),
                  ],
                ),
              ),
            ),
            if (p.error != null && p.pqrs.isEmpty)
              Expanded(child: Center(child: Text(p.error!, style: TextStyle(color: cs.error))))
            else if (p.loading && p.pqrs.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (p.pqrs.isEmpty)
              const Expanded(child: Center(child: Text('Sin PQRs')))
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: p.pqrs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PqrTile(
                    pqr: p.pqrs[i],
                    onTap: () => _abrirResponder(p.pqrs[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _FiltroChip({required this.label, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activo ? cs.primary : cs.outline),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: activo ? Colors.white : cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _PqrTile extends StatelessWidget {
  final PqrModel pqr;
  final VoidCallback onTap;

  const _PqrTile({required this.pqr, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    switch (pqr.estado) {
      case 'PENDIENTE':
        bg = DashboardTokens.bgOrange;
        fg = DashboardTokens.fgOrange;
        break;
      case 'EN_PROCESO':
        bg = DashboardTokens.bgYellow;
        fg = DashboardTokens.fgYellow;
        break;
      case 'RESUELTO':
        bg = DashboardTokens.bgGreen;
        fg = DashboardTokens.fgGreen;
        break;
      default:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurfaceVariant;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pqr.estadoLegible,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  pqr.tipoLegible,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pqr.asunto,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              pqr.descripcion,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline, size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(pqr.residenteNombre,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponderSheet extends StatelessWidget {
  final PqrModel pqr;
  final TextEditingController controller;

  const _ResponderSheet({required this.pqr, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pqr.asunto,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(pqr.descripcion,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Respuesta',
              hintText: 'Escribe la respuesta para el residente',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: controller.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Responder'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
