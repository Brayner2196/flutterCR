/// Punto de entrada único al actualizador de la plataforma.
///
/// Nadie importa `actualizador_io.dart` ni `actualizador_web.dart` directo:
/// hacerlo arrastra `dart:io` (o `package:web`) al árbol de la otra plataforma
/// y el build AOT de release falla. Siempre por acá, igual que `net_error.dart`
/// y `core/platform/archivo.dart`.
library;

export 'actualizador_io.dart'
    if (dart.library.js_interop) 'actualizador_web.dart';
