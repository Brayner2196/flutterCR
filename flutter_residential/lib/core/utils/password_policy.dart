/// Política de contraseñas — lógica centralizada y reutilizable.
/// Mismas reglas que [PasswordPolicyValidator] en el backend.
class PasswordPolicy {
  PasswordPolicy._();

  static const _commonPasswords = {
    '12345678', '123456789', '1234567890', 'password', 'password1',
    'qwerty123', 'qwertyuiop', 'iloveyou', 'admin1234', 'welcome1',
    'monkey123', 'dragon123', 'master123', 'abc12345', 'letmein1',
    'sunshine', 'princess', 'football', 'shadow123', 'superman',
    'contraseña', 'colombia1', 'bogota123', 'medellin1', 'cali1234',
  };

  static bool hasMinLength(String p)       => p.length >= 8;
  static bool hasMaxLength(String p)       => p.length <= 20;
  static bool hasUppercase(String p)       => p.contains(RegExp(r'[A-Z]'));
  static bool hasSpecial(String p)         => p.contains(RegExp(r'[^A-Za-z0-9]'));
  static bool hasNoSpaces(String p)        => !p.contains(' ');
  static bool hasNoRepeated(String p)      => !RegExp(r'(.)\1{2,}').hasMatch(p);
  static bool isNotCommon(String p)        => !_commonPasswords.contains(p.toLowerCase());

  static bool hasThreeTypes(String p) {
    int count = 0;
    if (p.contains(RegExp(r'[a-z]'))) count++;
    if (p.contains(RegExp(r'[A-Z]'))) count++;
    if (p.contains(RegExp(r'[0-9]'))) count++;
    if (p.contains(RegExp(r'[^A-Za-z0-9]'))) count++;
    return count >= 3;
  }

  /// Devuelve lista de [PolicyRule] con estado actual para cada regla.
  static List<PolicyRule> evaluate(String password) => [
    PolicyRule(
      label: 'Entre 8 y 20 caracteres',
      passes: password.isNotEmpty && hasMinLength(password) && hasMaxLength(password),
    ),
    PolicyRule(
      label: 'Al menos una letra mayúscula',
      passes: password.isNotEmpty && hasUppercase(password),
    ),
    PolicyRule(
      label: 'Al menos un carácter especial',
      passes: password.isNotEmpty && hasSpecial(password),
    ),
    PolicyRule(
      label: 'Sin espacios en blanco',
      passes: password.isNotEmpty && hasNoSpaces(password),
    ),
    PolicyRule(
      label: 'Sin caracteres repetidos (ej. "aaa")',
      passes: password.isNotEmpty && hasNoRepeated(password),
    ),
    PolicyRule(
      label: 'No es una contraseña común',
      passes: password.isNotEmpty && isNotCommon(password),
    ),
    PolicyRule(
      label: 'Combina al menos 3 tipos de caracteres',
      passes: password.isNotEmpty && hasThreeTypes(password),
    ),
  ];

  /// true si pasa todas las reglas.
  static bool isValid(String password) => evaluate(password).every((r) => r.passes);

  /// Mensaje de error para el [TextFormField] validator.
  static String? validate(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa una contraseña';
    if (!isValid(value)) return 'La contraseña no cumple con la política de seguridad';
    return null;
  }
}

class PolicyRule {
  final String label;
  final bool passes;
  const PolicyRule({required this.label, required this.passes});
}
