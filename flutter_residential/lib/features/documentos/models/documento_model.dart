/// Modelos del módulo Documentos de interés general.

class ArchivoDocumentoModel {
  final int id;
  final String nombreOriginal;
  final String? contentType;
  final String tipo; // PDF | WORD | EXCEL | IMAGEN | VIDEO
  final int? tamanoBytes;
  final String? creadoEn;

  ArchivoDocumentoModel({
    required this.id,
    required this.nombreOriginal,
    this.contentType,
    required this.tipo,
    this.tamanoBytes,
    this.creadoEn,
  });

  factory ArchivoDocumentoModel.fromJson(Map<String, dynamic> json) =>
      ArchivoDocumentoModel(
        id: json['id'],
        nombreOriginal: json['nombreOriginal'] ?? '',
        contentType: json['contentType'],
        tipo: json['tipo'] ?? 'OTROS',
        tamanoBytes: json['tamanoBytes'],
        creadoEn: json['creadoEn'],
      );
}

class DocumentoModel {
  final int id;
  final String titulo;
  final String? descripcion;
  final String categoria; // REGLAMENTO | ACTAS | FINANCIERO | COMUNICADOS | OTROS
  final String estado; // BORRADOR | PUBLICADO
  final int creadoPor;
  final String? creadoEn;
  final String? actualizadoEn;
  final List<ArchivoDocumentoModel> archivos;

  DocumentoModel({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.categoria,
    required this.estado,
    required this.creadoPor,
    this.creadoEn,
    this.actualizadoEn,
    required this.archivos,
  });

  bool get publicado => estado == 'PUBLICADO';
  int get totalArchivos => archivos.length;

  factory DocumentoModel.fromJson(Map<String, dynamic> json) => DocumentoModel(
        id: json['id'],
        titulo: json['titulo'] ?? '',
        descripcion: json['descripcion'],
        categoria: json['categoria'] ?? 'OTROS',
        estado: json['estado'] ?? 'BORRADOR',
        creadoPor: json['creadoPor'] ?? 0,
        creadoEn: json['creadoEn'],
        actualizadoEn: json['actualizadoEn'],
        archivos: (json['archivos'] as List?)
                ?.map((e) =>
                    ArchivoDocumentoModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
