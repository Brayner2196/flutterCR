import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/anuncio_model.dart';
import '../../providers/anuncio_provider.dart';
import '../../utils/fecha_relativa.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state_widget.dart';

class AdminVistasAnuncioScreen extends StatefulWidget {
  final AnuncioModel anuncio;
  const AdminVistasAnuncioScreen({super.key, required this.anuncio});

  @override
  State<AdminVistasAnuncioScreen> createState() =>
      _AdminVistasAnuncioScreenState();
}

class _AdminVistasAnuncioScreenState extends State<AdminVistasAnuncioScreen> {
  List<AnuncioVistaModel> _vistas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    _vistas = await context.read<AnuncioProvider>().cargarVistas(widget.anuncio.id);
    if (mounted) setState(() => _loading = false);
  }

  String? _primeraVistaRelativa() {
    if (_vistas.isEmpty) return null;
    DateTime? min;
    for (final v in _vistas) {
      try {
        final dt = DateTime.parse(v.vistoEn);
        if (min == null || dt.isBefore(min)) min = dt;
      } catch (_) {}
    }
    if (min == null) return null;
    return fechaRelativa(min.toIso8601String());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Vistas — ${widget.anuncio.titulo}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vistas.isEmpty
              ? const EmptyStateWidget(
                  icono: Icons.visibility_off_outlined,
                  mensaje: 'Nadie ha visto este anuncio aún',
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      _KpiCard(
                        total: _vistas.length,
                        primeraVistaRel: _primeraVistaRelativa(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Lista de lecturas',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          side: BorderSide(color: cs.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < _vistas.length; i++) ...[
                              if (i > 0)
                                Divider(
                                    height: 1, color: cs.outlineVariant),
                              _VistaTile(vista: _vistas[i]),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _BannerNoVistos(),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final int total;
  final String? primeraVistaRel;
  const _KpiCard({required this.total, required this.primeraVistaRel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$total',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              height: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            total == 1
                ? 'residente vio este anuncio'
                : 'residentes vieron este anuncio',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant),
          ),
          if (primeraVistaRel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'primera vista $primeraVistaRel',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _VistaTile extends StatelessWidget {
  final AnuncioVistaModel vista;
  const _VistaTile({required this.vista});

  String _formatear(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inicial = vista.residenteNombre.isNotEmpty
        ? vista.residenteNombre[0].toUpperCase()
        : '?';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.bgBlue,
        child: Text(
          inicial,
          style: const TextStyle(
            color: AppColors.blue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(vista.residenteNombre),
      subtitle: Text('Visto el ${_formatear(vista.vistoEn)}'),
      trailing: const Icon(Icons.check_circle_outline, color: AppColors.ok),
    );
  }
}

class _BannerNoVistos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: cs.onSurfaceVariant, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'El listado de quienes aún no leyeron estará disponible próximamente',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
