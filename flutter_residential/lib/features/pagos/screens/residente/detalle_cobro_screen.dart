import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/cobro_model.dart';
import '../../services/cobro_service.dart';
import '../../widgets/pasarela_selector.dart';
import 'pasarela_webview_screen.dart';
import 'registrar_abono_screen.dart';

class DetalleCobroScreen extends StatefulWidget {
  final CobroModel cobro;
  const DetalleCobroScreen({super.key, required this.cobro});

  @override
  State<DetalleCobroScreen> createState() => _DetalleCobroScreenState();
}

class _DetalleCobroScreenState extends State<DetalleCobroScreen> {
  bool _loadingMp = false;

  /// Estado local del cobro — se actualiza con polling post-pago
  late CobroModel _cobro;

  /// Polling: verifica el estado del cobro cada [_pollInterval] hasta que
  /// esté PAGADO o se agote el timeout [_pollMaxSegundos].
  static const _pollInterval    = Duration(seconds: 3);
  static const _pollMaxSegundos = 30;
  Timer? _pollTimer;
  int    _pollSegundos = 0;
  bool   _polleando    = false;

  CobroModel get cobro => _cobro;

  @override
  void initState() {
    super.initState();
    _cobro = widget.cobro;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ─── Acción: Pagar (multi-pasarela) ──────────────────────────────────────

  /// Delega al [PasarelaSelector] la selección de pasarela, creación de
  /// checkout y apertura del WebView. Maneja el resultado localmente.
  Future<void> _iniciarPago() async {
    setState(() => _loadingMp = true);
    try {
      final resultado = await PasarelaSelector.iniciarPago(
        context: context,
        cobroId: cobro.id,
        tituloCobro: cobro.anio != null
            ? '${cobro.concepto} ${cobro.mes}/${cobro.anio}'
            : cobro.concepto,
      );
      if (!mounted) return;
      _manejarResultadoPago(resultado);
    } catch (e) {
      if (mounted) {
        _mostrarError(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loadingMp = false);
    }
  }

  void _manejarResultadoPago(ResultadoPago? resultado) {
    switch (resultado) {
      case ResultadoPago.procesando:
        // El WebView interceptó la URL de éxito y disparó la confirmación.
        // Iniciamos polling para saber cuándo el back confirmó el pago.
        _iniciarPolling();
        break;
      case ResultadoPago.exito:
        _mostrarExito();
        Navigator.of(context).pop(true);
        break;
      case ResultadoPago.pendiente:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago pendiente de confirmación'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
        Navigator.of(context).pop(true);
        break;
      case ResultadoPago.fallo:
        _mostrarError('El pago no pudo procesarse. Podés intentarlo nuevamente.');
        break;
      case ResultadoPago.cancelado:
      case null:
        break;
    }
  }

  // ─── Polling del estado del cobro ─────────────────────────────────────────

  /// Inicia polling tras recibir [ResultadoPago.procesando] del WebView.
  /// Consulta el cobro cada 3s por hasta 30s.
  /// Si el cobro pasa a PAGADO → muestra éxito y hace pop.
  /// Si agota el tiempo → avisa que puede demorar y hace pop sin error.
  void _iniciarPolling() {
    if (_polleando) return;
    setState(() => _polleando = true);
    _pollSegundos = 0;

    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      _pollSegundos += _pollInterval.inSeconds;

      try {
        final cobroActualizado = await CobroService.getCobro(cobro.id);
        if (!mounted) {
          _pollTimer?.cancel();
          return;
        }
        setState(() => _cobro = cobroActualizado);

        if (cobroActualizado.esPagado) {
          _pollTimer?.cancel();
          setState(() => _polleando = false);
          _mostrarExito();
          Navigator.of(context).pop(true);
          return;
        }
      } catch (e) {
        debugPrint('Polling cobro ${cobro.id}: error → $e');
      }

      if (_pollSegundos >= _pollMaxSegundos) {
        _pollTimer?.cancel();
        if (!mounted) return;
        setState(() => _polleando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El pago está siendo procesado. '
              'En breve recibirás la confirmación.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 6),
          ),
        );
        Navigator.of(context).pop(true);
      }
    });
  }

  void _mostrarExito() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Pago confirmado con éxito!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ─── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final color = cobro.esVencido
        ? Colors.red
        : cobro.esPagado
            ? Colors.green
            : cobro.esParcial
                ? Colors.blue
                : Colors.orange;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Cobro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _estadoBadge(color),
          const SizedBox(height: 16),
          _seccion('Información del cobro', [
            _fila('Propiedad', cobro.propiedadIdentificador),
            if (cobro.anio != null)
              _fila('Período', '${cobro.mes}/${cobro.anio}')
            else
              _fila('Tipo', 'Cobro especial'),
            _fila('Concepto', cobro.concepto),
            if (cobro.descripcion != null)
              _fila('Descripción', cobro.descripcion!),
            _fila('Generado', cobro.fechaGeneracion),
            _fila('Límite de pago', cobro.fechaLimitePago),
          ]),
          const SizedBox(height: 12),
          _seccion('Montos', [
            _fila('Monto base', _fmt(cobro.montoBase)),
            if (cobro.montoMora > 0)
              _fila('Mora', _fmt(cobro.montoMora), color: Colors.red),
            _fila('Total a pagar', _fmt(cobro.montoTotal), bold: true),
            if (cobro.esParcial) ...[
              _fila('Abonado', _fmt(cobro.montoPagado), color: Colors.blue),
              _fila('Pendiente', _fmt(cobro.montoPendiente),
                  bold: true, color: Colors.orange),
              const SizedBox(height: 8),
              _barraProgreso(cobro),
            ],
          ]),
        ],
      ),
      bottomNavigationBar: _polleando
          // ── Banner de "verificando pago" ──────────────────────────────────
          ? SafeArea(
              child: Container(
                width: double.infinity,
                color: Colors.teal.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Verificando tu pago... (${_pollMaxSegundos - _pollSegundos}s)',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : cobro.tieneDeuda
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Pago online (multi-pasarela) ───────────────────────
                    if (cobro.esPendiente || cobro.esVencido || cobro.esParcial)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _loadingMp ? null : _iniciarPago,
                          icon: _loadingMp
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.payment),
                          label: Text(
                            _loadingMp ? 'Generando pago...' : 'Continuar al pago',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    if (cobro.esPendiente || cobro.esVencido || cobro.esParcial)
                      const SizedBox(height: 8),
                    // ── Opciones manuales ──────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => RegistrarAbonoScreen(
                                        propiedadId: cobro.propiedadId,
                                        propiedadNombre:
                                            cobro.propiedadIdentificador,
                                      )),
                            ),
                            icon: const Icon(Icons.savings_outlined),
                            label: const Text('Abonar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  // ─── Widgets helper ──────────────────────────────────────────────────────

  Widget _estadoBadge(Color color) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Estado: ${cobro.estado}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  cobro.esParcial
                      ? _fmt(cobro.montoPendiente)
                      : _fmt(cobro.montoTotal),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 20),
                ),
                if (cobro.esParcial)
                  Text('pendiente',
                      style: TextStyle(
                          fontSize: 11,
                          color: color.withValues(alpha: 0.7))),
              ],
            ),
          ],
        ),
      );

  Widget _barraProgreso(CobroModel c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: c.porcentajePagado,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(c.porcentajePagado * 100).toStringAsFixed(0)}% pagado',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );

  Widget _seccion(String titulo, List<Widget> hijos) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(children: hijos),
            ),
          ),
        ],
      );

  Widget _fila(String label, String valor,
          {Color? color, bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(valor,
                style: TextStyle(
                    fontWeight:
                        bold ? FontWeight.bold : FontWeight.normal,
                    color: color)),
          ],
        ),
      );

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
