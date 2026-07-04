import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'package:flutter_residential/core/utils/date_formatter.dart';
import '../models/bitacora_acceso_model.dart';
import '../services/admin_vigilancia_service.dart';

/// Reporte de bitácora/minuta de vigilancia para el administrador (últimos 7 días).
class BitacoraAdminScreen extends StatefulWidget {
  const BitacoraAdminScreen({super.key});

  @override
  State<BitacoraAdminScreen> createState() => _BitacoraAdminScreenState();
}

class _BitacoraAdminScreenState extends State<BitacoraAdminScreen> {
  List<BitacoraAccesoModel> _eventos = [];
  bool _cargando = true;
  String? _error;

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
      final res = await AdminVigilanciaService.bitacora();
      setState(() => _eventos = res);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bitácora de vigilancia')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _eventos.isEmpty
                  ? const Center(child: Text('Sin novedades en los últimos 7 días'))
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _eventos.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final e = _eventos[i];
                          final color = e.esDenegado
                              ? AppColors.danger
                              : (e.esPermitido ? AppColors.ok : AppColors.blue);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(e.tipoLegible,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              '${e.descripcion ?? ''}\n'
                              '${e.propiedadIdentificador != null ? 'Unidad ${e.propiedadIdentificador} · ' : ''}'
                              '${DateFormatter.fechaHoraMinAmPm(e.creadoEn)}',
                            ),
                            isThreeLine: true,
                            trailing: Text(e.resultado,
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: color, fontWeight: FontWeight.w700)),
                          );
                        },
                      ),
                    ),
    );
  }
}
