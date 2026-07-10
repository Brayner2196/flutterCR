import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../propiedades/providers/propiedad_provider.dart';
import '../../models/publicacion_model.dart';
import '../../services/publicacion_service.dart';
import 'publicacion_form_sheet.dart';

class MisPublicacionesScreen extends StatefulWidget {
  const MisPublicacionesScreen({super.key});

  @override
  State<MisPublicacionesScreen> createState() => _MisPublicacionesScreenState();
}

class _MisPublicacionesScreenState extends State<MisPublicacionesScreen> {
  List<PublicacionModel> _publicaciones = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final lista = await PublicacionService.getMisPublicaciones();
      if (mounted) setState(() => _publicaciones = lista);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _abrirFormulario({PublicacionModel? pub}) {
    // Al crear, validamos que el residente tenga propiedad asignada
    if (pub == null) {
      final propiedadId = context
          .read<PropiedadProvider>()
          .propiedadActual
          ?.propiedadId;

      if (propiedadId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Necesitas tener una propiedad asignada para crear una publicación.',
            ),
            backgroundColor: AppColors.danger,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PublicacionFormSheet(
          onGuardado: _cargar,
          propiedadId: propiedadId,
        ),
      );
      return;
    }

    // Edición: no se necesita propiedadId
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PublicacionFormSheet(publicacion: pub, onGuardado: _cargar),
    );
  }

  Future<void> _cambiarEstado(PublicacionModel pub, String nuevoEstado) async {
    try {
      await PublicacionService.cambiarEstado(pub.id, nuevoEstado);
      _cargar();
      _toast(ToastificationType.success, 'Estado actualizado');
    } catch (e) {
      _toast(ToastificationType.error, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _eliminar(PublicacionModel pub) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: Text('¿Eliminar "${pub.titulo}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await PublicacionService.eliminar(pub.id);
      _cargar();
      _toast(ToastificationType.success, 'Publicación eliminada');
    } catch (e) {
      if (mounted) {
        _toast(ToastificationType.error, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _toast(ToastificationType tipo, String msg) {
    if (!mounted) return;
    toastification.show(
      context: context,
      type: tipo,
      title: Text(msg),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis publicaciones')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_mis_pub',
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva publicación'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: TextStyle(color: cs.error)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                          onPressed: _cargar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar')),
                    ],
                  ),
                )
              : _publicaciones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.store_mall_directory_outlined,
                              size: 56, color: cs.outline),
                          const SizedBox(height: 14),
                          Text('Aún no tienes publicaciones',
                              style: TextStyle(color: cs.onSurfaceVariant)),
                          const SizedBox(height: 12),
                          
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: _publicaciones.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _MiPublicacionTile(
                          pub: _publicaciones[i],
                          onEditar: () => _abrirFormulario(pub: _publicaciones[i]),
                          onCambiarEstado: (e) => _cambiarEstado(_publicaciones[i], e),
                          onEliminar: () => _eliminar(_publicaciones[i]),
                        ),
                      ),
                    ),
    );
  }
}

// ── Tile de publicación propia ────────────────────────────────────────────────

class _MiPublicacionTile extends StatelessWidget {
  final PublicacionModel pub;
  final VoidCallback onEditar;
  final void Function(String estado) onCambiarEstado;
  final VoidCallback onEliminar;

  const _MiPublicacionTile({
    required this.pub,
    required this.onEditar,
    required this.onCambiarEstado,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final (fg, bg) = _coloresEstado(pub.estado, cs);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha:0.5)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fila 1: estado + fecha + menú ──────────────────
          Row(
            children: [
              _EstadoBadge(estado: pub.estadoLegible, fg: fg, bg: bg),
              const Spacer(),
              Text(pub.fechaCorta,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              _MenuAcciones(
                pub: pub,
                onEditar: onEditar,
                onCambiarEstado: onCambiarEstado,
                onEliminar: onEliminar,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Título ─────────────────────────────────────────
          Text(pub.titulo,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),

          // ── Marca ──────────────────────────────────────────
          if (pub.marca != null && pub.marca!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(pub.marca!,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
          const SizedBox(height: 8),

          // ── Precio + categoría ─────────────────────────────
          Row(
            children: [
              Text(pub.precioFormateado,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: cs.primary)),
              const Spacer(),
              _CategoriaChip(label: pub.categoriaLegible),
            ],
          ),
          const SizedBox(height: 8),

          // ── Badges: stock + delivery + métodos de pago ─────
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (pub.stock != null) _StockBadge(stock: pub.stock!),
              _DeliveryBadge(acepta: pub.aceptaDomicilio),
              ...pub.metodosPago.map((m) => _MetodoBadge(metodo: m)),
            ],
          ),
        ],
      ),
    );
  }

  (Color, Color) _coloresEstado(String estado, ColorScheme cs) {
    switch (estado) {
      case 'ACTIVA':  return (AppColors.ok, AppColors.bgGreen);
      case 'PAUSADA': return (AppColors.warning, AppColors.warningSoft);
      case 'VENDIDA': return (cs.primary, cs.primaryContainer);
      default:        return (cs.onSurfaceVariant, cs.surfaceContainerHighest);
    }
  }
}

// ── Menú de acciones ──────────────────────────────────────────────────────────

class _MenuAcciones extends StatelessWidget {
  final PublicacionModel pub;
  final VoidCallback onEditar;
  final void Function(String) onCambiarEstado;
  final VoidCallback onEliminar;

  const _MenuAcciones({
    required this.pub,
    required this.onEditar,
    required this.onCambiarEstado,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 18, color: cs.onSurfaceVariant),
      onSelected: (v) {
        if (v == 'editar')  onEditar();
        if (v == 'pausar')  onCambiarEstado('PAUSADA');
        if (v == 'activar') onCambiarEstado('ACTIVA');
        if (v == 'vendido') onCambiarEstado('VENDIDA');
        if (v == 'eliminar') onEliminar();
      },
      itemBuilder: (_) => [
        if (pub.esActiva || pub.esPausada)
          _item('editar', Icons.edit_outlined, 'Editar'),
        if (pub.esActiva)
          _item('pausar', Icons.pause_circle_outline, 'Pausar'),
        if (pub.esPausada)
          _item('activar', Icons.play_circle_outline, 'Activar'),
        if (!pub.esVendida)
          _item('vendido', Icons.check_circle_outline, 'Marcar vendido'),
        PopupMenuItem(
          value: 'eliminar',
          child: Row(children: [
            const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
            const SizedBox(width: 8),
            Text('Eliminar',
                style: const TextStyle(color: AppColors.danger)),
          ]),
        ),
      ],
    );
  }

  PopupMenuItem<String> _item(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ]),
    );
  }
}

// ── Badges y chips ────────────────────────────────────────────────────────────

class _EstadoBadge extends StatelessWidget {
  final String estado;
  final Color fg;
  final Color bg;
  const _EstadoBadge({required this.estado, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(estado,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}

class _CategoriaChip extends StatelessWidget {
  final String label;
  const _CategoriaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stock;
  const _StockBadge({required this.stock});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    if (stock <= 0) {
      bg = AppColors.dangerSoft; fg = AppColors.danger; label = 'Agotado';
    } else if (stock == 1) {
      bg = AppColors.warningSoft; fg = AppColors.warning; label = 'Último';
    } else {
      bg = AppColors.bgGreen; fg = AppColors.ok; label = '$stock uds.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

class _DeliveryBadge extends StatelessWidget {
  final bool acepta;
  const _DeliveryBadge({required this.acepta});

  @override
  Widget build(BuildContext context) {
    final Color bg   = acepta ? AppColors.bgBlue : AppColors.neutralSoft;
    final Color fg   = acepta ? AppColors.blue : AppColors.textLoLight;
    final String lbl = acepta ? 'Con domicilio' : 'Sin domicilio';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delivery_dining_outlined, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(lbl,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

class _MetodoBadge extends StatelessWidget {
  final String metodo;
  const _MetodoBadge({required this.metodo});

  String get _label {
    switch (metodo.toUpperCase()) {
      case 'EFECTIVO':      return 'Efectivo';
      case 'NEQUI':         return 'Nequi';
      case 'DAVIPLATA':     return 'Daviplata';
      case 'TRANSFERENCIA': return 'Transfer.';
      case 'BANCOLOMBIA':   return 'Bancolombia';
      default:              return metodo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.payments_outlined, size: 10, color: cs.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(_label,
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
