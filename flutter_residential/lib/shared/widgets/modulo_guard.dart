import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enums/modulo.dart';
import '../../features/modulos/providers/modulos_provider.dart';

/// Utilidades para condicionar la UI a los módulos que el conjunto tiene
/// habilitados. Un solo lugar del que tira toda la app, para no repetir
/// `context.watch<ModulosProvider>().activo(...)` en cada pantalla.
extension ModulosContext on BuildContext {
  /// ¿El conjunto tiene el módulo habilitado? Reconstruye el widget si cambia.
  bool moduloActivo(Modulo modulo) =>
      watch<ModulosProvider>().activo(modulo);

  /// Igual que [moduloActivo] pero sin suscribirse. Para callbacks y
  /// `initState`, donde `watch` no se puede usar.
  bool moduloActivoLeer(Modulo modulo) =>
      read<ModulosProvider>().activo(modulo);
}

/// Muestra [child] solo si el módulo está habilitado en el conjunto.
///
/// Por defecto el módulo apagado NO se muestra deshabilitado: se oculta. Un
/// candado sobre algo que el conjunto no contrató solo genera preguntas al
/// administrador. Si en algún caso conviene mostrar otra cosa, se pasa
/// [fallback].
///
/// ```dart
/// ModuloGuard(
///   modulo: Modulo.pqr,
///   child: QuickAccessCard(...),
/// )
/// ```
class ModuloGuard extends StatelessWidget {
  final Modulo modulo;
  final Widget child;
  final Widget? fallback;

  const ModuloGuard({
    super.key,
    required this.modulo,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (context.moduloActivo(modulo)) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

/// Igual que [ModuloGuard] pero exige que TODOS los módulos estén activos.
/// Útil para pantallas que cruzan dos módulos.
class ModulosGuard extends StatelessWidget {
  final List<Modulo> modulos;
  final Widget child;
  final Widget? fallback;

  const ModulosGuard({
    super.key,
    required this.modulos,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ModulosProvider>();
    if (provider.activosTodos(modulos)) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

/// Pantalla completa para cuando se llega a un módulo apagado por deep link,
/// notificación push o una ruta guardada. Evita el error crudo del 403.
class ModuloNoDisponibleScreen extends StatelessWidget {
  final Modulo modulo;

  const ModuloNoDisponibleScreen({super.key, required this.modulo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(modulo.nombre)),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.extension_off_outlined, size: 56, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Módulo no disponible',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'El módulo "${modulo.nombre}" no está habilitado en este conjunto. '
              'Comunícate con la administración si crees que debería estarlo.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
