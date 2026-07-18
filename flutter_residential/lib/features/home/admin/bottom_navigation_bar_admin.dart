import 'package:flutter/material.dart';

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
          onDestinationSelected: onTabChanged,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined,
                  color: onBg.withValues(alpha: 0.6)),
              selectedIcon: Icon(Icons.home_rounded, color: onBg),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_2_rounded,
                  color: onBg.withValues(alpha: 0.6)),
              selectedIcon: Icon(Icons.groups, color: onBg),
              label: 'Usuarios',
            ),
            NavigationDestination(
              icon: Icon(Icons.apartment_outlined,
                  color: onBg.withValues(alpha: 0.6)),
              selectedIcon: Icon(Icons.apartment_rounded, color: onBg),
              label: 'Propiedades',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline,
                  color: onBg.withValues(alpha: 0.6)),
              selectedIcon: Icon(Icons.person_rounded, color: onBg),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
