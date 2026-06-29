import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import '../models/config_vigilancia_model.dart';
import '../services/admin_vigilancia_service.dart';
import 'bitacora_admin_screen.dart';

/// Parametrización del módulo de vigilancia + acceso a reportes (admin).
class AdminVigilanciaScreen extends StatefulWidget {
  const AdminVigilanciaScreen({super.key});

  @override
  State<AdminVigilanciaScreen> createState() => _AdminVigilanciaScreenState();
}

class _AdminVigilanciaScreenState extends State<AdminVigilanciaScreen> {
  ConfigVigilanciaModel? _cfg;
  bool _cargando = true;
  bool _guardando = false;
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
      final cfg = await AdminVigilanciaService.obtenerConfig();
      setState(() => _cfg = cfg);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    if (_cfg == null) return;
    setState(() => _guardando = true);
    try {
      final cfg = await AdminVigilanciaService.actualizarConfig(_cfg!);
      setState(() => _cfg = cfg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configuración guardada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cfg = _cfg;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vigilancia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.fact_check_outlined),
            tooltip: 'Reportes / bitácora',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BitacoraAdminScreen())),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : cfg == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        Text('Visitas',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: AppSpacing.sm),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Vigencia del QR'),
                          subtitle: Text('${cfg.expiracionVisitaHoras} horas'),
                          trailing: SizedBox(
                            width: 140,
                            child: Slider(
                              value: cfg.expiracionVisitaHoras.toDouble().clamp(1, 72),
                              min: 1,
                              max: 72,
                              divisions: 71,
                              label: '${cfg.expiracionVisitaHoras} h',
                              onChanged: (v) => setState(() =>
                                  _cfg = cfg.copyWith(expiracionVisitaHoras: v.round())),
                            ),
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Aprobar con cartera restringida'),
                          subtitle: const Text(
                              'Si la unidad está en mora, permite al vigilante aprobar igual'),
                          value: cfg.permitirAprobarConCarteraRestringida,
                          onChanged: (v) => setState(() => _cfg =
                              cfg.copyWith(permitirAprobarConCarteraRestringida: v)),
                        ),
                        const Divider(),
                        Text('Acceso peatonal',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Exigir documento del visitante'),
                          value: cfg.exigeDocumentoPeatonal,
                          onChanged: (v) => setState(() =>
                              _cfg = cfg.copyWith(exigeDocumentoPeatonal: v)),
                        ),
                        const Divider(),
                        Text('Paquetería',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Notificar llegada al residente'),
                          value: cfg.notificarLlegadaPaquete,
                          onChanged: (v) => setState(() =>
                              _cfg = cfg.copyWith(notificarLlegadaPaquete: v)),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Exigir foto del paquete'),
                          value: cfg.exigeFotoPaquete,
                          onChanged: (v) => setState(() =>
                              _cfg = cfg.copyWith(exigeFotoPaquete: v)),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          onPressed: _guardando ? null : _guardar,
                          icon: _guardando
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.save_rounded),
                          label: const Text('Guardar configuración'),
                        ),
                      ],
                    ),
    );
  }
}
