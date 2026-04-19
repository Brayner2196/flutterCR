import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../models/tipo_propiedad_nodo.dart';
import '../../services/propiedad_service.dart';
import '../../services/auth_service.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _cargando = false;
  bool _cargandoTipos = false;

  List<TipoPropiedadNodo> _tiposRaiz = [];
  TipoPropiedadNodo? _tipoRaizSeleccionado;
  final List<TextEditingController> _pathCtrlList = [];
  final List<TipoPropiedadNodo> _nivelesActivos = [];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _codigoCtrl.dispose();
    _telefonoCtrl.dispose();
    for (final c in _pathCtrlList) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarTipos() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.isEmpty) return;

    setState(() {
      _cargandoTipos = true;
      _tiposRaiz = [];
      _tipoRaizSeleccionado = null;
      _nivelesActivos.clear();
      for (final c in _pathCtrlList) {
        c.dispose();
      }
      _pathCtrlList.clear();
    });

    try {
      final tipos = await PropiedadService.getTiposArbol(codigo);
      setState(() => _tiposRaiz = tipos);
    } catch (_) {
      
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text('No se obtuvieron los tipos de propiedad'),
        description:
            Text('No se pudo cargar la información del conjunto. Verifica el código e intenta de nuevo.'),
        alignment: Alignment.bottomCenter,
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: true,
        closeOnClick: true,
      );

    } finally {
      if (mounted) setState(() => _cargandoTipos = false);
    }
  }

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

  List<Map<String, dynamic>> _construirPropiedadPath() {
    final path = <Map<String, dynamic>>[];
    for (int i = 0; i < _nivelesActivos.length; i++) {
      final valor = _pathCtrlList[i].text.trim();
      if (valor.isEmpty) break;
      path.add({'tipoId': _nivelesActivos[i].id, 'valor': valor});
    }
    return path;
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      final propiedadPath = _construirPropiedadPath();
      final mensaje = await AuthService.registro(
        nombre: _nombreCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        codigoConjunto: _codigoCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim().isEmpty
            ? null
            : _telefonoCtrl.text.trim(),
        propiedadPath: propiedadPath.isEmpty ? null : propiedadPath,
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Solicitud enviada'),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitud de registro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ingresa tus datos y el código de tu conjunto.\nUn administrador aprobará tu acceso.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nombreCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu correo';
                    if (!v.contains('@')) return 'Correo no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Contraseña *',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _codigoCtrl,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Código del conjunto *',
                    prefixIcon: const Icon(Icons.vpn_key_outlined),
                    hintText: 'Ej: EL-PRADO-01',
                    suffixIcon: _cargandoTipos
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onFieldSubmitted: (_) => _cargarTipos(),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa el código del conjunto'
                      : null,
                ),
                const SizedBox(height: 8),

                if (_tiposRaiz.isEmpty && !_cargandoTipos)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _cargarTipos,
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('Buscar conjunto'),
                    ),
                  ),

                if (_tiposRaiz.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Tu propiedad (opcional)',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<TipoPropiedadNodo>(
                    value: _tipoRaizSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de propiedad',
                      prefixIcon: Icon(Icons.home_work_outlined),
                    ),
                    items: _tiposRaiz
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.nombre),
                            ))
                        .toList(),
                    onChanged: _onTipoRaizChanged,
                  ),

                  for (int i = 0; i < _nivelesActivos.length; i++) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pathCtrlList[i],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: _nivelesActivos[i].nombre,
                        hintText: _nivelesActivos[i].descripcion,
                        prefixIcon: const Icon(Icons.label_outline),
                      ),
                      onFieldSubmitted: (_) => _onNivelLlenado(i),
                      onChanged: (_) {
                        if (_pathCtrlList[i].text.trim().isNotEmpty) {
                          _onNivelLlenado(i);
                        }
                      },
                    ),
                  ],
                ],

                const SizedBox(height: 16),

                TextFormField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _cargando ? null : _registrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: _cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Enviar solicitud',
                          style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
