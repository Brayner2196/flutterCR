import 'package:flutter/material.dart';
import 'cobros_tab_view.dart';
import 'cobranza_tab_view.dart';
import 'cobros_config_screen.dart';
import 'admin_cobro_especial_screen.dart';

/// Hub unificado del módulo de cobros para el rol admin.
///
/// Reemplaza la antigua `AdminCobrosScreen` y unifica en pestañas lo que antes
/// estaba disperso: operación de cobros y gestión de cobranza (morosos).
/// El AppBar queda limpio: solo un menú con cobro especial y configuración
/// (cuotas/mora/pasarelas), en lugar de los cinco iconos sueltos anteriores.
class CobrosHubScreen extends StatefulWidget {
  /// 0 = Cobros, 1 = Cobranza. Permite abrir directo en una pestaña.
  final int initialTab;

  const CobrosHubScreen({super.key, this.initialTab = 0});

  @override
  State<CobrosHubScreen> createState() => _CobrosHubScreenState();
}

class _CobrosHubScreenState extends State<CobrosHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final GlobalKey<CobrosTabViewState> _cobrosKey =
      GlobalKey<CobrosTabViewState>();

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _abrirCobroEspecial() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminCobroEspecialScreen()),
    );
    if (result == true) _cobrosKey.currentState?.recargar();
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
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            onSelected: (v) {
              if (v == 'especial') _abrirCobroEspecial();
              if (v == 'config') _abrirConfiguracion();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'especial',
                child: ListTile(
                  leading: Icon(Icons.receipt_long_outlined),
                  title: Text('Cobro especial'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'config',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Configuración'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Cobros'),
            Tab(icon: Icon(Icons.gavel_outlined), text: 'Cobranza'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          CobrosTabView(key: _cobrosKey),
          const CobranzaTabView(),
        ],
      ),
    );
  }
}
