import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_formatter.dart';
import '../models/auditoria_model.dart';
import '../providers/auditoria_provider.dart';
import 'package:flutter_residential/shared/widgets/panel_tiles.dart';

/// Bandeja de auditoría financiera. Exclusiva del TENANT_ADMIN.
///
/// El contador no puede abrirla ni por accidente: el backend rechaza su token
/// con 403, y es a propósito — que pudiera revisar (o depurar) su propio rastro
/// anularía el sentido del registro.
class AdminAuditoriaScreen extends StatefulWidget {
  const AdminAuditoriaScreen({super.key});

  @override
  State<AdminAuditoriaScreen> createState() => _AdminAuditoriaScreenState();
}

class _AdminAuditoriaScreenState extends State<AdminAuditoriaScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_alDesplazar);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AuditoriaProvider>();
      p.cargarFiltros();
      p.cargar();
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_alDesplazar);
    _scroll.dispose();
    super.dispose();
  }

  /// Trae la siguiente página al acercarse al final. El umbral de 400px evita
  /// que el usuario vea el spinner: para cuando llega abajo, ya cargó.
  void _alDesplazar() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      context.read<AuditoriaProvider>().cargarMas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuditoriaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoría financiera'),
        actions: [
          if (!provider.filtro.vacio)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined),
              tooltip: 'Quitar filtros',
              onPressed: provider.limpiarFiltro,
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar',
            onPressed: () => _abrirFiltros(provider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.cargar,
        child: _cuerpo(provider),
      ),
    );
  }

  Widget _cuerpo(AuditoriaProvider provider) {
    if (provider.loading && provider.registros.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.registros.isEmpty) {
      return _MensajeCentral(
        icono: Icons.error_outline,
        titulo: 'No se pudo cargar la auditoría',
        detalle: provider.error!,
        accion: OutlinedButton(
          onPressed: provider.cargar,
          child: const Text('Reintentar'),
        ),
      );
    }
    if (provider.vacio) {
      return _MensajeCentral(
        icono: Icons.history_toggle_off,
        titulo: provider.filtro.vacio
            ? 'Todavía no hay movimientos'
            : 'Sin resultados para el filtro',
        detalle: provider.filtro.vacio
            ? 'Acá aparecerá cada acción sobre cobros, pagos y configuración.'
            : 'Prueba con otro rango de fechas o quita algún filtro.',
      );
    }

    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      itemCount: provider.registros.length + (provider.cargandoMas ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i >= provider.registros.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _TarjetaRegistro(registro: provider.registros[i]);
      },
    );
  }

  Future<void> _abrirFiltros(AuditoriaProvider provider) async {
    final nuevo = await showModalBottomSheet<FiltroAuditoria>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FiltrosSheet(
        inicial: provider.filtro,
        entidades: provider.entidades,
        acciones: provider.acciones,
      ),
    );
    if (nuevo != null) provider.aplicarFiltro(nuevo);
  }
}

// ─── Tarjeta de un movimiento ────────────────────────────────────────────────

class _TarjetaRegistro extends StatelessWidget {
  final RegistroAuditoria registro;

  const _TarjetaRegistro({required this.registro});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fallido = !registro.exitoso;

    return PanelTiles(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      // Franja lateral: el ojo distingue un intento rechazado sin leer.
      // Va como decoracion interna, sin color: un Border asimetrico no cabe en
      // el shape del Material y un DecoratedBox transparente no tapa el ripple.
      decoracionInterna: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: fallido ? cs.error : cs.primary.withValues(alpha: 0.5),
            width: 3,
          ),
        ),
      ),
      child: Theme(
        // Quita las líneas del ExpansionTile, que pelean con la franja lateral.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(
            '${registro.accionLegible} · ${registro.entidadLegible}'
            '${registro.entidadId != null ? " #${registro.entidadId}" : ""}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (registro.descripcion != null)
                  Text(
                    registro.descripcion!,
                    style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 13, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${registro.usuarioEmail ?? "—"}'
                        '${registro.usuarioRol != null ? " · ${registro.usuarioRol}" : ""}',
                        style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.fechaHoraMinAmPm(registro.creadoEn?.toIso8601String()),
                  style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          trailing: fallido
              ? Icon(Icons.block, size: 18, color: cs.error)
              : const Icon(Icons.expand_more, size: 20),
          children: [
            if (fallido && registro.mensajeError != null)
              _BloqueTexto(
                titulo: 'Rechazado',
                texto: registro.mensajeError!,
                color: cs.error,
              ),
            if (registro.valoresAntes != null)
              _BloqueJson(titulo: 'Antes', json: registro.valoresAntes!),
            if (registro.valoresDespues != null)
              _BloqueJson(titulo: 'Después', json: registro.valoresDespues!),
            if (registro.endpoint != null)
              _BloqueTexto(
                titulo: 'Origen',
                texto: '${registro.endpoint}'
                    '${registro.ip != null ? "\ndesde ${registro.ip}" : ""}',
                color: cs.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

/// Pinta un snapshot JSON como pares clave/valor.
///
/// El backend guarda estos campos sin conocer la forma de cada entidad, así que
/// acá tampoco se asume una: se recorre el mapa tal como venga. Si el contenido
/// no es un objeto JSON (un arreglo, un texto suelto), se muestra crudo antes
/// que perderlo.
class _BloqueJson extends StatelessWidget {
  final String titulo;
  final String json;

  const _BloqueJson({required this.titulo, required this.json});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Map<String, dynamic>? mapa;
    try {
      final decodificado = jsonDecode(json);
      if (decodificado is Map<String, dynamic>) mapa = decodificado;
    } catch (_) {
      // contenido no-JSON: cae al bloque de texto crudo de abajo
    }

    if (mapa == null) {
      return _BloqueTexto(titulo: titulo, texto: json, color: cs.onSurfaceVariant);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Etiqueta(titulo),
          const SizedBox(height: 4),
          ...mapa.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        e.key,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${e.value}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _BloqueTexto extends StatelessWidget {
  final String titulo;
  final String texto;
  final Color color;

  const _BloqueTexto({
    required this.titulo,
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Etiqueta(titulo),
          const SizedBox(height: 3),
          Text(texto, style: TextStyle(fontSize: 12, color: color, height: 1.4)),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;

  const _Etiqueta(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _MensajeCentral extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final Widget? accion;

  const _MensajeCentral({
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // ListView y no Column: el RefreshIndicator necesita algo desplazable
    // para que el gesto de arrastrar funcione también con la lista vacía.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Icon(icono, size: 44, color: cs.onSurfaceVariant),
        const SizedBox(height: 14),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            detalle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.4),
          ),
        ),
        if (accion != null) ...[
          const SizedBox(height: 18),
          Center(child: accion!),
        ],
      ],
    );
  }
}

// ─── Filtros ─────────────────────────────────────────────────────────────────

class _FiltrosSheet extends StatefulWidget {
  final FiltroAuditoria inicial;
  final List<String> entidades;
  final List<String> acciones;

  const _FiltrosSheet({
    required this.inicial,
    required this.entidades,
    required this.acciones,
  });

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  late String? _entidad = widget.inicial.entidad;
  late String? _accion = widget.inicial.accion;
  late bool _soloFallidos = widget.inicial.soloFallidos;
  late DateTime? _desde = widget.inicial.desde;
  late DateTime? _hasta = widget.inicial.hasta;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrar auditoría',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _entidad,
              decoration: const InputDecoration(
                labelText: 'Entidad',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...widget.entidades.map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(RegistroAuditoria.nombreEntidad(e)),
                    )),
              ],
              onChanged: (v) => setState(() => _entidad = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _accion,
              decoration: const InputDecoration(
                labelText: 'Acción',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...widget.acciones.map((a) => DropdownMenuItem(
                      value: a,
                      child: Text(RegistroAuditoria.nombreAccion(a)),
                    )),
              ],
              onChanged: (v) => setState(() => _accion = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _botonFecha('Desde', _desde, (d) => setState(() => _desde = d))),
                const SizedBox(width: 10),
                Expanded(child: _botonFecha('Hasta', _hasta, (d) => setState(() => _hasta = d))),
              ],
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _soloFallidos,
              onChanged: (v) => setState(() => _soloFallidos = v),
              title: const Text('Solo intentos rechazados',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: const Text(
                'Acciones que el sistema no dejó completar',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, const FiltroAuditoria()),
                  child: const Text('Limpiar'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    FiltroAuditoria(
                      entidad: _entidad,
                      accion: _accion,
                      soloFallidos: _soloFallidos,
                      desde: _desde,
                      hasta: _hasta,
                    ),
                  ),
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonFecha(String label, DateTime? valor, ValueChanged<DateTime?> onCambio) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today_outlined, size: 16),
      label: Text(
        valor == null ? label : DateFormatter.fechaCorta(valor.toIso8601String()),
        style: const TextStyle(fontSize: 13),
      ),
      onPressed: () async {
        final hoy = DateTime.now();
        final elegida = await showDatePicker(
          context: context,
          initialDate: valor ?? hoy,
          firstDate: DateTime(hoy.year - 5),
          lastDate: hoy,
        );
        if (elegida != null) onCambio(elegida);
      },
    );
  }
}
