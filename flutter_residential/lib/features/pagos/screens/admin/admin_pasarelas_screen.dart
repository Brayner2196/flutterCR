import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../models/pasarela_disponible_model.dart';
import '../../widgets/pasarela_comisiones_widget.dart';
import '../../config/credenciales_pasarela.dart';

// ─── Modelo de respuesta para admin ───────────────────────────────────────────

class PasarelaConfigModel {
  final int id;
  final TipoPasarela tipoPasarela;
  final String nombre;
  final bool activa;
  final int prioridad;
  final bool sandbox;
  final bool tienePublicKey;
  final bool tienePrivateKey;
  final bool tieneWebhookSecret;
  final bool tieneIntegritySecret;

  const PasarelaConfigModel({
    required this.id,
    required this.tipoPasarela,
    required this.nombre,
    required this.activa,
    required this.prioridad,
    required this.sandbox,
    required this.tienePublicKey,
    required this.tienePrivateKey,
    required this.tieneWebhookSecret,
    required this.tieneIntegritySecret,
  });

  factory PasarelaConfigModel.fromJson(Map<String, dynamic> json) {
    return PasarelaConfigModel(
      id: json['id'] as int,
      tipoPasarela: TipoPasarela.fromString(json['tipoPasarela'] as String),
      nombre: json['nombre'] as String,
      activa: json['activa'] as bool,
      prioridad: json['prioridad'] as int? ?? 1,
      sandbox: json['sandbox'] as bool? ?? false,
      tienePublicKey: json['tienePublicKey'] as bool? ?? false,
      tienePrivateKey: json['tienePrivateKey'] as bool? ?? false,
      tieneWebhookSecret: json['tieneWebhookSecret'] as bool? ?? false,
      tieneIntegritySecret: json['tieneIntegritySecret'] as bool? ?? false,
    );
  }
}

// ─── Pantalla principal ────────────────────────────────────────────────────────

/// Pantalla para que el TENANT_ADMIN gestione las pasarelas de pago del conjunto.
/// El SUPER_ADMIN puede pasar [tenantId] para gestionar cualquier tenant.
class AdminPasarelasScreen extends StatefulWidget {
  final int? tenantId; // null = usa el tenant del contexto (TENANT_ADMIN)

  const AdminPasarelasScreen({super.key, this.tenantId});

  @override
  State<AdminPasarelasScreen> createState() => _AdminPasarelasScreenState();
}

class _AdminPasarelasScreenState extends State<AdminPasarelasScreen> {
  List<PasarelaConfigModel> _pasarelas = [];
  bool _cargando = true;
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
      final url = widget.tenantId != null
          ? ApiConstants.tenantPasarelas(widget.tenantId!)
          : ApiConstants.adminPasarelas;
      final res = await ApiClient.get(url, requiresAuth: true);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        setState(() {
          _pasarelas = list
              .map(
                (e) => PasarelaConfigModel.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        });
      } else {
        setState(() => _error = 'Error ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _toggleActiva(PasarelaConfigModel p) async {
    try {
      final url = widget.tenantId != null
          ? ApiConstants.tenantPasarelaToggle(widget.tenantId!, p.id)
          : ApiConstants.adminPasarelaToggle(p.id);
      await ApiClient.patch('$url?activa=${!p.activa}');
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _eliminar(PasarelaConfigModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar pasarela?'),
        content: Text(
          'Se eliminará la configuración de ${p.nombre}. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final url = widget.tenantId != null
          ? ApiConstants.tenantPasarelaEliminar(widget.tenantId!, p.id)
          : ApiConstants.adminPasarelaEliminar(p.id);
      await ApiClient.delete(url);
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pasarelas de pago'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Agregar pasarela'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_pasarelas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No hay pasarelas configuradas',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agrega una pasarela para que los residentes\npuedan pagar en línea.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 80),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pasarelas.length,
      itemBuilder: (_, i) => _PasarelaCard(
        pasarela: _pasarelas[i],
        onToggle: () => _toggleActiva(_pasarelas[i]),
        onEditar: () => _mostrarFormulario(context, _pasarelas[i]),
        onEliminar: () => _eliminar(_pasarelas[i]),
      ),
    );
  }

  void _mostrarFormulario(
    BuildContext context,
    PasarelaConfigModel? existente,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PasarelaFormSheet(
        tenantId: widget.tenantId,
        existente: existente,
        onGuardado: _cargar,
      ),
    );
  }
}

// ─── Card de pasarela ─────────────────────────────────────────────────────────

class _PasarelaCard extends StatelessWidget {
  final PasarelaConfigModel pasarela;
  final VoidCallback onToggle;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _PasarelaCard({
    required this.pasarela,
    required this.onToggle,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Contenido principal ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _icono(pasarela.tipoPasarela),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pasarela.nombre,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              _chip(
                                pasarela.activa ? 'Activa' : 'Inactiva',
                                pasarela.activa ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              if (pasarela.sandbox)
                                _chip('Sandbox', Colors.orange),
                              const SizedBox(width: 6),
                              _chip(
                                'Prioridad ${pasarela.prioridad}',
                                Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: pasarela.activa,
                      onChanged: (_) => onToggle(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _credencial('Public Key', pasarela.tienePublicKey),
                    _credencial('Private Key', pasarela.tienePrivateKey),
                    _credencial('Webhook', pasarela.tieneWebhookSecret),
                    // Solo se muestra donde aplica: el descriptor decide, no un if por tipo.
                    if (CredencialesPasarela.integritySecret(pasarela.tipoPasarela) != null)
                      _credencial('Integridad', pasarela.tieneIntegritySecret),
                  ],
                ),

                // Una pasarela activa sin el secreto que firma el checkout no puede cobrar:
                // el residente veria un error de la pasarela sin explicacion. Mejor decirlo aqui.
                if (CredencialesPasarela.requiereIntegritySecret(pasarela.tipoPasarela) &&
                    !pasarela.tieneIntegritySecret)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _aviso(
                      'Falta el secreto de integridad: los residentes no podrán pagar con '
                      '${pasarela.nombre} hasta que lo configures.',
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onEditar,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Editar'),
                    ),
                    TextButton.icon(
                      onPressed: onEliminar,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Eliminar',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Sección de comisiones (dropdown inline) ────────────────────
          PasarelaComisionesInline(tipo: pasarela.tipoPasarela),
        ],
      ),
    );
  }

  Widget _icono(TipoPasarela tipo) {
    final icon = switch (tipo) {
      TipoPasarela.mercadoPago => 'assets/icons/icono_mp.png',
      TipoPasarela.wompi       => 'assets/icons/icono_wompi_black.png',
      TipoPasarela.bold        => 'assets/icons/icono_bold.png',
    };
    return SizedBox(
      width: 42,
      height: 42,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(icon, width: 42, height: 42, fit: BoxFit.cover),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _aviso(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 15, color: Colors.orange),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 11, color: Colors.orange, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _credencial(String label, bool tiene) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          tiene ? Icons.check_circle : Icons.cancel_outlined,
          size: 14,
          color: tiene ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ─── Formulario de pasarela ────────────────────────────────────────────────────

class _PasarelaFormSheet extends StatefulWidget {
  final int? tenantId;
  final PasarelaConfigModel? existente;
  final VoidCallback onGuardado;

  const _PasarelaFormSheet({
    this.tenantId,
    this.existente,
    required this.onGuardado,
  });

  @override
  State<_PasarelaFormSheet> createState() => _PasarelaFormSheetState();
}

class _PasarelaFormSheetState extends State<_PasarelaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  TipoPasarela _tipo = TipoPasarela.mercadoPago;
  final _publicKeyCtrl = TextEditingController();
  final _privateKeyCtrl = TextEditingController();
  final _webhookCtrl = TextEditingController();
  final _integrityCtrl = TextEditingController();
  int _prioridad = 1;
  bool _sandbox = false;
  bool _guardando = false;
  bool _mostrarPrivateKey = false;
  bool _mostrarIntegrity = false;

  @override
  void initState() {
    super.initState();
    if (widget.existente != null) {
      _tipo = widget.existente!.tipoPasarela;
      _prioridad = widget.existente!.prioridad;
      _sandbox = widget.existente!.sandbox;
    }
  }

  @override
  void dispose() {
    _publicKeyCtrl.dispose();
    _privateKeyCtrl.dispose();
    _webhookCtrl.dispose();
    _integrityCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final url = widget.tenantId != null
          ? ApiConstants.tenantPasarelas(widget.tenantId!)
          : ApiConstants.adminPasarelas;

      // Un campo vacio NO se manda: el backend conserva la credencial que ya tenia. Asi el
      // admin puede cambiar solo la prioridad sin volver a pegar todas las llaves (antes ese
      // guardado las borraba, y con el webhook secret eso apagaba la verificacion de firma).
      final body = {
        'tipoPasarela': _tipo.backendValue,
        if (_publicKeyCtrl.text.trim().isNotEmpty)
          'publicKey': _publicKeyCtrl.text.trim(),
        if (_privateKeyCtrl.text.trim().isNotEmpty)
          'privateKey': _privateKeyCtrl.text.trim(),
        if (_webhookCtrl.text.trim().isNotEmpty)
          'webhookSecret': _webhookCtrl.text.trim(),
        if (_integrityCtrl.text.trim().isNotEmpty)
          'integritySecret': _integrityCtrl.text.trim(),
        'sandbox': _sandbox,
        'prioridad': _prioridad,
      };

      final res = await ApiClient.post(url, body, requiresAuth: true);
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) Navigator.pop(context);
        widget.onGuardado();
      } else {
        final error = jsonDecode(res.body)['message'] ?? 'Error al guardar';
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existente != null;
    final campoIntegridad = CredencialesPasarela.integritySecret(_tipo);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit ? 'Editar pasarela' : 'Nueva pasarela',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Tipo de pasarela
              if (!isEdit) ...[
                const Text(
                  'Pasarela',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<TipoPasarela>(
                  initialValue: _tipo,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: TipoPasarela.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.nombreLegible),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _tipo = v!),
                ),
                const SizedBox(height: 14),
              ],

              // Ayuda contextual según pasarela
              _ayudaPasarela(_tipo),
              const SizedBox(height: 14),

              // Tarifas de comisión de la pasarela seleccionada
              PasarelaComisionesWidget(
                pasarelas: [_tipo],
                titulo: 'Comisiones de ${_tipo.nombreLegible}',
              ),

              // Public Key
              _campo(
                ctrl: _publicKeyCtrl,
                campo: CredencialesPasarela.publicKey(_tipo),
                esEdicion: isEdit,
              ),
              const SizedBox(height: 12),

              // Private Key
              _campo(
                ctrl: _privateKeyCtrl,
                campo: CredencialesPasarela.privateKey(_tipo),
                esEdicion: isEdit,
                obscure: !_mostrarPrivateKey,
                suffix: IconButton(
                  icon: Icon(
                    _mostrarPrivateKey
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _mostrarPrivateKey = !_mostrarPrivateKey),
                ),
              ),
              const SizedBox(height: 12),

              // Secreto de integridad — solo donde el descriptor dice que aplica
              if (campoIntegridad != null) ...[
                _campo(
                  ctrl: _integrityCtrl,
                  campo: campoIntegridad,
                  esEdicion: isEdit,
                  obscure: !_mostrarIntegrity,
                  suffix: IconButton(
                    icon: Icon(
                      _mostrarIntegrity
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _mostrarIntegrity = !_mostrarIntegrity),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Webhook secret
              _campo(
                ctrl: _webhookCtrl,
                campo: CredencialesPasarela.webhookSecret(_tipo),
                esEdicion: isEdit,
              ),
              const SizedBox(height: 14),

              // Prioridad y sandbox
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prioridad',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          initialValue: _prioridad,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: [1, 2, 3]
                              .map(
                                (n) => DropdownMenuItem(
                                  value: n,
                                  child: Text('$n'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _prioridad = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Modo sandbox',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        SwitchListTile(
                          title: Text(
                            _sandbox ? 'Pruebas' : 'Producción',
                            style: const TextStyle(fontSize: 13),
                          ),
                          value: _sandbox,
                          onChanged: (v) => setState(() => _sandbox = v),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Actualizar' : 'Guardar'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Campo de credencial. La etiqueta, el ejemplo y si es obligatorio salen de
  /// [CampoCredencial]: agregar una credencial nueva no toca este widget.
  ///
  /// En edicion nada es obligatorio: vacio significa "conserva la que ya esta guardada",
  /// porque el backend nunca devuelve los secretos y el formulario no los puede precargar.
  Widget _campo({
    required TextEditingController ctrl,
    required CampoCredencial campo,
    required bool esEdicion,
    bool obscure = false,
    Widget? suffix,
  }) {
    final exigir = campo.obligatorio && !esEdicion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exigir ? '${campo.label} *' : campo.label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: esEdicion ? 'Déjalo vacío para conservar el actual' : campo.hint,
            border: const OutlineInputBorder(),
            suffixIcon: suffix,
            helperText: campo.ayuda,
            helperMaxLines: 3,
            helperStyle: const TextStyle(fontSize: 11),
          ),
          validator: exigir
              ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
              : null,
        ),
      ],
    );
  }

  Widget _ayudaPasarela(TipoPasarela tipo) {
    final texto = CredencialesPasarela.ayudaGeneral(tipo);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha:0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

}