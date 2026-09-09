import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_residential/core/enums/estado_carga.dart';
import 'package:flutter_residential/core/enums/modulo.dart';
import 'package:flutter_residential/features/inquilinos/providers/inquilino_permisos_provider.dart';
import 'package:flutter_residential/features/modulos/providers/modulos_provider.dart';
import 'package:flutter_residential/features/modulos/models/modulo_estado.dart';

/// Blinda la decisión de diseño de los 3 estados. Es un contrato fácil de
/// romper sin darse cuenta (basta con "simplificar" el switch de `activo()` a
/// un booleano) y romperlo devuelve el parpadeo o, peor, deja la app vacía
/// cuando el backend falla.
/// Fila de catálogo como la arma el backend. Se construye por `fromJson` a
/// propósito: si el modelo cambia, el test no se cae por un constructor.
ModuloEstado _catalogo(Modulo modulo, {required bool activo}) =>
    ModuloEstado.fromJson({
      'codigo': modulo.codigo,
      'nombre': modulo.nombre,
      'activo': activo,
    });

void main() {
  group('ModulosProvider — qué responde según el estado', () {
    test('sin cargar oculta: nada parpadea en el primer frame', () {
      final p = ModulosProvider();

      expect(p.estadoCarga, EstadoCarga.inicial);
      expect(p.resuelto, isFalse);
      expect(p.activo(Modulo.pqr), isFalse);
    });

    test('cargado responde el dato real', () {
      final p = ModulosProvider()
        ..aplicarDesdeCatalogo([
          _catalogo(Modulo.pqr, activo: true),
          _catalogo(Modulo.reservas, activo: false),
        ]);

      expect(p.estadoCarga, EstadoCarga.listo);
      expect(p.resuelto, isTrue);
      expect(p.activo(Modulo.pqr), isTrue);
      expect(p.activo(Modulo.reservas), isFalse);
    });

    test('sin conjunto resuelve fail-open: nunca esqueleto eterno', () {
      final p = ModulosProvider()..marcarSinConjunto();

      expect(p.resuelto, isTrue,
          reason: 'si no resolviera, el gate mostraría el esqueleto para siempre');
      expect(p.activo(Modulo.pqr), isTrue,
          reason: 'fail-open: que corte el backend, no una app vacía');
    });

    test('limpiar (logout / cambio de conjunto) vuelve a ocultar', () {
      final p = ModulosProvider()
        ..aplicarDesdeCatalogo([_catalogo(Modulo.pqr, activo: true)]);

      p.limpiarDatos();

      expect(p.estadoCarga, EstadoCarga.inicial);
      expect(p.resuelto, isFalse);
      expect(p.activo(Modulo.pqr), isFalse,
          reason: 'no debe quedar visible el módulo del conjunto anterior');
    });
  });

  group('InquilinoPermisosProvider', () {
    test('sin cargar no está resuelto y no concede permisos', () {
      final p = InquilinoPermisosProvider();

      expect(p.resuelto, isFalse);
      expect(p.tienePermiso('ESTADO_CUENTA'), isFalse);
    });

    test('marcarNoAplica resuelve sin pedir nada al backend', () {
      final p = InquilinoPermisosProvider()..marcarNoAplica();

      expect(p.estadoCarga, EstadoCarga.listo);
      expect(p.resuelto, isTrue,
          reason: 'si no resolviera, el gate se colgaría para propietario, '
              'admin y vigilante, que nunca cargan permisos');
      expect(p.tienePermiso('ESTADO_CUENTA'), isFalse);
    });
  });

  group('EstadoCarga', () {
    test('resuelto solo para listo y error', () {
      expect(EstadoCarga.inicial.resuelto, isFalse);
      expect(EstadoCarga.cargando.resuelto, isFalse);
      expect(EstadoCarga.listo.resuelto, isTrue);
      expect(EstadoCarga.error.resuelto, isTrue);
    });
  });
}
