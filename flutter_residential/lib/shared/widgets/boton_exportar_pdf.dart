import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/platform/archivo.dart';

/// Acción de AppBar que exporta un PDF: lo genera y, según la plataforma, lo
/// abre o lo comparte.
///
/// No sabe qué documento genera: recibe [generar] y el nombre del archivo, así
/// sirve para cualquier pantalla (acuerdos, estados de cuenta, recibos…).
///
/// - Móvil: menú con "Ver PDF" (app nativa, desde ahí se guarda) y
///   "Compartir PDF" (hoja de compartir: WhatsApp, correo, Drive…).
/// - Web: no hay hoja de compartir, las dos acciones son una descarga, así que
///   se muestra un solo botón.
class BotonExportarPdf extends StatefulWidget {
  final Future<Uint8List> Function() generar;
  final String nombreArchivo;

  /// Mensaje que acompaña el archivo al compartirlo.
  final String? textoCompartir;

  const BotonExportarPdf({
    super.key,
    required this.generar,
    required this.nombreArchivo,
    this.textoCompartir,
  });

  @override
  State<BotonExportarPdf> createState() => _BotonExportarPdfState();
}

enum _AccionPdf { ver, compartir }

class _BotonExportarPdfState extends State<BotonExportarPdf> {
  bool _generando = false;

  Future<void> _ejecutar(_AccionPdf accion) async {
    if (_generando) return;
    setState(() => _generando = true);
    try {
      final bytes = await widget.generar();
      if (accion == _AccionPdf.compartir) {
        await guardarYCompartir(bytes, widget.nombreArchivo,
            texto: widget.textoCompartir);
      } else {
        await guardarYAbrir(bytes, widget.nombreArchivo);
      }
    } catch (e) {
      debugPrint('BotonExportarPdf: $e');
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('No se pudo exportar el PDF'),
        autoCloseDuration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_generando) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (kIsWeb) {
      return IconButton(
        tooltip: 'Descargar PDF',
        icon: const Icon(Icons.picture_as_pdf_outlined),
        onPressed: () => _ejecutar(_AccionPdf.ver),
      );
    }

    return PopupMenuButton<_AccionPdf>(
      tooltip: 'Exportar PDF',
      icon: const Icon(Icons.picture_as_pdf_outlined),
      onSelected: _ejecutar,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _AccionPdf.ver,
          child: _ItemMenu(Icons.visibility_outlined, 'Ver PDF'),
        ),
        PopupMenuItem(
          value: _AccionPdf.compartir,
          child: _ItemMenu(Icons.share_outlined, 'Compartir PDF'),
        ),
      ],
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _ItemMenu(this.icono, this.texto);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icono, size: 18),
          const SizedBox(width: 8),
          Text(texto),
        ],
      );
}
