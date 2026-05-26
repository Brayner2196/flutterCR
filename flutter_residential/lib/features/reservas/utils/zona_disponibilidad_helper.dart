import 'package:flutter/material.dart';
import '../models/reserva_model.dart';

/// Lógica reutilizable para calcular fechas y franjas válidas de una ZonaComunModel.
class ZonaDisponibilidadHelper {
  // Día en español → weekday de Dart (lunes=1 … domingo=7)
  static const Map<String, int> _diaAWd = {
    'LUNES': 1, 'MARTES': 2, 'MIERCOLES': 3, 'JUEVES': 4,
    'VIERNES': 5, 'SABADO': 6, 'DOMINGO': 7,
  };
  static const Map<int, String> _wdADia = {
    1: 'LUNES', 2: 'MARTES', 3: 'MIERCOLES', 4: 'JUEVES',
    5: 'VIERNES', 6: 'SABADO', 7: 'DOMINGO',
  };

  /// Conjunto de weekdays (1-7) en los que la zona está disponible.
  static Set<int> weekdaysDisponibles(ZonaComunModel zona) {
    final Set<int> dias = {};

    if (zona.horarioGrupos.isNotEmpty) {
      for (final g in zona.horarioGrupos) {
        for (final d in g.listaDias) {
          final wd = _diaAWd[d.trim().toUpperCase()];
          if (wd != null) dias.add(wd);
        }
      }
      if (dias.isNotEmpty) return dias;
    }

    // Fallback: campo legacy diasDisponibles
    if (zona.diasDisponibles != null && zona.diasDisponibles!.isNotEmpty) {
      for (final d in zona.listaDias) {
        final wd = _diaAWd[d.trim().toUpperCase()];
        if (wd != null) dias.add(wd);
      }
      if (dias.isNotEmpty) return dias;
    }

    // Sin restricción → todos los días
    return {1, 2, 3, 4, 5, 6, 7};
  }

  /// Lista de fechas próximas válidas para reservar en esta zona.
  static List<DateTime> proximasFechas(ZonaComunModel zona, {int maxDias = 90}) {
    final validos = weekdaysDisponibles(zona);
    final hoy = DateTime.now();
    final minDias = zona.anticipacionMinDias ?? 1;
    final maxLimite = zona.anticipacionMaxDias ?? maxDias;

    final desde = DateTime(hoy.year, hoy.month, hoy.day)
        .add(Duration(days: minDias.clamp(1, 365)));
    final hasta = DateTime(hoy.year, hoy.month, hoy.day)
        .add(Duration(days: maxLimite.clamp(1, 365)));

    final List<DateTime> fechas = [];
    DateTime cur = desde;
    while (!cur.isAfter(hasta)) {
      if (validos.contains(cur.weekday)) fechas.add(cur);
      cur = cur.add(const Duration(days: 1));
    }
    return fechas;
  }

  /// Grupo horario que aplica para la fecha dada (según sus días CSV).
  static HorarioGrupoModel? grupoParaFecha(ZonaComunModel zona, DateTime fecha) {
    final nombreDia = _wdADia[fecha.weekday];
    if (nombreDia == null) return null;
    for (final g in zona.horarioGrupos) {
      if (g.listaDias.any((d) => d.trim().toUpperCase() == nombreDia)) {
        return g;
      }
    }
    return null;
  }

  /// Franjas horarias disponibles para la fecha dada.
  static List<FranjaHorariaModel> franjasParaFecha(ZonaComunModel zona, DateTime fecha) {
    final grupo = grupoParaFecha(zona, fecha);
    if (grupo != null) return grupo.franjas;

    // Fallback legacy: una sola franja construida desde horaApertura/horaCierre
    if (zona.horaApertura != null && zona.horaCierre != null) {
      return [
        FranjaHorariaModel(
          horaInicio: zona.horaApertura!,
          horaFin: zona.horaCierre!,
        ),
      ];
    }
    return [];
  }

  /// Nombre corto del día en español.
  static String nombreDiaCorto(DateTime d) {
    const nombres = {1: 'Lun', 2: 'Mar', 3: 'Mié', 4: 'Jue', 5: 'Vie', 6: 'Sáb', 7: 'Dom'};
    return nombres[d.weekday] ?? '';
  }

  /// Nombre del mes abreviado.
  static String nombreMesCorto(DateTime d) {
    const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                   'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return meses[d.month - 1];
  }

  /// Nombre completo del mes.
  static String nombreMes(DateTime d) {
    const meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                   'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return meses[d.month - 1];
  }

  /// Icono por categoría.
  static IconData iconoCategoria(String? cat) {
    switch (cat) {
      case 'SALON':    return Icons.celebration_outlined;
      case 'PISCINA':  return Icons.pool_outlined;
      case 'GIMNASIO': return Icons.fitness_center_outlined;
      case 'BBQ':      return Icons.outdoor_grill_outlined;
      case 'CANCHA':   return Icons.sports_soccer_outlined;
      default:         return Icons.place_outlined;
    }
  }

  /// Color por categoría.
  static Color colorCategoria(String? cat) {
    switch (cat) {
      case 'SALON':    return const Color(0xFF6E2891); // purple
      case 'PISCINA':  return const Color(0xFF00698A); // blue
      case 'GIMNASIO': return const Color(0xFF8B4513); // brown
      case 'BBQ':      return const Color(0xFFB45000); // orange
      case 'CANCHA':   return const Color(0xFF006948); // green
      default:         return const Color(0xFF515F74);
    }
  }

  /// Texto de costo formateado.
  static String textoCosto(ZonaComunModel zona) {
    if (!zona.tieneCosto) return 'Gratis';
    final monto = zona.tarifaMonto;
    if (monto == null) return 'Con costo';
    final fmt = monto.toStringAsFixed(0);
    switch (zona.modoTarifa) {
      case 'POR_HORA':   return '₡$fmt / hora';
      case 'POR_PERSONA': return '₡$fmt / persona';
      default:            return '₡$fmt fijo';
    }
  }

  /// Formato "yyyy-MM-dd".
  static String formatFecha(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
