import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/version/version_provider.dart';
import 'actualizacion_banner.dart';
import 'actualizacion_obligatoria_screen.dart';

/// Envuelve la app y decide qué hacer con la versión instalada.
///
/// Sigue la forma de `OfflineGuard`: una capa delgada que envuelve al hijo y
/// solo reacciona a un estado. Se apila junto a él en `main.dart` en lugar de
/// meter la lógica dentro de `InitialRouterScreen`, que ya tiene bastante con
/// decidir la home de cada rol.
///
/// Tres comportamientos, en orden de prioridad:
///  1. **Obligatoria** → reemplaza toda la app por la pantalla de bloqueo.
///  2. **Sugerida** → banner arriba, la app funciona normal por debajo.
///  3. **Cualquier otro caso**, incluido no haber podido consultar → nada.
///
/// El chequeo también se repite al volver del segundo plano: el usuario pudo
/// haber actualizado desde la tienda por su cuenta y sería absurdo seguirle
/// mostrando el aviso.
class ActualizacionGate extends StatefulWidget {
  final Widget child;

  const ActualizacionGate({super.key, required this.child});

  @override
  State<ActualizacionGate> createState() => _ActualizacionGateState();
}

class _ActualizacionGateState extends State<ActualizacionGate>
    with WidgetsBindingObserver {

  /// Se guarda la instancia del provider en un campo en vez de buscarla en
  /// `dispose()`: hacer un lookup por `context` cuando el widget ya está
  /// desmontado lanza "Looking up a deactivated widget's ancestor is unsafe".
  VersionProvider? _provider;
  StreamSubscription<String>? _subObsoleta;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Segunda vía de entrada: el backend rechazó una petición con 426. Pasa
    // cuando el umbral sube con la app ya abierta, sin reinicio de por medio.
    _subObsoleta = ApiClient.versionObsoletaStream.listen((mensaje) {
      _provider?.marcarObsoleta(mensaje);
    });

    // Diferido con addPostFrameCallback: tocar un provider dentro de
    // initState revienta en web y escritorio (mouse_tracker.dart:199).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _provider = context.read<VersionProvider>();
      _provider?.verificar();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _provider?.verificar(forzar: true);
    }
  }

  @override
  void dispose() {
    _subObsoleta?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VersionProvider>(
      builder: (context, version, child) {
        if (version.debeBloquear) {
          return const ActualizacionObligatoriaScreen();
        }

        return Stack(
          children: [
            child!,
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              top: version.mostrarBanner ? 0 : -110,
              left: 0,
              right: 0,
              child: const ActualizacionBanner(),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
