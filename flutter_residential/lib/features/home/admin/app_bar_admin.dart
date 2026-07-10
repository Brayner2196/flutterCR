import 'package:flutter/material.dart';
import 'package:flutter_residential/features/auth/providers/auth_provider.dart';
import 'package:flutter_residential/core/utils/texto_utils.dart';

class AppBarAdmin extends StatelessWidget implements PreferredSizeWidget {
  final AuthProvider auth;
  final ColorScheme cs;
  final bool habilitarlogout;
  final bool habilitarReturnScreen;

  const AppBarAdmin({
    super.key,
    required this.auth,
    required this.cs,
    required this.habilitarlogout,
    required this.habilitarReturnScreen,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            // Avatar con iniciales del usuario
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                TextoUtils.getIniciales(auth.nombre ?? 'Usuario'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                auth.nombreConjunto ?? 'Conjunto Residencial',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: -0.5,
                  color: cs.primary,
                ),
              ),
              Text(
                auth.nombre ?? 'Usuario',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),

            ],
          )
        ],
      ),
    );
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
