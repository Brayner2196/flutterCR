/// Umbrales de ancho de la app.
///
/// La decision se toma por ancho disponible y nunca por plataforma: el
/// navegador de un celular tambien es `kIsWeb` pero debe verse como movil, y
/// una ventana de escritorio angosta tambien. Cualquier widget que necesite
/// comportarse distinto en pantallas grandes consulta este umbral en vez de
/// repetir el numero magico.
class Breakpoints {
  const Breakpoints._();

  /// Por debajo de este ancho la UI se trata como movil.
  static const double compacto = 600;

  /// `true` cuando hay ancho de sobra (web de escritorio, escritorio nativo,
  /// tablet en horizontal).
  static bool esAmplio(double ancho) => ancho >= compacto;
}
