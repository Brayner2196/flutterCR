import 'cartera_vencida.dart';
import 'estado_unidades.dart';
import 'pagos_por_verificar.dart';
import 'pendientes_hoy.dart';
import 'recaudo_mes.dart';
import 'tendencia.dart';

class DashboardResumen {
  final PendientesHoy pendientesHoy;
  final RecaudoMes recaudoMes;
  final CarteraVencida carteraVencida;
  final PagosPorVerificar pagosPorVerificar;
  final Tendencia tendencia;
  final EstadoUnidades estadoUnidades;

  const DashboardResumen({
    required this.pendientesHoy,
    required this.recaudoMes,
    required this.carteraVencida,
    required this.pagosPorVerificar,
    required this.tendencia,
    required this.estadoUnidades,
  });

  factory DashboardResumen.fromJson(Map<String, dynamic> json) => DashboardResumen(
        pendientesHoy: PendientesHoy.fromJson(json['pendientesHoy']),
        recaudoMes: RecaudoMes.fromJson(json['recaudoMes']),
        carteraVencida: CarteraVencida.fromJson(json['carteraVencida']),
        pagosPorVerificar: PagosPorVerificar.fromJson(json['pagosPorVerificar']),
        tendencia: Tendencia.fromJson(json['tendencia']),
        estadoUnidades: EstadoUnidades.fromJson(json['estadoUnidades']),
      );
}
