import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/cobro_model.dart';
import '../../../../models/estado_cuenta_model.dart';
import '../../../../models/movimiento_cobro_model.dart';
import '../../../../providers/abono_provider.dart';
import '../../../../providers/cobros_provider.dart';
import '../../../../services/cobro_service.dart';
import 'registrar_abono_screen.dart';
import 'registrar_pago_screen.dart';

class EstadoCuentaScreen extends StatefulWidget {
  const EstadoCuentaScreen({super.key});

  @override
  State<EstadoCuentaScreen> createState() => _EstadoCuentaScreenState();
}

class _EstadoCuentaScreenState extends State<EstadoCuentaScreen> {
  // Historial completo de cobros (pagados + pendientes)
  List<CobroModel> _historial = [];
  bool _loadingHistorial = true;

  // Filtros
  int? _anioFiltro;
  int? _mesFiltro;
  String? _estadoFiltro;

  static const _estadoOpciones = [
    'PENDIENTE', 'PARCIAL', 'VENCIDO', 'PAGADO', 'EXONERADO',
  ];

  static Color _colorEstado(String estado) {
    switch (estado) {
      case 'PAGADO':
      case 'EXONERADO':
        return Colors.green;
      case 'VENCIDO':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  static const _nombresMes = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  static const _abrevMes = [
    'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
    'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Estadísticas de balance (pendiente/vencido)
      context.read<CobrosProvider>().cargarEstadoCuenta();
      // Historial completo para la línea de tiempo
      _cargarHistorial();
    });
  }

  Future<void> _cargarHistorial() async {
    setState(() => _loadingHistorial = true);
    try {
      // Ambos endpoints en paralelo:
      // - historialCobros → cobros PAGADOS
      // - misCobros       → cobros ACTIVOS (pendientes / vencidos / parciales)
      final results = await Future.wait([
        CobroService.getHistorial(),
        CobroService.getMisCobros(),
      ]);

      // Merge deduplicando por ID (activos tienen prioridad sobre historial)
      final mapa = <int, CobroModel>{};
      for (final c in [...results[0], ...results[1]]) {
        mapa[c.id] = c;
      }

      final h = mapa.values.toList()
        ..sort((a, b) {
          if (b.anio != a.anio) return b.anio - a.anio;
          return b.mes - a.mes;
        });

      if (!mounted) return;
      setState(() => _historial = h);

      // Cargar saldo a favor usando propiedadId del primer cobro
      if (h.isNotEmpty) {
        context.read<AbonoProvider>().cargarSaldoFavor(h.first.propiedadId);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingHistorial = false);
    }
  }

  // ─── Filtros helpers ───────────────────────────────────────────────────────

  List<int> get _aniosDisponibles {
    final anios = _historial.map((c) => c.anio).toSet().toList();
    anios.sort((a, b) => b - a);
    return anios;
  }

  List<int> get _mesesDisponibles {
    final meses = _historial
        .where((c) => _anioFiltro == null || c.anio == _anioFiltro)
        .map((c) => c.mes)
        .toSet()
        .toList();
    meses.sort();
    return meses;
  }

  List<CobroModel> get _cobrosFiltrados => _historial.where((c) {
        if (_anioFiltro != null && c.anio != _anioFiltro) return false;
        if (_mesFiltro != null && c.mes != _mesFiltro) return false;
        if (_estadoFiltro != null && c.estado != _estadoFiltro) return false;
        return true;
      }).toList();

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CobrosProvider>();
    final abonos = context.watch<AbonoProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Estado de Cuenta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CobrosProvider>().cargarEstadoCuenta();
              _cargarHistorial();
            },
          ),
        ],
      ),
      body: provider.loading && _loadingHistorial
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _buildError(provider.error!)
              : RefreshIndicator(
                  onRefresh: () async {
                    await context.read<CobrosProvider>().cargarEstadoCuenta();
                    await _cargarHistorial();
                  },
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // ── Balance header ──────────────────────────
                      _BalanceHeader(
                        estadoCuenta: provider.estadoCuenta,
                        saldoFavor: abonos.saldoFavor?.saldo ?? 0,
                        formatMonto: _fmt,
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Filtros ─────────────────────────────
                            _buildFiltros(),
                            const SizedBox(height: 16),
                            // ── Título sección ──────────────────────
                            Text(
                              'Historial Detallado',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Línea de tiempo de sus movimientos financieros.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 16),

                            // ── Timeline ────────────────────────────
                            if (_loadingHistorial)
                              const Center(
                                  child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ))
                            else if (_cobrosFiltrados.isEmpty)
                              _buildVacio()
                            else
                              ..._buildTimeline(_cobrosFiltrados),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError(String msg) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center),
            TextButton(
              onPressed: () =>
                  context.read<CobrosProvider>().cargarEstadoCuenta(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );

  // ─── Filtros ──────────────────────────────────────────────────────────────

  Widget _buildFiltros() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Año
        _FiltroChip(
          label: _anioFiltro?.toString() ?? 'Año',
          isActive: _anioFiltro != null,
          opciones: [
            const DropdownMenuItem(value: null, child: Text('Todos los años')),
            ..._aniosDisponibles.map((a) =>
                DropdownMenuItem(value: a, child: Text(a.toString()))),
          ],
          value: _anioFiltro,
          onChanged: (v) => setState(() {
            _anioFiltro = v;
            _mesFiltro = null;
          }),
        ),
        // Mes
        _FiltroChip<int?>(
          label: _mesFiltro != null
              ? _nombresMes[_mesFiltro! - 1]
              : 'Todos los meses',
          isActive: _mesFiltro != null,
          opciones: [
            const DropdownMenuItem(value: null, child: Text('Todos los meses')),
            ..._mesesDisponibles.map((m) => DropdownMenuItem(
                  value: m,
                  child: Text(_nombresMes[m - 1]),
                )),
          ],
          value: _mesFiltro,
          onChanged: (v) => setState(() => _mesFiltro = v),
        ),
        // Estado
        _FiltroChip<String?>(
          label: _estadoFiltro ?? 'Estado',
          isActive: _estadoFiltro != null,
          activeColor:
              _estadoFiltro != null ? _colorEstado(_estadoFiltro!) : null,
          opciones: [
            const DropdownMenuItem(value: null, child: Text('Todos los estados')),
            ..._estadoOpciones.map((e) => DropdownMenuItem(
                  value: e,
                  child: Row(
                    children: [
                      Container(
                        width: 1,
                        height: 6,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: _colorEstado(e),
                          shape: BoxShape.rectangle,
                        ),
                      ),
                      Text(e, style: TextStyle(fontSize: 14)),
                    ],
                  ),
                )),
          ],
          value: _estadoFiltro,
          onChanged: (v) => setState(() => _estadoFiltro = v),
        ),
      ],
    );
  }

  // ─── Timeline ─────────────────────────────────────────────────────────────

  List<Widget> _buildTimeline(List<CobroModel> cobros) {
    return List.generate(cobros.length, (i) {
      final cobro = cobros[i];
      final esUltimo = i == cobros.length - 1;
      // Cobros con pago parcial van a registrar abono con el saldo pendiente
      final esAbono = cobro.esParcial;
      return _TimelineItem(
        cobro: cobro,
        esUltimo: esUltimo,
        formatMonto: _fmt,
        nombreMes: _nombresMes[cobro.mes - 1],
        abrevMes: _abrevMes[cobro.mes - 1],
        onLiquidar: esAbono
            ? () => _irARegistrarAbono(cobro)
            : () => _irARegistrarPago(cobro),
        esAbono: esAbono,
      );
    });
  }

  Widget _buildVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Sin cobros en este período',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Navegación ───────────────────────────────────────────────────────────

  Future<void> _irARegistrarPago(CobroModel cobro) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RegistrarPagoScreen(cobro: cobro)),
    );
    if (result == true && mounted) {
      context.read<CobrosProvider>().cargarEstadoCuenta();
      _cargarHistorial();
    }
  }

  Future<void> _irARegistrarAbono(CobroModel cobro) async {
    // Para cobros parciales usamos RegistrarPagoScreen con cobroId explícito,
    // así el backend aplica el pago al cobro correcto en vez de FIFO.
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RegistrarPagoScreen(
          cobro: cobro,
          montoPagar: cobro.montoPendiente,
        ),
      ),
    );
    if (result == true && mounted) {
      context.read<CobrosProvider>().cargarEstadoCuenta();
      _cargarHistorial();
    }
  }

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}

// ─── Balance Header ──────────────────────────────────────────────────────────

class _BalanceHeader extends StatelessWidget {
  final EstadoCuentaModel? estadoCuenta;
  final double saldoFavor;
  final String Function(double) formatMonto;

  const _BalanceHeader({
    required this.estadoCuenta,
    required this.saldoFavor,
    required this.formatMonto,
  });

  @override
  Widget build(BuildContext context) {
    final ec = estadoCuenta;
    final totalPendiente = ec?.totalDeuda ?? 0;
    final neto = (totalPendiente - saldoFavor).clamp(0.0, double.infinity);
    final estaAlDia = totalPendiente == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: estaAlDia
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : [const Color(0xFF1A237E), const Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BALANCE DE PAGOS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Total por pagar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Por pagar',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                formatMonto(totalPendiente),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),

          // Saldo a favor (si existe)
          if (saldoFavor > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Saldo a favor',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(
                  '− ${formatMonto(saldoFavor)}',
                  style: const TextStyle(
                      color: Color(0xFF80CBC4),
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),

          // Neto a pagar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estaAlDia ? '¡Estás al día!' : 'Neto a pagar',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  if (ec != null && !estaAlDia)
                    Text(
                      '${ec.cobrosVencidos} vencido${ec.cobrosVencidos != 1 ? 's' : ''} · ${ec.cobrosPendientes} pendiente${ec.cobrosPendientes != 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                ],
              ),
              Text(
                estaAlDia ? formatMonto(0) : formatMonto(neto),
                style: TextStyle(
                  color: estaAlDia
                      ? const Color(0xFF80CBC4)
                      : Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Filtro Chip ──────────────────────────────────────────────────────────────

class _FiltroChip<T> extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color? activeColor;
  final List<DropdownMenuItem<T>> opciones;
  final T value;
  final ValueChanged<T> onChanged;

  const _FiltroChip({
    required this.label,
    required this.isActive,
    this.activeColor,
    required this.opciones,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (activeColor ?? Theme.of(context).colorScheme.primary)
        : Colors.grey.shade600;

    return IntrinsicWidth(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: opciones,
          onChanged: (v) {
            if (v != null || T == Null || T.toString().contains('?')) {
              onChanged(v as T);
            }
          },
          selectedItemBuilder: (ctx) => opciones
              .map((_) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? color.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isActive
                              ? color.withValues(alpha: 0.4)
                              : Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label,
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w500,
                            )),
                        const SizedBox(width: 6),
                        Icon(Icons.keyboard_arrow_down,
                            size: 16, color: color),
                      ],
                    ),
                  ))
              .toList(),
          icon: const SizedBox.shrink(),
          isDense: true,
        ),
      ),
    );
  }
}

// ─── Timeline Item ────────────────────────────────────────────────────────────

class _TimelineItem extends StatelessWidget {
  final CobroModel cobro;
  final bool esUltimo;
  final String Function(double) formatMonto;
  final String nombreMes;
  final String abrevMes;
  final VoidCallback onLiquidar;
  final bool esAbono;

  const _TimelineItem({
    required this.cobro,
    required this.esUltimo,
    required this.formatMonto,
    required this.nombreMes,
    required this.abrevMes,
    required this.onLiquidar,
    this.esAbono = false,
  });

  Color get _dotColor {
    if (cobro.esPagado || cobro.esExonerado) return Colors.green;
    if (cobro.esVencido) return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Dot + línea vertical ──
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: _dotColor.withValues(alpha: 0.4),
                          blurRadius: 4)
                    ],
                  ),
                ),
                if (!esUltimo)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // ── Card del cobro ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _CobroCard(
                cobro: cobro,
                formatMonto: formatMonto,
                nombreMes: nombreMes,
                abrevMes: abrevMes,
                onLiquidar: onLiquidar,
                esAbono: esAbono,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cobro Card ───────────────────────────────────────────────────────────────

class _CobroCard extends StatefulWidget {
  final CobroModel cobro;
  final String Function(double) formatMonto;
  final String nombreMes;
  final String abrevMes;
  final VoidCallback onLiquidar;
  final bool esAbono;

  const _CobroCard({
    required this.cobro,
    required this.formatMonto,
    required this.nombreMes,
    required this.abrevMes,
    required this.onLiquidar,
    this.esAbono = false,
  });

  @override
  State<_CobroCard> createState() => _CobroCardState();
}

class _CobroCardState extends State<_CobroCard> {
  bool _expandido = false;
  bool _cargando = false;
  List<MovimientoCobroModel>? _movimientos;

  CobroModel get cobro => widget.cobro;

  bool get _estaActivo =>
      cobro.esPendiente || cobro.esVencido || cobro.esParcial;

  Color get _badgeColor {
    if (cobro.esPagado || cobro.esExonerado) return Colors.green;
    if (cobro.esVencido) return Colors.red;
    return Colors.orange;
  }

  String get _badgeTexto {
    if (cobro.esPagado) return 'PAGADO';
    if (cobro.esExonerado) return 'EXONERADO';
    if (cobro.esVencido) return 'ATRASADO';
    if (cobro.esParcial) return 'PARCIAL';
    return 'PENDIENTE';
  }

  String get _fechaInfo {
    if (cobro.esPagado || cobro.esExonerado) {
      return 'Liquidado antes del ${_formatFecha(cobro.fechaLimitePago)}';
    }
    if (cobro.esVencido) {
      try {
        final limite = DateTime.parse(cobro.fechaLimitePago);
        final dias = DateTime.now().difference(limite).inDays;
        return 'Vencido hace $dias día${dias != 1 ? 's' : ''}';
      } catch (_) {
        return 'Vencido el ${_formatFecha(cobro.fechaLimitePago)}';
      }
    }
    return 'Vence el ${_formatFecha(cobro.fechaLimitePago)}';
  }

  Color get _fechaInfoColor {
    if (cobro.esPagado || cobro.esExonerado) return Colors.grey.shade500;
    if (cobro.esVencido) return Colors.red;
    return Colors.orange.shade700;
  }

  String _formatFecha(String fecha) {
    try {
      final d = DateTime.parse(fecha);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha;
    }
  }

  String get _periodoTexto {
    final inicio = '01 ${widget.abrevMes}';
    final fin = _formatFechaLimite(cobro.fechaLimitePago, widget.abrevMes);
    return '$inicio - $fin';
  }

  String _formatFechaLimite(String fecha, String defaultAbrev) {
    try {
      final d = DateTime.parse(fecha);
      return '${d.day.toString().padLeft(2, '0')} $defaultAbrev';
    } catch (_) {
      return defaultAbrev;
    }
  }

  Future<void> _toggleMovimientos() async {
    if (_expandido) {
      setState(() => _expandido = false);
      return;
    }
    if (_movimientos == null) {
      setState(() => _cargando = true);
      try {
        final movs = await CobroService.getMovimientosCobro(cobro.id);
        if (mounted) setState(() => _movimientos = movs);
      } catch (_) {
        if (mounted) setState(() => _movimientos = []);
      } finally {
        if (mounted) setState(() => _cargando = false);
      }
    }
    if (mounted) setState(() => _expandido = true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: _badgeColor.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header del card ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.nombreMes} ${cobro.anio}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            _periodoTexto,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _badgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cobro.esPagado || cobro.esExonerado
                                ? Icons.check_circle_outline
                                : Icons.schedule_outlined,
                            size: 12,
                            color: _badgeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _badgeTexto,
                            style: TextStyle(
                              color: _badgeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _fechaInfo,
                  style: TextStyle(
                      fontSize: 12,
                      color: _fechaInfoColor,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade100),

          // ── Desglose de conceptos ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cobro.concepto,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade700)),
                          const SizedBox(height: 2),
                          Text(
                            cobro.descripcion != null &&
                                    cobro.descripcion!.isNotEmpty
                                ? cobro.descripcion!
                                : cobro.propiedadIdentificador,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      widget.formatMonto(cobro.montoBase),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700),
                    ),
                  ],
                ),
                if (cobro.montoMora > 0) ...[
                  const SizedBox(height: 6),
                  _LineaConcepto(
                    label: 'Recargo Mora',
                    monto: widget.formatMonto(cobro.montoMora),
                    color: Colors.red,
                    italica: true,
                  ),
                ],
                if (cobro.montoPagado > 0 && !cobro.esPagado) ...[
                  const SizedBox(height: 6),
                  _LineaConcepto(
                    label: 'Abonado',
                    monto: '− ${widget.formatMonto(cobro.montoPagado)}',
                    color: Colors.green,
                    italica: true,
                  ),
                ],
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _estaActivo ? 'POR PAGAR' : 'TOTAL',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5),
                    ),
                    Text(
                      _estaActivo
                          ? widget.formatMonto(cobro.montoPendiente)
                          : widget.formatMonto(cobro.montoTotal),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color:
                              _estaActivo ? _badgeColor : Colors.grey.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Botón "Ver movimientos" (solo si hay movimientos) ───
          if (cobro.tieneMovimientos) ...[
          Divider(height: 1, color: Colors.grey.shade100),
          InkWell(
            onTap: _toggleMovimientos,
            borderRadius: _estaActivo
                ? BorderRadius.zero
                : const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ver movimientos',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  if (_cargando)
                    const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Icon(
                      _expandido
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                ],
              ),
            ),
          ),

          // ── Mini-timeline de movimientos ─────────────────────────
          if (_expandido && _movimientos != null)
            _MovimientosTimeline(
              movimientos: _movimientos!,
              formatMonto: widget.formatMonto,
              esUltimoNivel: !_estaActivo,
            ),
          ], // fin if (cobro.tieneMovimientos)

          // ── Botón Liquidar ────────────────────────────────────────
          if (_estaActivo)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: TextButton(
                onPressed: widget.onLiquidar,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                ),
                child: Text(
                  widget.esAbono ? 'Abonar saldo restante' : 'Pagar Ahora',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Mini-timeline de movimientos por cobro ───────────────────────────────────

class _MovimientosTimeline extends StatelessWidget {
  final List<MovimientoCobroModel> movimientos;
  final String Function(double) formatMonto;
  final bool esUltimoNivel;

  const _MovimientosTimeline({
    required this.movimientos,
    required this.formatMonto,
    this.esUltimoNivel = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: movimientos.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sin movimientos registrados',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            )
          : Column(
              children: List.generate(movimientos.length, (i) {
                return _FilaMovimiento(
                  mov: movimientos[i],
                  formatMonto: formatMonto,
                  esUltimo: i == movimientos.length - 1,
                );
              }),
            ),
    );
  }
}

class _FilaMovimiento extends StatelessWidget {
  final MovimientoCobroModel mov;
  final String Function(double) formatMonto;
  final bool esUltimo;

  const _FilaMovimiento({
    required this.mov,
    required this.formatMonto,
    this.esUltimo = false,
  });

  Color get _estadoColor {
    if (mov.esVerificado) return Colors.green;
    if (mov.esRechazado) return Colors.red;
    return Colors.orange;
  }

  String get _estadoTexto {
    if (mov.esVerificado) return 'Verificado';
    if (mov.esRechazado) return 'Rechazado';
    return 'Pendiente';
  }

  IconData get _tipoIcon =>
      mov.esPago ? Icons.credit_card_outlined : Icons.account_balance_wallet_outlined;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: esUltimo ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot
          Column(
            children: [
              const SizedBox(height: 2),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _estadoColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!esUltimo)
                Container(
                  width: 1.5,
                  height: 28,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_tipoIcon, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      mov.esPago ? 'Pago' : 'Abono',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700),
                    ),
                    if (mov.metodoPago != null) ...[
                      Text(
                        ' · ${mov.metodoPago}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      formatMonto(mov.monto),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _estadoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _estadoTexto,
                        style: TextStyle(
                            fontSize: 10,
                            color: _estadoColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (mov.fecha != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        mov.fecha!,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                    if (mov.motivoRechazo != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          mov.motivoRechazo!,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.red),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Línea de concepto ────────────────────────────────────────────────────────

class _LineaConcepto extends StatelessWidget {
  final String label;
  final String monto;
  final Color color;
  final bool italica;

  const _LineaConcepto({
    required this.label,
    required this.monto,
    required this.color,
    this.italica = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontStyle: italica ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
        Text(
          monto,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
