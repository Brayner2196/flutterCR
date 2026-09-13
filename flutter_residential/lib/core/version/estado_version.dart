/// Modelo del chequeo de versión. Sin Flutter, sin http: se prueba con
/// `dart test` puro.
library;

/// Veredicto que emite el backend. La app no lo calcula, solo lo obedece:
/// así la regla se puede cambiar en el servidor sin publicar una app nueva,
/// que sería la paradoja evidente.
enum EstadoVersion {
  /// Nada que hacer.
  alDia,

  /// Hay algo más nuevo pero esta versión sigue sirviendo. Banner, no bloqueo.
  sugerida,

  /// Por debajo del mínimo: la app ya no habla con el backend.
  obligatoria,

  /// No se pudo averiguar (sin red, backend caído, tiempo agotado).
  ///
  /// Es un estado de primera clase y no un error: la app **deja pasar** al
  /// usuario. Un chequeo de versión que bloquea la app cuando el servidor está
  /// caído convierte una caída del backend en una app inservible.
  desconocido,
}

class InfoVersion {
  final EstadoVersion estado;

  /// Versión legible de la última publicada ("1.2.0"). Puede venir vacía.
  final String? versionNombre;

  /// Texto del backend. Si viene vacío se usa uno por defecto.
  final String? mensaje;

  /// Enlace de respaldo a la tienda, para cuando la actualización nativa
  /// no está disponible (instalaciones fuera de Play, emulador, etc.).
  final String? urlTienda;

  const InfoVersion({
    required this.estado,
    this.versionNombre,
    this.mensaje,
    this.urlTienda,
  });

  /// Estado neutro: el que se usa cuando no se pudo consultar.
  static const InfoVersion desconocido = InfoVersion(estado: EstadoVersion.desconocido);

  static const InfoVersion alDia = InfoVersion(estado: EstadoVersion.alDia);

  bool get requiereAccion =>
      estado == EstadoVersion.sugerida || estado == EstadoVersion.obligatoria;

  bool get bloquea => estado == EstadoVersion.obligatoria;

  /// El backend puede no mandar mensaje; la pantalla siempre necesita uno.
  String get mensajeVisible {
    final m = mensaje?.trim();
    if (m != null && m.isNotEmpty) return m;
    return estado == EstadoVersion.obligatoria
        ? 'Esta versión de la aplicación ya no es compatible. Actualízala para continuar.'
        : 'Hay una versión nueva disponible con mejoras y correcciones.';
  }

  factory InfoVersion.desdeJson(Map<String, dynamic> json) {
    return InfoVersion(
      estado: _estadoDesdeTexto(json['estado']?.toString()),
      versionNombre: json['versionNombre']?.toString(),
      mensaje: json['mensaje']?.toString(),
      urlTienda: json['urlTienda']?.toString(),
    );
  }

  /// Un valor que esta app no conoce se trata como al día, no como error: si
  /// mañana el backend agrega un estado nuevo, las versiones viejas siguen
  /// funcionando en vez de quedarse trabadas.
  static EstadoVersion _estadoDesdeTexto(String? valor) {
    switch (valor) {
      case 'OBLIGATORIA':
        return EstadoVersion.obligatoria;
      case 'SUGERIDA':
        return EstadoVersion.sugerida;
      case 'AL_DIA':
        return EstadoVersion.alDia;
      default:
        return EstadoVersion.alDia;
    }
  }
}
