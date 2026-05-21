import 'package:flutter/material.dart';
import '../../models/cobro_model.dart';
import '../../models/pasarela_disponible_model.dart';
import '../../services/pasarela_service.dart';
import '../../widgets/pasarela_logo_widget.dart';
import 'mercado_pago_webview_screen.dart';
import 'registrar_abono_screen.dart';
import 'registrar_pago_screen.dart';

class DetalleCobroScreen extends StatefulWidget {
  final CobroModel cobro;
  const DetalleCobroScreen({super.key, required this.cobro});

  @override
  State<DetalleCobroScreen> createState() => _DetalleCobroScreenState();
}

class _DetalleCobroScreenState extends State<DetalleCobroScreen> {
  bool _loadingMp = false;

  CobroModel get cobro => widget.cobro;

  // ─── Acción: Pagar (multi-pasarela) ──────────────────────────────────────

  Future<void> _iniciarPago() async {
    setState(() => _loadingMp = true);
    try {
      final pasarelas = await PasarelaService.obtenerDisponibles();
      if (pasarelas.isEmpty) {
        throw Exception('No hay métodos de pago configurados para este conjunto');
      }

      TipoPasarela? pasarelaElegida;
      if (pasarelas.length == 1) {
        pasarelaElegida = pasarelas.first.tipo;
      } else {
        setState(() => _loadingMp = false);
        if (!mounted) return;
        pasarelaElegida = await _mostrarSelectorPasarela(pasarelas);
        if (pasarelaElegida == null || !mounted) return;
        setState(() => _loadingMp = true);
      }

      final checkout = await PasarelaService.crearCheckout(cobro.id, pasarelaElegida);
      if (!mounted) return;
      await _abrirWebViewYNotificar(checkout.checkoutUrl,
          tipoPasarela: checkout.tipoPasarela);
    } catch (e) {
      if (mounted) {
        _mostrarError(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loadingMp = false);
    }
  }

  Future<TipoPasarela?> _mostrarSelectorPasarela(
      List<PasarelaDisponibleModel> pasarelas) async {
    return showModalBottomSheet<TipoPasarela>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona método de pago',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...pasarelas.map((p) => ListTile(
                  leading: PasarelaLogoWidget(tipo: p.tipo, size: 44),
                  title: Text(p.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle:
                      p.prioridad == 1 ? const Text('Recomendado',
                          style: TextStyle(color: Colors.teal, fontSize: 12))
                          : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, p.tipo),
                )),
          ],
        ),
      ),
    );
  }

  IconData _iconoPasarela(TipoPasarela tipo) {
    switch (tipo) {
      case TipoPasarela.mercadoPago:
        return Icons.payment;
      case TipoPasarela.wompi:
        return Icons.credit_card;
      case TipoPasarela.bold:
        return Icons.bolt;
    }
  }

  Color _colorPasarela(TipoPasarela tipo) {
    switch (tipo) {
      case TipoPasarela.mercadoPago:
        return const Color(0xFF009EE3);
      case TipoPasarela.wompi:
        return const Color(0xFF6C3CE1);
      case TipoPasarela.bold:
        return const Color(0xFF1A1A2E);
    }
  }

  Future<void> _abrirWebViewYNotificar(String url,
      {TipoPasarela tipoPasarela = TipoPasarela.mercadoPago}) async {
    final resultado = await Navigator.push<ResultadoPagoMP>(
      context,
      MaterialPageRoute(
        builder: (_) => MercadoPagoWebViewScreen(
          checkoutUrl: url,
          tituloCobro: cobro.anio != null
              ? '${cobro.concepto} ${cobro.mes}/${cobro.anio}'
              : cobro.concepto,
          tipoPasarela: tipoPasarela,
        ),
      ),
    );
    if (!mounted) return;
    _manejarResultadoPago(resultado);
  }

  void _manejarResultadoPago(ResultadoPagoMP? resultado) {
    switch (resultado) {
      case ResultadoPagoMP.exito:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Pago realizado con éxito!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop(true); // Regresa y refresca la lista
        break;
      case ResultadoPagoMP.pendiente:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago pendiente de confirmación'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop(true);
        break;
      case ResultadoPagoMP.fallo:
        _mostrarError('El pago no pudo procesarse. Podés intentarlo nuevamente.');
        break;
      case ResultadoPagoMP.cancelado:
      case null:
        break; // El usuario canceló, no hacemos nada
    }
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
      bottomNavigationBar: cobro.tieneDeuda
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
                        if (cobro.esPendiente || cobro.esVencido) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        RegistrarPagoScreen(cobro: cobro)),
                              ),
                              icon: const Icon(Icons.receipt_long_outlined),
                              label: const Text('Comprobante'),
                            ),
                          ),
                        ],
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
