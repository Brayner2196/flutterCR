import 'package:flutter/material.dart';
import 'package:flutter_residential/features/auth/providers/auth_provider.dart';
import 'package:flutter_residential/features/propiedades/providers/propiedad_provider.dart';
import 'package:flutter_residential/features/home/residente/widgets/propiedad_selector_dropdown.dart';
import 'package:flutter_residential/shared/utils/texto_utils.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../usuarios/models/usuario_propiedad_response.dart';

class AppBarResidente extends StatelessWidget implements PreferredSizeWidget {
  /// Callback opcional — se llama al cambiar de propiedad para que el
  /// padre recargue los datos dependientes (estadísticas, actividad, etc.)
  final void Function(UsuarioPropiedadResponse propiedad)? onPropiedadCambiada;

  const AppBarResidente({super.key, this.onPropiedadCambiada});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final propiedades = context.watch<PropiedadProvider>();
    final cs = Theme.of(context).colorScheme;

    return AppBar(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar con iniciales del usuario (circular + accesible)
          Semantics(
            label: 'Usuario: ${auth.nombre ?? ""}',
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  TextoUtils.getIniciales(auth.nombre ?? 'Usuario'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              auth.nombreConjunto ?? 'Conjunto Residencial',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.5,
                color: cs.primary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      // Dropdown de selección de propiedad (solo visible si hay >1 propiedad)
      actions: [
        PropiedadSelectorDropdown(
          onPropiedadCambiada: onPropiedadCambiada ?? (_) {},
        ),
      ],
    );
  }
}
