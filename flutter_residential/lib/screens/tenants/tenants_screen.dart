import 'package:flutter/material.dart';
import 'package:flutter_residential/core/enums/enum_mod_layouts_screen_tenants.dart';
import 'package:flutter_residential/screens/tenants/widgets/mod_layout_table.dart';
import 'package:flutter_residential/screens/tenants/widgets/tenant_form_insert_edit_dialog.dart';
import 'package:flutter_residential/screens/tenants/widgets/tenant_layout_switcher.dart';
import 'package:flutter_residential/screens/tenants/widgets/tenants_error_view.dart';
import 'package:flutter_residential/screens/tenants/wizard/tenant_wizard_screen.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/tenant_provider.dart';
import '../../models/tenant_response.dart';
import 'widgets/tenant_card.dart';
import 'widgets/tenant_header_widget.dart';
import 'widgets/tenants_empty_view.dart';

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

  /// Crea nuevo → abre wizard multi-paso
  void _abrirWizardCrear() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TenantWizardScreen()),
    );
  }

  /// Edita existente → sigue usando el dialog compacto
  void _abrirDialogEditar(TenantResponse tenant) {
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
          return TenantsErrorView(
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
                  // ─── Banner + KPIs ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: TenantHeaderWidget(
                      total: all.length,
                      activos: activos,
                      inactivos: inactivos,
                    ),
                  ),

                  // ─── Barra de búsqueda + switcher layout ──────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (v) => setState(() => _query = v),
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Buscar por nombre, código…',
                                  hintStyle: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(Icons.search,
                                      size: 18, color: cs.onSurfaceVariant),
                                  prefixIconConstraints: const BoxConstraints(
                                      minWidth: 40, minHeight: 40),
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 10),
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

                  // ─── Chips de filtro ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _FilterChipCustom(
                            label: 'Todos',
                            count: all.length,
                            selected: _filter == 'todos',
                            color: cs.primary,
                            onTap: () => setState(() => _filter = 'todos'),
                          ),
                          _FilterChipCustom(
                            label: 'Activos',
                            count: activos,
                            selected: _filter == 'activos',
                            color: AppColors.ok,
                            onTap: () => setState(() => _filter = 'activos'),
                          ),
                          _FilterChipCustom(
                            label: 'Inactivos',
                            count: inactivos,
                            selected: _filter == 'inactivos',
                            color: cs.onSurfaceVariant,
                            onTap: () => setState(() => _filter = 'inactivos'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // ─── Lista / grid / tabla ─────────────────────────────
                  if (lista.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: TenantsEmptyView(),
                    )
                  else if (_layout == ModosLayouts.table)
                    SliverToBoxAdapter(
                      child: ModLayoutTable(
                        tenants: lista,
                        usuarios: 9,
                        onTapTenant: (t) => _abrirDialogEditar(t),
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
                              onEditar: () => _abrirDialogEditar(t),
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
                            onEditar: () => _abrirDialogEditar(t),
                            onDesactivar: () => _confirmarDesactivar(t),
                            onActivar: () => _confirmarActivar(t),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // ─── FAB nuevo tenant ──────────────────────────────────────
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: _abrirWizardCrear,
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_business_outlined),
                label: const Text(
                  'Nuevo Tenant',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Chip de filtro estilizado ────────────────────────────────────────────────

class _FilterChipCustom extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChipCustom({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.5) : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.15)
                    : cs.outline.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
