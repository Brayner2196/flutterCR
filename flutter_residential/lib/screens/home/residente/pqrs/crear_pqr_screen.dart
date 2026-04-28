import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../providers/pqr_provider.dart';

class CrearPqrScreen extends StatefulWidget {
  const CrearPqrScreen({super.key});

  @override
  State<CrearPqrScreen> createState() => _CrearPqrScreenState();
}

class _CrearPqrScreenState extends State<CrearPqrScreen> {
  final _formKey = GlobalKey<FormState>();
  final _asuntoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  String? _tipoSeleccionado;
  bool _enviando = false;

  static const _tipos = [
    _TipoOption('PETICION', 'Peticion', Icons.mail_outline,
        'Solicita informacion o un servicio'),
    _TipoOption('QUEJA', 'Queja', Icons.sentiment_dissatisfied_outlined,
        'Expresa inconformidad con un servicio'),
    _TipoOption('RECLAMO', 'Reclamo', Icons.report_problem_outlined,
        'Exige un derecho o correccion'),
    _TipoOption('SUGERENCIA', 'Sugerencia', Icons.lightbulb_outline,
        'Propone una mejora'),
  ];

  @override
  void dispose() {
    _asuntoCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipoSeleccionado == null) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text('Selecciona el tipo de solicitud'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      await context.read<PqrProvider>().crearPqr(
            tipo: _tipoSeleccionado!,
            asunto: _asuntoCtrl.text.trim(),
            descripcion: _descripcionCtrl.text.trim(),
          );
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Solicitud enviada exitosamente'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(e.toString().replaceFirst('Exception: ', '')),
        autoCloseDuration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Solicitud')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Tipo ────────────────────────────
              Text(
                'Tipo de solicitud',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.6,
                children: _tipos
                    .map((t) => _TipoCard(
                          option: t,
                          seleccionado: _tipoSeleccionado == t.valor,
                          onTap: () =>
                              setState(() => _tipoSeleccionado = t.valor),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),

              // ─── Asunto ──────────────────────────
              Text(
                'Asunto',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _asuntoCtrl,
                decoration: const InputDecoration(
                  hintText: 'Resumen breve de tu solicitud',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El asunto es obligatorio'
                    : null,
              ),
              const SizedBox(height: 20),

              // ─── Descripcion ─────────────────────
              Text(
                'Descripcion',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcionCtrl,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Describe en detalle tu solicitud...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'La descripcion es obligatoria'
                    : null,
              ),
              const SizedBox(height: 32),

              // ─── Boton enviar ────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _enviando ? null : _enviar,
                  icon: _enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_enviando ? 'Enviando...' : 'Enviar Solicitud'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipoOption {
  final String valor;
  final String label;
  final IconData icono;
  final String descripcion;

  const _TipoOption(this.valor, this.label, this.icono, this.descripcion);
}

class _TipoCard extends StatelessWidget {
  final _TipoOption option;
  final bool seleccionado;
  final VoidCallback onTap;

  const _TipoCard({
    required this.option,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: seleccionado
              ? cs.primary.withValues(alpha: 0.1)
              : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? cs.primary : cs.outline,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              option.icono,
              size: 24,
              color: seleccionado ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              option.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: seleccionado ? cs.primary : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
