class PropiedadOpcionModel {
  final int id;
  final String identificador;

  const PropiedadOpcionModel({required this.id, required this.identificador});

  factory PropiedadOpcionModel.fromJson(Map<String, dynamic> json) =>
      PropiedadOpcionModel(
        id: (json['id'] as num).toInt(),
        identificador: json['identificador'] as String? ?? '',
      );
}
