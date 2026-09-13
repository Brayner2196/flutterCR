import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/version/version_provider.dart';
import '../theme/app_theme.dart';

/// Aviso de actualización sugerida. La app sigue funcionando por debajo.
///
/// Mismo formato que `_OfflineBanner`: barra superior fija, respetando el
/// notch. Va apilado *dentro* de `OfflineGuard`, así que si además se cae la
/// red el banner de "sin conexión" se pinta encima de este — que es el orden
/// correcto: sin red no hay actualización posible.
///
/// El texto del botón cambia con el estado real de la descarga en vez de decir
/// siempre "Actualizar": pulsar un botón que no hace nada porque todavía está
/// bajando es la manera más rápida de que alguien piense que la app falla.
class ActualizacionBanner extends StatelessWidget {
  const ActualizacionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final version = context.watch<VersionProvider>();

    return Material(
      elevation: 4,
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.only(
          top: topPadding + 10,
          bottom: 10,
          left: 16,
          right: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          border: const Border(
            bottom: BorderSide(color: AppColors.warning, width: 2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.system_update_rounded,
                color: AppColors.warning, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    version.info.versionNombre != null &&
                            version.info.versionNombre!.isNotEmpty
                        ? 'Versión ${version.info.versionNombre} disponible'
                        : 'Hay una versión nueva',
                    style: const TextStyle(
                      color: AppColors.textHiLight,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _subtitulo(version.fase),
                    style: const TextStyle(
                      color: AppColors.textMidLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _Accion(version: version),
            IconButton(
              onPressed: version.descartarBanner,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.textMidLight,
              tooltip: 'Ocultar',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  String _subtitulo(FaseActualizacion fase) {
    switch (fase) {
      case FaseActualizacion.descargando:
        return 'Descargando en segundo plano…';
      case FaseActualizacion.listaParaAplicar:
        return 'Lista para instalar';
      case FaseActualizacion.noDisponible:
        return 'Actualízala desde la tienda';
      case FaseActualizacion.fallo:
        return 'No se pudo descargar';
      case FaseActualizacion.reposo:
        return 'Puedes seguir usando la app';
    }
  }
}

/// Botón de la derecha. Solo aparece cuando hay algo que pulsar: mientras
/// descarga se muestra el progreso, no un botón inerte.
class _Accion extends StatelessWidget {
  final VersionProvider version;

  const _Accion({required this.version});

  @override
  Widget build(BuildContext context) {
    if (version.fase == FaseActualizacion.descargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.warning,
          ),
        ),
      );
    }

    if (version.fase != FaseActualizacion.listaParaAplicar) {
      return const SizedBox.shrink();
    }

    return TextButton(
      onPressed: version.aplicar,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.warning,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 36),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      child: const Text('Reiniciar'),
    );
  }
}
