import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/propiedades/models/tipo_propiedad_nodo.dart';
import '../../../../features/propiedades/providers/propiedad_provider.dart';

class UsuarioWizardStepPropiedad extends StatefulWidget {
  final String rol;

  const UsuarioWizardStepPropiedad({
    super.key,
    required this.rol,
  });

  @override
  UsuarioWizardStepPropiedadState createState() =>
      UsuarioWizardStepPropiedadState();
}

class UsuarioWizardStepPropiedadState
    extends State<UsuarioWizardStepPropiedad> {
  TipoPropiedadNodo? _tipoRaizSeleccionado;
  final List<TipoPropiedadNodo> _nivelesActivos = [];
  final List<TextEditingController> _pathCtrlList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropiedadProvider>().cargarTiposAdmin();
    });
  }

  @override
  void dispose() {
    for (final c in _pathCtrlList) {
      c.dispose();
    }
    super.dispose();
  }

  // ── API pública para el wizard ─────────────────────────────────────────────

  bool get esValido {
    if (_tipoRaizSeleccionado == null) return false;
    return _pathCtrlList.isNotEmpty &&
        _pathCtrlList[0].text.trim().isNotEmpty;
  }

  /// Retorna el path como lista de {tipoId, valor} para enviar al backend.
  List<Map<String, dynamic>> buildPath() {
    final path = <Map<String, dynamic>>[];
    for (int i = 0; i < _nivelesActivos.length; i++) {
      if (i >= _pathCtrlList.length) break;
      final valor = _pathCtrlList[i].text.trim();
      if (valor.isEmpty) break;
      path.add({'tipoId': _nivelesActivos[i].id, 'valor': valor});
    }
    return path;
  }

  /// Retorna etiquetas legibles para el resumen. Ej: ['Torre: A', 'Piso: 3']
  List<String> buildPathLabels() {
    final parts = <String>[];
    for (int i = 0; i < _nivelesActivos.length; i++) {
      if (i >= _pathCtrlList.length) break;
      final valor = _pathCtrlList[i].text.trim();
      if (valor.isEmpty) break;
      parts.add('${_nivelesActivos[i].nombre}: $valor');
    }
    return parts;
  }

  // ── Lógica interna ─────────────────────────────────────────────────────────

  void _onTipoRaizChanged(TipoPropiedadNodo? tipo) {
    for (final c in _pathCtrlList) {
      c.dispose();
    }
    _pathCtrlList.clear();
    _nivelesActivos.clear();

    if (tipo != null) {
      _nivelesActivos.add(tipo);
      _pathCtrlList.add(TextEditingController());
    }
    setState(() => _tipoRaizSeleccionado = tipo);
  }

  void _onNivelLlenado(int index) {
    final texto = _pathCtrlList[index].text.trim();
    if (texto.isEmpty) return;

    while (_nivelesActivos.length > index + 1) {
      _nivelesActivos.removeLast();
      _pathCtrlList.removeLast().dispose();
    }

    final nodoActual = _nivelesActivos[index];
    if (nodoActual.hijos.isNotEmpty) {
      _nivelesActivos.add(nodoActual.hijos.first);
      _pathCtrlList.add(TextEditingController());
    }
    setState(() {});
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  InputDecoration _decor(String label, IconData icon, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final tiposArbol = context.watch<PropiedadProvider>().tiposArbol;
    final esInquilino = widget.rol == 'INQUILINO';

    final bannerColor = esInquilino ? Colors.orange : Colors.teal;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner contextual según rol
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: bannerColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  esInquilino
                      ? Icons.info_outline
                      : Icons.home_work_outlined,
                  color: bannerColor,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        esInquilino ? 'Asociar a unidad existente' : 'Asignar unidad al propietario',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: bannerColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        esInquilino
                            ? 'El inquilino se vincula a una propiedad ya registrada. No se creará ninguna unidad nueva.'
                            : 'Si la unidad no existe aún, se creará automáticamente en la jerarquía del conjunto.',
                        style: TextStyle(
                          fontSize: 12,
                          color: bannerColor.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (tiposArbol.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.home_work_outlined,
                        size: 44, color: cs.outlineVariant),
                    const SizedBox(height: 12),
                    Text(
                      'Sin tipos de propiedad configurados',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configúralos desde la sección de Propiedades.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Selector de tipo raíz
            DropdownButtonFormField<TipoPropiedadNodo>(
              value: _tipoRaizSeleccionado,
              decoration: _decor(
                'Tipo de propiedad',
                Icons.home_work_outlined,
                hint: 'Selecciona...',
              ),
              hint: const Text('Selecciona el tipo...'),
              items: tiposArbol
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.nombre),
                      ))
                  .toList(),
              onChanged: _onTipoRaizChanged,
            ),

            // Campos dinámicos por nivel
            for (int i = 0; i < _nivelesActivos.length; i++) ...[
              const SizedBox(height: 14),
              _NivelField(
                nivel: i,
                nodo: _nivelesActivos[i],
                controller: _pathCtrlList[i],
                esPrimero: i == 0,
                esUltimo: i == _nivelesActivos.length - 1,
                onSubmitted: () => _onNivelLlenado(i),
                onChanged: (v) {
                  if (v.trim().isNotEmpty) _onNivelLlenado(i);
                },
              ),
            ],

            // Breadcrumb del path construido
            if (_pathCtrlList.isNotEmpty &&
                _pathCtrlList[0].text.trim().isNotEmpty) ...[
              const SizedBox(height: 20),
              _PathPreview(labels: buildPathLabels()),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Campo de nivel con decoración por profundidad ────────────────────────────

class _NivelField extends StatelessWidget {
  final int nivel;
  final TipoPropiedadNodo nodo;
  final TextEditingController controller;
  final bool esPrimero;
  final bool esUltimo;
  final VoidCallback onSubmitted;
  final void Function(String) onChanged;

  const _NivelField({
    required this.nivel,
    required this.nodo,
    required this.controller,
    required this.esPrimero,
    required this.esUltimo,
    required this.onSubmitted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colores = [
      Colors.teal,
      Colors.indigo,
      Colors.deepOrange,
      Colors.purple,
    ];
    final color = colores[nivel % colores.length];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Conector visual de jerarquía
        if (!esPrimero)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              Icons.subdirectory_arrow_right_rounded,
              size: 18,
              color: cs.outlineVariant,
            ),
          ),
        // Chip del tipo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            nodo.nombre,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Campo de texto
        Expanded(
          child: TextFormField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            textInputAction:
                esUltimo ? TextInputAction.done : TextInputAction.next,
            decoration: InputDecoration(
              hintText: nodo.descripcion ?? 'Ej: 101, A, etc.',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: color, width: 2),
              ),
            ),
            onFieldSubmitted: (_) => onSubmitted(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ─── Preview del path construido ──────────────────────────────────────────────

class _PathPreview extends StatelessWidget {
  final List<String> labels;

  const _PathPreview({required this.labels});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    if (labels.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.route_outlined, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                for (int i = 0; i < labels.length; i++) ...[
                  if (i > 0)
                    Icon(Icons.chevron_right,
                        size: 14, color: cs.onSurfaceVariant),
                  Text(
                    labels[i],
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.check_circle_outline,
              size: 16, color: Colors.teal),
        ],
      ),
    );
  }
}
