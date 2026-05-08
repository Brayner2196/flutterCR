import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/anuncio_model.dart';
import '../../providers/anuncio_provider.dart';
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Anuncios')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : provider.anuncios.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.campaign_outlined, size: 64, color: cs.outline),
                          const SizedBox(height: 12),
                          const Text('No hay anuncios activos'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.cargarResidente(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.anuncios.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _AnuncioResidenteCard(
                          anuncio: provider.anuncios[i],
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetalleAnuncioScreen(anuncio: provider.anuncios[i]),
                              ),
                            );
                            // recarga para actualizar el badge de visto
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

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: anuncio.vistoPorMi
                      ? cs.surfaceContainerHighest
                      : cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.campaign_outlined,
                  color: anuncio.vistoPorMi ? cs.outline : cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            anuncio.titulo,
                            style: TextStyle(
                              fontWeight: anuncio.vistoPorMi ? FontWeight.normal : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!anuncio.vistoPorMi)
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      anuncio.contenido,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      anuncio.vistoPorMi ? 'Visto' : 'Nuevo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: anuncio.vistoPorMi ? cs.outline : cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
