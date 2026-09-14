import 'package:flutter/material.dart';
import '../../cartera/models/estado_cartera_config_model.dart';

/// Lo que devuelve el diálogo de aviso.
class DatosAviso {
  /// Fase elegida. Null cuando el envío usa la fase vigente de cada propiedad.
  final EstadoCarteraConfig? fase;
  final String mensaje;

  const DatosAviso({this.fase, required this.mensaje});
}

/// Diálogo único para redactar un aviso de cobranza.
///
/// Sirve a los tres envíos —uno, la selección, o una fase completa— porque el
/// texto y las advertencias son los mismos; solo cambia el destinatario, que
/// llega en [descripcion]. Con [fases] no vacío muestra además el selector de
/// fase (envío masivo por fase).
class AvisoCobranzaDialog extends StatefulWidget {
  final String titulo;
  final String descripcion;
  final List<EstadoCarteraConfig> fases;

  const AvisoCobranzaDialog({
    super.key,
    required this.titulo,
    required this.descripcion,
    this.fases = const [],
  });

  /// Límite del backend: el aviso se guarda truncado a 500 caracteres.
  static const int maxMensaje = 500;

  static Future<DatosAviso?> mostrar(
    BuildContext context, {
    required String titulo,
    required String descripcion,
    List<EstadoCarteraConfig> fases = const [],
  }) =>
      showDialog<DatosAviso>(
        context: context,
        builder: (_) => AvisoCobranzaDialog(
          titulo: titulo,
          descripcion: descripcion,
          fases: fases,
        ),
      );

  @override
  State<AvisoCobranzaDialog> createState() => _AvisoCobranzaDialogState();
}

class _AvisoCobranzaDialogState extends State<AvisoCobranzaDialog> {
  final _ctrl = TextEditingController();
  EstadoCarteraConfig? _fase;

  @override
  void initState() {
    super.initState();
    if (widget.fases.isNotEmpty) _fase = widget.fases.first;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _puedeEnviar => widget.fases.isEmpty || _fase != null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.titulo),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.descripcion,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            if (widget.fases.isNotEmpty) ...[
              const SizedBox(height: 14),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fase de cartera',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: DropdownButton<EstadoCarteraConfig>(
                  value: _fase,
                  isExpanded: true,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: widget.fases
                      .map((f) => DropdownMenuItem(value: f, child: Text(f.nombre)))
                      .toList(),
                  onChanged: (v) => setState(() => _fase = v),
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              maxLines: 3,
              maxLength: AvisoCobranzaDialog.maxMensaje,
              decoration: const InputDecoration(
                labelText: 'Mensaje (opcional)',
                hintText: 'Si lo dejas vacío se usa el texto de la fase',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _puedeEnviar
              ? () => Navigator.pop(
                    context,
                    DatosAviso(fase: _fase, mensaje: _ctrl.text.trim()),
                  )
              : null,
          icon: const Icon(Icons.send, size: 18),
          label: const Text('Enviar'),
        ),
      ],
    );
  }
}
