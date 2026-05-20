import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/pasarela_disponible_model.dart';
import '../../services/pasarela_service.dart';

enum ResultadoPago { exito, fallo, pendiente, cancelado }

/// WebView genérico reutilizable para todas las pasarelas de pago.
/// Soporta MercadoPago, Wompi y Bold a través de patrones de URL configurables.
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
  bool _cargando = true;
  bool _procesando = false;

  // ─── Patrones de retorno por pasarela ─────────────────────────────────────

  // MercadoPago
  static const _mpExitoPath    = '/api/mp/pago-exito';
  static const _mpFalloPath    = '/api/mp/pago-fallo';
  static const _mpPendientePath = '/api/mp/pago-pendiente';
  static const _mpSchemeExito  = 'conjuntosapp://pago/exito';
  static const _mpSchemeFallo  = 'conjuntosapp://pago/fallo';
  static const _mpSchemePend   = 'conjuntosapp://pago/pendiente';

  // Wompi — redirige a la redirect_url configurada
  static const _wompiSchemeExito = 'conjuntosapp://pago/exito';
  static const _wompiSchemeFallo = 'conjuntosapp://pago/fallo';

  // Bold — redirige a la redirect_url configurada
  static const _boldSchemeExito = 'conjuntosapp://pago/exito';
  static const _boldSchemeFallo = 'conjuntosapp://pago/fallo';

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

    switch (widget.tipoPasarela) {
      case TipoPasarela.mercadoPago:
        return _interceptarMP(url);
      case TipoPasarela.wompi:
        return _interceptarWompi(url);
      case TipoPasarela.bold:
        return _interceptarBold(url);
    }
  }

  // ─── Interceptores específicos ─────────────────────────────────────────────

  NavigationDecision _interceptarMP(String url) {
    if (url.startsWith(_mpSchemeExito) || url.contains(_mpExitoPath)) {
      _procesarExitoMP(url);
      return NavigationDecision.prevent;
    }
    if (url.startsWith(_mpSchemeFallo) || url.contains(_mpFalloPath)) {
      _finalizarPago(ResultadoPago.fallo);
      return NavigationDecision.prevent;
    }
    if (url.startsWith(_mpSchemePend) || url.contains(_mpPendientePath)) {
      _procesarPendienteMP(url);
      return NavigationDecision.prevent;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      debugPrint('WebView MP: esquema externo bloqueado → $url');
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  NavigationDecision _interceptarWompi(String url) {
    // Wompi redirige a la redirect_url configurada en el backend
    if (url.startsWith(_wompiSchemeExito) || _esUrlExito(url)) {
      _finalizarPago(ResultadoPago.exito);
      return NavigationDecision.prevent;
    }
    if (url.startsWith(_wompiSchemeFallo) || _esUrlFallo(url)) {
      _finalizarPago(ResultadoPago.fallo);
      return NavigationDecision.prevent;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  NavigationDecision _interceptarBold(String url) {
    if (url.startsWith(_boldSchemeExito) || _esUrlExito(url)) {
      _finalizarPago(ResultadoPago.exito);
      return NavigationDecision.prevent;
    }
    if (url.startsWith(_boldSchemeFallo) || _esUrlFallo(url)) {
      _finalizarPago(ResultadoPago.fallo);
      return NavigationDecision.prevent;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  // ─── Procesadores de resultado ─────────────────────────────────────────────

  void _procesarExitoMP(String url) {
    if (_procesando) return;
    _procesando = true;
    final paymentId = _extraerQueryParam(url, 'payment_id') ??
        _extraerQueryParam(url, 'collection_id');
    if (paymentId != null) {
      PasarelaService.confirmarPagoMP(paymentId).catchError(
        (e) => debugPrint('WebView: error confirmando pago MP → $e'),
      );
    }
    if (mounted) Navigator.of(context).pop(ResultadoPago.exito);
  }

  void _procesarPendienteMP(String url) {
    if (_procesando) return;
    _procesando = true;
    final paymentId = _extraerQueryParam(url, 'payment_id') ??
        _extraerQueryParam(url, 'collection_id');
    if (paymentId != null) {
      PasarelaService.confirmarPagoMP(paymentId).catchError(
        (e) => debugPrint('WebView: error confirmando pendiente MP → $e'),
      );
    }
    if (mounted) Navigator.of(context).pop(ResultadoPago.pendiente);
  }

  void _finalizarPago(ResultadoPago resultado) {
    if (_procesando) return;
    _procesando = true;
    if (mounted) Navigator.of(context).pop(resultado);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  bool _esUrlExito(String url) =>
      url.contains('/pago/exito') || url.contains('status=approved') ||
      url.contains('resultado=exito');

  bool _esUrlFallo(String url) =>
      url.contains('/pago/fallo') || url.contains('status=declined') ||
      url.contains('status=error') || url.contains('resultado=fallo');

  String? _extraerQueryParam(String url, String param) {
    try {
      return Uri.parse(url).queryParameters[param];
    } catch (_) {
      return null;
    }
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
