import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/usuario_provider.dart';
import '../../models/usuario_response.dart';
import '../../widgets/pill_tab_bar.dart';
import 'usuario_crear_dialog.dart';
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
  int _tabActual = 1;
  String _busqueda = '';
  final TextEditingController _searchController = TextEditingController();

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

  void _cargarDatos() => context.read<UsuarioProvider>().cargarTodos();

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _abrirDetalle(UsuarioResponse usuario, {bool conAcciones = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          UsuarioDetalleSheet(usuario: usuario, mostrarAcciones: conAcciones),
    );
  }

  void _abrirCrear() {
    showDialog(context: context, builder: (_) => const UsuarioCrearDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(242, 245, 248, 0.91),
      appBar: AppBar(title: const Text('Gestión de Usuarios')),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(Icons.search, color: Colors.grey.shade600),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _busqueda = value.trim().toLowerCase()),
                          decoration: const InputDecoration(
                            hintText: 'Buscar usuarios...',
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      if (_busqueda.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey.shade600),
                          tooltip: 'Limpiar búsqueda',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _busqueda = '');
                          },
                        ),
                    ],
                  ),
                ),
              ),
              Consumer<UsuarioProvider>(
                builder: (_, provider, __) => PillTabBar(
                  tabs: [
                    PillTabItem(
                      label: 'Todos',
                      count: provider.usuarios.isNotEmpty
                          ? provider.usuarios.length
                          : null,
                      selectBackgroundColor: Color.fromRGBO(18, 47, 85, 1),
                      backgroundColor: Colors.grey.shade400,
                    ),
                    PillTabItem(
                      label: 'Activos',
                      count: provider.activos.isNotEmpty
                          ? provider.activos.length
                          : null,
                      selectBackgroundColor: Color.fromRGBO(18, 47, 85, 1),
                      backgroundColor: Colors.grey.shade400,
                    ),
                    PillTabItem(
                      label: 'Pendientes',
                      count: provider.pendientes.isNotEmpty
                          ? provider.pendientes.length
                          : null,
                      selectBackgroundColor: Color.fromRGBO(18, 47, 85, 1),
                      backgroundColor: Colors.grey.shade400,
                    ),
                    PillTabItem(
                      label: 'Inactivos',
                      count: provider.inactivos.isNotEmpty
                          ? provider.inactivos.length
                          : null,
                      selectBackgroundColor: Color.fromRGBO(18, 47, 85, 1),
                      backgroundColor: Colors.grey.shade400,
                    ),
                    PillTabItem(
                      label: 'Rechazados',
                      count: provider.rechazados.isNotEmpty
                          ? provider.rechazados.length
                          : null,
                      selectBackgroundColor: Color.fromRGBO(18, 47, 85, 1),
                      backgroundColor: Colors.grey.shade400,
                    ),
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
                      busqueda: _busqueda,
                      onTap: (u) => _abrirDetalle(u),
                      emptyMessage: 'No hay usuarios registrados',
                    ),
                    _TabLista(
                      selector: (p) => p.activos,
                      busqueda: _busqueda,
                      onTap: (u) => _abrirDetalle(u),
                      emptyMessage: 'No hay usuarios aprobados',
                    ),
                    _TabLista(
                      selector: (p) => p.pendientes,
                      busqueda: _busqueda,
                      onTap: (u) => _abrirDetalle(u, conAcciones: true),
                      emptyMessage: 'No hay solicitudes pendientes',
                      emptyIcon: Icons.check_circle_outline,
                    ),
                    _TabLista(
                      selector: (p) => p.inactivos,
                      busqueda: _busqueda,
                      onTap: (u) => _abrirDetalle(u),
                      emptyMessage: 'No hay usuarios inactivos',
                      emptyIcon: Icons.person_off_outlined,
                    ),
                    _TabLista(
                      selector: (p) => p.rechazados,
                      busqueda: _busqueda,
                      onTap: (u) => _abrirDetalle(u),
                      emptyMessage: 'No hay usuarios rechazados',
                      emptyIcon: Icons.block_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ── FAB crear usuario
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _abrirCrear,
              tooltip: 'Crear usuario',
              child: const Icon(Icons.person_add_outlined),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabActual,
        onDestinationSelected: (i) {
          if (i == 0) {
            Navigator.pop(context);
          } else {
            setState(() => _tabActual = i);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Usuarios',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_pin_outlined),
            label: 'Propietarios',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_work_outlined),
            label: 'Propiedades',
          ),
        ],
      ),
    );
  }
}

// ── Tab genérico ────────────────────────────────────────────────────────────────

class _TabLista extends StatelessWidget {
  final List<UsuarioResponse> Function(UsuarioProvider) selector;
  final void Function(UsuarioResponse) onTap;
  final String emptyMessage;
  final IconData emptyIcon;
  final String busqueda;

  const _TabLista({
    required this.selector,
    required this.onTap,
    required this.emptyMessage,
    required this.busqueda,
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

        final base = selector(provider);
        final lista = busqueda.isEmpty
            ? base
            : base
                .where((u) => u.nombre.toLowerCase().contains(busqueda))
                .toList();

        if (lista.isEmpty) {
          return _EmptyView(mensaje: emptyMessage, icono: emptyIcon);
        }

        return RefreshIndicator(
          onRefresh: () => context.read<UsuarioProvider>().cargarTodos(),
          child: ListView.builder(
            padding: const EdgeInsets.only(
              left: 0,
              right: 0,
              top: 8,
              bottom: 88,
            ),
            itemCount: lista.length,
            itemBuilder: (_, i) =>
                UsuarioCard(usuario: lista[i], onTap: () => onTap(lista[i])),
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

  const _EmptyView({required this.mensaje, this.icono = Icons.people_outline});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
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
