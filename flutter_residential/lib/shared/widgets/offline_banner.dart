import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/connectivity_provider.dart';

/// Envuelve cualquier widget y muestra un banner persistente en la parte superior
/// cuando no hay conexión a internet. El banner desaparece automáticamente
/// al recuperar la señal.
class OfflineGuard extends StatelessWidget {
  final Widget child;
  const OfflineGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Selector<ConnectivityProvider, bool>(
      selector: (_, p) => p.isOffline,
      builder: (context, isOffline, child) {
        return Stack(
          children: [
            child!,
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              top: isOffline ? 0 : -60,
              left: 0,
              right: 0,
              child: const _OfflineBanner(),
            ),
          ],
        );
      },
      child: child,
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Material(
      elevation: 4,
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.only(
          top: topPadding + 6,
          bottom: 8,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF323232),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 16),
            SizedBox(width: 8),
            Text(
              'Sin conexión a internet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
