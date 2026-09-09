import 'package:flutter/material.dart';

/// Fondo con color y esquinas redondeadas para envolver `ListTile` y sus
/// variantes (`SwitchListTile`, `CheckboxListTile`, `RadioListTile`,
/// `ExpansionTile`).
///
/// ## Por qué existe
///
/// Un `ListTile` NO pinta su fondo ni su ripple sobre sí mismo: los delega al
/// `Material` ancestro más cercano. Si entre el tile y ese `Material` hay un
/// `Container(decoration: BoxDecoration(color: ...))`, el color del contenedor
/// queda ENCIMA y tapa las dos cosas. Flutter lo detecta y lanza:
///
/// ```
/// ListTile background color or ink splashes may be invisible.
/// The ListTile is wrapped in a DecoratedBox that has a background color.
/// ```
///
/// El arreglo no es quitar el fondo, sino que el fondo lo pinte un `Material`:
/// así el tile encuentra un ancestro válido justo arriba y el ripple se dibuja
/// SOBRE el color, no debajo. `clipBehavior` lo recorta al radio, que es lo que
/// el `borderRadius` del `Container` hacía gratis.
///
/// El síntoma aparece sobre todo dentro de `showModalBottomSheet(
/// backgroundColor: Colors.transparent)`: ahí el `Material` del sheet no pinta
/// nada, así que el ripple se dibuja en una capa transparente por debajo del
/// color y no se ve nunca.
///
/// ## Uso
///
/// Es reemplazo directo del `Container` decorado: el `child` se deja igual.
///
/// ```dart
/// // antes
/// Container(
///   decoration: BoxDecoration(
///     color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
///     borderRadius: BorderRadius.circular(12),
///   ),
///   child: Column(children: [ ...tiles... ]),
/// )
///
/// // después
/// PanelTiles(
///   color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
///   child: Column(children: [ ...tiles... ]),
/// )
/// ```
class PanelTiles extends StatelessWidget {
  final Widget child;

  /// Fondo del panel. Por defecto `colorScheme.surface`.
  final Color? color;

  /// Radio uniforme de las esquinas. Por defecto 12. Lo ignora
  /// [radioPersonalizado] si viene.
  final double radio;

  /// Radio no uniforme, para bordes como los de un bottom sheet
  /// (`BorderRadius.vertical(top: ...)`).
  final BorderRadius? radioPersonalizado;

  /// Borde uniforme opcional. Equivale al `Border.all(...)` del `Container`.
  final BorderSide? lado;

  /// Separación exterior.
  final EdgeInsetsGeometry? margin;

  /// Separación interior, por dentro del color.
  final EdgeInsetsGeometry? padding;

  /// Decoración extra por dentro del `Material`, para bordes asimétricos que
  /// `RoundedRectangleBorder` no sabe expresar (una franja lateral, p. ej.).
  ///
  /// Debe ir SIN `color`: para el fondo está [color]. Un `DecoratedBox`
  /// transparente no tapa el ripple y no dispara el assert.
  final BoxDecoration? decoracionInterna;

  const PanelTiles({
    super.key,
    required this.child,
    this.color,
    this.radio = 12,
    this.radioPersonalizado,
    this.lado,
    this.margin,
    this.padding,
    this.decoracionInterna,
  });

  @override
  Widget build(BuildContext context) {
    // La validacion va aca y no en el constructor: este es const, y ahi un
    // assert no puede leer un campo del parametro (no es expresion constante).
    assert(
      decoracionInterna?.color == null,
      'decoracionInterna no puede traer color: taparia el ripple de los tiles, '
      'que es justo lo que este widget evita. Usa el parametro color.',
    );

    Widget contenido = child;

    if (decoracionInterna != null) {
      contenido = DecoratedBox(decoration: decoracionInterna!, child: contenido);
    }
    if (padding != null) {
      contenido = Padding(padding: padding!, child: contenido);
    }

    final panel = Material(
      color: color ?? Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radioPersonalizado ?? BorderRadius.circular(radio),
        side: lado ?? BorderSide.none,
      ),
      child: contenido,
    );

    if (margin == null) return panel;
    return Padding(padding: margin!, child: panel);
  }
}
