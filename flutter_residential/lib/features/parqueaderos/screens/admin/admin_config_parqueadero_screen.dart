import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../../models/parqueadero_model.dart';
import '../../providers/parqueadero_provider.dart';

/// Tab de configuración del módulo de parqueaderos (TENANT_ADMIN).
/// Se embebe dentro de AdminParqueaderosScreen.
class AdminConfigParqueaderoTab extends StatefulWidget {
  const AdminConfigParqueaderoTab({super.key});

  @override
  State<AdminConfigParqueaderoTab> createState() =>
      _AdminConfigParqueaderoTabState();
}

class _AdminConfigParqueaderoTabState extends State<AdminConfigParqueaderoTab> {
  // Controladores de texto
  final _totalCtrl      = TextEditingController();
  final _comunesCtrl    = TextEditingController();
  final _privadosCtrl   = TextEditingController();
  final _maxVehCtrl     = TextEditingController();
  final _visitantesCtrl = TextEditingController();

  // Valores de switches
  bool _permiteCarro          = true;
  bool _permiteMoto           = true;
  bool _permiteBici           = true;
  bool _requiereAprobacion    = false;
  bool _aceptaVisitantes      = false;
  ModeloParqueaderoPrivado _modeloPrivadoDefault = ModeloParqueaderoPrivado.ACCESORIO;

  bool _cargando = false;
  bool _iniciado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarConfig());
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    _comunesCtrl.dispose();
    _privadosCtrl.dispose();
    _maxVehCtrl.dispose();
    _visitantesCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarConfig() async {
    await context.read<ParqueaderoProvider>().cargarConfig();
    if (!mounted) return;
    _sincronizarFormulario();
    setState(() => _iniciado = true);
  }

  void _sincronizarFormulario() {
    final cfg = context.read<ParqueaderoProvider>().config;
    _totalCtrl.text    = cfg.totalParqueaderos.toString();
    _comunesCtrl.text  = cfg.parqueaderosComunes.toString();
    _privadosCtrl.text = cfg.parqueaderosPrivados.toString();
    _maxVehCtrl.text   = cfg.maxVehiculosPorPropiedad.toString();
    _permiteCarro         = cfg.permiteCarro;
    _permiteMoto          = cfg.permiteMoto;
    _permiteBici          = cfg.permiteBicicleta;
    _requiereAprobacion   = cfg.requiereAprobacionVehiculo;
    _modeloPrivadoDefault = cfg.modeloPrivadoDefault;
    _aceptaVisitantes     = cfg.aceptaParqueaderoVisitantes;
    _visitantesCtrl.text  = cfg.totalParqueaderosVisitantes.toString();
  }

  Future<void> _guardar() async {
    final data = {
      'totalParqueaderos':          int.tryParse(_totalCtrl.text) ?? 0,
      'parqueaderosComunes':        int.tryParse(_comunesCtrl.text) ?? 0,
      'parqueaderosPrivados':       int.tryParse(_privadosCtrl.text) ?? 0,
      'maxVehiculosPorPropiedad':   int.tryParse(_maxVehCtrl.text) ?? 2,
      'permiteCarro':               _permiteCarro,
      'permiteMoto':                _permiteMoto,
      'permiteBicicleta':           _permiteBici,
      'requiereAprobacionVehiculo':  _requiereAprobacion,
      'modeloPrivadoDefault':        _modeloPrivadoDefault.name,
      'aceptaParqueaderoVisitantes': _aceptaVisitantes,
      'totalParqueaderosVisitantes': _aceptaVisitantes
          ? (int.tryParse(_visitantesCtrl.text) ?? 0)
          : 0,
    };

    setState(() => _cargando = true);
    try {
      await context.read<ParqueaderoProvider>().guardarConfig(data);
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Configuración guardada'),
        autoCloseDuration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(e.toString().replaceFirst('Exception: ', '')),
        autoCloseDuration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<ParqueaderoProvider>().loading;

    if (!_iniciado && loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Conteos ────────────────────────────────────────────────
          _Seccion(titulo: 'Capacidad'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NumeroField(
                  controller: _totalCtrl,
                  label: 'Total',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumeroField(
                  controller: _comunesCtrl,
                  label: 'Comunes',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumeroField(
                  controller: _privadosCtrl,
                  label: 'Privados',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _NumeroField(
            controller: _maxVehCtrl,
            label: 'Máx. vehículos por propiedad',
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 24),

          // ── Tipos permitidos ─────────────────────────────────────
          _Seccion(titulo: 'Tipos de vehículo permitidos'),
          const SizedBox(height: 8),
          _SwitchTile(
            label: 'Carros',
            icono: Icons.directions_car_outlined,
            valor: _permiteCarro,
            onChange: (v) => setState(() => _permiteCarro = v),
          ),
          _SwitchTile(
            label: 'Motos',
            icono: Icons.two_wheeler_outlined,
            valor: _permiteMoto,
            onChange: (v) => setState(() => _permiteMoto = v),
          ),
          _SwitchTile(
            label: 'Bicicletas',
            icono: Icons.pedal_bike_outlined,
            valor: _permiteBici,
            onChange: (v) => setState(() => _permiteBici = v),
          ),

          const SizedBox(height: 24),

          // ── Aprobación ───────────────────────────────────────────
          _Seccion(titulo: 'Validación'),
          const SizedBox(height: 8),
          _SwitchTile(
            label: 'Requiere aprobación del admin para registrar vehículos',
            icono: Icons.verified_outlined,
            valor: _requiereAprobacion,
            onChange: (v) => setState(() => _requiereAprobacion = v),
          ),

          const SizedBox(height: 24),

          // ── Modelo parqueadero privado ────────────────────────────
          _Seccion(titulo: 'Modelo de parqueadero privado'),
          const SizedBox(height: 6),
          _InfoBanner(
            texto: _modeloPrivadoDefault == ModeloParqueaderoPrivado.INDEPENDIENTE
                ? 'Los parqueaderos privados son propiedades facturables independientes. '
                  'Se crean desde el árbol de tipos de propiedad (con "Es parqueadero" activo).'
                : 'Los parqueaderos privados son accesorios de un apartamento. '
                  'Se crean en bulk desde este módulo y se asignan manualmente.',
          ),
          const SizedBox(height: 10),
          _ModeloSelector(
            valor: _modeloPrivadoDefault,
            onChanged: (v) => setState(() => _modeloPrivadoDefault = v),
          ),

          const SizedBox(height: 24),

          // ── Visitantes ───────────────────────────────────────────
          _Seccion(titulo: 'Parqueadero de visitantes'),
          const SizedBox(height: 8),
          _SwitchTile(
            label: 'El conjunto tiene spots físicos para visitantes',
            icono: Icons.directions_car_filled,
            valor: _aceptaVisitantes,
            onChange: (v) => setState(() {
              _aceptaVisitantes = v;
              if (!v) _visitantesCtrl.text = '0';
            }),
          ),
          if (_aceptaVisitantes) ...[
            const SizedBox(height: 10),
            _NumeroField(
              controller: _visitantesCtrl,
              label: 'Cantidad de spots para visitantes',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 6),
            _InfoBanner(
              texto: 'Estos spots son para uso temporal de visitas. '
                  'El registro y control de visitantes se gestiona desde la portería.',
            ),
          ],

          const SizedBox(height: 32),

          // ── Botón guardar ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _cargando ? null : _guardar,
              child: _cargando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar configuración'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ──────────────────────────────────────────────────────

class _Seccion extends StatelessWidget {
  final String titulo;

  const _Seccion({required this.titulo});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      titulo.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}

class _NumeroField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;

  const _NumeroField({
    required this.controller,
    required this.label,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final IconData icono;
  final bool valor;
  final ValueChanged<bool> onChange;

  const _SwitchTile({
    required this.label,
    required this.icono,
    required this.valor,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icono, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Switch(value: valor, onChanged: onChange),
        ],
      ),
    );
  }
}

// ── Banner informativo ────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final String texto;
  const _InfoBanner({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 15, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto,
                style: const TextStyle(fontSize: 12, color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}

// ── Selector modelo privado ───────────────────────────────────────────────────

class _ModeloSelector extends StatelessWidget {
  final ModeloParqueaderoPrivado valor;
  final ValueChanged<ModeloParqueaderoPrivado> onChanged;

  const _ModeloSelector({required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        _OpcionModelo(
          activo: valor == ModeloParqueaderoPrivado.ACCESORIO,
          icono: Icons.link_outlined,
          titulo: 'Accesorio',
          subtitulo: 'Del apartamento',
          onTap: () => onChanged(ModeloParqueaderoPrivado.ACCESORIO),
          color: cs.primary,
        ),
        const SizedBox(width: 10),
        _OpcionModelo(
          activo: valor == ModeloParqueaderoPrivado.INDEPENDIENTE,
          icono: Icons.local_parking,
          titulo: 'Independiente',
          subtitulo: 'Propiedad propia',
          onTap: () => onChanged(ModeloParqueaderoPrivado.INDEPENDIENTE),
          color: Colors.teal,
        ),
      ],
    );
  }
}

class _OpcionModelo extends StatelessWidget {
  final bool activo;
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  final Color color;

  const _OpcionModelo({
    required this.activo,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: activo ? color.withValues(alpha: 0.1) : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: activo ? color.withValues(alpha: 0.6) : cs.outlineVariant,
              width: activo ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icono, size: 18, color: activo ? color : cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: activo ? color : cs.onSurface,
                        )),
                    Text(subtitulo,
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
