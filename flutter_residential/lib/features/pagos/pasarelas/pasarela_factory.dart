import '../models/pasarela_disponible_model.dart';
import 'bold_pasarela.dart';
import 'mercado_pago_pasarela.dart';
import 'pasarela_pago.dart';
import 'wompi_pasarela.dart';

/// Fábrica de implementaciones de [PasarelaPago].
///
/// Equivalente a PasarelaFactory en Spring Boot — retorna la implementación
/// correcta según el [TipoPasarela] solicitado.
///
/// Uso:
/// ```dart
/// final pasarela = PasarelaFactory.obtener(TipoPasarela.wompi);
/// ```
class PasarelaFactory {
  PasarelaFactory._(); // sin instancias — solo estático

  /// Retorna la implementación de [PasarelaPago] para el [tipo] dado.
  static PasarelaPago obtener(TipoPasarela tipo) => switch (tipo) {
        TipoPasarela.mercadoPago => const MercadoPagoPasarela(),
        TipoPasarela.wompi       => const WompiPasarela(),
        TipoPasarela.bold        => const BoldPasarela(),
      };
}
