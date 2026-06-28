import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import '../models/acceso_vehicular_model.dart';
import '../models/propiedad_opcion_model.dart';
import '../models/validar_visita_model.dart';
import '../providers/vigilancia_provider.dart';
import '../services/vigilancia_service.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<VigilanciaProvider>().cargarPropiedades());
  }

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
    final propiedades = context.watch<VigilanciaProvider>().propiedades;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<PropiedadOpcionModel>(
            value: _propiedad,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Unidad de destino',
              prefixIcon: Icon(Icons.home_work_outlined),
            ),
            items: propiedades
                .map((p) => DropdownMenuItem(value: p, child: Text(p.identificador)))
                .toList(),
            onChanged: (v) => setState(() => _propiedad = v),
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
  final _codigoCtrl = TextEditingController();
  bool _cargando = false;
  ValidarVisitaModel? _resultado;
  String? _error;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _validar() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.isEmpty) return;
    setState(() {
      _cargando = true;
      _resultado = null;
      _error = null;
    });
    try {
      final r = await VigilanciaService.validarVisita(codigo);
      setState(() => _resultado = r);
    } catch (e) {
      setState(() => _error = 'Código de visita no válido');
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
          Text(
            'Ingresa o escanea el código del QR que presenta la visita.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _codigoCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Código de la visita',
              prefixIcon: Icon(Icons.qr_code_2_rounded),
            ),
            onSubmitted: (_) => _validar(),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _cargando ? null : _validar,
            icon: _cargando
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.verified_user_rounded),
            label: const Text('Validar visita'),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_error != null)
            ResultadoAccesoCard(
              permitido: false,
              titulo: 'No válido',
              mensaje: _error!,
            ),
          if (_resultado != null)
            ResultadoAccesoCard(
              permitido: _resultado!.permitido,
              titulo: _resultado!.permitido ? 'Acceso autorizado' : 'Acceso denegado',
              mensaje: _resultado!.mensaje ?? '',
              detalles: {
                if (_resultado!.nombreVisitante != null)
                  'Visitante': _resultado!.nombreVisitante!,
                if (_resultado!.documento != null) 'Documento': _resultado!.documento!,
                if (_resultado!.propiedadIdentificador != null)
                  'Unidad': _resultado!.propiedadIdentificador!,
              },
            ),
        ],
      ),
    );
  }
}
