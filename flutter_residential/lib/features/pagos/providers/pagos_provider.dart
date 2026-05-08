import 'package:flutter/material.dart';
import '../models/pago_model.dart';
import '../services/pago_service.dart';

class PagosProvider extends ChangeNotifier {
  List<PagoModel> _pagos = [];
  bool _loading = false;
  String? _error;

  List<PagoModel> get pagos => _pagos;
  bool get loading => _loading;
  String? get error => _error;

  List<PagoModel> get pendientes =>
      _pagos.where((p) => p.esPendiente).toList();
  List<PagoModel> get verificados =>
      _pagos.where((p) => p.esVerificado).toList();
  List<PagoModel> get rechazados =>
      _pagos.where((p) => p.esRechazado).toList();

  Future<void> cargarMisPagos() async {
    _setLoading(true);
    try {
      _pagos = await PagoService.getMisPagos();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cargarPagosAdmin(
      {String estado = 'PENDIENTE_VERIFICACION'}) async {
    _setLoading(true);
    try {
      _pagos = await PagoService.listarPagosAdmin(estado: estado);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  /// Carga los tres estados a la vez para que los tabs muestren datos
  Future<void> cargarTodosPagosAdmin() async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        PagoService.listarPagosAdmin(estado: 'PENDIENTE_VERIFICACION'),
        PagoService.listarPagosAdmin(estado: 'VERIFICADO'),
        PagoService.listarPagosAdmin(estado: 'RECHAZADO'),
      ]);
      _pagos = [...results[0], ...results[1], ...results[2]];
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<PagoModel> registrar(Map<String, dynamic> data) async {
    final nuevo = await PagoService.registrarPago(data);
    _pagos.add(nuevo);
    notifyListeners();
    return nuevo;
  }

  Future<void> verificar(int id, {String? notas}) async {
    final actualizado = await PagoService.verificarPago(id, notas: notas);
    _reemplazar(actualizado);
  }

  Future<void> rechazar(int id, String motivo) async {
    final actualizado = await PagoService.rechazarPago(id, motivo);
    _reemplazar(actualizado);
  }

  void _reemplazar(PagoModel actualizado) {
    final idx = _pagos.indexWhere((p) => p.id == actualizado.id);
    if (idx != -1) {
      _pagos[idx] = actualizado;
    } else {
      _pagos.add(actualizado);
    }
    notifyListeners();
  }

  void limpiar() {
    _pagos = [];
    _error = null;
    _loading = false;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    _error = v ? null : _error;
    notifyListeners();
  }
}
