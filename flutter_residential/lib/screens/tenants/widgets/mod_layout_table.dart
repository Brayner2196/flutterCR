import 'package:flutter/material.dart';
import 'package:flutter_residential/models/tenant_response.dart';

class ModLayoutTable extends StatelessWidget {
  final List<TenantResponse> tenants;
  final int usuarios;
  final void Function(TenantResponse) onTapTenant;

  const ModLayoutTable({super.key, 
    required this.tenants,
    required this.usuarios,
    required this.onTapTenant,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 90),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(flex: 5, child: _hdr(context, 'TENANT')),
                Expanded(flex: 2, child: _hdr(context, 'USR.')),
                SizedBox(width: 76, child: _hdr(context, 'ESTADO')),
              ],
            ),
          ),
          // Rows
          for (int i = 0; i < tenants.length; i++)
            _row(context, tenants[i], isLast: i == tenants.length - 1),
        ],
      ),
    );
  }

  Widget _hdr(BuildContext ctx, String s) => Text(
    s,
    style: TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
    ),
  );

  Widget _row(BuildContext ctx, TenantResponse t, {required bool isLast}) {
    final cs = Theme.of(ctx).colorScheme;
    return InkWell(
      onTap: () => onTapTenant(t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.codigo,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                t.cantidadUsuarios.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            SizedBox(
              width: 76,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
                  decoration: BoxDecoration(
                    color: t.activo
                        ? const Color(0xFFE4EDE3)
                        : const Color(0xFFECECEA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: t.activo
                              ? const Color(0xFF3F7A4F)
                              : cs.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        t.activo ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: t.activo
                              ? const Color(0xFF3F7A4F)
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
}
