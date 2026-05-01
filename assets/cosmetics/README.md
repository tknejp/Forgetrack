# Cosmetics assets

This folder holds the visual assets that back the `cosmetics` feature
(`lib/features/cosmetics/`). The folder is wired into Flutter via
`pubspec.yaml`; do not introduce new top-level subdirectories without
updating the manifest.

## Layout

```
assets/cosmetics/
├── frames/        # avatar/profile frame overlays
├── relics/        # collectible relic icons
├── backgrounds/   # hero/profile background scenes
├── emblems/       # small badge/emblem marks
├── companions/    # companion creature portraits
└── README.md
```

`title_flairs/` and `map_effects/` folders are intentionally not created yet —
those cosmetic types ship without bundled artwork in the current build. Add
the folders (and the corresponding `pubspec.yaml` entries) when artwork
arrives.

## Naming convention

`<cosmetic_id>.png` — the file name **must** match the `id` in
`CosmeticCatalog.definitions` minus the type prefix. Example:

| Cosmetic id              | Folder        | File              |
| ------------------------ | ------------- | ----------------- |
| `frame_pilgrim`          | `frames/`     | `pilgrim.png`     |
| `relic_old_compass`      | `relics/`     | `old_compass.png` |
| `background_forest_trail`| `backgrounds/`| `forest_trail.png`|
| `emblem_forest_mark`     | `emblems/`    | `forest_mark.png` |

## Expected files for the journey reward set

The catalog references the assets below. Drop the PNGs into the listed
paths; cosmetics with missing artwork render as rarity-coloured
placeholders until the file ships.

**Backgrounds** (`backgrounds/`):
`camp.png`, `forest_trail.png`, `ravine.png`, `ruins.png`,
`bridge_crossing.png`, `mines.png`, `frostlands.png`, `frozen_lake.png`,
`rocky_mountains.png`, `dragonrock_fortress.png`.

**Emblems** (`emblems/` — badge / insignia style, ceremonial):
`pilgrim_mark.png`, `forest_mark.png`, `ruin_sigil.png`,
`gatekeeper_mark.png`, `mine_crest.png`, `underways_mark.png`,
`frost_sigil.png`, `icewalker_mark.png`, `mountain_crest.png`,
`dragon_mark.png`, `dragonrock_emblem.png`.

**Relics** (`relics/`):
`old_compass.png`, `old_gate_key.png`, `campfire_spark.png`,
`pilgrim_cloak.png`, `trail_compass.png`, `ancient_root.png`,
`ravine_stone.png`, `ruin_seal.png`, `bridge_key.png`,
`miners_lantern.png`, `polar_lantern.png`, `frost_shard.png`,
`frozen_lake_heart.png`, `dragon_scale.png`, `dragon_crown.png`,
`dragonrock_crown.png`.

**Frames** (`frames/`):
`lvl1.png`, `lvl10.png`, `lvl25.png`, `lvl40.png`, `lvl60.png`,
`lvl80.png`, `lvl100.png` (the `lvl100.png` doubles as the Dragonrock
endgame frame — there is no separate `dragonrock_frame.png`),
`frame_developer_tom.png`, `discipline.png`, `endurance.png`,
`steel.png`, `eternal_flame.png`, `balance.png`, `master_routine.png`,
`endless_trail.png`, `worldwalker.png`.

**Companions** (`companions/`):
`ember_sprite.png`, `forest_fox.png`, `ruin_raven.png`,
`lantern_golem.png`, `ice_wisp.png`, `mountain_gryphon.png`,
`dragonling.png`.

The asset key declared in the catalog (`cosmetics.frames.pilgrim`) is mapped
to the on-disk path by `CosmeticsConfig.resolveAssetPath` — keep the
`cosmetics.<bucket>.<name>` shape so the resolver finds it.

## Recommended sizes

| Bucket        | Recommended size | Notes                                          |
| ------------- | ---------------- | ---------------------------------------------- |
| `frames/`     | 256×256          | Square, transparent background, centred        |
| `relics/`     | 256×256          | Square icon, transparent background            |
| `backgrounds/`| 1080×1920        | Portrait scene, opaque, optimised for hero BG  |
| `emblems/`    | 128×128          | Small mark, transparent background             |
| `companions/` | 256×256          | Portrait crop, transparent background          |

Provide a single resolution per asset for now. If you later need @2x/@3x
variants, add them as Flutter sibling files (e.g. `2.0x/pilgrim.png`) — the
asset key in the catalog stays unchanged.

## Frame asset spec (priority bucket)

Frames are the bucket consumed by `CosmeticFramePreview` — currently used
to wrap the hero avatar in `SocialProfileHeader`. To author a frame:

* **Format:** transparent PNG, 24-bit + alpha (RGBA8). Avoid JPEG.
* **Canvas size:** 256×256 px. The widget renders at `BoxFit.contain`
  inside whatever `size` the host passes (currently 70 px in the hero
  header). 256 gives roughly 3.5× headroom for high-DPI screens.
* **Composition:** the avatar sits at the centre of the canvas as a
  rounded square (20 px radius at 70 px display size — about 28% of the
  edge). Design the frame so its inner cut-out aligns with that
  rounded-square shape. The middle ~70% of the canvas should be fully
  transparent so the avatar shows through.
* **Bleed:** decorative elements may extend close to the canvas edge but
  must stay within the 256×256 bounds — the widget does not over-draw.
* **File location:**
  `assets/cosmetics/frames/<name>.png`. The `<name>` is the cosmetic id
  with the `frame_` prefix stripped:

  | Cosmetic id           | File                                            |
  | --------------------- | ----------------------------------------------- |
  | `frame_pilgrim`       | `assets/cosmetics/frames/pilgrim.png`           |
  | `frame_ruined_bronze` | `assets/cosmetics/frames/ruined_bronze.png`     |

* **Hot-reload tip:** after dropping a new PNG into the folder, run a
  full restart (`R`), not hot reload — Flutter only re-indexes the asset
  bundle on restart.

While no PNG exists for a definition, the widget falls back to a
rarity-coloured ring (rounded-square because the host passes
`borderRadius: 20`). Replace the ring with real artwork by adding the
file at the path above.

## Format

* **Preferred:** transparent PNG (24-bit + alpha).
* **Acceptable:** WebP (lossy with alpha) when the size win is worth the
  fidelity tradeoff.
* Avoid JPEG — no transparency.

## Fallback behaviour

The cosmetics presentation widgets never crash on a missing asset:

* `CosmeticFramePreview` falls back to a rarity-coloured gradient ring.
* `CosmeticCollectionTile` falls back to a gradient placeholder behind the
  name banner.

This means a definition in the catalog can ship before its artwork lands —
the cosmetic will render as a coloured placeholder until the file is added.

## Firebase-only entitlements

Special cosmetics can be gated per user through Firestore entitlements. The
cosmetic definition and asset still ship in the app, but only users with an
active entitlement document get the item unlocked locally.

Set permissions here:

```
users/{uid}/cosmeticEntitlements/{cosmeticId}
```

For example, to grant the developer frame:

```
users/<your app uid>/cosmeticEntitlements/frame_developer_tom
```

Its bundled artwork is resolved from:

```
assets/cosmetics/frames/frame_developer_tom.png
```

Suggested document fields:

```json
{
  "active": true,
  "source": "developer",
  "grantedAt": "<server timestamp>"
}
```

`cosmeticId` may be omitted when the document id is the cosmetic id. Optional
fields:

* `cosmeticId`: override when the document id is not the cosmetic id.
* `sourceType`: unlock source stored locally; defaults to `source` or
  `promotional`.
* `sourceId`: audit id stored locally; defaults to
  `firebase_entitlement:{docId}`.
* `expiresAt`: timestamp after which the entitlement is ignored.
* `active`: set to `false` to stop future grants.

The `uid` is the same id used by social profiles in the `users` collection
(currently the app's canonical user id, usually the Google provider subject).
For production microtransactions, protect these documents with Firebase
Security Rules or a server/Cloud Function so clients cannot grant themselves
premium cosmetics.
