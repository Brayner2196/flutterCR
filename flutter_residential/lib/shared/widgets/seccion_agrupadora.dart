import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

class SeccionAgrupadora extends StatelessWidget {
  final String titulo;
  final List<Widget> items;

  const SeccionAgrupadora({
    super.key,
    required this.titulo,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Text(
            titulo.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast)
                    Divider(
                        height: 1,
                        indent: AppSpacing.md + 32 + AppSpacing.md,
                        endIndent: 0),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}