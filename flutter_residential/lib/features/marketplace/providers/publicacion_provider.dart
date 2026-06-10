import '../../../core/providers/base_provider.dart';
import '../models/publicacion_model.dart';
import '../services/publicacion_service.dart';

enum OrdenMarketplace { masReciente, precioMenor, precioMayor, masLejano }

class PublicacionProvider extends BaseProvider {
  List<PublicacionModel> _todas = [];

  String _busqueda = '';
  String? _categoria;
  int _radioProximidad = 3;
  double? _precioMin;
  double? _precioMax;
  String? _marcaFiltro;
  bool _soloConDomicilio = false;
  OrdenMarketplace _orden = OrdenMarketplace.masReciente;

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

  List<String> get marcasDisponibles {
    final marcas = _todas
        .where((p) => p.marca != null && p.marca!.isNotEmpty)
        .map((p) => p.marca!)
        .toSet()
        .toList();
    marcas.sort();
    return marcas;
  }

  List<PublicacionModel> get publicaciones {
    var lista = _todas.where((p) {
      if (_busqueda.isNotEmpty) {
        final q = _busqueda.toLowerCase();
        final coincide = p.titulo.toLowerCase().contains(q) ||
            (p.descripcion?.toLowerCase().contains(q) ?? false) ||
            (p.marca?.toLowerCase().contains(q) ?? false);
        if (!coincide) return false;
      }

      if (_categoria != null && p.categoria != _categoria) return false;
      if (_soloConDomicilio && !p.aceptaDomicilio) return false;
      if (_marcaFiltro != null && p.marca != _marcaFiltro) return false;
      if (_precioMin != null && p.precio < _precioMin!) return false;
      if (_precioMax != null && p.precio > _precioMax!) return false;

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

    switch (_orden) {
      case OrdenMarketplace.precioMenor:
        lista.sort((a, b) => a.precio.compareTo(b.precio));
      case OrdenMarketplace.precioMayor:
        lista.sort((a, b) => b.precio.compareTo(a.precio));
      case OrdenMarketplace.masLejano:
        lista.sort((a, b) =>
            (b.distanciaProximidad ?? 999).compareTo(a.distanciaProximidad ?? 999));
      case OrdenMarketplace.masReciente:
        break;
    }

    return lista;
  }

  Future<void> cargar() async {
    final resultado = await ejecutar(() => PublicacionService.getMarketplace());
    if (resultado != null) {
      _todas = resultado;
    }
  }

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
