import 'package:flutter/material.dart';
import 'package:flutter_residential/features/auth/providers/auth_provider.dart';
import 'package:flutter_residential/features/usuarios/providers/app_provider.dart';
import 'package:flutter_residential/shared/dialogs/confirmar_logout.dart';
import 'package:flutter_residential/shared/utils/texto_utils.dart';
import 'package:flutter_residential/shared/widgets/seccion_agrupadora.dart';
import 'package:flutter_residential/shared/widgets/seccion_agrupadora_item.dart';
import 'package:flutter_residential/shared/widgets/seccion_agrupadora_item_accion.dart';
import 'package:flutter_residential/shared/widgets/seccion_agrupadora_item_toogle.dart';
import 'package:provider/provider.dart';
import '../../../../shared/theme/app_theme.dart';

class PerfilAdminScreen extends StatelessWidget {
  const PerfilAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nombre = auth.nombre ?? 'Usuario';
    final email = auth.email ?? '';
    final nombreConjunto = auth.nombreConjunto ?? 'Conjunto Residencial';
    final inicialesNombre = TextoUtils.getIniciales(nombre);

    final appProvider = context.watch<AppProvider>();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      inicialesNombre,
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
            titulo: 'Informacion del conjunto Residencial',
            items: [
              SeccionAgrupadoraItem(
                icono: Icons.apartment_rounded,
                label: 'Conjunto Residencial',
                valor: nombreConjunto,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // ── Preferencias ──
          SeccionAgrupadora(
            titulo: 'Preferencias',
            items: [
              SeccionAgrupadoraItemToogle(
                icono: Icons.dark_mode,
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
                  onTap: () =>  LogoutDialog.confirmar(context, auth),
                ),
              ],
            ),
        ],
      ),
    );
  }

}
