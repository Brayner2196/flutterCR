import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../theme/app_theme.dart';

/// Avisos de resultado de una operación, en un solo sitio.
///
/// Existe porque el patrón repetido en las pantallas era este:
///
/// ```dart
/// await provider.crear(datos);          // ejecutar() se traga la excepción
/// mostrarExito('Creado correctamente'); // ...y esto corre igual si falló
/// ```
///
/// `BaseProvider.ejecutar` atrapa el error y devuelve null a propósito, para que
/// las pantallas de carga puedan leer `provider.error` y pintarlo. El efecto
/// secundario es que una MUTACIÓN nunca lanza, así que el `catch` del llamador
/// no corre nunca y la pantalla felicita al usuario por algo que no pasó.
///
/// La forma correcta, ahora que las mutaciones devuelven `bool`:
///
/// ```dart
/// final ok = await provider.crear(datos);
/// if (!context.mounted) return;
/// if (!ok) {
///   MensajeOperacion.error(context, 'Error al crear usuario', provider.error);
///   return;
/// }
/// MensajeOperacion.exito(context, 'Usuario creado correctamente');
/// ```
class MensajeOperacion {
  const MensajeOperacion._();

  /// Falla de una operación. [detalle] es el `provider.error`, que ya viene con
  /// el `message` real del backend gracias a `BaseApiService`.
  static void error(BuildContext context, String titulo, String? detalle) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      title: Text(titulo),
      description: Text(
        // Sin detalle el toast quedaría con el título solo, que no dice nada
        // accionable; este texto al menos orienta.
        (detalle == null || detalle.trim().isEmpty)
            ? 'No se pudo completar la operación. Inténtalo de nuevo.'
            : detalle,
      ),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 5),
      showProgressBar: true,
      closeOnClick: true,
    );
  }

  /// Operación completada. Se usa SnackBar y no toast por consistencia con el
  /// resto de confirmaciones del proyecto.
  static void exito(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.ok,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
