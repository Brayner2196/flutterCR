import 'package:flutter/material.dart';
import '../models/abono_model.dart';
import '../models/saldo_favor_model.dart';
import '../services/abono_service.dart';

class AbonoProvider extends ChangeNotifier {
  List<AbonoModel> _abonos = [];
  SaldoFavorModel? _saldoFavor;
  bool _loading = false;
  String? _error;

  List<AbonoModel> get abonos => _abonos;
  SaldoFavorModel? get saldoFavor => _saldoFavor;
  bool get loading => _loading;
  String? get error => _error;

  List<AbonoModel> get pendientes =>
      _abonos.where((a) => a.esPendiente).toList();
  List<AbonoModel> get verificados =>
      _abonos.where((a) => a.esVerificado).toList();
  List<AbonoModel> get rechazados =>
      _abonos.where((a) => a.esRechazado).toList();

  Future<void> cargarMisAbonos() async {
    _setLoading(true);
    try {
      _abonos = await AbonoService.getMisAbonos();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cargarSaldoFavor(int propiedadId) async {
    try {
      _saldoFavor = await AbonoService.getSaldoFavor(propiedadId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> cargarTodosAbonosAdmin() async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        AbonoService.listarAbonosAdmin(estado: 'PENDIENTE_VERIFICACION'),
        AbonoService.listarAbonosAdmin(estado: 'VERIFICADO'),
        AbonoService.listarAbonosAdmin(estado: 'RECHAZADO'),
      ]);
      _abonos = [...results[0], ...results[1], ...results[2]];
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<AbonoModel> registrar(Map<String, dynamic> data) async {
    final nuevo = await AbonoService.registrarAbono(data);
    _abonos.add(nuevo);
    notifyListeners();
    return nuevo;
  }

  Future<void> verificar(int id, {String? notas}) async {
    final actualizado = await AbonoService.verificarAbono(id, notas: notas);
    _reemplazar(actualizado);
  }

  Future<void> rechazar(int id, String motivo) async {
    final actualizado = await AbonoService.rechazarAbono(id, motivo);
    _reemplazar(actualizado);
  }

  void _reemplazar(AbonoModel actualizado) {
    final idx = _abonos.indexWhere((a) => a.id == actualizado.id);
    if (idx != -1) {
      _abonos[idx] = actualizado;
    } else {
      _abonos.add(actualizado);
    }
    notifyListeners();
  }

  void limpiar() {
    _abonos = [];
    _saldoFavor = null;
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
