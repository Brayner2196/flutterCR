import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/usuario_propiedad_response.dart';
import '../../providers/propiedad_provider.dart';

class MiPropiedadScreen extends StatefulWidget {
  const MiPropiedadScreen({super.key});

  @override
  State<MiPropiedadScreen> createState() => _MiPropiedadScreenState();
}

class _MiPropiedadScreenState extends State<MiPropiedadScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropiedadProvider>().cargarMisPropiedades();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PropiedadProvider>();
    final theme = Theme.of(context);

    if (provider.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.misPropiedades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Sin propiedad asignada',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'El administrador debe asignarte una propiedad.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final propiedadActual = provider.propiedadActual;

    return Column(
      children: [
        if (provider.misPropiedades.length > 1)
          _SelectorPropiedades(
            propiedades: provider.misPropiedades,
            seleccionada: propiedadActual,
            onSeleccionar: (p) =>
                context.read<PropiedadProvider>().seleccionarPropiedad(p),
          ),

        Expanded(
          child: propiedadActual == null
              ? const Center(child: CircularProgressIndicator())
              : _DetallePropiedadCard(propiedad: propiedadActual),
        ),
      ],
    );
  }
}

class _SelectorPropiedades extends StatelessWidget {
  final List<UsuarioPropiedadResponse> propiedades;
  final UsuarioPropiedadResponse? seleccionada;
  final void Function(UsuarioPropiedadResponse) onSeleccionar;

  const _SelectorPropiedades({
    required this.propiedades,
    required this.seleccionada,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mis propiedades',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: propiedades.map((p) {
              final selected = p.propiedadId == seleccionada?.propiedadId;
              return FilterChip(
                selected: selected,
                label: Text(p.pathTexto),
                onSelected: (_) => onSeleccionar(p),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DetallePropiedadCard extends StatelessWidget {
  final UsuarioPropiedadResponse propiedad;

  const _DetallePropiedadCard({required this.propiedad});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.home_work_outlined,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              propiedad.pathTexto,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (propiedad.nombreTipoRaiz.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  propiedad.nombreTipoRaiz,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (propiedad.esPrincipal)
                        Tooltip(
                          message: 'Propiedad principal',
                          child: Icon(Icons.star,
                              color: theme.colorScheme.primary, size: 20),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
