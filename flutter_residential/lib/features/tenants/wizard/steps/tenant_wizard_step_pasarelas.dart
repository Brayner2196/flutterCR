import 'package:flutter/material.dart';
import '../../../../features/pagos/models/pasarela_disponible_model.dart';
import '../../../../features/pagos/widgets/pasarela_comisiones_widget.dart';
import '../../../../features/pagos/config/credenciales_pasarela.dart';

// ─── Modelo interno del wizard ────────────────────────────────────────────────

/// Datos de una pasarela durante la configuración del wizard.
/// Independiente del modelo de red — solo vive en memoria.
class PasarelaWizardData {
  final TipoPasarela tipo;
  bool habilitada;
  bool sandbox;
  int prioridad;
  final TextEditingController publicKeyCtrl  = TextEditingController();
  final TextEditingController privateKeyCtrl = TextEditingController();
  final TextEditingController webhookCtrl    = TextEditingController();
  /// Solo lo usan las pasarelas que firman el checkout (hoy Wompi). Ver
  /// [CredencialesPasarela.integritySecret].
  final TextEditingController integrityCtrl  = TextEditingController();

  PasarelaWizardData({
    required this.tipo,
    this.habilitada = false,
    this.sandbox    = true,
    this.prioridad  = 1,
  });

  /// Convierte a JSON para enviar al backend al crear el tenant
  Map<String, dynamic> toJson() => {
    'tipoPasarela' : tipo.backendValue,
    'publicKey'    : publicKeyCtrl.text.trim().isEmpty ? null : publicKeyCtrl.text.trim(),
    'privateKey'   : privateKeyCtrl.text.trim().isEmpty ? null : privateKeyCtrl.text.trim(),
    'webhookSecret': webhookCtrl.text.trim().isEmpty ? null : webhookCtrl.text.trim(),
    'integritySecret': integrityCtrl.text.trim().isEmpty ? null : integrityCtrl.text.trim(),
    'sandbox'      : sandbox,
    'prioridad'    : prioridad,
  };

  void dispose() {
    publicKeyCtrl.dispose();
    privateKeyCtrl.dispose();
    webhookCtrl.dispose();
    integrityCtrl.dispose();
  }
}

// ─── Step Widget ──────────────────────────────────────────────────────────────

class TenantWizardStepPasarelas extends StatefulWidget {
  final List<PasarelaWizardData> pasarelas;
  final VoidCallback onCambio;

  const TenantWizardStepPasarelas({
    super.key,
    required this.pasarelas,
    required this.onCambio,
  });

  @override
  State<TenantWizardStepPasarelas> createState() =>
      _TenantWizardStepPasarelasState();
}

class _TenantWizardStepPasarelasState
    extends State<TenantWizardStepPasarelas> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner informativo ───────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.payments_outlined, color: Colors.blue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Configura las pasarelas de pago del conjunto. '
                    'Es opcional — puedes hacerlo después desde la gestión del tenant. '
                    'Activa solo las que el conjunto usará.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Card por pasarela ────────────────────────────────────────────
          ...widget.pasarelas.asMap().entries.map((entry) {
            final idx      = entry.key;
            final pasarela = entry.value;
            return _PasarelaCard(
              pasarela: pasarela,
              index: idx,
              totalHabilitadas: widget.pasarelas.where((p) => p.habilitada).length,
              onCambio: () {
                setState(() {});
                widget.onCambio();
              },
            );
          }),
        ],
      ),
    );
  }
}

// ─── Card expandible por pasarela ─────────────────────────────────────────────

class _PasarelaCard extends StatefulWidget {
  final PasarelaWizardData pasarela;
  final int index;
  final int totalHabilitadas;
  final VoidCallback onCambio;

  const _PasarelaCard({
    required this.pasarela,
    required this.index,
    required this.totalHabilitadas,
    required this.onCambio,
  });

  @override
  State<_PasarelaCard> createState() => _PasarelaCardState();
}

class _PasarelaCardState extends State<_PasarelaCard> {
  bool _verPrivateKey   = false;
  bool _verWebhook      = false;
  bool _verIntegrity    = false;

  @override
  Widget build(BuildContext context) {
    final cs          = Theme.of(context).colorScheme;
    final theme       = Theme.of(context);
    final p           = widget.pasarela;
    final color       = _colorPasarela(p.tipo);
    final icono       = _iconoPasarela(p.tipo);
    final campoIntegridad = CredencialesPasarela.integritySecret(p.tipo);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: p.habilitada ? color.withValues(alpha: 0.5) : cs.outlineVariant,
          width: p.habilitada ? 1.5 : 1,
        ),
        color: p.habilitada
            ? color.withValues(alpha: 0.04)
            : cs.surface,
      ),
      child: Column(
        children: [
          // ── Header con toggle ──────────────────────────────────────────
          InkWell(
            onTap: () {
              setState(() => p.habilitada = !p.habilitada);
              widget.onCambio();
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Ícono
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icono, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.tipo.nombreLegible,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _subtituloPasarela(p.tipo),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Toggle
                  Switch(
                    value: p.habilitada,
                    activeThumbColor: color,
                    onChanged: (v) {
                      setState(() => p.habilitada = v);
                      widget.onCambio();
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Campos desplegables cuando está habilitada ─────────────────
          if (p.habilitada) ...[
            Divider(height: 1, color: cs.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sandbox toggle
                  _SandboxRow(
                    sandbox: p.sandbox,
                    onChanged: (v) => setState(() => p.sandbox = v),
                  ),
                  const SizedBox(height: 14),

                  // Prioridad
                  _PrioridadRow(
                    prioridad: p.prioridad,
                    onChanged: (v) => setState(() => p.prioridad = v),
                  ),
                  const SizedBox(height: 14),

                  // Public key
                  _CredencialField(
                    controller: p.publicKeyCtrl,
                    campo: CredencialesPasarela.publicKey(p.tipo),
                  ),
                  const SizedBox(height: 10),

                  // Private key
                  _CredencialField(
                    controller: p.privateKeyCtrl,
                    campo: CredencialesPasarela.privateKey(p.tipo),
                    visible: _verPrivateKey,
                    onToggleVisible: () => setState(() => _verPrivateKey = !_verPrivateKey),
                  ),
                  const SizedBox(height: 10),

                  // Secreto de integridad — solo en las pasarelas que firman el checkout.
                  // El descriptor decide si aplica: aqui no hay un if por tipo de pasarela.
                  if (campoIntegridad != null) ...[
                    _CredencialField(
                      controller: p.integrityCtrl,
                      campo: campoIntegridad,
                      visible: _verIntegrity,
                      onToggleVisible: () => setState(() => _verIntegrity = !_verIntegrity),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Webhook secret
                  _CredencialField(
                    controller: p.webhookCtrl,
                    campo: CredencialesPasarela.webhookSecret(p.tipo),
                    visible: _verWebhook,
                    onToggleVisible: () => setState(() => _verWebhook = !_verWebhook),
                  ),

                  // Nota de seguridad
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 13, color: cs.onSurfaceVariant),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Las credenciales se almacenan cifradas con AES-256-GCM.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // ── Tarifas de comisión (dropdown inline, siempre visible) ─────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(14),
            ),
            child: PasarelaComisionesInline(tipo: p.tipo),
          ),
        ],
      ),
    );
  }

  // ── Helpers de UI por tipo de pasarela ──────────────────────────────────────

  Color _colorPasarela(TipoPasarela tipo) {
    switch (tipo) {
      case TipoPasarela.mercadoPago: return const Color(0xFF009EE3);
      case TipoPasarela.wompi:       return const Color(0xFF00C896);
      case TipoPasarela.bold:        return const Color(0xFF5B2D8E);
    }
  }

  IconData _iconoPasarela(TipoPasarela tipo) {
    switch (tipo) {
      case TipoPasarela.mercadoPago: return Icons.payment_outlined;
      case TipoPasarela.wompi:       return Icons.credit_card_outlined;
      case TipoPasarela.bold:        return Icons.bolt_outlined;
    }
  }

  String _subtituloPasarela(TipoPasarela tipo) {
    switch (tipo) {
      case TipoPasarela.mercadoPago: return 'Tarjetas, PSE, Nequi, efectivo';
      case TipoPasarela.wompi:       return 'Tarjetas, Nequi, Bancolombia';
      case TipoPasarela.bold:        return 'Tarjetas débito y crédito';
    }
  }

}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _SandboxRow extends StatelessWidget {
  final bool sandbox;
  final ValueChanged<bool> onChanged;

  const _SandboxRow({required this.sandbox, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          sandbox ? Icons.science_outlined : Icons.rocket_launch_outlined,
          size: 16,
          color: sandbox ? Colors.amber.shade700 : Colors.green,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            sandbox ? 'Modo pruebas (sandbox)' : 'Modo producción',
            style: theme.textTheme.bodySmall?.copyWith(
              color: sandbox ? Colors.amber.shade700 : Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch(
          value: !sandbox,
          activeThumbColor: Colors.green,
          onChanged: (v) => onChanged(!v),
        ),
      ],
    );
  }
}

class _PrioridadRow extends StatelessWidget {
  final int prioridad;
  final ValueChanged<int> onChanged;

  const _PrioridadRow({required this.prioridad, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.format_list_numbered, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          'Prioridad (orden de aparición):',
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const Spacer(),
        _PrioridadSelector(value: prioridad, onChanged: onChanged),
      ],
    );
  }
}

class _PrioridadSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _PrioridadSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove, size: 16),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
        Container(
          width: 32,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, size: 16),
          onPressed: value < 9 ? () => onChanged(value + 1) : null,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }
}

/// Campo de credencial del wizard. Toda la descripcion (etiqueta, ejemplo, si es secreto)
/// viene de [CampoCredencial], asi que agregar una credencial no toca este widget.
class _CredencialField extends StatelessWidget {
  final TextEditingController controller;
  final CampoCredencial campo;

  /// Solo aplica a los campos secretos: si el valor se muestra en claro.
  final bool visible;

  /// Solo aplica a los campos secretos: alterna [visible].
  final VoidCallback? onToggleVisible;

  const _CredencialField({
    required this.controller,
    required this.campo,
    this.visible = false,
    this.onToggleVisible,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: campo.secreto && !visible,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          decoration: InputDecoration(
            labelText: campo.obligatorio ? '${campo.label} *' : campo.label,
            hintText: campo.hint,
            prefixIcon: Icon(campo.icono, size: 18),
            suffixIcon: (campo.secreto && onToggleVisible != null)
                ? IconButton(
                    icon: Icon(
                      visible ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: onToggleVisible,
                  )
                : null,
            filled: true,
            fillColor: cs.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
          ),
        ),
        // La ayuda va debajo y no en el hint porque el hint desaparece al escribir, y es
        // justo mientras el admin pega el valor cuando necesita saber que pego lo correcto.
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text(
            campo.ayuda,
            style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
