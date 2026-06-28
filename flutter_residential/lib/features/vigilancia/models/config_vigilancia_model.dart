class ConfigVigilanciaModel {
  final int expiracionVisitaHoras;
  final bool exigeDocumentoPeatonal;
  final bool exigeFotoPaquete;
  final bool notificarLlegadaPaquete;

  const ConfigVigilanciaModel({
    required this.expiracionVisitaHoras,
    required this.exigeDocumentoPeatonal,
    required this.exigeFotoPaquete,
    required this.notificarLlegadaPaquete,
  });

  factory ConfigVigilanciaModel.fromJson(Map<String, dynamic> json) =>
      ConfigVigilanciaModel(
        expiracionVisitaHoras: (json['expiracionVisitaHoras'] as num?)?.toInt() ?? 24,
        exigeDocumentoPeatonal: json['exigeDocumentoPeatonal'] as bool? ?? true,
        exigeFotoPaquete: json['exigeFotoPaquete'] as bool? ?? false,
        notificarLlegadaPaquete: json['notificarLlegadaPaquete'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'expiracionVisitaHoras': expiracionVisitaHoras,
        'exigeDocumentoPeatonal': exigeDocumentoPeatonal,
        'exigeFotoPaquete': exigeFotoPaquete,
        'notificarLlegadaPaquete': notificarLlegadaPaquete,
      };

  ConfigVigilanciaModel copyWith({
    int? expiracionVisitaHoras,
    bool? exigeDocumentoPeatonal,
    bool? exigeFotoPaquete,
    bool? notificarLlegadaPaquete,
  }) =>
      ConfigVigilanciaModel(
        expiracionVisitaHoras: expiracionVisitaHoras ?? this.expiracionVisitaHoras,
        exigeDocumentoPeatonal: exigeDocumentoPeatonal ?? this.exigeDocumentoPeatonal,
        exigeFotoPaquete: exigeFotoPaquete ?? this.exigeFotoPaquete,
        notificarLlegadaPaquete: notificarLlegadaPaquete ?? this.notificarLlegadaPaquete,
      );
}
