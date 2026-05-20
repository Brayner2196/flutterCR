import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/anuncio_model.dart';
import '../../providers/anuncio_provider.dart';

class AdminCrearAnuncioScreen extends StatefulWidget {
  final AnuncioModel? anuncioEditar;
  const AdminCrearAnuncioScreen({super.key, this.anuncioEditar});

  @override
  State<AdminCrearAnuncioScreen> createState() => _AdminCrearAnuncioScreenState();
}

class _AdminCrearAnuncioScreenState extends State<AdminCrearAnuncioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _contenidoCtrl = TextEditingController();
  bool _guardando = false;

  bool get _esEdicion => widget.anuncioEditar != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      final a = widget.anuncioEditar!;
      _tituloCtrl.text = a.titulo;
      _contenidoCtrl.text = a.contenido;
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _contenidoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar anuncio' : 'Nuevo anuncio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  hintText: 'Ej: Mantenimiento del sábado',
                  border: OutlineInputBorder(),
                ),
                maxLength: 200,
                validator: (v) => (v == null || v.isEmpty) ? 'El título es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contenidoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contenido *',
                  hintText: 'Descripción completa del anuncio...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                maxLength: 4000,
                validator: (v) => (v == null || v.isEmpty) ? 'El contenido es obligatorio' : null,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: Text(_esEdicion ? 'Guardar cambios' : 'Publicar anuncio'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final body = {
        'titulo': _tituloCtrl.text.trim(),
        'contenido': _contenidoCtrl.text.trim(),
      };
      final provider = context.read<AnuncioProvider>();
      if (_esEdicion) {
        await provider.actualizar(widget.anuncioEditar!.id, body);
      } else {
        await provider.crear(body);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}
