import 'permiso_contable_model.dart';

/// Un contador del conjunto con su alcance vigente.
///
/// [permisos] trae el catalogo COMPLETO con la marca de otorgado, no solo los
/// concedidos: la pantalla muestra tambien lo que el contador no puede hacer,
/// que es la mitad de la informacion que el administrador necesita.
class Contador {
  final int usuarioId;
  final String nombre;
  final String email;
  final String estado;
  final bool activo;
  final int permisosOtorgados;
  final List<PermisoContable> permisos;

  const Contador({
    required this.usuarioId,
    required this.nombre,
    required this.email,
    required this.estado,
    required this.activo,
    required this.permisosOtorgados,
    required this.permisos,
  });

  factory Contador.fromJson(Map<String, dynamic> json) => Contador(
        usuarioId: json['usuarioId'] ?? 0,
        nombre: json['nombre'] ?? '',
        email: json['email'] ?? '',
        estado: json['estado'] ?? 'ACTIVO',
        activo: json['activo'] == true,
        permisosOtorgados: json['permisosOtorgados'] ?? 0,
        permisos: (json['permisos'] as List<dynamic>? ?? [])
            .map((e) => PermisoContable.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Nombres de los permisos concedidos, que es lo que espera el PUT.
  List<String> get otorgados =>
      permisos.where((p) => p.otorgado).map((p) => p.nombre).toList();

  /// Contador sin ningun permiso: entra a la app pero no ve nada financiero.
  bool get sinAlcance => permisosOtorgados == 0;

  /// Permisos agrupados y en el orden que los manda el backend.
  Map<String, List<PermisoContable>> get porGrupo {
    final mapa = <String, List<PermisoContable>>{};
    for (final p in permisos) {
      mapa.putIfAbsent(p.grupo, () => []).add(p);
    }
    return mapa;
  }
}
