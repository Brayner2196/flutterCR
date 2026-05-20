# Reporte de Mejora — Proyecto CR (Flutter + Spring Boot)

## 1. Análisis Rápido

### Hallazgos principales

**Backend (BackEndCR)**
- `resolverAdminId` / `resolverResidenteId` duplicados en 7 controllers (~80 líneas repetidas) → extraído a `SecurityUtils`
- N+1 query en `PagoService.getMovimientosCobro()` — una query por abono dentro de un loop → corregido con batch `findAllById`
- `AuthService.registro()` sin `@Transactional` — fallo a mitad dejaba datos huérfanos en BD → corregido
- Patrón `jsonDecode + statusCode check` duplicado en 14+ servicios Flutter → centralizado en `BaseApiService`

**Frontend (flutterCR)**
- 3 patrones distintos de notificación (SnackBar, toastification, custom) → unificados en `AppToast`
- `_fmt()` local duplicado en múltiples pantallas de pagos → centralizado en `CurrencyFormatter`
- `Exception.toString().replaceFirst('Exception: ', '')` en 90+ lugares → `ApiException.extract()`
- Roles `PROPIETARIO` e `INQUILINO` no existían → implementados en backend y frontend

---

## 2. Análisis Detallado

### Flujos y Procesos

#### A. N+1 en PagoService (CRÍTICO)

**Antes:**
```java
for (MovimientoCobro mov : movimientos) {
    List<Abono> abonos = abonoRepo.findByMovimientoCobroId(mov.getId()); // query por iteración
    ...
}
```

**Después:**
```java
Set<Long> ids = movimientos.stream().map(MovimientoCobro::getId).collect(Collectors.toSet());
Map<Long, List<Abono>> abonoMap = abonoRepo.findAllById(ids)
    .stream().collect(Collectors.groupingBy(a -> a.getMovimientoCobro().getId()));

for (MovimientoCobro mov : movimientos) {
    List<Abono> abonos = abonoMap.getOrDefault(mov.getId(), List.of());
    ...
}
```
**Impacto:** De N+1 queries a 2 queries totales.

#### B. @Transactional faltante en AuthService.registro()

**Antes:**
```java
public AuthResponse registro(RegistroRequest req) { // sin @Transactional
    Identidad id = identidadRepo.save(...);
    Usuario u = usuarioRepo.save(...); // si falla → Identidad huérfana en BD
    ...
}
```

**Después:**
```java
@Transactional
public AuthResponse registro(RegistroRequest req) { // rollback automático si falla
    ...
}
```

#### C. Roles PROPIETARIO e INQUILINO

- `CrearUsuarioRequest` acepta `PROPIETARIO` en el regex de validación
- Endpoint `PUT /api/usuarios/{id}/aprobar?rolDestino=PROPIETARIO` permite aprobar como propietario
- Nuevo `PropietarioController` con `GET/POST/DELETE /api/propietario/inquilinos`
- Flutter: tab "Inquilinos" visible solo para `isPropietario`, nuevo `MisInquilinosScreen`

---

### Métodos Reutilizables

#### A. SecurityUtils (Spring)

**Patrón duplicado (7 controllers, ~80 líneas):**
```java
private Long resolverAdminId(String email) {
    return identidadRepo.findByEmail(email)
        .flatMap(i -> usuarioRepo.findByIdentidadId(i.getId()))
        .map(u -> u.getId())
        .orElseThrow(...);
}
```

**Solución:**
```java
// config/SecurityUtils.java
@Component
public class SecurityUtils {
    public Long resolverUsuarioId(String email) { ... }
}
// Uso en cualquier controller:
securityUtils.resolverUsuarioId(email)
```
**Archivos refactorizados:** `AdminAnuncioController`, `AdminPQRController`, `AdminVotacionController`, `AdminReservasController`, `AdminPagosController`, `ResidenteAnuncioController`, `ResidenteVotacionController`

#### B. BaseApiService (Flutter)

**Patrón duplicado (14+ servicios):**
```dart
if (res.statusCode == 200) {
  final body = jsonDecode(res.body) as List;
  return body.map((e) => MyModel.fromJson(e)).toList();
}
final body = jsonDecode(res.body);
throw Exception(body['message'] ?? 'Error genérico');
```

**Solución:**
```dart
// core/services/base_api_service.dart
class BaseApiService {
  static List<T> parseList<T>(res, fromJson, fallbackMsg) { ... }
  static T parseSingle<T>(res, fromJson, {successCodes, fallbackMsg}) { ... }
  static void assertSuccess(res, {successCodes, fallbackMsg}) { ... }
}
// Uso:
return BaseApiService.parseList(res, MyModel.fromJson, 'Error al cargar');
```
**Aplicado en:** `UsuarioService` (completado). Pendiente: 13 servicios restantes.

#### C. ApiException (Flutter)

**Antes:**
```dart
} catch (e) {
  setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
}
```

**Después:**
```dart
} catch (e) {
  setState(() => _error = ApiException.extract(e));
}
```

#### D. AppToast (Flutter)

**Antes (3 patrones distintos):**
```dart
// Patrón 1
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
// Patrón 2
toastification.show(context: context, type: ToastificationType.success, ...);
// Patrón 3
ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: Duration(seconds: 5), ...));
```

**Después:**
```dart
AppToast.success(context, 'Operación exitosa');
AppToast.error(context, e);
AppToast.info(context, 'Sin conexión');
```

#### E. CurrencyFormatter (Flutter)

**Antes:**
```dart
String _fmt(num v) => '\$${v.toInt().toString().replaceAllMapped(...)}';
```
Duplicado en múltiples pantallas de pagos.

**Después:**
```dart
CurrencyFormatter.cop(valor)       // $1.234.567
CurrencyFormatter.copFromString(s) // null-safe
CurrencyFormatter.parse(text)      // String → double
```

---

### UX/UI

- Pantalla de aprobación de usuario: ahora pregunta "Aprobar como Residente o Propietario?" antes de ejecutar la acción
- Etiquetas de rol mejoradas: `_etiquetaRol` cubre todos los roles incluyendo `PROPIETARIO`, `INQUILINO`, `RESIDENTE_PENDIENTE`
- `MisInquilinosScreen`: estado vacío explícito, estado de error, RefreshIndicator, confirmación antes de eliminar

---

## 3. Próximos Pasos (Priorizados)

| # | Tarea | Impacto | Esfuerzo |
|---|-------|---------|----------|
| 1 | Aplicar `BaseApiService` a los 13 servicios restantes | Alto | Bajo |
| 2 | Reemplazar `ScaffoldMessenger`/toastification por `AppToast` en ~44 screens | Alto | Medio |
| 3 | Reemplazar `_fmt()` por `CurrencyFormatter` en pantallas de pagos | Medio | Bajo |
| 4 | Fix N+1 en `DashboardService` (múltiples `findAll()` completos) | Alto | Medio |
| 5 | Agregar `@Transactional` a otros métodos críticos de escritura | Medio | Bajo |
| 6 | Test de integración para `PropietarioService` (crear/eliminar inquilino) | Alto | Alto |

---

*Generado: 2026-05-17 | Stack: Spring Boot + Flutter | Proyecto: Conjuntos Residenciales Multitenant*
