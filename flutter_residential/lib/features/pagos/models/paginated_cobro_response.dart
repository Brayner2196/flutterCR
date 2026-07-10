import 'cobro_model.dart';

/// Wrapper del Page'CobroResponse' que devuelve Spring Data.
class PaginatedCobroResponse {
  final List<CobroModel> content;
  final int totalElements;
  final int totalPages;
  final bool last;
  final int number; // página actual (0-based)
  final int size;

  const PaginatedCobroResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.last,
    required this.number,
    required this.size,
  });

  bool get hayMasPaginas => !last;

  factory PaginatedCobroResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedCobroResponse(
      content: (json['content'] as List<dynamic>)
          .map((e) => CobroModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      last: json['last'] as bool? ?? true,
      number: json['number'] as int? ?? 0,
      size: json['size'] as int? ?? 5,
    );
  }
}
