# Director's Notes · My CR Launch Film (25s · 16:9)

> Escrito antes de animar — regla #1 del workflow huashu-design launch-film.
> 5 partes: Statement / Visual System / Story Arc / Storyboard / Manifest.

---

## 1. Statement

**Qué vendemos**: una app que reemplaza el grupo de WhatsApp del conjunto, el archivo Excel del administrador y la libreta del recibo de pago — con algo que se siente como tu vida cotidiana, no como un sistema empresarial.

**A quién**: residentes que viven en conjuntos cerrados en Latinoamérica (Colombia foco, donde nació el producto). Tienen entre 28 y 55 años, son propietarios o inquilinos con permisos. Hoy reciben fotos del recibo por WhatsApp, hacen pagos en bancos físicos o por links sueltos, y no saben cuándo está la reserva del salón social. Quieren que "esto sea más fácil" sin tener que aprender una herramienta nueva.

**Cómo deben sentirse al final**: "Quiero que mi conjunto use esto." Confort + alivio + un poco de orgullo. NO emoción de SaaS B2B, NO emoción de fintech agresiva. La emoción target es la misma que da llegar a tu casa y encontrar que alguien dejó la luz prendida.

**Reto principal**: el producto es funcional y útil, pero la categoría es aburrida ("software para administración de conjunto"). El film tiene que **vender el mood, no las features**. Las features son la prueba; el mood es el gancho.

---

## 2. Visual System

### Paleta del film (NO la del app — ver `brand-spec.md`)

| Rol | HEX | Uso |
|---|---|---|
| Background base cálido | `#F7F1E8` | Fondo entero del canvas |
| Background secundario | `#FBF8F2` | Variaciones sutiles |
| Tinta serif | `#1F1A14` | Tagline + copy hero |
| Tinta secundaria | `#5A4E3F` | Subtítulos |
| Acento cálido | `#C9764E` | 1 highlight emocional (corazón del cierre) |
| Acento marca (preserved) | `#005F8F` | Sólo cuando el iPhone es protagonista, dentro de mockups |

### Tipografía

- **Newsreader** (serif, Google Fonts) — display hero y tagline. Pesos 400/500/600. Italic disponible.
- **Google Sans** (sans, local) — dentro de mockups del app, fiel al producto real.
- **JetBrains Mono** (mono, Google Fonts) — solo el cursor del typewriter en login.

### Iconografía

- Material Icons via inline SVG dentro de mockups (apartment_rounded, email, lock, account_balance_wallet, event, etc.) — fieles al app.
- **NO** iconos decorativos fuera de los mockups. El fondo cálido y la tipografía cargan el mood; no se agregan iconos sueltos.

### Motion language (8 reglas para este film)

1. **Hero element persistente**: el iPhone existe desde t=3.0s hasta t=22.0s sin desmontarse. Lo que cambia es su contenido (morphea), su posición (sutil), su escala (respiración).
2. **Easing principal**: `expoOut` (`cubic-bezier(0.16, 1, 0.3, 1)`) — usado en 80% de transiciones.
3. **Easing secundario**: `overshoot` para botones presionados y celebraciones.
4. **Duraciones base**: transiciones de cámara 800ms, micro-interactions 200–400ms, typewriter 80–150ms/char.
5. **Sin cortes duros**: cuando una escena termina, el siguiente elemento ya está apareciendo (overlap 200–400ms).
6. **Stagger**: cards del dashboard aparecen con offset de 80ms entre ellas, NO todas a la vez.
7. **Cámara**: el iPhone se mueve max 12% del frame (sutil "respiración"). Nada de zooms agresivos.
8. **Watermark del logo CR**: aparece en esquina inferior derecha desde t=8s en adelante, opacity 0.4, never dominant.

### Reglas de composición

- **Regla del tercio horizontal**: el iPhone vive ligeramente a la derecha del centro (x ≈ 58% del canvas). El espacio izquierdo es para tagline/copy.
- **Aire generoso**: padding del iPhone vs bordes del canvas ≥ 140px (en 1920×1080).
- **Sombra del iPhone**: blur 60px, offset y=40px, opacity 0.18, color warm `#2B1F0E`. NO sombra negra.

---

## 3. Story Arc (25s, 5 actos)

### Acto I · Hook (0–3s) · "Entrar al mundo"

- t=0.0–0.5s: Fade-in del fondo crema desde negro suave (NO negro puro). Sin tagline aún.
- t=0.5–1.2s: Aparece "Tu conjunto." en serif grande, izquierda-centro, font-weight 500. Slide-up + opacity 0→1 con expoOut 800ms.
- t=1.2–2.0s: Aparece ". En tu mano." en la misma línea, completando la frase. Stagger natural.
- t=2.0–3.0s: La frase se mantiene, sutil drift hacia arriba (max 8px), preparando entrada del iPhone.

**Sentimiento**: ligereza, no urgencia. Como abrir un libro.

### Acto II · Login con typewriter (3–7s) · "Soy yo"

- t=3.0–3.3s: iPhone entra desde abajo del frame, posicionado ligeramente a la derecha. Easing expoOut, 700ms. La frase del hook se reposiciona arriba-izquierda y reduce a 60% size.
- t=3.3–3.5s: Render de login screen vacío dentro del iPhone (logo apartment, título "My Conjunto Residencial", form con inputs).
- t=3.5–5.0s: **Typewriter del email** "ana@torres.co" — 12 caracteres a ~125ms cada uno. Cursor mono parpadea. SFX `keyboard/type.mp3` por char.
- t=5.0–5.2s: Tab visual (focus salta al password input).
- t=5.2–6.5s: **Typewriter del password** — 8 dots `••••••••` apareciendo uno por uno a ~160ms. SFX `keyboard/type.mp3` más suave.
- t=6.5–6.9s: Botón "Ingresar" presiona (scale 0.97 → 1.02 con overshoot). SFX `keyboard/enter.mp3`.
- t=6.9–7.0s: Flash sutil de loading (spinner 0.1s).

**Sentimiento**: identidad. "Este es MI conjunto."

### Acto III · Dashboard residente (7–12s) · "Mi día arranca bien"

- t=7.0–7.3s: Transición login→dashboard dentro del iPhone (NO se cambia el iPhone, solo su contenido). SFX `transition/whoosh.mp3`. Fade + slide-up sutil.
- t=7.3–7.6s: Header "Hola, Ana" aparece arriba del dashboard.
- t=7.6–8.5s: **DeudaResumenWidget verde** "¡Todo al día! 🎉" aparece grande, con stagger natural (icono check primero, luego texto, luego CTA outline).
- t=8.5–11.5s: Cards "Accesos rápidos" caen en cascada (stagger 100ms):
  - Estado de Cuenta (azul `#005F8F` icon, bg `#E6F7FF`)
  - Reservas (orange icon, bg `#FFEDE0`)
  - PQRs (purple icon, bg `#F9E6FF`)
  - Anuncios (yellow icon, bg `#FFFBE6`)
  - Votaciones (green icon, bg `#E6FFF3`)
- t=11.5–12.0s: Mano/cursor virtual hace hover sobre "Estado de cuenta", se prepara para el tap.

**Side composition** (fuera del iPhone): tagline secundario aparece a la izquierda en serif 32px: "Tu hogar, organizado."

**Sentimiento**: control sin esfuerzo. "Todo en un solo lugar."

### Acto IV · Pagos + Reservas (12–21s) · "Y funciona"

#### Pagos (12–17s)
- t=12.0–12.3s: Tap en "Estado de cuenta". SFX `ui/tap-finger.mp3`. Card hace press feedback (scale 0.98).
- t=12.3–13.0s: La card se expande/morphea hacia pantalla completa (NO transición de modal estándar — crece desde la posición de la card).
- t=13.0–14.0s: Aparece estado de cuenta: lista de cobros, monto destacado "$280.000" en blue `#005F8F`, botón primario "Pagar cuota".
- t=14.0–14.3s: Tap en "Pagar cuota". Bottom sheet con pasarela (Wompi mock simplificado) sube desde abajo.
- t=14.3–14.8s: Pasarela se procesa visualmente (barra de progreso 500ms).
- t=14.8–15.5s: **Success state**: check verde grande con scale spring 0→1.1→1, glow warm orange por 400ms. SFX `feedback/success-chime.mp3`. Texto "Pago realizado".

**Side copy** (fuera del iPhone): "Sin filas. Sin bancos."

#### Reservas (17–21s)
- t=17.0–17.3s: Transición rápida dentro del iPhone hacia mis_reservas. SFX `transition/swipe-horizontal.mp3`.
- t=17.3–18.5s: Calendario simplificado aparece (mes actual, días, día sábado 15 marcado como disponible para "Salón social").
- t=18.5–19.0s: Tap en "Salón social · Sábado 15 · 6pm". Card resalta, SFX `ui/tap-finger.mp3`.
- t=19.0–19.5s: Confirmación con check + texto "Reservado". SFX `feedback/notification-pop.mp3`.
- t=19.5–21.0s: El iPhone se aleja sutilmente (scale 1.0 → 0.92), permitiendo que el fondo cálido respire.

**Side copy**: "Tu salón. A un toque."

**Sentimiento**: prueba. "Esto SÍ funciona."

### Acto V · Cierre con marca (21–25s) · "Quédate"

- t=21.0–21.5s: iPhone se desplaza hacia la derecha y baja opacity a 0.0 (sale de escena). El fondo cálido se vuelve ligeramente más oscuro/profundo (`#F7F1E8` → `#EDE3D2`, simulando atardecer).
- t=21.5–22.0s: Logo CR (logocr.png) aparece centrado, escala 0→1 con expoOut 500ms. SFX `impact/logo-reveal.mp3`.
- t=22.0–23.0s: Tagline serif "My CR" en `Newsreader` weight 600, debajo del logo.
- t=23.0–24.0s: Sub-tagline "Tu conjunto. En tu mano." en weight 400 italic.
- t=24.0–25.0s: Aparece sutilmente un footer "myconjuntoresidencial.com · Disponible en iOS y Android" (sin badges grandes — minimal).

**Sentimiento**: cierre tranquilo. Como apagar la luz al final del día.

---

## 4. Storyboard (12 shots clave)

| # | t | Composición | Hero element | Anti-slop check |
|---|---|---|---|---|
| 1 | 0.5s | Fondo crema vacío + tagline serif izquierda | Tipografía | ✅ sin emoji, sin gradient violet |
| 2 | 2.5s | Tagline completa + sombra de iPhone subiendo | Tipografía + hint del phone | ✅ sin filler stats |
| 3 | 4.0s | iPhone full, login en pantalla, typewriter a mitad de email | Typewriter live | ✅ sin "stats slop" |
| 4 | 6.5s | Botón "Ingresar" se presiona, micro-feedback | Botón + haptic visual | ✅ sin SVG faces |
| 5 | 8.5s | Dashboard con DeudaResumen y primeras 2 cards | Cards stagger | ✅ icons del Material real (no emoji decorativo) |
| 6 | 11.0s | Dashboard completo con todas las cards + cursor hover | Stack completo | ✅ side copy serif equilibra densidad |
| 7 | 13.5s | Estado de cuenta abierto, monto grande | Tipografía $280.000 en `#005F8F` | ✅ azul preservado solo en data, no en fondo |
| 8 | 15.0s | Success state pago, check + glow warm | Check spring | ✅ glow warm `#C9764E` no violet |
| 9 | 18.0s | Calendario reservas + slot disponible | Calendario simple | ✅ sin gradient en celdas |
| 10 | 19.5s | "Reservado" confirmación pop | Pop chip | ✅ sin confetti slop |
| 11 | 22.0s | Logo CR centrado, fondo más profundo | Logo | ✅ logo real del proyecto, no recreado |
| 12 | 24.5s | Frame final: logo + tagline + footer URL | Marca completa | ✅ sin "badges" app store gigantes |

---

## 5. Manifest

### Archivos del producto a leer/copiar

| Asset | Origen | Destino |
|---|---|---|
| Logo CR | `assets/icons/logocr.png` | `_promo_video/assets/logocr.png` ✅ copiado |
| Google Sans Regular/Medium/Bold | `assets/fonts/GoogleSans-*.ttf` | `_promo_video/assets/fonts/` ✅ copiado |
| Login screen UI ref | `lib/features/auth/screens/login_screen.dart` | (lectura) ✅ |
| Dashboard residente UI ref | `lib/features/home/residente/residente_dashboard_screen.dart` | (lectura) ✅ |
| Deuda resumen UI ref | `lib/features/home/residente/widgets/carousel/deuda_resumen_widget.dart` | (lectura) ✅ |
| Tema y colores | `lib/shared/theme/app_theme.dart` | (lectura) ✅ |

### Skill assets a usar

| Asset | Path | Uso |
|---|---|---|
| Stage + Sprite + useTime + Easing | `.claude/skills/huashu-design/assets/animations.jsx` | Inline en HTML |
| IosFrame | `.claude/skills/huashu-design/assets/ios_frame.jsx` | Inline en HTML |
| BGM educational | `.claude/skills/huashu-design/assets/bgm-educational.mp3` | Mezcla final |
| SFX (9 archivos) | `.claude/skills/huashu-design/assets/sfx/...` | Cues timeline |
| render-video.js | `.claude/skills/huashu-design/scripts/render-video.js` | Render MP4 |
| add-music.sh | `.claude/skills/huashu-design/scripts/add-music.sh` | Mezcla BGM |

### Entregables

- `_promo_video/promo-launch-film.html` — HTML único con todo inline
- `_promo_video/output/promo-launch-film.mp4` — render silente (intermedio)
- `_promo_video/output/promo-launch-film-bgm.mp4` — final con BGM
- `_promo_video/output/promo-final.mp4` — final con BGM + SFX mezclados (entregable real)

### Dependencias técnicas

- Node.js + Playwright global (`npm install -g playwright`)
- ffmpeg en PATH
- Navegador Chromium (lo trae Playwright)

### Watermark

Se mantiene el watermark "Created by Huashu-Design" en esquina inferior izquierda con opacity 0.35 — política default de la skill para piezas de animación. Si el usuario lo pide quitar antes del render final, se quita en una línea del HTML.

---

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Sin screens reales del Flutter, mockups pueden divergir del producto | Mockups basados en lectura literal del código (paleta, layout, iconos, copy) — están "fieles" al app, no inventados |
| 25 segundos es justo para 5 actos | Acto III y IV comparten varios elementos (iPhone persiste); transiciones overlap reducen "vacíos" |
| Typewriter con dependencia de fonts (FOIT) | `window.__ready = true` se setea tras `document.fonts.ready`, alineado con Stage de la skill |
| SFX no se sincronizan en `add-music.sh` (solo BGM) | Se mezclan con un segundo pase `ffmpeg -filter_complex amix` con cues posicionados en su `t` — script `mix-sfx.sh` adaptado |
| Loop accidental en preview | Stage detecta `window.__recording = true` y fuerza loop=false durante render |

