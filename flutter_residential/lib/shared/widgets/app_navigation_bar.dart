import 'package:flutter/material.dart';

/// Barra inferior de las homes por rol. Solo aporta el ESTILO; los destinos los
/// pone cada rol.
///
/// Se extrajo de `BottomNavigationBarAdmin` cuando apareció la home del
/// contador, que necesita el mismo aspecto pero con pestañas que dependen de
/// los permisos del usuario. Duplicar el estilo habría dejado dos barras que se
/// desincronizan al primer ajuste de tema.
class AppNavigationBar extends StatelessWidget {
  final int tabActual;
  final void Function(int) onTabChanged;
  final ColorScheme colorScheme;

  /// Pares de iconos y etiqueta. Se pasan planos (no `NavigationDestination`)
  /// para que quien los define no tenga que conocer los colores del estilo.
  final List<AppNavItem> items;

  const AppNavigationBar({
    super.key,
    required this.tabActual,
    required this.onTabChanged,
    required this.colorScheme,
    required this.items,
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
            return TextStyle(color: onBg.withValues(alpha: 0.6), fontSize: 12);
          }),
        ),
        child: NavigationBar(
          backgroundColor: colorScheme.primary,
          // clamp defensivo: si el número de pestañas cambia en caliente
          // (permisos revocados mientras la app está abierta) el índice viejo
          // podría quedar fuera de rango y NavigationBar lanza excepción.
          selectedIndex: tabActual.clamp(0, items.length - 1),
          onDestinationSelected: onTabChanged,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: items
              .map((i) => NavigationDestination(
                    icon: Icon(i.icon, color: onBg.withValues(alpha: 0.6)),
                    selectedIcon: Icon(i.selectedIcon ?? i.icon, color: onBg),
                    label: i.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

/// Una pestaña de [AppNavigationBar].
class AppNavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const AppNavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}
