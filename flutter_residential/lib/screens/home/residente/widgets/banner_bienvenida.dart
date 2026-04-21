import 'package:flutter/material.dart';

class BannerBienvenidaResidente extends StatelessWidget {
  final String nombreUser;

  const BannerBienvenidaResidente({super.key, required this.nombreUser});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final String nom = nombreUser.split(" ").first;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 12.0,
          right: 12.0,
          top: 12.0,
          bottom: 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido a casa, $nom! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '🏠  Vivir bien es también estar informado.',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
