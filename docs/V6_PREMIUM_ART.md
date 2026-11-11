# Echoes of Aether v6 — Premium Art Import

The detailed original landscape images were generated independently of Higgsfield. This 10-image pack is a higher-resolution **optional** replacement for existing procedural realm art. Their output is NOT yet embedded in the GitHub repository unless the files below appear in `assets/`.

## Auto-load artwork filenames

Extract the provided **EchoesOfAether_V6_Premium_Import_Ready.zip** at the repository root (where `project.godot` lives). Preserve the `assets/` prefix:

- `assets/v6_premium_hub.jpg` — Moonhaven/Aether Crossroads
- `assets/v6_premium_forest.jpg` — Whisperwood Vale
- `assets/v6_premium_rootcrypt.jpg` — Rootbound Crypt
- `assets/v6_premium_crystal.jpg` — Crystal Hollow
- `assets/v6_premium_mirror_vault.jpg` — Mirror Vault
- `assets/v6_premium_marsh.jpg` — Shadowfen Marsh
- `assets/v6_premium_mire_catacombs.jpg` — Mire Catacombs
- `assets/v6_premium_abyss.jpg` — Abyssal Depths
- `assets/v6_premium_tide_temple.jpg` — Temple of the Tide
- `assets/v6_premium_garden.jpg` — Everdawn Gardens

Commit those ten JPG files to GitHub. On the next GitHub Actions run, Godot imports them into the APK, and `Game.gd::load_premium_art()` caches the texture for each map. `Game.gd::_draw()` prioritizes premium art for the current separate portal scene, without repeating one background across adjacent maps. Graphics quality Low can disable the optional artwork and use the cheaper fallback.

The premium images are *scenery*, not actual collider meshes, enemies, interaction objects, or pathfinding; gameplay platforms and puzzles are rendered separately by Godot.

## Quality guarantees and limits

- Android app identifier, signing keystore, user save and HUD editor remain unchanged.
- The baseline CI build **does not fail** if these optional images are missing.
- Never claim that an optional image is inside an APK until the file exists in `assets/` on that build's GitHub commit.
- Each premium JPG is about 1600×900 resolution; combined import-ready archive is ~8.3 MB.
- Actual texture/art direction and touchscreen readability still require a phone playtest.
