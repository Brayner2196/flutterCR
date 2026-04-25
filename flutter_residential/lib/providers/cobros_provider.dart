import 'package:flutter/material.dart';
import '../models/cobro_model.dart';
import '../models/estado_cuenta_model.dart';
import '../models/periodo_cobro_model.dart';
import '../services/cobro_service.dart';

class CobrosProvider extends ChangeNotifier {
  EstadoCuentaModel? _estadoCuenta;
  List<CobroModel> _cobros = [];
  List<PeriodoCobroModel> _periodos = [];
  bool _loading = false;
  String? _error;

  EstadoCuentaModel? get estadoCuenta => _estadoCuenta;
  List<CobroModel> get cobros => _cobros;
  List<PeriodoCobroModel> get periodos => _periodos;
  bool get loading => _loading;
  String? get error => _error;

  List<CobroModel> get pendientes => _cobros.where((c) => c.esPendiente).toList();
  List<CobroModel> get vencidos => _cobros.where((c) => c.esVencido).toList();
  List<CobroModel> get pagados => _cobros.where((c) => c.esPagado).toList();

  Future<void> cargarEstadoCuenta() async {
    _setLoading(true);
    try {
      _estadoCuenta = await CobroService.getEstadoCuenta();
      _cobros = _estadoCuenta!.cobrosActivos;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cargarHistorial() async {
    _setLoading(true);
    try {
      _cobros = await CobroService.getHistorial();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cargarPeriodos() async {
    _setLoading(true);
    try {
      _periodos = await CobroService.listarPeriodos();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cargarCobrosAdmin({int? periodoId, String? estado}) async {
    _setLoading(true);
    try {
      _cobros = await CobroService.listarCobrosAdmin(
          periodoId: periodoId, estado: estado);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<PeriodoCobroModel> abrirPeriodo(Map<String, dynamic> data) async {
    final nuevo = await CobroService.abrirPeriodo(data);
    _periodos.insert(0, nuevo);
    notifyListeners();
    return nuevo;
  }

  Future<void> cerrarPeriodo(int id) async {
    final actualizado = await CobroService.cerrarPeriodo(id);
    final idx = _periodos.indexWhere((p) => p.id == actualizado.id);
    if (idx != -1) _periodos[idx] = actualizado;
    notifyListeners();
  }

  Future<List<CobroModel>> generarCobros(int anio, int mes) async {
    final nuevos = await CobroService.generarCobros(anio, mes);
    _cobros = nuevos;
    notifyListeners();
    return nuevos;
  }

  void limpiar() {
    _estadoCuenta = null;
    _cobros = [];
    _periodos = [];
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
