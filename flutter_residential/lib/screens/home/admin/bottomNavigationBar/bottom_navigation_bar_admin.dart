import 'package:flutter/material.dart';
import 'package:flutter_residential/screens/home/admin/screens/usuarios/usuarios_screen.dart';
import 'package:flutter_residential/theme/app_theme.dart';

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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(28),
        
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: AppColors.bgBlue,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold);
            }
            return null; // usa el estilo del tema por defecto
          }),
        ),
        child: NavigationBar(
          surfaceTintColor: colorScheme.primary,
          selectedIndex: tabActual,
          onDestinationSelected: (i) {
            onTabChanged(i);
            if (tabActual!=i && i == 0) {
              Navigator.pop(
                context);
            }else if (tabActual!=i && i == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsuariosScreen()),
              ).then((_) => onTabChanged(0));
            }
          },
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: AppColors.blue,
              ),
              label: 'Inicio'
            ),
            const NavigationDestination(icon: Icon(Icons.people_outline,color: AppColors.blue,), label: 'Usuarios'),
            const NavigationDestination(icon: Icon(Icons.person_pin_outlined), label: 'Propietarios'),
            const NavigationDestination(icon: Icon(Icons.home_work_outlined), label: 'Propiedades'),
          ],
        ),
      ),
    );
  }
}
