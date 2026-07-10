/// Estadísticas agregadas del consejo para un rango de fechas.
class ConsejoEstadisticasModel {
  final String desde;
  final String hasta;

  // PQRs
  final int pqrTotal;
  final Map<String, int> pqrPorEstado;
  final Map<String, int> pqrPorTipo;
  final int pqrResueltas;
  final double? pqrTiempoPromRespuestaHoras;

  // Anuncios
  final int anuncioTotal;
  final int anuncioActivos;
  final int anuncioTotalVistas;

  // Votaciones
  final int votacionTotal;
  final Map<String, int> votacionPorEstado;
  final int votacionParticipantes;

  const ConsejoEstadisticasModel({
    required this.desde,
    required this.hasta,
    required this.pqrTotal,
    required this.pqrPorEstado,
    required this.pqrPorTipo,
    required this.pqrResueltas,
    this.pqrTiempoPromRespuestaHoras,
    required this.anuncioTotal,
    required this.anuncioActivos,
    required this.anuncioTotalVistas,
    required this.votacionTotal,
    required this.votacionPorEstado,
    required this.votacionParticipantes,
  });

  factory ConsejoEstadisticasModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> toIntMap(dynamic raw) {
      if (raw == null) return {};
      return (raw as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toInt()));
    }

    return ConsejoEstadisticasModel(
      desde: json['desde'] as String? ?? '',
      hasta: json['hasta'] as String? ?? '',
      pqrTotal: (json['pqrTotal'] as num?)?.toInt() ?? 0,
      pqrPorEstado: toIntMap(json['pqrPorEstado']),
      pqrPorTipo: toIntMap(json['pqrPorTipo']),
      pqrResueltas: (json['pqrResueltas'] as num?)?.toInt() ?? 0,
      pqrTiempoPromRespuestaHoras: (json['pqrTiempoPromRespuestaHoras'] as num?)?.toDouble(),
      anuncioTotal: (json['anuncioTotal'] as num?)?.toInt() ?? 0,
      anuncioActivos: (json['anuncioActivos'] as num?)?.toInt() ?? 0,
      anuncioTotalVistas: (json['anuncioTotalVistas'] as num?)?.toInt() ?? 0,
      votacionTotal: (json['votacionTotal'] as num?)?.toInt() ?? 0,
      votacionPorEstado: toIntMap(json['votacionPorEstado']),
      votacionParticipantes: (json['votacionParticipantes'] as num?)?.toInt() ?? 0,
    );
  }

  /// Tasa de resolución de PQRs (0.0 – 1.0)
  double get tasaResolucionPqr =>
      pqrTotal == 0 ? 0.0 : pqrResueltas / pqrTotal;

  /// Pendientes = RADICADA + EN_PROCESO
  int get pqrPendientes =>
      (pqrPorEstado['RADICADA'] ?? 0) + (pqrPorEstado['EN_PROCESO'] ?? 0);

  /// Votaciones abiertas actualmente (estado ABIERTA)
  int get votacionesAbiertas => votacionPorEstado['ABIERTA'] ?? 0;
}
