import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tenant_provider.dart';
import '../../models/tenant_response.dart';
import 'widgets/tenant_card.dart';
import 'widgets/tenant_form_dialog.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<TenantProvider>().cargarTodos(),
    );
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

  @override
  Widget build(BuildContext context) {
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

        return Stack(
          children: [
            if (provider.tenants.isEmpty)
              const _EmptyView()
            else
              RefreshIndicator(
                onRefresh: () => context.read<TenantProvider>().cargarTodos(),
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                      top: 8, left: 0, right: 0, bottom: 80),
                  itemCount: provider.tenants.length,
                  itemBuilder: (_, i) {
                    final t = provider.tenants[i];
                    return TenantCard(
                      tenant: t,
                      onEditar: () => _abrirFormulario(tenant: t),
                      onDesactivar: () => _confirmarDesactivar(t),
                      onActivar: () => _confirmarActivar(t),
                    );
                  },
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
            'No hay tenants registrados',
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
