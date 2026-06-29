class PropiedadOpcionModel {
  final int id;
  final String identificador;
  final String? pathCorto;

  const PropiedadOpcionModel({
    required this.id,
    required this.identificador,
    this.pathCorto,
  });

  /// Texto a mostrar en el selector: prioriza el path corto (p. ej. "A101").
  String get etiqueta =>
      (pathCorto != null && pathCorto!.isNotEmpty) ? pathCorto! : identificador;

  factory PropiedadOpcionModel.fromJson(Map<String, dynamic> json) =>
      PropiedadOpcionModel(
        id: (json['id'] as num).toInt(),
        identificador: json['identificador'] as String? ?? '',
        pathCorto: json['pathCorto'] as String?,
      );
}

/// Página de propiedades para el selector con buscador/paginación.
class PropiedadOpcionPage {
  final List<PropiedadOpcionModel> content;
  final int page;
  final int totalPages;
  final bool last;

  const PropiedadOpcionPage({
    required this.content,
    required this.page,
    required this.totalPages,
    required this.last,
  });

  factory PropiedadOpcionPage.fromJson(Map<String, dynamic> json) =>
      PropiedadOpcionPage(
        content: (json['content'] as List? ?? [])
            .map((e) => PropiedadOpcionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: (json['page'] as num?)?.toInt() ?? 0,
        totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
        last: json['last'] as bool? ?? true,
      );
}
