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
for symbol in ['func open_cache(', 'func unlock_rune(', 'func register_hunt(', 'func nearby_cache_index(', 'func update_floating_text(', 'save_version": 6']:
    assert symbol in contents, f"Missing Relic Hunters gameplay: {symbol}"
hud=(r/'scripts/HUD.gd').read_text()
for symbol in ['func draw_trainer(', 'func draw_boss_health(', 'func draw_dash_button(']:
    assert symbol in hud, f"Missing Relic Hunters UI: {symbol}"
for symbol in ["func guard(", "func trigger_guard_counter(", "combo_stage", "mastery_rewards", '"save_version": 6']:
    assert symbol in contents, f"Missing v0.6 combat system: {symbol}"
for symbol in ["func editor_touch_press(", "func editor_touch_drag(", "func editor_touch_release(", "func reset_control_layout(", "func save_control_layout(", "user://aether_controls.json", "func draw_hud_editor("]:
    assert symbol in hud, f"Missing v0.6 control customization: {symbol}"
assert (r/"tests/v06_custom_hud.gd").is_file(), "Missing v0.6 playable regression suite"
assert 'window/handheld/orientation=4' in (r/'project.godot').read_text()
assert 'window/stretch/aspect="expand"' in (r/'project.godot').read_text(), "Ultrawide phones must not be letterboxed"
assert 'WORLD_WIDTH := 15800.0' in contents
for symbol in ['func portal_jump(', 'func nearby_portal_index(', 'func active_boss_info(', 'func draw_expansion_scenery(', 'func draw_expansion_scenery(', 'func go_expansion_world(', 'func update_moving_platforms(', 'func expansion_quest_label(']:
    assert symbol in contents, f"Missing World Expansion mechanic: {symbol}"
for symbol in ['func draw_portal_network(', 'func draw_world_map(', 'func draw_realm_victory(']:
    assert symbol in hud, f"Missing World Expansion UI: {symbol}"
assert Path(r/'tests/world_expansion.gd').is_file()
assert 'tests/world_expansion.gd' in workflow
print("PASS: World Expansion regions, fullscreen stretch, portal UI and Godot tests")
print("PASS: referenced assets, Android CI build/export, and landscape orientation")
