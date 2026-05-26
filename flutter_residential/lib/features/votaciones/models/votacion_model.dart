class OpcionVotacionModel {
  final int id;
  final String texto;
  final int orden;
  final int totalVotos;

  OpcionVotacionModel({
    required this.id,
    required this.texto,
    required this.orden,
    required this.totalVotos,
  });

  factory OpcionVotacionModel.fromJson(Map<String, dynamic> json) =>
      OpcionVotacionModel(
        id: json['id'],
        texto: json['texto'] ?? '',
        orden: json['orden'] ?? 0,
        totalVotos: json['totalVotos'] ?? 0,
      );
}

class VotoResidenteModel {
  final int residenteId;
  final String residenteNombre;
  final int? opcionId;
  final int? valorNumerico;
  final String? respuestaTexto;
  final String? votadoEn;

  VotoResidenteModel({
    required this.residenteId,
    required this.residenteNombre,
    this.opcionId,
    this.valorNumerico,
    this.respuestaTexto,
    this.votadoEn,
  });

  factory VotoResidenteModel.fromJson(Map<String, dynamic> json) =>
      VotoResidenteModel(
        residenteId: json['residenteId'],
        residenteNombre: json['residenteNombre'] ?? '',
        opcionId: json['opcionId'],
        valorNumerico: json['valorNumerico'],
        respuestaTexto: json['respuestaTexto'],
        votadoEn: json['votadoEn'],
      );
}

class VotacionModel {
  final int id;
  final String titulo;
  final String? descripcion;
  final String tipoVotacion; // OPCION_UNICA | OPCION_MULTIPLE | ESCALA_NUMERICA | TEXTO_LIBRE
  final String estado;
  final int? escalaMax;
  final bool mostrarVotantes;
  final bool permiteCambiarVoto;
  final String? fechaInicio;
  final String? fechaFin;
  final String? creadoEn;
  final int? creadoPor;
  final int totalVotantes;
  final bool yaVote;
  final List<OpcionVotacionModel> opciones;
  final List<VotoResidenteModel>? votantes;

  /// IDs de opciones que el usuario actual ya seleccionó (viene del backend).
  final List<int> miVotoOpcionIds;

  /// Valor numérico que el usuario votó en escalas (viene del backend).
  final int? miVotoValorNumerico;

  /// Texto libre que el usuario escribió (viene del backend).
  final String? miVotoRespuestaTexto;

  /// Si los propietarios/inquilinos pueden ver el porcentaje de votos por opción.
  final bool mostrarPorcentajes;

  VotacionModel({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.tipoVotacion,
    required this.estado,
    this.escalaMax,
    required this.mostrarVotantes,
    required this.permiteCambiarVoto,
    this.fechaInicio,
    this.fechaFin,
    this.creadoEn,
    this.creadoPor,
    required this.totalVotantes,
    required this.yaVote,
    required this.opciones,
    this.votantes,
    this.miVotoOpcionIds = const [],
    this.miVotoValorNumerico,
    this.miVotoRespuestaTexto,
    this.mostrarPorcentajes = false,
  });

  factory VotacionModel.fromJson(Map<String, dynamic> json) => VotacionModel(
        id: json['id'],
        titulo: json['titulo'] ?? '',
        descripcion: json['descripcion'],
        tipoVotacion: json['tipoVotacion'] ?? 'OPCION_UNICA',
        estado: json['estado'] ?? 'BORRADOR',
        escalaMax: json['escalaMax'],
        mostrarVotantes: json['mostrarVotantes'] ?? false,
        permiteCambiarVoto: json['permiteCambiarVoto'] ?? false,
        fechaInicio: json['fechaInicio'],
        fechaFin: json['fechaFin'],
        creadoEn: json['creadoEn'],
        creadoPor: json['creadoPor'],
        totalVotantes: json['totalVotantes'] ?? 0,
        yaVote: json['yaVote'] ?? false,
        opciones: (json['opciones'] as List<dynamic>? ?? [])
            .map((o) => OpcionVotacionModel.fromJson(o))
            .toList(),
        votantes: json['votantes'] != null
            ? (json['votantes'] as List<dynamic>)
                .map((v) => VotoResidenteModel.fromJson(v))
                .toList()
            : null,
        miVotoOpcionIds: (json['miVotoOpcionIds'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
        miVotoValorNumerico: json['miVotoValorNumerico'] != null
            ? (json['miVotoValorNumerico'] as num).toInt()
            : null,
        miVotoRespuestaTexto: json['miVotoRespuestaTexto'] as String?,
        mostrarPorcentajes: json['mostrarPorcentajes'] as bool? ?? false,
      );
}
