import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/opcion_tenant.dart';

class SeleccionTenantScreen extends StatefulWidget {
  const SeleccionTenantScreen({super.key});

  @override
  State<SeleccionTenantScreen> createState() => _SeleccionTenantScreenState();
}

class _SeleccionTenantScreenState extends State<SeleccionTenantScreen> {
  String? _tenantSeleccionado;
  bool _cargando = false;

  Future<void> _confirmar() async {
    if (_tenantSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un conjunto para continuar')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      await context.read<AuthProvider>().seleccionarTenant(_tenantSeleccionado!);
      // SplashScreen reacciona automáticamente al cambio de status
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final conjuntos = auth.multiTenantPendiente?.conjuntos ?? <OpcionTenant>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Conjunto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _cargando ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu cuenta tiene acceso a varios conjuntos.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '¿A cuál deseas ingresar?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView.separated(
                itemCount: conjuntos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final conjunto = conjuntos[index];
                  final seleccionado = _tenantSeleccionado == conjunto.tenantId;

                  return InkWell(
                    onTap: _cargando
                        ? null
                        : () => setState(
                              () => _tenantSeleccionado = conjunto.tenantId,
                            ),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: seleccionado
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: seleccionado ? 2 : 1,
                        ),
                        color: seleccionado
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surface,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: seleccionado
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.apartment,
                              color: seleccionado
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  conjunto.nombre,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: seleccionado
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: seleccionado
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                ),
                                if (conjunto.direccion != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    conjunto.direccion!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (seleccionado)
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargando ? null : _confirmar,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: _cargando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Continuar', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
