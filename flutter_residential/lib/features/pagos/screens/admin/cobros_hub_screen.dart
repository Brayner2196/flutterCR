import 'package:flutter/material.dart';
import '../../../../shared/widgets/segmented_pills.dart';
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

  const CobrosHubScreen({super.key, this.initialTab = 0});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobros'),
        actions: [
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
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
