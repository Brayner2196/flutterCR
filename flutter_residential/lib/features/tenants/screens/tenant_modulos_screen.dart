import 'package:flutter/material.dart';

import '../../modulos/models/modulo_estado.dart';
import '../../modulos/services/modulo_service.dart';
import '../models/tenant_response.dart';

/// Panel del SUPER_ADMIN para encender y apagar los módulos de un conjunto.
///
/// Solo lista los módulos SWITCHEABLES. El núcleo del negocio (cobros, pagos,
/// abonos, cartera, usuarios, propiedades, autenticación) no aparece acá
/// porque no se puede apagar: se muestra como nota fija al inicio para que
/// quede claro que no es un olvido.
class TenantModulosScreen extends StatefulWidget {
  final TenantResponse tenant;

  const TenantModulosScreen({super.key, required this.tenant});

  @override
  State<TenantModulosScreen> createState() => _TenantModulosScreenState();
}

class _TenantModulosScreenState extends State<TenantModulosScreen> {
  List<ModuloEstado> _modulos = [];
  bool _cargando = true;
  String? _error;

  /// Código del módulo que se está guardando ahora mismo. Bloquea solo ese
  /// switch en vez de toda la pantalla.
  String? _guardando;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final datos = await ModuloService.listarDeTenant(widget.tenant.id);
      if (!mounted) return;
      setState(() {
        _modulos = datos;
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

  Future<void> _toggle(ModuloEstado modulo, bool activo) async {
    setState(() => _guardando = modulo.codigo);
    try {
      // El backend devuelve el catálogo completo ya recalculado: apagar un
      // módulo padre arrastra a sus dependientes, y con una sola respuesta la
      // lista queda coherente sin un segundo GET.
      final actualizado = await ModuloService.toggle(
        tenantId: widget.tenant.id,
        codigo: modulo.codigo,
        activo: activo,
      );
      if (!mounted) return;
      setState(() {
        _modulos = actualizado;
        _guardando = null;
      });
      _avisar('${modulo.nombre}: ${activo ? 'activado' : 'desactivado'}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = null);
      _avisar(e.toString().replaceFirst('Exception: ', ''), esError: true);
    }
  }

  void _avisar(String mensaje, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensaje),
      backgroundColor:
          esError ? Theme.of(context).colorScheme.error : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.tenant.nombre,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _cargando ? null : _cargar,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _EstadoVacio(
        icono: Icons.error_outline,
        titulo: 'No se pudieron cargar los módulos',
        detalle: _error!,
        accion: FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
      );
    }
    if (_modulos.isEmpty) {
      return const _EstadoVacio(
        icono: Icons.extension_outlined,
        titulo: 'Sin módulos configurables',
        detalle: 'Este conjunto no tiene módulos parametrizables.',
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _modulos.length + 1,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == 0) return const _NotaNucleo();
          return _tile(_modulos[index - 1]);
        },
      ),
    );
  }

  Widget _tile(ModuloEstado modulo) {
    final esteGuardando = _guardando == modulo.codigo;
    final hayOtroGuardando = _guardando != null && !esteGuardando;

    // Un hijo con el padre apagado no se puede encender: el backend lo
    // rechazaría con 409. Se deshabilita el switch y se explica por qué.
    final padreApagado = modulo.bloqueadoPorPadre ||
        (modulo.requiere != null &&
            !_modulos.any((m) => m.codigo == modulo.requiere && m.activo));

    final nombrePadre = modulo.requiere == null
        ? null
        : _modulos
            .where((m) => m.codigo == modulo.requiere)
            .map((m) => m.nombre)
            .firstOrNull;

    return SwitchListTile(
      value: modulo.activo,
      onChanged: (hayOtroGuardando || esteGuardando || (padreApagado && !modulo.activo))
          ? null
          : (valor) => _toggle(modulo, valor),
      title: Text(
        modulo.nombre,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(modulo.descripcion),
          if (padreApagado && nombrePadre != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Requiere que "$nombrePadre" esté activo',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          if (modulo.actualizadoPor != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Último cambio: ${modulo.actualizadoPor}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
      secondary: esteGuardando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }
}

/// Aclara qué NO se puede apagar, para que no se busque el switch que falta.
class _NotaNucleo extends StatelessWidget {
  const _NotaNucleo();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cobros, pagos, cartera, usuarios y propiedades están siempre '
              'activos: son el núcleo de la plataforma y no se pueden apagar. '
              'Al desactivar un módulo sus datos se conservan y vuelven a '
              'aparecer si lo reactivas.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final Widget? accion;

  const _EstadoVacio({
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(titulo,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(detalle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall),
            if (accion != null) ...[
              const SizedBox(height: 16),
              accion!,
            ],
          ],
        ),
      ),
    );
  }
}
