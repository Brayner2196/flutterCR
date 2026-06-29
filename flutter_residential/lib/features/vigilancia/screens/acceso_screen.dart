import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import '../models/acceso_vehicular_model.dart';
import '../models/propiedad_opcion_model.dart';
import '../services/vigilancia_service.dart';
import '../utils/qr_visita.dart';
import 'visita_resultado_screen.dart';
import 'widgets/propiedad_selector_field.dart';
import 'widgets/resultado_acceso_card.dart';

/// Control de acceso con 3 modos: placa vehicular, peatonal y QR de visita.
class AccesoScreen extends StatelessWidget {
  const AccesoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const Material(
            child: TabBar(
              tabs: [
                Tab(text: 'Vehículo', icon: Icon(Icons.directions_car_rounded)),
                Tab(text: 'Peatonal', icon: Icon(Icons.directions_walk_rounded)),
                Tab(text: 'Visita QR', icon: Icon(Icons.qr_code_2_rounded)),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _TabVehicular(),
                _TabPeatonal(),
                _TabVisita(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Acceso vehicular por placa ────────────────────────────────────────

class _TabVehicular extends StatefulWidget {
  const _TabVehicular();
  @override
  State<_TabVehicular> createState() => _TabVehicularState();
}

class _TabVehicularState extends State<_TabVehicular> {
  final _placaCtrl = TextEditingController();
  bool _cargando = false;
  AccesoVehicularModel? _resultado;
  String? _mensajeEspecial;

  @override
  void dispose() {
    _placaCtrl.dispose();
    super.dispose();
  }

  Future<void> _consultar() async {
    final placa = _placaCtrl.text.trim();
    if (placa.isEmpty) return;
    setState(() {
      _cargando = true;
      _resultado = null;
      _mensajeEspecial = null;
    });
    try {
      final r = await VigilanciaService.accesoVehicular(placa);
      setState(() => _resultado = r);
    } catch (e) {
      // 404 → placa no registrada: se gestiona como visitante.
      setState(() => _mensajeEspecial =
          'Placa no registrada. Gestiónala como visitante en la pestaña Peatonal.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _placaCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Placa del vehículo',
              prefixIcon: Icon(Icons.pin_rounded),
            ),
            onSubmitted: (_) => _consultar(),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _cargando ? null : _consultar,
            icon: _cargando
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.search_rounded),
            label: const Text('Verificar acceso'),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_mensajeEspecial != null)
            ResultadoAccesoCard(
              permitido: false,
              advertencia: true,
              titulo: 'Sin registro',
              mensaje: _mensajeEspecial!,
            ),
          if (_resultado != null)
            ResultadoAccesoCard(
              permitido: _resultado!.permitido,
              titulo: _resultado!.permitido ? 'Acceso permitido' : 'Acceso denegado',
              mensaje: _resultado!.mensaje ?? '',
              detalles: {
                'Placa': _resultado!.placa,
                'Unidad': _resultado!.propiedad,
                if (_resultado!.estadoNombre != null)
                  'Estado cartera': _resultado!.estadoNombre!,
              },
            ),
        ],
      ),
    );
  }
}

// ─── Tab 2: Acceso peatonal ───────────────────────────────────────────────────

class _TabPeatonal extends StatefulWidget {
  const _TabPeatonal();
  @override
  State<_TabPeatonal> createState() => _TabPeatonalState();
}

class _TabPeatonalState extends State<_TabPeatonal> {
  final _nombreCtrl = TextEditingController();
  final _docCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  PropiedadOpcionModel? _propiedad;
  bool _cargando = false;
  bool _registrado = false;
  bool _permitido = false;
  String? _mensaje;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _docCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_propiedad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona la unidad de destino')));
      return;
    }
    setState(() {
      _cargando = true;
      _registrado = false;
    });
    try {
      final r = await VigilanciaService.accesoPeatonal(
        propiedadId: _propiedad!.id,
        nombreVisitante: _nombreCtrl.text.trim().isEmpty ? null : _nombreCtrl.text.trim(),
        documento: _docCtrl.text.trim().isEmpty ? null : _docCtrl.text.trim(),
        motivo: _motivoCtrl.text.trim().isEmpty ? null : _motivoCtrl.text.trim(),
      );
      setState(() {
        _registrado = true;
        _permitido = r.esPermitido;
        _mensaje = r.descripcion;
      });
      _nombreCtrl.clear();
      _docCtrl.clear();
      _motivoCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PropiedadSelectorField(
            seleccionada: _propiedad,
            onSeleccion: (p) => setState(() => _propiedad = p),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre del visitante',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _docCtrl,
            decoration: const InputDecoration(
              labelText: 'Documento',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _motivoCtrl,
            decoration: const InputDecoration(
              labelText: 'Motivo (opcional)',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _cargando ? null : _registrar,
            icon: _cargando
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.login_rounded),
            label: const Text('Registrar ingreso'),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_registrado)
            ResultadoAccesoCard(
              permitido: _permitido,
              titulo: _permitido ? 'Ingreso registrado' : 'Ingreso denegado',
              mensaje: _mensaje ?? '',
            ),
        ],
      ),
    );
  }
}

// ─── Tab 3: Validar QR de visita ──────────────────────────────────────────────

class _TabVisita extends StatefulWidget {
  const _TabVisita();
  @override
  State<_TabVisita> createState() => _TabVisitaState();
}

class _TabVisitaState extends State<_TabVisita> {
  final _scannerCtrl = MobileScannerController();
  bool _procesando = false;

  @override
  void dispose() {
    _scannerCtrl.dispose();
    super.dispose();
  }

  Future<void> _procesarCodigo(String raw) async {
    if (_procesando) return;
    final codigo = extraerCodigoVisita(raw);
    if (codigo.isEmpty) return;
    setState(() => _procesando = true);
    try {
      await _scannerCtrl.stop();
    } catch (_) {}
    try {
      final detalle = await VigilanciaService.consultarVisita(codigo);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VisitaResultadoScreen(detalle: detalle)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
        try {
          await _scannerCtrl.start();
        } catch (_) {}
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw != null && raw.isNotEmpty) _procesarCodigo(raw);
  }

  Future<void> _ingresarManual() async {
    final ctrl = TextEditingController();
    final codigo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ingresar código'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'Código de la visita'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Validar')),
        ],
      ),
    );
    if (codigo != null && codigo.isNotEmpty) _procesarCodigo(codigo);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              MobileScanner(controller: _scannerCtrl, onDetect: _onDetect),
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              if (_procesando)
                Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Apunta la cámara al QR de la visita.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.keyboard_rounded),
                label: const Text('Código manual'),
                onPressed: _procesando ? null : _ingresarManual,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
