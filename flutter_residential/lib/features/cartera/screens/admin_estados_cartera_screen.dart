import 'package:flutter/material.dart';
import '../models/estado_cartera_config_model.dart';
import '../services/cartera_config_service.dart';
import '../utils/cartera_labels.dart';
import 'admin_estado_cartera_form_screen.dart';

/// Lista y administración de los estados de cartera del conjunto.
class AdminEstadosCarteraScreen extends StatefulWidget {
  const AdminEstadosCarteraScreen({super.key});

  @override
  State<AdminEstadosCarteraScreen> createState() => _AdminEstadosCarteraScreenState();
}

class _AdminEstadosCarteraScreenState extends State<AdminEstadosCarteraScreen> {
  late Future<List<EstadoCarteraConfig>> _futuro;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _futuro = CarteraConfigService.listar();
  }

  Future<void> _refrescar() async => setState(_cargar);

  Future<void> _sembrar() async {
    setState(() => _ocupado = true);
    try {
      await CarteraConfigService.sembrarDefaults();
      if (mounted) _snack('Estados por defecto creados');
      await _refrescar();
    } catch (e) {
      if (mounted) _snack(_msg(e), error: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _abrirEditor([EstadoCarteraConfig? estado]) async {
    final guardado = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => AdminEstadoCarteraFormScreen(estado: estado),
    ));
    if (guardado == true) _refrescar();
  }

  Future<void> _eliminar(EstadoCarteraConfig e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar estado'),
        content: Text('¿Eliminar el estado "${e.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || e.id == null) return;
    try {
      await CarteraConfigService.eliminar(e.id!);
      if (mounted) _snack('Estado eliminado');
      _refrescar();
    } catch (err) {
      if (mounted) _snack(_msg(err), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estados de cartera')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo estado'),
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: FutureBuilder<List<EstadoCarteraConfig>>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _error(_msg(snap.error));
            }
            final estados = snap.data ?? [];
            if (estados.isEmpty) return _vacio();
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: estados.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _EstadoCard(
                estado: estados[i],
                onEditar: () => _abrirEditor(estados[i]),
                onEliminar: () => _eliminar(estados[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _vacio() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        Icon(Icons.account_balance_wallet_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text('Aún no hay estados de cartera',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Crea los estados manualmente o empieza con un conjunto recomendado '
          '(Al día, Vencida, En mora, Cobro prejurídico).',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _ocupado ? null : _sembrar,
          icon: _ocupado
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.auto_awesome_outlined),
          label: const Text('Sembrar estados por defecto'),
        ),
      ],
    );
  }

  Widget _error(String msg) => ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center),
        ],
      );

  void _snack(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ));
  }

  String _msg(Object? e) => e.toString().replaceFirst('Exception: ', '');
}

class _EstadoCard extends StatelessWidget {
  final EstadoCarteraConfig estado;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _EstadoCard({required this.estado, required this.onEditar, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final color = CarteraLabels.colorDeHex(estado.color);
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onEditar,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(estado.nombre,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          ),
                          if (estado.esPositivo)
                            _chip('AL DÍA', color)
                          else
                            _chip('SEV ${estado.severidad}', color),
                          if (!estado.activo) ...[
                            const SizedBox(width: 6),
                            _chip('INACTIVO', cs.outline),
                          ],
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 20, color: cs.error),
                            onPressed: onEliminar,
                          ),
                        ],
                      ),
                      Text(estado.codigo,
                          style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
                      if (estado.descripcion != null && estado.descripcion!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(estado.descripcion!,
                            style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
                      ],
                      const SizedBox(height: 10),
                      Row(children: [
                        _meta(context, Icons.rule_outlined, '${estado.reglas.length} regla(s)'),
                        const SizedBox(width: 14),
                        _meta(context, Icons.block_outlined, '${estado.restricciones.length} restricción(es)'),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c, letterSpacing: 0.4)),
      );

  Widget _meta(BuildContext context, IconData i, String t) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Icon(i, size: 14, color: cs.onSurfaceVariant),
      const SizedBox(width: 4),
      Text(t, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
    ]);
  }
}
