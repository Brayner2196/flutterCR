import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/miembro_consejo_model.dart';
import '../providers/consejo_provider.dart';

/// Directorio público del consejo — accesible a todos los residentes.
class ConsejoDirectorioScreen extends StatefulWidget {
  const ConsejoDirectorioScreen({super.key});

  @override
  State<ConsejoDirectorioScreen> createState() =>
      _ConsejoDirectorioScreenState();
}

class _ConsejoDirectorioScreenState extends State<ConsejoDirectorioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsejoProvider>().cargarDirectorio();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ConsejoProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Consejo Comunal')),
      body: RefreshIndicator(
        onRefresh: () => context.read<ConsejoProvider>().cargarDirectorio(),
        child: p.loading && p.directorio.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : p.error != null && p.directorio.isEmpty
                ? Center(
                    child: Text(p.error!,
                        style: TextStyle(color: cs.error)))
                : p.directorio.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline,
                                size: 48, color: cs.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text('No hay miembros del consejo activos',
                                style:
                                    TextStyle(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: p.directorio.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, i) =>
                            _MiembroTile(miembro: p.directorio[i]),
                      ),
      ),
    );
  }
}

class _MiembroTile extends StatelessWidget {
  final MiembroConsejoModel miembro;

  const _MiembroTile({required this.miembro});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bgPurple,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.person_rounded,
                color: AppColors.purple, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  miembro.nombreUsuario,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  miembro.cargoTexto,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.purple,
                      fontWeight: FontWeight.w600),
                ),
                if (miembro.fechaInicio.isNotEmpty)
                  Text(
                    'Desde ${miembro.fechaInicio}',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
