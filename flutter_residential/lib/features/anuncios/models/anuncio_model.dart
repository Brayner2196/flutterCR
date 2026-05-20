class AnuncioModel {
  final int id;
  final String titulo;
  final String contenido;
  final String estado;
  final int creadoPor;
  final String? creadoPorNombre;
  final String? fechaInicio;
  final String? fechaFin;
  final String? creadoEn;
  final int totalVistas;
  final bool vistoPorMi;

  AnuncioModel({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.estado,
    required this.creadoPor,
    this.creadoPorNombre,
    this.fechaInicio,
    this.fechaFin,
    this.creadoEn,
    required this.totalVistas,
    required this.vistoPorMi,
  });

  factory AnuncioModel.fromJson(Map<String, dynamic> json) => AnuncioModel(
        id: json['id'],
        titulo: json['titulo'] ?? '',
        contenido: json['contenido'] ?? '',
        estado: json['estado'] ?? 'ACTIVO',
        creadoPor: json['creadoPor'] ?? 0,
        creadoPorNombre: json['creadoPorNombre'],
        fechaInicio: json['fechaInicio'],
        fechaFin: json['fechaFin'],
        creadoEn: json['creadoEn'],
        totalVistas: json['totalVistas'] ?? 0,
        vistoPorMi: json['vistoPorMi'] ?? false,
      );

  AnuncioModel copyWith({bool? vistoPorMi, int? totalVistas}) => AnuncioModel(
        id: id,
        titulo: titulo,
        contenido: contenido,
        estado: estado,
        creadoPor: creadoPor,
        creadoPorNombre: creadoPorNombre,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        creadoEn: creadoEn,
        totalVistas: totalVistas ?? this.totalVistas,
        vistoPorMi: vistoPorMi ?? this.vistoPorMi,
      );
}

class AnuncioVistaModel {
  final int residenteId;
  final String residenteNombre;
  final String vistoEn;

  AnuncioVistaModel({
    required this.residenteId,
    required this.residenteNombre,
    required this.vistoEn,
  });

  factory AnuncioVistaModel.fromJson(Map<String, dynamic> json) =>
      AnuncioVistaModel(
        residenteId: json['residenteId'],
        residenteNombre: json['residenteNombre'] ?? '',
        vistoEn: json['vistoEn'] ?? '',
      );
}
