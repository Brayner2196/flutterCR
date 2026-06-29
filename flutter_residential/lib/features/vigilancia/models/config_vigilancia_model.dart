class ConfigVigilanciaModel {
  final int expiracionVisitaHoras;
  final bool exigeDocumentoPeatonal;
  final bool exigeFotoPaquete;
  final bool notificarLlegadaPaquete;
  final bool permitirAprobarConCarteraRestringida;

  const ConfigVigilanciaModel({
    required this.expiracionVisitaHoras,
    required this.exigeDocumentoPeatonal,
    required this.exigeFotoPaquete,
    required this.notificarLlegadaPaquete,
    required this.permitirAprobarConCarteraRestringida,
  });

  factory ConfigVigilanciaModel.fromJson(Map<String, dynamic> json) =>
      ConfigVigilanciaModel(
        expiracionVisitaHoras: (json['expiracionVisitaHoras'] as num?)?.toInt() ?? 24,
        exigeDocumentoPeatonal: json['exigeDocumentoPeatonal'] as bool? ?? true,
        exigeFotoPaquete: json['exigeFotoPaquete'] as bool? ?? false,
        notificarLlegadaPaquete: json['notificarLlegadaPaquete'] as bool? ?? true,
        permitirAprobarConCarteraRestringida:
            json['permitirAprobarConCarteraRestringida'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'expiracionVisitaHoras': expiracionVisitaHoras,
        'exigeDocumentoPeatonal': exigeDocumentoPeatonal,
        'exigeFotoPaquete': exigeFotoPaquete,
        'notificarLlegadaPaquete': notificarLlegadaPaquete,
        'permitirAprobarConCarteraRestringida': permitirAprobarConCarteraRestringida,
      };

  ConfigVigilanciaModel copyWith({
    int? expiracionVisitaHoras,
    bool? exigeDocumentoPeatonal,
    bool? exigeFotoPaquete,
    bool? notificarLlegadaPaquete,
    bool? permitirAprobarConCarteraRestringida,
  }) =>
      ConfigVigilanciaModel(
        expiracionVisitaHoras: expiracionVisitaHoras ?? this.expiracionVisitaHoras,
        exigeDocumentoPeatonal: exigeDocumentoPeatonal ?? this.exigeDocumentoPeatonal,
        exigeFotoPaquete: exigeFotoPaquete ?? this.exigeFotoPaquete,
        notificarLlegadaPaquete: notificarLlegadaPaquete ?? this.notificarLlegadaPaquete,
        permitirAprobarConCarteraRestringida:
            permitirAprobarConCarteraRestringida ?? this.permitirAprobarConCarteraRestringida,
      );
}
