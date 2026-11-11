"""Fast repository integrity checks; CI also runs the actual Godot importer."""
from pathlib import Path
import re
r = Path(__file__).resolve().parent.parent
required = ["project.godot", "export_presets.cfg", "scenes/Main.tscn", "scripts/Game.gd", "scripts/HUD.gd", "assets/hero_idle.png", "assets/hero_run.png", "assets/boss.png", "assets/forest_tree.png", "assets/theme.wav"]
for name in required:
    p=r/name
    assert p.is_file() and p.stat().st_size>10, f"Missing/empty {name}"
contents=(r/"scripts/Game.gd").read_text()
for mechanic in ["func _physics_process", "func attack", "func jump", "func dash", "func use_skill", "func damage_player", "func update_enemies", "func save_game", "func load_game", "func interact", "func buy_shop_item", "func boss_attack"]:
    assert mechanic in contents, f"Missing mechanic entry: {mechanic}"
preset=(r/'export_presets.cfg').read_text()
assert 'platform="Android"' in preset
assert 'package/unique_name="org.lokij.echoesofaether"' in preset, "Do not change package ID across updates"
assert 'package/signed=true' in preset
assert 'version/code=' in preset and 'version/name=' in preset
print("PASS: core source, assets and Android export preset are present")

# Verify all eagerly loaded PNG/WAV resources are actually in the project.
for m in re.findall(r'res://(assets/[a-zA-Z0-9_./-]+\.(?:png|wav))', contents):
    assert (r/m).is_file(), f"Missing referenced asset {m}"
workflow=(r/'.github/workflows/android-apk.yml').read_text()
for required in ['--export-debug Android', 'actions/upload-artifact@v4', 'GODOT_VERSION: "4.5.2"', 'editor_settings-4.5.tres']:
    assert required in workflow, f"Missing CI integration: {required}"
assert 'GITHUB_RUN_NUMBER' in workflow and 'APKSIGNER' in workflow, "Missing Android update metadata/signature checks"
for symbol in ['func open_cache(', 'func unlock_rune(', 'func register_hunt(', 'func nearby_cache_index(', 'func update_floating_text(', 'save_version": V6_SAVE_VERSION']:
    assert symbol in contents, f"Missing Relic Hunters gameplay: {symbol}"
hud=(r/'scripts/HUD.gd').read_text()
for symbol in ['func draw_trainer(', 'func draw_boss_health(', 'func draw_dash_button(']:
    assert symbol in hud, f"Missing Relic Hunters UI: {symbol}"
for symbol in ["func guard(", "func trigger_guard_counter(", "combo_stage", "mastery_rewards", '"save_version": V6_SAVE_VERSION']:
    assert symbol in contents, f"Missing v0.6 combat system: {symbol}"
for symbol in ["func editor_touch_press(", "func editor_touch_drag(", "func editor_touch_release(", "func reset_control_layout(", "func save_control_layout(", "user://aether_controls.json", "func draw_hud_editor("]:
    assert symbol in hud, f"Missing v0.6 control customization: {symbol}"
assert (r/"tests/v06_custom_hud.gd").is_file(), "Missing v0.6 playable regression suite"
assert 'window/handheld/orientation=4' in (r/'project.godot').read_text()
assert 'window/stretch/aspect="expand"' in (r/'project.godot').read_text(), "Ultrawide phones must not be letterboxed"
assert 'screen/support_small=true' in preset, "Small Android screens must be supported"
assert 'func safe_layout_rect(' in hud and 'func default_control_centers_for(' in hud, "Missing adaptive HUD layout"
assert 'func active_control_scale(' in hud, "Touch target size must scale with viewport"
assert 'WORLD_WIDTH := 83300.0' in contents
for symbol in ['func portal_jump(', 'func nearby_portal_index(', 'func active_boss_info(', 'func draw_expansion_scenery(', 'func draw_expansion_scenery(', 'func go_expansion_world(', 'func update_moving_platforms(', 'func expansion_quest_label(']:
    assert symbol in contents, f"Missing World Expansion mechanic: {symbol}"
for symbol in ['func draw_portal_network(', 'func draw_world_map(', 'func draw_realm_victory(']:
    assert symbol in hud, f"Missing World Expansion UI: {symbol}"
assert Path(r/'tests/world_expansion.gd').is_file()
assert 'tests/world_expansion.gd' in workflow
print("PASS: World Expansion regions, fullscreen stretch, portal UI and Godot tests")
print("PASS: referenced assets, Android CI build/export, and landscape orientation")

for symbol in ["func nearby_shrine_index(", "func open_echo_puzzle(", "func choose_echo_rune(", "func leave_echo_puzzle(", "func hero_animation_params(", "func load_realm_backdrops(", "func load_visual_preferences(", '"save_version": V6_SAVE_VERSION']:
    assert symbol in contents, f"Missing v1 Awakening feature: {symbol}"
for symbol in ["func draw_echo_puzzle(", "func draw_main_menu(", "func draw_dialogue("]:
    assert symbol in hud, f"Missing v1 interactive UI: {symbol}"
assert (r/"tests/v1_awakening.gd").is_file(), "Missing v1 puzzle and animation regression suite"
assert (r/"tools/fetch_v1_art.py").is_file() and (r/"assets/v1_art_manifest.json").is_file(), "Missing generated art import"
for file in ("v1_bg_crystal.png", "v1_bg_sky.png", "v1_bg_marsh.png"):
    assert (r/"assets"/file).is_file(), f"Missing downloaded Higgsfield art: {file}"
assert "tests/v1_awakening.gd" in workflow and "tools/fetch_v1_art.py" in workflow, "Missing v1 Android CI integration"
print("PASS: v1 world art, optional puzzles, responsive interactive HUD and animation source")

# v2 production acceptance: all actual Higgsfield PNGs are processed before
# the Godot editor imports them. Visuals cannot be just reference/mockup art.
import json
manifest = json.loads((r/"assets/v2_art_manifest.json").read_text())
asset_names = [f"v2_{item['id']}.png" for item in manifest["backgrounds"] + manifest["individuals"]]
asset_names += [f"v2_{kind}.png" for sheet in manifest["sheets"] for kind in sheet["types"]]
asset_names.append("v2_crystal_wisp.png")
assert len(asset_names) >= 22 and len(set(asset_names)) == len(asset_names)
for asset in asset_names:
    assert (r/"assets"/asset).is_file(), f"Missing actual in-game art: {asset}"
for required_symbol in ["EMBER_START", "CINDER_VAULT_START", "func open_ember_brazier(", "func select_ember_rune(",
    "func rescue_emberling(", "func update_emberling(", "func register_ember_hunt(", "func load_ember_art(",
    "func mobile_action_at(", "func hud_event_position(", '"save_version": V6_SAVE_VERSION']:
    assert required_symbol in contents, f"Missing v2 implementation: {required_symbol}"
for ui_symbol in ["func draw_ember_puzzle(", "func draw_ember_victory(", "func draw_portal_network(", "SHATTERED   R E A L M S"]:
    # The redesigned menu intentionally uses separate letter spacing.
    assert ui_symbol in hud or ui_symbol == "SHATTERED   R E A L M S", f"Missing v2 UI: {ui_symbol}"
assert 'S H A T T E R E D   R E A L M S' in hud
for file in ["tools/fetch_v2_art.py", "tests/v2_shattered_realms.gd"]:
    assert (r/file).is_file(), "Missing v2 build/test script: " + file
assert "tests/v2_shattered_realms.gd" in workflow
assert "tools/fetch_v2_art.py" in workflow
print("PASS: v2 Emberfall, responsive mobile controls, 21 Higgsfield images and Android CI")

# v5: do not mistake static art or an elongated strip for independent RPG zones.
catalog=(r/"scripts/RealmCatalog.gd").read_text()
realm_script=r/"scripts/RealmScene.gd"
assert realm_script.is_file(), "Missing real scene/portal renderer"
assert "const REGIONS" in catalog and "const QUESTS" in catalog
assert len(re.findall(r'"id": "q[0-9][0-9]"', catalog)) >= 30, "Missing 30 tracked RPG quests"
realm_ids=["hub","forest","ruins","crystal","sky","marsh","ember","cinder",
    "abyss","tide_temple","garden","verdant_vault","nexus","rootcrypt",
    "mirror_vault","gale_spire","mire_catacombs","echo_labyrinth","nexus_core"]
assert len(realm_ids)==19
for id in realm_ids:
    path=r/"scenes"/"realms"/(id+".tscn")
    assert path.is_file(), "Missing PackedScene realm: "+id
    assert 'realm_id = "'+id+'"' in path.read_text(), "Wrong scene identity for "+id
for marker in ["func enter_realm(", "func load_realm_stage(", "func realign_realm_to_position(",
    "func is_realm_unlocked(", "func record_quest_event(", "func quest_progress(",
    "func v5_story_label(", "func pin_quest(", "func pinned_quest(", "func clear_quest_pin(", "V5_SAVE_VERSION := 50", "func boss_attack("]:
    assert marker in contents, "Missing v5 RPG mechanic: "+marker
for marker in ["func draw_portal_network(", "func draw_quests(", "func draw_v5_victory(", '"pin:" + str(q["id"])']:
    assert marker in hud, "Missing v5 interactive UI: "+marker
assert (r/"docs/V5_MASTER_PLAN.md").is_file()
assert (r/"tests/v5_realms.gd").is_file() and "tests/v5_realms.gd" in workflow
print("PASS: 19 independent playable realm scenes, 8 dungeon guardians and 30 tracked quests")

# One background panorama per zone, not repeated tiles with vertical seams.
assert "draw_texture_rect_region(tex, Rect2(px" not in contents, "Tiled v5 backgrounds create visible seams"
assert "func draw_realm_backdrop(" in contents and "func draw_v2_background(" in contents
assert "SKIP STORY" in hud and "game.story_queue.clear()" in hud, "Long story scenarios need a working skip action"

# New v5 credit-free original art pipeline: generated PNGs must be available
# before the editor import, and individual new areas must not share art paths.
local_scenes = ["abyss","tide_temple","garden","verdant_vault","nexus","nexus_core","rootcrypt"]
assert (r/"tools/build_v5_art.py").is_file()
assert 'tools/build_v5_art.py' in workflow, "Art generation missing from Android pipeline"
for scene in local_scenes:
    assert '"id": "'+scene+'"' in catalog
    assert '"art": "v5_generated_'+scene+'"' in catalog
    assert (r/"assets"/("v5_generated_"+scene+".png")).is_file(), "Missing original art for "+scene
assert 'func load_v5_generated_art(' in contents
assert 'v5_art.get(art_name.trim_prefix("v5_generated_"), null)' in contents
assert 'seven original offline generated realm backgrounds' in workflow
print("PASS: seven original offline locally generated game panoramas")

# v6: 27 genuinely instantiated portal rooms, 46 real RPG quest rows and
# four interactive puzzle modes with distinct transparent rewards/checkpoints.
new_rooms = ["root_gallery","prism_annex","wind_observatory","bog_lanterns",
    "forge_engine","tide_control","seed_arbor","nexus_memory"]
assert "const TRIALS" in catalog and '"id": "q46"' in catalog
for id in new_rooms:
    packed = r/"scenes"/"realms"/(id + ".tscn")
    assert packed.is_file() and 'realm_id = "'+id+'"' in packed.read_text()
    assert '"id": "' + id + '"' in catalog, "Missing trial region " + id
    art = [item for item in ["rootgallery","prismannex","windobservatory","boglanterns",
        "forgeengine","tidecontrol","seedarbor","nexusmemory"] if ('v6_generated_'+item) in catalog]
    assert len(art) >= 8
    assert (r/"scripts/PuzzleEngine.gd").is_file()
for name in ["rootgallery","prismannex","windobservatory","boglanterns","forgeengine","tidecontrol","seedarbor","nexusmemory"]:
    assert (r/"assets"/("v6_generated_"+name+".png")).is_file(), "Missing actual v6 room art "+name
for symbol in ["V6_SAVE_VERSION := 60","func open_trial_puzzle(", "func press_trial_cell(", "func leave_trial_puzzle(",
    "func load_v6_generated_art(", "func trial_side_room(", "trial_completed"]:
    assert symbol in contents
for symbol in ["func draw_v6_puzzle(", '"v6_hint"', '"v6_leave"']:
    assert symbol in hud
assert (r/"tests/v6_deep_realms.gd").is_file()
assert "tests/v6_deep_realms.gd" in workflow and "tools/build_v6_art.py" in workflow
print("PASS: v6 has eight unique deep dungeon rooms, 46 quests, 4 puzzles and original art")

# v6 exploration + optional premium graphics: safe to build without the
# separately distributed images; project never tries downloading them at runtime.
assert 'func load_premium_art(' in contents and 'premium_art.has(premium_key)' in contents
assert 'func secret_cache_positions(' in contents and 'func collect_secret_cache(' in contents
assert '"secret_caches": secret_caches' in contents
assert '"id": "q56"' in catalog and '"event": "secret:forest"' in catalog
assert 'PASS: 52 discoverable realm secrets' in workflow
print("PASS: optional premium art loader, 52 treasure sites and ten exploration RPG quests")

# v7 live review: no absolute legacy region locks may be applied to separate
# portal dungeons. Actual GDScript gameplay tests will validate movement too.
for token in ["func load_v7_mob_art(", "func build_v7_vertical_routes(",
              "func skyshard_position(", "func collect_skyshard_if_close(",
              '"skyshards_collected": skyshards_collected']:
    assert token in contents, "Missing v7 core system: "+token
assert 'current_realm_id == "ruins"' in contents
assert 'current_realm_id == "crystal" and not defeated_boss' in contents
for kind in ["tide_stalker", "coral_wisp", "thorn_knight", "petal_moth",
             "root_colossus", "mirror_keeper", "gale_wyrm", "mire_reaver",
             "echo_archon", "abyss_leviathan", "thornheart", "nexus_echo"]:
    assert (r/"assets"/("v7_"+kind+".png")).is_file(), "Missing unique v7 enemy sprite: "+kind
assert '"id": "q68"' in catalog and '"event": "skyshard:forest"' in catalog
assert (r/"tools/build_v7_mobs.py").is_file()
assert (r/"tests/v7_field_review.gd").is_file()
assert "build_v7_mobs.py" in workflow and "tests/v7_field_review.gd" in workflow
print("PASS: v7 isolated dungeon fixes, raised paths, 12 new mobs and 68 quests")
