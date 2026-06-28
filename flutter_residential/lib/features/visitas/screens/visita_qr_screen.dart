import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'package:flutter_residential/core/utils/date_formatter.dart';
import '../../vigilancia/models/visita_model.dart';

/// Muestra el QR de una visita para que el residente lo comparta con su invitado.
class VisitaQrScreen extends StatelessWidget {
  final VisitaModel visita;

  const VisitaQrScreen({super.key, required this.visita});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('QR de visita')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(visita.nombreVisitante,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              if (visita.propiedadIdentificador != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text('Unidad ${visita.propiedadIdentificador}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: QrImageView(
                  data: visita.codigo,
                  version: QrVersions.auto,
                  size: 220,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SelectableText(
                visita.codigo,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (visita.expiraEn != null)
                Text('Válido hasta ${DateFormatter.fechaHora(visita.expiraEn)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'El vigilante escaneará o digitará este código para autorizar el ingreso.',
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
