# Echoes of Aether — v3 → v5 Master RPG Blueprint

## Player-first goals
- **Make every place feel like a destination, not a stitched panorama.** A hub/portal gate loads each independently saved Godot `PackedScene`. Camera and player movement are clamped to the loaded realm. There is no continuous walking transition from one background into another.
- **Retain the Android user's game**: unchanged package ID `org.lokij.echoesofaether`, stable signing key, and safe migration of `user://aether_save.json` and the independent `user://aether_controls.json` custom button layout.
- **Meaningful RPG progression, not padded walking**: guardians, dungeon entrances, chapter scenarios, optional hunts, repeatable enemy combat (but one-time mission rewards), discovery and quest rewards.
- **Fair mobile gameplay:** screen-scaled touch controls, readable attack warnings, puzzles can be exited, story dialogue never softlocks, automatic checkpoints and portals back to hub. Graphics-quality options for lower-end phones.

## v3 planned systems — COMBAT / CHARACTER EXPRESSION
**Now implemented in the v5 milestone:** Four rotating boss patterns with proper windup: three/five-way magic fan, single accurate projectile, low ground wave and a short dash plus an arcing projectile. Charger enemies wind up before lunging; armored guards take a defensive stance; ranged wisps kite and vary the number/speed of their shots. Existing three-hit combos, timed parry, Aether Bolt, double-jump, dash and Emberling pet remain.

**Further depth to build after playtesting:** A proper weapon-class selector (sword/bow/staff), equippable relic loadouts, full sprite-frame animations, the ability to parry ranged projectiles, independently tuned boss move tables and player-friendly hit pause/camera FX.

## v4 planned systems — SEPARATE REALMS / DUNGEONS
**Now implemented in the v5 milestone:** 19 Godot PackedScene destinations in `scenes/realms/`, one loaded at a time, authored and routed by `scripts/RealmCatalog.gd`. Every adventure realm has an optional dungeon gateway near its eastern edge. Existing saved x-coordinates are maintained as private map offsets to preserve older saves; players cannot physically walk between regions. Each dungeon has its own background tint, geometry, spawned encounters and boss/guardian. Dungeon victories stay cleared across saves.

Core routes:
- **Moonhaven Village**: safe hub, Mira, merchant, trainer, portal network
- **Whisperwood Vale** → Rootbound Crypt / Root Colossus
- **Sunken Ruins** → Echo Labyrinth / Echo Archon
- **Crystal Hollow** → Mirror Vault / Mirror Keeper
- **Celestial Highlands** → Gale Spire / Gale Wyrm
- **Shadowfen Marsh** → Mire Catacombs / Mire Reaver
- **Emberfall Citadel** → Cinder Vault / Cinder Warden
- **Abyssal Depths** → Temple of the Tide / Abyss Leviathan
- **Everdawn Gardens** → Verdant Sanctum / Thornheart
- **Aether Nexus** → Heart of the Core / Nexus Echo

Dungeon content is one connected area per instance at this milestone, with real enemies, platforms, hazards and a guardian. **Long-form multi-floor interiors, authored switches, collectible keys, boss intro cutscenes and unique level artwork** remain future upgrades, not falsely marked as complete.

## v5 planned systems — RPG STORY / QUESTS / QUALITY
**Now implemented in the v5 milestone:**
- 30 objective-based quests and a scrollable journal; visit, conversation, kill, rescue, seed and boss events count toward one-time gold/XP rewards.
- Chapter lore through multi-line talking scenes in each major realm; optional and dismissible.
- A portal atlas with actual scene choices, lock state and a separate selection page for dungeons.
- New Chapter III (Abyssal Depths), IV (Everdawn Gardens) and V (Aether Nexus); their guardian clears unlock the next chapter.
- Dedicated win panels for each dungeon and for the final Aether Core restoration, with rewards and persisted progress.
- NPC cues, scene-based portal props, dungeon pillars/particles, new enemy pack and camera isolation.
- Regression coverage for old v2 save migration, independent realm scenes, portal boundaries, quests, boss attack rotation, final story and Android upgrade signing.

**Not yet complete:** unique Higgsfield-generated scenery for Abyssal/Everdawn/Nexus, since the connected Higgsfield workspace returned 0 available credits on 2026-11-11. The milestone reuses existing authorized Higgsfield images and recolored/procedural Godot visuals, designed so higher-resolution originals can be substituted later without affecting gameplay. Fully authored NPC daily routines, elaborate cutscenes, dedicated three-floor dungeons, a bestiary codex and a multi-weapon skill tree are future milestones.

## Story outline / scenarios
**Chapter I — The Fading Star.** The hero meets Mira, restores three Aether Seeds, and faces the Star Warden. This protects the original opening gameplay and teaches the controls.

**Chapter II — The Shattered Path.** Mira and Taro explain that the first restoration was temporary. Each realm has a fragment of the damaged Core. The player travels through Whisperwood, ruins, Crystal, Sky, Shadowfen and Emberfall; local people tell short scenario dialogues and the player may clear the nearby vaults to help their community.

**Chapter III — Beneath the Tide.** Captain Nera describes a drowned civilization. In Abyssal Depths the player defeats Tide Stalkers and Coral Wisps, then finds the Abyss Leviathan in the Temple of the Tide. Victory unlocks the gardens.

**Chapter IV — The Thorned Dawn.** Gardener Eve asks the player to recover the Seed of Renewal, now overrun by thorn knights and petal moths. Thornheart protects the Verdant Sanctum; after its defeat the Nexus route opens.

**Chapter V — The True Core.** Mira's final dialogue reveals the Nexus Echo. The hero collects allies, enters the Heart of the Core, and defeats the final foe. The ending shows all quest/dungeon progress, but allows free roaming after victory.

## Acceptance / loop engineering
1. Every scene must instantiate in Godot, load its own ID, and be reachable only through a portal or a saved checkpoint.
2. The camera must never show an adjacent realm while walking at a map border.
3. New game, old v1/v2 saved progress, all 30 quest counters, quest rewards, custom HUD layout, dungeon clears, and scene returns must survive reload.
4. Each boss must rotate through four patterns and visibly warn before attacks. Guardian rewards must be one-time.
5. Godot headless CI must pass **all older smoke tests** plus v5 real-map/quest/attack/final-boss tests; Android debug APK must retain app identity/signature with a higher versionCode.
6. A successful APK build is **not** proof of polished Android gameplay. Real physical-device screenshot/video testing remains necessary for clipping, aspect ratios, sprite art style, and control comfort.


## v5.0 Journal polish — quest pinning (implemented)

- The player can tap **TRACK** next to any incomplete quest in the Journal. The objective appears as a small on-screen label with actual progress; the entire world remains playable without any quest overlay covering the action.
- Tapping **UNPIN** returns to automatically selecting the first available unfinished objective.
- When a tracked quest completes, the pin is cleared and the next relevant objective is displayed. Progress and the chosen pin survive ordinary save/load and Android app updates; older v2/v5 save files without this field safely choose an automatic objective.
- CI includes a synthetic touch-button test, persistent reload test, automatic completion and fallback test, without bypassing the original 30-quest story progression.

**Next deepening ideas (not implemented in this patch):** optional bounty-board chains with meaningful dialogue, branching NPC replies, scene-local key/door puzzles, unique Abyssal/Everdawn/Nexus Higgsfield artwork when credits are available, narrated cutscene beats, more equipment categories, and dungeon-specific enemy tactics. These should be developed and measured as separate gameplay milestones rather than claimed complete from the roadmap alone.


## Local-original-art pipeline for v5 realms — implemented

If Higgsfield generation credits are unavailable, the CI produces seven self-contained original panoramas with `tools/build_v5_art.py` using Pillow. They are committed as `assets/v5_generated_*.png` and loaded/cached in the Godot renderer for Abyssal, Tide Temple, Everdawn, Verdant Vault, Aether Nexus, Nexus Core and Rootbound Crypt. The offline test suite verifies the exact image paths, dimensions and scene-to-texture bindings. This removes the placeholder-reused backgrounds in those seven locations without adding any external runtime dependency.

The four high-resolution concept pictures made in chat show a richer future art direction; they are **not** the exact procedural PNGs in the APK. Real Pixel-Art sprite polish, parallax animation, and physical-phone visual acceptance remain necessary before declaring the art final.


## v6 Deep Realms: playable annex milestone

Eight independent bonus dungeon scenes and sixteen extra quest entries extend the original chapter. Side portals at the midpoint of Rootbound Crypt, Mirror Vault, Gale Spire, Mire Catacombs, Cinder Vault, Tide Temple, Verdant Sanctum and the Nexus Core lead to unique-themed annexes with distinctive original art, enemy encounters, NPC story beats, and one optional puzzle pedestal per annex.

The new `PuzzleEngine.gd` supplies four genuinely different mechanics: sliding-image assembly, reciprocal rotated light connections, three-dial constraint solving, and watched/repeated memory symbols. All support hint, restart and instant exit. Save migration is incremental with version 60 and preserves old progress/custom controls. This is a playable new dungeon-system milestone, **not** a claim that every realm now has a sprawling multi-floor AAA dungeon or that the generated premium concept paintings were successfully uploaded.
