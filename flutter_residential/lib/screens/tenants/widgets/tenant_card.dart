import 'package:flutter/material.dart';
import '../../../models/tenant_response.dart';

class TenantCard extends StatelessWidget {
  final TenantResponse tenant;
  final VoidCallback onEditar;
  final VoidCallback onDesactivar;

  const TenantCard({
    super.key,
    required this.tenant,
    required this.onEditar,
    required this.onDesactivar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activo = tenant.activo;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tenant.nombre,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: activo
                        ? Colors.green.withOpacity(0.15)
                        : Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    activo ? 'Activo' : 'Inactivo',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: activo ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'editar') onEditar();
                    if (value == 'desactivar') onDesactivar();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    if (activo)
                      const PopupMenuItem(
                        value: 'desactivar',
                        child: Row(
                          children: [
                            Icon(Icons.block_outlined, size: 20,
                                color: Colors.red),
                            SizedBox(width: 8),
                            Text('Desactivar',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icono: Icons.tag,
              texto: 'Código: ${tenant.codigo}',
            ),
            _InfoRow(
              icono: Icons.storage_outlined,
              texto: 'Schema: ${tenant.schemaName}',
            ),
            if (tenant.direccion != null && tenant.direccion!.isNotEmpty)
              _InfoRow(
                icono: Icons.location_on_outlined,
                texto: tenant.direccion!,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _InfoRow({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icono, size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
