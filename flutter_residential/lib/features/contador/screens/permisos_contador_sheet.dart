import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contador_model.dart';
import '../models/permiso_contable_model.dart';
import '../providers/admin_contadores_provider.dart';

/// Pantalla donde el administrador define el alcance de un contador.
///
/// El catálogo lo manda el backend con etiqueta, descripción y grupo: acá no
/// hay textos de permisos escritos a mano, así que agregar uno en Java lo hace
/// aparecer sin tocar Flutter.
///
/// ## Los sensibles van aparte
///
/// Exonerar, verificar pagos, configurar cuotas o migrar cartera mueven dinero
/// de forma difícil de revertir. Se agrupan visualmente y se marcan, para que
/// activarlos sea una decisión y no un descuido al bajar por la lista.
class PermisosContadorSheet extends StatefulWidget {
  final int usuarioId;
  final String nombre;

  const PermisosContadorSheet({
    super.key,
    required this.usuarioId,
    required this.nombre,
  });

  /// Abre el sheet y retorna true si se guardaron cambios.
  static Future<bool> mostrar(
    BuildContext context, {
    required int usuarioId,
    required String nombre,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PermisosContadorSheet(usuarioId: usuarioId, nombre: nombre),
    );
    return result ?? false;
  }

  @override
  State<PermisosContadorSheet> createState() => _PermisosContadorSheetState();
}

class _PermisosContadorSheetState extends State<PermisosContadorSheet> {
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  Contador? _contador;

  /// Selección en curso. Se trabaja sobre una copia local y se manda completa al
  /// guardar: así el administrador puede prender y apagar varios y arrepentirse
  /// sin dejar filas a medias, y la auditoría queda con un solo antes/después.
  Set<String> _seleccion = {};

  @override
  void initState() {
    super.initState(); 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cargar();
    });
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final provider = context.read<AdminContadoresProvider>();
      await provider.seleccionar(widget.usuarioId);
      final c = provider.seleccionado;
      if (c == null) throw Exception(provider.error ?? 'No se pudo cargar el contador');
      if (!mounted) return;
      setState(() {
        _contador = c;
        _seleccion = c.otorgados.toSet();
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final provider = context.read<AdminContadoresProvider>();
    final ok = await provider.guardarPermisos(widget.usuarioId, _seleccion.toList());
    if (!mounted) return;
    setState(() => _guardando = false);

    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    // El backend contesta 409 con un mensaje útil cuando el usuario no tiene
    // rol CONTADOR. Se muestra tal cual: dice exactamente qué hacer.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.error ?? 'No se pudieron guardar los permisos')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          _Encabezado(nombre: widget.nombre, seleccionados: _seleccion.length),
          const Divider(height: 1),
          Expanded(child: _cuerpo(scrollController, cs)),
          if (!_cargando && _error == null) _barraAcciones(cs),
        ],
      ),
    );
  }

  Widget _cuerpo(ScrollController controller, ColorScheme cs) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _EstadoError(mensaje: _error!, onReintentar: _cargar);
    }

    final grupos = _contador!.porGrupo;
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (_seleccion.isEmpty) _AvisoSinAlcance(cs: cs),
        for (final entrada in grupos.entries) ...[
          _TituloGrupo(titulo: PermisoContable.etiquetaGrupo(entrada.key)),
          ...entrada.value.map(_fila),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _fila(PermisoContable permiso) {
    final activo = _seleccion.contains(permiso.nombre);
    final cs = Theme.of(context).colorScheme;

    return SwitchListTile.adaptive(
      value: activo,
      onChanged: (v) => setState(() {
        if (v) {
          _seleccion.add(permiso.nombre);
        } else {
          _seleccion.remove(permiso.nombre);
        }
      }),
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Flexible(
            child: Text(
              permiso.etiqueta,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          if (permiso.sensible) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'SENSIBLE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: cs.error,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          permiso.descripcion,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.35),
        ),
      ),
    );
  }

  Widget _barraAcciones(ColorScheme cs) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            TextButton(
              onPressed: _guardando || _seleccion.isEmpty
                  ? null
                  : () => setState(_seleccion.clear),
              child: const Text('Quitar todos'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Piezas de presentación ──────────────────────────────────────────────────

class _Encabezado extends StatelessWidget {
  final String nombre;
  final int seleccionados;

  const _Encabezado({required this.nombre, required this.seleccionados});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Permisos contables',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '$nombre · $seleccionados activos',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

class _TituloGrupo extends StatelessWidget {
  final String titulo;

  const _TituloGrupo({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        titulo.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _AvisoSinAlcance extends StatelessWidget {
  final ColorScheme cs;

  const _AvisoSinAlcance({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sin permisos activos este contador entra a la app pero no ve '
              'nada financiero.',
              style: TextStyle(fontSize: 12.5, color: cs.onSurface, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _EstadoError({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: cs.error),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
