import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'package:flutter_residential/core/utils/date_formatter.dart';
import '../../vigilancia/models/paquete_model.dart';
import '../providers/paquete_residente_provider.dart';

/// Pantalla del residente para ver la correspondencia recibida en portería.
class MisPaquetesScreen extends StatefulWidget {
  const MisPaquetesScreen({super.key});

  @override
  State<MisPaquetesScreen> createState() => _MisPaquetesScreenState();
}

class _MisPaquetesScreenState extends State<MisPaquetesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<PaqueteResidenteProvider>().cargar());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PaqueteResidenteProvider>();
    final paquetes = prov.paquetes;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis paquetes')),
      body: RefreshIndicator(
        onRefresh: () => prov.cargar(),
        child: prov.loading && paquetes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : paquetes.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Icon(Icons.inbox_rounded, size: 64, color: AppColors.textLoLight),
                      SizedBox(height: AppSpacing.md),
                      Center(child: Text('No tienes paquetes registrados')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: paquetes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _PaqueteTile(paquete: paquetes[i]),
                  ),
      ),
    );
  }
}

class _PaqueteTile extends StatelessWidget {
  final PaqueteModel paquete;

  const _PaqueteTile({required this.paquete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entregado = paquete.esEntregado;
    final color = entregado ? AppColors.ok : AppColors.orange;
    final bg = entregado ? AppColors.okSoft : AppColors.bgOrange;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              entregado ? Icons.assignment_turned_in_rounded : Icons.inventory_2_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(paquete.descripcion,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  entregado
                      ? 'Entregado ${DateFormatter.fechaHora(paquete.entregadoEn)}'
                      : 'En portería desde ${DateFormatter.fechaHora(paquete.recibidoEn)}',
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                ),
                if (paquete.transportadora != null)
                  Text(paquete.transportadora!,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
