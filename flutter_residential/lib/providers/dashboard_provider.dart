import 'package:flutter/material.dart';
import '../models/dashboard/dashboard_resumen.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardResumen? _resumen;
  bool _loading = false;
  String? _error;

  DashboardResumen? get resumen => _resumen;
  bool get loading => _loading;
  String? get error => _error;
  bool get tieneDatos => _resumen != null;

  Future<void> cargar() async {
    _setLoading(true);
    try {
      _resumen = await DashboardService.getResumen();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refrescar() => cargar();

  void limpiar() {
    _resumen = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    if (v) _error = null;
    notifyListeners();
  }
}
