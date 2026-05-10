# Forgetrack — Claude Code Instructions

## Project architecture
- Use feature-first architecture.
- Each feature should follow domain/application/data/presentation layering where practical.
- Keep business logic out of widgets.
- Prefer explicit services/providers over hidden side effects.

## Coding style
- Prefer simple imperative code.
- Avoid streams unless they clearly simplify the solution.
- Keep orchestration readable and sequential.
- Add AppLog logging for important sync/reset/export/progression steps.

## Progression system
- Rewards must be idempotent.
- Reward grants should use deterministic keys.
- Achievement unlocks are durable events, not recomputed UI-only state.
- Do not implement migrations unless explicitly requested; the app can be reset during development.

## Health Connect
- Treat Health Connect as external source of truth.
- Never delete or modify user Health Connect data.
- Local cache may be cleared.
- Permissions may be revoked only if Android/plugin supports it.

## Google Sheets export
- Preserve merge-by-date semantics.
- Use localized labels.
- Keep formatting logic centralized where possible.

## Output expectations
- Before editing, inspect the relevant files.
- Make minimal targeted changes.
- After changes, summarize modified files and remaining risks.

## Progression Engine V2 — in-flight refactor

- Branch `refactor/progression-engine-v2` runs the new engine alongside
  the legacy progression module. Status + cookbook in
  [docs/progression_engine_session_handoff.md](docs/progression_engine_session_handoff.md).
- Authoritative phased plan in
  [docs/progression_engine_v2_phased_plan.md](docs/progression_engine_v2_phased_plan.md).
- Read the handoff first when resuming the V2 work.
