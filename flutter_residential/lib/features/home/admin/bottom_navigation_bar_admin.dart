import 'package:flutter/material.dart';

import '../../../shared/widgets/app_navigation_bar.dart';

/// Pestañas de la home del administrador.
///
/// El estilo vive en [AppNavigationBar], compartido con la home del contador:
/// acá solo se declara QUÉ pestañas tiene el admin.
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

  static const _items = [
    AppNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Inicio',
    ),
    AppNavItem(
      icon: Icons.groups_2_rounded,
      selectedIcon: Icons.groups,
      label: 'Usuarios',
    ),
    AppNavItem(
      icon: Icons.apartment_outlined,
      selectedIcon: Icons.apartment_rounded,
      label: 'Propiedades',
    ),
    AppNavItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person_rounded,
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppNavigationBar(
      tabActual: tabActual,
      onTabChanged: onTabChanged,
      colorScheme: colorScheme,
      items: _items,
    );
  }
}
