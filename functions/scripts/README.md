# Ops scripts

Local-only Node.js scripts run against the live Firestore project using
firebase-admin (service-account auth, no IAM custom claims required).
Not deployed as Cloud Functions.

## Setup (one-time)

1. Firebase Console → Project Settings → Service accounts → **Generate
   new private key**. Save the JSON.
2. Either set `GOOGLE_APPLICATION_CREDENTIALS=/path/to/the.json` in your
   shell, **or** drop the file at `functions/scripts/service-account.json`
   (gitignored).
3. From the repo root: `cd functions && npm install` once to get
   `firebase-admin` on disk.

## grant-cosmetic.js — cosmetic entitlements ops (Trello #82 Tier 1)

Writes / lists / revokes docs under
`users/{uid}/cosmeticEntitlements/{cosmeticId}`. The app subscribes to
that collection as a live stream
([`FirestoreCosmeticEntitlementsSource.watchForUser`](../../lib/features/cosmetics/data/firestore_cosmetic_entitlements_source.dart)),
so a grant lands without an app restart.

```bash
# Grant
node functions/scripts/grant-cosmetic.js \
    --uid <firebaseUid> \
    --cosmetic <cosmeticId> \
    [--source promotional] \
    [--source-id <free-text-id>] \
    [--expires <ISO-8601 timestamp>]

# List current entitlements for a user
node functions/scripts/grant-cosmetic.js --uid <uid> --list

# Revoke (deletes the doc — client stream drops the unlock on next
# emission, but the local Isar row stays unless wiped via DevTools)
node functions/scripts/grant-cosmetic.js --uid <uid> --revoke <cosmeticId>
```

**Idempotency.** Document id is the cosmetic id, so re-running `--grant`
with the same args is a same-data overwrite.

**Caveat — revoke semantics.** Deleting the entitlement doc removes
the server-side grant, but the **local** Isar unlock added by
`service.unlock(...)` stays put. Use `devToolsResetProgressionUnlocks`
or factory reset to drop the local copy too if you need to revoke
in earnest.
