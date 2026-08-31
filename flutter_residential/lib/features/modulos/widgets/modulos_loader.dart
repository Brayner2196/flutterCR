import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/modulos_provider.dart';

/// Garantiza que [ModulosProvider] esté cargado y sincronizado con el conjunto
/// de la sesión activa.
///
/// Se pone UNA vez, envolviendo las home de los roles que pertenecen a un
/// conjunto (admin, residente, vigilante). Así ninguna pantalla tiene que
/// acordarse de cargar los módulos, y el cambio de conjunto en el login
/// multi-tenant recarga solo.
///
/// El SUPER_ADMIN NO se envuelve: no pertenece a ningún conjunto y su token no
/// lleva `X-Tenant-ID`, así que la llamada fallaría.
class ModulosLoader extends StatefulWidget {
  final Widget child;

  const ModulosLoader({super.key, required this.child});

  @override
  State<ModulosLoader> createState() => _ModulosLoaderState();
}

class _ModulosLoaderState extends State<ModulosLoader> {
  /// Conjunto para el que ya se pidieron los módulos. Evita repetir la llamada
  /// en cada rebuild y fuerza la recarga si el usuario cambia de conjunto.
  String? _tenantCargado;

  void _sincronizar(String? tenantActual) {
    if (tenantActual == _tenantCargado) return;

    _tenantCargado = tenantActual;
    final modulos = context.read<ModulosProvider>();

    if (tenantActual == null || tenantActual.isEmpty) {
      modulos.limpiarDatos();
      return;
    }
    modulos.cargar();
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
