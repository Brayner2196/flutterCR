import '../enums/estado_carga.dart';

/// Contrato mínimo de un provider del que la UI necesita esperar respuesta
/// antes de decidir qué pintar.
///
/// Existe para que los widgets que esperan (`SesionListaGate`) no tengan que
/// conocer a `ModulosProvider` ni a `InquilinoPermisosProvider` en concreto:
/// esperan a "cosas resolubles", y mañana se agrega otra sin tocar el gate.
///
/// ```dart
/// class MiProvider extends BaseProvider implements CargaResoluble {
///   EstadoCarga _estado = EstadoCarga.inicial;
///   @override
///   EstadoCarga get estadoCarga => _estado;
/// }
/// ```
abstract interface class CargaResoluble {
  /// Estado del dato principal del provider.
  EstadoCarga get estadoCarga;

  /// Atajo: ¿ya hubo respuesta del backend (buena o mala)?
  bool get resuelto;
}
