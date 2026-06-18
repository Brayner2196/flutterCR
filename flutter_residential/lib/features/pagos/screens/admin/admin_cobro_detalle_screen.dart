import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/cobro_model.dart';
import '../../models/movimiento_cobro_model.dart';
import '../../providers/cobros_provider.dart';
import '../../services/cobro_service.dart';
import '../../widgets/cobro_estado_badge.dart';
import '../../widgets/movimiento_timeline.dart';

/// Detalle y trazabilidad de un cobro (vista admin).
///
/// Muestra el desglose (base, mora, total), el avance pagado/pendiente y la
/// línea de tiempo de movimientos (pagos y abonos). Permite exonerar si el
/// cobro está pendiente o vencido. Devuelve `true` al cerrar si hubo cambios,
/// para que la lista se refresque.
class AdminCobroDetalleScreen extends StatefulWidget {
  final CobroModel cobro;
  const AdminCobroDetalleScreen({super.key, required this.cobro});

  @override
  State<AdminCobroDetalleScreen> createState() =>
      _AdminCobroDetalleScreenState();
}

class _AdminCobroDetalleScreenState extends State<AdminCobroDetalleScreen> {
  late CobroModel _cobro;
  late Future<List<MovimientoCobroModel>> _futMovs;
  bool _cambios = false;

  static const _meses = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    _cobro = widget.cobro;
    _futMovs = CobroService.getMovimientosCobro(_cobro.id);
  }

  String get _periodoLabel {
    if (_cobro.mes != null && _cobro.mes! >= 1 && _cobro.mes! <= 12) {
      return '${_meses[_cobro.mes!]} ${_cobro.anio ?? ''}'.trim();
    }
    return DateFormatter.fechaCorta(_cobro.fechaGeneracion);
  }

  Future<void> _exonerar() async {
    final notaCtrl = TextEditingController();
    final nota = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exonerar cobro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Propiedad: ${_cobro.propiedadIdentificador}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Monto: ${CurrencyFormatter.cop(_cobro.montoTotal)}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: notaCtrl,
              decoration: const InputDecoration(
                labelText: 'Nota de exoneración',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, notaCtrl.text),
            child: const Text('Exonerar'),
          ),
        ],
      ),
    );
    if (nota == null || nota.trim().isEmpty) return;
    try {
      final actualizado =
          await context.read<CobrosProvider>().exonerar(_cobro.id, nota.trim());
      if (!mounted) return;
      setState(() {
        _cobro = actualizado;
        _cambios = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cobro exonerado'),
        backgroundColor: AppColors.purple,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  bool get _puedeExonerar => _cobro.esPendiente || _cobro.esVencido;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _cambios);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_cobro.propiedadIdentificador),
          actions: [
            if (_puedeExonerar)
              PopupMenuButton<String>(
                tooltip: 'Más opciones',
                onSelected: (v) {
                  if (v == 'exonerar') _exonerar();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'exonerar',
                    child: ListTile(
                      leading: Icon(Icons.remove_circle_outline),
                      title: Text('Exonerar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _cabecera(),
            const SizedBox(height: 16),
            _desglose(),
            const SizedBox(height: 20),
            Text(
              'Movimientos',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _timeline(),
          ],
        ),
      ),
    );
  }

  Widget _cabecera() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_cobro.concepto} · $_periodoLabel',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            CobroEstadoBadge(estado: _cobro.estado, mostrarIcono: true),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_outlined,
                      size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Vence ${DateFormatter.fechaCorta(_cobro.fechaLimitePago)}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _desglose() {
    final cs = Theme.of(context).colorScheme;
    final pct = _cobro.montoTotal > 0
        ? (_cobro.montoPagado / _cobro.montoTotal).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          _filaMonto(_cobro.concepto, _cobro.montoBase),
          if (_cobro.montoMora > 0) ...[
            const SizedBox(height: 8),
            _filaMonto('Mora acumulada', _cobro.montoMora,
                color: AppColors.danger),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: cs.outlineVariant),
          ),
          _filaMonto('Total del cobro', _cobro.montoTotal, fuerte: true),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: cs.surfaceContainerHighest,
              color: AppColors.ok,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pagado ${CurrencyFormatter.cop(_cobro.montoPagado)}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ok),
              ),
              Text(
                'Pendiente ${CurrencyFormatter.cop(_cobro.montoPendiente)}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _cobro.montoPendiente > 0
                        ? AppColors.warning
                        : cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filaMonto(String label, double monto,
      {bool fuerte = false, Color? color}) {
    final cs = Theme.of(context).colorScheme;
    final estilo = TextStyle(
      fontSize: fuerte ? 16 : 14,
      fontWeight: fuerte ? FontWeight.bold : FontWeight.w400,
      color: color ?? cs.onSurface,
    );
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: estilo.copyWith(
                  fontWeight: fuerte ? FontWeight.bold : FontWeight.w400)),
        ),
        Text(CurrencyFormatter.cop(monto), style: estilo),
      ],
    );
  }

  Widget _timeline() {
    return FutureBuilder<List<MovimientoCobroModel>>(
      future: _futMovs,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final movs = snap.data ?? const <MovimientoCobroModel>[];
        return MovimientoTimeline(
          movimientos: movs,
          generadoLabel: 'Cobro generado',
          generadoFecha: _cobro.fechaGeneracion,
          generadoMonto: _cobro.montoTotal,
        );
      },
    );
  }
}
