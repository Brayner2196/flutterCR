import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/anuncio_model.dart';
import '../../providers/anuncio_provider.dart';
import '../../utils/fecha_relativa.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import 'detalle_anuncio_screen.dart';

class MisAnunciosScreen extends StatefulWidget {
  const MisAnunciosScreen({super.key});

  @override
  State<MisAnunciosScreen> createState() => _MisAnunciosScreenState();
}

class _MisAnunciosScreenState extends State<MisAnunciosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnuncioProvider>().cargarResidente();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnuncioProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Anuncios')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : provider.anuncios.isEmpty
                  ? const EmptyStateWidget(
                      icono: Icons.campaign_outlined,
                      mensaje: 'No hay anuncios activos',
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.cargarResidente(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: provider.anuncios.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm + 2),
                        itemBuilder: (_, i) => _AnuncioResidenteCard(
                          anuncio: provider.anuncios[i],
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetalleAnuncioScreen(
                                    anuncio: provider.anuncios[i]),
                              ),
                            );
                            if (mounted) provider.cargarResidente();
                          },
                        ),
                      ),
                    ),
    );
  }
}

class _AnuncioResidenteCard extends StatelessWidget {
  final AnuncioModel anuncio;
  final VoidCallback onTap;
  const _AnuncioResidenteCard({required this.anuncio, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final leido = anuncio.vistoPorMi;

    final tituloStyle = TextStyle(
      fontSize: 15,
      fontWeight: leido ? FontWeight.w400 : FontWeight.w700,
      color: cs.onSurface.withValues(alpha: leido ? 0.6 : 1.0),
    );

    final contenidoStyle = TextStyle(
      fontSize: 13,
      color: cs.onSurfaceVariant.withValues(alpha: leido ? 0.7 : 1.0),
    );

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            anuncio.titulo,
                            style: tituloStyle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!leido) ...[
                          const SizedBox(width: AppSpacing.sm),
                          const _PildoraNuevo(),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      anuncio.contenido,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: contenidoStyle,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      fechaRelativa(anuncio.creadoEn),
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PildoraNuevo extends StatelessWidget {
  const _PildoraNuevo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgBlue,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: const Text(
        'Nuevo',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.blue,
        ),
      ),
    );
  }
}
