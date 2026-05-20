import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../exceptions/api_exception.dart';

/// Punto único para mostrar toasts en la app.
/// Unifica las 3 formas distintas de notificación que existían:
///   1. ScaffoldMessenger + SnackBar
///   2. toastification directo
///   3. ScaffoldMessenger con duración custom
class AppToast {
  AppToast._();

  static void success(
    BuildContext context,
    String title, {
    String? description,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      tipo: ToastificationType.success,
      title: title,
      description: description,
      duration: duration,
    );
  }

  static void error(
    BuildContext context,
    dynamic error, {
    String? title,
    Duration duration = const Duration(seconds: 5),
  }) {
    _show(
      context,
      tipo: ToastificationType.error,
      title: title ?? 'Error',
      description: ApiException.extract(error),
      duration: duration,
    );
  }

  static void info(
    BuildContext context,
    String title, {
    String? description,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      tipo: ToastificationType.info,
      title: title,
      description: description,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context,
    String title, {
    String? description,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      tipo: ToastificationType.warning,
      title: title,
      description: description,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required ToastificationType tipo,
    required String title,
    String? description,
    required Duration duration,
  }) {
    toastification.show(
      context: context,
      type: tipo,
      style: ToastificationStyle.flatColored,
      title: Text(title),
      description: description != null ? Text(description) : null,
      alignment: Alignment.topRight,
      autoCloseDuration: duration,
      showProgressBar: true,
      closeOnClick: true,
    );
  }
}
