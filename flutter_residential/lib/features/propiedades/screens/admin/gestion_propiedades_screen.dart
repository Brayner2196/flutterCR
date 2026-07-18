import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/propiedad_admin.dart';
import '../../providers/gestion_propiedades_provider.dart';
import '../../widgets/propiedad_card.dart';
import '../../widgets/propiedad_detalle_sheet.dart';

/// Filtros disponibles en la barra de estadísticas. Conjunto vacío = "Total"
/// (se muestran todas las unidades).
enum FiltroPropiedad { ocupadas, disponibles, mantenimiento, sinResidentes }

/// Módulo admin de gestión de propiedades (unidades): búsqueda, estadísticas
/// que a la vez actúan como filtros (activables/desactivables) y acceso al
/// detalle con residentes y estado.
class GestionPropiedadesScreen extends StatefulWidget {
  const GestionPropiedadesScreen({super.key});

  @override
  State<GestionPropiedadesScreen> createState() =>
      _GestionPropiedadesScreenState();
}

class _GestionPropiedadesScreenState extends State<GestionPropiedadesScreen> {
  String _busqueda = '';
  final TextEditingController _searchController = TextEditingController();

  /// Filtros activos. Vacío = "Total" (todas las unidades). Selección múltiple:
  /// la lista muestra la unión de los estados/condiciones activos.
  final Set<FiltroPropiedad> _filtros = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GestionPropiedadesProvider>().cargarTodas();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _abrirDetalle(PropiedadAdmin p) {
    PropiedadDetalleSheet.mostrar(context, p.id);
  }

  void _toggleFiltro(FiltroPropiedad f) {
    setState(() {
      if (!_filtros.remove(f)) _filtros.add(f);
    });
  }

  void _mostrarTodas() {
    setState(_filtros.clear);
  }

  /// True si la propiedad coincide con los filtros activos (unión / OR).
  /// Sin filtros activos, todas coinciden.
  bool _coincideFiltro(PropiedadAdmin p) {
    if (_filtros.isEmpty) return true;
    for (final f in _filtros) {
      switch (f) {
        case FiltroPropiedad.ocupadas:
          if (p.estado == EstadoPropiedad.ocupado) return true;
        case FiltroPropiedad.disponibles:
          if (p.estado == EstadoPropiedad.disponible) return true;
        case FiltroPropiedad.mantenimiento:
          if (p.estado == EstadoPropiedad.enMantenimiento) return true;
        case FiltroPropiedad.sinResidentes:
          if (p.sinResidentes) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.scrim,
      child: Column(
        children: [
          // ── Buscador ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.search, color: Colors.grey.shade600),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(
                        () => _busqueda = value.trim().toLowerCase(),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Buscar unidad, tipo o residente...',
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  if (_busqueda.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey.shade600),
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _busqueda = '');
                      },
                    ),
                ],
              ),
            ),
          ),

          // ── Estadísticas-filtro (activables/desactivables) ────────────
          Consumer<GestionPropiedadesProvider>(
            builder: (_, provider, __) => _StatsFiltroBar(
              provider: provider,
              filtros: _filtros,
              onToggle: _toggleFiltro,
              onTotal: _mostrarTodas,
            ),
          ),

          // ── Lista filtrada ────────────────────────────────────────────
          Expanded(
            child: _ListaPropiedades(
              coincideFiltro: _coincideFiltro,
              busqueda: _busqueda,
              onTap: _abrirDetalle,
              hayFiltros: _filtros.isNotEmpty,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barra de estadísticas que actúan como filtros ─────────────────────────────
class _StatsFiltroBar extends StatelessWidget {
  final GestionPropiedadesProvider provider;
  final Set<FiltroPropiedad> filtros;
  final void Function(FiltroPropiedad) onToggle;
  final VoidCallback onTotal;

  const _StatsFiltroBar({
    required this.provider,
    required this.filtros,
    required this.onToggle,
    required this.onTotal,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.total == 0) return const SizedBox.shrink();
    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _StatChip(
            label: 'Total',
            valor: provider.total,
            color: const Color(0xFF334155),
            icono: Icons.home_work_outlined,
            seleccionado: filtros.isEmpty,
            onTap: onTotal,
          ),
          _StatChip(
            label: 'Ocupadas',
            valor: provider.totalOcupadas,
            color: EstadoPropiedad.color(EstadoPropiedad.ocupado),
            icono: Icons.person_outline,
            seleccionado: filtros.contains(FiltroPropiedad.ocupadas),
            onTap: () => onToggle(FiltroPropiedad.ocupadas),
          ),
          _StatChip(
            label: 'Disponibles',
            valor: provider.totalDisponibles,
            color: EstadoPropiedad.color(EstadoPropiedad.disponible),
            icono: Icons.check_circle_outline,
            seleccionado: filtros.contains(FiltroPropiedad.disponibles),
            onTap: () => onToggle(FiltroPropiedad.disponibles),
          ),
          _StatChip(
            label: 'Mantenim.',
            valor: provider.totalMantenimiento,
            color: EstadoPropiedad.color(EstadoPropiedad.enMantenimiento),
            icono: Icons.build_outlined,
            seleccionado: filtros.contains(FiltroPropiedad.mantenimiento),
            onTap: () => onToggle(FiltroPropiedad.mantenimiento),
          ),
          _StatChip(
            label: 'Sin residente',
            valor: provider.totalSinResidentes,
            color: const Color(0xFFDC2626),
            icono: Icons.people_outline,
            seleccionado: filtros.contains(FiltroPropiedad.sinResidentes),
            onTap: () => onToggle(FiltroPropiedad.sinResidentes),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int valor;
  final Color color;
  final IconData icono;
  final bool seleccionado;
  final VoidCallback onTap;

  const _StatChip({
    required this.label,
    required this.valor,
    required this.color,
    required this.icono,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Seleccionado → relleno con el color de estado y texto blanco.
    // Sin seleccionar → fondo blanco con borde/valor del color de estado.
    final bg = seleccionado ? color : Colors.white;
    final fg = seleccionado ? Colors.white : color;
    final labelColor =
        seleccionado ? Colors.white.withValues(alpha: 0.9) : Colors.grey.shade700;

    return Container(
      margin: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 112,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: seleccionado ? color : color.withValues(alpha: 0.25),
                width: seleccionado ? 1 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(icono, size: 15, color: fg),
                    const SizedBox(width: 4),
                    Text(
                      '$valor',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: fg,
                      ),
                    ),
                    if (seleccionado) ...[
                      const Spacer(),
                      const Icon(Icons.check, size: 14, color: Colors.white),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(color: labelColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Lista de propiedades (filtro de estado + búsqueda) ─────────────────────────
class _ListaPropiedades extends StatelessWidget {
  final bool Function(PropiedadAdmin) coincideFiltro;
  final void Function(PropiedadAdmin) onTap;
  final String busqueda;
  final bool hayFiltros;

  const _ListaPropiedades({
    required this.coincideFiltro,
    required this.onTap,
    required this.busqueda,
    required this.hayFiltros,
  });

  bool _coincideBusqueda(PropiedadAdmin p) {
    if (busqueda.isEmpty) return true;
    if (p.pathTexto.toLowerCase().contains(busqueda)) return true;
    if (p.titulo.toLowerCase().contains(busqueda)) return true;
    if (p.nombreTipo.toLowerCase().contains(busqueda)) return true;
    return p.residentes
        .any((r) => r.nombre.toLowerCase().contains(busqueda));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GestionPropiedadesProvider>(
      builder: (_, provider, __) {
        if (provider.loading && provider.propiedades.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null && provider.propiedades.isEmpty) {
          return _ErrorView(
            mensaje: provider.error!,
            onReintentar: () => provider.cargarTodas(),
          );
        }

        final lista = provider.propiedades
            .where(coincideFiltro)
            .where(_coincideBusqueda)
            .toList();

        if (lista.isEmpty) {
          final mensaje = busqueda.isNotEmpty
              ? 'No hay unidades que coincidan con la búsqueda'
              : hayFiltros
                  ? 'No hay unidades que coincidan con los filtros'
                  : 'No hay unidades registradas';
          return _EmptyView(mensaje: mensaje, icono: Icons.home_work_outlined);
        }

        return RefreshIndicator(
          onRefresh: () => provider.cargarTodas(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            itemCount: lista.length,
            itemBuilder: (_, i) =>
                PropiedadCard(propiedad: lista[i], onTap: () => onTap(lista[i])),
          ),
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String mensaje;
  final IconData icono;

  const _EmptyView({required this.mensaje, this.icono = Icons.home_work_outlined});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 64, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            mensaje,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _ErrorView({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(mensaje,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
