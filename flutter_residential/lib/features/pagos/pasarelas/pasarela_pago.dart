import 'package:flutter/material.dart';
import '../models/pasarela_disponible_model.dart';

/// Contrato de una pasarela de pago — equivalente al interface PasarelaService
/// del backend Spring Boot.
///
/// Cada pasarela implementa sus propios metadatos visuales (color, ícono,
/// descripción de métodos soportados) y la lógica de creación de checkout.
///
/// Uso:
/// ```dart
/// final pasarela = PasarelaFactory.obtener(TipoPasarela.wompi);
/// final checkout = await pasarela.crearCheckout(cobro.id);
/// ```
abstract class PasarelaPago {
  // ── Identidad ───────────────────────────────────────────────────────────────

  /// Tipo de pasarela — debe coincidir con el enum del backend.
  TipoPasarela get tipo;

  /// Nombre legible para mostrar en la UI.
  String get nombre;

  // ── Presentación visual ─────────────────────────────────────────────────────

  /// Color de marca principal de la pasarela.
  Color get color;

  /// Ícono representativo.
  IconData get icono;

  /// Descripción corta de los métodos de pago soportados.
  /// Ej: "Tarjetas, PSE, efectivo"
  String get descripcion;

  // ── Operaciones ─────────────────────────────────────────────────────────────

  /// Crea el checkout en el backend y retorna la URL + tipo de pasarela.
  ///
  /// [cobroId] — ID del cobro a pagar.
  /// [monto]   — Monto personalizado (opcional; si es null usa el monto del cobro).
  Future<CheckoutResponseModel> crearCheckout(int cobroId, {double? monto});
}
