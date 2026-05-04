import 'package:flutter/material.dart';

/// Diálogo de confirmación reutilizable con título, mensaje y acciones.
class ConfirmDialog extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final String textoConfirmar;
  final String textoCancelar;
  final Color? colorConfirmar;

  const ConfirmDialog({
    super.key,
    required this.titulo,
    required this.mensaje,
    this.textoConfirmar = 'Confirmar',
    this.textoCancelar = 'Cancelar',
    this.colorConfirmar,
  });

  /// Muestra el diálogo y retorna true si el usuario confirma.
  static Future<bool> mostrar({
    required BuildContext context,
    required String titulo,
    required String mensaje,
    String textoConfirmar = 'Confirmar',
    String textoCancelar = 'Cancelar',
    Color? colorConfirmar,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        titulo: titulo,
        mensaje: mensaje,
        textoConfirmar: textoConfirmar,
        textoCancelar: textoCancelar,
        colorConfirmar: colorConfirmar,
      ),
    );
    return resultado ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(textoCancelar),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: colorConfirmar != null
              ? FilledButton.styleFrom(backgroundColor: colorConfirmar)
              : null,
          child: Text(textoConfirmar),
        ),
      ],
    );
  }
}
