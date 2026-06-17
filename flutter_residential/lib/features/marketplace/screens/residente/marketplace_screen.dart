import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/publicacion_model.dart';
import '../../providers/publicacion_provider.dart';
import 'mis_publicaciones_screen.dart';
import 'publicacion_detalle_sheet.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _busquedaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PublicacionProvider>().cargar();
    });
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<PublicacionProvider>(),
        child: const _FiltrosSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prov = context.watch<PublicacionProvider>();
    final lista = prov.publicaciones;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.store_outlined),
            tooltip: 'Mis publicaciones',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MisPublicacionesScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de búsqueda + botón filtros ─────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _busquedaCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar productos, marcas…',
                      prefixIcon:
                          const Icon(Icons.search_outlined, size: 20),
                      suffixIcon: _busquedaCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _busquedaCtrl.clear();
                                prov.setBusqueda('');
                              },
                            )
                          : null,
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    onChanged: prov.setBusqueda,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: prov.hayFiltrosActivos,
                  child: IconButton.outlined(
                    onPressed: _abrirFiltros,
                    icon: const Icon(Icons.tune_outlined),
                    tooltip: 'Filtros',
                  ),
                ),
              ],
            ),
          ),

          // ── Chips de categoría ─────────────────────────────
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                _FiltroChip(
                  label: 'Todas',
                  activo: prov.categoria == null,
                  onTap: () => prov.setCategoria(null),
                ),
                ...kCategorias.map((cat) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _FiltroChip(
                        label: cat.$2,
                        activo: prov.categoria == cat.$1,
                        onTap: () => prov.setCategoria(
                            prov.categoria == cat.$1 ? null : cat.$1),
                      ),
                    )),
              ],
            ),
          ),

          // ── Barra de estado: resultados + limpiar filtros ──
          if (prov.hayFiltrosActivos || prov.busqueda.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 14,
                      color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${lista.length} resultado${lista.length != 1 ? 's' : ''}',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      prov.limpiarFiltros();
                      _busquedaCtrl.clear();
                    },
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0)),
                    child: const Text('Limpiar', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // ── Chip de radio de proximidad activo ─────────────
          if (prov.radioProximidad < 3)
            Padding(
              padding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgTeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_outlined,
                            size: 12, color: AppColors.teal),
                        const SizedBox(width: 4),
                        Text(
                          _labelRadio(prov.radioProximidad),
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.teal,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => prov.setRadioProximidad(3),
                          child: const Icon(Icons.close,
                              size: 12, color: AppColors.teal),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Lista de publicaciones ─────────────────────────
          Expanded(
            child: prov.loading
                ? const Center(child: CircularProgressIndicator())
                : prov.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(prov.error!,
                                style: TextStyle(color: cs.error),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: prov.cargar,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : lista.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.storefront_outlined,
                                    size: 56, color: cs.outline),
                                const SizedBox(height: 14),
                                Text(
                                  prov.hayFiltrosActivos ||
                                          prov.busqueda.isNotEmpty
                                      ? 'Sin resultados para tu búsqueda'
                                      : 'No hay productos disponibles',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: prov.cargar,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: lista.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) => _PublicacionCard(
                                pub: lista[i],
                                onTap: () => PublicacionDetalleSheet.mostrar(
                                    context, lista[i]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  String _labelRadio(int radio) {
    switch (radio) {
      case 0: return 'Solo mi piso';
      case 1: return 'Pisos adyacentes';
      case 2: return 'Mi torre';
      default: return 'Todo el conjunto';
    }
  }
}

// ── Card de publicación ───────────────────────────────────────────────────────

class _PublicacionCard extends StatelessWidget {
  final PublicacionModel pub;
  final VoidCallback onTap;

  const _PublicacionCard({required this.pub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: pub.agotado ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: pub.agotado ? 0.55 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Fila superior: categoría + proximidad + fecha
              Row(
                children: [
                  _CategoriaChip(label: pub.categoriaLegible),
                  const SizedBox(width: 6),
                  if (pub.distanciaProximidad != null)
                    _ProximidadChip(distancia: pub.distanciaProximidad!),
                  const Spacer(),
                  Text(pub.fechaCorta,
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 8),

              // ── Título + marca
              Text(pub.titulo,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              if (pub.marca != null && pub.marca!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(pub.marca!,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],

              // ── Descripción preview
              if (pub.descripcion != null && pub.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(pub.descripcion!,
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),

              // ── Fila inferior: precio + badges + vendedor
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pub.precioFormateado,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: cs.primary)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 5,
                          children: [
                            if (pub.stock != null)
                              _StockMiniChip(stock: pub.stock!),
                            if (pub.aceptaDomicilio)
                              _DeliveryMiniChip(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 13, color: cs.onSurfaceVariant),
                      const SizedBox(width: 3),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(pub.vendedorNombre,
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini badges para la card ──────────────────────────────────────────────────

class _StockMiniChip extends StatelessWidget {
  final int stock;
  const _StockMiniChip({required this.stock});

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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _DeliveryMiniChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: AppColors.bgBlue, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.delivery_dining_outlined,
              size: 10, color: AppColors.blue),
          SizedBox(width: 3),
          Text('Domicilio',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue)),
        ],
      ),
    );
  }
}

// ── Chips de categoría y proximidad ──────────────────────────────────────────

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
          style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
    );
  }
}

class _ProximidadChip extends StatelessWidget {
  final int distancia;
  const _ProximidadChip({required this.distancia});

  String get _label {
    if (distancia == 0) return 'Tu propiedad';
    if (distancia <= 2) return 'Mismo piso';
    if (distancia <= 4) return 'Misma torre';
    return 'En el conjunto';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgTeal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me_outlined, size: 10, color: AppColors.teal),
          const SizedBox(width: 3),
          Text(_label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.teal,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _FiltroChip(
      {required this.label, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: activo ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activo ? cs.primary : cs.outline),
        ),
        child: Center(
          heightFactor: 1,
          child: Text(label,
              style: TextStyle(
                  color: activo ? cs.onPrimaryContainer : cs.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ── Sheet de filtros avanzados ────────────────────────────────────────────────

class _FiltrosSheet extends StatefulWidget {
  const _FiltrosSheet();

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  late int _radio;
  late bool _domicilio;
  late String? _marca;
  late OrdenMarketplace _orden;
  final _precioMinCtrl = TextEditingController();
  final _precioMaxCtrl = TextEditingController();

  static const _radiosLabel = [
    'Mi piso',
    'Pisos Cercanos',
    'Mi torre',
    'Todo el conjunto',
  ];

  static const _ordenesLabel = [
    (OrdenMarketplace.masReciente, 'Más recientes'),
    (OrdenMarketplace.precioMenor, 'Precio: menor primero'),
    (OrdenMarketplace.precioMayor, 'Precio: mayor primero'),
    (OrdenMarketplace.masLejano, 'Más lejanos'),
  ];

  @override
  void initState() {
    super.initState();
    final prov = context.read<PublicacionProvider>();
    _radio = prov.radioProximidad;
    _domicilio = prov.soloConDomicilio;
    _marca = prov.marcaFiltro;
    _orden = prov.orden;
    if (prov.precioMin != null) {
      _precioMinCtrl.text = prov.precioMin!.toStringAsFixed(0);
    }
    if (prov.precioMax != null) {
      _precioMaxCtrl.text = prov.precioMax!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _precioMinCtrl.dispose();
    _precioMaxCtrl.dispose();
    super.dispose();
  }

  void _aplicar() {
    final prov = context.read<PublicacionProvider>();
    prov.setRadioProximidad(_radio);
    prov.setSoloConDomicilio(_domicilio);
    prov.setMarcaFiltro(_marca);
    prov.setOrden(_orden);
    prov.setPrecioMin(_precioMinCtrl.text.isEmpty
        ? null
        : double.tryParse(_precioMinCtrl.text));
    prov.setPrecioMax(_precioMaxCtrl.text.isEmpty
        ? null
        : double.tryParse(_precioMaxCtrl.text));
    Navigator.of(context).pop();
  }

  void _limpiar() {
    setState(() {
      _radio = 3;
      _domicilio = false;
      _marca = null;
      _orden = OrdenMarketplace.masReciente;
      _precioMinCtrl.clear();
      _precioMaxCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final prov = context.watch<PublicacionProvider>();
    final marcas = prov.marcasDisponibles;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Título
            Row(
              children: [
                Text('Filtros',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                    onPressed: _limpiar,
                    child: const Text('Limpiar todo')),
              ],
            ),
            const SizedBox(height: 16),

            // ── Proximidad ────────────────────────────────────
            Text('Rango de proximidad',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: cs.primary)),
            const SizedBox(height: 4),
            Text(
              _radiosLabel[_radio],
                style: TextStyle(
                    fontSize: 13, color: cs.onSurfaceVariant)),
            Slider(
              value: _radio.toDouble(),
              min: 0,
              max: 3,
              divisions: 3,
              onChanged: (v) => setState(() => _radio = v.round()),
            ),
            

            // ── Precio ────────────────────────────────────────
            Text('Rango de precio',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: cs.primary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _precioMinCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Mínimo',
                      prefixText: '\$',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('—'),
                ),
                Expanded(
                  child: TextField(
                    controller: _precioMaxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Máximo',
                      prefixText: '\$',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Domicilio ─────────────────────────────────────
            SwitchListTile(
              value: _domicilio,
              onChanged: (v) => setState(() => _domicilio = v),
              contentPadding: EdgeInsets.zero,
              title: const Text('Solo con domicilio',
                  style: TextStyle(fontSize: 14)),
              secondary:
                  const Icon(Icons.delivery_dining_outlined),
            ),
            const SizedBox(height: 12),

            // ── Marca ─────────────────────────────────────────
            if (marcas.isNotEmpty) ...[
              Text('Marca',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: cs.primary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _FiltroChip(
                    label: 'Todas',
                    activo: _marca == null,
                    onTap: () => setState(() => _marca = null),
                  ),
                  ...marcas.map((m) => _FiltroChip(
                        label: m,
                        activo: _marca == m,
                        onTap: () =>
                            setState(() => _marca = _marca == m ? null : m),
                      )),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // ── Ordenar por ───────────────────────────────────
            Text('Ordenar por',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: cs.primary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _ordenesLabel
                  .map((o) => _FiltroChip(
                        label: o.$2,
                        activo: _orden == o.$1,
                        onTap: () => setState(() => _orden = o.$1),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),

            // ── Botón aplicar ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _aplicar,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Aplicar filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
