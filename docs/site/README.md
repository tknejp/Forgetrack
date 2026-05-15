# Forgetrack — interaktivní architektonická dokumentace

Statická HTML dokumentace, kterou lze proklikat. Pokrývá feature mapu,
graf providerů, datové toky, úložiště, externí integrace, doménový
slovník, RPG vrstvu a architektonická rozhodnutí.

Plán a status iterací: [docs/PLAN.md](../PLAN.md).

## Spuštění lokálně

Browser blokuje `fetch` z `file://`, takže je potřeba lokální HTTP
server. Z kořene repa:

```bash
python -m http.server 8000 --directory docs/site
```

Pak otevři `http://localhost:8000/` v prohlížeči.

Alternativně z `docs/site/`:

```bash
python -m http.server 8000
```

## Struktura

```text
docs/site/
├── index.html              # entry point
├── css/
│   ├── tokens.css          # CSS proměnné odvozené z ThemeTokens.dark
│   └── style.css           # layout + komponenty
├── js/
│   ├── app.js              # hash-based router + side panel
│   └── views/              # jeden modul na pohled
└── data/                   # JSON podklad pro každý pohled
```

## Hosting

GitHub Pages přes Actions workflow [`.github/workflows/pages.yml`](../../.github/workflows/pages.yml).
Workflow se spustí při každém push do `main`, který se dotkne
`docs/site/**` nebo samotného workflow souboru, a publikuje
obsah `docs/site/` jako statický web.

Pro aktivaci v GitHub UI: Settings → Pages → Source = "GitHub Actions".

## Udržování

Při změně architektury aktualizuj odpovídající JSON v `data/` — žádný
build step. Mapování:

| Změna v projektu | Aktualizuj |
|---|---|
| Nová feature pod `lib/features/` | `data/features.json` |
| Nový provider / proxy závislost v `main.dart` | `data/providers.json` |
| Nová Isar kolekce / Firestore subkolekce / prefs klíč | `data/storage.json` |
| Nová externí integrace (API, SDK) | `data/integrations.json` |
| Nový architektonicky významný flow | `data/dataflows.json` |
| Nová sealed hierarchie / klíčový enum | `data/glossary.json` |
| Nové architektonické rozhodnutí | `data/decisions.json` |

JSON soubory záměrně držíme oddělené od JS — PR diffy zůstávají
čitelné a obsah lze validovat samostatně.
