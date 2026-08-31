import 'package:flutter/material.dart';

import '../models/pasarela_disponible_model.dart';
import 'pasarela_logo_widget.dart';

/// Bottom sheet para elegir con qué pasarela pagar.
///
/// Estaba duplicado: uno en `PasarelaSelector` y otro dentro de la tarjeta de cobro
/// del estado de cuenta, con distinto ícono y distinto texto para lo mismo. Al vivir
/// en un solo lugar, el residente ve siempre la misma pantalla venga de donde venga,
/// y agregar una pasarela nueva no obliga a acordarse del segundo sitio.
Future<TipoPasarela?> mostrarSelectorPasarela(
  BuildContext context,
  List<PasarelaDisponibleModel> pasarelas,
) {
  return showModalBottomSheet<TipoPasarela>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _SelectorPasarelaSheet(pasarelas: pasarelas),
  );
}

class _SelectorPasarelaSheet extends StatelessWidget {
  final List<PasarelaDisponibleModel> pasarelas;

  const _SelectorPasarelaSheet({required this.pasarelas});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Elige método de pago',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Todas procesan el pago al instante',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            ...pasarelas.map(
              (p) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: PasarelaLogoWidget(tipo: p.tipo, size: 44),
                title: Text(
                  p.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: p.prioridad == 1
                    ? const Text(
                        'Recomendado',
                        style: TextStyle(color: Colors.teal, fontSize: 12),
                      )
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, p.tipo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
