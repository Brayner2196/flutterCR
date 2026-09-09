import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/inquilinos/providers/inquilino_permisos_provider.dart';
import '../../features/contador/providers/permisos_contables_provider.dart';
import '../../features/modulos/providers/modulos_provider.dart';

/// Carga el contexto de acceso de la sesión: los **módulos** del conjunto y los
/// **permisos** del usuario.
///
/// Se pone UNA vez, envolviendo la home de los roles que pertenecen a un
/// conjunto (admin, residente, vigilante). Así ninguna pantalla tiene que
/// acordarse de cargar nada, y el cambio de conjunto en el login multi-tenant
/// recarga solo.
///
/// El SUPER_ADMIN NO se envuelve: no pertenece a ningún conjunto y su token no
/// lleva `X-Tenant-ID`, así que la llamada fallaría.
///
/// ## Por qué las dos cargas juntas
///
/// Son la misma capa conceptual (¿qué puede ver este usuario?) y la UI las
/// combina en la misma condición. Cargarlas en sitios distintos producía dos
/// reflows seguidos y, peor, una carrera: la home pedía los permisos y el
/// dashboard decidía qué peticiones disparar antes de que llegaran, así que un
/// inquilino se quedaba sin anuncios ni PQRs hasta hacer pull-to-refresh.
///
/// Este widget solo DISPARA las cargas. Quien espera a que terminen para pintar
/// es [SesionListaGate], que va justo adentro.
class SesionContextoLoader extends StatefulWidget {
  final Widget child;

  const SesionContextoLoader({super.key, required this.child});

  @override
  State<SesionContextoLoader> createState() => _SesionContextoLoaderState();
}

class _SesionContextoLoaderState extends State<SesionContextoLoader> {
  /// Conjunto para el que ya se pidió el contexto. Evita repetir las llamadas
  /// en cada rebuild y fuerza la recarga si el usuario cambia de conjunto.
  String? _tenantCargado;

  void _sincronizar(String? tenantActual) {
    if (tenantActual == _tenantCargado) return;

    _tenantCargado = tenantActual;
    final modulos = context.read<ModulosProvider>();
    final permisos = context.read<InquilinoPermisosProvider>();
    final contables = context.read<PermisosContablesProvider>();

    if (tenantActual == null || tenantActual.isEmpty) {
      // Sin conjunto no hay nada que pedir, pero tampoco se puede dejar el
      // contexto sin resolver: el gate de abajo estaría esperando una respuesta
      // que nunca va a llegar y la app se quedaría en el esqueleto. Se marcan
      // los dos como resueltos (los módulos, además, fail-open).
      modulos.marcarSinConjunto();
      permisos.marcarNoAplica();
      contables.marcarNoAplica();
      return;
    }

    modulos.cargar();

    // Solo el inquilino tiene permisos que consultar. Los demás roles se marcan
    // como resueltos sin pedir nada: si se dejaran en `inicial`, el gate se
    // quedaría esperando una respuesta que nunca va a llegar.
    final auth = context.read<AuthProvider>();

    if (auth.isInquilino) {
      permisos.cargar();
    } else {
      permisos.marcarNoAplica();
    }

    // Permisos contables: los piden el CONTADOR y el TENANT_ADMIN. Los demás
    // roles se marcan resueltos sin llamar al backend, por la misma razón que
    // arriba: si quedaran en `inicial`, el gate esperaría para siempre.
    if (auth.isAreaContable) {
      contables.cargar();
    } else {
      contables.marcarNoAplica();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantActual = context.watch<AuthProvider>().tenantId;

    // La carga se agenda fuera del build: llamar a notifyListeners() durante
    // el build de otro widget lanza excepción en Flutter.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sincronizar(tenantActual);
    });

    return widget.child;
  }
}
