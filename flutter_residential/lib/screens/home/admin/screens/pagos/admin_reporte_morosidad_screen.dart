import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../providers/cobros_provider.dart';
import '../../../../../models/cobro_model.dart';

class AdminReporteMorosidadScreen extends StatefulWidget {
  const AdminReporteMorosidadScreen({super.key});

  @override
  State<AdminReporteMorosidadScreen> createState() =>
      _AdminReporteMorosidadScreenState();
}

class _AdminReporteMorosidadScreenState
    extends State<AdminReporteMorosidadScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context
            .read<CobrosProvider>()
            .cargarCobrosAdmin(estado: 'VENCIDO'));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CobrosProvider>();
    final vencidos = provider.vencidos;
    final totalMora = vencidos.fold(
        0.0, (sum, c) => sum + c.montoMora);
    final totalDeuda = vencidos.fold(
        0.0, (sum, c) => sum + c.montoTotal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Morosidad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context
                .read<CobrosProvider>()
                .cargarCobrosAdmin(estado: 'VENCIDO'),
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _resumen(vencidos.length, totalMora, totalDeuda),
                Expanded(
                  child: vencidos.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sentiment_satisfied_alt,
                                  size: 52, color: Colors.green),
                              SizedBox(height: 12),
                              Text('Sin cobros vencidos',
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: vencidos.length,
                          itemBuilder: (_, i) =>
                              _MorosoTile(cobro: vencidos[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _resumen(
      int cantidad, double totalMora, double totalDeuda) =>
      Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('Vencidos', '$cantidad', Colors.red),
            _stat('Total mora', _fmt(totalMora), Colors.orange),
            _stat('Total deuda', _fmt(totalDeuda), Colors.red.shade700),
          ],
        ),
      );

  Widget _stat(String label, String valor, Color color) => Column(
        children: [
          Text(valor,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey)),
        ],
      );
}

class _MorosoTile extends StatelessWidget {
  final CobroModel cobro;
  const _MorosoTile({required this.cobro});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: Colors.red.withValues(alpha: 0.3))),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0x1FFF0000),
          child: Icon(Icons.warning_amber, color: Colors.red, size: 20),
        ),
        title: Text(cobro.propiedadIdentificador,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            cobro.usuarioNombre,
            style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_fmt(cobro.montoTotal),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),
            if (cobro.montoMora > 0)
              Text('Mora: ${_fmt(cobro.montoMora)}',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.orange)),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
