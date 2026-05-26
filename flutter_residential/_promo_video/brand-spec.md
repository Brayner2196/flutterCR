# My CR · Brand Spec (para Launch Film)

> Compilado: 2026-05-23
> Fuente: código fuente del proyecto `flutter_residential` (autoridad: `lib/shared/theme/app_theme.dart`, `lib/features/auth/screens/login_screen.dart`, `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`)
> Completitud: alta — todos los assets críticos vienen del repo, sin invención.

## Identidad

| Campo | Valor | Origen |
|---|---|---|
| Nombre comercial corto | **My CR** | `AndroidManifest.xml` `android:label` |
| Nombre largo | **My Conjunto Residencial** | `login_screen.dart` l.133 |
| Categoría | App de gestión residencial multitenant | exploración de módulos |
| Rol protagónico del video | **Residente** | decisión del usuario |
| Tagline propuesto | "Tu conjunto. En tu mano." | nuevo, derivado del posicionamiento |

## 🎯 Assets de primera clase

### Logo
- Principal: `assets/logocr.png` (copiado de `assets/icons/logocr.png` del proyecto)
- Uso: hook 0–3s sutil, cierre 21–25s grande centrado, esquina inferior en todas las escenas como watermark sutil

### Mockups de pantallas
**No se capturan screenshots reales del Flutter en este pase** porque arrancar Flutter web en este entorno requiere setup adicional. Se reconstruyen mockups fieles dentro del HTML usando React/CSS basados en lectura del código real:
- `login_screen.dart` → mockup login (gradiente azul claro, logo apartment_rounded sobre cuadrado primary, card con form, label "Bienvenido", inputs con icons email/lock, botón "Ingresar" primary fill)
- `residente_dashboard_screen.dart` + `deuda_resumen_widget.dart` → mockup dashboard (DeudaResumenWidget verde "¡Todo al día! 🎉" + sección "Accesos rápidos" con QuickAccessCards de Estado de Cuenta, Reservas, PQRs, Anuncios, Votaciones)
- Pagos → mockup con monto destacado + botón "Pagar cuota" + success state
- Reservas → calendario simplificado + slot "Salón social · Sábado 15" + confirmación

## 🎨 Assets de apoyo

### Paleta (basada en `app_theme.dart` real, ajustada al mood cálido/humano elegido)

**Base del app (autoridad)**:
- `blue` primary: `#005F8F`
- `bgBlue`: `#E6F7FF`
- `ok` verde: `#3F7A4F`, `okSoft`: `#E4EDE3`
- `orange`: `#B45000`, `bgOrange`: `#FFEDE0`
- `yellow`: `#8C6D00`, `bgYellow`: `#FFFBE6`
- `green` (módulo): `#00694A`, `bgGreen`: `#E6FFF3`
- `purple`: `#6E2891`, `bgPurple`: `#F9E6FF`
- `teal`: `#00695C`, `bgTeal`: `#E0F7F4`
- `bgLight`: `#FFFFFF`, `surfaceLight`: `#F9F9F9`
- `textHiLight`: `#191C1E`, `textMidLight`: `#515F74`

**Ajustes cálidos del launch film** (Notion/Airbnb vibe):
- Background principal del film: crema cálido `#F7F1E8` (no blanco puro) — temperatura ~3500K visual
- Acento de calidez emocional: terracota `#C9764E` (para highlights de "comunidad/hogar")
- Tinta de copy serif: `#1F1A14` (warm black, no negro)
- El azul `#005F8F` se conserva DENTRO de los mockups del app (fidelidad) pero NO domina el fondo

**Regla**: dentro del iPhone, los colores son fieles al app real. FUERA del iPhone (fondos, tipografía hero, watermark), paleta cálida.

### Tipografía

| Rol | Fuente | Source | Uso |
|---|---|---|---|
| Hero serif display | **Newsreader** | Google Fonts (CDN) | Tagline 0–3s y 21–25s |
| UI sans (dentro del app) | **Google Sans** | `assets/fonts/GoogleSans-*.ttf` copiadas | Toda la UI dentro del iPhone (fiel al app) |
| Mono (typewriter cursor) | **JetBrains Mono** | Google Fonts | Cursor parpadeante del email durante typewriter |

### Firma de detalle ("120%")

El typewriter de login: cada carácter cae con micro-easing (overshoot mínimo), cursor parpadea a 530ms, sonido `keyboard/type.mp3` por cada char. Esto es el "wow moment" que justifica todo lo demás siendo 80%.

### Prohibiciones

- ❌ Negro puro `#000` (usar `#1F1A14`)
- ❌ Gradiente púrpura/violeta (slop)
- ❌ Emoji como iconos de UI (excepto el 🎉 del "¡Todo al día!" que ya está en el app)
- ❌ Sombras dramáticas oscuras (el mood es claro/cálido)
- ❌ Inventar nuevos colores fuera de la paleta listada arriba

### Keywords de mood

cálido · doméstico · confiable · tranquilo · cotidiano · luminoso

## 🎵 Audio

### BGM
- Pista: `bgm-educational.mp3` de la skill (`.claude/skills/huashu-design/assets/`)
- Razón: "warm, patient, inviting learning tone" — encaja con mood cálido elegido
- Mezcla: -18 dB, fade-in 0.3s, fade-out 1.0s (manejado por `add-music.sh`)

### SFX cues (timeline)

| t (s) | SFX | Archivo skill | Evento |
|---|---|---|---|
| 3.3 | type loop | `sfx/keyboard/type.mp3` | Cada char del email (10 chars × ~150ms) |
| 5.0 | type loop | `sfx/keyboard/type.mp3` | Cada dot del password (8 chars × ~120ms) |
| 6.8 | enter | `sfx/keyboard/enter.mp3` | Botón "Ingresar" presionado |
| 7.1 | whoosh | `sfx/transition/whoosh.mp3` | Transición login→dashboard |
| 12.0 | tap-finger | `sfx/ui/tap-finger.mp3` | Tap en "Estado de cuenta" |
| 14.8 | success-chime | `sfx/feedback/success-chime.mp3` | Pago confirmado |
| 17.2 | swipe | `sfx/transition/swipe-horizontal.mp3` | Cambio a reservas |
| 19.5 | notification-pop | `sfx/feedback/notification-pop.mp3` | Reserva confirmada |
| 22.0 | logo-reveal | `sfx/impact/logo-reveal.mp3` | Cierre con logo |

**Total: 9 cues distribuidos en 25s**, densidad media. Sin voz off, sin ducking (no hay narración que proteger).
