import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cobros_provider.dart';
import '../../models/cobro_model.dart';
import '../../services/gestion_cartera_service.dart';
import '../../widgets/filtro_chips.dart';
import '../../../cartera/models/estado_cartera_vigente_model.dart';
import '../../../cartera/models/estado_cartera_config_model.dart';
import '../../../cartera/services/cartera_config_service.dart';
import '../../../cartera/widgets/estado_cartera_badge.dart';
import '../../../cartera/utils/cartera_labels.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/theme/app_theme.dart';

/// Pestaña "Cobranza" del hub: gestión de morosos.
///
/// Lista los cobros vencidos con su fase de cartera vigente y permite enviar
/// avisos (recordatorio, paso a cartera, pre-juridico) de forma individual o
/// masiva por fase. Reutiliza el sistema de estados de cartera configurables.
class CobranzaTabView extends StatefulWidget {
  const CobranzaTabView({super.key});

  @override
  State<CobranzaTabView> createState() => _CobranzaTabViewState();
}

class _CobranzaTabViewState extends State<CobranzaTabView>
    with AutomaticKeepAliveClientMixin {
  Map<int, EstadoCarteraVigente> _estados = {};
  List<EstadoCarteraConfig> _fases = [];
  String? _faseFiltro; // codigo de la fase; null = todas
  bool _enviando = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    context.read<CobrosProvider>().cargarCobrosAdmin(estado: 'VENCIDO');
    try {
      final estados = await CarteraConfigService.estadosVigentes();
      final fases = await CarteraConfigService.listar();
      if (!mounted) return;
      setState(() {
        _estados = estados;
        _fases = (fases.where((f) => f.activo && !f.esPositivo).toList()
          ..sort((a, b) => b.severidad.compareTo(a.severidad)));
      });
    } catch (_) {
      // Degradacion segura: sin estados no se muestran badges ni filtros.
    }
  }

  EstadoCarteraVigente? _estadoDe(CobroModel c) => _estados[c.propiedadId];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<CobrosProvider>();
    final vencidos = provider.vencidos;
    final visibles = _faseFiltro == null
        ? vencidos
        : vencidos
            .where((c) => _estadoDe(c)?.estadoCodigo == _faseFiltro)
            .toList();

    final puedeAvisar = vencidos.isNotEmpty && _fases.isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: puedeAvisar ? _barraAcciones() : null,
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _resumen(vencidos),
                if (vencidos.isNotEmpty) _filtrosFase(vencidos),
                Expanded(child: _lista(visibles)),
              ],
            ),
    );
  }

  Widget _resumen(List<CobroModel> vencidos) {
    final totalMora = vencidos.fold<double>(0, (s, c) => s + c.montoMora);
    final totalDeuda = vencidos.fold<double>(0, (s, c) => s + c.montoTotal);
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Morosos', '${vencidos.length}', AppColors.danger),
          _stat('Total mora', CurrencyFormatter.cop(totalMora), AppColors.warning),
          _stat('Total deuda', CurrencyFormatter.cop(totalDeuda), AppColors.danger),
        ],
      ),
    );
  }

  Widget _stat(String label, String valor, Color color) => Column(
        children: [
          Text(valor,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17, color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      );

  Widget _filtrosFase(List<CobroModel> vencidos) {
    final counts = <String, int>{};
    final colores = <String, Color>{};
    for (final c in vencidos) {
      final e = _estadoDe(c);
      if (e == null || e.estadoCodigo == null) continue;
      counts[e.estadoCodigo!] = (counts[e.estadoCodigo!] ?? 0) + 1;
      colores[e.estadoCodigo!] = CarteraLabels.colorDeHex(e.color);
    }
    if (counts.isEmpty) return const SizedBox.shrink();

    final items = <FiltroChipData>[
      FiltroChipData(
        valor: null,
        label: 'Todos',
        count: vencidos.length,
        color: AppColors.danger,
      ),
      for (final entry in counts.entries)
        FiltroChipData(
          valor: entry.key,
          label: _nombreFase(entry.key),
          count: entry.value,
          color: colores[entry.key] ?? AppColors.danger,
        ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: FiltroChips(
        items: items,
        seleccionado: _faseFiltro,
        onSeleccionar: (v) => setState(() => _faseFiltro = v),
      ),
    );
  }

  String _nombreFase(String codigo) {
    final f = _fases.where((x) => x.codigo == codigo).firstOrNull;
    return f?.nombre ?? codigo;
  }

  Widget _lista(List<CobroModel> morosos) {
    final cs = Theme.of(context).colorScheme;
    if (morosos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sentiment_satisfied_alt,
                size: 52, color: AppColors.ok),
            const SizedBox(height: 12),
            Text('Sin morosos para mostrar',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
      itemCount: morosos.length,
      itemBuilder: (_, i) => _MorosoTile(
        cobro: morosos[i],
        estado: _estadoDe(morosos[i]),
        onAvisar: () => _avisoIndividual(morosos[i]),
      ),
    );
  }

  /// Barra inferior fija con la acción de aviso masivo.
  Widget _barraAcciones() {
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
          child: FilledButton.icon(
            onPressed: _enviando ? null : _avisoMasivo,
            icon: const Icon(Icons.campaign_outlined, size: 18),
            label: const Text('Aviso masivo'),
          ),
        ),
      ),
    );
  }

  // Acciones de aviso

  Future<void> _avisoIndividual(CobroModel moroso) async {
    final fase = _estadoDe(moroso);
    final msgCtrl = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar aviso de cobranza'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Propiedad: ${moroso.propiedadIdentificador}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (fase != null && fase.tieneEstado) ...[
              const SizedBox(height: 6),
              EstadoCarteraBadge(estado: fase),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mensaje (opcional)',
                hintText: 'Si lo dejas vacio se usa el aviso de la fase actual',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    setState(() => _enviando = true);
    try {
      final r = await GestionCarteraService.notificarPropiedad(
        moroso.propiedadId,
        mensaje: msgCtrl.text,
      );
      _snack(
        r.enviado
            ? 'Aviso enviado a ${r.usuariosNotificados} residente(s)'
            : 'La propiedad no tiene residentes con notificaciones activas',
        r.enviado ? AppColors.ok : AppColors.warning,
      );
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), AppColors.danger);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _avisoMasivo() async {
    EstadoCarteraConfig? faseSel = _fases.isNotEmpty ? _fases.first : null;
    final msgCtrl = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Aviso masivo por fase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Se notificara a todas las propiedades en la fase elegida.',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fase de cartera',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: DropdownButton<EstadoCarteraConfig>(
                  value: faseSel,
                  isExpanded: true,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: _fases
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.nombre),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => faseSel = v),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mensaje (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: faseSel == null ? null : () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.campaign_outlined, size: 18),
              label: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
    if (confirmado != true || faseSel?.id == null) return;

    setState(() => _enviando = true);
    try {
      final res = await GestionCarteraService.notificarMasivoPorEstado(
        faseSel!.id!,
        mensaje: msgCtrl.text,
      );
      final propiedades = res.length;
      final usuarios = res.fold<int>(0, (s, r) => s + r.usuariosNotificados);
      _snack(
        propiedades == 0
            ? 'No hay propiedades en la fase "${faseSel!.nombre}"'
            : 'Aviso enviado a $propiedades propiedad(es), $usuarios residente(s)',
        propiedades == 0 ? AppColors.warning : AppColors.ok,
      );
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), AppColors.danger);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }
}

class _MorosoTile extends StatelessWidget {
  final CobroModel cobro;
  final EstadoCarteraVigente? estado;
  final VoidCallback onAvisar;

  const _MorosoTile({
    required this.cobro,
    required this.estado,
    required this.onAvisar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.danger.withValues(alpha: 0.12),
          child: const Icon(Icons.warning_amber, color: AppColors.danger, size: 20),
        ),
        title: Text(cobro.propiedadIdentificador,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cobro.concepto, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            if (estado != null && estado!.tieneEstado) ...[
              const SizedBox(height: 4),
              EstadoCarteraBadge(estado: estado),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(CurrencyFormatter.cop(cobro.montoTotal),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.danger)),
            if (cobro.montoMora > 0)
              Text('Mora: ${CurrencyFormatter.cop(cobro.montoMora)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.warning)),
            const SizedBox(height: 2),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onAvisar,
              icon: const Icon(Icons.notifications_active_outlined, size: 16),
              label: const Text('Avisar', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
