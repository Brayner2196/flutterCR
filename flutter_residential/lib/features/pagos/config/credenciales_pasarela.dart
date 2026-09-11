import 'package:flutter/material.dart';
import '../models/pasarela_disponible_model.dart';

/// Descripción de un campo de credencial: cómo se llama en el panel de la pasarela,
/// qué formato tiene y si el checkout puede funcionar sin él.
class CampoCredencial {
  /// Etiqueta visible. Usa el nombre exacto que la pasarela le da en SU panel, para que el
  /// admin sepa qué copiar sin adivinar.
  final String label;

  /// Ejemplo del formato del valor.
  final String hint;

  final IconData icono;

  /// Si el checkout no puede funcionar sin este dato.
  final bool obligatorio;

  /// Si se muestra oculto, con botón de ver/ocultar.
  final bool secreto;

  /// Una línea de contexto: para qué sirve y de dónde se saca.
  final String ayuda;

  const CampoCredencial({
    required this.label,
    required this.hint,
    required this.icono,
    required this.obligatorio,
    required this.secreto,
    required this.ayuda,
  });
}

/// Qué credenciales pide cada pasarela, en un solo lugar.
///
/// El wizard de creación del conjunto y la pantalla de administración pedían las mismas
/// credenciales con etiquetas y ayudas escritas por separado en cada archivo. Al vivir aquí,
/// agregar un campo (o corregir un nombre que la pasarela cambió) se hace una vez y las dos
/// pantallas quedan iguales.
class CredencialesPasarela {
  const CredencialesPasarela._();

  // ─── Llave pública ─────────────────────────────────────────────────────────

  static CampoCredencial publicKey(TipoPasarela tipo) => switch (tipo) {
        TipoPasarela.mercadoPago => const CampoCredencial(
            label: 'Public key',
            hint: 'APP_USR-xxxxxxxx...',
            icono: Icons.key_outlined,
            obligatorio: true,
            secreto: false,
            ayuda: 'Llave pública del checkout, en Credenciales de Mercado Pago.',
          ),
        TipoPasarela.wompi => const CampoCredencial(
            label: 'Llave pública',
            hint: 'pub_test_xxxx / pub_prod_xxxx',
            icono: Icons.key_outlined,
            obligatorio: true,
            secreto: false,
            ayuda: 'Identifica al comercio y define el ambiente: pub_test es pruebas, '
                'pub_prod es producción.',
          ),
        TipoPasarela.bold => const CampoCredencial(
            label: 'API key pública',
            hint: 'pk_xxxxxxxx...',
            icono: Icons.key_outlined,
            obligatorio: true,
            secreto: false,
            ayuda: 'Llave de identificación pública del panel de Bold.',
          ),
      };

  // ─── Llave privada ─────────────────────────────────────────────────────────

  static CampoCredencial privateKey(TipoPasarela tipo) => switch (tipo) {
        TipoPasarela.mercadoPago => const CampoCredencial(
            label: 'Access token',
            hint: 'APP_USR-xxxxxxxx-xxxx...',
            icono: Icons.lock_outline,
            obligatorio: true,
            secreto: true,
            ayuda: 'Con esto se crean las preferencias de pago. No se comparte con nadie.',
          ),
        TipoPasarela.wompi => const CampoCredencial(
            label: 'Llave privada',
            hint: 'prv_test_xxxx / prv_prod_xxxx',
            icono: Icons.lock_outline,
            obligatorio: true,
            secreto: true,
            ayuda: 'Sirve para consultar el estado de una transacción cuando el residente '
                'vuelve a la app.',
          ),
        TipoPasarela.bold => const CampoCredencial(
            label: 'API key privada',
            hint: 'sk_xxxxxxxx...',
            icono: Icons.lock_outline,
            obligatorio: true,
            secreto: true,
            ayuda: 'Llave secreta del panel de Bold.',
          ),
      };

  // ─── Secreto de eventos / webhooks ─────────────────────────────────────────

  static CampoCredencial webhookSecret(TipoPasarela tipo) => switch (tipo) {
        TipoPasarela.mercadoPago => const CampoCredencial(
            label: 'Clave secreta de webhooks',
            hint: 'Para verificar la firma de las notificaciones',
            icono: Icons.webhook_outlined,
            obligatorio: false,
            secreto: true,
            ayuda: 'Sin esto, cualquiera podría enviar una notificación falsa de pago '
                'aprobado. Está en la configuración de notificaciones.',
          ),
        TipoPasarela.wompi => const CampoCredencial(
            label: 'Secreto de eventos',
            hint: 'events_secret del panel de Wompi',
            icono: Icons.webhook_outlined,
            obligatorio: false,
            secreto: true,
            ayuda: 'Verifica que el aviso de pago viene de Wompi. Sin esto, un aviso falso '
                'podría marcar cobros como pagados.',
          ),
        TipoPasarela.bold => const CampoCredencial(
            label: 'Secreto de eventos',
            hint: 'Secreto configurado en el panel',
            icono: Icons.webhook_outlined,
            obligatorio: false,
            secreto: true,
            ayuda: 'Verifica que el aviso de pago viene de Bold.',
          ),
      };

  // ─── Secreto de integridad ─────────────────────────────────────────────────

  /// El secreto con el que se FIRMA la URL del checkout antes de abrírsela al residente.
  ///
  /// Devuelve null en las pasarelas que no lo usan, y así el campo no aparece en el
  /// formulario: es la única fuente que decide si se pide o no.
  ///
  /// No confundirlo con el secreto de eventos: ese verifica lo que llega, este firma lo que
  /// sale. Son dos valores distintos en el panel de Wompi.
  static CampoCredencial? integritySecret(TipoPasarela tipo) => switch (tipo) {
        TipoPasarela.wompi => const CampoCredencial(
            label: 'Secreto de integridad',
            hint: 'prod_integrity_xxxx / test_integrity_xxxx',
            icono: Icons.verified_user_outlined,
            obligatorio: true,
            secreto: true,
            ayuda: 'Firma el cobro para que nadie pueda alterar el monto en el enlace de '
                'pago. Sin esto, Wompi rechaza el checkout. Es distinto del secreto de '
                'eventos y está en el mismo panel, en Configuración del comercio.',
          ),
        TipoPasarela.mercadoPago => null,
        TipoPasarela.bold => null,
      };

  /// Si esta pasarela necesita el secreto de integridad para poder cobrar.
  static bool requiereIntegritySecret(TipoPasarela tipo) =>
      integritySecret(tipo)?.obligatorio ?? false;

  // ─── Ayuda general de la pasarela ──────────────────────────────────────────

  static String ayudaGeneral(TipoPasarela tipo) => switch (tipo) {
        TipoPasarela.mercadoPago =>
          'Mercado Pago: copia la Public key y el Access token desde Tus integraciones → '
              'Credenciales.',
        TipoPasarela.wompi =>
          'Wompi: necesita tres datos del panel — llave pública, llave privada y secreto de '
              'integridad. El secreto de eventos es opcional pero muy recomendado.',
        TipoPasarela.bold =>
          'Bold: copia las API keys pública y privada desde el panel de integraciones.',
      };
}
