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
