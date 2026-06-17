/// Resultado de un envío de aviso de cobranza (respuesta del backend).
class AvisoCobranzaResultado {
  final int propiedadId;
  final String? faseNombre;
  final int usuariosNotificados;
  final bool enviado;

  const AvisoCobranzaResultado({
    required this.propiedadId,
    this.faseNombre,
    required this.usuariosNotificados,
    required this.enviado,
  });

  factory AvisoCobranzaResultado.fromJson(Map<String, dynamic> j) =>
      AvisoCobranzaResultado(
        propiedadId: j['propiedadId'] as int,
        faseNombre: j['faseNombre'] as String?,
        usuariosNotificados: j['usuariosNotificados'] as int? ?? 0,
        enviado: j['enviado'] as bool? ?? false,
      );
}
