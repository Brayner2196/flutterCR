import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/pasarela_disponible_model.dart';
import '../../services/pasarela_service.dart';

enum ResultadoPagoMP { exito, fallo, pendiente, cancelado }

/// WebView genérico de pago. Funciona para MercadoPago, Wompi y Bold.
/// Solo llama al endpoint de confirmación cuando [tipoPasarela] es MP,
/// ya que Wompi/Bold se confirman automáticamente vía webhook.
class MercadoPagoWebViewScreen extends StatefulWidget {
  final String checkoutUrl;
  final String tituloCobro;
  final TipoPasarela tipoPasarela;

  const MercadoPagoWebViewScreen({
    super.key,
    required this.checkoutUrl,
    required this.tituloCobro,
    this.tipoPasarela = TipoPasarela.mercadoPago,
  });

  @override
  State<MercadoPagoWebViewScreen> createState() =>
      _MercadoPagoWebViewScreenState();
}

class _MercadoPagoWebViewScreenState extends State<MercadoPagoWebViewScreen> {
  late final WebViewController _controller;
  bool _cargando = true;
  bool _procesando = false;

  // Rutas HTTP de retorno del backend (sandbox y producción)
  static const _exitoPath = '/api/mp/pago-exito';
  static const _falloPath = '/api/mp/pago-fallo';
  static const _pendientePath = '/api/mp/pago-pendiente';

  // Deep links de retorno (producción móvil)
  static const _schemeExito = 'conjuntosapp://pago/exito';
  static const _schemeFallo = 'conjuntosapp://pago/fallo';
  static const _schemePendiente = 'conjuntosapp://pago/pendiente';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 12; Pixel 6) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _cargando = true),
          onPageFinished: (_) => setState(() => _cargando = false),
          onWebResourceError: (_) => setState(() => _cargando = false),
          onNavigationRequest: _interceptarNavegacion,
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  NavigationDecision _interceptarNavegacion(NavigationRequest request) {
    final url = request.url;

    // ── Pago exitoso: extraer payment_id y notificar al backend ──────────
    // Nota: _procesarExito es async pero lo llamamos sin await aquí porque
    // NavigationDecision es síncrono. El Future corre en background y hace
    // pop cuando confirmarPago termina (evita race condition).
    if (url.startsWith(_schemeExito) || url.contains(_exitoPath)) {
      _procesarExito(url);
      return NavigationDecision.prevent;
    }

    // ── Pago fallido o pendiente ──────────────────────────────────────────
    if (url.startsWith(_schemeFallo) || url.contains(_falloPath)) {
      _finalizarPago(ResultadoPagoMP.fallo);
      return NavigationDecision.prevent;
    }
    if (url.startsWith(_schemePendiente) || url.contains(_pendientePath)) {
      _procesarPendiente(url);
      return NavigationDecision.prevent;
    }

    // ── Bloquear esquemas no-HTTP (intent://, market://, etc.) ───────────
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      debugPrint('WebView MP: esquema externo bloqueado → $url');
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  /// Confirma en el backend y hace pop.
  /// Solo llama al endpoint de confirmar para MercadoPago;
  /// Wompi/Bold se confirman automáticamente vía webhook.
  Future<void> _procesarExito(String url) async {
    if (_procesando) return;
    _procesando = true;

    if (widget.tipoPasarela == TipoPasarela.mercadoPago) {
      final paymentId = _extraerPaymentId(url);
      if (paymentId != null) {
        try {
          await PasarelaService.confirmarPagoMP(paymentId);
        } catch (e) {
          debugPrint('WebView MP: error confirmando pago → $e');
        }
      }
    }

    if (mounted) Navigator.of(context).pop(ResultadoPagoMP.exito);
  }

  Future<void> _procesarPendiente(String url) async {
    if (_procesando) return;
    _procesando = true;

    if (widget.tipoPasarela == TipoPasarela.mercadoPago) {
      final paymentId = _extraerPaymentId(url);
      if (paymentId != null) {
        try {
          await PasarelaService.confirmarPagoMP(paymentId);
        } catch (e) {
          debugPrint('WebView MP: error confirmando pendiente → $e');
        }
      }
    }

    if (mounted) Navigator.of(context).pop(ResultadoPagoMP.pendiente);
  }

  String? _extraerPaymentId(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['payment_id'] ??
          uri.queryParameters['collection_id'];
    } catch (_) {
      return null;
    }
  }

  void _finalizarPago(ResultadoPagoMP resultado) {
    if (_procesando) return;
    _procesando = true;
    if (mounted) Navigator.of(context).pop(resultado);
  }

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
      Navigator.of(context).pop(ResultadoPagoMP.cancelado);
    }
  }

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
              const Text(
                'Pago seguro',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
