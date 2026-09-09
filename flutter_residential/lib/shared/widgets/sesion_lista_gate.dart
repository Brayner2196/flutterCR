import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/carga_resoluble.dart';
import '../../features/inquilinos/providers/inquilino_permisos_provider.dart';
import '../../features/contador/providers/permisos_contables_provider.dart';
import '../../features/modulos/providers/modulos_provider.dart';
import 'home_skeleton.dart';

/// No construye [child] hasta que TODO el contexto de acceso de la sesión haya
/// respondido; mientras tanto pinta [cargando].
///
/// Resuelve el parpadeo de arranque: antes la home se pintaba con módulos y
/// permisos sin cargar, el usuario alcanzaba a ver accesos que medio segundo
/// después desaparecían.
///
/// El efecto de fondo es más grande que lo visual: como el subárbol no se
/// construye, **todos los `initState` de adentro corren ya con los datos
/// resueltos**. Por eso las pantallas hijas (dashboard del residente, home del
/// vigilante) no necesitaron ni un cambio: sus condiciones
/// `modulos.activo(...) && permisos.tienePermiso(...)` ahora evalúan sobre
/// datos reales en vez de sobre defaults.
///
/// ```dart
/// SesionContextoLoader(
///   child: SesionListaGate(child: AdminHomeScreen()),
/// )
/// ```
class SesionListaGate extends StatelessWidget {
  final Widget child;

  /// Qué pintar mientras se espera. Por defecto el esqueleto de la home.
  final Widget? cargando;

  const SesionListaGate({super.key, required this.child, this.cargando});

  @override
  Widget build(BuildContext context) {
    // Se listan acá y no en el constructor a propósito: los providers hay que
    // observarlos (watch) para reconstruir cuando resuelvan. Agregar una
    // dependencia nueva en el futuro es agregar una línea a esta lista.
    final dependencias = <CargaResoluble>[
      context.watch<ModulosProvider>(),
      context.watch<InquilinoPermisosProvider>(),
      context.watch<PermisosContablesProvider>(),
    ];

    final listo = dependencias.every((d) => d.resuelto);
    if (!listo) return cargando ?? const HomeSkeleton();

    return child;
  }
}
