/// Estado de cartera vigente de una propiedad (snapshot), para pintar badges.
class EstadoCarteraVigente {
  final int propiedadId;
  final String? estadoCodigo;
  final String? estadoNombre;
  final String? color;
  final bool esPositivo;
  final int diasVencidoMax;
  final double montoAdeudado;

  EstadoCarteraVigente({
    required this.propiedadId,
    this.estadoCodigo,
    this.estadoNombre,
    this.color,
    this.esPositivo = false,
    this.diasVencidoMax = 0,
    this.montoAdeudado = 0,
  });

  factory EstadoCarteraVigente.fromJson(Map<String, dynamic> j) => EstadoCarteraVigente(
        propiedadId: j['propiedadId'] as int,
        estadoCodigo: j['estadoCodigo'],
        estadoNombre: j['estadoNombre'],
        color: j['color'],
        esPositivo: j['esPositivo'] ?? false,
        diasVencidoMax: j['diasVencidoMax'] ?? 0,
        montoAdeudado: (j['montoAdeudado'] as num?)?.toDouble() ?? 0,
      );

  bool get tieneEstado => estadoNombre != null && estadoNombre!.isNotEmpty;
}
