import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/segmented_pills.dart';
import '../../../auditoria/screens/admin_auditoria_screen.dart';
import '../../../auth/providers/auth_provider.dart';
import 'cobros_tab_view.dart';
import 'cobranza_tab_view.dart';
import 'cobros_config_screen.dart';

/// Hub unificado del módulo de cobros para el rol admin.
///
/// Unifica en un control segmentado (Cobros / Cobranza) la operación de
/// cobros y la gestión de cobranza (morosos). El AppBar queda limpio: lock
/// para cerrar período (solo en Cobros) y un menú con configuración.
class CobrosHubScreen extends StatefulWidget {
  /// 0 = Cobros, 1 = Cobranza. Permite abrir directo en una pestaña.
  final int initialTab;

  /// True cuando la pantalla es una pestaña del IndexedStack de una home (la
  /// del contador). En ese caso el encabezado del contenedor es el único: acá
  /// se omite el AppBar y las acciones se mueven junto al selector.
  ///
  /// Sin esto habría doble encabezado, y además el IndexedStack mide las
  /// pestañas ocultas con constraints de ~1px, donde una fila de `actions:` no
  /// se puede comprimir y revienta con un RenderFlex overflow.
  final bool embebida;

  const CobrosHubScreen({super.key, this.initialTab = 0, this.embebida = false});

  @override
  State<CobrosHubScreen> createState() => _CobrosHubScreenState();
}

class _CobrosHubScreenState extends State<CobrosHubScreen> {
  final GlobalKey<CobrosTabViewState> _cobrosKey =
      GlobalKey<CobrosTabViewState>();
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab.clamp(0, 1);
  }

  void _abrirConfiguracion() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CobrosConfigScreen()),
      );

  void _abrirAuditoria() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminAuditoriaScreen()),
      );

  /// Acciones del encabezado. Se arman una sola vez y se colocan en el AppBar
  /// o al lado del selector según el modo, para no mantener dos listas.
  List<Widget> _acciones() => [
        if (_index == 0)
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Cerrar período',
            onPressed: () => _cobrosKey.currentState?.cerrarPeriodoActual(),
          ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Configuración',
          onPressed: _abrirConfiguracion,
        ),
        // Auditoría: solo el administrador. El contador comparte esta pantalla
        // pero no puede revisar su propio rastro — el backend lo rechaza con
        // 403 igual, así que aquí ni se ofrece.
        if (context.watch<AuthProvider>().isAdmin)
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Auditoría financiera',
            onPressed: _abrirAuditoria,
          ),
      ];

  @override
  Widget build(BuildContext context) {
    final acciones = _acciones();

    return Scaffold(
      appBar: widget.embebida
          ? null
          : AppBar(title: const Text('Cobros'), actions: acciones),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedPills(
                    labels: const ['Cobros', 'Cobranza'],
                    icons: const [
                      Icons.receipt_long_outlined,
                      Icons.gavel_outlined,
                    ],
                    selectedIndex: _index,
                    onChanged: (i) => setState(() => _index = i),
                  ),
                ),
                // Embebida: las acciones viven acá porque no hay AppBar donde
                // ponerlas. El Expanded de arriba deja que la fila se comprima
                // sin desbordar cuando el IndexedStack mide la pestaña oculta.
                if (widget.embebida) ...acciones,
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                CobrosTabView(key: _cobrosKey),
                const CobranzaTabView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
