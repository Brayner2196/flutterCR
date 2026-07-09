/// Acta de reunión del consejo generada por voz (Whisper en el backend).
class ActaModel {
  final int id;
  final String titulo;
  final String? fechaReunion; // instante ISO (UTC) — formatear con DateFormatter
  final String estado; // PROCESANDO | BORRADOR | FINALIZADA | ERROR
  final String? transcripcion;
  final String? contenido;
  final int? duracionSegundos;
  final int? creadoPorUsuarioId;
  final String? creadoPorNombre;
  final String? errorMensaje;
  final String? finalizadaEn;
  final String? creadoEn;

  const ActaModel({
    required this.id,
    required this.titulo,
    this.fechaReunion,
    required this.estado,
    this.transcripcion,
    this.contenido,
    this.duracionSegundos,
    this.creadoPorUsuarioId,
    this.creadoPorNombre,
    this.errorMensaje,
    this.finalizadaEn,
    this.creadoEn,
  });

  factory ActaModel.fromJson(Map<String, dynamic> json) {
    return ActaModel(
      id: (json['id'] as num).toInt(),
      titulo: json['titulo'] as String? ?? '',
      fechaReunion: json['fechaReunion'] as String?,
      estado: json['estado'] as String? ?? 'PROCESANDO',
      transcripcion: json['transcripcion'] as String?,
      contenido: json['contenido'] as String?,
      duracionSegundos: (json['duracionSegundos'] as num?)?.toInt(),
      creadoPorUsuarioId: (json['creadoPorUsuarioId'] as num?)?.toInt(),
      creadoPorNombre: json['creadoPorNombre'] as String?,
      errorMensaje: json['errorMensaje'] as String?,
      finalizadaEn: json['finalizadaEn'] as String?,
      creadoEn: json['creadoEn'] as String?,
    );
  }

  bool get esProcesando => estado == 'PROCESANDO';
  bool get esBorrador => estado == 'BORRADOR';
  bool get esFinalizada => estado == 'FINALIZADA';
  bool get esError => estado == 'ERROR';

  /// Duración legible: "1 h 05 min" | "12 min" | "45 s".
  String get duracionLegible {
    final s = duracionSegundos ?? 0;
    if (s <= 0) return '—';
    if (s < 60) return '$s s';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '$h h ${m.toString().padLeft(2, '0')} min';
    return '$m min';
  }
}
