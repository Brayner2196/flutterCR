/// Motivo por el que la propiedad no puede pedir un acuerdo.
///
/// El código es lo que decide en la app (qué mostrar, qué acción ofrecer); el
/// mensaje es solo el texto ya redactado por el backend, para no mantener la
/// misma redacción en dos sitios.
class MotivoNoElegibleModel {
  final String codigo;
  final String mensaje;

  const MotivoNoElegibleModel({required this.codigo, required this.mensaje});

  factory MotivoNoElegibleModel.fromJson(Map<String, dynamic> json) =>
      MotivoNoElegibleModel(
        codigo: json['codigo'] as String? ?? 'DESCONOCIDO',
        mensaje: json['mensaje'] as String? ?? '',
      );
}

/// Respuesta de "¿puedo pedir un acuerdo de pago?".
class ElegibilidadAcuerdoModel {
  final bool elegible;
  final List<MotivoNoElegibleModel> motivos;
  final double montoDeudaElegible;
  final int cantidadCobros;
  final int diasMoraMaxima;
  final int maxCuotas;
  final double porcentajeAbonoInicial;
  final bool requiereAprobacion;
  final int? acuerdoVigenteId;
  final String? estadoAcuerdoVigente;

  const ElegibilidadAcuerdoModel({
    required this.elegible,
    required this.motivos,
    required this.montoDeudaElegible,
    required this.cantidadCobros,
    required this.diasMoraMaxima,
    required this.maxCuotas,
    required this.porcentajeAbonoInicial,
    required this.requiereAprobacion,
    this.acuerdoVigenteId,
    this.estadoAcuerdoVigente,
  });

  factory ElegibilidadAcuerdoModel.fromJson(Map<String, dynamic> json) =>
      ElegibilidadAcuerdoModel(
        elegible: json['elegible'] as bool? ?? false,
        motivos: (json['motivos'] as List<dynamic>? ?? [])
            .map((e) => MotivoNoElegibleModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        montoDeudaElegible:
            (json['montoDeudaElegible'] as num? ?? 0).toDouble(),
        cantidadCobros: json['cantidadCobros'] as int? ?? 0,
        diasMoraMaxima: json['diasMoraMaxima'] as int? ?? 0,
        maxCuotas: json['maxCuotas'] as int? ?? 0,
        porcentajeAbonoInicial:
            (json['porcentajeAbonoInicial'] as num? ?? 0).toDouble(),
        requiereAprobacion: json['requiereAprobacion'] as bool? ?? true,
        acuerdoVigenteId: json['acuerdoVigenteId'] as int?,
        estadoAcuerdoVigente: json['estadoAcuerdoVigente'] as String?,
      );

  /// Sin evaluar todavía: se usa como estado inicial del provider.
  static const desconocida = ElegibilidadAcuerdoModel(
    elegible: false,
    motivos: [],
    montoDeudaElegible: 0,
    cantidadCobros: 0,
    diasMoraMaxima: 0,
    maxCuotas: 0,
    porcentajeAbonoInicial: 0,
    requiereAprobacion: true,
  );

  bool get tieneAcuerdoVigente => acuerdoVigenteId != null;
  String get primerMotivo => motivos.isEmpty ? '' : motivos.first.mensaje;
}
