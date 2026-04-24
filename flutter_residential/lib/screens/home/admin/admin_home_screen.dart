import 'package:flutter/material.dart';
import 'package:flutter_residential/screens/home/admin/appBar/app_bar_admin.dart';
import 'package:flutter_residential/screens/home/admin/bottomNavigationBar/bottom_navigation_bar_admin.dart';
import 'package:flutter_residential/screens/home/admin/widgets/quick_access_cards.dart';
import 'package:flutter_residential/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _tabActual = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBarAdmin(auth: auth, cs: cs),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Text(
                  'Hola, ${auth.nombre}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            QuickAccessGrid(
              cards: [
                QuickAccessCardData(
                  title: 'Gestionar Usuarios',
                  icon: Icons.groups,
                  backgroundColor: AppColors.bgBlue,
                  iconBackgroundColor: Colors.white,
                  iconColor: AppColors.blue,
                  colorText: AppColors.blue,
                  onTap: () => setState(() => _tabActual = 1),
                ),
                QuickAccessCardData(
                  title: 'Crear Anuncio',
                  icon: Icons.campaign_outlined,
                  backgroundColor: AppColors.bgYellow,
                  iconBackgroundColor: Colors.white,
                  iconColor: AppColors.yellow,
                  colorText: AppColors.yellow,
                  onTap: () => setState(() => _tabActual = 1)
                )
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarAdmin(
        tabActual: _tabActual,
        onTabChanged: (i) => setState(() => _tabActual = i),
        colorScheme: cs,
      ),
    );
  }

}
