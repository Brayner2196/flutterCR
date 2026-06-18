import 'package:flutter/material.dart';
import 'package:flutter_residential/core/utils/format_moneda.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/cobro_model.dart';
import '../../models/estado_cuenta_model.dart';
import '../../services/cobro_service.dart';

class AdminVerComoResidenteScreen extends StatefulWidget {
  final int usuarioId;
  final String usuarioNombre;

  const AdminVerComoResidenteScreen({
    super.key,
    required this.usuarioId,
    required this.usuarioNombre,
  });

  @override
  State<AdminVerComoResidenteScreen> createState() =>
      _AdminVerComoResidenteScreenState();
}

class _AdminVerComoResidenteScreenState
    extends State<AdminVerComoResidenteScreen> {
  EstadoCuentaModel? _estadoCuenta;
  List<CobroModel> _cobros = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        CobroService.getEstadoCuentaUsuario(widget.usuarioId),
        CobroService.listarCobrosDeUsuario(widget.usuarioId),
      ]);
      if (!mounted) return;
      setState(() {
        _estadoCuenta = results[0] as EstadoCuentaModel;
        _cobros = (results[1] as List).cast<CobroModel>();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.usuarioNombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Recargar',
            onPressed: _cargar,
          ),
        ],
      ),
      body: Column(
        children: [
          _BannerModoVista(nombre: widget.usuarioNombre),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _cargar)
                    : _estadoCuenta == null
                        ? const SizedBox()
                        : _ContenidoCuenta(
                            estadoCuenta: _estadoCuenta!,
                            cobros: _cobros,
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Banner naranja ────────────────────────────────────────────────────────────

class _BannerModoVista extends StatelessWidget {
  final String nombre;
  const _BannerModoVista({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.bgOrange,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, color: AppColors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.orange,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  const TextSpan(text: 'Vista de residente — '),
                  TextSpan(
                    text: nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text: '  •  Solo lectura',
                    style: TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contenido principal ───────────────────────────────────────────────────────

class _ContenidoCuenta extends StatelessWidget {
  final EstadoCuentaModel estadoCuenta;
  final List<CobroModel> cobros;

  const _ContenidoCuenta({
    required this.estadoCuenta,
    required this.cobros,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendientes = cobros.where((c) => c.tieneDeuda).toList();
    final historial = cobros.where((c) => !c.tieneDeuda).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _KpiResumen(estadoCuenta: estadoCuenta),
        const SizedBox(height: 20),

        if (pendientes.isNotEmpty) ...[
          _SectionLabel(label: 'Cobros pendientes', count: pendientes.length),
          const SizedBox(height: 8),
          ...pendientes.map((c) => _CobroTile(cobro: c)),
          const SizedBox(height: 20),
        ],

        if (historial.isNotEmpty) ...[
          _SectionLabel(label: 'Historial', count: historial.length),
          const SizedBox(height: 8),
          ...historial.map((c) => _CobroTile(cobro: c)),
          const SizedBox(height: 20),
        ],

        if (cobros.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    'Sin cobros registrados',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── KPI cards ─────────────────────────────────────────────────────────────────

class _KpiResumen extends StatelessWidget {
  final EstadoCuentaModel estadoCuenta;
  const _KpiResumen({required this.estadoCuenta});

  @override
  Widget build(BuildContext context) {
    final alDia = estadoCuenta.alDia;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: alDia ? AppColors.bgGreen : AppColors.bgOrange,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                alDia ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                color: alDia ? AppColors.ok : AppColors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alDia ? 'Al día' : 'Tiene deuda',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: alDia ? AppColors.ok : AppColors.orange,
                    ),
                  ),
                  if (!alDia)
                    Text(
                      'Total: ${FormatMoneda.format(estadoCuenta.totalDeuda)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Pendiente',
                valor: FormatMoneda.format(estadoCuenta.totalPendiente),
                color: AppColors.blue,
                bgColor: AppColors.bgBlue,
                icon: Icons.hourglass_empty_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                label: 'Vencido',
                valor: FormatMoneda.format(estadoCuenta.totalVencido),
                color: AppColors.danger,
                bgColor: AppColors.dangerSoft,
                icon: Icons.error_outline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                label: 'Cobros venc.',
                valor: '${estadoCuenta.cobrosVencidos}',
                color: AppColors.warning,
                bgColor: AppColors.warningSoft,
                icon: Icons.calendar_today_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _KpiCard({
    required this.label,
    required this.valor,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.75)),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  const _SectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

// ── Tile de cobro (read-only) ─────────────────────────────────────────────────

class _CobroTile extends StatelessWidget {
  final CobroModel cobro;
  const _CobroTile({required this.cobro});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, bgColor, label) = _estadoStyle(cobro.estado);

    String? periodo;
    if (cobro.anio != null && cobro.mes != null) {
      const meses = [
        '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      periodo = '${meses[cobro.mes!]} ${cobro.anio}';
    }

    // Formato de fecha: yyyy-MM-dd → dd/MM/yyyy
    String fechaLimite = cobro.fechaLimitePago;
    try {
      final partes = cobro.fechaLimitePago.split('-');
      if (partes.length == 3) {
        fechaLimite = '${partes[2]}/${partes[1]}/${partes[0]}';
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cobro.tieneDeuda
              ? color.withOpacity(0.35)
              : theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                        _etiquetaConcepto(cobro.concepto),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cobro.propiedadIdentificador,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),

            if (cobro.descripcion != null) ...[
              const SizedBox(height: 6),
              Text(
                cobro.descripcion!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _MontoItem(
                    label: 'Total',
                    valor: FormatMoneda.format(cobro.montoTotal),
                    bold: true,
                  ),
                ),
                if (cobro.montoPagado > 0)
                  Expanded(
                    child: _MontoItem(
                      label: 'Pagado',
                      valor: FormatMoneda.format(cobro.montoPagado),
                      color: AppColors.ok,
                    ),
                  ),
                if (cobro.tieneDeuda)
                  Expanded(
                    child: _MontoItem(
                      label: 'Pendiente',
                      valor: FormatMoneda.format(cobro.montoPendiente),
                      color: color,
                      bold: true,
                    ),
                  ),
                if (cobro.montoMora > 0)
                  Expanded(
                    child: _MontoItem(
                      label: 'Mora',
                      valor: FormatMoneda.format(cobro.montoMora),
                      color: AppColors.danger,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                if (periodo != null) ...[
                  const Icon(Icons.calendar_month_outlined,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(periodo,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.grey)),
                  const SizedBox(width: 12),
                ],
                const Icon(Icons.access_time_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Límite: $fechaLimite',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color, String) _estadoStyle(String estado) {
    switch (estado) {
      case 'PAGADO':
        return (AppColors.ok, AppColors.bgGreen, 'Pagado');
      case 'PARCIAL':
        return (AppColors.blue, AppColors.bgBlue, 'Parcial');
      case 'VENCIDO':
        return (AppColors.danger, AppColors.dangerSoft, 'Vencido');
      case 'EXONERADO':
        return (AppColors.teal, AppColors.bgTeal, 'Exonerado');
      default:
        return (AppColors.warning, AppColors.warningSoft, 'Pendiente');
    }
  }

  String _etiquetaConcepto(String c) {
    switch (c) {
      case 'ADMINISTRACION': return 'Administración';
      case 'MULTA':          return 'Multa';
      case 'SANCION':        return 'Sanción';
      case 'RECARGO':        return 'Recargo';
      default:               return c;
    }
  }
}

class _MontoItem extends StatelessWidget {
  final String label;
  final String valor;
  final Color? color;
  final bool bold;

  const _MontoItem({
    required this.label,
    required this.valor,
    this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = color ?? theme.colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
