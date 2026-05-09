import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/votacion_model.dart';
import '../../providers/votacion_provider.dart';
import 'votar_screen.dart';

class MisVotacionesScreen extends StatefulWidget {
  const MisVotacionesScreen({super.key});

  @override
  State<MisVotacionesScreen> createState() => _MisVotacionesScreenState();
}

class _MisVotacionesScreenState extends State<MisVotacionesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VotacionProvider>().cargarResidente();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VotacionProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Votaciones')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : provider.votaciones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.how_to_vote_outlined, size: 64, color: cs.outline),
                          const SizedBox(height: 12),
                          const Text('No hay votaciones abiertas'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.cargarResidente(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.votaciones.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _VotacionResidenteCard(
                          votacion: provider.votaciones[i],
                        ),
                      ),
                    ),
    );
  }
}

class _VotacionResidenteCard extends StatelessWidget {
  final VotacionModel votacion;
  const _VotacionResidenteCard({required this.votacion});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final yaVoto = votacion.yaVote;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    votacion.titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                if (yaVoto)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Votado',
                        style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Pendiente',
                        style: TextStyle(
                            color: cs.onPrimaryContainer, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            if (votacion.descripcion != null) ...[
              const SizedBox(height: 6),
              Text(votacion.descripcion!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.how_to_vote_outlined, size: 14, color: cs.outline),
                const SizedBox(width: 4),
                Text('${votacion.totalVotantes} han votado',
                    style: TextStyle(fontSize: 11, color: cs.outline)),
                const Spacer(),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => VotarScreen(votacion: votacion)),
                    ).then((_) => context.read<VotacionProvider>().cargarResidente()),
                    child: Text(yaVoto
                        ? (votacion.permiteCambiarVoto ? 'Ver / Cambiar' : 'Ver resultados')
                        : 'Participar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
