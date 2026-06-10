import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'seleccion_tenant_screen.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _cargando = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      final auth = context.read<AuthProvider>();
      final esDirecto = await auth.login(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );

      if (!mounted) return;

      if (!esDirecto && auth.multiTenantPendiente != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SeleccionTenantScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final safeTop = mq.padding.top;
    final safeBottom = mq.padding.bottom;
    final keyboardH = mq.viewInsets.bottom;

    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final imgPath = isDark
        ? 'assets/images/My_CR_dark.webp'
        : 'assets/images/My_CR_light.webp';

    final scrimGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.24, 0.52, 1.0],
      colors: isDark
          ? [
              const Color.fromRGBO(8, 18, 34, 0),
              const Color.fromRGBO(8, 16, 30, 0.549),
              AppColors.bgDark.withValues(alpha: 0.97),
            ]
          : [
              Colors.transparent,
              const Color.fromRGBO(247, 250, 253, 0.502),
              AppColors.bgLight.withValues(alpha: 0.97),
            ],
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // ── 1. Fondo sólido del tema ──────────────────────────
            Positioned.fill(child: ColoredBox(color: bgColor)),

            // ── 2. Imagen + scrim (cubre solo el 80% superior) ────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenH * 0.80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imgPath,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.36),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(gradient: scrimGradient),
                  ),
                ],
              ),
            ),

            // ── 3. Header: logo + título sobre la imagen ───────────
            Positioned(
              top: safeTop + 40,
              left: 0,
              right: 0,
              child: _buildHeader(isDark),
            ),

            // ── 4. Tarjeta glass anclada abajo, sube con el teclado ─
            Positioned(
              left: 0,
              right: 0,
              bottom: keyboardH,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + safeBottom),
                child: _buildGlassCard(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header: logo + nombre + subtítulo ──────────────────────────────
  Widget _buildHeader(bool isDark) {
    final textColor =
        isDark ? const Color(0xFFF4F1EA) : const Color(0xFF0E2238);
    final subColor = isDark
        ? const Color(0xB3F4F1EA) // 70%
        : const Color(0x9E0E2238); // 62%

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo en contenedor blanco redondeado
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x38081428),
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/icons/logocr.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'My Conjunto Residencial',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
            shadows: isDark
                ? const [
                    Shadow(
                        color: Color(0x73000000),
                        blurRadius: 16,
                        offset: Offset(0, 2))
                  ]
                : const [
                    Shadow(
                        color: Color(0x8CFFFFFF),
                        blurRadius: 12,
                        offset: Offset(0, 1))
                  ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        Text(
          'Tu comunidad en un solo lugar',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: subColor,
            shadows: isDark
                ? const [Shadow(color: Color(0x66000000), blurRadius: 10)]
                : null,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Tarjeta glass con formulario ───────────────────────────────────
  Widget _buildGlassCard(bool isDark) {
    final glassBg =
        isDark ? const Color(0x8012110F) : const Color(0xD9FFFFFF);
    final glassBorder =
        isDark ? const Color(0x24FFFFFF) : const Color(0x2613314C);
    final titleColor =
        isDark ? const Color(0xFFF4F1EA) : const Color(0xFF13314C);
    final subColor =
        isDark ? const Color(0xB3F4F1EA) : const Color(0x9E13314C);
    final forgotColor =
        isDark ? const Color(0xC7F4F1EA) : const Color(0xFF16324C);
    final registerColor =
        isDark ? const Color(0xB8F4F1EA) : const Color(0xB213314C);

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: glassBg,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: glassBorder),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0x4D081428)
                    : const Color(0x1A13314C),
                blurRadius: isDark ? 50 : 32,
                offset: const Offset(0, 12),
              ),
              if (!isDark)
                const BoxShadow(
                  color: Color(0x0D13314C),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Ingresa tus credenciales para acceder',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: subColor,
                  ),
                ),
                const SizedBox(height: 18),

                // Campo email
                _glassField(
                  controller: _emailCtrl,
                  hint: 'Correo electrónico',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  isDark: isDark,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu correo';
                    if (!v.contains('@')) return 'Correo no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Campo contraseña
                _glassField(
                  controller: _passwordCtrl,
                  hint: 'Contraseña',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  isDark: isDark,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: isDark
                          ? const Color(0x99F4F1EA)
                          : const Color(0x8016324C),
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),

                // Olvidé contraseña
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: forgotColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Botón ingresar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _cargando ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      shadowColor: AppColors.blue.withValues(alpha: 0.33),
                      elevation: 10,
                    ),
                    child: _cargando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Ingresar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 19,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Registrarse
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const RegistroScreen()),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: registerColor,
                        ),
                        children: const [
                          TextSpan(text: '¿No tienes cuenta? '),
                          TextSpan(
                            text: 'Regístrate aquí',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Campo de texto con estilo glass ────────────────────────────────
  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    final inputBg =
        isDark ? const Color(0x9E282623) : const Color(0xC7FFFFFF);
    final inputBorder =
        isDark ? const Color(0x29FFFFFF) : const Color(0xE5FFFFFF);
    final textColor =
        isDark ? const Color(0xFFF4F1EA) : const Color(0xFF16324C);
    final iconColor =
        isDark ? const Color(0xB3F4F1EA) : const Color(0x9916324C);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.1,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: iconColor,
        ),
        prefixIcon: Icon(icon, size: 19, color: iconColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: inputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
              color: AppColors.blue.withValues(alpha: 0.8), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
    );
  }
}
