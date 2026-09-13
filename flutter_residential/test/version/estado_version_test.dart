import 'package:flutter_residential/core/version/estado_version.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parseo y presentación del estado de versión. Sin widgets, sin red.
void main() {
  group('InfoVersion.desdeJson', () {
    test('lee el estado obligatorio y sus campos', () {
      final info = InfoVersion.desdeJson({
        'estado': 'OBLIGATORIA',
        'versionNombre': '1.2.0',
        'mensaje': 'Los pagos de Wompi requieren la versión nueva',
        'urlTienda': 'market://details?id=com.flutter_residential.flutter_residential',
      });

      expect(info.estado, EstadoVersion.obligatoria);
      expect(info.bloquea, isTrue);
      expect(info.requiereAccion, isTrue);
      expect(info.versionNombre, '1.2.0');
      expect(info.mensajeVisible, 'Los pagos de Wompi requieren la versión nueva');
    });

    test('sugerida no bloquea pero sí requiere acción', () {
      final info = InfoVersion.desdeJson({'estado': 'SUGERIDA'});

      expect(info.bloquea, isFalse);
      expect(info.requiereAccion, isTrue);
    });

    test('al día no requiere nada', () {
      final info = InfoVersion.desdeJson({'estado': 'AL_DIA'});

      expect(info.estado, EstadoVersion.alDia);
      expect(info.requiereAccion, isFalse);
      expect(info.bloquea, isFalse);
    });

    test('un estado que esta versión no conoce se trata como al día', () {
      // Si el backend agrega un estado nuevo, las apps viejas siguen
      // funcionando en vez de quedarse trabadas.
      final info = InfoVersion.desdeJson({'estado': 'ALGO_NUEVO'});

      expect(info.estado, EstadoVersion.alDia);
    });

    test('estado ausente o nulo se trata como al día', () {
      expect(InfoVersion.desdeJson({}).estado, EstadoVersion.alDia);
      expect(InfoVersion.desdeJson({'estado': null}).estado, EstadoVersion.alDia);
    });
  });

  group('mensajeVisible', () {
    test('usa un texto propio cuando el backend no manda ninguno', () {
      final obligatoria = InfoVersion.desdeJson({'estado': 'OBLIGATORIA'});
      final sugerida = InfoVersion.desdeJson({'estado': 'SUGERIDA'});

      expect(obligatoria.mensajeVisible, isNotEmpty);
      expect(sugerida.mensajeVisible, isNotEmpty);
      expect(obligatoria.mensajeVisible, isNot(sugerida.mensajeVisible));
    });

    test('un mensaje en blanco cuenta como ausente', () {
      final info = InfoVersion.desdeJson({'estado': 'SUGERIDA', 'mensaje': '   '});

      expect(info.mensajeVisible.trim(), isNotEmpty);
    });
  });

  group('desconocido', () {
    test('nunca bloquea: una caída del backend no puede inutilizar la app', () {
      expect(InfoVersion.desconocido.bloquea, isFalse);
      expect(InfoVersion.desconocido.requiereAccion, isFalse);
    });
  });
}
