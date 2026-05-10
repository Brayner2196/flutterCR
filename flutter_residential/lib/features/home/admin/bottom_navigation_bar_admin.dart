import 'package:flutter/material.dart';
import 'package:flutter_residential/features/usuarios/screens/admin/usuarios_screen.dart';
import 'package:flutter_residential/screens/home/admin/widget_edificio_grafico.dart/isometric_progress_ring.dart';

class BottomNavigationBarAdmin extends StatelessWidget {
  final int tabActual;
  final void Function(int) onTabChanged;
  final ColorScheme colorScheme;

  const BottomNavigationBarAdmin({
    super.key,
    required this.tabActual,
    required this.onTabChanged,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final onBg = colorScheme.onPrimaryContainer;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: Colors.transparent,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: onBg, size: 24);
            }
            return IconThemeData(color: onBg.withValues(alpha: 0.6), size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                color: onBg,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              );
            }
            return TextStyle(
              color: onBg.withValues(alpha: 0.6),
              fontSize: 12,
            );
          }),
        ),
        child: NavigationBar(
          backgroundColor: colorScheme.primary,
          selectedIndex: tabActual,
          onDestinationSelected: (i) {
            onTabChanged(i);
            if (tabActual != i && i == 0) {
              Navigator.pop(context);
            } else if (tabActual != i && i == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsuariosScreen()),
              ).then((_) => onTabChanged(0));
            } else if (tabActual != i && i == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: SingleChildScrollView(
                      child: Column(
                        children: [
                          IsometricProgressRing(
                            percentage: 0.60,
                            size: 200,
                          ),
                          const SizedBox(height: 10),
                          IsometricProgressRing(
                            percentage: 0.25,
                            size: 300,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).then((_) => onTabChanged(0));
            }
          },
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined,
                  color: onBg.withValues(alpha: 0.6)),
              selectedIcon: Icon(Icons.home_rounded, color: onBg),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline,
                  color: onBg.withValues(alpha: 0.6)),
              selectedIcon: Icon(Icons.people_rounded, color: onBg),
              label: 'Usuarios',
            ),
            NavigationDestination(
              icon: Icon(Icons.business_outlined,
                  color: onBg.withValues(alpha: 0.6)),
              selectedIcon: Icon(Icons.business_rounded, color: onBg),
              label: 'Edificios',
            ),
          ],
        ),
      ),
    );
  }
}
