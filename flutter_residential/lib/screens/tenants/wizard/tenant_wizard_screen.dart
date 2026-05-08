import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/tenant_provider.dart';
import '../../../shared/theme/app_theme.dart';
import 'steps/tenant_wizard_step_basico.dart';
import 'steps/tenant_wizard_step_schema.dart';
import 'steps/tenant_wizard_step_admin.dart';
import 'steps/tenant_wizard_step_propiedades.dart';
import 'steps/tenant_wizard_step_resumen.dart';

/// Pantallas del wizard
class _WizardStep {
  final String titulo;
  final String subtitulo;
  final IconData icono;

  const _WizardStep({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
  });
}

const _pasos = [
  _WizardStep(
    titulo: 'Información básica',
    subtitulo: 'Nombre y ubicación del conjunto',
    icono: Icons.apartment_outlined,
  ),
  _WizardStep(
    titulo: 'Base de datos',
    subtitulo: 'Identificador único del esquema',
    icono: Icons.storage_outlined,
  ),
  _WizardStep(
    titulo: 'Administrador',
    subtitulo: 'Credenciales del admin del conjunto',
    icono: Icons.manage_accounts_outlined,
  ),
  _WizardStep(
    titulo: 'Tipos de propiedad',
    subtitulo: 'Estructura del conjunto (opcional)',
    icono: Icons.home_work_outlined,
  ),
  _WizardStep(
    titulo: 'Resumen',
    subtitulo: 'Confirma los datos antes de crear',
    icono: Icons.check_circle_outline,
  ),
];

class TenantWizardScreen extends StatefulWidget {
  const TenantWizardScreen({super.key});

  @override
  State<TenantWizardScreen> createState() => _TenantWizardScreenState();
}

class _TenantWizardScreenState extends State<TenantWizardScreen> {
  final _pageCtrl = PageController();
  int _pasoActual = 0;
  bool _creando = false;

  // ── Claves de formulario por paso ───────────────────────────────────────
  final _keyBasico = GlobalKey<FormState>();
  final _keySchema = GlobalKey<FormState>();
  final _keyAdmin = GlobalKey<FormState>();

  // ── Datos recopilados entre pasos ───────────────────────────────────────
  final _datos = <String, dynamic>{
    'nombre': '',
    'codigo': '',
    'direccion': '',
    'schemaName': '',
    'emailAdmin': '',
    'passwordAdmin': '',
    'tiposPropiedad': <TipoNodoEditable>[],
  };

  // ── Controladores de texto compartidos ─────────────────────────────────
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _schemaCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl    = TextEditingController();
    _codigoCtrl    = TextEditingController();
    _direccionCtrl = TextEditingController();
    _schemaCtrl    = TextEditingController();
    _emailCtrl     = TextEditingController();
    _passwordCtrl  = TextEditingController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nombreCtrl.dispose();
    _codigoCtrl.dispose();
    _direccionCtrl.dispose();
    _schemaCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Validar el paso actual antes de avanzar ─────────────────────────────
  bool _validarPasoActual() {
    switch (_pasoActual) {
      case 0:
        return _keyBasico.currentState?.validate() ?? false;
      case 1:
        return _keySchema.currentState?.validate() ?? false;
      case 2:
        return _keyAdmin.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  void _siguiente() {
    if (!_validarPasoActual()) return;
    if (_pasoActual < _pasos.length - 1) {
      setState(() => _pasoActual++);
      _pageCtrl.animateToPage(
        _pasoActual,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _anterior() {
    if (_pasoActual > 0) {
      setState(() => _pasoActual--);
      _pageCtrl.animateToPage(
        _pasoActual,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  List<Map<String, dynamic>> _buildTiposJson(List<TipoNodoEditable> nodos) {
    return nodos
        .where((n) => n.nombreCtrl.text.trim().isNotEmpty)
        .map((n) => {
              'nombre': n.nombreCtrl.text.trim(),
              if (n.descCtrl.text.trim().isNotEmpty)
                'descripcion': n.descCtrl.text.trim(),
              'hijos': _buildTiposJson(n.hijos),
            })
        .toList();
  }

  Future<void> _crear() async {
    setState(() => _creando = true);
    final tiposJson =
        _buildTiposJson(_datos['tiposPropiedad'] as List<TipoNodoEditable>);

    try {
      await context.read<TenantProvider>().crear({
        'schemaName': _schemaCtrl.text.trim(),
        'nombre': _nombreCtrl.text.trim(),
        'codigo': _codigoCtrl.text.trim(),
        'emailAdmin': _emailCtrl.text.trim(),
        'passwordAdmin': _passwordCtrl.text,
        if (_direccionCtrl.text.trim().isNotEmpty)
          'direccion': _direccionCtrl.text.trim(),
        if (tiposJson.isNotEmpty) 'tiposPropiedad': tiposJson,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 10),
                Text('Tenant "${_nombreCtrl.text.trim()}" creado exitosamente'),
              ],
            ),
            backgroundColor: AppColors.ok,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final esUltimoPaso = _pasoActual == _pasos.length - 1;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmarSalida(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nuevo Tenant',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Paso ${_pasoActual + 1} de ${_pasos.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Progress bar + step info ────────────────────────────────────
          _WizardProgressHeader(
            pasoActual: _pasoActual,
            totalPasos: _pasos.length,
            paso: _pasos[_pasoActual],
          ),

          // ── Contenido de cada paso ──────────────────────────────────────
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                TenantWizardStepBasico(
                  formKey: _keyBasico,
                  nombreCtrl: _nombreCtrl,
                  codigoCtrl: _codigoCtrl,
                  direccionCtrl: _direccionCtrl,
                ),
                TenantWizardStepSchema(
                  formKey: _keySchema,
                  schemaCtrl: _schemaCtrl,
                  nombreConjunto: _nombreCtrl.text,
                ),
                TenantWizardStepAdmin(
                  formKey: _keyAdmin,
                  emailCtrl: _emailCtrl,
                  passwordCtrl: _passwordCtrl,
                ),
                TenantWizardStepPropiedades(
                  tiposRaiz: _datos['tiposPropiedad'] as List<TipoNodoEditable>,
                  onCambio: () => setState(() {}),
                ),
                TenantWizardStepResumen(
                  nombreCtrl: _nombreCtrl,
                  codigoCtrl: _codigoCtrl,
                  direccionCtrl: _direccionCtrl,
                  schemaCtrl: _schemaCtrl,
                  emailCtrl: _emailCtrl,
                  tiposPropiedad:
                      _datos['tiposPropiedad'] as List<TipoNodoEditable>,
                ),
              ],
            ),
          ),

          // ── Botones de navegación ───────────────────────────────────────
          _WizardNavBar(
            pasoActual: _pasoActual,
            esUltimoPaso: esUltimoPaso,
            creando: _creando,
            onAnterior: _pasoActual > 0 ? _anterior : null,
            onSiguiente: esUltimoPaso ? null : _siguiente,
            onCrear: esUltimoPaso ? _crear : null,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarSalida(BuildContext context) async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir del formulario?'),
        content: const Text('Se perderán los datos ingresados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (salir == true && context.mounted) Navigator.pop(context);
  }
}

// ─── Progress header ─────────────────────────────────────────────────────────

class _WizardProgressHeader extends StatelessWidget {
  final int pasoActual;
  final int totalPasos;
  final _WizardStep paso;

  const _WizardProgressHeader({
    required this.pasoActual,
    required this.totalPasos,
    required this.paso,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Barra de progreso animada ───────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pasoActual + 1) / totalPasos,
              minHeight: 5,
              backgroundColor: cs.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
          const SizedBox(height: 14),

          // ── Info del paso actual ────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(paso.icono, color: cs.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paso.titulo,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      paso.subtitulo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Indicadores de paso ─────────────────────────────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(totalPasos, (i) {
                  final activo = i == pasoActual;
                  final completado = i < pasoActual;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(left: 4),
                    width: activo ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: completado
                          ? AppColors.ok
                          : activo
                              ? cs.primary
                              : cs.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Nav bar inferior ─────────────────────────────────────────────────────────

class _WizardNavBar extends StatelessWidget {
  final int pasoActual;
  final bool esUltimoPaso;
  final bool creando;
  final VoidCallback? onAnterior;
  final VoidCallback? onSiguiente;
  final VoidCallback? onCrear;

  const _WizardNavBar({
    required this.pasoActual,
    required this.esUltimoPaso,
    required this.creando,
    this.onAnterior,
    this.onSiguiente,
    this.onCrear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          // ── Anterior ────────────────────────────────────────────────────
          if (pasoActual > 0)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: creando ? null : onAnterior,
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
              label: const Text('Anterior'),
            )
          else
            const SizedBox.shrink(),

          const Spacer(),

          // ── Siguiente / Crear ────────────────────────────────────────────
          if (!esUltimoPaso)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: creando ? null : onSiguiente,
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              iconAlignment: IconAlignment.end,
              label: const Text('Siguiente'),
            )
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ok,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: creando ? null : onCrear,
              icon: creando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(creando ? 'Creando...' : 'Crear Tenant'),
            ),
        ],
      ),
    );
  }
}
