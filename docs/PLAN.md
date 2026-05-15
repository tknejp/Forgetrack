# Plán: Interaktivní architektonická dokumentace

Statický web v `docs/site/`, vanilla HTML + JS, hostovaný přes GitHub
Pages. Žádný build step.

## Stack

- **HTML/CSS/JS** (vanilla, ES modules)
- **Cytoscape.js** (CDN) — interaktivní grafy (provider DI, závislosti
  mezi feature)
- **Mermaid** (CDN) — deklarativní diagramy (sequence, class diagram,
  flowchart)
- **JSON** podkladová data v `docs/site/data/` — oddělená od JS, aby
  PR diffy zůstávaly čitelné

## Pohledy

| # | View | Knihovna | Datový soubor |
|---|---|---|---|
| 1 | Mapa feature | vanilla | `features.json` |
| 2 | Graf providerů | Cytoscape | `providers.json` |
| 3 | Datové toky | Mermaid sequence | `dataflows.json` |
| 4 | Úložiště (Isar / Firestore / Prefs / Secure) | vanilla | `storage.json` |
| 5 | Externí integrace | vanilla | `integrations.json` |
| 6 | Doménový slovník (sealed hierarchies) | Mermaid classDiagram | `glossary.json` |
| 7 | RPG vrstva (Journey → Chapter → Quest → Objective → Reward → Cosmetic) | Mermaid flowchart | `progression.json` |
| 8 | Rozhodnutí (ADRs) | vanilla | `decisions.json` |

## Iterace

| # | Co | Status |
|---|---|---|
| 1 | Foundation (HTML/CSS/JS shell, router, side panel) + **Mapa feature** | ✅ |
| 2 | **Graf providerů** (Cytoscape) + light mode toggle | ✅ |
| 3 | **Úložiště** + **Externí integrace** | ✅ |
| 4 | **Datové toky** (8–9 scénářů, Mermaid sequence) | ⏸️ |
| 5 | **Doménový slovník** (sealed hierarchies, Mermaid class) | ⏸️ |
| 6 | **RPG vrstva** (cross-cutting flowchart) | ⏸️ |
| 7 | **ADRs** (8–12 rozhodnutí, derivováno z `git log` + kódu) | ⏸️ |
| 8 | GitHub Pages workflow + polish + zmínka v CLAUDE.md o údržbě | ⏸️ |

## Zásady

- V2 progression engine je jediná dokumentovaná verze. Legacy V1 modul
  ignorovat (treat as deleted).
- RPG mode toggle ještě neexistuje — neukazovat.
- Tmavé téma sladěné s appkou (CSS proměnné odvozené z
  `lib/shared/theme/design_tokens.dart`).
- Jazyk UI: čeština. Kódové identifikátory zůstávají anglicky.
- Žádné progress / planning info v lib/ READMEs — plány patří do
  `docs/`.

## Spuštění

Z kořene repa:

```bash
python -m http.server 8000 --directory docs/site
```

Pak otevři `http://localhost:8000/`.

## Hosting

GitHub Pages přes Actions workflow (publikuje `docs/site/` při push do
`main`). Workflow se přidá v iteraci 8.
