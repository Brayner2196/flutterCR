import 'package:flutter/material.dart';

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
    this.colorText
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? (isDark ? cs.surface : Colors.white),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cs.onSurface.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
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
                color: iconColor ?? Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: titleStyle ?? 
                  Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorText,
                        fontSize: 10
                      ),
            ),
          ],
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
    this.spacing = 16,
    this.padding = const EdgeInsets.only(left: 18,right: 18,top:0),
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
          childAspectRatio: 1.20,
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
  });
}
