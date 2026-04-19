import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/tenant_response.dart';
import '../../../providers/tenant_provider.dart';

class TenantFormDialog extends StatefulWidget {
  final TenantResponse? tenant;

  const TenantFormDialog({super.key, this.tenant});

  @override
  State<TenantFormDialog> createState() => _TenantFormDialogState();
}

class _TenantFormDialogState extends State<TenantFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _schemaCtrl;
  late final TextEditingController _emailAdminCtrl;
  late final TextEditingController _passwordAdminCtrl;
  late final TextEditingController _direccionCtrl;

  bool _guardando = false;

  final List<_TipoNodoEditable> _tiposRaiz = [];

  bool get _esEdicion => widget.tenant != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tenant;
    _nombreCtrl = TextEditingController(text: t?.nombre ?? '');
    _codigoCtrl = TextEditingController(text: t?.codigo ?? '');
    _schemaCtrl = TextEditingController();
    _emailAdminCtrl = TextEditingController();
    _passwordAdminCtrl = TextEditingController();
    _direccionCtrl = TextEditingController(text: t?.direccion ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _codigoCtrl.dispose();
    _schemaCtrl.dispose();
    _emailAdminCtrl.dispose();
    _passwordAdminCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _buildTiposJson(List<_TipoNodoEditable> nodos) {
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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final provider = context.read<TenantProvider>();

    try {
      if (_esEdicion) {
        await provider.actualizar(widget.tenant!.id, {
          'nombre': _nombreCtrl.text.trim(),
          'codigo': _codigoCtrl.text.trim(),
          'direccion': _direccionCtrl.text.trim(),
          'activo': widget.tenant!.activo,
        });
      } else {
        final tiposJson = _buildTiposJson(_tiposRaiz);
        await provider.crear({
          'schemaName': _schemaCtrl.text.trim(),
          'nombre': _nombreCtrl.text.trim(),
          'codigo': _codigoCtrl.text.trim(),
          'emailAdmin': _emailAdminCtrl.text.trim(),
          'passwordAdmin': _passwordAdminCtrl.text,
          if (_direccionCtrl.text.trim().isNotEmpty)
            'direccion': _direccionCtrl.text.trim(),
          if (tiposJson.isNotEmpty) 'tiposPropiedad': tiposJson,
        });
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_esEdicion ? 'Editar Tenant' : 'Nuevo Tenant'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del conjunto *',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _codigoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Código *',
                    prefixIcon: Icon(Icons.tag),
                    hintText: 'EJ: EL-PRADO-01',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                ),
                if (!_esEdicion) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _schemaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Schema (identificador DB) *',
                      prefixIcon: Icon(Icons.storage_outlined),
                      hintText: 'ej: el_prado_01',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Campo requerido';
                      if (!RegExp(r'^[a-z0-9_]+$').hasMatch(v.trim())) {
                        return 'Solo minúsculas, números y guiones bajos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailAdminCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email del administrador *',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Campo requerido';
                      if (!v.contains('@')) return 'Email inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordAdminCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña del administrador *',
                      prefixIcon: Icon(Icons.lock_outlined),
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tipos de Propiedad del Conjunto',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'Agregar tipo raíz',
                        onPressed: () => setState(() =>
                            _tiposRaiz.add(_TipoNodoEditable())),
                      ),
                    ],
                  ),
                  if (_tiposRaiz.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Ej: Torre → Apto, Parqueadero',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  for (int i = 0; i < _tiposRaiz.length; i++)
                    _TipoNodoWidget(
                      nodo: _tiposRaiz[i],
                      indent: 0,
                      onEliminar: () => setState(() => _tiposRaiz.removeAt(i)),
                      onCambio: () => setState(() {}),
                    ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _direccionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_esEdicion ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}

class _TipoNodoEditable {
  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final List<_TipoNodoEditable> hijos = [];
}

class _TipoNodoWidget extends StatelessWidget {
  final _TipoNodoEditable nodo;
  final int indent;
  final VoidCallback onEliminar;
  final VoidCallback onCambio;

  const _TipoNodoWidget({
    required this.nodo,
    required this.indent,
    required this.onEliminar,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(left: indent * 16.0, top: 8),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (indent > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.subdirectory_arrow_right,
                              size: 16, color: theme.colorScheme.outline),
                        ),
                      Expanded(
                        child: TextField(
                          controller: nodo.nombreCtrl,
                          decoration: InputDecoration(
                            labelText: indent == 0 ? 'Tipo raíz' : 'Subtipo',
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        tooltip: 'Agregar hijo',
                        onPressed: () {
                          nodo.hijos.add(_TipoNodoEditable());
                          onCambio();
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 18, color: theme.colorScheme.error),
                        onPressed: onEliminar,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nodo.descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (hint en el registro)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        for (int j = 0; j < nodo.hijos.length; j++)
          _TipoNodoWidget(
            nodo: nodo.hijos[j],
            indent: indent + 1,
            onEliminar: () {
              nodo.hijos.removeAt(j);
              onCambio();
            },
            onCambio: onCambio,
          ),
      ],
    );
  }
}
