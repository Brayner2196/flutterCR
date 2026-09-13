/// Versión con la que se compiló este binario.
///
/// El valor lo inyecta el Makefile con `--dart-define=APP_BUILD=<n>`, leyéndolo
/// del propio `pubspec.yaml`. No se usa `package_info_plus` por dos razones:
/// evita una dependencia más, y en web ese paquete lee el `version.json` del
/// servidor — que es justamente el archivo con el que queremos *comparar*, no
/// del que queremos leernos a nosotros mismos.
///
/// `defaultValue: 0` significa "no sé mi versión". Todo el sistema trata ese
/// caso como al día: un `flutter run` sin defines nunca debe verse bloqueado.
library;

class AppVersion {
  AppVersion._();

  /// El `+65` de `version: 1.1.0+65`. Entero y monótono: comparar enteros no
  /// tiene la ambigüedad de comparar "1.10.0" contra "1.9.0" como texto.
  static const int build = int.fromEnvironment('APP_BUILD', defaultValue: 0);

  /// Solo para mostrar en pantalla ("1.1.0").
  static const String nombre = String.fromEnvironment('APP_VERSION', defaultValue: '');

  /// Falso en un `flutter run` sin defines. Los chequeos se saltan.
  static bool get conocida => build > 0;
}
