import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../models/configuracion_cuota_model.dart';
import '../../../propiedades/models/tipo_propiedad_nodo.dart';
import '../../../propiedades/services/propiedad_service.dart';
import '../../services/cuota_service.dart';
import '../../../../shared/theme/app_theme.dart';

class AdminConfigurarCuotasScreen extends StatefulWidget {
  const AdminConfigurarCuotasScreen({super.key});

  @override
  State<AdminConfigurarCuotasScreen> createState() =>
      _AdminConfigurarCuotasScreenState();
}

class _AdminConfigurarCuotasScreenState
    extends State<AdminConfigurarCuotasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _cargando = true;
  List<TipoPropiedadNodo> _tiposFlat = [];
  List<Map<String, dynamic>> _propiedades = [];
  List<ConfiguracionCuotaModel> _cuotasActivas = [];
  List<ConfiguracionCuotaModel> _cuotasHistorial = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final resT = await ApiClient.get(ApiConstants.tiposPropiedad,
          requiresAuth: true);
      final listJson = jsonDecode(resT.body) as List;
      final nodos =
          listJson.map((e) => TipoPropiedadNodo.fromJson(e)).toList();
      final flat = <TipoPropiedadNodo>[];
      void flatten(TipoPropiedadNodo n) {
        flat.add(n);
        for (final h in n.hijos) flatten(h);
      }
      for (final n in nodos) flatten(n);

      final propiedades = await PropiedadService.listarPropiedades();
      final activas = await CuotaService.listar();
      final todas = await CuotaService.listarTodas();
      final historial = todas.where((c) => !c.activo).toList()
        ..sort((a, b) =>
            b.fechaVigenciaDesde.compareTo(a.fechaVigenciaDesde));

      if (mounted) {
        setState(() {
          _tiposFlat = flat;
          _propiedades = propiedades;
          _cuotasActivas = activas;
          _cuotasHistorial = historial;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _nombreTipo(int? id) {
    if (id == null) return 'Sin tipo';
    return _tiposFlat
        .firstWhere((t) => t.id == id,
            orElse: () => TipoPropiedadNodo(id: id, nombre: '#$id'))
        .nombre;
  }

  String _nombrePropiedad(int? id) {
    if (id == null) return '';
    final p = _propiedades.firstWhere(
      (p) => p['id'] == id,
      orElse: () => {'pathTexto': 'Propiedad #$id'},
    );
    return (p['pathTexto'] as String?) ?? (p['identificador'] as String?) ?? 'Propiedad #$id';
  }

  Future<void> _desactivar(ConfiguracionCuotaModel cuota) async {
    final esIndividual = cuota.propiedadId != null;
    final descripcion = esIndividual
        ? _nombrePropiedad(cuota.propiedadId)
        : _nombreTipo(cuota.tipoPropiedadId);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar cuota'),
        content: Text(
          'Desactivar la cuota de "$descripcion" '
          'por \$${_fmtMonto(cuota.monto)} (${cuota.periodicidad.toLowerCase()})?\n\n'
          'Pasará al historial y no se aplicará en futuros cobros.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await CuotaService.desactivar(cuota.id);
      await _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cuota desactivada y movida al historial'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _abrirFormulario() async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _NuevaCuotaSheet(
        tiposFlat: _tiposFlat,
        propiedades: _propiedades,
      ),
    );
    if (guardado == true) await _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar cuotas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 16),
                  const SizedBox(width: 6),
                  const Text('Activas'),
                  if (_cuotasActivas.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _CountBadge(_cuotasActivas.length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, size: 16),
                  const SizedBox(width: 6),
                  const Text('Historial'),
                  if (_cuotasHistorial.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _CountBadge(_cuotasHistorial.length),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Nueva cuota'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _TabActivas(
                  cuotas: _cuotasActivas,
                  nombreTipo: _nombreTipo,
                  nombrePropiedad: _nombrePropiedad,
                  onDesactivar: _desactivar,
                ),
                _TabHistorial(
                  cuotas: _cuotasHistorial,
                  nombreTipo: _nombreTipo,
                  nombrePropiedad: _nombrePropiedad,
                ),
              ],
            ),
    );
  }
}

// ─── Tab Activas ──────────────────────────────────────────────────────────────

class _TabActivas extends StatelessWidget {
  final List<ConfiguracionCuotaModel> cuotas;
  final String Function(int?) nombreTipo;
  final String Function(int?) nombrePropiedad;
  final void Function(ConfiguracionCuotaModel) onDesactivar;

  const _TabActivas({
    required this.cuotas,
    required this.nombreTipo,
    required this.nombrePropiedad,
    required this.onDesactivar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (cuotas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tune, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Sin cuotas configuradas',
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Toca "Nueva cuota" para comenzar',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    // Separar: cuotas por tipo (base + rango) vs. overrides individuales
    final porTipo = cuotas.where((c) => c.propiedadId == null).toList();
    final individuales = cuotas.where((c) => c.propiedadId != null).toList();

    // Agrupar por tipo
    final grupos = <int?, List<ConfiguracionCuotaModel>>{};
    for (final c in porTipo) {
      grupos.putIfAbsent(c.tipoPropiedadId, () => []).add(c);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Sección por tipo de propiedad
        ...grupos.entries.map((entry) {
          final base = entry.value.where((c) => c.numeroDesde == null).toList();
          final rangos = entry.value.where((c) => c.numeroDesde != null).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SeccionHeader(nombreTipo(entry.key).toUpperCase()),
              ...base.map((c) => _CuotaActivaTile(
                    cuota: c,
                    onDesactivar: () => onDesactivar(c),
                  )),
              if (rangos.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                  child: Row(
                    children: [
                      Container(width: 3, height: 12, color: cs.outlineVariant),
                      const SizedBox(width: 6),
                      Text('Overrides por rango',
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                ...rangos.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _CuotaActivaTile(
                        cuota: c,
                        onDesactivar: () => onDesactivar(c),
                        esRangoOverride: true,
                      ),
                    )),
              ],
              const SizedBox(height: 16),
            ],
          );
        }),

        // Sección cuotas individuales
        if (individuales.isNotEmpty) ...[
          _SeccionHeader('CUOTAS ESPECIALES'),
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgOrange,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Cuotas asignadas a unidades específicas. Tienen prioridad sobre las reglas por tipo.',
                    style: TextStyle(fontSize: 11, color: AppColors.orange),
                  ),
                ),
              ],
            ),
          ),
          ...individuales.map((c) => _CuotaActivaTile(
                cuota: c,
                nombrePropiedadOverride: nombrePropiedad(c.propiedadId),
                onDesactivar: () => onDesactivar(c),
                esIndividual: true,
              )),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _SeccionHeader extends StatelessWidget {
  final String texto;
  const _SeccionHeader(this.texto);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CuotaActivaTile extends StatelessWidget {
  final ConfiguracionCuotaModel cuota;
  final VoidCallback onDesactivar;
  final String? nombrePropiedadOverride;
  final bool esRangoOverride;
  final bool esIndividual;

  const _CuotaActivaTile({
    required this.cuota,
    required this.onDesactivar,
    this.nombrePropiedadOverride,
    this.esRangoOverride = false,
    this.esIndividual = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rangoStr = cuota.numeroDesde != null
        ? (cuota.numeroDesde == cuota.numeroHasta
            ? 'Nº ${cuota.numeroDesde}'
            : 'Nros ${cuota.numeroDesde}–${cuota.numeroHasta}')
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: esIndividual
            ? BorderSide(color: AppColors.orange.withOpacity(0.4), width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Etiqueta de propiedad individual si aplica
                  if (esIndividual && nombrePropiedadOverride != null) ...[
                    Row(
                      children: [
                        Icon(Icons.home_outlined,
                            size: 13, color: AppColors.orange),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            nombrePropiedadOverride!,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.orange,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Text(
                        '\$${_fmtMonto(cuota.monto)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _BadgePeriodicidad(cuota.periodicidad),
                      if (esIndividual) ...[
                        const SizedBox(width: 6),
                        _BadgeOverride(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (rangoStr != null) ...[
                        Icon(Icons.tag, size: 13, color: cs.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(rangoStr,
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant)),
                        const SizedBox(width: 12),
                      ],
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: cs.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Text(
                        cuota.fechaVigenciaHasta != null
                            ? '${_fmtFecha(cuota.fechaVigenciaDesde)} → ${_fmtFecha(cuota.fechaVigenciaHasta!)}'
                            : 'Desde ${_fmtFecha(cuota.fechaVigenciaDesde)}',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: AppColors.danger),
              tooltip: 'Desactivar',
              onPressed: onDesactivar,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Historial ────────────────────────────────────────────────────────────

class _TabHistorial extends StatelessWidget {
  final List<ConfiguracionCuotaModel> cuotas;
  final String Function(int?) nombreTipo;
  final String Function(int?) nombrePropiedad;

  const _TabHistorial({
    required this.cuotas,
    required this.nombreTipo,
    required this.nombrePropiedad,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (cuotas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Sin historial aun',
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Las cuotas desactivadas apareceran aqui',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: cuotas.length,
      itemBuilder: (_, i) {
        final c = cuotas[i];
        final esIndividual = c.propiedadId != null;
        final titulo = esIndividual
            ? nombrePropiedad(c.propiedadId)
            : nombreTipo(c.tipoPropiedadId);
        final rangoStr = c.numeroDesde != null
            ? (c.numeroDesde == c.numeroHasta
                ? 'Nº ${c.numeroDesde}'
                : 'Nros ${c.numeroDesde}–${c.numeroHasta}')
            : null;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i < cuotas.length - 1)
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 1.5,
                            color: cs.outlineVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: cs.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (esIndividual) ...[
                                Icon(Icons.home_outlined,
                                    size: 13, color: AppColors.orange),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  titulo,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: esIndividual ? AppColors.orange : null,
                                  ),
                                ),
                              ),
                              _BadgePeriodicidad(c.periodicidad),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '\$${_fmtMonto(c.monto)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              if (rangoStr != null) ...[
                                const SizedBox(width: 10),
                                Text(rangoStr,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c.fechaVigenciaHasta != null
                                ? '${_fmtFecha(c.fechaVigenciaDesde)} → ${_fmtFecha(c.fechaVigenciaHasta!)}'
                                : 'Desde ${_fmtFecha(c.fechaVigenciaDesde)}',
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Badges ───────────────────────────────────────────────────────────────────

class _BadgePeriodicidad extends StatelessWidget {
  final String periodicidad;
  const _BadgePeriodicidad(this.periodicidad);

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (periodicidad) {
      'MENSUAL'    => ('Mensual',    AppColors.blue,   AppColors.bgBlue),
      'TRIMESTRAL' => ('Trimestral', AppColors.teal,   AppColors.bgTeal),
      'SEMESTRAL'  => ('Semestral',  AppColors.orange, AppColors.bgOrange),
      'ANUAL'      => ('Anual',      AppColors.purple, AppColors.bgPurple),
      _            => (periodicidad, AppColors.blue,   AppColors.bgBlue),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _BadgeOverride extends StatelessWidget {
  const _BadgeOverride();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.bgOrange,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.orange.withOpacity(0.4)),
      ),
      child: Text(
        'Individual',
        style: TextStyle(
            fontSize: 10, color: AppColors.orange, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge(this.count);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: cs.onPrimaryContainer),
      ),
    );
  }
}

// ─── Formulario nueva cuota (bottom sheet) ────────────────────────────────────

enum _ModoAsignacion { porTipo, individual }

class _NuevaCuotaSheet extends StatefulWidget {
  final List<TipoPropiedadNodo> tiposFlat;
  final List<Map<String, dynamic>> propiedades;

  const _NuevaCuotaSheet({
    required this.tiposFlat,
    required this.propiedades,
  });

  @override
  State<_NuevaCuotaSheet> createState() => _NuevaCuotaSheetState();
}

class _NuevaCuotaSheetState extends State<_NuevaCuotaSheet> {
  final _form = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _desdeCtrl = TextEditingController();
  final _hastaCtrl = TextEditingController();

  _ModoAsignacion _modo = _ModoAsignacion.porTipo;
  String _periodicidad = 'MENSUAL';
  int? _tipoPropiedadId;
  int? _propiedadId;
  String? _propiedadLabel;
  DateTime _fechaVigencia = DateTime.now();
  DateTime? _fechaVigenciaHasta;
  bool _usarRango = false;
  bool _guardando = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _desdeCtrl.dispose();
    _hastaCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirPickerPropiedad() async {
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _PropiedadPickerDialog(
        propiedades: widget.propiedades,
      ),
    );
    if (selected != null) {
      setState(() {
        _propiedadId = selected['id'] as int;
        _propiedadLabel =
            (selected['pathTexto'] as String?) ??
            (selected['identificador'] as String?) ??
            'Propiedad #${selected['id']}';
      });
    }
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;

    if (_modo == _ModoAsignacion.porTipo && _tipoPropiedadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona un tipo de propiedad'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (_modo == _ModoAsignacion.individual && _propiedadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona una propiedad'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _guardando = true);
    try {
      String isoDate(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final body = <String, dynamic>{
        'monto': double.parse(_montoCtrl.text),
        'periodicidad': _periodicidad,
        'fechaVigenciaDesde': isoDate(_fechaVigencia),
        if (_fechaVigenciaHasta != null)
          'fechaVigenciaHasta': isoDate(_fechaVigenciaHasta!),
      };

      if (_modo == _ModoAsignacion.individual) {
        body['propiedadId'] = _propiedadId;
      } else {
        body['tipoPropiedadId'] = _tipoPropiedadId;
        if (_usarRango) {
          body['numeroDesde'] = int.parse(_desdeCtrl.text);
          body['numeroHasta'] = int.parse(_hastaCtrl.text);
        }
      }

      await CuotaService.crear(body);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Nueva configuracion de cuota',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // ── Selector de modo ──────────────────────────────────
              SegmentedButton<_ModoAsignacion>(
                segments: const [
                  ButtonSegment(
                    value: _ModoAsignacion.porTipo,
                    icon: Icon(Icons.category_outlined, size: 16),
                    label: Text('Por tipo'),
                  ),
                  ButtonSegment(
                    value: _ModoAsignacion.individual,
                    icon: Icon(Icons.home_outlined, size: 16),
                    label: Text('Por unidad'),
                  ),
                ],
                selected: {_modo},
                onSelectionChanged: (s) => setState(() {
                  _modo = s.first;
                  _tipoPropiedadId = null;
                  _propiedadId = null;
                  _propiedadLabel = null;
                  _usarRango = false;
                  _desdeCtrl.clear();
                  _hastaCtrl.clear();
                }),
              ),
              const SizedBox(height: 16),

              // ── Campos según modo ─────────────────────────────────
              if (_modo == _ModoAsignacion.porTipo) ...[
                DropdownButtonFormField<int>(
                  value: _tipoPropiedadId,
                  decoration: const InputDecoration(
                      labelText: 'Tipo de propiedad',
                      border: OutlineInputBorder()),
                  items: widget.tiposFlat
                      .where((t) => t.esFacturable)
                      .map((t) => DropdownMenuItem(
                          value: t.id, child: Text(t.nombre)))
                      .toList(),
                  onChanged: (v) => setState(() => _tipoPropiedadId = v),
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  value: _usarRango,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aplicar por rango de número'),
                  subtitle: const Text(
                    'Ej: unidades 101–120 pagan monto diferente',
                    style: TextStyle(fontSize: 11),
                  ),
                  onChanged: (v) => setState(() {
                    _usarRango = v;
                    if (!v) {
                      _desdeCtrl.clear();
                      _hastaCtrl.clear();
                    }
                  }),
                ),
                if (_usarRango) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _desdeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Desde',
                              border: OutlineInputBorder()),
                          validator: (v) {
                            if (!_usarRango) return null;
                            if (v == null || v.isEmpty) return 'Requerido';
                            if (int.tryParse(v) == null) return 'Entero';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _hastaCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Hasta',
                              border: OutlineInputBorder()),
                          validator: (v) {
                            if (!_usarRango) return null;
                            if (v == null || v.isEmpty) return 'Requerido';
                            final hasta = int.tryParse(v);
                            if (hasta == null) return 'Entero';
                            final desde = int.tryParse(_desdeCtrl.text) ?? 0;
                            if (hasta < desde) return '>= Desde';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ] else ...[
                // Modo individual: picker de propiedad
                GestureDetector(
                  onTap: _abrirPickerPropiedad,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Unidad / Propiedad',
                      border: const OutlineInputBorder(),
                      suffixIcon: _propiedadId != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() {
                                _propiedadId = null;
                                _propiedadLabel = null;
                              }),
                            )
                          : const Icon(Icons.search),
                    ),
                    child: Text(
                      _propiedadLabel ?? 'Buscar y seleccionar unidad...',
                      style: TextStyle(
                        color: _propiedadLabel != null
                            ? cs.onSurface
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bgOrange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Cuota Especial individual: tiene prioridad sobre las reglas por tipo y rango.',
                    style: TextStyle(fontSize: 11, color: AppColors.orange),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // ── Monto ─────────────────────────────────────────────
              const SizedBox(height: 4),
              TextFormField(
                controller: _montoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$',
                    border: OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (double.tryParse(v) == null) return 'Numero invalido';
                  if (double.parse(v) <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // ── Periodicidad ──────────────────────────────────────
              DropdownButtonFormField<String>(
                value: _periodicidad,
                decoration: const InputDecoration(
                    labelText: 'Periodicidad', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'MENSUAL', child: Text('Mensual')),
                  DropdownMenuItem(
                      value: 'TRIMESTRAL', child: Text('Trimestral')),
                  DropdownMenuItem(
                      value: 'SEMESTRAL', child: Text('Semestral')),
                  DropdownMenuItem(value: 'ANUAL', child: Text('Anual')),
                ],
                onChanged: (v) => setState(() => _periodicidad = v!),
              ),
              const SizedBox(height: 12),

              // ── Vigencia desde ────────────────────────────────────
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fechaVigencia,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _fechaVigencia = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'Vigencia desde',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today)),
                  child: Text(
                      '${_fechaVigencia.day.toString().padLeft(2, '0')}/${_fechaVigencia.month.toString().padLeft(2, '0')}/${_fechaVigencia.year}'),
                ),
              ),
              const SizedBox(height: 12),

              // ── Vigencia hasta (opcional) ──────────────────────────
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fechaVigenciaHasta ??
                        _fechaVigencia.add(const Duration(days: 30)),
                    firstDate: _fechaVigencia,
                    lastDate: DateTime(2100),
                  );
                  if (picked != null)
                    setState(() => _fechaVigenciaHasta = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Vigencia hasta (opcional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: _fechaVigenciaHasta != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            tooltip: 'Quitar fecha de fin',
                            onPressed: () =>
                                setState(() => _fechaVigenciaHasta = null),
                          )
                        : const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _fechaVigenciaHasta != null
                        ? '${_fechaVigenciaHasta!.day.toString().padLeft(2, '0')}/${_fechaVigenciaHasta!.month.toString().padLeft(2, '0')}/${_fechaVigenciaHasta!.year}'
                        : 'Vigente indefinidamente',
                    style: _fechaVigenciaHasta == null
                        ? TextStyle(color: cs.onSurfaceVariant)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: const Text('Guardar configuracion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dialog picker de propiedad ───────────────────────────────────────────────

class _PropiedadPickerDialog extends StatefulWidget {
  final List<Map<String, dynamic>> propiedades;
  const _PropiedadPickerDialog({required this.propiedades});

  @override
  State<_PropiedadPickerDialog> createState() => _PropiedadPickerDialogState();
}

class _PropiedadPickerDialogState extends State<_PropiedadPickerDialog> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtradas {
    if (_query.isEmpty) return widget.propiedades;
    final q = _query.toLowerCase();
    return widget.propiedades.where((p) {
      final path = ((p['pathTexto'] as String?) ?? '').toLowerCase();
      final id = ((p['identificador'] as String?) ?? '').toLowerCase();
      return path.contains(q) || id.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtradas = _filtradas;

    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Text(
                  'Seleccionar unidad',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o identificador...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: filtradas.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Sin resultados',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtradas.length,
                    itemBuilder: (_, i) {
                      final p = filtradas[i];
                      final label = (p['pathTexto'] as String?) ??
                          (p['identificador'] as String?) ??
                          'Propiedad #${p['id']}';
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.home_outlined, size: 18),
                        title: Text(label, style: const TextStyle(fontSize: 13)),
                        onTap: () => Navigator.pop(context, p),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmtMonto(double v) => v
    .toStringAsFixed(0)
    .replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

String _fmtFecha(String iso) {
  try {
    final d = DateTime.parse(iso);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return iso;
  }
}
