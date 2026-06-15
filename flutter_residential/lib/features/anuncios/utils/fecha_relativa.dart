import '../../../core/utils/date_formatter.dart';

/// Devuelve una representación relativa y compacta de una fecha ISO.
/// Ejemplos: "hace 5 min", "hace 2h", "ayer", "12 may", "12 may 2024".
/// El instante se interpreta en la zona del conjunto (no la del teléfono).
String fechaRelativa(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  DateTime dt;
  try {
    dt = DateFormatter.instanteEnZona(iso);
  } catch (_) {
    return iso;
  }

  final now = DateFormatter.ahoraEnZona();
  final diff = now.difference(dt);

  if (diff.inSeconds < 60) return 'hace un momento';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours}h';

  final hoy = DateTime(now.year, now.month, now.day);
  final dia = DateTime(dt.year, dt.month, dt.day);
  final dDias = hoy.difference(dia).inDays;

  if (dDias == 1) return 'ayer';
  if (dDias < 7) return 'hace $dDias días';

  const meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  final mes = meses[dt.month - 1];
  if (dt.year == now.year) return '${dt.day} $mes';
  return '${dt.day} $mes ${dt.year}';
}
