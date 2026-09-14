import '../../pagos/models/aviso_cobranza_resultado.dart';

/// Resumen legible de un envío de avisos (individual, por selección o por fase).
///
/// El backend devuelve una fila por propiedad; la UI necesita una frase. Esta
/// clase hace esa traducción una sola vez, para que ninguna pantalla vuelva a
/// contar a mano ni invente un mensaje distinto.
class AvisoLoteResumen {
  final int propiedadesNotificadas;
  final int residentesNotificados;
  final int sinResidentes;
  final int sinDeuda;

  const AvisoLoteResumen({
    required this.propiedadesNotificadas,
    required this.residentesNotificados,
    required this.sinResidentes,
    required this.sinDeuda,
  });

  factory AvisoLoteResumen.de(List<AvisoCobranzaResultado> resultados) {
    var propiedades = 0, residentes = 0, sinRes = 0, sinDeu = 0;
    for (final r in resultados) {
      if (r.enviado) {
        propiedades++;
        residentes += r.usuariosNotificados;
      } else if (r.motivo == 'SIN_DEUDA') {
        sinDeu++;
      } else {
        sinRes++;
      }
    }
    return AvisoLoteResumen(
      propiedadesNotificadas: propiedades,
      residentesNotificados: residentes,
      sinResidentes: sinRes,
      sinDeuda: sinDeu,
    );
  }

  bool get algunoEnviado => propiedadesNotificadas > 0;

  /// Frase para el snack: qué salió y, si algo no salió, por qué.
  String get mensaje {
    if (!algunoEnviado) {
      if (sinDeuda > 0 && sinResidentes == 0) {
        return 'No se envió: la deuda ya fue pagada o exonerada';
      }
      return 'No se envió: ninguna propiedad tiene residentes con la app';
    }
    final base = 'Aviso enviado a $propiedadesNotificadas '
        '${propiedadesNotificadas == 1 ? 'propiedad' : 'propiedades'} '
        '($residentesNotificados ${residentesNotificados == 1 ? 'residente' : 'residentes'})';
    final omitidas = <String>[
      if (sinDeuda > 0) '$sinDeuda sin deuda vigente',
      if (sinResidentes > 0) '$sinResidentes sin residentes con la app',
    ];
    return omitidas.isEmpty ? base : '$base · Omitidas: ${omitidas.join(', ')}';
  }
}
