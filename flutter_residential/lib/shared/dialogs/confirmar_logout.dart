import 'package:flutter/material.dart';
import 'package:flutter_residential/features/auth/providers/auth_provider.dart';

class LogoutDialog {
  static Future<void> confirmar(
    BuildContext context,
    AuthProvider auth,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Estás seguro de que deseas salir?',
        ),
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
      await auth.logout();
    }
  }
}