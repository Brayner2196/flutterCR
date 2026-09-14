import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../pagos/widgets/filtro_chips.dart';
import '../../../shared/widgets/seleccion_bar.dart';
import '../../cartera/utils/cartera_labels.dart';
import '../../contador/providers/permisos_contables_provider.dart';
import '../../pagos/screens/admin/admin_cobro_detalle_screen.dart';
import '../../pagos/services/cobro_service.dart';
import '../models/aviso_lote_resumen.dart';
import '../models/cobro_cobranza_model.dart';
import '../providers/cobranza_provider.dart';
import '../utils/agrupador_cobranza.dart';
import '../widgets/aviso_cobranza_dialog.dart';
import '../widgets/cartera_resumen_card.dart';
import '../widgets/cobranza_card.dart';
import '../widgets/cobranza_metricas_grid.dart';
import '../widgets/grupo_mes_header.dart';
import '../widgets/mes_cartera_bar.dart';

/// Pestaña "Cobranza" del hub: la cartera que sigue sin pagarse.
///
/// Orden de lectura: mes → cuánto se debe → urgencia (grid que filtra) → fase
/// de cartera → lista agrupada por mes. Las acciones viven abajo: aviso masivo
/// por fase cuando no hay nada marcado, y el envío a la selección cuando sí.
///
/// Lo que se ve aquí es deuda viva y solo deuda viva: el endpoint no devuelve
/// cobros exonerados ni pagados.
class CobranzaTabView extends StatefulWidget {
  const CobranzaTabView({super.key});

  @override
  State<CobranzaTabView> createState() => _CobranzaTabViewState();
}

class _CobranzaTabViewState extends State<CobranzaTabView>
    with AutomaticKeepAliveClientMixin {
  /// Se resuelve en cada build desde los permisos contables de la sesión.
  bool _puedeNotificar = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Diferido: tocar un provider dentro de initState revienta en web y
    // escritorio ("mouse_tracker.dart:199").
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final provider = context.read<CobranzaProvider>();
    await Future.wait([provider.cargar(), provider.cargarFases()]);
  }

  // ── Acciones ───────────────────────────────────────────────────────────

  Future<void> _avisarUno(CobroCobranzaModel cobro) async {
    final provider = context.read<CobranzaProvider>();
    final datos = await AvisoCobranzaDialog.mostrar(
      context,
      titulo: 'Enviar aviso de cobranza',
      descripcion: '${cobro.propiedadIdentificador}\n'
          '${cobro.conceptoLabel} · ${CurrencyFormatter.cop(cobro.montoPendiente)} · '
          '${cobro.etiquetaVencimiento.toLowerCase()}'
          '${cobro.tieneFase ? '\nFase actual: ${cobro.faseNombre}' : ''}',
    );
    if (datos == null) return;
    final resumen =
        await provider.avisarPropiedad(cobro.propiedadId, mensaje: datos.mensaje);
    _reportar(resumen, provider.error);
  }

  Future<void> _avisarSeleccion() async {
    final provider = context.read<CobranzaProvider>();
    final cobros = provider.seleccion.length;
    final propiedades = provider.propiedadesSeleccionadas.length;
    final datos = await AvisoCobranzaDialog.mostrar(
      context,
      titulo: 'Aviso a la selección',
      descripcion: propiedades == cobros
          ? 'Se notificará a $propiedades ${propiedades == 1 ? 'propiedad' : 'propiedades'}.'
          : 'Seleccionaste $cobros cobros de $propiedades propiedades. '
              'A cada propiedad le llega un solo aviso, no uno por cobro.',
    );
    if (datos == null) return;
    final resumen = await provider.avisarSeleccion(mensaje: datos.mensaje);
    _reportar(resumen, provider.error);
  }

  Future<void> _avisarPorFase() async {
    final provider = context.read<CobranzaProvider>();
    final datos = await AvisoCobranzaDialog.mostrar(
      context,
      titulo: 'Aviso masivo por fase',
      descripcion:
          'Se notificará a todas las propiedades que estén en la fase elegida, '
          'aunque no aparezcan en la lista de este mes.',
      fases: provider.fases,
    );
    if (datos?.fase?.id == null) return;
    final resumen =
        await provider.avisarPorFase(datos!.fase!.id!, mensaje: datos.mensaje);
    _reportar(resumen, provider.error);
  }

  Future<void> _abrirDetalle(CobroCobranzaModel cobro) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final completo = await CobroService.getCobroAdmin(cobro.cobroId);
      if (!mounted) return;
      final cambios = await navigator.push<bool>(
        MaterialPageRoute(builder: (_) => AdminCobroDetalleScreen(cobro: completo)),
      );
      // Exonerar o registrar un pago desde el detalle saca al cobro de la
      // cartera: hay que releer para que no quede una fila fantasma.
      if (cambios == true && mounted) await _cargar();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  /// Traduce el resultado del envío a un mensaje; en null, muestra el error.
  void _reportar(AvisoLoteResumen? resumen, String? error) {
    if (!mounted) return;
    if (resumen == null) {
      _snack(error ?? 'No se pudo enviar el aviso', AppColors.danger);
      return;
    }
    _snack(
      resumen.mensaje,
      resumen.algunoEnviado ? AppColors.ok : AppColors.warning,
    );
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ── Construcción ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<CobranzaProvider>();
    final cargaInicial = provider.loading && provider.cobros.isEmpty;
    // El contador puede tener permiso de ver cartera pero no de notificarla:
    // sin esto vería casillas y botones que el backend le rechaza con 403.
    _puedeNotificar =
        context.watch<PermisosContablesProvider>().puede('NOTIFICAR_CARTERA');

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: _barraInferior(provider),
      body: cargaInicial
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: CustomScrollView(
                // Con poca cartera la lista no llena la pantalla; sin esto el
                // gesto de "deslizar para refrescar" no se dispara.
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (provider.cobros.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: MesCarteraBar(
                        grupos: provider.grupos,
                        seleccionado: provider.mes,
                        total: provider.cobros.length,
                        onSeleccionar: provider.seleccionarMes,
                        onVerAnteriores: provider.mesesVentana > 0
                            ? () => provider.cargar(meses: 0)
                            : null,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: CarteraResumenCard(
                        totalDeuda: provider.totalDeuda,
                        totalMora: provider.totalMora,
                        propiedades: provider.propiedadesMorosas,
                        contexto: _contexto(provider),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: CobranzaMetricasGrid(
                        counts: provider.metricas,
                        seleccionado: provider.urgencia,
                        onSeleccionar: provider.seleccionarUrgencia,
                        diasCritico: CobranzaProvider.diasCritico,
                      ),
                    ),
                    if (provider.conteoPorFase.isNotEmpty)
                      SliverToBoxAdapter(child: _chipsFase(provider)),
                  ],
                  ..._contenido(provider),
                ],
              ),
            ),
    );
  }

  String _contexto(CobranzaProvider provider) {
    final mes = provider.mes;
    if (mes == null) return 'todos los meses';
    return provider.grupos
            .where((g) => g.clave == mes)
            .firstOrNull
            ?.nombre
            .toLowerCase() ??
        'todos los meses';
  }

  Widget _chipsFase(CobranzaProvider provider) {
    final conteo = provider.conteoPorFase;
    final total = conteo.values.fold<int>(0, (s, v) => s + v);
    final items = <FiltroChipData>[
      FiltroChipData(
        valor: null,
        label: 'Todas',
        count: total,
        color: AppColors.danger,
      ),
      for (final entry in conteo.entries)
        FiltroChipData(
          valor: entry.key,
          label: provider.nombreFase(entry.key),
          count: entry.value,
          color: CarteraLabels.colorDeHex(_colorFase(provider, entry.key)),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: FiltroChips(
        items: items,
        seleccionado: provider.fase,
        onSeleccionar: provider.seleccionarFase,
      ),
    );
  }

  String? _colorFase(CobranzaProvider provider, String codigo) =>
      provider.cobros.where((c) => c.faseCodigo == codigo).firstOrNull?.faseColor;

  /// Lista agrupada por mes, o el vacío que corresponda al filtro activo.
  List<Widget> _contenido(CobranzaProvider provider) {
    if (provider.cobros.isEmpty) {
      // Un fallo de red y una cartera sana se ven igual si se mezclan: el
      // primero necesita reintentar, la segunda es una buena noticia.
      final hayError = provider.error != null;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptyStateWidget(
                  icono: hayError ? Icons.cloud_off : Icons.sentiment_satisfied_alt,
                  mensaje: hayError
                      ? provider.error!
                      : 'No hay cartera vencida ni por vencer.\nTodo está al día.',
                ),
                if (hayError) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _cargar,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reintentar'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ];
    }

    final grupos = provider.gruposVisibles;
    if (grupos.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                const EmptyStateWidget(
                  icono: Icons.filter_list_off,
                  mensaje: 'Ningún cobro cumple los filtros activos',
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: provider.limpiarFiltros,
                  child: const Text('Quitar filtros'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      for (final grupo in grupos) ...[
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverToBoxAdapter(
            child: GrupoMesHeader(
              grupo: grupo,
              mostrarSeleccion: _puedeNotificar,
              todosSeleccionados: _todosSeleccionados(provider, grupo),
              onAlternarTodos: () => provider
                  .alternarVarios(grupo.cobros.map((c) => c.cobroId).toList()),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList.builder(
            itemCount: grupo.cobros.length,
            itemBuilder: (_, i) {
              final cobro = grupo.cobros[i];
              return CobranzaCard(
                cobro: cobro,
                seleccionado: provider.estaSeleccionado(cobro.cobroId),
                diasCritico: CobranzaProvider.diasCritico,
                seleccionable: _puedeNotificar,
                onAlternar: () => provider.alternar(cobro.cobroId),
                onAvisar: _puedeNotificar ? () => _avisarUno(cobro) : null,
                onDetalle: () => _abrirDetalle(cobro),
              );
            },
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
    ];
  }

  bool _todosSeleccionados(CobranzaProvider provider, GrupoMesCobranza grupo) =>
      grupo.cobros.isNotEmpty &&
      grupo.cobros.every((c) => provider.estaSeleccionado(c.cobroId));

  /// Barra inferior: contextual con selección, y de aviso por fase sin ella.
  Widget? _barraInferior(CobranzaProvider provider) {
    if (provider.haySeleccion) {
      final cobros = provider.seleccion.length;
      final propiedades = provider.propiedadesSeleccionadas.length;
      return SeleccionBar(
        titulo: '$cobros ${cobros == 1 ? 'cobro' : 'cobros'} seleccionados',
        subtitulo: '$propiedades ${propiedades == 1 ? 'propiedad' : 'propiedades'} '
            'recibirán el aviso',
        ocupado: provider.enviando,
        onLimpiar: provider.limpiarSeleccion,
        onAccion: _avisarSeleccion,
        textoAccion: 'Avisar',
        iconoAccion: Icons.campaign_outlined,
      );
    }

    if (!_puedeNotificar || provider.cobros.isEmpty || provider.fases.isEmpty) {
      return null;
    }

    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: OutlinedButton.icon(
            onPressed: provider.enviando ? null : _avisarPorFase,
            icon: const Icon(Icons.campaign_outlined, size: 18),
            label: const Text('Aviso masivo por fase'),
          ),
        ),
      ),
    );
  }
}
