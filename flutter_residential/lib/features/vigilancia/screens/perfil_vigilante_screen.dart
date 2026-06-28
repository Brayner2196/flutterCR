import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/dialogs/confirmar_logout.dart';
import 'package:flutter_residential/core/utils/texto_utils.dart';
import 'package:flutter_residential/shared/widgets/seccion_agrupadora.dart';
import 'package:flutter_residential/shared/widgets/seccion_agrupadora_item.dart';
import 'package:flutter_residential/shared/widgets/seccion_agrupadora_item_accion.dart';
import 'package:flutter_residential/shared/widgets/seccion_agrupadora_item_toogle.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../usuarios/providers/app_provider.dart';
import '../../../shared/theme/app_theme.dart';

/// Perfil del vigilante. Clona la estructura del perfil de residente, sin la
/// sección de vivienda (el vigilante no está asociado a una unidad).
class PerfilVigilanteScreen extends StatelessWidget {
  const PerfilVigilanteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appProvider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final nombre = auth.nombre ?? 'Vigilante';
    final email = auth.email ?? '';
    final conjunto = auth.nombreConjunto ?? 'Conjunto Residencial';
    final iniciales = TextoUtils.getIniciales(nombre);

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
                Text(nombre,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(email,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgBlue,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: const Text('Vigilante',
                      style: TextStyle(
                          color: AppColors.blue, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SeccionAgrupadora(
            titulo: 'Información',
            items: [
              SeccionAgrupadoraItem(
                icono: Icons.apartment_rounded,
                label: 'Conjunto',
                valor: conjunto,
              ),
              SeccionAgrupadoraItem(
                icono: Icons.shield_outlined,
                label: 'Función',
                valor: 'Control de acceso y portería',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SeccionAgrupadora(
            titulo: 'Preferencias',
            items: [
              SeccionAgrupadoraItemToogle(
                icono: Icons.dark_mode_sharp,
                label: 'Tema oscuro',
                valor: appProvider.esOscuro(context),
                onChanged: () => appProvider.toggleTheme(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
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
