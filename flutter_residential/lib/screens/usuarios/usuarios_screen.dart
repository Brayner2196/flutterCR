import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/usuario_provider.dart';
import '../../models/usuario_response.dart';
import '../../widgets/pill_tab_bar.dart';
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
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _selectedTab) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarDatos());
  }

  /// Una sola llamada a la API; los filtros se calculan en el provider.
  void _cargarDatos() => context.read<UsuarioProvider>().cargarTodos();

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
        Consumer<UsuarioProvider>(
          builder: (_, provider, __) => PillTabBar(
            tabs: [
              PillTabItem(
                label: 'Todos',
                count: provider.usuarios.isNotEmpty
                    ? provider.usuarios.length
                    : null,
              ),
              PillTabItem(
                label: 'Activos',
                count: provider.activos.isNotEmpty
                    ? provider.activos.length
                    : null,
              ),
              PillTabItem(
                label: 'Pendientes',
                count: provider.pendientes.isNotEmpty
                    ? provider.pendientes.length
                    : null,
              ),
              PillTabItem(
                label: 'Inactivos',
                count: provider.inactivos.isNotEmpty
                    ? provider.inactivos.length
                    : null,
              ),
              PillTabItem(
                label:  'Rechazados',
                count: provider.rechazados.isNotEmpty 
                  ? provider.rechazados.length 
                  : null
              )

            ],
            selectedIndex: _selectedTab,
            onTabSelected: (i) {
              _tabController.animateTo(i);
              setState(() => _selectedTab = i);
            },
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _TabLista(
                selector: (p) => p.usuarios,
                onTap: (u) => _abrirDetalle(u),
                emptyMessage: 'No hay usuarios registrados',
              ),
              _TabLista(
                selector: (p) => p.activos,
                onTap: (u) => _abrirDetalle(u),
                emptyMessage: 'No hay usuarios activos',
                emptyIcon: Icons.check_circle_outline,
              ),
              _TabLista(
                selector: (p) => p.pendientes,
                onTap: (u) => _abrirDetalle(u, conAcciones: true),
                emptyMessage: 'No hay solicitudes pendientes',
                emptyIcon: Icons.check_circle_outline,
              ),
              _TabLista(
                selector: (p) => p.inactivos,
                onTap: (u) => _abrirDetalle(u),
                emptyMessage: 'No hay usuarios inactivos',
                emptyIcon: Icons.person_off_outlined,
              ),
              _TabLista(
                selector: (p) => p.rechazados,
                onTap: (u) => _abrirDetalle(u),
                emptyMessage: 'No hay usuarios rechazados',
                emptyIcon: Icons.block_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tab genérico ────────────────────────────────────────────────────────────────

class _TabLista extends StatelessWidget {
  final List<UsuarioResponse> Function(UsuarioProvider) selector;
  final void Function(UsuarioResponse) onTap;
  final String emptyMessage;
  final IconData emptyIcon;

  const _TabLista({
    required this.selector,
    required this.onTap,
    required this.emptyMessage,
    this.emptyIcon = Icons.people_outline,
  });

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

        final lista = selector(provider);

        if (lista.isEmpty) {
          return _EmptyView(mensaje: emptyMessage, icono: emptyIcon);
        }

        return RefreshIndicator(
          onRefresh: () => context.read<UsuarioProvider>().cargarTodos(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: lista.length,
            itemBuilder: (_, i) => UsuarioCard(
              usuario: lista[i],
              onTap: () => onTap(lista[i]),
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
          Icon(icono,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant),
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
