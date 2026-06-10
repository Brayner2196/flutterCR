import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/pasarela_webview_config.dart';
import '../../models/pasarela_disponible_model.dart';

/// Estado del resultado del pago devuelto al hacer pop de esta pantalla.
///
/// - [procesando] → el WebView interceptó la URL de éxito y lanzó la
///   confirmación al back, pero aún no hay confirmación definitiva del webhook.
///   La pantalla padre debe hacer polling del estado del cobro.
/// - [exito] → pago confirmado de forma síncrona (raro; reservado para futuros usos).
/// - [fallo] → el usuario completó el flujo pero el pago fue rechazado.
/// - [pendiente] → pago en revisión (típico en MP para ciertos medios de pago).
/// - [cancelado] → el usuario abandonó el WebView explícitamente.
enum ResultadoPago { procesando, exito, fallo, pendiente, cancelado }

/// WebView genérico reutilizable para todas las pasarelas de pago.
///
/// La lógica específica de cada pasarela (detección de URLs, confirmación,
/// filtro de errores JS) está desacoplada en [PasarelaWebViewConfig].
/// Este widget solo coordina el ciclo de vida del WebView y el pop con resultado.
///
/// Pasarelas soportadas: MercadoPago, Wompi, Bold.
class PasarelaWebViewScreen extends StatefulWidget {
  final String checkoutUrl;
  final TipoPasarela tipoPasarela;
  final String tituloCobro;

  const PasarelaWebViewScreen({
    super.key,
    required this.checkoutUrl,
    required this.tipoPasarela,
    required this.tituloCobro,
  });

  @override
  State<PasarelaWebViewScreen> createState() => _PasarelaWebViewScreenState();
}

class _PasarelaWebViewScreenState extends State<PasarelaWebViewScreen> {
  late final WebViewController _controller;

  /// Configuración específica de la pasarela: URLs, confirmación, filtros JS.
  late final PasarelaWebViewConfig _config;

  bool _cargando = true;

  /// Bandera para evitar procesar el resultado más de una vez
  /// (puede dispararse tanto en [_interceptarNavegacion] como en [_onPageStarted]).
  bool _procesando = false;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _config = PasarelaWebViewConfig.para(widget.tipoPasarela);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_config.userAgent)

      // Filtrar ruido de consola JS de SDKs terceros (Wompi, MP Bricks, etc.)
      ..setOnConsoleMessage((msg) {
        if (_config.debeLoguear(msg)) {
          debugPrint('[WebView:${widget.tipoPasarela.name}][${msg.level.name}] ${msg.message}');
        }
      })

      ..setNavigationDelegate(
        NavigationDelegate(
          // Primera línea: bloquea antes de que empiece a cargar
          onNavigationRequest: _interceptarNavegacion,

          // Segunda línea: para redirects HTTP 302 server-side que en Android
          // pueden saltarse onNavigationRequest. Cuando ya empezó a cargar y
          // matchea un patrón de retorno, cortamos con about:blank.
          onPageStarted: _onPageStarted,

          onPageFinished: (_) => setState(() => _cargando = false),
          onWebResourceError: (_) => setState(() => _cargando = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));

    // Hook para ajustes adicionales según la pasarela
    _config.aplicarAjustes(_controller);
  }

  // ─── Interceptores ─────────────────────────────────────────────────────────

  NavigationDecision _interceptarNavegacion(NavigationRequest request) {
    final url = request.url;

    if (_config.esUrlExito(url)) {
      _procesarExito(url);
      return NavigationDecision.prevent;
    }
    if (_config.esUrlFallo(url)) {
      _finalizarPago(ResultadoPago.fallo);
      return NavigationDecision.prevent;
    }
    if (_config.esUrlPendiente(url)) {
      _procesarPendiente(url);
      return NavigationDecision.prevent;
    }

    // Bloquear esquemas no-HTTP (deep-links, intents, etc.)
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      debugPrint('[WebView:${widget.tipoPasarela.name}] Esquema externo bloqueado → $url');
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  /// Segunda línea de defensa: Android puede saltarse [onNavigationRequest]
  /// para ciertos redirects server-side (HTTP 302 de Wompi/Bold).
  void _onPageStarted(String url) {
    setState(() => _cargando = true);

    // Si ya fue manejado por onNavigationRequest, no duplicar
    if (_procesando) return;

    if (_config.esUrlExito(url)) {
      _controller.loadRequest(Uri.parse('about:blank')); // cortar la carga
      _procesarExito(url);
    } else if (_config.esUrlFallo(url)) {
      _controller.loadRequest(Uri.parse('about:blank'));
      _finalizarPago(ResultadoPago.fallo);
    } else if (_config.esUrlPendiente(url)) {
      _controller.loadRequest(Uri.parse('about:blank'));
      _procesarPendiente(url);
    }
  }

  // ─── Procesadores de resultado ─────────────────────────────────────────────

  /// Pago exitoso. Confirma en el back y hace pop con [ResultadoPago.procesando].
  ///
  /// - Si [PasarelaWebViewConfig.confirmacionAsincrona] == true (Wompi):
  ///   espera la respuesta del back antes de hacer pop (confirmación principal).
  /// - Si false (MP, Bold): fire-and-forget; el webhook es la fuente de verdad.
  Future<void> _procesarExito(String url) async {
    if (_procesando) return;
    _procesando = true;

    final txId = _config.extraerTransactionId(url);

    if (_config.confirmacionAsincrona) {
      try {
        await _config.confirmarPago(txId);
      } catch (e) {
        debugPrint('[WebView:${widget.tipoPasarela.name}] Error confirmando pago → $e '
            '(el webhook lo resuelve igualmente)');
      }
    } else {
      // Fire-and-forget intencional: el back es idempotente, el webhook es el fallback
      _config.confirmarPago(txId).catchError(
        (Object e) => debugPrint('[WebView:${widget.tipoPasarela.name}] '
            'Fire-and-forget → $e (el webhook confirma igualmente)'),
      );
    }

    if (mounted) Navigator.of(context).pop(ResultadoPago.procesando);
  }

  /// Pago pendiente (ej. MP con medios de pago en efectivo).
  /// Intenta confirmar pero hace pop con [ResultadoPago.pendiente] sin esperar.
  Future<void> _procesarPendiente(String url) async {
    if (_procesando) return;
    _procesando = true;

    final txId = _config.extraerTransactionId(url);
    _config.confirmarPago(txId).catchError(
      (Object e) => debugPrint('[WebView:${widget.tipoPasarela.name}] '
          'Confirmación pendiente fallida → $e'),
    );

    if (mounted) Navigator.of(context).pop(ResultadoPago.pendiente);
  }

  /// Pago fallido o cancelado por la pasarela.
  void _finalizarPago(ResultadoPago resultado) {
    if (_procesando) return;
    _procesando = true;
    if (mounted) Navigator.of(context).pop(resultado);
  }

  // ─── Diálogo de salida ─────────────────────────────────────────────────────

  Future<void> _onWillPop() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cancelar pago?'),
        content: const Text(
            'Si salís ahora, el pago no se completará. ¿Querés cancelar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar pago'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (salir == true && mounted) {
      Navigator.of(context).pop(ResultadoPago.cancelado);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pago seguro · ${widget.tipoPasarela.nombreLegible}',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.tituloCobro,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancelar pago',
            onPressed: _onWillPop,
          ),
          bottom: _cargando
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    color: Color(0xFF009EE3),
                  ),
                )
              : null,
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
