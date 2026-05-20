import 'package:flutter/material.dart';

/// Nodo editable del árbol de tipos de propiedad
class TipoNodoEditable {
  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final List<TipoNodoEditable> hijos = [];
  bool esFacturable = false;

  void dispose() {
    nombreCtrl.dispose();
    descCtrl.dispose();
    for (final h in hijos) {
      h.dispose();
    }
  }
}

class TenantWizardStepPropiedades extends StatefulWidget {
  final List<TipoNodoEditable> tiposRaiz;
  final VoidCallback onCambio;

  const TenantWizardStepPropiedades({
    super.key,
    required this.tiposRaiz,
    required this.onCambio,
  });

  @override
  State<TenantWizardStepPropiedades> createState() =>
      _TenantWizardStepPropiedadesState();
}

class _TenantWizardStepPropiedadesState
    extends State<TenantWizardStepPropiedades> {
  void _agregar() {
    setState(() => widget.tiposRaiz.add(TipoNodoEditable()));
    widget.onCambio();
  }

  void _eliminar(int index) {
    setState(() => widget.tiposRaiz.removeAt(index));
    widget.onCambio();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBanner(
            icon: Icons.home_work_outlined,
            color: Colors.teal,
            texto:
                'Define la estructura de propiedades del conjunto. Puedes agregar tipos raíz (Torre, Bloque) y sus subtipos (Apartamento, Parqueadero).',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates_outlined,
                    size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Este paso es opcional. Puedes configurar la estructura más adelante.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Header + botón agregar ───────────────────────────────────────
          Row(
            children: [
              Text(
                'Tipos de propiedad',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: _agregar,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar tipo'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (widget.tiposRaiz.isEmpty)
            _EmptyPropiedades()
          else
            for (int i = 0; i < widget.tiposRaiz.length; i++)
              _TipoNodoWidget(
                nodo: widget.tiposRaiz[i],
                indent: 0,
                onEliminar: () => _eliminar(i),
                onCambio: () {
                  setState(() {});
                  widget.onCambio();
                },
              ),
        ],
      ),
    );
  }
}

// ─── Widget vacío ─────────────────────────────────────────────────────────────

class _EmptyPropiedades extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.home_work_outlined,
              size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text(
            'Sin tipos configurados',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ej: Torre → Apartamento, Parqueadero',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nodo del árbol ───────────────────────────────────────────────────────────

class _TipoNodoWidget extends StatelessWidget {
  final TipoNodoEditable nodo;
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
    final cs = theme.colorScheme;

    final colores = [
      Colors.teal,
      Colors.indigo,
      Colors.deepOrange,
      Colors.pink,
    ];
    final color = colores[indent % colores.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(left: indent * 16.0, top: 8),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          indent == 0
                              ? Icons.home_work_outlined
                              : Icons.subdirectory_arrow_right,
                          size: 14,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: nodo.nombreCtrl,
                          decoration: InputDecoration(
                            labelText:
                                indent == 0 ? 'Tipo raíz' : 'Subtipo',
                            hintText: indent == 0
                                ? 'Ej: Torre, Bloque'
                                : 'Ej: Apartamento',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MiniBtn(
                        icon: Icons.add,
                        color: color,
                        tooltip: 'Agregar subtipo',
                        onTap: () {
                          nodo.hijos.add(TipoNodoEditable());
                          onCambio();
                        },
                      ),
                      const SizedBox(width: 4),
                      _MiniBtn(
                        icon: Icons.delete_outline,
                        color: cs.error,
                        tooltip: 'Eliminar',
                        onTap: onEliminar,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nodo.descCtrl,
                          decoration: InputDecoration(
                            labelText: 'Descripción (opcional)',
                            hintText: 'Descripción o hint para el registro',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          nodo.esFacturable = !nodo.esFacturable;
                          onCambio();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: nodo.esFacturable
                                ? Colors.teal.withValues(alpha: 0.15)
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: nodo.esFacturable
                                  ? Colors.teal
                                  : Theme.of(context).colorScheme.outline,
                              width: nodo.esFacturable ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                nodo.esFacturable
                                    ? Icons.receipt_long
                                    : Icons.receipt_long_outlined,
                                size: 14,
                                color: nodo.esFacturable
                                    ? Colors.teal
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Facturable',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: nodo.esFacturable
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: nodo.esFacturable
                                      ? Colors.teal
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _MiniBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ─── Banner informativo ───────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String texto;
  const _InfoBanner({required this.icon, required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                color: color.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
