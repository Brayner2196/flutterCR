import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import '../../models/propiedad_opcion_model.dart';
import '../../services/vigilancia_service.dart';

/// Campo selector de unidad FACTURABLE con buscador paginado.
/// Muestra el path corto de la propiedad seleccionada.
class PropiedadSelectorField extends StatelessWidget {
  final PropiedadOpcionModel? seleccionada;
  final ValueChanged<PropiedadOpcionModel> onSeleccion;
  final String label;

  const PropiedadSelectorField({
    super.key,
    required this.seleccionada,
    required this.onSeleccion,
    this.label = 'Unidad de destino',
  });

  Future<void> _abrirBuscador(BuildContext context) async {
    final r = await showModalBottomSheet<PropiedadOpcionModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _PropiedadSearchSheet(),
    );
    if (r != null) onSeleccion(r);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _abrirBuscador(context),
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.home_work_outlined),
          suffixIcon: const Icon(Icons.search_rounded),
        ),
        child: Text(
          seleccionada?.etiqueta ?? 'Buscar unidad…',
          style: TextStyle(
            color: seleccionada == null
                ? Theme.of(context).hintColor
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ─── Hoja de búsqueda con paginación ──────────────────────────────────────────

class _PropiedadSearchSheet extends StatefulWidget {
  const _PropiedadSearchSheet();
  @override
  State<_PropiedadSearchSheet> createState() => _PropiedadSearchSheetState();
}

class _PropiedadSearchSheetState extends State<_PropiedadSearchSheet> {
  final _buscarCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<PropiedadOpcionModel> _items = [];

  Timer? _debounce;
  int _page = 0;
  bool _last = false;
  bool _cargando = false;
  String _query = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _cargar(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscarCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_cargando &&
        !_last) {
      _cargar();
    }
  }

  void _onBuscarCambia(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _query = value.trim();
      _cargar(reset: true);
    });
  }

  Future<void> _cargar({bool reset = false}) async {
    if (_cargando) return;
    setState(() {
      _cargando = true;
      _error = null;
      if (reset) {
        _page = 0;
        _last = false;
        _items.clear();
      }
    });
    try {
      final pagina = await VigilanciaService.buscarPropiedades(
        buscar: _query.isEmpty ? null : _query,
        page: _page,
      );
      setState(() {
        _items.addAll(pagina.content);
        _last = pagina.last;
        _page += 1;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Buscar unidad',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _buscarCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Ej: A101, Torre B…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: _onBuscarCambia,
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: _error != null
                  ? Center(child: Text(_error!))
                  : (_items.isEmpty && !_cargando)
                      ? const Center(child: Text('Sin resultados'))
                      : ListView.separated(
                          controller: _scrollCtrl,
                          itemCount: _items.length + (_last ? 0 : 1),
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            if (i >= _items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: Center(
                                    child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2))),
                              );
                            }
                            final p = _items[i];
                            return ListTile(
                              leading: const Icon(Icons.home_work_outlined),
                              title: Text(p.etiqueta,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: p.pathCorto != null &&
                                      p.pathCorto != p.identificador
                                  ? Text('Id: ${p.identificador}')
                                  : null,
                              onTap: () => Navigator.pop(context, p),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
