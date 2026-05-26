import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'tenant_wizard_step_propiedades.dart';
import 'tenant_wizard_step_pasarelas.dart';

class TenantWizardStepResumen extends StatelessWidget {
  final TextEditingController nombreCtrl;
  final TextEditingController codigoCtrl;
  final TextEditingController direccionCtrl;
  final TextEditingController schemaCtrl;
  final TextEditingController emailCtrl;
  final String timezone;
  final List<TipoNodoEditable> tiposPropiedad;
  final List<PasarelaWizardData> pasarelas;

  const TenantWizardStepResumen({
    super.key,
    required this.nombreCtrl,
    required this.codigoCtrl,
    required this.direccionCtrl,
    required this.schemaCtrl,
    required this.emailCtrl,
    required this.timezone,
    required this.tiposPropiedad,
    required this.pasarelas,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final tiposValidos = tiposPropiedad
        .where((t) => t.nombreCtrl.text.trim().isNotEmpty)
        .toList();
    final pasarelasHabilitadas = pasarelas.where((p) => p.habilitada).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner de confirmación ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.ok.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.ok.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.okSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.ok,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Todo listo para crear!',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.ok,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Revisa los datos antes de confirmar. No podrás cambiar el schema después.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.ok.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Sección: Información básica ─────────────────────────────────
          _SeccionResumen(
            titulo: 'Información básica',
            icono: Icons.apartment_outlined,
            color: cs.primary,
            items: [
              _ItemResumen(
                label: 'Nombre',
                valor: nombreCtrl.text.trim(),
                icono: Icons.apartment_outlined,
              ),
              _ItemResumen(
                label: 'Código',
                valor: codigoCtrl.text.trim(),
                icono: Icons.tag,
                mono: true,
              ),
              if (direccionCtrl.text.trim().isNotEmpty)
                _ItemResumen(
                  label: 'Dirección',
                  valor: direccionCtrl.text.trim(),
                  icono: Icons.location_on_outlined,
                ),
              _ItemResumen(
                label: 'Zona horaria',
                valor: timezone,
                icono: Icons.public,
                mono: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Sección: Base de datos ──────────────────────────────────────
          _SeccionResumen(
            titulo: 'Base de datos',
            icono: Icons.storage_outlined,
            color: Colors.indigo,
            items: [
              _ItemResumen(
                label: 'Schema',
                valor: schemaCtrl.text.trim(),
                icono: Icons.storage_outlined,
                mono: true,
                esImportante: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Sección: Administrador ──────────────────────────────────────
          _SeccionResumen(
            titulo: 'Administrador',
            icono: Icons.manage_accounts_outlined,
            color: Colors.deepPurple,
            items: [
              _ItemResumen(
                label: 'Correo',
                valor: emailCtrl.text.trim(),
                icono: Icons.email_outlined,
              ),
              const _ItemResumen(
                label: 'Contraseña',
                valor: '••••••••',
                icono: Icons.lock_outlined,
              ),
            ],
          ),

          // ── Sección: Tipos de propiedad ─────────────────────────────────
          if (tiposValidos.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SeccionTiposArbol(tiposValidos: tiposValidos),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Sin tipos de propiedad configurados',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Sección: Pasarelas de pago ──────────────────────────────────
          const SizedBox(height: 16),
          if (pasarelasHabilitadas.isNotEmpty)
            _SeccionPasarelas(pasarelas: pasarelasHabilitadas)
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.payments_outlined, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Sin pasarelas de pago configuradas',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // ── Alerta schema inmutable ─────────────────────────────────────
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.orange.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'El schema "${schemaCtrl.text.trim()}" no podrá ser cambiado una vez se cree el tenant. Verifica que sea correcto.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sección agrupada ─────────────────────────────────────────────────────────

class _SeccionResumen extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final List<_ItemResumen> items;

  const _SeccionResumen({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado de sección ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(icono, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // ── Items ───────────────────────────────────────────────────────
          ...items.map(
            (item) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: item,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sección árbol tipos de propiedad ────────────────────────────────────────

class _SeccionTiposArbol extends StatelessWidget {
  final List<TipoNodoEditable> tiposValidos;

  const _SeccionTiposArbol({required this.tiposValidos});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.home_work_outlined, size: 16, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  'TIPOS DE PROPIEDAD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
          // Árbol de nodos
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < tiposValidos.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _NodoArbolWidget(nodo: tiposValidos[i], nivel: 0),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NodoArbolWidget extends StatelessWidget {
  final TipoNodoEditable nodo;
  final int nivel;

  const _NodoArbolWidget({required this.nodo, required this.nivel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nombre = nodo.nombreCtrl.text.trim();
    if (nombre.isEmpty) return const SizedBox.shrink();

    final colores = [Colors.teal, Colors.indigo, Colors.deepOrange, Colors.pink];
    final color = colores[nivel % colores.length];

    final hijosValidos = nodo.hijos
        .where((h) => h.nombreCtrl.text.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila del nodo
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Indentación + conector
            if (nivel > 0) ...[
              SizedBox(width: (nivel - 1) * 20.0),
              Icon(Icons.subdirectory_arrow_right_rounded,
                  size: 16, color: cs.outlineVariant),
              const SizedBox(width: 4),
            ],
            // Chip del tipo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    nivel == 0 ? Icons.home_work_outlined : Icons.layers_outlined,
                    size: 13,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    nombre,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            // Badge facturable
            if (nodo.esFacturable) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade600, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long, size: 11, color: Colors.amber.shade700),
                    const SizedBox(width: 3),
                    Text(
                      'Facturable',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        // Hijos recursivos
        if (hijosValidos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: hijosValidos
                  .map((h) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _NodoArbolWidget(nodo: h, nivel: nivel + 1),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

// ─── Sección pasarelas de pago ────────────────────────────────────────────────

class _SeccionPasarelas extends StatelessWidget {
  final List<PasarelaWizardData> pasarelas;
  const _SeccionPasarelas({required this.pasarelas});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'PASARELAS DE PAGO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${pasarelas.length} activa${pasarelas.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chips por pasarela
          Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pasarelas.map((p) => _PasarelaChip(pasarela: p)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasarelaChip extends StatelessWidget {
  final PasarelaWizardData pasarela;
  const _PasarelaChip({required this.pasarela});

  @override
  Widget build(BuildContext context) {
    final color = _color(pasarela.tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icono(pasarela.tipo), size: 15, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pasarela.tipo.nombreLegible,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                pasarela.sandbox ? 'Sandbox' : 'Producción',
                style: TextStyle(
                  fontSize: 10,
                  color: pasarela.sandbox ? Colors.amber.shade700 : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Badge de prioridad
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${pasarela.prioridad}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _color(tipo) {
    switch (tipo.toString()) {
      case 'TipoPasarela.mercadoPago': return const Color(0xFF009EE3);
      case 'TipoPasarela.wompi':       return const Color(0xFF00C896);
      case 'TipoPasarela.bold':        return const Color(0xFF5B2D8E);
      default:                         return Colors.grey;
    }
  }

  IconData _icono(tipo) {
    switch (tipo.toString()) {
      case 'TipoPasarela.mercadoPago': return Icons.payment_outlined;
      case 'TipoPasarela.wompi':       return Icons.credit_card_outlined;
      case 'TipoPasarela.bold':        return Icons.bolt_outlined;
      default:                         return Icons.payments_outlined;
    }
  }
}

// ─── Item individual ──────────────────────────────────────────────────────────

class _ItemResumen extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icono;
  final bool mono;
  final bool esImportante;

  const _ItemResumen({
    required this.label,
    required this.valor,
    required this.icono,
    this.mono = false,
    this.esImportante = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      esImportante ? FontWeight.w700 : FontWeight.w500,
                  color: esImportante
                      ? Colors.indigo
                      : cs.onSurface,
                  fontFamily: mono ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
