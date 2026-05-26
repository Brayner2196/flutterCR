import 'package:intl/intl.dart';

/// Formatea fechas/horas respetando la timezone del tenant.
///
/// Uso típico:
/// ```dart
/// final auth = context.read<AuthProvider>();
/// DateFormatter.fecha(cobro.fechaLimitePago, auth.timezone)   // "15 ene 2026"
/// DateFormatter.fechaHora(cobro.creadoEn, auth.timezone)      // "15 ene 2026 14:30"
/// DateFormatter.esHoy(cobro.fechaLimitePago, auth.timezone)   // true/false
/// ```
class DateFormatter {
  DateFormatter._();

  // ── Parseo ────────────────────────────────────────────────────────

  /// Convierte un ISO-8601 String (con o sin 'Z') en DateTime local.
  static DateTime _parse(String iso) {
    return DateTime.parse(iso).toLocal();
  }

  // ── Formateo ──────────────────────────────────────────────────────

  /// Formato largo: "15 ene 2026"
  static String fecha(String? isoDate, [String? timezone]) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      final dt = _parse(isoDate);
      return DateFormat('d MMM y', 'es').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  /// Formato corto: "15/01/2026"
  static String fechaCorta(String? isoDate, [String? timezone]) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      final dt = _parse(isoDate);
      return DateFormat('dd/MM/y', 'es').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  /// Formato con hora: "15 ene 2026, 14:30"
  static String fechaHora(String? iso, [String? timezone]) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final dt = _parse(iso);
      return DateFormat('d MMM y, HH:mm', 'es').format(dt);
    } catch (_) {
      return iso;
    }
  }

  /// Solo hora: "14:30"
  static String hora(String? iso, [String? timezone]) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final dt = _parse(iso);
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }

  // ── Comparaciones ─────────────────────────────────────────────────

  /// True si [isoDate] corresponde al día de hoy en la timezone del tenant.
  static bool esHoy(String? isoDate, [String? timezone]) {
    if (isoDate == null) return false;
    try {
      final hoy = DateTime.now();
      final dt  = _parse(isoDate);
      return dt.year == hoy.year && dt.month == hoy.month && dt.day == hoy.day;
    } catch (_) {
      return false;
    }
  }

  /// True si [isoDate] es anterior al día de hoy (está vencido).
  static bool esPasado(String? isoDate, [String? timezone]) {
    if (isoDate == null) return false;
    try {
      final hoy = DateTime.now();
      final hoyNormalizado = DateTime(hoy.year, hoy.month, hoy.day);
      final dt = _parse(isoDate);
      final dtNormalizado = DateTime(dt.year, dt.month, dt.day);
      return dtNormalizado.isBefore(hoyNormalizado);
    } catch (_) {
      return false;
    }
  }
}
