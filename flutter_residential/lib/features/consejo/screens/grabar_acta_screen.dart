import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../../core/utils/app_toast.dart';
import '../../../shared/theme/app_theme.dart';
import '../providers/acta_provider.dart';

/// Grabación del acta de reunión (solo PRESIDENTE — el backend lo valida).
/// Graba en m4a (AAC), muestra el tiempo transcurrido y al detener sube el
/// audio; Whisper lo transcribe en el servidor.
class GrabarActaScreen extends StatefulWidget {
  const GrabarActaScreen({super.key});

  @override
  State<GrabarActaScreen> createState() => _GrabarActaScreenState();
}

class _GrabarActaScreenState extends State<GrabarActaScreen> {
  final _tituloCtrl = TextEditingController();
  final _recorder = AudioRecorder();

  bool _grabando = false;
  bool _pausado = false;
  bool _subiendo = false;
  int _segundos = 0;
  Timer? _timer;
  String? _rutaAudio;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _tituloCtrl.dispose();
    super.dispose();
  }

  // ─── Control de grabación ─────────────────────────────────────

  Future<void> _iniciar() async {
    if (_tituloCtrl.text.trim().isEmpty) {
      AppToast.error(context, 'Escribe el título del acta antes de grabar');
      return;
    }
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      AppToast.error(context, 'Permiso de micrófono denegado');
      return;
    }
    if (!mounted) return;
    // Cerrar el teclado: abierto reduce la altura y puede ocultar los controles.
    FocusScope.of(context).unfocus();

    final dir = await getTemporaryDirectory();
    final ruta =
        '${dir.path}/acta_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000, // voz: suficiente calidad y archivo liviano
        sampleRate: 16000, // Whisper trabaja internamente a 16 kHz
        numChannels: 1,
      ),
      path: ruta,
    );

    setState(() {
      _grabando = true;
      _pausado = false;
      _segundos = 0;
      _rutaAudio = ruta;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_pausado) setState(() => _segundos++);
    });
  }

  Future<void> _pausarReanudar() async {
    if (_pausado) {
      await _recorder.resume();
    } else {
      await _recorder.pause();
    }
    setState(() => _pausado = !_pausado);
  }

  Future<void> _detenerYSubir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar grabación'),
        content: const Text(
            'Se subirá el audio y Whisper generará la transcripción del acta. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir grabando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Subir'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final ruta = await _recorder.stop();
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _grabando = false;
      _subiendo = true;
    });

    if (ruta == null) {
      setState(() => _subiendo = false);
      AppToast.error(context, 'No se pudo guardar la grabación');
      return;
    }

    final acta = await context.read<ActaProvider>().crear(
          titulo: _tituloCtrl.text.trim(),
          audioPath: ruta,
          duracionSegundos: _segundos,
        );

    // El audio local ya no se necesita tras subirlo.
    try {
      await File(ruta).delete();
    } catch (_) {}

    if (!mounted) return;
    setState(() => _subiendo = false);

    if (acta != null) {
      AppToast.success(
        context,
        'Grabación subida',
        description:
            'Whisper está transcribiendo el acta. Aparecerá como borrador al terminar.',
      );
      Navigator.pop(context);
    } else {
      final error = context.read<ActaProvider>().error;
      AppToast.error(context, error ?? 'No se pudo subir la grabación');
    }
  }

  Future<void> _cancelar() async {
    if (_subiendo) return; // no salir mientras se sube el audio
    if (_grabando) {
      final salir = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Descartar grabación'),
          content: const Text('Se perderá el audio grabado. ¿Salir?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Continuar grabando'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
      if (salir != true) return;
      await _recorder.stop();
      _timer?.cancel();
      if (_rutaAudio != null) {
        try {
          await File(_rutaAudio!).delete();
        } catch (_) {}
      }
    }
    if (mounted) Navigator.pop(context);
  }

  String get _tiempo {
    final h = _segundos ~/ 3600;
    final m = ((_segundos % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_segundos % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  // ─── UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelar();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Grabar Acta'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _subiendo ? null : _cancelar,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              TextField(
                controller: _tituloCtrl,
                enabled: !_grabando && !_subiendo,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Título del acta',
                  hintText: 'Ej: Reunión ordinaria del consejo — Julio',
                  counterText: '',
                ),
              ),
              const Spacer(),
              // ── Indicador de tiempo ──
              Text(
                _tiempo,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: _grabando && !_pausado
                      ? AppColors.danger
                      : cs.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _subiendo
                    ? 'Subiendo grabación…'
                    : !_grabando
                        ? 'Listo para grabar'
                        : _pausado
                            ? 'Grabación en pausa'
                            : 'Grabando reunión…',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              // ── Controles ──
              if (_subiendo)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.xxl),
                  child: CircularProgressIndicator(),
                )
              else if (!_grabando)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  child: _BotonMic(onTap: _iniciar),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        iconSize: 32,
                        tooltip: _pausado ? 'Reanudar' : 'Pausar',
                        onPressed: _pausarReanudar,
                        icon: Icon(_pausado
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                          ),
                          onPressed: _detenerYSubir,
                          icon: const Icon(Icons.stop_rounded),
                          label: const Text('Detener y subir'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Botón grande de micrófono ────────────────────────────────────────────────

class _BotonMic extends StatelessWidget {
  final VoidCallback onTap;
  const _BotonMic({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(60),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.primary,
        ),
        child: Icon(Icons.mic_rounded, size: 44, color: cs.onPrimary),
      ),
    );
  }
}
