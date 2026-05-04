import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Anillo de progreso 3D isometrico.
/// El aro blanco es el brazo y el progreso es una manga que lo envuelve.
class IsometricProgressRing extends StatefulWidget {
  final double percentage; // 0.0 a 1.0
  final double startOffset; // 0.0 a 1.0
  final double size;
  final Color progressColor;
  final Color baseColor;
  final Color trackColor;
  final Color backgroundColor;
  final Duration animationDuration;

  const IsometricProgressRing({
    super.key,
    required this.percentage,
    this.startOffset = 0.12,
    this.size = 300,
    this.progressColor = const Color(0xFFBDD827),
    this.baseColor = const Color(0xFF5AB020),
    this.trackColor = const Color.fromARGB(255, 255, 255, 255),
    this.backgroundColor = Colors.black,
    this.animationDuration = const Duration(milliseconds: 1800),
  });

  @override
  State<IsometricProgressRing> createState() => _IsometricProgressRingState();
}

class _IsometricProgressRingState extends State<IsometricProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double get _target => widget.percentage.clamp(0.0, 2.0).toDouble();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation = _tween(0.0, _target);
    _controller.forward();
  }

  Animation<double> _tween(double from, double to) {
    return Tween<double>(
      begin: from,
      end: to,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant IsometricProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.percentage != widget.percentage) {
      _animation = _tween(_animation.value, _target);
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      color: widget.backgroundColor,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) => CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _IsometricRingPainter(
            percentage: _animation.value,
            startOffset: widget.startOffset,
            progressColor: widget.progressColor,
            baseColor: widget.baseColor,
            trackColor: widget.trackColor,
          ),
        ),
      ),
    );
  }
}

class _IsometricRingPainter extends CustomPainter {
  final double percentage;
  final double startOffset;
  final Color progressColor;
  final Color baseColor;
  final Color trackColor;

  _IsometricRingPainter({
    required this.percentage,
    required this.startOffset,
    required this.progressColor,
    required this.baseColor,
    required this.trackColor,
  });

  static const double _yScale = 0.7;
  static const int _segments = 560;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = percentage.clamp(0.0, 1.0).toDouble();

    final cx = size.width / 2;
    final cy = size.height / 2;

    final centerR = size.width * 0.3;

    final armThickness = size.width * 0.008;   //aro
    final armDepth = size.height * 0.007;       // más plano

    final sleeveThickness = size.width * 0.055; //progreso
    final sleeveDepth = size.height * 0.032;    // plano: ratio altura/ancho reducido

    final sleeveTopY = cy - sleeveDepth * 0.45;
    final sleeveBotY = sleeveTopY + sleeveDepth;

    final armTopY = sleeveTopY + (sleeveDepth - armDepth) / 2.5;
    final armBotY = armTopY + armDepth;

    final startAngle = -math.pi / 2 + (2 * math.pi * startOffset);
    final sweepAngle = 2 * math.pi * progress;
    final endAngle = startAngle + sweepAngle;

    final discR = centerR - armThickness / 2 - size.width * 0.11;
    final discHeight = size.height * 0.038;
    final discTopY = sleeveTopY;
    final discBotY = discTopY + discHeight;

    // ── Plataforma base: disco 3D prominente ──────────────────────────────
    _drawBasePlatform(
      canvas: canvas,
      cx: cx,
      discR: discR,
      discTopY: discTopY,
      discBotY: discBotY,
    );

    // ── Sin progreso: anillo completo, sin manga ───────────────────────────
    if (progress <= 0) {
      _drawArmSegment3D(
        canvas: canvas,
        cx: cx,
        topY: armTopY,
        botY: armBotY,
        centerR: centerR,
        thickness: armThickness,
        startAngle: 0,
        sweepAngle: 2 * math.pi,
        drawStartCap: false,
        drawEndCap: false,
      );
      return;
    }

    // ── Con progreso: NUNCA dibujar el anillo completo ─────────────────────
    // Dibujamos el arm SOLO en las regiones donde debe verse,
    // eliminando las cuñas en los extremos de la manga.
    final remainingSweep = 2 * math.pi - sweepAngle;

    double visibleSweep = 0.0;
    double exitMaskSweep = 0.0;

    if (remainingSweep > 0.001) {
      final connectionReveal = _connectionRevealForProgress(progress);
      final connectionBoost = (1.0 - progress).clamp(0.0, 1.0);
      final dynamicFactor = 1.65 + (1.8 * connectionBoost);
      final coverSweep = math.max(
        0.12,
        (armThickness / centerR) * dynamicFactor,
      );
      final rawHidden = coverSweep * (1.0 - connectionReveal);
      final hiddenAtStartSweep = math
          .min(remainingSweep * 0.6, rawHidden)
          .toDouble();

      visibleSweep = remainingSweep - hiddenAtStartSweep;

      exitMaskSweep = _exitMaskSweepForProgress(
        progress: progress,
        armThickness: armThickness,
        centerR: centerR,
        availableSweep: visibleSweep,
      );

      final armVisibleStartAngle = endAngle + exitMaskSweep;
      final armVisibleSweep = visibleSweep - exitMaskSweep;

      // Arm en la región visible (entre cap de fin y zona oculta del inicio)
      if (armVisibleSweep > 0.001) {
        _drawArmSegment3D(
          canvas: canvas,
          cx: cx,
          topY: armTopY,
          botY: armBotY,
          centerR: centerR,
          thickness: armThickness,
          startAngle: armVisibleStartAngle,
          sweepAngle: armVisibleSweep,
          drawStartCap: false,
          drawEndCap: false,
        );
      }

      // Pequeño segmento justo bajo el cap de inicio:
      // da continuidad visual (visible a través de la ranura del cap)
      // sin extenderse hasta los extremos de la manga.
      final slotExtend = (armThickness / centerR) * 0.9;
      final slotStart = startAngle - hiddenAtStartSweep;
      final slotSweep = hiddenAtStartSweep + slotExtend;
      if (slotSweep > 0.001) {
        _drawArmSegment3D(
          canvas: canvas,
          cx: cx,
          topY: armTopY,
          botY: armBotY,
          centerR: centerR,
          thickness: armThickness,
          startAngle: slotStart,
          sweepAngle: slotSweep,
          drawStartCap: false,
          drawEndCap: false,
        );
      }
    }

    // ── Manga encima del arm ───────────────────────────────────────────────
    _drawSleeve3D(
      canvas: canvas,
      cx: cx,
      topY: sleeveTopY,
      botY: sleeveBotY,
      armTopY: armTopY,
      armBotY: armBotY,
      centerR: centerR,
      sleeveThickness: sleeveThickness,
      armThickness: armThickness,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
    );

    _drawSoftBridge(
  canvas: canvas,
  cx: cx,
  topY: armTopY,
  botY: armBotY,
  centerR: centerR,
  armThickness: armThickness,
  angle: endAngle,
  progress: progress,
);

    if (remainingSweep > 0.001) {
      _redrawSleeveEndCap(
        canvas: canvas,
        cx: cx,
        topY: sleeveTopY,
        botY: sleeveBotY,
        armTopY: armTopY,
        armBotY: armBotY,
        centerR: centerR,
        sleeveThickness: sleeveThickness,
        armThickness: armThickness,
        endAngle: endAngle,
      );

      _redrawSleeveStartCap(
        canvas: canvas,
        cx: cx,
        topY: sleeveTopY,
        botY: sleeveBotY,
        armTopY: armTopY,
        armBotY: armBotY,
        centerR: centerR,
        sleeveThickness: sleeveThickness,
        armThickness: armThickness,
        startAngle: startAngle,
      );

      _redrawSleeveTopSurface(
        canvas: canvas,
        cx: cx,
        topY: sleeveTopY,
        centerR: centerR,
        sleeveThickness: sleeveThickness,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
      );

      if (visibleSweep > 0.001) {
        _drawArmExitConnector(
          canvas: canvas,
          cx: cx,
          topY: armTopY,
          botY: armBotY,
          centerR: centerR,
          armThickness: armThickness,
          endAngle: endAngle,
          availableSweep: visibleSweep,
          exitMaskSweep: exitMaskSweep,
        );
      }
    }
  }

  double _connectionRevealForProgress(double progress) {
    // Ventana adelantada para arm grueso (0.088):
    // a 20 % ya ocultamos ~36° del arm antes del inicio de la manga,
    // eliminando el artefacto de cuña en porcentajes bajos.
    if (progress <= 0.06) return 1.0;
    if (progress >= 0.28) return 0.0;

    final t = ((progress - 0.06) / (0.28 - 0.06)).clamp(0.0, 1.0).toDouble();
    final smooth = t * t * (3.0 - 2.0 * t);

    return 1.0 - smooth;
  }

  double _capSlotClosureForProgress(double progress) {
    if (progress <= 0.42) return 0.0;
    if (progress >= 0.55) return 1.0;

    final t = ((progress - 0.42) / (0.55 - 0.42)).clamp(0.0, 1.0).toDouble();
    return t * t * (3.0 - 2.0 * t);
  }

  double _exitMaskSweepForProgress({
    required double progress,
    required double armThickness,
    required double centerR,
    required double availableSweep,
  }) {
    final lowProgress = ((0.45 - progress) / 0.45)
        .clamp(0.0, 1.0)
        .toDouble();

    if (lowProgress <= 0 || availableSweep <= 0.001) return 0.0;

    final targetSweep = math.max(
      0.055,
      (armThickness / centerR) * (0.55 + 0.35 * lowProgress),
    );

    final dynamicClamp = 0.35 + (0.25 * (1 - progress));

return math.min(availableSweep * dynamicClamp, targetSweep);
  }

  void _drawArmExitConnector({
    required Canvas canvas,
    required double cx,
    required double topY,
    required double botY,
    required double centerR,
    required double armThickness,
    required double endAngle,
    required double availableSweep,
    required double exitMaskSweep,
  }) {
    final lowProgress = ((0.38 - percentage) / 0.42)
        .clamp(0.0, 1.0)
        .toDouble();

    if (lowProgress <= 0 || availableSweep <= 0.001) return;

    final outerR = centerR + armThickness / 2 ;
    final innerR = centerR - armThickness / 2 ;

    final centerBridgeSweep = math.min(
      availableSweep,
      math.max(
        exitMaskSweep,
        (armThickness / centerR) * (1.6 + 1.2 * lowProgress),
      ),
    ).toDouble();

    if (centerBridgeSweep > 0.001) {
      _drawArmSegment3D(
        canvas: canvas,
        cx: cx,
        topY: topY,
        botY: botY,
        centerR: centerR,
        thickness: armThickness,
        startAngle: endAngle,
        sweepAngle: centerBridgeSweep,
        drawStartCap: false,
        drawEndCap: false,
      );
    }

    final slot = _buildCapPath(
      cx: cx,
      topY: topY,
      botY: botY,
      outerR: outerR + 0.9,
      innerR: innerR - 0.9,
      angle: endAngle,
    );

    canvas.save();
    canvas.clipPath(slot, doAntiAlias: true);

    _drawArmCap(
      canvas: canvas,
      cx: cx,
      topY: topY,
      botY: botY,
      outerR: outerR + 0.7,
      innerR: innerR - 0.7,
      angle: endAngle,
    );

    canvas.restore();
  }

  // ── Plataforma base: disco 3D prominente ────────────────────────────────
  /// Dibuja un disco/moneda 3D isométrico como plataforma central.
  /// Top: amarillo-lima (progressColor). Pared lateral: verde oscuro.
  void _drawBasePlatform({
    required Canvas canvas,
    required double cx,
    required double discR,
    required double discTopY,
    required double discBotY,
  }) {
    // ── Sombra difusa debajo del disco ──────────────────────────────────
    final shadowRect = Rect.fromCenter(
      center: Offset(cx, discBotY + 4),
      width: (discR + 16) * 2,
      height: (discR + 16) * _yScale * 0.55,
    );
    canvas.drawOval(
      shadowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.black.withOpacity(0.32), Colors.transparent],
        ).createShader(shadowRect)
        ..isAntiAlias = true,
    );

    // ── Pared del cilindro (mitad frontal visible) ──────────────────────
    final sideColor = _darken(progressColor, 0.26);
    final wallPath = _buildWallPath(
      cx: cx,
      topY: discTopY,
      botY: discBotY,
      r: discR,
      startAngle: 0,
      sweepAngle: math.pi,
    );
    canvas.drawPath(
      wallPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _lighten(sideColor, 0.06),
            sideColor,
            _darken(sideColor, 0.14),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(wallPath.getBounds())
        ..isAntiAlias = true,
    );

    // ── Cara superior del disco (amarillo-lima) ─────────────────────────
    final topRect = Rect.fromCenter(
      center: Offset(cx, discTopY),
      width: discR * 2,
      height: discR * 2 * _yScale,
    );
    final topPath = Path()..addOval(topRect);

    canvas.drawPath(
      topPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _lighten(progressColor, 0.22),
            _lighten(progressColor, 0.08),
            progressColor,
            _darken(progressColor, 0.10),
            _darken(progressColor, 0.18),
          ],
          stops: const [0.0, 0.22, 0.55, 0.80, 1.0],
        ).createShader(topRect)
        ..isAntiAlias = true,
    );

    // Especular — reflejo de luz frontal-izquierdo
    canvas.drawPath(
      topPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.80,
          colors: [
            Colors.white.withOpacity(0.22),
            Colors.white.withOpacity(0.06),
            Colors.transparent,
          ],
          stops: const [0.0, 0.38, 1.0],
        ).createShader(topRect)
        ..blendMode = BlendMode.screen
        ..isAntiAlias = true,
    );
  }
  // ───────────────────────────────────────────────────────────────────────

  void _drawArmSegment3D({
    required Canvas canvas,
    required double cx,
    required double topY,
    required double botY,
    required double centerR,
    required double thickness,
    required double startAngle,
    required double sweepAngle,
    required bool drawStartCap,
    required bool drawEndCap,
  }) {
    final outerR = centerR + thickness / 2;
    final innerR = centerR - thickness / 2;
    final isFullRing = sweepAngle.abs() >= 2 * math.pi - 0.001;

    _drawSoftWall(
      canvas: canvas,
      cx: cx,
      topY: topY,
      botY: botY,
      r: outerR,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      baseColor: _darken(trackColor, 0.16),
    );

    _drawSoftWall(
      canvas: canvas,
      cx: cx,
      topY: topY,
      botY: botY,
      r: innerR,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      baseColor: _darken(trackColor, 0.24),
    );

    if (!isFullRing) {
      if (drawStartCap) {
        _drawArmCap(
          canvas: canvas,
          cx: cx,
          topY: topY,
          botY: botY,
          outerR: outerR,
          innerR: innerR,
          angle: startAngle,
        );
      }

      if (drawEndCap) {
        _drawArmCap(
          canvas: canvas,
          cx: cx,
          topY: topY,
          botY: botY,
          outerR: outerR,
          innerR: innerR,
          angle: startAngle + sweepAngle,
        );
      }
    }

    final topFace = _buildAnnularSector(
      cx: cx,
      cy: topY,
      outerR: outerR,
      innerR: innerR,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
    );

    canvas.drawPath(
      topFace,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _lighten(trackColor, 0.08),
            trackColor,
            _darken(trackColor, 0.08),
          ],
        ).createShader(topFace.getBounds())
        ..isAntiAlias = true,
    );
  }

  void _drawSleeve3D({
    required Canvas canvas,
    required double cx,
    required double topY,
    required double botY,
    required double armTopY,
    required double armBotY,
    required double centerR,
    required double sleeveThickness,
    required double armThickness,
    required double startAngle,
    required double sweepAngle,
  }) {
    final outerR = centerR + sleeveThickness / 2;
    final innerR = centerR - sleeveThickness / 2;

    final armOuterR = centerR + armThickness / 2;
    final armInnerR = centerR - armThickness / 2;

    final isFullRing = sweepAngle.abs() >= 2 * math.pi - 0.001;

    _drawSleeveOuterWall(
      canvas: canvas,
      cx: cx,
      topY: topY,
      botY: botY,
      r: outerR,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
    );

    _drawSleeveInnerWall(
      canvas: canvas,
      cx: cx,
      topY: topY,
      botY: botY,
      r: innerR,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
    );

    if (!isFullRing) {
      _drawSleeveCap(
        canvas: canvas,
        cx: cx,
        topY: topY,
        botY: botY,
        armTopY: armTopY,
        armBotY: armBotY,
        outerR: outerR,
        innerR: innerR,
        armOuterR: armOuterR,
        armInnerR: armInnerR,
        angle: startAngle,
        color: _darken(progressColor, 0.12),
      );

      _drawSleeveCap(
        canvas: canvas,
        cx: cx,
        topY: topY,
        botY: botY,
        armTopY: armTopY,
        armBotY: armBotY,
        outerR: outerR,
        innerR: innerR,
        armOuterR: armOuterR,
        armInnerR: armInnerR,
        angle: startAngle + sweepAngle,
        color: _darken(progressColor, 0.08),
      );
    }

    _drawSleeveTop(
      canvas: canvas,
      cx: cx,
      topY: topY,
      outerR: outerR,
      innerR: innerR,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      thickness: sleeveThickness,
    );
  }

  void _redrawSleeveStartCap({
    required Canvas canvas,
    required double cx,
    required double topY,
    required double botY,
    required double armTopY,
    required double armBotY,
    required double centerR,
    required double sleeveThickness,
    required double armThickness,
    required double startAngle,
  }) {
    final connectionBoost = (1.0 - percentage).clamp(0.0, 1.0);

    // Bleed escalado al grosor del arm para cubrir bien el borde lateral
    // cuando el arm es grueso (antes era fijo en ~0.8 px, insuficiente).
    final bleed = math.max(
      armThickness * 0.06,
      sleeveThickness * (0.005 + 0.06 * connectionBoost),
    );

    final outerR = centerR + sleeveThickness / 2 + bleed;
    final innerR = centerR - sleeveThickness / 2 - bleed;

    final armOuterR = centerR + armThickness / 2;
    final armInnerR = centerR - armThickness / 2;

    _drawSleeveCap(
      canvas: canvas,
      cx: cx,
      topY: topY,
      botY: botY,
      armTopY: armTopY,
      armBotY: armBotY,
      outerR: outerR,
      innerR: innerR,
      armOuterR: armOuterR,
      armInnerR: armInnerR,
      angle: startAngle,
      color: _darken(progressColor, 0.12),
    );
  }

  void _redrawSleeveEndCap({
    required Canvas canvas,
    required double cx,
    required double topY,
    required double botY,
    required double armTopY,
    required double armBotY,
    required double centerR,
    required double sleeveThickness,
    required double armThickness,
    required double endAngle,
  }) {

    final outerR = centerR + sleeveThickness / 2 ;
    final innerR = centerR - sleeveThickness / 2 ;

    final armOuterR = centerR + armThickness / 2;
    final armInnerR = centerR - armThickness / 2;

    _drawSleeveCap(
      canvas: canvas,
      cx: cx,
      topY: topY,
      botY: botY,
      armTopY: armTopY,
      armBotY: armBotY,
      outerR: outerR,
      innerR: innerR,
      armOuterR: armOuterR,
      armInnerR: armInnerR,
      angle: endAngle,
      color: _darken(progressColor, 0.08),
    );
  }

  void _drawSoftBridge({
  required Canvas canvas,
  required double cx,
  required double topY,
  required double botY,
  required double centerR,
  required double armThickness,
  required double angle,
  required double progress,
}) {
  final outerR = centerR + armThickness / 2;
  final innerR = centerR - armThickness / 2;

  // Cuanto más bajo el progreso → más grande el puente
  final intensity = ((0.35 - progress) / 0.35).clamp(0.0, 1.0);

  if (intensity <= 0) return;

  // Sweep pequeño pero dinámico
  final bridgeSweep = (armThickness / centerR) * (1.2 + 1.8 * intensity);

  // Expandimos ligeramente para tapar el gap
  final bleed = armThickness * (0.15 + 0.25 * intensity);

  final path = _buildAnnularSector(
    cx: cx,
    cy: topY,
    outerR: outerR + bleed,
    innerR: innerR - bleed,
    startAngle: angle,
    sweepAngle: bridgeSweep,
  );

  final bounds = path.getBounds();

  canvas.drawPath(
    path,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        radius: 1.0,
        colors: [
          _lighten(trackColor, 0.12).withOpacity(0.9 * intensity),
          trackColor.withOpacity(0.7 * intensity),
          trackColor.withOpacity(0.25 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.75, 1.0],
      ).createShader(bounds)
      ..blendMode = BlendMode.srcOver
      ..isAntiAlias = true,
  );
}

  void _redrawSleeveTopSurface({
    required Canvas canvas,
    required double cx,
    required double topY,
    required double centerR,
    required double sleeveThickness,
    required double startAngle,
    required double sweepAngle,
  }) {
    final outerR = centerR + sleeveThickness / 2;
    final innerR = centerR - sleeveThickness / 2;

    _drawSleeveTop(
      canvas: canvas,
      cx: cx,
      topY: topY,
      outerR: outerR,
      innerR: innerR,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      thickness: sleeveThickness,
    );
  }

  void _drawSleeveTop({
    required Canvas canvas,
    required double cx,
    required double topY,
    required double outerR,
    required double innerR,
    required double startAngle,
    required double sweepAngle,
    required double thickness,
  }) {
    final topFace = _buildAnnularSector(
      cx: cx,
      cy: topY,
      outerR: outerR,
      innerR: innerR,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
    );

    final bounds = topFace.getBounds();

    // ── Commit 3: gradiente base con mayor contraste claro/oscuro ──────────
    canvas.drawPath(
      topFace,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _lighten(progressColor, 0.20),
            _lighten(progressColor, 0.08),
            progressColor,
            _darken(progressColor, 0.10),
            _darken(progressColor, 0.18),
          ],
          stops: const [0.0, 0.22, 0.55, 0.80, 1.0],
        ).createShader(bounds)
        ..isAntiAlias = true,
    );

    // Especular principal — reflejo de luz frontal-izquierdo
    canvas.drawPath(
      topFace,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.55, -0.60),
          radius: 1.05,
          colors: [
            Colors.white.withOpacity(0.22),
            Colors.white.withOpacity(0.07),
            Colors.transparent,
          ],
          stops: const [0.0, 0.40, 1.0],
        ).createShader(bounds)
        ..blendMode = BlendMode.screen
        ..isAntiAlias = true,
    );

    // Especular secundario sutil — borde derecho de la superficie
    canvas.drawPath(
      topFace,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.75, 0.60),
          radius: 0.65,
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ).createShader(bounds)
        ..blendMode = BlendMode.screen
        ..isAntiAlias = true,
    );
    // ───────────────────────────────────────────────────────────────────────

    _drawTopRims(
      canvas: canvas,
      cx: cx,
      cy: topY,
      outerR: outerR,
      innerR: innerR,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      thickness: thickness,
    );
  }

  void _drawSleeveOuterWall({
    required Canvas canvas,
    required double cx,
    required double topY,
    required double botY,
    required double r,
    required double startAngle,
    required double sweepAngle,
  }) {
    _drawContinuousVisibleWall(
      canvas: canvas,
      cx: cx,
      topY: topY,
      botY: botY,
      r: r,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      baseColor: _darken(progressColor, 0.18),
      visibleWhen: (angle) => math.sin(angle) > -0.02,
      bottomEdgeOpacity: 0.16,
    );
  }

  void _drawSleeveInnerWall({
    required Canvas canvas,
    required double cx,
    required double topY,
    required double botY,
    required double r,
    required double startAngle,
    required double sweepAngle,
  }) {
    _drawContinuousVisibleWall(
      canvas: canvas,
      cx: cx,
      topY: topY,
      botY: botY,
      r: r,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      baseColor: _darken(progressColor, 0.27),
      visibleWhen: (angle) => math.sin(angle) < 0.58,
      bottomEdgeOpacity: 0.07,
    );
  }

  void _drawContinuousVisibleWall({
    required Canvas canvas,
    required double cx,
    required double topY,
    required double botY,
    required double r,
    required double startAngle,
    required double sweepAngle,
    required Color baseColor,
    required bool Function(double angle) visibleWhen,
    required double bottomEdgeOpacity,
  }) {
    final steps = math.max(
      16,
      (_segments * sweepAngle.abs() / (2 * math.pi)).ceil(),
    );

    for (int i = 0; i < steps; i++) {
      final a0 = startAngle + sweepAngle * (i / steps);
      final a1 = startAngle + sweepAngle * ((i + 1) / steps);
      final mid = (a0 + a1) / 2;

      double visibility = visibleWhen(mid) ? 1.0 : 0.0;

      // Transición suave cerca del horizonte
      const fadeZone = 0.12;
      final horizon = math.sin(mid);

      if (horizon > -fadeZone && horizon < fadeZone) {
        final t = ((horizon + fadeZone) / (2 * fadeZone)).clamp(0.0, 1.0);
        visibility *= t;
      }

      if (visibility <= 0.01) continue;

      final wall = _buildWallPath(
        cx: cx,
        topY: topY,
        botY: botY,
        r: r,
        startAngle: a0,
        sweepAngle: a1 - a0,
      );

      canvas.drawPath(
        wall,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _lighten(baseColor, 0.055).withOpacity(visibility),
              baseColor.withOpacity(visibility),
              _darken(baseColor, 0.115).withOpacity(visibility),
            ],
          ).createShader(wall.getBounds())
          ..isAntiAlias = true,
      );
    }
  }

  void _drawSleeveCap({
    required Canvas canvas,
    required double cx,
    required double topY,
    required double botY,
    required double armTopY,
    required double armBotY,
    required double outerR,
    required double innerR,
    required double armOuterR,
    required double armInnerR,
    required double angle,
    required Color color,
  }) {
    final fullCap = _buildCapPath(
      cx: cx,
      topY: topY,
      botY: botY,
      outerR: outerR,
      innerR: innerR,
      angle: angle,
    );

    final armSlot = _buildCapPath(
      cx: cx,
      topY: armTopY,
      botY: armBotY,
      outerR: armOuterR,
      innerR: armInnerR,
      angle: angle,
    );

    final capWithHole = Path.combine(
      PathOperation.difference,
      fullCap,
      armSlot,
    );

    final bounds = fullCap.getBounds();
    final slotClosure = _capSlotClosureForProgress(percentage);

    canvas.drawPath(
      capWithHole,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_lighten(color, 0.08), color, _darken(color, 0.14)],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(bounds)
        ..isAntiAlias = true,
    );

    if (slotClosure > 0) {
      canvas.drawPath(
        fullCap,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _lighten(color, 0.08).withOpacity(slotClosure),
              color.withOpacity(slotClosure),
              _darken(color, 0.14).withOpacity(slotClosure),
            ],
            stops: const [0.0, 0.42, 1.0],
          ).createShader(bounds)
          ..isAntiAlias = true,
      );
    }

    if (slotClosure < 0.98) {
      canvas.drawPath(
        capWithHole,
        Paint()
          ..color = Colors.white.withOpacity(0.055 * (1.0 - slotClosure))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..isAntiAlias = true,
      );
    }
  }

  void _drawArmCap({
    required Canvas canvas,
    required double cx,
    required double topY,
    required double botY,
    required double outerR,
    required double innerR,
    required double angle,
  }) {
    final cap = _buildCapPath(
      cx: cx,
      topY: topY,
      botY: botY,
      outerR: outerR,
      innerR: innerR,
      angle: angle,
    );

    canvas.drawPath(
      cap,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _lighten(trackColor, 0.08),
            trackColor,
            _darken(trackColor, 0.12),
          ],
        ).createShader(cap.getBounds())
        ..isAntiAlias = true,
    );
  }

  void _drawSoftWall({
    required Canvas canvas,
    required double cx,
    required double topY,
    required double botY,
    required double r,
    required double startAngle,
    required double sweepAngle,
    required Color baseColor,
  }) {
    final wall = _buildWallPath(
      cx: cx,
      topY: topY,
      botY: botY,
      r: r,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
    );

    canvas.drawPath(
      wall,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _lighten(baseColor, 0.025),
            baseColor,
            _darken(baseColor, 0.07),
          ],
        ).createShader(wall.getBounds())
        ..isAntiAlias = true,
    );
  }

  void _drawTopRims({
    required Canvas canvas,
    required double cx,
    required double cy,
    required double outerR,
    required double innerR,
    required double startAngle,
    required double sweepAngle,
    required double thickness,
  }) {
    final stroke = math.max(0.7, thickness * 0.022);

    canvas.drawPath(
      _buildEllipsePath(
        cx: cx,
        cy: cy,
        r: outerR,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
      ),
      Paint()
        ..color = Colors.white.withOpacity(0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );

    canvas.drawPath(
      _buildEllipsePath(
        cx: cx,
        cy: cy,
        r: innerR,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.9
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  Path _buildWallPath({
    required double cx,
    required double topY,
    required double botY,
    required double r,
    required double startAngle,
    required double sweepAngle,
  }) {
    final path = Path();
    final steps = math.max(
      4,
      (_segments * sweepAngle.abs() / (2 * math.pi)).ceil(),
    );

    for (int i = 0; i <= steps; i++) {
      final a = startAngle + sweepAngle * (i / steps);
      final x = cx + r * math.cos(a);
      final y = topY + r * _yScale * math.sin(a);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    for (int i = steps; i >= 0; i--) {
      final a = startAngle + sweepAngle * (i / steps);
      path.lineTo(cx + r * math.cos(a), botY + r * _yScale * math.sin(a));
    }

    path.close();
    return path;
  }

  Path _buildCapPath({
    required double cx,
    required double topY,
    required double botY,
    required double outerR,
    required double innerR,
    required double angle,
  }) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    return Path()
      ..moveTo(cx + innerR * cosA, topY + innerR * _yScale * sinA)
      ..lineTo(cx + outerR * cosA, topY + outerR * _yScale * sinA)
      ..lineTo(cx + outerR * cosA, botY + outerR * _yScale * sinA)
      ..lineTo(cx + innerR * cosA, botY + innerR * _yScale * sinA)
      ..close();
  }

  Path _buildEllipsePath({
    required double cx,
    required double cy,
    required double r,
    required double startAngle,
    required double sweepAngle,
  }) {
    final path = Path();
    final steps = math.max(
      2,
      (_segments * sweepAngle.abs() / (2 * math.pi)).ceil(),
    );

    for (int i = 0; i <= steps; i++) {
      final a = startAngle + sweepAngle * (i / steps);
      final x = cx + r * math.cos(a);
      final y = cy + r * _yScale * math.sin(a);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    return path;
  }

  Path _buildAnnularSector({
    required double cx,
    required double cy,
    required double outerR,
    required double innerR,
    required double startAngle,
    required double sweepAngle,
  }) {
    final path = Path();
    final steps = math.max(
      2,
      (_segments * sweepAngle.abs() / (2 * math.pi)).ceil(),
    );

    for (int i = 0; i <= steps; i++) {
      final a = startAngle + sweepAngle * (i / steps);
      final x = cx + outerR * math.cos(a);
      final y = cy + outerR * _yScale * math.sin(a);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    for (int i = steps; i >= 0; i--) {
      final a = startAngle + sweepAngle * (i / steps);
      final x = cx + innerR * math.cos(a);
      final y = cy + innerR * _yScale * math.sin(a);
      path.lineTo(x, y);
    }

    path.close();
    return path;
  }

  Color _darken(Color color, double amount) {
    return _shiftLightness(color, -amount);
  }

  Color _lighten(Color color, double amount) {
    return _shiftLightness(color, amount);
  }

  Color _shiftLightness(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(covariant _IsometricRingPainter old) =>
      old.percentage != percentage ||
      old.startOffset != startOffset ||
      old.progressColor != progressColor ||
      old.baseColor != baseColor ||
      old.trackColor != trackColor;
}
