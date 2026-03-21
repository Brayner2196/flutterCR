import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/usuario_provider.dart';
import '../../models/usuario_response.dart';
import 'widgets/usuario_card.dart';
import 'widgets/usuario_detalle_sheet.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarDatos());
  }

  void _cargarDatos() {
    final provider = context.read<UsuarioProvider>();
    provider.cargarTodos();
    provider.cargarPendientes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _abrirDetalle(UsuarioResponse usuario, {bool conAcciones = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UsuarioDetalleSheet(
        usuario: usuario,
        mostrarAcciones: conAcciones,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Pendientes'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _TabTodos(onTap: (u) => _abrirDetalle(u)),
              _TabPendientes(onTap: (u) => _abrirDetalle(u, conAcciones: true)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tab: Todos ────────────────────────────────────────────────────────────────

class _TabTodos extends StatelessWidget {
  final void Function(UsuarioResponse) onTap;
  const _TabTodos({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<UsuarioProvider>(
      builder: (_, provider, __) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _ErrorView(
            mensaje: provider.error!,
            onReintentar: () => context.read<UsuarioProvider>().cargarTodos(),
          );
        }

        if (provider.usuarios.isEmpty) {
          return const _EmptyView(mensaje: 'No hay usuarios registrados');
        }

        return RefreshIndicator(
          onRefresh: () => context.read<UsuarioProvider>().cargarTodos(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.usuarios.length,
            itemBuilder: (_, i) => UsuarioCard(
              usuario: provider.usuarios[i],
              onTap: () => onTap(provider.usuarios[i]),
            ),
          ),
        );
      },
    );
  }
}

// ── Tab: Pendientes ───────────────────────────────────────────────────────────

class _TabPendientes extends StatelessWidget {
  final void Function(UsuarioResponse) onTap;
  const _TabPendientes({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<UsuarioProvider>(
      builder: (_, provider, __) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _ErrorView(
            mensaje: provider.error!,
            onReintentar: () => context.read<UsuarioProvider>().cargarPendientes(),
          );
        }

        if (provider.pendientes.isEmpty) {
          return const _EmptyView(
            mensaje: 'No hay solicitudes pendientes',
            icono: Icons.check_circle_outline,
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<UsuarioProvider>().cargarPendientes(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.pendientes.length,
            itemBuilder: (_, i) => UsuarioCard(
              usuario: provider.pendientes[i],
              onTap: () => onTap(provider.pendientes[i]),
            ),
          ),
        );
      },
    );
  }
}

// ── Widgets de apoyo ──────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String mensaje;
  final IconData icono;

  const _EmptyView({
    required this.mensaje,
    this.icono = Icons.people_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            mensaje,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _ErrorView({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
