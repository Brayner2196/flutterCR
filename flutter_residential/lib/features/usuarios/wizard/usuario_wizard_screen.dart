import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../providers/usuario_provider.dart';
import '../../../shared/theme/app_theme.dart';
import 'steps/usuario_wizard_step_rol.dart';
import 'steps/usuario_wizard_step_datos.dart';
import 'steps/usuario_wizard_step_propiedad.dart';
import 'steps/usuario_wizard_step_resumen.dart';

// ─── Metadatos de cada paso ────────────────────────────────────────────────────

class _PasoMeta {
  final String titulo;
  final String subtitulo;
  final IconData icono;

  const _PasoMeta({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
  });
}

const _pasosMeta = [
  _PasoMeta(
    titulo: 'Tipo de usuario',
    subtitulo: 'Selecciona el rol que tendrá',
    icono: Icons.badge_outlined,
  ),
  _PasoMeta(
    titulo: 'Datos personales',
    subtitulo: 'Información de acceso y contacto',
    icono: Icons.person_outline,
  ),
  _PasoMeta(
    titulo: 'Unidad',
    subtitulo: 'Propiedad asociada al usuario',
    icono: Icons.home_work_outlined,
  ),
  _PasoMeta(
    titulo: 'Resumen',
    subtitulo: 'Confirma los datos antes de crear',
    icono: Icons.check_circle_outline,
  ),
];

// ─── Wizard principal ─────────────────────────────────────────────────────────

class UsuarioWizardScreen extends StatefulWidget {
  const UsuarioWizardScreen({super.key});

  @override
  State<UsuarioWizardScreen> createState() => _UsuarioWizardScreenState();
}

class _UsuarioWizardScreenState extends State<UsuarioWizardScreen> {
  final _pageCtrl = PageController();

  // ── Índice de página (0-3) ─────────────────────────────────────────────────
  int _pasoActual = 0;
  bool _creando = false;

  // ── Estado del wizard ──────────────────────────────────────────────────────
  String _rol = '';
  bool _verPassword = false;

  // Path de propiedad capturado al salir del paso 2. Se guarda aquí porque el
  // PageView desmonta el State del step al perder foco y _keyPropiedad.currentState
  // queda null al momento de crear (el usuario terminaba sin propiedad asignada).
  List<Map<String, dynamic>> _propiedadPath = [];
  List<String> _propiedadPathLabels = [];

  final _keyDatos = GlobalKey<FormState>();
  final _keyPropiedad = GlobalKey<UsuarioWizardStepPropiedadState>();

  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  // ── Derived ────────────────────────────────────────────────────────────────
  bool get _requierePropiedad =>
      _rol == 'PROPIETARIO' || _rol == 'INQUILINO';

  /// Total de pasos lógicos que ve el usuario.
  int get _totalPasosLogicos => _requierePropiedad ? 4 : 3;

  /// Paso lógico (1-based) para mostrar en el header.
  int get _pasoLogico {
    if (_pasoActual <= 1) return _pasoActual + 1;
    if (_pasoActual == 2) return 3; // propiedad → siempre lógico 3
    // _pasoActual == 3 (resumen)
    return _requierePropiedad ? 4 : 3;
  }

  _PasoMeta get _metaActual {
    if (_pasoActual == 3 && !_requierePropiedad) {
      return _pasosMeta[3]; // resumen
    }
    return _pasosMeta[_pasoActual];
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  // ── Navegación ─────────────────────────────────────────────────────────────

  bool _validarPasoActual() {
    switch (_pasoActual) {
      case 0:
        if (_rol.isEmpty) {
          _mostrarError('Selecciona un rol para continuar.');
          return false;
        }
        return true;
      case 1:
        return _keyDatos.currentState?.validate() ?? false;
      case 2:
        if (!(_keyPropiedad.currentState?.esValido ?? false)) {
          _mostrarError('Completa al menos el primer nivel de la unidad.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  /// Captura el path del step de propiedad mientras su State sigue montado.
  void _capturarPropiedad() {
    final st = _keyPropiedad.currentState;
    _propiedadPath = st?.buildPath() ?? [];
    _propiedadPathLabels = st?.buildPathLabels() ?? [];
  }

  void _siguiente() {
    if (!_validarPasoActual()) return;

    // Al abandonar el paso de propiedad guardamos el path antes de que el
    // PageView pueda desmontar su State (si no, la asignación se pierde).
    if (_pasoActual == 2) _capturarPropiedad();

    int destino;
    if (_pasoActual == 1 && !_requierePropiedad) {
      destino = 3; // saltar paso de propiedad
    } else {
      destino = _pasoActual + 1;
    }

    _pageCtrl.animateToPage(
      destino,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _pasoActual = destino);
  }

  void _anterior() {
    int destino;
    if (_pasoActual == 3 && !_requierePropiedad) {
      destino = 1; // volver saltando paso de propiedad
    } else {
      destino = _pasoActual - 1;
    }

    _pageCtrl.animateToPage(
      destino,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _pasoActual = destino);
  }

  // ── Creación ───────────────────────────────────────────────────────────────

  Future<void> _crear() async {
    setState(() => _creando = true);
    try {
      // Fallback: si por alguna razón no se capturó al navegar, reintenta leerlo.
      if (_requierePropiedad && _propiedadPath.isEmpty) _capturarPropiedad();

      final propiedadPath =
          _requierePropiedad ? _propiedadPath : <Map<String, dynamic>>[];

      await context.read<UsuarioProvider>().crear({
        'nombre': _nombreCtrl.text.trim(),
        'email': _emailCtrl.text.trim().toLowerCase(),
        'password': _passwordCtrl.text,
        'rol': _rol,
        if (_telefonoCtrl.text.trim().isNotEmpty)
          'telefono': _telefonoCtrl.text.trim(),
        if (propiedadPath.isNotEmpty) 'propiedadPath': propiedadPath,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          '${_nombreCtrl.text.trim()} fue creado correctamente.',
        ),backgroundColor: AppColors.ok,),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: const Text('Error al crear usuario'),
        description:
            Text(e.toString().replaceFirst('Exception: ', '')),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 5),
        showProgressBar: true,
        closeOnClick: true,
      );
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _confirmarSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content:
            const Text('Se perderán los datos ingresados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if ((salir ?? false) && mounted) Navigator.of(context).pop();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  List<String> get _pathLabelsActuales {
    if (!_requierePropiedad) return [];
    // Prioriza las capturadas; si aún no hay (usuario en el paso), lee en vivo.
    if (_propiedadPathLabels.isNotEmpty) return _propiedadPathLabels;
    return _keyPropiedad.currentState?.buildPathLabels() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final esResumen = _pasoActual == 3;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmarSalida();
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmarSalida,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nuevo usuario',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Paso $_pasoLogico de $_totalPasosLogicos',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // ── Header de progreso ─────────────────────────────────────
            _WizardProgressHeader(
              pasoLogico: _pasoLogico,
              totalPasosLogicos: _totalPasosLogicos,
              meta: _metaActual,
            ),

            // ── Páginas ────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Página 0: rol
                  UsuarioWizardStepRol(
                    rolSeleccionado: _rol.isEmpty ? null : _rol,
                    onRolCambiado: (r) => setState(() => _rol = r),
                  ),
                  // Página 1: datos personales
                  UsuarioWizardStepDatos(
                    formKey: _keyDatos,
                    nombreCtrl: _nombreCtrl,
                    emailCtrl: _emailCtrl,
                    passwordCtrl: _passwordCtrl,
                    telefonoCtrl: _telefonoCtrl,
                    verPassword: _verPassword,
                    onToggleVerPassword: () =>
                        setState(() => _verPassword = !_verPassword),
                  ),
                  // Página 2: propiedad (solo visitada si requiere propiedad)
                  UsuarioWizardStepPropiedad(
                    key: _keyPropiedad,
                    rol: _rol,
                  ),
                  // Página 3: resumen
                  UsuarioWizardStepResumen(
                    rol: _rol,
                    nombre: _nombreCtrl.text,
                    email: _emailCtrl.text,
                    telefono: _telefonoCtrl.text.trim().isEmpty
                        ? null
                        : _telefonoCtrl.text.trim(),
                    pathLabels: _pathLabelsActuales,
                  ),
                ],
              ),
            ),

            // ── Barra de navegación inferior ───────────────────────────
            _WizardNavBar(
              pasoActual: _pasoActual,
              esResumen: esResumen,
              creando: _creando,
              onAnterior: _pasoActual > 0 ? _anterior : null,
              onSiguiente: esResumen ? null : _siguiente,
              onCrear: esResumen ? _crear : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header de progreso ────────────────────────────────────────────────────────

class _WizardProgressHeader extends StatelessWidget {
  final int pasoLogico;
  final int totalPasosLogicos;
  final _PasoMeta meta;

  const _WizardProgressHeader({
    required this.pasoLogico,
    required this.totalPasosLogicos,
    required this.meta,
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
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pasoLogico / totalPasosLogicos,
              minHeight: 5,
              backgroundColor: cs.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
          const SizedBox(height: 14),
          // Info del paso + dots
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(meta.icono, color: cs.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.titulo,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      meta.subtitulo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Dots indicadores
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(totalPasosLogicos, (i) {
                  final activo = i == pasoLogico - 1;
                  final completado = i < pasoLogico - 1;
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

// ─── Barra de navegación inferior ────────────────────────────────────────────

class _WizardNavBar extends StatelessWidget {
  final int pasoActual;
  final bool esResumen;
  final bool creando;
  final VoidCallback? onAnterior;
  final VoidCallback? onSiguiente;
  final VoidCallback? onCrear;

  const _WizardNavBar({
    required this.pasoActual,
    required this.esResumen,
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
          // Anterior
          if (pasoActual > 0)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: creando ? null : onAnterior,
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
              label: const Text('Anterior'),
            )
          else
            const SizedBox.shrink(),

          const Spacer(),

          // Siguiente / Crear
          if (!esResumen)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: creando ? null : onSiguiente,
              icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14),
              iconAlignment: IconAlignment.end,
              label: const Text('Siguiente'),
            )
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ok,
                minimumSize: const Size(0, 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24),
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
                  : const Icon(Icons.person_add_outlined, size: 18),
              label:
                  Text(creando ? 'Creando...' : 'Crear usuario'),
            ),
        ],
      ),
    );
  }
}
