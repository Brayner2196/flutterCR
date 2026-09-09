import '../../../core/enums/estado_carga.dart';
import '../../../core/providers/base_provider.dart';
import '../../../core/providers/carga_resoluble.dart';
import '../services/contador_service.dart';

/// Alcance financiero del usuario de la sesion.
///
/// Tercera capa del control de acceso, junto a los modulos del conjunto
/// ([ModulosProvider]) y los permisos de inquilino: el modulo dice que contrato
/// el conjunto, este dice que le dejo hacer el administrador al contador.
///
/// [puede] es **fail-closed**: sin dato responde false. Igual que con los
/// permisos de inquilino, mostrarle a un contador un boton que el backend le va
/// a rechazar con 403 es peor que no mostrarselo. El parpadeo lo evita el gate,
/// que no construye la pantalla hasta que [resuelto] sea true.
///
/// El TENANT_ADMIN carga esto tambien y recibe `administrador = true` con el
/// catalogo completo, de modo que las pantallas compartidas usan una sola
/// condicion (`permisos.puede('X')`) sin ramificar por rol.
class PermisosContablesProvider extends BaseProvider implements CargaResoluble {
  Set<String> _permisos = {};
  bool _administrador = false;
  EstadoCarga _estado = EstadoCarga.inicial;

  Set<String> get permisos => _permisos;

  /// Verdadero para TENANT_ADMIN y SUPER_ADMIN: pasan todos los permisos.
  bool get esAdministrador => _administrador;

  @override
  EstadoCarga get estadoCarga => _estado;

  @override
  bool get resuelto => _estado.resuelto;

  /// Un contador con cero permisos entra a la app pero no ve nada financiero.
  /// La home lo detecta con esto para mostrar un mensaje en vez de tabs vacias.
  bool get sinAlcance => !_administrador && _permisos.isEmpty;

  bool puede(String permiso) => _administrador || _permisos.contains(permiso);

  /// Verdadero si tiene al menos uno de los permisos indicados. Util para
  /// decidir si una pestana completa se muestra.
  bool puedeAlguno(List<String> permisos) =>
      _administrador || permisos.any(_permisos.contains);

  Future<void> cargar() async {
    _estado = EstadoCarga.cargando;
    try {
      setLoading(true);
      final r = await ContadorService.misPermisos();
      _administrador = r.administrador;
      _permisos = r.permisos;
      _estado = EstadoCarga.listo;
      limpiarError();
    } catch (e) {
      // Fail-closed: ante el error el usuario no ve acciones financieras.
      _administrador = false;
      _permisos = {};
      _estado = EstadoCarga.error;
      setError('Error cargando permisos contables');
    } finally {
      setLoading(false);
    }
  }

  /// Marca los permisos como resueltos SIN pedirlos al backend.
  ///
  /// Necesario para los roles que no entran al area financiera (residente,
  /// vigilante): nunca llaman a [cargar], asi que sin esto el estado se
  /// quedaria en `inicial` para siempre y el gate se colgaria en el esqueleto.
  void marcarNoAplica() {
    _administrador = false;
    _permisos = {};
    _estado = EstadoCarga.listo;
    limpiarError();
    setLoading(false);
  }

  void limpiarDatos() {
    _administrador = false;
    _permisos = {};
    _estado = EstadoCarga.inicial;
    limpiarError();
    setLoading(false);
  }
}
