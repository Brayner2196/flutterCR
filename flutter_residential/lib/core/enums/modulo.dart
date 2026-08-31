/// Catálogo de módulos parametrizables del conjunto.
///
/// Espejo EXACTO del enum `Modulo` del backend
/// (`entity/enums/Modulo.java`): el valor de [codigo] es la clave que viaja en
/// el JSON, así que si allá se agrega un módulo, acá también.
///
/// Acá NO están los módulos núcleo (cobros, pagos, abonos, cartera, usuarios,
/// propiedades, autenticación, dashboard): esos siempre están disponibles y no
/// se pueden apagar, por eso no necesitan representación.
enum Modulo {
  pqr('PQR', 'PQRs'),
  reservas('RESERVAS', 'Reservas'),
  anuncios('ANUNCIOS', 'Anuncios'),
  documentos('DOCUMENTOS', 'Documentos'),
  votaciones('VOTACIONES', 'Votaciones'),
  marketplace('MARKETPLACE', 'Marketplace'),
  presupuesto('PRESUPUESTO', 'Presupuesto'),
  parqueaderos('PARQUEADEROS', 'Parqueaderos'),
  consejo('CONSEJO', 'Consejo comunal'),
  vigilancia('VIGILANCIA', 'Vigilancia'),
  visitas('VISITAS', 'Visitas'),
  paquetes('PAQUETES', 'Paquetes'),
  planesPago('PLANES_PAGO', 'Planes de pago'),
  inquilinos('INQUILINOS', 'Inquilinos');

  const Modulo(this.codigo, this.nombre);

  /// Clave que usa el backend (ej: `PLANES_PAGO`).
  final String codigo;

  /// Etiqueta legible por defecto. El backend puede enviar otra en el panel
  /// del super admin; esta sirve para mensajes locales.
  final String nombre;

  /// Busca por código. Devuelve `null` si el backend envía uno desconocido
  /// (ej: la app está desactualizada frente al servidor).
  static Modulo? desdeCodigo(String? codigo) {
    if (codigo == null || codigo.isEmpty) return null;
    for (final m in Modulo.values) {
      if (m.codigo == codigo) return m;
    }
    return null;
  }
}
