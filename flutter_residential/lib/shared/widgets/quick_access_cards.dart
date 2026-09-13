import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'package:flutter_residential/shared/utils/breakpoints.dart';

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

  /// Alto fijo (px) del card cuando la ventana es amplia.
  ///
  /// `null` => el card sigue siendo cuadrado en todos los anchos, que es el
  /// comportamiento historico. Con un valor, el alto deja de depender del
  /// ancho de la columna: en web una fila de 3 columnas da ~440px de ancho por
  /// card y el cuadrado convierte eso en 440px de alto.
  final double? altoCardAmplio;

  /// Ancho maximo por card en ventana amplia. El delegate reparte las columnas
  /// que quepan en vez de estirar [crossAxisCount] a lo ancho de la pantalla.
  /// Solo aplica cuando [altoCardAmplio] esta definido.
  final double anchoMaxCardAmplio;

  const QuickAccessGrid({
    super.key,
    required this.cards,
    this.crossAxisCount = 3,
    this.spacing = 20,
    this.padding = const EdgeInsets.only(left: 18, right: 18, top: 0),
    this.altoCardAmplio,
    this.anchoMaxCardAmplio = 180,
  });

  /// Unico punto donde se decide la geometria de la grilla, para que las
  /// pantallas solo declaren el dato (el alto deseado) y no la regla.
  SliverGridDelegate _delegate(double ancho) {
    final alto = altoCardAmplio;

    // Movil o ventana angosta: card cuadrado de [crossAxisCount] columnas.
    if (alto == null || !Breakpoints.esAmplio(ancho)) {
      return SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.0,
      );
    }

    // Ventana amplia: mainAxisExtent fija el alto en px y anula la relacion de
    // aspecto, asi el card no crece con el ancho de la pantalla.
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: anchoMaxCardAmplio,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      mainAxisExtent: alto,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) => GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: _delegate(constraints.maxWidth),
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
