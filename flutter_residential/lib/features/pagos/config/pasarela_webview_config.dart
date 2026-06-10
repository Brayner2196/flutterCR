import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/pasarela_disponible_model.dart';
import '../services/pasarela_service.dart';

/// Capa de configuración por pasarela para el WebView de pago.
///
/// Cada implementación encapsula:
///  - User agent a inyectar
///  - Cómo reconocer URLs de éxito / fallo / pendiente
///  - Cómo extraer el transaction/payment ID de la URL
///  - Si la confirmación al back es asíncrona (await) o fire-and-forget
///  - Mensajes de consola JS a suprimir (ruido de SDKs terceros)
///  - Ajustes adicionales al WebViewController (ej. cookies, headers)
///
/// Uso:
/// ```dart
/// final _config = PasarelaWebViewConfig.para(widget.tipoPasarela);
/// ```
abstract class PasarelaWebViewConfig {
  // ─── User agent ────────────────────────────────────────────────────────────

  /// Chrome Mobile sobre Android — requerido por MP Checkout Pro y Wompi
  /// para renderizar correctamente sus widgets de tarjeta.
  static const _uaChromeMobile =
      'Mozilla/5.0 (Linux; Android 12; Pixel 6) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/120.0.0.0 Mobile Safari/537.36';

  String get userAgent => _uaChromeMobile;

  // ─── Detección de URLs ─────────────────────────────────────────────────────

  /// Retorna true si la URL corresponde a un pago exitoso de esta pasarela.
  bool esUrlExito(String url);

  /// Retorna true si la URL corresponde a un pago fallido / rechazado.
  bool esUrlFallo(String url);

  /// Retorna true si la URL corresponde a un pago pendiente de confirmación.
  /// Por defecto false (solo MP tiene estado pendiente explícito).
  bool esUrlPendiente(String url) => false;

  // ─── Extracción de ID ──────────────────────────────────────────────────────

  /// Extrae el identificador de transacción/pago desde la URL de retorno.
  /// Devuelve null si no se encuentra o no aplica (ej. Bold).
  String? extraerTransactionId(String url) => _queryParam(url, 'id');

  // ─── Comportamiento de confirmación ───────────────────────────────────────

  /// Si true, la confirmación al back se espera con await antes de hacer pop.
  /// Si false, se envía fire-and-forget y se hace pop inmediatamente.
  ///
  /// Wompi: true  (su webhook es más lento, la confirmación app es el mecanismo principal)
  /// MP:    false (el webhook es la fuente de verdad; la confirmación app es best-effort)
  /// Bold:  false (no hay endpoint de confirmación, solo webhooks)
  bool get confirmacionAsincrona => false;

  /// Llama al endpoint de confirmación en el backend.
  /// No-op por defecto; cada pasarela sobreescribe según corresponda.
  Future<void> confirmarPago(String? transactionId) async {}

  // ─── Filtro de consola JS ──────────────────────────────────────────────────

  /// Fragmentos de texto que, si aparecen en un mensaje de consola del WebView,
  /// hacen que el mensaje se suprima (no se imprima en el log de Flutter).
  ///
  /// Sirve para ocultar errores internos de los SDKs de terceros que no
  /// podemos corregir y que confunden al desarrollador.
  List<String> get mensajesSuprimidos => const [];

  /// Devuelve true si el mensaje de consola debe mostrarse en el log.
  bool debeLoguear(JavaScriptConsoleMessage msg) {
    if (mensajesSuprimidos.isEmpty) return true;
    final texto = msg.message;
    return !mensajesSuprimidos.any(texto.contains);
  }

  // ─── Ajustes adicionales al controller ────────────────────────────────────

  /// Hook para aplicar configuraciones extra al [WebViewController].
  /// Se llama en initState después de configurar el NavigationDelegate.
  void aplicarAjustes(WebViewController controller) {}

  // ─── Factory ───────────────────────────────────────────────────────────────

  /// Devuelve la configuración correcta para el [TipoPasarela] dado.
  static PasarelaWebViewConfig para(TipoPasarela tipo) => switch (tipo) {
        TipoPasarela.mercadoPago => MercadoPagoWebViewConfig(),
        TipoPasarela.wompi       => WompiWebViewConfig(),
        TipoPasarela.bold        => BoldWebViewConfig(),
      };

  // ─── Utilidad interna ──────────────────────────────────────────────────────

  static String? _queryParam(String url, String key) {
    try {
      return Uri.parse(url).queryParameters[key];
    } catch (_) {
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MercadoPago — Checkout Pro
// ═══════════════════════════════════════════════════════════════════════════════

/// Configuración del WebView para MercadoPago Checkout Pro.
///
/// Flujo:
///  1. Backend crea preferencia → devuelve `init_point` (producción y sandbox).
///  2. El WebView abre el init_point.
///  3. MP redirige a back_urls: /api/mp/pago-{exito|fallo|pendiente}
///  4. El controller devuelve un HTML con JS que hace `window.location = 'conjuntosapp://...'`
///  5. El WebView intercepta el deep-link y hace pop con el resultado.
///
/// Fix CORS:
///  El backend siempre usa `getInitPoint()` (www.mercadopago.com.co), nunca
///  `getSandboxInitPoint()` (sandbox.mercadopago.com.co), porque el dominio
///  sandbox NO está en la whitelist CORS de api.mercadopago.com en Android WebView.
///  MP enruta internamente las credenciales de prueba al sandbox.
///
/// Errores suprimidos:
///  - "has been blocked by CORS policy" → error conocido con sandbox_init_point (ya corregido en back)
///  - "Access to fetch at 'https://api.mercadopago.com" → correlacionado con el anterior
///  - "[BRICKS ERROR]" → errores internos de MP Bricks cuando el form no está montado
class MercadoPagoWebViewConfig extends PasarelaWebViewConfig {
  // Paths del backend (back_urls configuradas en la preferencia MP)
  static const _exitoPath    = '/api/mp/pago-exito';
  static const _falloPath    = '/api/mp/pago-fallo';
  static const _pendientePath = '/api/mp/pago-pendiente';

  // Deep-links generados por el HTML del controller (segunda línea de defensa)
  static const _schemeExito    = 'conjuntosapp://pago/exito';
  static const _schemeFallo    = 'conjuntosapp://pago/fallo';
  static const _schemePendiente = 'conjuntosapp://pago/pendiente';

  @override
  bool esUrlExito(String url) =>
      url.startsWith(_schemeExito) || url.contains(_exitoPath);

  @override
  bool esUrlFallo(String url) =>
      url.startsWith(_schemeFallo) || url.contains(_falloPath);

  @override
  bool esUrlPendiente(String url) =>
      url.startsWith(_schemePendiente) || url.contains(_pendientePath);

  /// MP envía `payment_id` en la back_url de éxito; `collection_id` es un alias.
  @override
  String? extraerTransactionId(String url) =>
      PasarelaWebViewConfig._queryParam(url, 'payment_id') ??
      PasarelaWebViewConfig._queryParam(url, 'collection_id');

  /// Fire-and-forget: el webhook de MP es la fuente de verdad.
  /// La confirmación app es best-effort para acelerar la UX.
  @override
  bool get confirmacionAsincrona => false;

  @override
  Future<void> confirmarPago(String? transactionId) async {
    if (transactionId == null || transactionId.isEmpty) return;
    await PasarelaService.confirmarPagoMP(transactionId);
  }

  @override
  List<String> get mensajesSuprimidos => const [
    'has been blocked by CORS policy',
    "Access to fetch at 'https://api.mercadopago.com",
    '[BRICKS ERROR]',
    'secure-fields.mercadopago.com',
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// Wompi — Payment Link
// ═══════════════════════════════════════════════════════════════════════════════

/// Configuración del WebView para Wompi.
///
/// Flujo:
///  1. Backend crea payment link de Wompi → devuelve URL de la pasarela.
///  2. El WebView abre la URL.
///  3. Wompi redirige a la redirect_url configurada: /api/pago/exito?id=TX_ID
///  4. El controller devuelve un HTML con JS que hace `window.location = 'conjuntosapp://...'`
///  5. El WebView intercepta y hace pop.
///
/// Confirmación asíncrona:
///  El webhook de Wompi es más lento que el de MP; la confirmación desde la app
///  es el mecanismo PRINCIPAL para actualizar el cobro. Se hace await antes de pop.
///
/// Errores suprimidos:
///  - "Error during initialization" → Wompi SDK falla al inicializar (error interno)
///  - "Failed to fetch"             → Wompi SDK no puede contactar su API interna
///  - "Cannot read properties of null" → null-check fallido en bundle.js de Wompi
///  - "wompijs.wompi.com"           → cualquier error proveniente del dominio Wompi JS
class WompiWebViewConfig extends PasarelaWebViewConfig {
  static const _schemeExito = 'conjuntosapp://pago/exito';
  static const _schemeFallo = 'conjuntosapp://pago/fallo';

  @override
  bool esUrlExito(String url) =>
      url.startsWith(_schemeExito) ||
      url.contains('/pago/exito') ||
      url.contains('status=approved') ||
      url.contains('resultado=exito');

  @override
  bool esUrlFallo(String url) =>
      url.startsWith(_schemeFallo) ||
      url.contains('/pago/fallo') ||
      url.contains('status=declined') ||
      url.contains('status=error') ||
      url.contains('resultado=fallo');

  /// Wompi incluye el transaction ID como `?id=TX_ID` en la redirect_url.
  @override
  String? extraerTransactionId(String url) =>
      PasarelaWebViewConfig._queryParam(url, 'id');

  /// await antes de pop: la confirmación app es el mecanismo principal en Wompi.
  @override
  bool get confirmacionAsincrona => true;

  @override
  Future<void> confirmarPago(String? transactionId) async {
    if (transactionId == null || transactionId.isEmpty) return;
    await PasarelaService.confirmarPagoWompi(transactionId);
  }

  @override
  List<String> get mensajesSuprimidos => const [
    'Error during initialization',
    'Failed to fetch',
    'Cannot read properties of null',
    'wompijs.wompi.com',
    'TypeError: Cannot read',
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bold — Payment Link
// ═══════════════════════════════════════════════════════════════════════════════

/// Configuración del WebView para Bold.
///
/// Flujo:
///  1. Backend crea payment link de Bold → devuelve URL de la pasarela.
///  2. El WebView abre la URL.
///  3. Bold redirige a la redirect_url configurada: /api/pago/exito
///  4. El WebView intercepta y hace pop con [ResultadoPago.procesando].
///
/// Sin confirmación de app:
///  Bold NO tiene endpoint de confirmación sincrónica; el webhook es el único
///  mecanismo para registrar el pago. La app hace pop con "procesando" y la
///  pantalla padre hace polling del estado del cobro.
class BoldWebViewConfig extends PasarelaWebViewConfig {
  static const _schemeExito = 'conjuntosapp://pago/exito';
  static const _schemeFallo = 'conjuntosapp://pago/fallo';

  @override
  bool esUrlExito(String url) =>
      url.startsWith(_schemeExito) ||
      url.contains('/pago/exito') ||
      url.contains('resultado=exito');

  @override
  bool esUrlFallo(String url) =>
      url.startsWith(_schemeFallo) ||
      url.contains('/pago/fallo') ||
      url.contains('resultado=fallo');

  /// Bold no expone un transaction ID en la redirect_url de forma estándar.
  @override
  String? extraerTransactionId(String url) => null;

  /// No hay endpoint de confirmación en Bold; los webhooks son la fuente de verdad.
  @override
  bool get confirmacionAsincrona => false;

  /// No-op intencional: Bold usa exclusivamente webhooks para confirmar pagos.
  @override
  Future<void> confirmarPago(String? transactionId) async {}

  @override
  void aplicarAjustes(WebViewController controller) {
    // Bold no requiere ajustes adicionales por ahora.
    debugPrint('[BoldWebViewConfig] WebView listo para Bold payment link');
  }
}
