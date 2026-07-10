/// Tipos de parqueadero: privado (pertenece a una propiedad) o común (conteo en configuración).
enum TipoParqueadero { comun, privado }

/// Modelo de un parqueadero PRIVADO:
/// INDEPENDIENTE → es una propiedad facturable propia (propiedadParqueaderoId apunta a ella).
/// ACCESORIO     → complemento de un apartamento (propiedadId apunta al apartamento).
enum ModeloParqueaderoPrivado { independiente, accesorio }

class ParqueaderoModel {
  final int id;
  final String identificador;
  final TipoParqueadero tipo;

  /// Solo aplica a PRIVADO. Determina cómo se gestiona este parqueadero.
  final ModeloParqueaderoPrivado? modeloPropiedad;

  /// ACCESORIO: ID del apartamento dueño.
  /// INDEPENDIENTE: null o ID de apartamento relacionado (opcional).
  final int? propiedadId;
  final String? propiedadIdentificador;

  /// Path corto de la propiedad asociada (para mostrar a qué propiedad pertenece).
  final String? propiedadPath;

  /// INDEPENDIENTE únicamente: ID de la Propiedad de tipo parqueadero en el árbol.
  final int? propiedadParqueaderoId;

  final int? vehiculoId;
  final String? vehiculoPlaca;
  final String? vehiculoTipo;

  const ParqueaderoModel({
    required this.id,
    required this.identificador,
    required this.tipo,
    this.modeloPropiedad,
    this.propiedadId,
    this.propiedadIdentificador,
    this.propiedadPath,
    this.propiedadParqueaderoId,
    this.vehiculoId,
    this.vehiculoPlaca,
    this.vehiculoTipo,
  });

  bool get tienePropiedad    => propiedadId != null;
  /// Asignado a una propiedad por cualquiera de los dos modelos:
  /// ACCESORIO (propiedadId) o INDEPENDIENTE (propiedadParqueaderoId).
  bool get tieneAsignacion   => propiedadId != null || propiedadParqueaderoId != null;
  bool get tieneVehiculo     => vehiculoId != null;
  bool get esIndependiente   => modeloPropiedad == ModeloParqueaderoPrivado.independiente;
  bool get esAccesorio       => modeloPropiedad == ModeloParqueaderoPrivado.accesorio;

  factory ParqueaderoModel.fromJson(Map<String, dynamic> json) {
    return ParqueaderoModel(
      id:                     json['id'] as int,
      identificador:          json['identificador'] as String,
      tipo:                   TipoParqueadero.values.firstWhere(
                                (e) => e.name == json['tipo'],
                                orElse: () => TipoParqueadero.privado,
                              ),
      modeloPropiedad:        json['modeloPropiedad'] != null
                                ? ModeloParqueaderoPrivado.values.firstWhere(
                                    (e) => e.name == json['modeloPropiedad'],
                                    orElse: () => ModeloParqueaderoPrivado.accesorio,
                                  )
                                : null,
      propiedadId:            json['propiedadId'] as int?,
      propiedadIdentificador: json['propiedadIdentificador'] as String?,
      propiedadPath:          json['propiedadPath'] as String?,
      propiedadParqueaderoId: json['propiedadParqueaderoId'] as int?,
      vehiculoId:             json['vehiculoId'] as int?,
      vehiculoPlaca:          json['vehiculoPlaca'] as String?,
      vehiculoTipo:           json['vehiculoTipo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':                      id,
    'identificador':           identificador,
    'tipo':                    tipo.name,
    'modeloPropiedad':         modeloPropiedad?.name,
    'propiedadId':             propiedadId,
    'propiedadIdentificador':  propiedadIdentificador,
    'propiedadPath':           propiedadPath,
    'propiedadParqueaderoId':  propiedadParqueaderoId,
    'vehiculoId':              vehiculoId,
    'vehiculoPlaca':           vehiculoPlaca,
    'vehiculoTipo':            vehiculoTipo,
  };
}
