import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../models/periodo_cobro_model.dart';
import '../../../../../providers/cobros_provider.dart';

class AdminGenerarCobrosScreen extends StatefulWidget {
  final PeriodoCobroModel? periodo;
  const AdminGenerarCobrosScreen({super.key, this.periodo});

  @override
  State<AdminGenerarCobrosScreen> createState() =>
      _AdminGenerarCobrosScreenState();
}

class _AdminGenerarCobrosScreenState
    extends State<AdminGenerarCobrosScreen> {
  final _form = GlobalKey<FormState>();
  int _anio = DateTime.now().year;
  int _mes = DateTime.now().month;
  DateTime _fechaLimite =
      DateTime.now().add(const Duration(days: 10));
  bool _creandoPeriodo = false;
  bool _generando = false;

  static const _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generar Cobros')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.periodo != null)
              _infoPeriodo(widget.periodo!)
            else
              _formNuevoPeriodo(),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: (_creandoPeriodo || _generando) ? null : _ejecutar,
              icon: (_creandoPeriodo || _generando)
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
              label: Text(widget.periodo != null
                  ? 'Generar cobros para ${widget.periodo!.nombreMes}'
                  : 'Crear período y generar cobros'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPeriodo(PeriodoCobroModel p) => Card(
        color: Colors.green.shade50,
        child: ListTile(
          leading:
              const Icon(Icons.calendar_month, color: Colors.green),
          title: Text(p.nombreMes,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Límite: ${p.fechaLimitePago}'),
        ),
      );

  Widget _formNuevoPeriodo() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nuevo período de cobro',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _anio,
                  decoration: const InputDecoration(
                      labelText: 'Año',
                      border: OutlineInputBorder()),
                  items: List.generate(
                          3,
                          (i) => DateTime.now().year + i - 1)
                      .map((y) =>
                          DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (v) => setState(() => _anio = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _mes,
                  decoration: const InputDecoration(
                      labelText: 'Mes',
                      border: OutlineInputBorder()),
                  items: List.generate(12, (i) => i + 1)
                      .map((m) => DropdownMenuItem(
                          value: m, child: Text(_meses[m - 1])))
                      .toList(),
                  onChanged: (v) => setState(() => _mes = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _selectorFecha(
              'Fecha límite de pago', _fechaLimite,
              (d) => setState(() => _fechaLimite = d)),
        ],
      );

  Widget _selectorFecha(
          String label, DateTime valor, ValueChanged<DateTime> onChange) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: Text(
            '${valor.day}/${valor.month}/${valor.year}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: valor,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (d != null) onChange(d);
        },
      );

  Future<void> _ejecutar() async {
    final provider = context.read<CobrosProvider>();
    try {
      PeriodoCobroModel? periodo = widget.periodo;
      if (periodo == null) {
        setState(() => _creandoPeriodo = true);
        final inicio = DateTime(_anio, _mes, 1);
        final fin = DateTime(_anio, _mes + 1, 0);
        periodo = await provider.abrirPeriodo({
          'anio': _anio,
          'mes': _mes,
          'fechaInicio': _fmtDate(inicio),
          'fechaFin': _fmtDate(fin),
          'fechaLimitePago': _fmtDate(_fechaLimite),
        });
        setState(() => _creandoPeriodo = false);
      }
      setState(() => _generando = true);
      final cobros =
          await provider.generarCobros(periodo.anio, periodo.mes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('${cobros.length} cobros generados correctamente'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() {
        _creandoPeriodo = false;
        _generando = false;
      });
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
