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
for symbol in ['func open_cache(', 'func unlock_rune(', 'func register_hunt(', 'func nearby_cache_index(', 'func update_floating_text(', 'save_version": 20']:
    assert symbol in contents, f"Missing Relic Hunters gameplay: {symbol}"
hud=(r/'scripts/HUD.gd').read_text()
for symbol in ['func draw_trainer(', 'func draw_boss_health(', 'func draw_dash_button(']:
    assert symbol in hud, f"Missing Relic Hunters UI: {symbol}"
for symbol in ["func guard(", "func trigger_guard_counter(", "combo_stage", "mastery_rewards", '"save_version": 20']:
    assert symbol in contents, f"Missing v0.6 combat system: {symbol}"
for symbol in ["func editor_touch_press(", "func editor_touch_drag(", "func editor_touch_release(", "func reset_control_layout(", "func save_control_layout(", "user://aether_controls.json", "func draw_hud_editor("]:
    assert symbol in hud, f"Missing v0.6 control customization: {symbol}"
assert (r/"tests/v06_custom_hud.gd").is_file(), "Missing v0.6 playable regression suite"
assert 'window/handheld/orientation=4' in (r/'project.godot').read_text()
assert 'window/stretch/aspect="expand"' in (r/'project.godot').read_text(), "Ultrawide phones must not be letterboxed"
assert 'screen/support_small=true' in preset, "Small Android screens must be supported"
assert 'func safe_layout_rect(' in hud and 'func default_control_centers_for(' in hud, "Missing adaptive HUD layout"
assert 'func active_control_scale(' in hud, "Touch target size must scale with viewport"
assert 'WORLD_WIDTH := 23000.0' in contents
for symbol in ['func portal_jump(', 'func nearby_portal_index(', 'func active_boss_info(', 'func draw_expansion_scenery(', 'func draw_expansion_scenery(', 'func go_expansion_world(', 'func update_moving_platforms(', 'func expansion_quest_label(']:
    assert symbol in contents, f"Missing World Expansion mechanic: {symbol}"
for symbol in ['func draw_portal_network(', 'func draw_world_map(', 'func draw_realm_victory(']:
    assert symbol in hud, f"Missing World Expansion UI: {symbol}"
assert Path(r/'tests/world_expansion.gd').is_file()
assert 'tests/world_expansion.gd' in workflow
print("PASS: World Expansion regions, fullscreen stretch, portal UI and Godot tests")
print("PASS: referenced assets, Android CI build/export, and landscape orientation")

for symbol in ["func nearby_shrine_index(", "func open_echo_puzzle(", "func choose_echo_rune(", "func leave_echo_puzzle(", "func hero_animation_params(", "func load_realm_backdrops(", "func load_visual_preferences(", '"save_version": 20']:
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
    "func mobile_action_at(", "func hud_event_position(", '"save_version": 20']:
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
