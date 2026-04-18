import 'package:flutter/material.dart';
import 'package:flutter_residential/core/enums/enum_mod_layouts_screen_tenants.dart';
import 'package:flutter_residential/screens/tenants/widgets/mod_layout_table.dart';
import 'package:flutter_residential/screens/tenants/widgets/tenant_form_insert_edit_dialog.dart';
import 'package:flutter_residential/screens/tenants/widgets/tenant_layout_switcher.dart';
import 'package:flutter_residential/screens/tenants/widgets/filter_capsula.dart';
import 'package:provider/provider.dart';
import '../../providers/tenant_provider.dart';
import '../../models/tenant_response.dart';
import 'widgets/tenant_card.dart';
import 'widgets/tenant_header_widget.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'todos'; // todos | activos | inactivos
  ModosLayouts _layout = ModosLayouts.list;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<TenantProvider>().cargarTodos(),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _abrirFormulario({TenantResponse? tenant}) {
    showDialog(
      context: context,
      builder: (_) => TenantFormDialog(tenant: tenant),
    );
  }

  Future<void> _confirmarActivar(TenantResponse tenant) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Activar Tenant'),
        content: Text('¿Deseas activar "${tenant.nombre}" nuevamente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Activar'),
          ),
        ],
      ),
    );

    if (confirmado == true && mounted) {
      try {
        await context.read<TenantProvider>().activar(tenant.id);
      } catch (_) {}
    }
  }

  Future<void> _confirmarDesactivar(TenantResponse tenant) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar Tenant'),
        content: Text(
          '¿Deseas desactivar "${tenant.nombre}"? Los datos se conservarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirmado == true && mounted) {
      try {
        await context.read<TenantProvider>().desactivar(tenant.id);
      } catch (_) {}
    }
  }

  List<TenantResponse> _filtrar(List<TenantResponse> all) {
    return all.where((t) {
      if (_filter == 'activos' && !t.activo) return false;
      if (_filter == 'inactivos' && t.activo) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return t.nombre.toLowerCase().contains(q) ||
          t.codigo.toLowerCase().contains(q) ||
          (t.direccion?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Consumer<TenantProvider>(
      builder: (_, provider, __) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _ErrorView(
            mensaje: provider.error!,
            onReintentar: () => context.read<TenantProvider>().cargarTodos(),
          );
        }

        final all = provider.tenants;
        final activos = all.where((t) => t.activo).length;
        final inactivos = all.length - activos;
        final lista = _filtrar(all);

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => context.read<TenantProvider>().cargarTodos(),
              child: CustomScrollView(
                slivers: [
                  // ─── Header con KPIs ───
                  SliverToBoxAdapter(
                    child: TenantHeaderWidget(
                      total: all.length,
                      activos: activos,
                      inactivos: inactivos,
                    ),
                  ),

                  // ─── Search + layout switcher ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (v) => setState(() => _query = v),
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Buscar tenant, código…',
                                  hintStyle: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(Icons.search,
                                      size: 18, color: cs.onSurfaceVariant),
                                  prefixIconConstraints: const BoxConstraints(
                                      minWidth: 38, minHeight: 38),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TenantLayoutSwitcher(
                            mode: _layout,
                            onChanged: (m) => setState(() => _layout = m),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── Filter chips ───
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          FilterCapsula(
                            label: 'Todos',
                            count: all.length,
                            selected: _filter == 'todos',
                            onTap: () => setState(() => _filter = 'todos'),
                          ),
                          FilterCapsula(
                            label: 'Activos',
                            count: activos,
                            selected: _filter == 'activos',
                            onTap: () => setState(() => _filter = 'activos'),
                          ),
                          FilterCapsula(
                            label: 'Inactivos',
                            count: inactivos,
                            selected: _filter == 'inactivos',
                            onTap: () => setState(() => _filter = 'inactivos'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── Lista / grid / tabla ───
                  if (lista.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyView(),
                    )
                  else if (_layout == ModosLayouts.table)
                    SliverToBoxAdapter(
                      child: ModLayoutTable(
                        tenants: lista,
                        usuarios: 9,
                        onTapTenant: (t) => _abrirFormulario(tenant: t),
                      ),
                    )
                  else if (_layout == ModosLayouts.grid)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 0,
                          childAspectRatio: 0.82,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final t = lista[i];
                            return TenantCard(
                              tenant: t,
                              usuariosCount: t.cantidadUsuarios,
                              onEditar: () => _abrirFormulario(tenant: t),
                              onDesactivar: () => _confirmarDesactivar(t),
                              onActivar: () => _confirmarActivar(t),
                            );
                          },
                          childCount: lista.length,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 4, bottom: 90),
                      sliver: SliverList.builder(
                        itemCount: lista.length,
                        itemBuilder: (_, i) {
                          final t = lista[i];
                          return TenantCard(
                            tenant: t,
                            usuariosCount: t.cantidadUsuarios,
                            onEditar: () => _abrirFormulario(tenant: t),
                            onDesactivar: () => _confirmarDesactivar(t),
                            onActivar: () => _confirmarActivar(t),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () => _abrirFormulario(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Tenant'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.apartment_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No hay tenants que coincidan',
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
