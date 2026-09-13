import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/version/version_provider.dart';
import '../theme/app_theme.dart';

/// Pantalla que reemplaza toda la app cuando la versión ya no es compatible.
///
/// No tiene botón de cerrar ni de "más tarde", y por eso mismo el backend solo
/// debe llegar a este estado cuando de verdad la app dejó de funcionar: dejar a
/// alguien encerrado aquí por una mejora opcional es peor que no avisar nada.
///
/// El mensaje viene del backend para poder explicar el motivo real ("desde el
/// martes los pagos de Wompi requieren la versión nueva") en lugar de un texto
/// genérico que no le dice nada a nadie.
class ActualizacionObligatoriaScreen extends StatelessWidget {
  const ActualizacionObligatoriaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final version = context.watch<VersionProvider>();
    final cs = Theme.of(context).colorScheme;
    final info = version.info;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.system_update_rounded, size: 64, color: cs.primary),
                  const SizedBox(height: 24),

                  Text(
                    'Actualiza My CR',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    info.mensajeVisible,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),

                  if (info.versionNombre != null && info.versionNombre!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Versión disponible: ${info.versionNombre}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  _BotonPrincipal(version: version),

                  // Respaldo: instalaciones fuera de Play, emulador sin Play
                  // Services, iOS. Sin esto el usuario queda encerrado sin
                  // ninguna forma de salir.
                  if (version.fase == FaseActualizacion.noDisponible &&
                      info.urlTienda != null &&
                      info.urlTienda!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _abrirTienda(info.urlTienda!),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(kIsWeb ? 'Abrir la versión nueva' : 'Abrir la tienda'),
                    ),
                  ],

                  if (version.fase == FaseActualizacion.fallo) ...[
                    const SizedBox(height: 16),
                    Text(
                      'No se pudo completar la actualización. Revisa tu conexión e inténtalo otra vez.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.danger,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirTienda(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// El botón cambia según lo que realmente se puede hacer en este momento.
class _BotonPrincipal extends StatelessWidget {
  final VersionProvider version;

  const _BotonPrincipal({required this.version});

  @override
  Widget build(BuildContext context) {
    switch (version.fase) {
      case FaseActualizacion.descargando:
        return const FilledButton(
          onPressed: null,
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );

      case FaseActualizacion.listaParaAplicar:
        return FilledButton.icon(
          onPressed: version.aplicar,
          icon: const Icon(Icons.restart_alt_rounded, size: 20),
          label: Text(kIsWeb ? 'Recargar ahora' : 'Instalar y reiniciar'),
        );

      case FaseActualizacion.noDisponible:
      case FaseActualizacion.fallo:
      case FaseActualizacion.reposo:
        return FilledButton.icon(
          onPressed: () => version.verificar(forzar: true),
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: const Text('Reintentar'),
        );
    }
  }
}
