/// Tipos de pasarela soportados (deben coincidir con el enum TipoPasarela del backend)
enum TipoPasarela {
  mercadoPago('MERCADO_PAGO'),
  wompi('WOMPI'),
  bold('BOLD');

  final String backendValue;
  const TipoPasarela(this.backendValue);

  static TipoPasarela fromString(String value) {
    return TipoPasarela.values.firstWhere(
      (e) => e.backendValue == value,
      orElse: () => TipoPasarela.mercadoPago,
    );
  }

  String get nombreLegible {
    switch (this) {
      case TipoPasarela.mercadoPago:
        return 'Mercado Pago';
      case TipoPasarela.wompi:
        return 'Wompi';
      case TipoPasarela.bold:
        return 'Bold';
    }
  }
}

/// Modelo de una pasarela disponible para el residente
class PasarelaDisponibleModel {
  final TipoPasarela tipo;
  final String nombre;
  final int prioridad;

  const PasarelaDisponibleModel({
    required this.tipo,
    required this.nombre,
    required this.prioridad,
  });

  factory PasarelaDisponibleModel.fromJson(Map<String, dynamic> json) {
    return PasarelaDisponibleModel(
      tipo: TipoPasarela.fromString(json['tipo'] as String),
      nombre: json['nombre'] as String,
      prioridad: json['prioridad'] as int? ?? 1,
    );
  }
}

/// Respuesta unificada del checkout
class CheckoutResponseModel {
  final String checkoutUrl;
  final TipoPasarela tipoPasarela;

  const CheckoutResponseModel({
    required this.checkoutUrl,
    required this.tipoPasarela,
  });

  factory CheckoutResponseModel.fromJson(Map<String, dynamic> json) {
    return CheckoutResponseModel(
      checkoutUrl: json['checkoutUrl'] as String,
      tipoPasarela: TipoPasarela.fromString(json['tipo'] as String),
    );
  }
}
