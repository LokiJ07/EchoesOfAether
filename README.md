# Echoes of Aether v6 — DEEP REALMS: Eight Annex Trials

The new content expands the existing v5 portal RPG to **27 independent PackedScene destinations** and **46 saved quests** (previously 19 and 30). Eight original branch rooms are accessible from mid-dungeon secret portals: Rootbound Mural Gallery, Prism Circuit Annex, Wind Observatory, Lantern Chamber, Living Forge Engine, Tidal Control Vault, Seedweave Arbor and Star Memory Chamber.

## Truly different interactive puzzles

1. **Sliding mural assembly** — slide eight real picture fragments around the one empty square, rearranging an actual portion of the room background to reconstruct it. Every initial board is solvable.
2. **Rotating energy circuits** — turn pipe pieces until reciprocal connections carry the beam from the left input through an actual route to the right exit. A rotated tile without matching neighbors cannot complete the circuit.
3. **Three-dial number logic** — solve three simultaneous pair-sum constraints by adjusting individual valves.
4. **Watch-and-repeat memory** — study an original 5–6-glyph sequence, then repeat it. Wrong entries reset only the memory sequence; clues can reveal the next glyph.

Every chamber is **optional**, entered through its own portal; there are no forced timers, damage penalties, mandatory solve locks or lost resources. Buttons provide Hint, Restart and Exit; puzzles pause live hazards and combat. Solving once grants a relic, coin rewards and quest completion saved in the original `user://aether_save.json`. Already-completed chambers cannot be exploited for unlimited coins.

## Expanded maps and dungeon encounters

All eight chambers have their own local generated illustrated backgrounds, physically isolated by camera/portal transitions, plus real terrain platforms, original room props and enemy packs. The existing old saves, dungeon bosses, mobile controls, music settings and Android install-over identity remain intact.

`tools/build_v6_art.py` draws original temple and chamber art offline using Pillow. Each distinct image is packaged as `assets/v6_generated_*.png`. The earlier premium high-res images generated in ChatGPT are available in a separate concept-art package, **not automatically used as these PNG textures** because the connected GitHub adapter cannot upload their local image bytes. These generated backgrounds are production placeholders until premium art is transferred into the repository.

The v6 Godot tests exercise the entire portal/puzzle/reward/save experience and build the Android APK only after v0.1–v5 regressions are green. Physical-phone touch/layout and playtime must still be verified.

---

# ECHOES OF AETHER — v5.0 PORTAL RPG MILESTONE

## v5 original-art fallback (no Higgsfield credits required)

This release also embeds **seven different locally generated PNG panoramas** in the actual Godot application: Abyssal Depths, Temple of the Tide, Everdawn Gardens, Verdant Sanctum, Aether Nexus, Heart of the Core, and Rootbound Crypt.

`tools/build_v5_art.py` draws each original fantasy environment using deterministic Pillow rendering (landscape layers, distinct architecture, lights and habitat-specific plants/crystals/ruins). GitHub Actions runs this script before importing Godot assets and commits the PNGs into `assets/` so future builds remain offline. The camera uses one panorama per isolated map with no repeated-image seam. This procedural art is intentionally different from the separate high-resolution concept pictures generated in chat, which cannot currently be uploaded into GitHub using the available connection.

Old Android package identity, signing key, save migration and customized touch controls stay unchanged. The v5 gameplay tests now open every generated `Texture2D` and verify it is connected to the correct scene.


**New in this revision:** The Journal has touch-friendly TRACK / UNPIN controls for all unfinished quests. The chosen quest appears as a compact progress objective while playing, survives save/load and Android updates, and automatically advances after completion. Existing saves safely fall back to the next available objective. The full v3–v5 blueprint is in [V5 Master Plan](docs/V5_MASTER_PLAN.md).

**Developed from the v3 + v4 + v5 roadmap.** The 65k internal coordinate world is now split into **19 real Godot PackedScene destinations** with individual camera bounds and interactable portal gates. Players no longer walk across visible seams between realms. The old world-space offsets stay private to preserve local Android saves. The new Journal tracks **30 one-time quests**, eight additional dungeon guardians have encounter rooms, and bosses rotate through four attack patterns instead of repeating a single projectile fan.

**Playable locations:** Moonhaven hub, Whisperwood, Sunken Ruins, Crystal Hollow, Celestial Highlands, Shadowfen, Emberfall, Cinder Vault, Abyssal Depths, Temple of the Tide, Everdawn Gardens, Verdant Sanctum, Aether Nexus, Rootbound Crypt, Mirror Vault, Gale Spire, Mire Catacombs, Echo Labyrinth and Heart of the Core. See [V5 Master Plan](docs/V5_MASTER_PLAN.md) for the full feature matrix and follow-on polish.

**Progression:** Start in Moonhaven; the first forest gate is accessible right away. Explore separate places, talk to their local lore NPCs, complete real kill/rescue/visit/boss missions, enter optional dungeons, claim unique rewards and unlock Abyssal → Everdawn → Aether Nexus via the guardian chain. Existing v1/v2 equipment, coins, quests, relics, portals and custom HUD positions continue through save migration.

**Art status:** The current milestone reuses existing, already imported Higgsfield world art and monster sprites, recolored and layered with Godot scenery for new regions. Newly requested Higgsfield images were **not generated** because the connected account reported insufficient credits. Original dedicated Abyssal/Garden/Nexus art and more elaborate authored dungeon interiors are documented follow-on items, not claimed as complete.

**Release quality:** Each source commit triggers GitHub CI for Godot import, old gameplay tests, v5 scene/quest/AI/endgame tests, and Android APK export with original package ID and signing certificate. An Android physical-device playtest is still needed for actual visuals and touchscreen comfort.

---

# ECHOES OF AETHER — v2.0 SHATTERED REALMS (EMBERFALL MILESTONE)

**Status:** First complete playable v2.0 chapter — Emberfall Citadel + Cinder Vault dungeon, not yet the Abyssal Depths or Everdawn Gardens. The longer v2 roadmap is documented below; new lands will only be called playable once implemented and CI-verified.

### Player-visible improvements

- **Longer connected game:** The world expands from 15,800 to 23,000 world units. Chapter II becomes available after clearing Shadowfen. Emberfall Citadel is followed by the separate-looking Cinder Vault dungeon (Gatehouse, Furnace Hall, Cinder Throne), and a new Cinder Warden boss with a two-phase fireball attack and on-screen warning.
- **22 ACTUAL imported art assets (21 original Higgsfield images plus 1 derived crystal variant)**, sourced from Higgsfield and imported into Godot: volcanic Citadel background, molten dungeon, Cinder Warden, Emberling pet, Fire Imp, 12 distinct ordinary mob designs, 4 distinct realm-boss designs. PNG image processing converts chroma-green sheets to transparent per-species sprites. All are packed into the APK; **no live network required**.
- **Mob identity overhaul:** Old forest/slime/moth/beetle/sentinel/wisp, crystal/sky/marsh monsters and original bosses now load separate visual sprites rather than displaying the same image with different color tints. Enemy names are visible above sprites, while existing behaviors, health, damage and attack telegraphs remain functional.
- **Controls that actually move:** Fixed a bug where the joystick was accidentally included in the action-button hit test, swallowing touch presses after custom HUD repositioning. The engine now converts Android event coordinates into local HUD space, resolves the nearest *visible* action, and uses the actual saved on-screen control positions. You can reposition joystick, Attack, Jump, Guard, Dash, Potion, etc.; the hit zones follow.
- **New recognizable animated main menu:** Full-screen Higgsfield Emberfall poster art, dark cinematic split panel, gold/teal typography, smooth embers, large adventure buttons, and redesigned five-destination portal network and world atlas.
- **Real Emberling companion:** Rescue the pet at the watchtower. It flies behind the hero, teleports to your position when fast-traveling rather than getting stuck, and automatically attacks nearby enemies. Rest/call it from Inventory.
- **Three optional fire-rune puzzles**, with explicit hint and escape buttons, no HP or coin penalty on a wrong guess, and one-time 100-coin + relic rewards. Solving them is **never required** to enter the dungeon or beat the boss.
- **Optional species hunts** for Fire Imps, Ash Knights, and Ember Wisps, with one-time rewards to extend exploration and progress. Permanent quest/save state.
- **Save and APK continuity:** Legacy v0.1–v1.0 save format `user://aether_save.json` preserved, new saved keys default safely on old data. Existing `user://aether_controls.json` preferences continue. Same Android app ID and signing keystore, increasing versionCode for update-over-install. No uninstall required.

### What this milestone does not yet include

Abyssal Depths, Everdawn Gardens, a full multi-weapon inventory or a dedicated branching talent-tree GUI are **planned v2 expansions**, not implemented here. Do not label those features complete until built and tested.

### Development / loop-engineering quality gates

`tools/fetch_v2_art.py` processes Higgsfield originals into 22 separate `assets/v2_*.png` images; GitHub Actions embeds them and attempts to commit the processed files for future offline builds. Godot headless tests cover unique texture loading, repositioned real touchscreen hits, five-portal save migration, optional puzzle exits/rewards, companion behavior, multiple enemy hunts, boss phase 2, dungeon clear persistence, and the original v1 smoke tests. CI then builds and signs the same-package Android APK. **Physical-phone look-and-feel verification is still needed after CI succeeds.**

---

# ECHOES OF AETHER v1.0 — THE AETHER AWAKENING

The **v1.0** release advances the existing offline Android game with smoother animation, interactive user interfaces, optional logic mini-games, original generated scenery, and clearer combat feedback. All four main realms, story quests, checkpoints, relics, saved progress, customizable mobile controls, and the existing package/signing identity remain intact.

## What's new

- **Three original Higgsfield-generated offline backgrounds:** Crystal Hollow, Celestial Highlands, Shadowfen Marsh. The artwork is prepared by CI and embedded as PNG files **inside the APK**. GitHub Actions also attempts to commit the imported artwork into `assets/` so future builds can operate without fetching it again. The original procedural environment is retained as the fallback.
- **Animated gameplay poses:** The existing hero sprites now move with idle breathing, run bounce, jump tilt, sword attack lean, dash stretch, guard stance, healing pulse and damage recoil. Enemies have subtle movement and attack reactions; bosses show a **0.55-second visual warning** before casting projectiles.
- **Interactive Aether Echo rune shrines:** Six optional puzzle landmarks across the connected world. At each, tap SUN, MOON or STAR in the sequence described by the clue. Wrong answers simply reset the puzzle sequence—**no damage, items lost, or quest penalties**. Players can ask for the next rune hint or leave instantly, returning to the same place. First-time completion gives **55 coins and +6 permanent max HP**, saves instantly and unlocks a short lore memory. Each shrine pays out only once.
- **Premium UI/UX:** Redesigned animated main menu, refined touch-friendly buttons, animated interface accents, improved dialogue panels, rune puzzle modal with explicit **Leave Puzzle**, and a journal counter for completed optional challenges.
- **Graphics & accessibility controls:** Settings includes Low, Balanced, High and **Reduce Motion**, saved separately from gameplay progress. Low reduces particles and optional full-resolution backgrounds; all modes retain playable geometry and mechanics.
- **No hindrance to play:** Puzzles are opt-in and never block the main story or portal fast-travel. Background imagery is visual only; no collisions are added. During puzzles the game world is paused, with clear Hint and Exit buttons. Responsive touch controls and user HUD placement remain available.
- **Safe updates and migration:** Preserve Android package `org.lokij.echoesofaether`, stable debug signing certificate, automatic increasing version codes, saved adventure, and separately saved HUD settings. Previous v0.6 save files load with unopened optional shrines.

## How to install on Android

Open the latest **successful** Actions workflow and download **EchoesOfAether-Android-debug-APK**. Extract and install the APK **over** your existing game. Do not uninstall your current installation if you wish to preserve local game progress. The CI verifies consistent signing certificate, package ID and increasing versionCode. No network connection is needed to play the resulting APK.

## GitHub build checks

CI validates: original Godot game and story smoke tests; expanded worlds and portal travel; v0.6 HUD dragging, combat, save migration and screen ratios; plus new v1 puzzle rewards/exit, animation poses, legacy save loading, graphics preferences, telegraphed bosses and all three offline realm backgrounds. It then exports, verifies signing, and uploads the Android debug APK.

---

# Echoes of Aether v0.6 — CONTROL FORGE & GUARDIAN MASTERY

**A major, playable upgrade** over the v0.3 Worlds Beyond expansion. The four-realm story, portal network, old quests, enemies, relics and map remain unchanged. Existing Android app installs and save files remain compatible.

### Automatic screen-ratio support

The game now uses Godot's **expand** aspect ratio (no forced 16:9 bars), keeping the native landscape aspect of wide, ultrawide, conventional 16:9, and tablet screens. Terrain fills the complete camera view on taller screens. HUD positions use a compact safe-area margin, adaptive button and joystick sizes, and top-bar spacing that adjusts to viewport width. The portable HUD editor saves positions in normalized coordinates and clamps them inside the current viewport when the phone's shape changes. Android export enables small/normal/large/xlarge screen support.

The v0.6 regression tests check layout boundaries for simulated **960×540, 1152×648, 1440×648, 1152×864, and 1920×648** viewports, in addition to touchscreen drag/save behavior. These automated checks do not replace physical testing on individual notched devices.

## New in v0.6

**Fully customizable on-phone HUD editor:** Go to **PAUSE → SETTINGS → CUSTOMIZE HUD & CONTROLS**. Drag the joystick or any action button (ATTACK, JUMP, DASH, AETHER, POTION, TALK/TRAVEL, GUARD) to a comfortable place. The editor allows **SMALLER / LARGER** (75–135%) and **FADE / BRIGHT** (35–100% background transparency) adjustments, and includes **RESET** and **SAVE & EXIT**. Positions are stored as normalized screen coordinates so they work on wide Android phone displays. All moved controls also use the **moved hitboxes in the actual game**. Layout preferences are saved separately in `user://aether_controls.json`, so choosing a new adventure cannot erase your control layout.

**Mastery combat:** A new **GUARD** button (or G on keyboard) spends 18 stamina for a 0.55-second defensive window. If an enemy hits you within the window, the hit is blocked and the nearest enemy is counterattacked. Guard has a 2.6-second cooldown and a visible countdown. **Three consecutive ATTACK taps** within the combo window create a heavier third strike, with combat feedback in the HUD. The **Hunter Mastery** lifetime kill tracker pays one-time bonuses at 12, 30 and 60 enemies defeated. Your kill count and claimed rewards persist between sessions; they do not repeat on respawn.

**Safe updating:** Android CI automatically generates a higher versionCode, preserves the original package ID and signing certificate, compiles and tests Godot scenes, verifies v0.1/v0.2/v0.3 save migration, tests the real draggable touchscreen layout and guard/combos/mastery, and exports a signed update APK. Download the latest successful Actions artifact and **install over the current game** without uninstalling it.

---

# Echoes of Aether v0.3 — WORLDS BEYOND

**Android fullscreen and playable world expansion**. Built as an upgrade for the existing game; keep the original APK installed and choose **Update** when installing the v0.3 Android APK. The same Android package ID and debug signing certificate remain in GitHub Actions.

## New in v0.3

- **Fullscreen support for ultrawide Android phones** with Godot Canvas Items stretch and **Expand** aspect instead of forced 16:9 letterboxing. The world camera adjusts to the real viewport width; the HUD anchors to the visible edges.
- **Responsive movement & touch controls:** stronger left/right acceleration and top speed, easier button hit targets, a larger virtual joystick and a brief coyote-time window after running off a platform.
- **Three additional side-scrolling world regions**, expanding the main world from 8,400 to **15,800** world units: **Crystal Hollow** (glowing quartz, cavern roof, stalactites, underground streams), **Celestial Highlands** (moving clouds, hanging islands, waterfalls, moving platforms), and **Shadowfen Marsh** (glowing fungi, marsh fog/fireflies, poisonous ground pools).
- **Four functional portals**, one in Moonhaven Village and one in each new region. Portals have locked/unlocked visuals and an interactive travel menu. Defeat the old Star Warden to open Crystal Hollow, the Crystal Titan to unlock the Highlands, and the Sky Herald to unlock Shadowfen. The portal network never bypasses locked bosses.
- **Three new realm bosses:** Crystal Titan, Sky Herald and Shadowfen Guardian, each with health, phase-dependent attacks, rewards, and one-time victory progression. New biome enemy variants pursue and attack the player.
- **World Atlas** accessible through the new MAP button; shows the connected region sequence and portal unlock progress.
- **Autosave compatible with v0.1 and v0.2:** all existing inventory, quest, gear, relic and rune progress is retained. New realm boss flags and portals default safely for older saves. Portal travel automatically saves its checkpoint.
- **Better mobile combat:** boss health panel works for all four bosses; larger on-screen attack/jump/skill controls, floating damage, and clear interaction text.
- **Godot CI gameplay tests** verify touchscreen motion, world gates, travel to all four destinations, the new bosses, environmental hazards, stage unlock progression, v0.2 save tests, and an Android APK signature/version check.

### Getting into the new worlds

1. Continue your existing save. If you already defeated the Star Warden, you are ready for the expansion.
2. Walk to the glowing **Portal Network** gate near the end of Moonhaven Village (around world x=1720), or choose **Explore Crystal Hollow** from the Star Warden victory screen.
3. Tap **TRAVEL**, choose an unlocked destination, and explore the next biome. Boss defeats unlock subsequent destinations. Your portal checkpoints save automatically.
4. Visit **MAP** at the top-right to view your current region and world progression.

All three new environments are connected along one continuous side-scrolling world; they are **not separate Godot scenes**. Portal travel provides practical shortcuts between their entrances.

---
# Echoes of Aether v0.2 — RELIC HUNTERS (Android)

**Major playable update** with permanent exploration rewards, combat enhancements and new challenges. Compatible with existing v0.1 Android saves and install-over updates.

## New in v0.2

- **Six hidden Aether caches**, across Moonhaven, Whisperwood and the Sunken Ruins. Stand near a glowing chest and use the OPEN action; each chest gives **1 relic shard + 25 coins**, only once per save.
- **Taro's Rune Trainer**, near the village's Wayfarer's Rest (world x~1510), offers three permanent powers for 2 shards each: **Windstep** (double jump), **Astral Edge** (+28 Aether Bolt damage and a faster projectile), and **Vital Spark** (+35 maximum stamina and quicker recovery).
- **Two one-time bounty hunts**, active automatically: defeat **3 moths** for 75 coins + 1 potion, and **2 sentinels** for 100 coins + 15 maximum HP. Rewards persist and cannot be claimed twice.
- **Mobile gameplay polish:** context-aware OPEN/TRAIN/SHOP/TALK buttons, visible dash cooldown countdown, boss HP bar, damage popups, atmospheric dusk effect, improved quests and inventory screens.
- **Legacy save migration** for saves made by the earlier APK. Continue Journey retains level, coins, gear, seeds, main quest and checkpoint while initializing new relic content to unopened.
- **GitHub CI** now tests real chest-opening progression, the three upgrades, double-jump, bounty rewards, old-save migration and original boss story, then verifies APK package ID, signing certificate and versionCode for update installs.

**Upgrade your existing phone install:** download the newest successful Actions artifact, unzip the APK and tap Update. Do *not* uninstall, because that can erase the local saved adventure. The same debug key and package ID are deliberately retained. This is an offline developer build, not a store-signed production release.

---

## Original playable foundation

Original Godot **4.5.2** project written in GDScript. Designed as an offline, landscape 2D mobile game. No third-party sprites, copyrighted game assets or mandatory online services.

**Status:** source-based first playable build candidate. Python project integrity checks pass. Full Godot import, Android CI export, on-device tests and long gameplay QA must still run; **do not treat an untested artifact as a released game.**

## What is actually implemented

- 3 connected zones: **Moonhaven Village**, **Whisperwood Forest**, **Sunken Ruins**, plus a final Astral Sanctum encounter.
- Hero run, jump, dash, sword attack, Aether Bolt projectile skill, health, stamina, invincibility, level/EXP.
- Five distinct normal enemies: moss slime, dusk moth, crystal beetle, stone sentinel, astral wisp. Patrol/chase/combat logic and enemies that fire projectiles. 
- Final Warden boss with 2 phases (more projectiles and faster movement below half HP).
- Village NPCs: **Mira** (main quest), **Lyra** (shop), **Taro** (controls/exploration hints).
- Complete main quest sequence: speak to Mira → defeat forest slimes and collect 3 seeds → cross the gate → defeat the Warden → victory.
- Coins, potion drops, Aether Seeds, health potions, permanent sword/armor upgrades, shops, inventory and quest log.
- Floating platforms, timed-enough jumpable pits, checkpoint/respawn logic, auto-save and continue.
- Landscaped touch UI: left move thumbstick; attack, jump, dash, skill, potion and NPC interaction on right. 
- Original pixel art and simple original music/sounds produced by `tools/generate_assets.py` (Pillow for generating sprites, standard-library `wave` for audio). **All generated assets are already included**; Python/Pillow are not required to play or build the game.
- Offline gameplay, no login, no permission request for network access.

## Build the APK with GitHub Actions (no local Android SDK)

1. Create a new GitHub repository, for example `EchoesOfAether`.
2. Upload **all** files/folders here, including the hidden `.github/workflows/android-apk.yml`. Put `project.godot` at the **repository root**, not inside another `EchoesOfAether` directory.
3. Push to `main`, or choose **Actions → Android APK (Godot) → Run workflow**.
4. When the workflow is green, open its run and scroll to **Artifacts**.
5. Download `EchoesOfAether-Android-debug-APK.zip`, unzip, then sideload the `.apk` on an Android arm64 smartphone.

The action downloads Godot 4.5.2 + matching export templates, prepares Android SDK and Java 17, runs static checks, performs a real headless Godot import, startup test and gameplay progression test (quest → seed collection → Warden victory → save/load), creates a signed **debug APK**, and uploads the APK as a workflow artifact.

**Debug signing:** the `dev-signing/aether-debug.keystore` is a stable **development-only** key so consecutive CI debug APKs can upgrade one another, preserving app data (as long as the package ID stays the same). The test password is intentionally public. **Never use this public debug key to sign a production release.** For public distribution, use a privately stored release keystore in GitHub Actions Secrets.

### Using Git on PC

```bash
# Inside the extracted EchoesOfAether folder
# Replace USERNAME and create the empty repository on GitHub first.
git init
git add .
git commit -m "Initial playable Aether adventure with Android CI"
git branch -M main
git remote add origin https://github.com/USERNAME/EchoesOfAether.git
git push -u origin main
```

## Update your existing Android installation (no uninstall)

For future fixes, **do not uninstall the game**. Download the newest **successful** Actions artifact, extract the APK, and open it on your phone. Android should offer **Update** or **Install** over the current app. Keep the installed game and its local save data.

The Android package ID stays `org.lokij.echoesofaether`, and the CI uses the same fixed development keystore. Each **new GitHub Actions run** now has a larger Android `versionCode`, and the workflow checks the APK package ID, versionCode and signing-certificate fingerprint before uploading it. A rerun of the *same* workflow run has the same versionCode; use a fresh run for a newer update.

Your saved journey (`user://aether_save.json`) should persist through an in-place APK update. If Android reports **App not installed**, don't uninstall your old game: check whether the installed APK was signed with a different key or is a higher-version build. A package ID/signing certificate mismatch cannot be fixed simply by changing the version code.

## Controls

| On Android | PC / Testing |
|---|---|
| Left joystick | A / D or arrow keys |
| Jump | Space / W / up arrow |
| Sword | J (hold to auto-attack) |
| Dash | Shift |
| Aether Bolt | K |
| Heal | H |
| Talk / Interact | E |
| Inventory | I |
| Quest journal | Q |
| Pause | Escape / P |

Start with **New Adventure**, walk right to Mira at x≈415, and tap **TALK**. If a dialogue appears, tap to close it before moving on.

## Android and debugging

- Screen orientation: Sensor Landscape.
- Export target: arm64-v8a, signed development APK; Android export preset in `export_presets.cfg`.
- Save file on device: `user://aether_save.json` (persistent internal app storage).
- If CI is red, read **Import assets and validate GDScript**, **Run game headless smoke test**, or **Export signed debug APK** steps; download `godot-build-logs` if offered.
- The CI smoke test only checks a headless startup. It does **not** replace hands-on touch/collision/game-completion testing on a phone.
- GitHub Actions artifacts are kept 30 days; releases can be added once the project has passed gameplay testing.

## Current limitations / next engineering passes

This first slice uses original compact pixel sprites and procedurally arranged environments. It does **not** yet include a fully hand-painted world, deeply branching NPC dialogues, a complex crafting system, sprite-sheet animation timelines, environmental puzzles, multiple story chapters, advanced pathfinding, or a device-tested release APK. The boss and five normal enemy archetypes are implemented, but their gameplay balance needs device playtesting. Expand these after the base loop works on your phone.

The code intentionally favors an integrated playable loop over pretending many unfinished features are complete.
