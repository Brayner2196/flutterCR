import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/dialogs/confirmar_logout.dart';
import 'package:flutter_residential/shared/utils/texto_utils.dart';
import 'package:flutter_residential/shared/widgets/seccion_agrupadora.dart';
import 'package:flutter_residential/shared/widgets/seccion_agrupadora_item.dart';
import 'package:flutter_residential/shared/widgets/seccion_agrupadora_item_accion.dart';
import 'package:flutter_residential/shared/widgets/seccion_agrupadora_item_toogle.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../propiedades/providers/propiedad_provider.dart';
import '../../../usuarios/providers/app_provider.dart';
import '../../../../shared/theme/app_theme.dart';

class PerfilResidenteScreen extends StatelessWidget {
  const PerfilResidenteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final propiedades = context.watch<PropiedadProvider>();
    final appProvider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final nombre = auth.nombre ?? 'Usuario';
    final email = auth.email ?? '';
    final conjunto = auth.nombreConjunto ?? 'Conjunto Residencial';
    final propiedad =
        propiedades.propiedadActual?.pathTexto ?? 'Sin propiedad asignada';
    final iniciales = TextoUtils.getIniciales(nombre);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + nombre ──
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      iniciales,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  nombre,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Info del conjunto ──
          SeccionAgrupadora(
            titulo: 'Información de vivienda',
            items: [
              SeccionAgrupadoraItem(
                icono: Icons.apartment_rounded,
                label: 'Conjunto',
                valor: conjunto,
              ),
              SeccionAgrupadoraItem(
                icono: Icons.home_work_rounded,
                label: 'Unidad',
                valor: propiedad,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Preferencias ──
          SeccionAgrupadora(
            titulo: 'Preferencias',
            items: [
              SeccionAgrupadoraItemToogle(
                icono: Icons.dark_mode_sharp,
                label: 'Tema oscuro',
                valor: appProvider.themeMode == ThemeMode.dark,
                onChanged: appProvider.toggleTheme,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Sesión ──
          SeccionAgrupadora(
            titulo: 'Sesión',
            items: [
              SeccionAgrupadoraItemAccion(
                icono: Icons.logout_rounded,
                label: 'Cerrar sesión',
                color: cs.error,
                onTap: () => LogoutDialog.confirmar(context, auth),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
