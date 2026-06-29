/// Detalle de la visita que ve el vigilante al escanear, con el estado de cartera
/// y si puede decidir/aprobar según la parametrización del conjunto.
class DetalleVisitaModel {
  final int id;
  final String codigo;
  final String estado;
  final String nombreVisitante;
  final int cantidadPersonas;
  final String? acompanantes;
  final String? documento;
  final String? placa;
  final String? motivo;
  final int propiedadId;
  final String? propiedadIdentificador;
  final String? franjaDesde;
  final String? franjaHasta;
  final String? expiraEn;
  final String? ingresoEn;
  final String? motivoRechazo;
  final bool carteraRestringida;
  final String? carteraMensaje;
  final bool puedeDecidir;
  final bool puedeAprobar;
  final String? mensaje;

  const DetalleVisitaModel({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.nombreVisitante,
    this.cantidadPersonas = 1,
    this.acompanantes,
    this.documento,
    this.placa,
    this.motivo,
    required this.propiedadId,
    this.propiedadIdentificador,
    this.franjaDesde,
    this.franjaHasta,
    this.expiraEn,
    this.ingresoEn,
    this.motivoRechazo,
    this.carteraRestringida = false,
    this.carteraMensaje,
    this.puedeDecidir = false,
    this.puedeAprobar = false,
    this.mensaje,
  });

  factory DetalleVisitaModel.fromJson(Map<String, dynamic> json) =>
      DetalleVisitaModel(
        id: (json['id'] as num).toInt(),
        codigo: json['codigo'] as String? ?? '',
        estado: json['estado'] as String? ?? 'PENDIENTE',
        nombreVisitante: json['nombreVisitante'] as String? ?? '',
        cantidadPersonas: (json['cantidadPersonas'] as num?)?.toInt() ?? 1,
        acompanantes: json['acompanantes'] as String?,
        documento: json['documento'] as String?,
        placa: json['placa'] as String?,
        motivo: json['motivo'] as String?,
        propiedadId: (json['propiedadId'] as num).toInt(),
        propiedadIdentificador: json['propiedadIdentificador'] as String?,
        franjaDesde: json['franjaDesde'] as String?,
        franjaHasta: json['franjaHasta'] as String?,
        expiraEn: json['expiraEn'] as String?,
        ingresoEn: json['ingresoEn'] as String?,
        motivoRechazo: json['motivoRechazo'] as String?,
        carteraRestringida: json['carteraRestringida'] as bool? ?? false,
        carteraMensaje: json['carteraMensaje'] as String?,
        puedeDecidir: json['puedeDecidir'] as bool? ?? false,
        puedeAprobar: json['puedeAprobar'] as bool? ?? false,
        mensaje: json['mensaje'] as String?,
      );

  bool get esIngreso => estado == 'INGRESO';
  bool get esRechazada => estado == 'RECHAZADA';
}
