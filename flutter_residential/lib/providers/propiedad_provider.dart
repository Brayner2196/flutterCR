import 'package:flutter/material.dart';
import '../models/tipo_propiedad_nodo.dart';
import '../models/usuario_propiedad_response.dart';
import '../services/propiedad_service.dart';

class PropiedadProvider extends ChangeNotifier {
  List<TipoPropiedadNodo> _tiposArbol = [];
  List<UsuarioPropiedadResponse> _misPropiedades = [];
  UsuarioPropiedadResponse? _propiedadActual;
  bool _cargando = false;
  String? _error;

  List<TipoPropiedadNodo> get tiposArbol => _tiposArbol;
  List<UsuarioPropiedadResponse> get misPropiedades => _misPropiedades;
  UsuarioPropiedadResponse? get propiedadActual => _propiedadActual;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargarTiposAdmin() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _tiposArbol = await PropiedadService.getTiposArbolAdmin();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _tiposArbol = [];
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<List<TipoPropiedadNodo>> cargarTipos(String codigo) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _tiposArbol = await PropiedadService.getTiposArbol(codigo);
      return _tiposArbol;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _tiposArbol = [];
      return [];
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarMisPropiedades() async {
    try {
      _misPropiedades = await PropiedadService.getMisPropiedades();
      _propiedadActual = _misPropiedades.firstWhere(
        (p) => p.esPrincipal,
        orElse: () => _misPropiedades.isNotEmpty ? _misPropiedades.first : _propiedadActual!,
      );
    } catch (_) {
      // silently fail — no propiedades asignadas aún
    }
    notifyListeners();
  }

  void seleccionarPropiedad(UsuarioPropiedadResponse propiedad) {
    _propiedadActual = propiedad;
    notifyListeners();
  }

  void limpiar() {
    _tiposArbol = [];
    _misPropiedades = [];
    _propiedadActual = null;
    notifyListeners();
  }
}
