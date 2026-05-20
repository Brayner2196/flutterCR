import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../models/anuncio_model.dart';
import '../../providers/anuncio_provider.dart';
import '../../utils/fecha_relativa.dart';
import '../../../../shared/theme/app_theme.dart';

class DetalleAnuncioScreen extends StatefulWidget {
  final AnuncioModel anuncio;
  const DetalleAnuncioScreen({super.key, required this.anuncio});

  @override
  State<DetalleAnuncioScreen> createState() => _DetalleAnuncioScreenState();
}

class _DetalleAnuncioScreenState extends State<DetalleAnuncioScreen> {
  bool _marcado = false;

  @override
  void initState() {
    super.initState();
    _marcado = widget.anuncio.vistoPorMi;
    WidgetsBinding.instance.addPostFrameCallback((_) => _marcarYNotificar());
  }

  Future<void> _marcarYNotificar() async {
    final eraNoLeido = !widget.anuncio.vistoPorMi;
    await context.read<AnuncioProvider>().marcarVisto(widget.anuncio.id);
    if (!mounted) return;
    setState(() => _marcado = true);
    if (eraNoLeido) {
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Anuncio marcado como leído'),
        autoCloseDuration: const Duration(milliseconds: 1500),
        alignment: Alignment.bottomCenter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = widget.anuncio;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anuncio'),
        actions: [
          if (_marcado)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.md),
              child: Icon(Icons.check_circle_outline, color: AppColors.ok),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a.titulo,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${a.creadoPorNombre ?? 'Administración'}  ·  ${fechaRelativa(a.creadoEn)}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(color: cs.onSurfaceVariant, height: 1),
            const SizedBox(height: AppSpacing.md),
            Text(
              a.contenido,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
