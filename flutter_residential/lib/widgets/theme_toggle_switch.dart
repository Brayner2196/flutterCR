import 'dart:math';
import 'package:flutter/material.dart';

class ThemeToggleSwitch extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const ThemeToggleSwitch({
    super.key,
    required this.isDark,
    required this.onToggle,
  });

  @override
  State<ThemeToggleSwitch> createState() => _ThemeToggleSwitchState();
}

class _ThemeToggleSwitchState extends State<ThemeToggleSwitch>
    with TickerProviderStateMixin {
  // 0 = luz, 1 = oscuro
  late final AnimationController _mainCtrl;
  // rotación del círculo al cambiar
  late final AnimationController _rotateCtrl;
  // parpadeo continuo de las estrellas
  late final AnimationController _twinkleCtrl;
  // flotado continuo de las nubes
  late final AnimationController _cloudCtrl;

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: widget.isDark ? 1.0 : 0.0,
    );
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _twinkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _cloudCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void didUpdateWidget(ThemeToggleSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDark != oldWidget.isDark) {
      widget.isDark ? _mainCtrl.forward() : _mainCtrl.reverse();
      _rotateCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _rotateCtrl.dispose();
    _twinkleCtrl.dispose();
    _cloudCtrl.dispose();
    super.dispose();
  }

  // Desplazamiento de flotado de nubes: 0→4→-4→0 en el ciclo de 6s
  double _cloudFloat(double t) {
    if (t < 0.4) return 4.0 * (t / 0.4);
    if (t < 0.8) return 4.0 - 8.0 * ((t - 0.4) / 0.4);
    return -4.0 + 4.0 * ((t - 0.8) / 0.2);
  }

  // Escala de parpadeo de estrellas con delay individual
  double _starScale(double t, double delayFraction) {
    final dt = (t + delayFraction) % 1.0;
    if (dt < 0.4) return 1.0 + 0.2 * (dt / 0.4);
    if (dt < 0.8) return 1.2 - 0.4 * ((dt - 0.4) / 0.4);
    return 0.8 + 0.2 * ((dt - 0.8) / 0.2);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _mainCtrl,
          _rotateCtrl,
          _twinkleCtrl,
          _cloudCtrl,
        ]),
        builder: (context, _) {
          final t = CurvedAnimation(
            parent: _mainCtrl,
            curve: Curves.easeInOut,
          ).value;

          final ballLeft = 4.0 + 26.0 * t;
          final bg = Color.lerp(const Color(0xFF2196F3), Colors.black, t)!;
          final ballColor = Color.lerp(Colors.yellow, Colors.white, t)!;
          final rotAngle = _rotateCtrl.value * 2 * pi;
          // Las nubes se desplazan junto con la bola + flotado
          final cloudDx = 26.0 * t + _cloudFloat(_cloudCtrl.value).clamp(0.0, 26.0);

          return Container(
            width: 60,
            height: 34,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(34),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                // ── Estrellas (modo oscuro) ──────────────────────────────
                // En modo luz se ocultan 32px arriba; en modo oscuro vuelven a y=0
                Transform.translate(
                  offset: Offset(0, -32.0 * (1 - t)),
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: SizedBox(
                      width: 60,
                      height: 34,
                      child: Stack(
                        children: [
                          _buildStar(left: 3, top: 2, size: 20, delay: 0.15),
                          _buildStar(left: 3, top: 16, size: 6, delay: 0.0),
                          _buildStar(left: 10, top: 20, size: 12, delay: 0.30),
                          _buildStar(left: 18, top: 0, size: 18, delay: 0.65),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Nubes (modo luz) ─────────────────────────────────────
                // Posiciones calculadas con base en sun-moon inicial (left:4, top:4)
                // Al deslizarse la bola 26px, las nubes salen del track por la derecha
                Transform.translate(
                  offset: Offset(cloudDx, 0),
                  child: Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0),
                    child: SizedBox(
                      width: 60,
                      height: 34,
                      child: Stack(
                        children: [
                          _buildCloud(left: 34, top: 19, size: 40, color: const Color(0xFFCCCCCC)),
                          _buildCloud(left: 48, top: 14, size: 20, color: const Color(0xFFCCCCCC)),
                          _buildCloud(left: 22, top: 28, size: 30, color: const Color(0xFFCCCCCC)),
                          _buildCloud(left: 40, top: 22, size: 40, color: const Color(0xFFEEEEEE)),
                          _buildCloud(left: 52, top: 18, size: 20, color: const Color(0xFFEEEEEE)),
                          _buildCloud(left: 26, top: 30, size: 30, color: const Color(0xFFEEEEEE)),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bola sol / luna ──────────────────────────────────────
                Positioned(
                  left: ballLeft,
                  top: 4,
                  child: Transform.rotate(
                    angle: rotAngle,
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Rayos de luz (detrás de la bola, visibles en modo sol)
                          Positioned(
                            left: -8,
                            top: -8,
                            child: Opacity(
                              opacity: 0.1 * (1 - t),
                              child: _circle(43),
                            ),
                          ),
                          Positioned(
                            left: -13,
                            top: -13,
                            child: Opacity(
                              opacity: 0.1 * (1 - t),
                              child: _circle(55),
                            ),
                          ),
                          Positioned(
                            left: -18,
                            top: -18,
                            child: Opacity(
                              opacity: 0.1 * (1 - t),
                              child: _circle(60),
                            ),
                          ),

                          // Círculo principal (amarillo → blanco)
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: ballColor,
                              shape: BoxShape.circle,
                            ),
                          ),

                          // Cráteres de la luna (opacos en modo oscuro)
                          Positioned(
                            left: 10,
                            top: 3,
                            child: Opacity(
                              opacity: t,
                              child: _crater(6),
                            ),
                          ),
                          Positioned(
                            left: 2,
                            top: 10,
                            child: Opacity(
                              opacity: t,
                              child: _crater(10),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            top: 18,
                            child: Opacity(
                              opacity: t,
                              child: _crater(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStar({
    required double left,
    required double top,
    required double size,
    required double delay,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.scale(
        scale: _starScale(_twinkleCtrl.value, delay),
        child: CustomPaint(
          size: Size(size, size),
          painter: _StarPainter(),
        ),
      ),
    );
  }

  Widget _buildCloud({
    required double left,
    required double top,
    required double size,
    required Color color,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size * 0.5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size),
        ),
      ),
    );
  }

  Widget _circle(double size) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      );

  Widget _crater(double size) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF888888),
          shape: BoxShape.circle,
        ),
      );
}

// Estrella de 4 puntas con curvas cúbicas (fiel al SVG original)
class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final sx = size.width / 20.0;
    final sy = size.height / 20.0;

    final path = Path()
      ..moveTo(0 * sx, 10 * sy)
      ..cubicTo(10 * sx, 10 * sy, 10 * sx, 10 * sy, 0 * sx, 10 * sy)
      ..cubicTo(10 * sx, 10 * sy, 10 * sx, 10 * sy, 10 * sx, 20 * sy)
      ..cubicTo(10 * sx, 10 * sy, 10 * sx, 10 * sy, 20 * sx, 10 * sy)
      ..cubicTo(10 * sx, 10 * sy, 10 * sx, 10 * sy, 10 * sx, 0 * sy)
      ..cubicTo(10 * sx, 10 * sy, 10 * sx, 10 * sy, 0 * sx, 10 * sy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => false;
}
