import 'package:flutter/material.dart';
import '../exceptions/api_exception.dart';

/// Clase base para todos los providers.
/// Centraliza: loading, error handling, notificación.
///
/// Uso:
/// ```dart
/// class MiProvider extends BaseProvider {
///   List<Modelo> _items = [];
///
///   Future<void> cargar() async {
///     _items = await ejecutar(() => MiService.obtenerItems());
///   }
/// }
/// ```
abstract class BaseProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Getters públicos (nunca setters)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  bool get loading => _loading;
  String? get error => _error;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Métodos públicos
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Establece el estado de carga y notifica listeners
  void setLoading(bool value) {
    _loading = value;
    if (value) _error = null; // Limpiar error al cargar
    notifyListeners();
  }

  Future<T?> ejecutar<T>(Future<T> Function() operacion) async {
    setLoading(true);
    try {
      final resultado = await operacion();
      _error = null;
      notifyListeners();
      return resultado;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      setLoading(false);
    }
  }

  void reemplazar<T>(
    List<T> items,
    T item,
    dynamic Function(T) compareFn,
  ) {
    final idx = items.indexWhere((x) => compareFn(x) == compareFn(item));
    if (idx != -1) {
      items[idx] = item;
      notifyListeners();
    }
  }

  /// Agrega un item al inicio de la lista
  void agregarAlInicio<T>(List<T> items, T item) {
    items.insert(0, item);
    notifyListeners();
  }

  /// Agrega un item al final de la lista
  void agregarAlFinal<T>(List<T> items, T item) {
    items.add(item);
    notifyListeners();
  }

  /// Elimina items que cumplan con el predicado
  void eliminar<T>(List<T> items, bool Function(T) predicate) {
    items.removeWhere(predicate);
    notifyListeners();
  }

  /// Elimina un item específico
  void eliminarItem<T>(List<T> items, T item) {
    items.remove(item);
    notifyListeners();
  }

  /// Limpia la lista
  void limpiar<T>(List<T> items) {
    items.clear();
    notifyListeners();
  }

  /// Establece el mensaje de error y notifica listeners
  /// Usa null para limpiar el error.
  void setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  /// Limpia error
  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}
