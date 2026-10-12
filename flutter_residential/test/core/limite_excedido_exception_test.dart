import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_residential/core/exceptions/api_exception.dart';
import 'package:flutter_residential/core/exceptions/limite_excedido_exception.dart';

void main() {
  group('LimiteExcedidoException.desdeRespuesta', () {
    test('toma el mensaje del ErrorResponse y el Retry-After en segundos', () {
      final e = LimiteExcedidoException.desdeRespuesta(
        '{"status":429,"error":"LIMITE_EXCEDIDO","message":"Demasiados intentos fallidos. Intenta de nuevo en 15 minutos."}',
        '900',
      );

      expect(e.message, 'Demasiados intentos fallidos. Intenta de nuevo en 15 minutos.');
      expect(e.reintentarEn, const Duration(seconds: 900));
      expect(e.statusCode, 429);
    });

    test('con body vacío o no-JSON usa el mensaje por defecto', () {
      expect(LimiteExcedidoException.desdeRespuesta('', null).message,
          LimiteExcedidoException.mensajePorDefecto);
      expect(LimiteExcedidoException.desdeRespuesta('<html>', '30').message,
          LimiteExcedidoException.mensajePorDefecto);
    });

    test('ignora un Retry-After inválido', () {
      expect(LimiteExcedidoException.desdeRespuesta('{}', 'mañana').reintentarEn, isNull);
      expect(LimiteExcedidoException.desdeRespuesta('{}', '0').reintentarEn, isNull);
    });

    test('es un ApiException: los providers muestran el mensaje sin código extra', () {
      final e = LimiteExcedidoException.desdeRespuesta('{"message":"Espera"}', '5');

      expect(e, isA<ApiException>());
      expect(ApiException.extract(e), 'Espera');
    });
  });
}
