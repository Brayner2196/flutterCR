import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../models/pasarela_disponible_model.dart';
import '../../widgets/pasarela_comisiones_widget.dart';

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
                Row(
                  children: [
                    _credencial('Public Key', pasarela.tienePublicKey),
                    const SizedBox(width: 8),
                    _credencial('Private Key', pasarela.tienePrivateKey),
                    const SizedBox(width: 8),
                    _credencial('Webhook', pasarela.tieneWebhookSecret),
                  ],
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
  int _prioridad = 1;
  bool _sandbox = false;
  bool _guardando = false;
  bool _mostrarPrivateKey = false;

  @override
  void initState() {
    super.initState();
    if (widget.existente != null) {
      _tipo = widget.existente!.tipoPasarela;
      _prioridad = widget.existente!.prioridad;
      _sandbox = widget.existente!.sandbox;
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final url = widget.tenantId != null
          ? ApiConstants.tenantPasarelas(widget.tenantId!)
          : ApiConstants.adminPasarelas;

      final body = {
        'tipoPasarela': _tipo.backendValue,
        'publicKey': _publicKeyCtrl.text.trim(),
        'privateKey': _privateKeyCtrl.text.trim(),
        if (_webhookCtrl.text.isNotEmpty)
          'webhookSecret': _webhookCtrl.text.trim(),
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
                label: _labelPublicKey(_tipo),
                hint: _hintPublicKey(_tipo),
                required: true,
              ),
              const SizedBox(height: 12),

              // Private Key
              _campo(
                ctrl: _privateKeyCtrl,
                label: _labelPrivateKey(_tipo),
                hint: _hintPrivateKey(_tipo),
                required: true,
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

              // Webhook secret
              _campo(
                ctrl: _webhookCtrl,
                label: 'Webhook Secret (opcional)',
                hint: 'Para verificar la firma de webhooks',
                required: false,
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

  Widget _campo({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required bool required,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            suffixIcon: suffix,
          ),
          validator: required
              ? (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null
              : null,
        ),
      ],
    );
  }

  Widget _ayudaPasarela(TipoPasarela tipo) {
    final texto = switch (tipo) {
      TipoPasarela.mercadoPago =>
        'Para MercadoPago: usa la Access Token de tu cuenta. '
            'La Public Key es la llave pública del checkout.',
      TipoPasarela.wompi =>
        'Para Wompi: usa la llave privada como Private Key '
            'y la llave pública como Public Key. '
            'El Webhook Secret es el "events_secret" de tu cuenta Wompi.',
      TipoPasarela.bold =>
        'Para Bold: usa tu API key como Private Key. '
            'El Webhook Secret es el secreto de eventos configurado en el panel.',
    };
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

  String _labelPublicKey(TipoPasarela tipo) => switch (tipo) {
    TipoPasarela.mercadoPago => 'Public Key',
    TipoPasarela.wompi => 'Llave pública',
    TipoPasarela.bold => 'API Key pública',
  };

  String _hintPublicKey(TipoPasarela tipo) => switch (tipo) {
    TipoPasarela.mercadoPago => 'APP_USR-...',
    TipoPasarela.wompi => 'pub_...',
    TipoPasarela.bold => 'pk_...',
  };

  String _labelPrivateKey(TipoPasarela tipo) => switch (tipo) {
    TipoPasarela.mercadoPago => 'Access Token (Private Key)',
    TipoPasarela.wompi => 'Llave privada (Private Key)',
    TipoPasarela.bold => 'API Key privada',
  };

  String _hintPrivateKey(TipoPasarela tipo) => switch (tipo) {
    TipoPasarela.mercadoPago => 'APP_USR-...',
    TipoPasarela.wompi => 'prv_...',
    TipoPasarela.bold => 'sk_...',
  };
}

class _FallbackLogo extends StatelessWidget {
  final Color color;
  final String label;
  final double size;
  const _FallbackLogo({
    required this.color,
    required this.label,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final initials = label.split(' ').map((w) => w[0]).take(2).join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.32,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
