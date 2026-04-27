import 'package:flutter/material.dart';
import 'package:flutter_residential/providers/app_provider.dart';
import 'package:flutter_residential/widgets/theme_toggle_switch.dart';
import 'package:provider/provider.dart';
import 'package:flutter_residential/providers/auth_provider.dart';

class AppBarAdmin extends StatelessWidget implements PreferredSizeWidget {
  final AuthProvider auth;
  final ColorScheme cs;
  final bool habilitarlogout;

  const AppBarAdmin({
    super.key,
    required this.auth,
    required this.cs,
    required this.habilitarlogout,
  });

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    return AppBar(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      title: Align(
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              domadorDeGritosGraficos(auth.nombreConjunto ?? ''),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.5,
                color: cs.onSurface,
              ),
            ),
            if (!habilitarlogout)
              Text(
                domadorDeGritosGraficos(auth.nombre ?? ''),
                style: TextStyle(fontSize: 10),
              ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Row(
            children: [
              ThemeToggleSwitch(
                isDark: appProvider.themeMode == ThemeMode.dark,
                onToggle: appProvider.toggleTheme,
              ),
              const SizedBox(width: 8),
              if (habilitarlogout)
                IconButton(
                  icon: Icon(Icons.logout, color: cs.error),
                  tooltip: 'Cerrar sesión',
                  onPressed: () => _confirmarLogout(context),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmarLogout(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmado == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  String domadorDeGritosGraficos(String text) {
    const lowerWords = ['de', 'la', 'el', 'los', 'las', 'y', 'en'];

    return text
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((word) {
          if (lowerWords.contains(word)) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
