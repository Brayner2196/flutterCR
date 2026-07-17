import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'package:flutter_residential/shared/widgets/seccion_agrupadora.dart';
import 'package:flutter_residential/shared/widgets/seccion_agrupadora_item_accion.dart';
import 'package:flutter_residential/shared/widgets/seccion_agrupadora_item_switch.dart';
import 'package:flutter_residential/shared/widgets/seccion_agrupadora_item_slider.dart';
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
              : _cfg == null
                  ? const SizedBox.shrink()
                  : _buildContenido(context, _cfg!),
    );
  }

  Widget _buildContenido(BuildContext context, ConfigVigilanciaModel cfg) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ──
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.shield_rounded, size: 38, color: cs.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Vigilancia',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Parametriza el control de acceso del conjunto',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Visitas ──
          SeccionAgrupadora(
            titulo: 'Visitas',
            items: [
              SeccionAgrupadoraItemSlider(
                icono: Icons.qr_code_rounded,
                label: 'Vigencia del QR',
                valorTexto: '${cfg.expiracionVisitaHoras} h',
                valor: cfg.expiracionVisitaHoras.toDouble().clamp(1, 72),
                min: 1,
                max: 72,
                divisions: 71,
                etiquetaSlider: '${cfg.expiracionVisitaHoras} h',
                onChanged: (v) => setState(() =>
                    _cfg = cfg.copyWith(expiracionVisitaHoras: v.round())),
              ),
              SeccionAgrupadoraItemSwitch(
                icono: Icons.account_balance_wallet_rounded,
                label: 'Aprobar con cartera restringida',
                subtitle:
                    'Si la unidad está en mora, permite al vigilante aprobar igual',
                valor: cfg.permitirAprobarConCarteraRestringida,
                onChanged: (v) => setState(() => _cfg =
                    cfg.copyWith(permitirAprobarConCarteraRestringida: v)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Acceso peatonal ──
          SeccionAgrupadora(
            titulo: 'Acceso peatonal',
            items: [
              SeccionAgrupadoraItemSwitch(
                icono: Icons.badge_rounded,
                label: 'Exigir documento del visitante',
                valor: cfg.exigeDocumentoPeatonal,
                onChanged: (v) => setState(
                    () => _cfg = cfg.copyWith(exigeDocumentoPeatonal: v)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Paquetería ──
          SeccionAgrupadora(
            titulo: 'Paquetería',
            items: [
              SeccionAgrupadoraItemSwitch(
                icono: Icons.notifications_active_rounded,
                label: 'Notificar llegada al residente',
                valor: cfg.notificarLlegadaPaquete,
                onChanged: (v) => setState(
                    () => _cfg = cfg.copyWith(notificarLlegadaPaquete: v)),
              ),
              SeccionAgrupadoraItemSwitch(
                icono: Icons.photo_camera_rounded,
                label: 'Exigir foto del paquete',
                valor: cfg.exigeFotoPaquete,
                onChanged: (v) => setState(
                    () => _cfg = cfg.copyWith(exigeFotoPaquete: v)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_rounded),
            label: const Text('Guardar configuración'),
          ),
        ],
      ),
    );
  }
}
