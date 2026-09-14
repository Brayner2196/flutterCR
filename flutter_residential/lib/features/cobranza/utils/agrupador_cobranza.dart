import '../models/cobro_cobranza_model.dart';

/// Un mes de cartera con sus cobros y totales ya calculados.
class GrupoMesCobranza {
  final int anio;
  final int mes;
  final List<CobroCobranzaModel> cobros;

  const GrupoMesCobranza({
    required this.anio,
    required this.mes,
    required this.cobros,
  });

  static const _meses = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  static const _mesesAbrev = [
    '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  /// Clave estable del grupo: '2026-09'. Sirve de valor de filtro.
  String get clave => AgrupadorCobranza.clave(anio, mes);

  bool get sinPeriodo => mes == 0;
  String get nombre => sinPeriodo ? 'Sin período' : '${_meses[mes]} $anio';
  String get nombreCorto => sinPeriodo ? 'Otros' : '${_mesesAbrev[mes]} $anio';

  int get cantidad => cobros.length;
  int get vencidos => cobros.where((c) => c.vencido).length;
  double get totalPendiente =>
      cobros.fold<double>(0, (s, c) => s + c.montoPendiente);
  double get totalMora => cobros.fold<double>(0, (s, c) => s + c.montoMora);
  Set<int> get propiedades => cobros.map((c) => c.propiedadId).toSet();
}

/// Agrupación de cartera por mes. Función pura y sin dependencias de UI: la
/// usan la barra de meses, los encabezados de la lista y las métricas, y así
/// el criterio de "a qué mes pertenece un cobro" está escrito una sola vez.
class AgrupadorCobranza {
  AgrupadorCobranza._();

  static String clave(int anio, int mes) =>
      '$anio-${mes.toString().padLeft(2, '0')}';

  /// Grupos del mes más reciente al más antiguo. Los cobros sin período ni
  /// fecha (caso defensivo) caen en un grupo "Sin período" al final.
  static List<GrupoMesCobranza> porMes(List<CobroCobranzaModel> cobros) {
    final mapa = <String, List<CobroCobranzaModel>>{};
    for (final c in cobros) {
      mapa.putIfAbsent(clave(c.anioAgrupacion, c.mesAgrupacion), () => []).add(c);
    }
    final grupos = mapa.entries.map((e) {
      final partes = e.key.split('-');
      return GrupoMesCobranza(
        anio: int.parse(partes[0]),
        mes: int.parse(partes[1]),
        cobros: e.value,
      );
    }).toList();

    grupos.sort((a, b) {
      final porAnio = b.anio.compareTo(a.anio);
      return porAnio != 0 ? porAnio : b.mes.compareTo(a.mes);
    });
    return grupos;
  }
}
