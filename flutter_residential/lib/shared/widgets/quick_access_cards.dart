import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

class QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final double? iconSize;
  final TextStyle? titleStyle;
  final Color? colorText;

  /// Contador opcional sobre el icono. null o 0 => no se pinta.
  final int? badge;

  const QuickAccessCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.backgroundColor,
    this.iconBackgroundColor,
    this.iconColor,
    this.iconSize = 16,
    this.titleStyle,
    this.colorText,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = backgroundColor ?? (isDark ? cs.surface : Colors.white);
    final fgIcono = iconColor ?? Colors.white;
    final tieneBadge = badge != null && badge! > 0;

    return Semantics(
      label: title,
      hint: 'Toca para abrir',
      button: true,
      value: tieneBadge ? '${badge! > 99 ? "99+" : badge} pendientes' : null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.onSurface.withValues(alpha: 0.08),
                blurRadius: 0,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBackgroundColor ?? cs.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: fgIcono,
                    ),
                  ),
                  if (tieneBadge)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          // El badge toma el color fuerte de la tarjeta y el
                          // texto el fondo suave: contraste correcto en light y
                          // en dark sin mantener una tabla de color aparte.
                          color: fgIcono,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: bg, width: 1.5),
                        ),
                        child: Text(
                          badge! > 99 ? '99+' : '${badge!}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: bg,
                            fontSize: 9,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: titleStyle ??
                    Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorText,
                          fontSize: 10,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickAccessGrid extends StatelessWidget {
  final List<QuickAccessCardData> cards;
  final int crossAxisCount;
  final double spacing;
  final EdgeInsets padding;

  const QuickAccessGrid({
    super.key,
    required this.cards,
    this.crossAxisCount = 3,
    this.spacing = 20,
    this.padding = const EdgeInsets.only(left: 18, right: 18, top: 0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1.0,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return QuickAccessCard(
            icon: card.icon,
            title: card.title,
            onTap: card.onTap,
            backgroundColor: card.backgroundColor,
            iconBackgroundColor: card.iconBackgroundColor,
            iconColor: card.iconColor,
            iconSize: card.iconSize,
            titleStyle: card.titleStyle,
            colorText: card.colorText,
            badge: card.badge,
          );
        },
      ),
    );
  }
}

class QuickAccessCardData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final double? iconSize;
  final TextStyle? titleStyle;
  final Color? colorText;
  final int? badge;

  QuickAccessCardData({
    required this.icon,
    required this.title,
    required this.onTap,
    this.backgroundColor,
    this.iconBackgroundColor,
    this.iconColor,
    this.iconSize,
    this.titleStyle,
    this.colorText,
    this.badge,
  });

  /// Unico punto donde se resuelve la paleta light/dark de una quick access
  /// card. Cualquier pantalla que la use queda consistente en ambos temas sin
  /// repetir el resolve ni el juego de colores del icono.
  factory QuickAccessCardData.tema({
    required IconData icon,
    required String title,
    required Color bgLight,
    required Color fgLight,
    required bool isDark,
    required VoidCallback onTap,
    int? badge,
  }) {
    final p = PaletteQuickAccessCard.resolve(bgLight, fgLight, isDark);
    return QuickAccessCardData(
      icon: icon,
      title: title,
      onTap: onTap,
      badge: badge,
      backgroundColor: p.bg,
      // En light el circulo es blanco (como hasta ahora); en dark el blanco
      // quema, asi que se usa el propio color de acento translucido.
      iconBackgroundColor: isDark ? p.fg.withValues(alpha: 0.14) : Colors.white,
      iconColor: p.fg,
      colorText: p.fg,
    );
  }
}
