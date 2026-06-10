import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../../features/usuarios/models/usuario_response.dart';
import '../../../features/usuarios/services/usuario_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/miembro_consejo_model.dart';
import '../services/admin_consejo_service.dart';

/// Pantalla de administración del Consejo Comunal.
/// Permite al TENANT_ADMIN designar y revocar consejeros.
class AdminConsejoScreen extends StatefulWidget {
  const AdminConsejoScreen({super.key});

  @override
  State<AdminConsejoScreen> createState() => _AdminConsejoScreenState();
}

class _AdminConsejoScreenState extends State<AdminConsejoScreen> {
  List<MiembroConsejoModel> _miembros = [];
  bool _loading = true;
  String? _error;

  static const _cargos = [
    'PRESIDENTE',
    'VICEPRESIDENTE',
    'TESORERO',
    'SECRETARIO',
    'VOCAL',
  ];

  static const _cargoColores = {
    'PRESIDENTE':     (Color(0xFFE8D5FA), Color(0xFF5B21B6)),
    'VICEPRESIDENTE': (Color(0xFFDCFCE7), Color(0xFF166534)),
    'TESORERO':       (Color(0xFFFFE8CC), Color(0xFFB45309)),
    'SECRETARIO':     (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    'VOCAL':          (Color(0xFFFFF9C4), Color(0xFF7B6000)),
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final m = await AdminConsejoService.listarActivos();
      if (mounted) setState(() { _miembros = m; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _revocar(MiembroConsejoModel m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Revocar membresía'),
        content: Text('¿Revocar a ${m.nombreUsuario} como ${m.cargoTexto}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AdminConsejoService.revocar(m.id);
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: Text('${m.nombreUsuario} fue removido del consejo'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(e.toString().replaceFirst('Exception: ', '')),
        autoCloseDuration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _abrirDesignar() async {
    final actualizado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DesignarSheet(cargos: _cargos, miembrosActivos: _miembros),
    );
    if (actualizado == true) await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consejo Comunal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargar,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirDesignar,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Designar'),
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: cs.error)))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: _miembros.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.gavel_outlined, size: 48, color: cs.onSurfaceVariant),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No hay consejeros activos',
                                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Usa el botón "Designar" para agregar miembros',
                                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _miembros.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _MiembroTileAdmin(
                            miembro: _miembros[i],
                            colores: _cargoColores[_miembros[i].cargo],
                            onRevocar: () => _revocar(_miembros[i]),
                          ),
                        ),
                ),
    );
  }
}

// ─── Tile de miembro ──────────────────────────────────────────────────────────

class _MiembroTileAdmin extends StatelessWidget {
  final MiembroConsejoModel miembro;
  final (Color, Color)? colores;
  final VoidCallback onRevocar;

  const _MiembroTileAdmin({
    required this.miembro,
    required this.colores,
    required this.onRevocar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = colores?.$1 ?? cs.surfaceContainerHighest;
    final fg = colores?.$2 ?? cs.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.person_rounded, color: fg, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  miembro.nombreUsuario,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        miembro.cargoTexto,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Desde ${miembro.fechaInicio}',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red),
            tooltip: 'Revocar',
            onPressed: onRevocar,
          ),
        ],
      ),
    );
  }
}

// ─── Sheet para designar ──────────────────────────────────────────────────────

class _DesignarSheet extends StatefulWidget {
  final List<String> cargos;
  final List<MiembroConsejoModel> miembrosActivos;

  const _DesignarSheet({required this.cargos, required this.miembrosActivos});

  @override
  State<_DesignarSheet> createState() => _DesignarSheetState();
}

class _DesignarSheetState extends State<_DesignarSheet> {
  List<UsuarioResponse> _usuarios = [];
  bool _cargandoUsuarios = true;

  UsuarioResponse? _usuarioSel;
  String? _cargoSel;
  DateTime _fechaInicio = DateTime.now();
  bool _guardando = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    try {
      final todos = await UsuarioService.listarTodos();
      // Excluir los que ya son consejeros activos
      final idsActivos = widget.miembrosActivos.map((m) => m.usuarioId).toSet();
      final filtrados = todos.where((u) => u.activo && !idsActivos.contains(u.id)).toList();
      if (mounted) setState(() { _usuarios = filtrados; _cargandoUsuarios = false; });
    } catch (_) {
      if (mounted) setState(() { _cargandoUsuarios = false; });
    }
  }

  Future<void> _designar() async {
    if (_usuarioSel == null || _cargoSel == null) {
      setState(() => _errorMsg = 'Selecciona un usuario y un cargo');
      return;
    }
    setState(() { _guardando = true; _errorMsg = null; });
    try {
      await AdminConsejoService.designar(
        usuarioId: _usuarioSel!.id,
        cargo: _cargoSel!,
        fechaInicio: _fechaInicio.toIso8601String().split('T').first,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _fechaInicio = picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.outline, borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text(
                    'Designar consejero',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: cs.onSurfaceVariant,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _cargandoUsuarios
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      children: [
                        // ── Usuario ──────────────────────────────────
                        _Label('Usuario'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<UsuarioResponse>(
                          value: _usuarioSel,
                          hint: const Text('Selecciona un residente'),
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          items: _usuarios.map((u) => DropdownMenuItem(
                            value: u,
                            child: Text('${u.nombre} · ${u.rol}', overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (v) => setState(() => _usuarioSel = v),
                        ),
                        const SizedBox(height: 16),

                        // ── Cargo ─────────────────────────────────────
                        _Label('Cargo'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _cargoSel,
                          hint: const Text('Selecciona un cargo'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          items: widget.cargos.map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(_cargoLegible(c)),
                          )).toList(),
                          onChanged: (v) => setState(() => _cargoSel = v),
                        ),
                        const SizedBox(height: 16),

                        // ── Fecha de inicio ───────────────────────────
                        _Label('Fecha de inicio'),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickFecha,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: cs.outline),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 18, color: cs.onSurfaceVariant),
                                const SizedBox(width: 10),
                                Text(
                                  '${_fechaInicio.day.toString().padLeft(2, '0')}/'
                                  '${_fechaInicio.month.toString().padLeft(2, '0')}/'
                                  '${_fechaInicio.year}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_errorMsg != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _errorMsg!,
                              style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _guardando ? null : _designar,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.purple,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: _guardando
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.gavel_rounded, size: 18),
                            label: const Text('Designar consejero'),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _cargoLegible(String c) {
    if (c.isEmpty) return c;
    return c[0].toUpperCase() + c.substring(1).toLowerCase();
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.4,
      ),
    );
  }
}
