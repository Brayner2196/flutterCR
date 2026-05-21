import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  late final StreamSubscription<List<ConnectivityResult>> _sub;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    // Estado inicial al arrancar
    final result = await _connectivity.checkConnectivity();
    _isOnline = _evaluar(result);
    notifyListeners();

    // Escuchar cambios en tiempo real
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final online = _evaluar(results);
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    });
  }

  bool _evaluar(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  /// Verificación puntual (útil desde ApiClient antes de un request).
  Future<bool> verificar() async {
    final result = await _connectivity.checkConnectivity();
    return _evaluar(result);
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
