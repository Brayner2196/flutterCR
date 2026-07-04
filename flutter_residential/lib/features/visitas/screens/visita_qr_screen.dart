import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'package:flutter_residential/core/utils/date_formatter.dart';
import '../../vigilancia/models/visita_model.dart';

/// Muestra el QR de una visita para que el residente lo comparta con su invitado.
/// El QR lleva los datos embebidos; el vigilante los ve al escanear.
class VisitaQrScreen extends StatefulWidget {
  final VisitaModel visita;

  const VisitaQrScreen({super.key, required this.visita});

  @override
  State<VisitaQrScreen> createState() => _VisitaQrScreenState();
}

class _VisitaQrScreenState extends State<VisitaQrScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _compartiendo = false;

  Future<void> _compartir() async {
    final v = widget.visita;
    setState(() => _compartiendo = true);
    try {
      final boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/visita_${v.codigo}.png');
      await file.writeAsBytes(bytes);

      final mensaje = 'Visita para ${v.nombreVisitante}'
          '${v.propiedadIdentificador != null ? ' — unidad ${v.propiedadIdentificador}' : ''}.'
          ' Muestra este QR en portería. Código: ${v.codigo}';

      await Share.shareXFiles([XFile(file.path)], text: mensaje);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo compartir el QR')));
      }
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = widget.visita;
    return Scaffold(
      appBar: AppBar(title: const Text('QR de visita')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(v.nombreVisitante,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${v.cantidadPersonas} persona(s)'
                '${v.propiedadIdentificador != null ? ' · Unidad ${v.propiedadIdentificador}' : ''}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: QrImageView(
                    data: v.qrData,
                    version: QrVersions.auto,
                    size: 220,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SelectableText(
                v.codigo,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              if (v.acompanantes != null && v.acompanantes!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Acompañantes: ${v.acompanantes}',
                    textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              ],
              if (v.franjaDesde != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Horario: ${DateFormatter.fechaHoraMinSegAmPm(v.franjaDesde)}'
                  '${v.franjaHasta != null ? ' a ${DateFormatter.fechaHoraMinSegAmPm(v.franjaHasta)}' : ''}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (v.expiraEn != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text('Válido hasta ${DateFormatter.fechaHoraMinSegAmPm(v.expiraEn)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _compartiendo ? null : _compartir,
                icon: _compartiendo
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.share_rounded),
                label: const Text('Compartir QR'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'El vigilante escaneará este código para autorizar el ingreso.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
