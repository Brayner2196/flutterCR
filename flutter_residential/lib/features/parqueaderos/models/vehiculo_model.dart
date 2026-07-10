enum TipoVehiculo  { carro, moto, bicicleta }
enum EstadoVehiculo { pendiente, aprobado, rechazado }

class VehiculoModel {
  final int id;
  final String placa;
  final TipoVehiculo tipo;
  final String? marca;
  final String? modelo;
  final String? color;
  final int propiedadId;
  final int? parqueaderoId;
  final String? parqueaderoIdentificador;
  final EstadoVehiculo estado;
  final String? motivoRechazo;

  const VehiculoModel({
    required this.id,
    required this.placa,
    required this.tipo,
    this.marca,
    this.modelo,
    this.color,
    required this.propiedadId,
    this.parqueaderoId,
    this.parqueaderoIdentificador,
    required this.estado,
    this.motivoRechazo,
  });

  bool get esPendiente  => estado == EstadoVehiculo.pendiente;
  bool get esAprobado   => estado == EstadoVehiculo.aprobado;
  bool get esRechazado  => estado == EstadoVehiculo.rechazado;

  String get estadoLegible {
    switch (estado) {
      case EstadoVehiculo.pendiente:  return 'Pendiente';
      case EstadoVehiculo.aprobado:   return 'Aprobado';
      case EstadoVehiculo.rechazado:  return 'Rechazado';
    }
  }

  String get tipoLegible {
    switch (tipo) {
      case TipoVehiculo.carro:     return 'Carro';
      case TipoVehiculo.moto:      return 'Moto';
      case TipoVehiculo.bicicleta: return 'Bicicleta';
    }
  }

  /// Descripción compacta: placa + marca/modelo si están disponibles.
  String get descripcion {
    final partes = <String>[placa];
    if (marca != null && marca!.isNotEmpty) partes.add(marca!);
    if (modelo != null && modelo!.isNotEmpty) partes.add(modelo!);
    return partes.join(' · ');
  }

  factory VehiculoModel.fromJson(Map<String, dynamic> json) {
    return VehiculoModel(
      id:                       json['id'] as int,
      placa:                    json['placa'] as String,
      tipo:                     TipoVehiculo.values.firstWhere(
                                  (e) => e.name == json['tipo'],
                                  orElse: () => TipoVehiculo.carro,
                                ),
      marca:                    json['marca'] as String?,
      modelo:                   json['modelo'] as String?,
      color:                    json['color'] as String?,
      propiedadId:              json['propiedadId'] as int,
      parqueaderoId:            json['parqueaderoId'] as int?,
      parqueaderoIdentificador: json['parqueaderoIdentificador'] as String?,
      estado:                   EstadoVehiculo.values.firstWhere(
                                  (e) => e.name == json['estado'],
                                  orElse: () => EstadoVehiculo.pendiente,
                                ),
      motivoRechazo:            json['motivoRechazo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':                       id,
    'placa':                    placa,
    'tipo':                     tipo.name,
    'marca':                    marca,
    'modelo':                   modelo,
    'color':                    color,
    'propiedadId':              propiedadId,
    'parqueaderoId':            parqueaderoId,
    'parqueaderoIdentificador': parqueaderoIdentificador,
    'estado':                   estado.name,
    'motivoRechazo':            motivoRechazo,
  };
}
