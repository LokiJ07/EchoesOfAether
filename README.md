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
