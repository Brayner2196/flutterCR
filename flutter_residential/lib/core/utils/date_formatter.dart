import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

/// Formatea fechas/horas convirtiendo a la zona horaria del tenant activo.
///
/// Regla de oro:
/// - Los *instantes* (cuándo pasó algo: `creadoEn`, `fechaVerificacion`, etc.)
///   se guardan en UTC en el backend y aquí se convierten a la zona del tenant.
/// - Las *fechas civiles* (día de calendario: `fechaLimitePago`, `fechaPago`,
///   vencimientos, periodos) NO se convierten — un "15 jun" debe seguir siendo
///   "15 jun" en cualquier zona.
///
/// La zona del tenant se setea una vez tras el login mediante [zonaTenant]
/// (ver AuthProvider). Cada método acepta un `timezone` opcional que la
/// sobreescribe puntualmente.
///
/// Uso típico:
/// ```dart
/// DateFormatter.fecha(cobro.fechaLimitePago)   // civil  → "15 ene 2026"
/// DateFormatter.fechaHora(abono.creadoEn)      // UTC→tenant → "15 ene 2026, 14:30"
/// DateFormatter.fechaHora12(mov.creadoEn)      // UTC→tenant → "15 ene 2026 2:30 pm"
/// ```
class DateFormatter {
  DateFormatter._();

  /// Zona IANA del tenant activo (ej. "America/Bogota", "America/Lima").
  /// La sincroniza AuthProvider al iniciar/restaurar/cerrar sesión.
  static String zonaTenant = 'America/Bogota';

  static const String _zonaFallback = 'America/Bogota';

  // ── Inicialización ────────────────────────────────────────────────

  static bool _tzReady = false;

  /// Carga la base de datos de zonas horarias. Idempotente.
  /// Llamar una vez al arrancar la app (main); también se autoejecuta perezosamente.
  static void init() {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    _tzReady = true;
  }

  // ── Parseo ────────────────────────────────────────────────────────

  /// Ubicación IANA del tenant (o la indicada), con fallback seguro.
  static tz.Location _location([String? timezone]) {
    init();
    try {
      return tz.getLocation(timezone ?? zonaTenant);
    } catch (_) {
      return tz.getLocation(_zonaFallback);
    }
  }

  /// Fecha civil: se interpreta tal cual, sin conversión de zona.
  static DateTime _parseCivil(String iso) => DateTime.parse(iso);

  /// Instante del backend → convertido a la zona del tenant.
  ///
  /// El backend genera los timestamps con `@CreationTimestamp` en UTC y los
  /// envía como "yyyy-MM-dd HH:mm:ss" (o ISO con 'Z'/offset). Aquí se marca
  /// como UTC cuando no trae zona y se convierte a la zona destino.
  /// Si la cadena no tiene hora, se trata como fecha civil (no se desfasa el día).
  static tz.TZDateTime _parseInstante(String iso, [String? timezone]) {
    final loc = _location(timezone);
    var s = iso.trim().replaceFirst(' ', 'T');
    final tieneHora = s.contains(':');
    if (!tieneHora) {
      final d = DateTime.parse(s);
      return tz.TZDateTime(loc, d.year, d.month, d.day);
    }
    final tieneZona =
        s.endsWith('Z') || RegExp(r'[+-]\d\d:?\d\d$').hasMatch(s);
    if (!tieneZona) s = '${s}Z'; // backend manda UTC sin marcador
    return tz.TZDateTime.from(DateTime.parse(s), loc);
  }

  // ── Acceso a instante en zona del tenant ──────────────────────────

  /// Instante del backend convertido a la zona del tenant (o la indicada).
  /// Para logicas que necesitan el DateTime ya en zona (relativas, comparaciones),
  /// NO la zona del telefono. Reemplaza el uso de `DateTime.parse(iso).toLocal()`.
  static DateTime instanteEnZona(String iso, [String? timezone]) =>
      _parseInstante(iso, timezone);

  /// "Ahora" en la zona del tenant. Para comparar dias (hoy/ayer) y tiempos
  /// relativos de forma consistente con la zona del conjunto.
  static DateTime ahoraEnZona([String? timezone]) {
    init();
    return tz.TZDateTime.now(_location(timezone));
  }

  // ── Formateo ──────────────────────────────────────────────────────

  /// Formato largo (fecha civil): "15 ene 2026"
  static String fecha(String? isoDate, [String? timezone]) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      return DateFormat('d MMM y', 'es').format(_parseCivil(isoDate));
    } catch (_) {
      return isoDate;
    }
  }

  /// Formato corto (fecha civil): "15/01/2026"
  static String fechaCorta(String? isoDate, [String? timezone]) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      return DateFormat('dd/MM/y', 'es').format(_parseCivil(isoDate));
    } catch (_) {
      return isoDate;
    }
  }

  /// Instante con hora (zona del tenant): "15 ene 2026, 14:30"
  static String fechaHora(String? iso, [String? timezone]) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      return DateFormat('d MMM y, HH:mm', 'es').format(_parseInstante(iso, timezone));
    } catch (_) {
      return iso;
    }
  }

  /// Abreviaturas de mes en 3 letras (sin punto), independiente del locale.
  static const List<String> _mesesAbrev = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  /// Instante en formato exacto (zona del tenant): "13 jun 2026 7:23 am"
  /// → día mes(3 letras) año hora:minutos am/pm (12h)
  static String fechaHora12(String? iso, [String? timezone]) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final dt = _parseInstante(iso, timezone);
      final mes = _mesesAbrev[dt.month - 1];
      var hora12 = dt.hour % 12;
      if (hora12 == 0) hora12 = 12;
      final min = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour < 12 ? 'am' : 'pm';
      return '${dt.day} $mes ${dt.year} $hora12:$min $ampm';
    } catch (_) {
      return iso;
    }
  }

  /// Convierte una hora "HH:mm" (24h) a "h:mm am/pm" (12h).
  /// Ej: "14:00" → "2:00 pm", "08:30" → "8:30 am", "00:00" → "12:00 am".
  /// Pensado para franjas horarias que ya vienen como string del backend
  /// (no son instantes, no se aplica zona horaria).
  static String hora12Texto(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return '-';
    try {
      final p = hhmm.split(':');
      final h = int.parse(p[0]);
      final min = (p.length > 1 ? p[1] : '00').padLeft(2, '0');
      var h12 = h % 12;
      if (h12 == 0) h12 = 12;
      final ampm = h < 12 ? 'am' : 'pm';
      return '$h12:$min $ampm';
    } catch (_) {
      return hhmm;
    }
  }

  /// Solo hora (zona del tenant): "14:30"
  static String hora(String? iso, [String? timezone]) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      return DateFormat('HH:mm').format(_parseInstante(iso, timezone));
    } catch (_) {
      return iso;
    }
  }

  // ── Comparaciones ─────────────────────────────────────────────────

  /// True si [isoDate] (fecha civil) corresponde a hoy en la zona del tenant.
  static bool esHoy(String? isoDate, [String? timezone]) {
    if (isoDate == null) return false;
    try {
      final hoy = tz.TZDateTime.now(_location(timezone));
      final dt = _parseCivil(isoDate);
      return dt.year == hoy.year && dt.month == hoy.month && dt.day == hoy.day;
    } catch (_) {
      return false;
    }
  }

  /// True si [isoDate] (fecha civil) es anterior a hoy en la zona del tenant.
  static bool esPasado(String? isoDate, [String? timezone]) {
    if (isoDate == null) return false;
    try {
      final hoy = tz.TZDateTime.now(_location(timezone));
      final hoyNorm = DateTime(hoy.year, hoy.month, hoy.day);
      final dt = _parseCivil(isoDate);
      final dtNorm = DateTime(dt.year, dt.month, dt.day);
      return dtNorm.isBefore(hoyNorm);
    } catch (_) {
      return false;
    }
  }
}
