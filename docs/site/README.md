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

## Udržování

Při změně architektury (nová feature, nový provider, nový datový tok)
aktualizuj odpovídající JSON v `data/`. Žádný build step není potřeba.

JSON soubory záměrně držíme oddělené od JS — PR diffy zůstávají
čitelné a obsah lze validovat samostatně.
