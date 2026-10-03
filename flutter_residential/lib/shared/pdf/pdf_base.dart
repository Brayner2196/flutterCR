import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../theme/app_theme.dart';

/// Kit común para los PDF de la app: tema con la tipografía de la marca, logo,
/// colores y piezas de maquetación que se repiten entre documentos.
///
/// Cada documento (acuerdo de pago, estado de cuenta, recibo…) arma su
/// contenido con estas piezas, así todos los PDF se ven iguales.
///
/// Fuentes y logo se cargan una sola vez y quedan en caché: el primer PDF paga
/// la lectura de los assets y los siguientes salen al instante.
class PdfBase {
  PdfBase._();

  static pw.ThemeData? _tema;

  /// Se cachean los bytes y no el MemoryImage: la imagen embebida pertenece a
  /// un documento, así que cada PDF crea la suya a partir de los mismos bytes.
  static Uint8List? _logoPng;

  /// Ancho en px al que se reduce el logo antes de embeberlo. El PNG original
  /// es de 1254 px (~1 MB): tal cual infla el PDF y tarda en codificarse.
  static const int _anchoLogo = 160;

  // ── Colores: los mismos de AppColors para que el PDF se vea como la app ──

  static final PdfColor primario = color(AppColors.blue);
  static final PdfColor colorTexto = color(AppColors.textHiLight);
  static final PdfColor colorTextoSuave = color(AppColors.textMidLight);
  static final PdfColor colorBorde = color(AppColors.borderLight);
  static final PdfColor colorFondoBarra = color(AppColors.hairlineLight);

  static PdfColor color(ui.Color c) => PdfColor.fromInt(c.toARGB32());

  // ── Recursos ─────────────────────────────────────────────────────────────

  /// Tema con GoogleSans. La Helvetica que trae `pdf` por defecto no soporta
  /// Unicode completo: caracteres como "—" o "·" salen rotos.
  /// Solo regular y bold: cada TTF pesa ~2 MB y no se usa cursiva. En el PDF
  /// solo se embeben los glifos usados, así que el archivo final queda liviano.
  static Future<pw.ThemeData> tema() async {
    return _tema ??= pw.ThemeData.withFont(
      base: await _fuente('GoogleSans-Regular'),
      bold: await _fuente('GoogleSans-Bold'),
    );
  }

  static Future<pw.Font> _fuente(String nombre) async =>
      pw.Font.ttf(await rootBundle.load('assets/fonts/$nombre.ttf'));

  /// Logo de la app reducido a [_anchoLogo] px.
  static Future<pw.MemoryImage> logo() async =>
      pw.MemoryImage(_logoPng ??= await _logoReducido());

  static Future<Uint8List> _logoReducido() async {
    final data = await rootBundle.load('assets/icons/logocr.png');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      targetWidth: _anchoLogo,
    );
    final frame = await codec.getNextFrame();
    final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    if (png == null) throw StateError('No se pudo codificar el logo del PDF');

    return Uint8List.view(png.buffer, png.offsetInBytes, png.lengthInBytes);
  }

  // ── Texto ────────────────────────────────────────────────────────────────

  static pw.TextStyle estilo({
    double tamano = 10,
    bool negrita = false,
    PdfColor? color,
  }) =>
      pw.TextStyle(
        fontSize: tamano,
        fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color ?? colorTexto,
      );

  // ── Estructura de página ─────────────────────────────────────────────────

  /// Encabezado que se repite en cada página: logo, organización, título y
  /// una etiqueta opcional a la derecha (p. ej. el estado del documento).
  static pw.Widget encabezado({
    required pw.MemoryImage logo,
    required String organizacion,
    required String titulo,
    pw.Widget? etiqueta,
  }) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.only(bottom: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: colorBorde)),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Image(logo, width: 34, height: 34),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(organizacion,
                      style: estilo(tamano: 9, color: colorTextoSuave)),
                  pw.SizedBox(height: 2),
                  pw.Text(titulo,
                      style: estilo(tamano: 15, negrita: true, color: primario)),
                ],
              ),
            ),
            if (etiqueta != null) etiqueta,
          ],
        ),
      );

  /// Pie de cada página: una nota a la izquierda y la numeración a la derecha.
  static pw.Widget pie(pw.Context ctx, {required String nota}) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 10),
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: colorBorde)),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(nota,
                  style: estilo(tamano: 8, color: colorTextoSuave)),
            ),
            pw.SizedBox(width: 12),
            pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
                style: estilo(tamano: 8, color: colorTextoSuave)),
          ],
        ),
      );

  // ── Bloques de contenido ─────────────────────────────────────────────────

  static pw.Widget tituloSeccion(String titulo) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
        child: pw.Text(titulo,
            style: estilo(tamano: 11, negrita: true, color: primario)),
      );

  /// Etiqueta de color (estado, categoría…).
  static pw.Widget chip(String texto,
          {required PdfColor fondo, required PdfColor color}) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: pw.BoxDecoration(
          color: fondo,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Text(texto,
            style: estilo(tamano: 9, negrita: true, color: color)),
      );

  /// Caja con borde que agrupa filas de datos.
  static pw.Widget caja(List<pw.Widget> hijos, {PdfColor? fondo}) =>
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: fondo,
          border: pw.Border.all(color: colorBorde),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: hijos,
        ),
      );

  /// Fila "etiqueta ........ valor". Mitad y mitad: los textos largos
  /// (nombres, fechas límite) parten línea en vez de desbordarse.
  static pw.Widget filaDato(
    String etiqueta,
    String valor, {
    bool negrita = false,
    PdfColor? color,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(etiqueta, style: estilo(color: colorTextoSuave)),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Text(valor,
                  textAlign: pw.TextAlign.right,
                  style: estilo(negrita: negrita, color: color)),
            ),
          ],
        ),
      );

  /// Datos en rejilla (etiqueta arriba, valor abajo), dentro de una [caja].
  static pw.Widget rejillaDatos(List<(String, String)> datos,
      {int columnas = 2}) {
    final filas = <pw.Widget>[];
    for (var i = 0; i < datos.length; i += columnas) {
      filas.add(pw.Padding(
        padding: pw.EdgeInsets.only(
            bottom: i + columnas < datos.length ? 8.0 : 0.0),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (var j = i; j < i + columnas; j++)
              pw.Expanded(
                child: j < datos.length
                    ? _datoApilado(datos[j].$1, datos[j].$2)
                    : pw.SizedBox(),
              ),
          ],
        ),
      ));
    }
    return caja(filas);
  }

  static pw.Widget _datoApilado(String etiqueta, String valor) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(etiqueta, style: estilo(tamano: 8, color: colorTextoSuave)),
          pw.SizedBox(height: 2),
          pw.Text(valor, style: estilo(negrita: true)),
        ],
      );

  /// Bloque de texto libre (observaciones, notas, motivos).
  static pw.Widget bloqueTexto(
    String titulo,
    String contenido, {
    PdfColor? fondo,
    PdfColor? colorTitulo,
  }) =>
      pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(top: 8),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: fondo,
          border: pw.Border.all(color: colorBorde),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(titulo,
                style: estilo(
                    tamano: 9,
                    negrita: true,
                    color: colorTitulo ?? colorTextoSuave)),
            pw.SizedBox(height: 3),
            pw.Text(contenido, style: estilo()),
          ],
        ),
      );

  static pw.Widget divisor() =>
      pw.Divider(color: colorBorde, height: 12, thickness: 0.5);

  /// Barra de progreso (0..1).
  static pw.Widget barraProgreso(double valor, {PdfColor? color}) {
    final lleno = (valor.clamp(0, 1) * 1000).round();
    return pw.Container(
      height: 6,
      decoration: pw.BoxDecoration(
        color: colorFondoBarra,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Row(
        children: [
          if (lleno > 0)
            pw.Expanded(
              flex: lleno,
              child: pw.Container(
                height: 6,
                decoration: pw.BoxDecoration(
                  color: color ?? primario,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
              ),
            ),
          if (lleno < 1000) pw.Expanded(flex: 1000 - lleno, child: pw.SizedBox()),
        ],
      ),
    );
  }

  /// Tabla con el encabezado repetido en cada página.
  ///
  /// [alinearDerecha]: índices de columnas numéricas.
  /// [fondoFila]: color de fondo de una fila (p. ej. vencidas) o null.
  static pw.Widget tabla({
    required List<String> encabezados,
    required List<List<String>> filas,
    Map<int, pw.TableColumnWidth>? anchos,
    Set<int> alinearDerecha = const {},
    PdfColor? Function(int fila)? fondoFila,
  }) {
    pw.Widget celda(String texto, int columna, {bool encabezado = false}) =>
        pw.Container(
          alignment: alinearDerecha.contains(columna)
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(
            texto,
            style: encabezado
                ? estilo(tamano: 9, negrita: true, color: PdfColors.white)
                : estilo(tamano: 9),
          ),
        );

    pw.TableRow filaTabla(int f) {
      final fondo = fondoFila?.call(f);
      return pw.TableRow(
        decoration: fondo == null ? null : pw.BoxDecoration(color: fondo),
        children: [
          for (var c = 0; c < filas[f].length; c++) celda(filas[f][c], c),
        ],
      );
    }

    return pw.Table(
      columnWidths: anchos,
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: colorBorde, width: 0.5),
        bottom: pw.BorderSide(color: colorBorde, width: 0.5),
      ),
      children: [
        pw.TableRow(
          repeat: true,
          decoration: pw.BoxDecoration(color: primario),
          children: [
            for (var c = 0; c < encabezados.length; c++)
              celda(encabezados[c], c, encabezado: true),
          ],
        ),
        for (var f = 0; f < filas.length; f++) filaTabla(f),
      ],
    );
  }
}
