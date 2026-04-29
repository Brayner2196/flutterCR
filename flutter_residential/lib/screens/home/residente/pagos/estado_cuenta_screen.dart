import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/cobros_provider.dart';
import '../../../../providers/residente_estadisticas_provider.dart';
import '../../../../models/cobro_model.dart';
import '../../../../models/estado_cuenta_model.dart';
import '../widgets/estado_badge_card.dart';
import '../widgets/kpi_card.dart';
import '../widgets/proximo_vencimiento_card.dart';
import 'detalle_cobro_screen.dart';
import 'mis_cobros_screen.dart';

class EstadoCuentaScreen extends StatefulWidget {
  const EstadoCuentaScreen({super.key});

  @override
  State<EstadoCuentaScreen> createState() => _EstadoCuentaScreenState();
}

class _EstadoCuentaScreenState extends State<EstadoCuentaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CobrosProvider>().cargarEstadoCuenta();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CobrosProvider>();
    final stats = context.watch<ResidenteEstadisticasProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de Cuenta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CobrosProvider>().cargarEstadoCuenta();
              context.read<ResidenteEstadisticasProvider>().refrescar();
            },
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _error(provider.error!)
              : _body(provider.estadoCuenta, stats),
    );
  }

  Widget _error(String msg) => Center(
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

  Widget _body(EstadoCuentaModel? ec, ResidenteEstadisticasProvider stats) {
    if (ec == null) return const SizedBox.shrink();
    final e = stats.estadisticas;

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<CobrosProvider>().cargarEstadoCuenta();
        await context.read<ResidenteEstadisticasProvider>().refrescar();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Badge de estado general ──────────────────
          EstadoBadgeCard(
            alDia: ec.alDia,
            enMora: ec.cobrosVencidos > 0,
            totalDeuda: ec.totalDeuda,
            cobrosPendientes: ec.cobrosPendientes,
            cobrosVencidos: ec.cobrosVencidos,
            formatMonto: _fmt,
          ),
          const SizedBox(height: 14),

          // ─── KPIs detallados ──────────────────────────
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 6,
            mainAxisSpacing: 8,
            childAspectRatio: 1.8,
            children: [
              KpiCard(
                label: 'Pendiente',
                valor: _fmt(ec.totalPendiente),
                icono: Icons.schedule_rounded,
                color: Colors.orange,
                subtitulo: '${ec.cobrosPendientes} cobro${ec.cobrosPendientes != 1 ? 's' : ''}',
              ),
              KpiCard(
                label: 'Vencido',
                valor: _fmt(ec.totalVencido),
                icono: Icons.warning_amber_rounded,
                color: Colors.red,
                subtitulo: '${ec.cobrosVencidos} cobro${ec.cobrosVencidos != 1 ? 's' : ''}',
              ),
              if (e != null) ...[
                KpiCard(
                  label: 'Total pagado',
                  valor: _fmt(e.totalPagadoHistorico),
                  icono: Icons.check_circle_outline,
                  color: Colors.green,
                  subtitulo: '${e.cobrosPagados} cobros pagados',
                ),
                KpiCard(
                  label: 'Cumplimiento',
                  valor: '${e.porcentajeCumplimiento.toInt()}%',
                  icono: Icons.trending_up_rounded,
                  color: e.porcentajeCumplimiento >= 80
                      ? Colors.green
                      : e.porcentajeCumplimiento >= 50
                          ? Colors.orange
                          : Colors.red,
                  subtitulo: '${e.cobrosPagados} de ${e.totalCobrosHistoricos}',
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // ─── Próximo vencimiento ──────────────────────
          if (e != null && e.proximoVencimiento != null) ...[
            ProximoVencimientoCard(
              cobro: e.proximoVencimiento!,
              diasRestantes: e.diasParaVencimiento,
              formatMonto: _fmt,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DetalleCobroScreen(cobro: e.proximoVencimiento!),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ─── Último pago ──────────────────────────────
          if (ec.ultimoPago != null)
            _infoCard(
              icono: Icons.payment,
              color: const Color(0xFF5479E0),
              titulo: 'Último pago registrado',
              subtitulo: ec.ultimoPago!,
            ),

          // ─── Cobros activos ───────────────────────────
          if (ec.cobrosActivos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cobros activos',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MisCobrosScreen())),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...ec.cobrosActivos.map((c) => _CobroCard(cobro: c)),
          ] else if (ec.alDia) ...[
            const SizedBox(height: 16),
            _tarjetaAlDia(),
          ],
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icono,
    required Color color,
    required String titulo,
    required String subtitulo,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
                Text(subtitulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaAlDia() => Card(
        color: Colors.green.shade50,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 52),
              SizedBox(height: 12),
              Text('Sin cobros pendientes',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 4),
              Text('Todas tus cuotas están al día',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}

class _CobroCard extends StatelessWidget {
  final CobroModel cobro;
  const _CobroCard({required this.cobro});

  @override
  Widget build(BuildContext context) {
    final color = cobro.esVencido ? Colors.red : Colors.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3))),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.receipt_long, color: color, size: 22),
        ),
        title: Text(cobro.concepto,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${cobro.mes}/${cobro.anio} · ${cobro.propiedadIdentificador}',
                style: const TextStyle(fontSize: 12)),
            Text('Vence: ${cobro.fechaLimitePago}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_fmt(cobro.montoTotal),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 15)),
            if (cobro.montoMora > 0)
              Text('Mora: ${_fmt(cobro.montoMora)}',
                  style: const TextStyle(
                      color: Colors.red, fontSize: 10)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4)),
              child: Text(cobro.estado,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10)),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DetalleCobroScreen(cobro: cobro)),
        ),
      ),
    );
  }

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
