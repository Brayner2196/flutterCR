import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

// ─── Pantallas admin ──────────────────────────────────────────────────────────
import '../../features/pagos/screens/admin/admin_cobros_screen.dart';
import '../../features/reservas/screens/admin/admin_reservas_screen.dart';
import '../../features/pqr/screens/admin/admin_pqrs_screen.dart';
import '../../features/anuncios/screens/admin/admin_anuncios_screen.dart';
import '../../features/votaciones/screens/admin/admin_votaciones_screen.dart';
import '../../features/usuarios/screens/admin/usuarios_screen.dart';

// ─── Pantallas residente ──────────────────────────────────────────────────────
import '../../features/pagos/screens/residente/estado_cuenta_screen.dart';
import '../../features/reservas/screens/residente/mis_reservas_screen.dart';
import '../../features/pqr/screens/residente/mis_pqrs_screen.dart';
import '../../features/anuncios/screens/residente/mis_anuncios_screen.dart';
import '../../features/votaciones/screens/residente/mis_votaciones_screen.dart';
import '../../features/marketplace/screens/residente/marketplace_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Handler top-level para mensajes recibidos con la app en background/terminada.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// ─── Convención de rutas (campo "route" en data del payload FCM) ──────────────
//
// El backend envía en el data payload: { "route": "<valor>" }
// Rutas soportadas:
//   "pagos"       → cobros del admin / mis cobros del residente
//   "reservas"    → reservas (admin / residente)
//   "pqr"         → PQRs (admin / residente)
//   "anuncios"    → anuncios (admin / residente)
//   "votaciones"  → votaciones (admin / residente)
//   "marketplace" → marketplace (residente)
//   "usuarios"    → gestión de usuarios (admin)
//   (sin ruta)    → solo abre la app

class NotificacionService {
  static final NotificacionService _instancia = NotificacionService._();
  factory NotificacionService() => _instancia;
  NotificacionService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const _channelId   = 'conjuntos_cr_channel';
  static const _channelName = 'Conjuntos CR';

  /// NavigatorKey inyectado desde main.dart — permite navegar sin BuildContext.
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Configura la clave del navigator. Llamar antes de inicializar().
  void configurarNavigator(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  // ─── Inicialización ───────────────────────────────────────────────────────

  Future<void> inicializar() async {
    await _solicitarPermisos();
    await _configurarNotificacionesLocales();

    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _escucharForeground();
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // App en background → usuario toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      debugPrint('[FCM] onMessageOpenedApp: ${msg.data}');
      _manejarData(msg.data);
    });

    // App cerrada → notificación que la abrió.
    // Se da un delay mínimo para que MaterialApp construya el árbol de widgets;
    // el retry en _manejarData se encarga de esperar a que AuthProvider cargue el rol.
    final inicial = await FirebaseMessaging.instance.getInitialMessage();
    if (inicial != null) {
      debugPrint('[FCM] getInitialMessage: ${inicial.data}');
      Future.delayed(const Duration(milliseconds: 500), () {
        _manejarData(inicial.data);
      });
    }
  }

  Future<void> _solicitarPermisos() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permiso: ${settings.authorizationStatus}');
  }

  Future<void> _configurarNotificacionesLocales() async {
    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings();

    await _localNotif.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      // App en foreground → usuario toca la notificación local
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[FCM] Tap en notificación local: ${response.payload}');
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            _manejarData(data);
          } catch (_) {}
        }
      },
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notificaciones del conjunto residencial',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Muestra la notificación cuando la app está en primer plano.
  void _escucharForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground: ${message.notification?.title} | data: ${message.data}');

      final notif = message.notification;
      if (notif == null) return;

      final notifId = DateTime.now().millisecondsSinceEpoch % 100000;

      _localNotif.show(
        notifId,
        notif.title,
        notif.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Notificaciones del conjunto residencial',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            color: const Color(0xFF005F8F),
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });
  }

  // ─── Navegación por notificación ──────────────────────────────────────────

  /// [intentos] evita un loop infinito si el usuario no está autenticado.
  void _manejarData(Map<String, dynamic> data, {int intentos = 0}) {
    const maxIntentos = 15;
    const retryDelay  = Duration(milliseconds: 400);

    final ruta = data['route'] as String?;
    if (ruta == null || ruta.isEmpty) return;

    final nav = _navigatorKey?.currentState;
    final ctx = _navigatorKey?.currentContext;
    if (nav == null || ctx == null) {
      if (intentos < maxIntentos) {
        debugPrint('[FCM] Navigator no listo, reintentando ($intentos)... ruta=$ruta');
        Future.delayed(retryDelay, () => _manejarData(data, intentos: intentos + 1));
      } else {
        debugPrint('[FCM] Navigator nunca disponible, se abandona la navegación: $ruta');
      }
      return;
    }

    AuthProvider authProvider;
    try {
      authProvider = ctx.read<AuthProvider>();
    } catch (e) {
      if (intentos < maxIntentos) {
        debugPrint('[FCM] AuthProvider no disponible, reintentando ($intentos)...');
        Future.delayed(retryDelay, () => _manejarData(data, intentos: intentos + 1));
      }
      return;
    }

    // Esperar a que la sesión termine de cargarse desde SharedPreferences
    if (authProvider.status == AuthStatus.inicial ||
        authProvider.status == AuthStatus.cargando) {
      if (intentos < maxIntentos) {
        debugPrint('[FCM] Auth aún cargando, reintentando ($intentos)... ruta=$ruta');
        Future.delayed(retryDelay, () => _manejarData(data, intentos: intentos + 1));
      } else {
        debugPrint('[FCM] Auth nunca estuvo lista, se abandona: $ruta');
      }
      return;
    }

    final String? rol = authProvider.rol;
    debugPrint('[FCM] Navegando → ruta=$ruta  rol=$rol');

    final esAdmin      = rol == 'TENANT_ADMIN';
    final esResidente  = rol == 'PROPIETARIO' || rol == 'INQUILINO';

    Widget? destino;

    switch (ruta) {
      case 'pagos':
        if (esAdmin)     destino = const AdminCobrosScreen();
        if (esResidente) destino = const EstadoCuentaScreen();
        break;

      case 'reservas':
        if (esAdmin)     destino = const AdminReservasScreen();
        if (esResidente) destino = const MisReservasScreen();
        break;

      case 'pqr':
        if (esAdmin)     destino = const AdminPqrsScreen();
        if (esResidente) destino = const MisPqrsScreen();
        break;

      case 'anuncios':
        if (esAdmin)     destino = const AdminAnunciosScreen();
        if (esResidente) destino = const MisAnunciosScreen();
        break;

      case 'votaciones':
        if (esAdmin)     destino = const AdminVotacionesScreen();
        if (esResidente) destino = const MisVotacionesScreen();
        break;

      case 'marketplace':
        destino = const MarketplaceScreen();
        break;

      case 'usuarios':
        if (esAdmin) destino = const UsuariosScreen();
        break;

      default:
        debugPrint('[FCM] Ruta desconocida: $ruta — solo se abre la app');
    }

    if (destino != null) {
      nav.push(MaterialPageRoute(builder: (_) => destino!));
    }
  }

  // ─── Token FCM ────────────────────────────────────────────────────────────

  Future<void> registrarTokenEnBackend() async {
    try {
      final token = await _fcm.getToken();
      debugPrint('[FCM] Token: ${token?.substring(0, 20)}...');
      if (token == null) return;

      await ApiClient.post(
        ApiConstants.fcmToken,
        {'token': token, 'plataforma': _plataforma()},
        requiresAuth: true,
      );

      _fcm.onTokenRefresh.listen((nuevoToken) {
        ApiClient.post(
          ApiConstants.fcmToken,
          {'token': nuevoToken, 'plataforma': _plataforma()},
          requiresAuth: true,
        );
      });
    } catch (e) {
      debugPrint('[FCM] Error al registrar token: $e');
    }
  }

  /// Elimina el token FCM del backend.
  /// [token] y [tenantId] se pasan explícitamente desde logout() para evitar
  /// el race condition entre el HTTP DELETE y el borrado del secure storage.
  Future<void> eliminarTokenDelBackend({String? token, String? tenantId}) async {
    try {
      await ApiClient.delete(
        ApiConstants.fcmToken,
        token: token,
        tenantId: tenantId,
      );
      await _fcm.deleteToken();
    } catch (_) {}
  }

  // ─── Helper ───────────────────────────────────────────────────────────────

  String _plataforma() => Platform.isAndroid ? 'ANDROID' : 'IOS';
}
