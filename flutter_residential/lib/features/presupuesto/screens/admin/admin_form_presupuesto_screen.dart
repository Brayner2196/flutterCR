import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/presupuesto_model.dart';
import '../../providers/presupuesto_provider.dart';

/// Formulario para crear o editar un presupuesto anual con sus categorías.
class AdminFormPresupuestoScreen extends StatefulWidget {
  /// Si se pasa, es edición; si no, es creación.
  final PresupuestoModel? presupuesto;

  const AdminFormPresupuestoScreen({super.key, this.presupuesto});

  @override
  State<AdminFormPresupuestoScreen> createState() =>
      _AdminFormPresupuestoScreenState();
}

class _AdminFormPresupuestoScreenState
    extends State<AdminFormPresupuestoScreen> {
  final _anioCtrl = TextEditingController();
  final _tituloCtrl = TextEditingController();
  bool _activo = false;
  bool _guardando = false;

  /// Lista editable de categorías: {nombre, descripcion, montoAsignado, color, icono}
  final List<Map<String, dynamic>> _categorias = [];

  bool get _esEdicion => widget.presupuesto != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      final p = widget.presupuesto!;
      _anioCtrl.text = p.anio.toString();
      _tituloCtrl.text = p.titulo ?? '';
      _activo = p.activo;
      _categorias.addAll(p.categorias.map((c) => {
            'nombre': c.nombre,
            'descripcion': c.descripcion ?? '',
            'montoAsignado': c.montoAsignado.toStringAsFixed(0),
            'color': c.color ?? '',
            'icono': c.icono ?? '',
          }));
    } else {
      _anioCtrl.text = DateTime.now().year.toString();
      _categorias.add(_categoriaVacia());
    }
  }

  @override
  void dispose() {
    _anioCtrl.dispose();
    _tituloCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _categoriaVacia() => {
        'nombre': '',
        'descripcion': '',
        'montoAsignado': '',
        'color': '',
        'icono': '',
      };

  double get _totalPresupuestado => _categorias.fold(0.0, (s, c) {
        return s + (double.tryParse(c['montoAsignado'] as String? ?? '') ?? 0);
      });

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  Future<void> _guardar() async {
    // Validaciones básicas
    final anio = int.tryParse(_anioCtrl.text.trim());
    if (anio == null || anio < 2000 || anio > 2100) {
      _toast(ToastificationType.warning, 'Ingresa un año válido (2000-2100)');
      return;
    }
    if (_categorias.isEmpty) {
      _toast(ToastificationType.warning, 'Agrega al menos una categoría');
      return;
    }
    for (final c in _categorias) {
      if ((c['nombre'] as String).trim().isEmpty) {
        _toast(ToastificationType.warning, 'Todas las categorías deben tener nombre');
        return;
      }
      if ((double.tryParse(c['montoAsignado'] as String? ?? '') ?? 0) <= 0) {
        _toast(ToastificationType.warning,
            'El monto de cada categoría debe ser mayor a 0');
        return;
      }
    }

    setState(() => _guardando = true);
    try {
      final body = {
        'anio': anio,
        'titulo': _tituloCtrl.text.trim().isEmpty ? null : _tituloCtrl.text.trim(),
        'activo': _activo,
        'categorias': _categorias
            .map((c) => {
                  'nombre': (c['nombre'] as String).trim(),
                  'descripcion': (c['descripcion'] as String).trim().isEmpty
                      ? null
                      : (c['descripcion'] as String).trim(),
                  'montoAsignado':
                      double.parse(c['montoAsignado'] as String),
                  'color': (c['color'] as String).trim().isEmpty
                      ? null
                      : (c['color'] as String).trim(),
                  'icono': (c['icono'] as String).trim().isEmpty
                      ? null
                      : (c['icono'] as String).trim(),
                })
            .toList(),
      };

      final provider = context.read<PresupuestoProvider>();
      if (_esEdicion) {
        await provider.actualizar(widget.presupuesto!.id, body);
      } else {
        await provider.crear(body);
      }

      if (!mounted) return;
      _toast(ToastificationType.success,
          _esEdicion ? 'Presupuesto actualizado' : 'Presupuesto creado');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _toast(ToastificationType.error,
          e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _toast(ToastificationType tipo, String msg) {
    toastification.show(
      context: context,
      type: tipo,
      title: Text(msg),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar presupuesto' : 'Nuevo presupuesto'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Datos generales ───────────────────────────────
          _SectionLabel('Datos generales'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _anioCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Año *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _tituloCtrl,
                  decoration: InputDecoration(
                    labelText: 'Título (opcional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _activo,
            onChanged: (v) => setState(() => _activo = v),
            title: const Text('Marcar como presupuesto activo',
                style: TextStyle(fontSize: 14)),
            subtitle: const Text(
                'El presupuesto activo es el que los residentes ven',
                style: TextStyle(fontSize: 12)),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),

          // ── Categorías ────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionLabel('Categorías de gasto'),
              TextButton.icon(
                onPressed: () => setState(() => _categorias.add(_categoriaVacia())),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_categorias.length, (i) => _CategoriaForm(
                index: i,
                data: _categorias[i],
                onChanged: (key, val) =>
                    setState(() => _categorias[i][key] = val),
                onEliminar: _categorias.length > 1
                    ? () => setState(() => _categorias.removeAt(i))
                    : null,
              )),
          const SizedBox(height: 16),

          // ── Total ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total presupuestado',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(_fmt(_totalPresupuestado),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.blue)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Botón guardar ─────────────────────────────────
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined),
            style: FilledButton.styleFrom(
                minimumSize: const Size(0, 50)),
            label: Text(_guardando
                ? 'Guardando...'
                : (_esEdicion ? 'Guardar cambios' : 'Crear presupuesto')),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Formulario de una categoría ───────────────────────────────────────────────

class _CategoriaForm extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;
  final void Function(String key, String val) onChanged;
  final VoidCallback? onEliminar;

  const _CategoriaForm({
    required this.index,
    required this.data,
    required this.onChanged,
    this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Categoría ${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              if (onEliminar != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.danger,
                  onPressed: onEliminar,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _Field(
            label: 'Nombre *',
            initial: data['nombre'] as String,
            onChanged: (v) => onChanged('nombre', v),
          ),
          const SizedBox(height: 8),
          _Field(
            label: 'Monto asignado *',
            initial: data['montoAsignado'] as String,
            keyboardType: TextInputType.number,
            onChanged: (v) => onChanged('montoAsignado', v),
          ),
          const SizedBox(height: 8),
          _Field(
            label: 'Descripción (opcional)',
            initial: data['descripcion'] as String,
            onChanged: (v) => onChanged('descripcion', v),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String initial;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;

  const _Field({
    required this.label,
    required this.initial,
    this.keyboardType = TextInputType.text,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        initialValue: initial,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.5,
      ));
}
