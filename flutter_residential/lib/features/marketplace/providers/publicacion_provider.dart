import 'package:flutter/foundation.dart';
import '../models/publicacion_model.dart';
import '../services/publicacion_service.dart';

enum OrdenMarketplace { masReciente, precioMenor, precioMayor, masLejano }

class PublicacionProvider extends ChangeNotifier {
  List<PublicacionModel> _todas = [];
  bool _cargando = false;
  String? _error;

  // ─── Filtros locales ──────────────────────────────────────────
  String _busqueda = '';
  String? _categoria;

  /// Radio de proximidad: 0=Mi piso, 1=Pisos adyacentes, 2=Mi torre, 3=Todo el conjunto
  int _radioProximidad = 3;

  double? _precioMin;
  double? _precioMax;
  String? _marcaFiltro;
  bool _soloConDomicilio = false;
  OrdenMarketplace _orden = OrdenMarketplace.masReciente;

  // ─── Getters ──────────────────────────────────────────────────
  bool get cargando => _cargando;
  String? get error => _error;
  String get busqueda => _busqueda;
  String? get categoria => _categoria;
  int get radioProximidad => _radioProximidad;
  double? get precioMin => _precioMin;
  double? get precioMax => _precioMax;
  String? get marcaFiltro => _marcaFiltro;
  bool get soloConDomicilio => _soloConDomicilio;
  OrdenMarketplace get orden => _orden;

  bool get hayFiltrosActivos =>
      _categoria != null ||
      _radioProximidad < 3 ||
      _precioMin != null ||
      _precioMax != null ||
      _marcaFiltro != null ||
      _soloConDomicilio ||
      _orden != OrdenMarketplace.masReciente;

  /// Marcas únicas disponibles para filtrar
  List<String> get marcasDisponibles {
    final marcas = _todas
        .where((p) => p.marca != null && p.marca!.isNotEmpty)
        .map((p) => p.marca!)
        .toSet()
        .toList();
    marcas.sort();
    return marcas;
  }

  /// Publicaciones filtradas y ordenadas (resultado final)
  List<PublicacionModel> get publicaciones {
    var lista = _todas.where((p) {
      // Búsqueda por texto
      if (_busqueda.isNotEmpty) {
        final q = _busqueda.toLowerCase();
        final coincide = p.titulo.toLowerCase().contains(q) ||
            (p.descripcion?.toLowerCase().contains(q) ?? false) ||
            (p.marca?.toLowerCase().contains(q) ?? false);
        if (!coincide) return false;
      }

      // Categoría
      if (_categoria != null && p.categoria != _categoria) return false;

      // Domicilio
      if (_soloConDomicilio && !p.aceptaDomicilio) return false;

      // Marca
      if (_marcaFiltro != null && p.marca != _marcaFiltro) return false;

      // Precio
      if (_precioMin != null && p.precio < _precioMin!) return false;
      if (_precioMax != null && p.precio > _precioMax!) return false;

      // Proximidad: distanciaProximidad usa escala 0-4+
      // 0=Radio 0 (mi piso exacto), 1=pisos adyacentes(<=2), 2=torre(<=4), 3=todo
      if (_radioProximidad < 3 && p.distanciaProximidad != null) {
        final maxDist = _radioProximidad == 0
            ? 0
            : _radioProximidad == 1
                ? 2
                : 4;
        if (p.distanciaProximidad! > maxDist) return false;
      }

      return true;
    }).toList();

    // Ordenar
    switch (_orden) {
      case OrdenMarketplace.precioMenor:
        lista.sort((a, b) => a.precio.compareTo(b.precio));
      case OrdenMarketplace.precioMayor:
        lista.sort((a, b) => b.precio.compareTo(a.precio));
      case OrdenMarketplace.masLejano:
        lista.sort((a, b) =>
            (b.distanciaProximidad ?? 999).compareTo(a.distanciaProximidad ?? 999));
      case OrdenMarketplace.masReciente:
        // El backend ya devuelve por fecha desc; preservar orden original
        break;
    }

    return lista;
  }

  // ─── Carga ────────────────────────────────────────────────────
  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _todas = await PublicacionService.getMarketplace();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // ─── Setters de filtros ───────────────────────────────────────
  void setBusqueda(String v) {
    _busqueda = v;
    notifyListeners();
  }

  void setCategoria(String? v) {
    _categoria = v;
    notifyListeners();
  }

  void setRadioProximidad(int v) {
    _radioProximidad = v;
    notifyListeners();
  }

  void setPrecioMin(double? v) {
    _precioMin = v;
    notifyListeners();
  }

  void setPrecioMax(double? v) {
    _precioMax = v;
    notifyListeners();
  }

  void setMarcaFiltro(String? v) {
    _marcaFiltro = v;
    notifyListeners();
  }

  void setSoloConDomicilio(bool v) {
    _soloConDomicilio = v;
    notifyListeners();
  }

  void setOrden(OrdenMarketplace v) {
    _orden = v;
    notifyListeners();
  }

  void limpiarFiltros() {
    _categoria = null;
    _radioProximidad = 3;
    _precioMin = null;
    _precioMax = null;
    _marcaFiltro = null;
    _soloConDomicilio = false;
    _orden = OrdenMarketplace.masReciente;
    notifyListeners();
  }
}
