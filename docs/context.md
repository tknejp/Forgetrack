Project context — Forgetrack

This is a Flutter fitness/RPG tracking app using feature-first architecture.

Current architecture:
- lib/app/ = app-level providers/configuration only
- lib/core/ = technical infrastructure, logging, navigation, storage, services
- lib/shared/ = reusable UI/theme/helpers with no feature dependencies
- lib/features/<feature>/ = feature-first modules
  - application/ = providers, use-cases, orchestration
  - data/ = API/DB/services/repositories
  - domain/ = models, pure domain logic
  - presentation/ = screens/widgets/UI

Important architectural rules:
1. shared/ must not import features/*
   - Shared widgets must receive data through constructor parameters.
   - If a widget needs AuthProvider/FitnessProvider/etc., keep it inside the relevant feature or pass plain values into it.

2. application/ must not import presentation/
   - Providers/use-cases cannot depend on UI files.
   - If a provider is currently in presentation/, move it to application/.

3. domain/ must stay pure.
   - No Flutter widgets, BuildContext, Provider, Firebase, Isar, HTTP, SharedPreferences, or UI imports.
   - Domain models and logic should be testable without Flutter.

4. data/ can depend on domain/, but not on presentation/.
   - Data layer handles APIs, DB, parsing, persistence.
   - Data layer should not call UI or provider methods directly.

5. presentation/ can read providers and build UI.
   - UI can use context.watch/read/select.
   - Keep heavy logic out of widgets; move it to provider/query/helper classes where reasonable.

6. core/ should not become a god layer.
   - core/services may orchestrate cross-cutting work like background sync, notifications, logging.
   - If business logic grows there, split it into feature-specific services/providers.

7. Do not reintroduce legacy folders:
   - Do not create lib/screens/
   - Do not create lib/providers/
   - Do not create lib/models/
   - Do not create lib/services/
   - Do not create lib/widgets/
   - Do not create lib/theme/
   Use feature-first paths instead.

8. Preserve existing behavior unless the task explicitly asks for functional changes.
   - Prefer small, safe refactors.
   - After moving files, update imports only.
   - Avoid redesigning UI unless requested.

9. Run after every phase:
   - flutter analyze
   - relevant flutter test files
   - mention any remaining warnings/errors separately

10. Logging:
   - Use AppLog from lib/core/logging/app_log.dart.
   - Do not use print().
   - Keep logs structured and domain-scoped.

11. DevTools/debug mode:
   - DevTools must be gated by kDebugMode or explicit developer UID allowlist.
   - Debug tools may inspect provider state, DB/cache state, sync history, background refresh and notifications.
   - Debug actions that mutate real app state require confirmation.
   - Do not make debug overrides affect production calculations unless explicitly requested and safely gated.

12. Health Connect sync rules:
   - Do not overwrite valid cached DB data with empty lists after partial Health Connect failures.
   - Quota errors must preserve DB state and not stamp lastSyncedAt as successful.
   - For range refreshes, use inclusive UI range but exclusive query end:
     start = selected start day 00:00
     endExclusive = selected end day + 1 day
   - After fetching, filter records back to the selected inclusive range before saving.
   - Be careful with DateTime local vs UTC boundaries.

13. KT nutrition sync rules:
   - Avoid repeated getRange()/avgField() spam from build methods.
   - Prefer computing one range summary once and reusing it in UI.
   - Today can legitimately be zero just after midnight if no food is logged yet.
   - Do not let a past-range refresh accidentally overwrite today's provider state with stale/empty values.
   - Keep cached data available even if API sync fails.

14. Progression/RPG rules:
   - Progression should evaluate from provider/DB state, not directly from UI widgets.
   - Be careful with “today” after midnight. If current day has no nutrition yet, daily nutrition quests will show 0.
   - Avoid evaluating progression repeatedly during every rebuild.
   - Prefer explicit refresh/recalc triggers or debounced provider-level updates.

Task style:
- Work in small phases.
- Before changing code, inspect the relevant existing files.
- Keep imports clean.
- Do not create duplicate screens/components when an existing one should be modified.
- Do not delete working logic unless it is confirmed unused.
- If something is risky, leave a TODO or disabled devtools action instead of hacking it.