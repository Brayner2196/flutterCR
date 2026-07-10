import 'package:flutter_residential/features/parqueaderos/models/parqueadero_model.dart';

class ConfiguracionParqueaderoModel {
  final int? id;
  final int totalParqueaderos;
  final int parqueaderosComunes;
  final int parqueaderosPrivados;
  final int maxVehiculosPorPropiedad;
  final bool permiteCarro;
  final bool permiteMoto;
  final bool permiteBicicleta;
  final bool requiereAprobacionVehiculo;

  /// Modelo aplicado al crear parqueaderos privados en bulk.
  /// ACCESORIO     → se asignan a un apartamento (comportamiento clásico).
  /// INDEPENDIENTE → cada spot es una propiedad facturable propia.
  final ModeloParqueaderoPrivado modeloPrivadoDefault;

  /// ¿El conjunto habilita spots físicos para visitantes?
  final bool aceptaParqueaderoVisitantes;

  /// Cantidad de spots destinados a visitantes (aplica cuando [aceptaParqueaderoVisitantes] = true).
  final int totalParqueaderosVisitantes;

  const ConfiguracionParqueaderoModel({
    this.id,
    required this.totalParqueaderos,
    required this.parqueaderosComunes,
    required this.parqueaderosPrivados,
    required this.maxVehiculosPorPropiedad,
    required this.permiteCarro,
    required this.permiteMoto,
    required this.permiteBicicleta,
    required this.requiereAprobacionVehiculo,
    this.modeloPrivadoDefault = ModeloParqueaderoPrivado.accesorio,
    this.aceptaParqueaderoVisitantes = false,
    this.totalParqueaderosVisitantes = 0,
  });

  factory ConfiguracionParqueaderoModel.vacia() =>
      const ConfiguracionParqueaderoModel(
        totalParqueaderos: 0,
        parqueaderosComunes: 0,
        parqueaderosPrivados: 0,
        maxVehiculosPorPropiedad: 2,
        permiteCarro: true,
        permiteMoto: true,
        permiteBicicleta: true,
        requiereAprobacionVehiculo: false,
        modeloPrivadoDefault: ModeloParqueaderoPrivado.accesorio,
        aceptaParqueaderoVisitantes: false,
        totalParqueaderosVisitantes: 0,
      );

  factory ConfiguracionParqueaderoModel.fromJson(Map<String, dynamic> json) {
    return ConfiguracionParqueaderoModel(
      id:                           json['id'] as int?,
      totalParqueaderos:            json['totalParqueaderos'] as int? ?? 0,
      parqueaderosComunes:          json['parqueaderosComunes'] as int? ?? 0,
      parqueaderosPrivados:         json['parqueaderosPrivados'] as int? ?? 0,
      maxVehiculosPorPropiedad:     json['maxVehiculosPorPropiedad'] as int? ?? 2,
      permiteCarro:                 json['permiteCarro'] as bool? ?? true,
      permiteMoto:                  json['permiteMoto'] as bool? ?? true,
      permiteBicicleta:             json['permiteBicicleta'] as bool? ?? true,
      requiereAprobacionVehiculo:   json['requiereAprobacionVehiculo'] as bool? ?? false,
      modeloPrivadoDefault: json['modeloPrivadoDefault'] != null
          ? ModeloParqueaderoPrivado.values.firstWhere(
              (e) => e.name == json['modeloPrivadoDefault'],
              orElse: () => ModeloParqueaderoPrivado.accesorio,
            )
          : ModeloParqueaderoPrivado.accesorio,
      aceptaParqueaderoVisitantes:  json['aceptaParqueaderoVisitantes'] as bool? ?? false,
      totalParqueaderosVisitantes:  json['totalParqueaderosVisitantes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalParqueaderos':            totalParqueaderos,
    'parqueaderosComunes':          parqueaderosComunes,
    'parqueaderosPrivados':         parqueaderosPrivados,
    'maxVehiculosPorPropiedad':     maxVehiculosPorPropiedad,
    'permiteCarro':                 permiteCarro,
    'permiteMoto':                  permiteMoto,
    'permiteBicicleta':             permiteBicicleta,
    'requiereAprobacionVehiculo':   requiereAprobacionVehiculo,
    'modeloPrivadoDefault':         modeloPrivadoDefault.name,
    'aceptaParqueaderoVisitantes':  aceptaParqueaderoVisitantes,
    'totalParqueaderosVisitantes':  totalParqueaderosVisitantes,
  };

  ConfiguracionParqueaderoModel copyWith({
    int? totalParqueaderos,
    int? parqueaderosComunes,
    int? parqueaderosPrivados,
    int? maxVehiculosPorPropiedad,
    bool? permiteCarro,
    bool? permiteMoto,
    bool? permiteBicicleta,
    bool? requiereAprobacionVehiculo,
    ModeloParqueaderoPrivado? modeloPrivadoDefault,
    bool? aceptaParqueaderoVisitantes,
    int? totalParqueaderosVisitantes,
  }) {
    return ConfiguracionParqueaderoModel(
      id:                           id,
      totalParqueaderos:            totalParqueaderos ?? this.totalParqueaderos,
      parqueaderosComunes:          parqueaderosComunes ?? this.parqueaderosComunes,
      parqueaderosPrivados:         parqueaderosPrivados ?? this.parqueaderosPrivados,
      maxVehiculosPorPropiedad:     maxVehiculosPorPropiedad ?? this.maxVehiculosPorPropiedad,
      permiteCarro:                 permiteCarro ?? this.permiteCarro,
      permiteMoto:                  permiteMoto ?? this.permiteMoto,
      permiteBicicleta:             permiteBicicleta ?? this.permiteBicicleta,
      requiereAprobacionVehiculo:   requiereAprobacionVehiculo ?? this.requiereAprobacionVehiculo,
      modeloPrivadoDefault:         modeloPrivadoDefault ?? this.modeloPrivadoDefault,
      aceptaParqueaderoVisitantes:  aceptaParqueaderoVisitantes ?? this.aceptaParqueaderoVisitantes,
      totalParqueaderosVisitantes:  totalParqueaderosVisitantes ?? this.totalParqueaderosVisitantes,
    );
  }
}
