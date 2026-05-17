# Handoff: Companion Claim Flow

## Overview

Tato handoff dokumentace popisuje **claim flow pro odemčení tajemných společníků** v aplikaci Forgetrack. Když uživatel splní podmínky (např. „Buď aktivní 7 dní nebo dokonči 3 denní úkoly"), v inventáři Kosmetika se zpřístupní uzamčená dlaždice. Po otevření detailu uvidí stav **PŘIPRAVEN**, tlačítkem **Vyzvedni společníka** spustí krátký rituál (5,4 s), ze kterého se zhmotní konkrétní společník (např. *Jiskřička*) — a poté pokračuje do běžného detailu, kde si ho může **Vybavit** nebo **Přivolat**.

## About the Design Files

Soubory v tomto balíčku jsou **design reference vytvořené v HTML/React (Babel) prototypu** — slouží jako vizuální specifikace zamýšleného vzhledu a chování animace. **Nejsou určeny k přímému nasazení do produkce.** Cílem je tyto designy znovu sestavit v cílovém prostředí aplikace Forgetrack (zřejmě Flutter — viz screenshoty s Material status bar) a využít existující komponenty, design tokens a animační knihovny (Flutter animations / Rive / Lottie podle potřeby). Pokud cílový stack ještě není zvolen, prototyp pomůže rozhodnout, jaký renderer / animační systém je vhodný.

## Fidelity

**High-fidelity (hifi).** Layout, barvy, typografie, časování a easing křivky odpovídají zamýšlené finální podobě. Vývojář by měl reprodukovat 1:1 s odchylkou max. na úrovni typografie / ikon, pokud existující design systém diktuje jiné. Velikosti částic, počet emitovaných sparků a délky fází jsou laděné — neupravovat bez explicitního důvodu.

## Layout: Obrazovka Kosmetika (pozadí)

Statické pozadí, není součástí tohoto flow, ale prototyp ho rekonstruuje pro kontext.

- **Top app bar:** back arrow 40×40 (rounded 12), title `Kosmetika` (Inter 26/700)
- **Section "VYBAVENO"** (eyebrow): Inter 12/700, letter-spacing 1.4, color `#7B7AFB`, with sparkle icon prefix
- **3 vybavené karty** v gridu 3×1, gap 10 — každá rounded 18, padding `14 10 10`, min-height 168
  - Border barva podle stavu rámečku (`red` `#E54C4C` / `green` `#4CAF6D`), background tlumený toho samého odstínu (~8 % alpha)
  - Pravý horní roh: 22×22 zaškrtnutý kruh s ✓
- **Section "INVENTÁŘ"** stejný styl jako VYBAVENO
- **TabBar** rounded 24, padding 6, items: Vše / Rámeček / Pozadí / **Společník** (aktivní = lila accent pill)
- **Inventory grid 3×N** s gap 10 — uzamčená dlaždice ukazuje 🔒 ikonu a label `Tajemný společník` v `#6B7193`

## Stavy a flow

Komponenta `<CompanionClaim>` má **state machine se 4 fázemi**:

```
ready → forging → morphing → detail
                              ↑ (reset → ready)
```

### Stav 1: `ready` — sheet "PŘIPRAVEN"

Bottom sheet, height auto, slides up z původního screenu. Background `#171A2E`, border-radius 28 nahoře, padding `14 22 28`.

- Drag handle 56×5, rounded 3, `rgba(255,255,255,0.18)`
- Eyebrow: `PŘIPRAVEN` Inter 12/700, color accent `#7B7AFB`, letter-spacing 1.6, centered
- Title: `Tajemný společník` Inter 30/700, white, centered
- Subtitle: `Spojí potřebné relikvie. Vyzvedni jej v detailu.` 15/400 `#9AA0BF`, line-height 1.5
- **Preview area** (height 200, centered):
  - Vnější dýchající kruh 160×160, border 1px `rgba(255,255,255,0.10)`, gradient `rgba(123,122,251,0.10)` → transparent. Animace `breathe` 2.6s ease-in-out infinite (scale 1↔1.08, opacity 0.6↔1)
  - Vnitřní paw silhouette 110×110 placeholder
  - Dvě relikvie po stranách (70×70 a 84×84) s float animacemi (`floatA` `floatB` 3.4s) a drop-shadows
- **Relic chips** pod preview: rounded 100, gap 8, 28×28 ikona + název + ✓ checkmark
- **Primary CTA** `Vyzvedni společníka`: full-width, height 60, rounded 18, bg `#E9EAF5`, text `#0C0F1E` Inter 17/700, sparkle ikona vlevo, shadow `0 10px 30px rgba(123,122,251,0.18)`

### Stav 2: `forging` — animační overlay (5,4 s)

Fullscreen overlay přes celou plochu. Tři přepínatelné varianty animace:

#### Varianta A: **Orbita** (default)

| t (ms) | fáze | popis |
|---|---|---|
| 0–600 | fly-in | Relikvie se přesunou ze sheet pozic do orbity (±80 px od středu) |
| 600–2400 | orbit + spiral | Relikvie obíhají střed, zrychlují (turns ≈ 2.5), poloměr `lerp(80, 0, easeInOut)` |
| 2400–2700 | pull-to-center | Relikvie se stáhnou ke středu, scale 1→0.3 |
| 2700–3100 | burst | Částice (60 ks × intensity) vystřelí ven, **bez full-screen flash kroužků** |
| 2700–3300 | aura bloom | Úzká zlatá aura blooming od středu |
| 2800–4800 | sprite materialize | Společník roste: scale 0.12→1 (easeOut), opacity `pow(x, 1.6)`, blur 14→0 px, rise 40→0 px |
| 2800–4750 | converging wisps | Zlatě svítící wispy létají ze vzdálenosti 150 px do středu |
| 4800–5400 | settle | Idle float (sin wobble ±6 px, 350 ms perioda) |
| 5400 | onComplete → morphing | |

#### Varianta B: **Fontána**

Relikvie spadnou do centrální „studny", ze které vystřelí geyser jisker. Z apexu se materializuje společník.

| t (ms) | fáze |
|---|---|
| 0–900 | drop (relikvie padají dolů, scale 1→0) |
| 900–1800 | well charge (pulsující elliptický glow) |
| 1800–3400 | geyser column + sparks (~80 částic × intensity, gravity -260) |
| 2200–3000 | aura bloom |
| 2400–4500 | sprite materialize (start cy+20, end y=0.4×screen, scale 0.12→1) |
| 4500–5400 | settle |

#### Varianta C: **Náraz** (shatter)

Relikvie chargují s rostoucím chvěním, slamnou do sebe, prasklina vyzáří paprsky.

| t (ms) | fáze |
|---|---|
| 0–1300 | charge (relikvie se přibližují + chvějí, shake amplituda roste kvadraticky) |
| 1300–1700 | slam (kolize) |
| 1700–2300 | crack rays (12 SVG paprsků z centra) + ~50 shard částic |
| 2100–2700 | aura bloom |
| 2300–4700 | sprite materialize |
| 4700–5400 | settle |

> **Důležité:** „Výbuchové" kroužky přes celou obrazovku byly explicitně odstraněny po review. Žádný full-screen ring shockwave. Pouze částice + cracky/wispy.

#### Status text během animace

Centered, ~18 % od spodu obrazovky:

- t < 600: `Připravuji rituál…` (Inter 15/500, `#9AA0BF`)
- t < 2400: `Spojuji relikvie…`
- t < 2900: (skryto)
- t < 4700: `Probouzím společníka…`
- t ≥ 4700: `Jiskřička` (Inter 30/700, bílá, textShadow `0 0 20px rgba(255,180,80,0.4)`) + sub `Tvůj nový společník`

### Stav 3: `morphing` — přechod overlay→sheet (1,2 s)

Critical handoff fáze. Společník hladce přejde z overlay středu do slot pozice v detail sheetu:

- **Source:** střed obrazovky, 220×220 px, drop-shadow 12px
- **Destination:** levý horní roh detail sheetu, 130×130 px (pozice `(87, sheet_top + 35 + 65)` v px), drop-shadow 8px
- **Transition:** CSS `transition: left/top/transform 1150ms cubic-bezier(.22,.8,.2,1)`
- **Detail sheet** současně vyjede ze spodu (1,1 s, stejná křivka)
- **DetailSheet** během morphu má `hideCompanion={true}` — slot je tam, ale obrázek schovaný
- **Render order:** `MorphTransition` se renderuje **AFTER** `DetailSheet` v DOM, aby společník byl nad vysunujícím se sheetem (jinak by problikl)
- Po 1200 ms → `setPhase('detail')`, MorphTransition odejde, DetailSheet ukáže svůj nativní companion image (na identické pozici, takže přechod neviditelný)

### Stav 4: `detail` — detail společníka

Bottom sheet, height auto. Identická pozice jako ready sheet.

- **Levý sloupec:** 130×130 box s radial gradient bg, uvnitř ember sprite 130×130 s idle float animací (`companionIdle` 3.2s)
- **Pravý sloupec:**
  - Title: `Jiskřička` Inter 26/700
  - Tagy: `Společník` + `Běžné` v rounded 100 pillech (border `rgba(255,255,255,0.08)`, padding `5 12`)
  - Datum odemčení: `Odemčeno {dnes}.` 12/500 `#6B7193`
- **Description:** `Malá jiskra, která doprovází ty, kdo udrží tempo.` 15/400 `#9AA0BF`, line-height 1.55
- **Perk badge:** rounded 14, bg `rgba(123,122,251,0.08)`, border `rgba(123,122,251,0.18)`, sparkle + `+5 % zkušeností za dokončené denní úkoly`
- **Action row** (gap 10):
  - 56×56 ghost button: reset / přehrát znovu (refresh ikona)
  - 56×56 ember-tinted button: přivolat (flame ikona, bg `rgba(255,140,42,0.12)`, color `#FF8C2A`)
  - Flex-1 primary `Vybavit`: 56 height, bg `#E9EAF5`, check + label Inter 16/700

## Design Tokens

### Colors

```
bg              #0B0D1A   primary screen bg
bgSheet         #171A2E   sheet bg
bgSheetSoft     #1D2138   secondary panel bg
card            #1A1E34
cardLocked      #23273D   locked inventory slot
cardBorder      rgba(255,255,255,0.06)
cardRedBorder   rgba(229,76,76,0.55)
cardRedBg       rgba(229,76,76,0.08)
cardGreenBorder rgba(76,175,109,0.55)
cardGreenBg     rgba(76,175,109,0.08)

text            #FFFFFF
textDim         #9AA0BF
textMuted       #6B7193

accent          #7B7AFB   (eyebrow + active tab + perk border)
accentSoft      rgba(123,122,251,0.18)

ember           #FF8C2A   (companion glow + summon button)
emberBright     #FFD166   (particles + sparks)

red             #E54C4C
green           #4CAF6D

btnLight        #E9EAF5   (primary CTA bg)
btnLightText    #0C0F1E
```

### Typography

Family: **Inter** (Google Fonts, weights 400/500/600/700/800). Fallback `system-ui, sans-serif`.

| Use | Size / Weight | Letter-spacing |
|---|---|---|
| Page title | 26 / 700 | 0 |
| Sheet title | 30 / 700 | 0 |
| Eyebrow (uppercase) | 12 / 700 | 1.4–1.6 |
| Body | 15 / 400, lh 1.5–1.55 | 0 |
| Status text (loading) | 15 / 500 | 0.3 |
| Status text (reveal name) | 30 / 700 | 0 |
| Card label | 11 / 600 | 0 |
| Tag | 12 / 500 | 0 |
| Primary CTA | 17 / 700 | 0 |

### Spacing & radii

- Spacing scale: 4, 6, 8, 10, 12, 14, 16, 18, 22, 28
- Card radius: 18 (inventory cards), 20 (companion preview box)
- Sheet radius: 28 (top corners only)
- Pill / tag radius: 100
- Button radius: 16 (square actions), 18 (primary CTA)

### Animation curves

```
easeOut       1 - (1-t)³
easeIn        t³
easeInOut     piecewise cubic
easeBack      t > 1 + (s+1)(t-1)³ + s(t-1)²   (NOT used for companion entrance — gave a pop)
cubic-bezier(.22, .8, .2, 1)   used for morph + sheet rise
cubic-bezier(.2, .7, .2, 1)    used for sheet-in
```

### Companion entrance formula (all variants)

```ts
spriteReveal ∈ [0, 1]            // linear 0→1 over ~2000-2400 ms
scale   = lerp(0.12, 1, easeOut(spriteReveal))
opacity = spriteReveal ** 1.6     // gentle ease-in
blur    = lerp(14, 0, easeOut(spriteReveal)) // px
filter: drop-shadow(0 12px 32px rgba(255,140,42, 0.55 * opacity)) blur(<blur>px)
```

## Interactions

- **Tap `Vyzvedni společníka`** → krátký vizuální „haptic pulse" (visual only — v cílovém Flutter použít `HapticFeedback.mediumImpact()`), poté přechod do `forging`
- **Žádné dotyky během `forging`/`morphing`** — pointer-events: none na overlay (přeskočení/zkrácení neexistuje)
- **Tap reset** (refresh icon v detail sheetu) → `setPhase('ready')`
- **Idle float** společníka v detail sheetu — `companionIdle` keyframes (translateY ±6, rotate ±2)
- **autoReplay** tweak: pokud aktivní, po 2,4 s v `detail` stavu automaticky `reset`

## State Management

```ts
type Phase = 'ready' | 'forging' | 'morphing' | 'detail';

const [phase, setPhase] = useState<Phase>('ready');

// Trigger
const startClaim = () => setPhase('forging');

// ClaimOverlay drives forging→morphing internally at t=5400ms
<ClaimOverlay onComplete={() => setPhase('morphing')} />

// Morph auto-advances
useEffect(() => {
  if (phase === 'morphing') {
    const id = setTimeout(() => setPhase('detail'), 1200);
    return () => clearTimeout(id);
  }
}, [phase]);
```

V produkci doporučuji animaci řídit přes přesnou timeline (Flutter `AnimationController` s `Duration(milliseconds: 5400)` + sequenced `Interval`s). Speed multiplier (tweak `speed`) se pak aplikuje na `controller.duration`.

## Assets

V `assets/` jsou tři PNG s alpha kanálem (~83-66 % transparentní):

| Soubor | Rozměr | Účel |
|---|---|---|
| `campfire_spark.png` | 300×300 | Relikvie „Jiskra ohniště" |
| `warm_kindling.png` | 320×320 | Relikvie „Teplé třísky" |
| `ember_sprite.png` | 1024×1024 | Společník Jiskřička |

Pro produkci doporučuji:
- Připravit @1×/@2×/@3× varianty (cílit Android xhdpi/xxhdpi/xxxhdpi)
- Pro Flutter: vložit do `assets/companions/jiskricka/` a `assets/relics/`
- Zvážit Rive/Lottie pro idle animaci společníka (sprite oscillation + záře pulsace), pokud je potřeba vyšší produkční kvalita než `Transform.translate` + sin wobble

## Files

```
design_handoff_companion_claim/
├── README.md                  ← this file
├── Companion Claim.html       ← main entry, state machine + Tweaks panel
├── app.jsx                    ← Kosmetika background screen
├── sheets.jsx                 ← ReadySheet + DetailSheet
├── claim.jsx                  ← ClaimOverlay (3 variants) + MorphTransition + helpers
├── android-frame.jsx          ← prototype device frame (REMOVE in production)
├── tweaks-panel.jsx           ← prototype tweaks panel (REMOVE in production)
└── assets/
    ├── campfire_spark.png
    ├── warm_kindling.png
    └── ember_sprite.png
```

Vstupní bod logiky je v `Companion Claim.html` — `<script type="text/babel">` blok obsahuje state machine `App` komponenty. Skutečné komponenty pro reimplementaci jsou v `sheets.jsx` (statické UI) a `claim.jsx` (animační overlay — nejcennější kus).

## Otevřené otázky pro vývojáře

1. **Haptická zpětná vazba** — kde přesně volat (start, burst peak, reveal moment)?
2. **Skip animace** — má jít animaci přerušit/přeskočit? Aktuálně ne.
3. **Performance** — částice jsou kreslené jako stovky absolutně pozicovaných `<div>`. Ve Flutter doporučuji vlastní `CustomPainter` nebo `Flame` engine. Cílová FPS 60.
4. **Lokalizace** — všechny texty jsou česky. Připravit do i18n.
5. **Více společníků** — flow je naimplementovaný pro jednoho (Jiskřička). Pro N společníků bude potřeba data layer: kompoziční relikvie + odměna + popis + perk pro každého.
