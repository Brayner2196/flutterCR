import 'package:flutter/material.dart';

/// Diálogo de confirmación para acciones irreversibles.
///
/// El botón de acción solo se habilita cuando el usuario escribe [textoEsperado]
/// exactamente. Es el patrón de GitHub para borrar un repositorio: obliga a
/// leer QUÉ se está por destruir, en vez de confirmar por reflejo.
///
/// Es genérico a propósito — no sabe nada de conjuntos ni de módulos — para
/// poder reutilizarlo en cualquier acción destructiva de la app.
///
/// ```dart
/// final ok = await ConfirmacionDestructivaDialog.mostrar(
///   context,
///   titulo: 'Eliminar conjunto',
///   mensaje: 'Se borrará el conjunto y todos sus datos.',
///   consecuencias: ['Se pierden los cobros', 'Se pierden los usuarios'],
///   textoEsperado: tenant.codigo,
///   etiquetaBoton: 'Eliminar definitivamente',
/// );
/// if (ok == true) { ... }
/// ```
class ConfirmacionDestructivaDialog extends StatefulWidget {
  final String titulo;
  final String mensaje;

  /// Lista de lo que se pierde. Se pinta como viñetas para que se lea de un
  /// vistazo en vez de esconderse en un párrafo.
  final List<String> consecuencias;

  /// Lo que se pierde NO: tranquiliza y evita cancelaciones por las dudas.
  final List<String> conservado;

  /// Texto exacto que hay que escribir para habilitar el botón.
  final String textoEsperado;

  final String etiquetaBoton;

  const ConfirmacionDestructivaDialog({
    super.key,
    required this.titulo,
    required this.mensaje,
    required this.textoEsperado,
    required this.etiquetaBoton,
    this.consecuencias = const [],
    this.conservado = const [],
  });

  /// Abre el diálogo. Devuelve `true` solo si el usuario confirmó.
  static Future<bool?> mostrar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    required String textoEsperado,
    required String etiquetaBoton,
    List<String> consecuencias = const [],
    List<String> conservado = const [],
  }) {
    return showDialog<bool>(
      context: context,
      // No se cierra tocando fuera: es una acción que no se deshace.
      barrierDismissible: false,
      builder: (_) => ConfirmacionDestructivaDialog(
        titulo: titulo,
        mensaje: mensaje,
        textoEsperado: textoEsperado,
        etiquetaBoton: etiquetaBoton,
        consecuencias: consecuencias,
        conservado: conservado,
      ),
    );
  }

  @override
  State<ConfirmacionDestructivaDialog> createState() =>
      _ConfirmacionDestructivaDialogState();
}

class _ConfirmacionDestructivaDialogState
    extends State<ConfirmacionDestructivaDialog> {
  final _ctrl = TextEditingController();
  bool _coincide = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final ok = _ctrl.text.trim() == widget.textoEsperado;
      if (ok != _coincide) setState(() => _coincide = ok);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: cs.error, size: 32),
      title: Text(widget.titulo),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.mensaje, style: theme.textTheme.bodyMedium),

            if (widget.consecuencias.isNotEmpty) ...[
              const SizedBox(height: 14),
              _Bloque(
                titulo: 'Se pierde',
                icono: Icons.close_rounded,
                color: cs.error,
                items: widget.consecuencias,
              ),
            ],

            if (widget.conservado.isNotEmpty) ...[
              const SizedBox(height: 10),
              _Bloque(
                titulo: 'Se conserva',
                icono: Icons.check_rounded,
                color: cs.primary,
                items: widget.conservado,
              ),
            ],

            const SizedBox(height: 18),
            Text.rich(
              TextSpan(
                style: theme.textTheme.bodySmall,
                children: [
                  const TextSpan(text: 'Para confirmar, escribe '),
                  TextSpan(
                    text: widget.textoEsperado,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                hintText: widget.textoEsperado,
                suffixIcon: _coincide
                    ? Icon(Icons.check_circle, color: cs.primary)
                    : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
          ),
          onPressed: _coincide ? () => Navigator.pop(context, true) : null,
          child: Text(widget.etiquetaBoton),
        ),
      ],
    );
  }
}

/// Lista con viñetas de una sola línea cada una.
class _Bloque extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final List<String> items;

  const _Bloque({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icono, size: 14, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(item, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
