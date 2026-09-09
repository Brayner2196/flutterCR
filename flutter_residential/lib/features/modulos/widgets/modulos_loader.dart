// ARCHIVO OBSOLETO — se puede borrar.
//
// `ModulosLoader` fue reemplazado por `SesionContextoLoader`, en
// `lib/shared/widgets/sesion_contexto_loader.dart`, que además de los módulos
// del conjunto carga los permisos del usuario en el mismo punto.
//
// Se movió a `shared/` porque ya no es un widget del feature de módulos: cruza
// auth + modulos + inquilinos, igual que `shared/widgets/modulo_guard.dart`.
//
// Quedó vacío en vez de borrado porque esta sesión no tiene permiso de
// eliminar archivos. Para limpiarlo:
//
//     rm lib/features/modulos/widgets/modulos_loader.dart
//     rmdir lib/features/modulos/widgets
