extends SceneTree
const MECHANICS = preload("res://scripts/AetherMechanics.gd")

func _initialize() -> void:
	call_deferred("run_tests")

func check(value: bool, label: String) -> bool:
	if value: return true
	push_error("AETHER MECHANICS FAILED: " + label)
	quit(1)
	return false

func run_tests() -> void:
	var recording: Dictionary = MECHANICS.start_recording()
	for i in range(100):
		MECHANICS.record_frame(recording, 0.1, Vector2(float(i), 250.0), i >= 30 and i < 70)
	if not check(not recording["recording"], "assertion 1: not recording['recording']"): return
	if not check(recording["playing"], "assertion 2: recording['playing']"): return
	if not check(recording["frames"].size() > 50, "assertion 3: recording['frames'].size() > 50"): return
	var echo: Dictionary = MECHANICS.clone_frame(recording, 4.0)
	if not check(echo["switch"], "assertion 4: echo['switch']"): return
	if not check(MECHANICS.can_open_echo_gate(echo, true), "assertion 5: MECHANICS.can_open_echo_gate(echo, true)"): return
	if not check(not MECHANICS.can_open_echo_gate(echo, false), "assertion 6: not MECHANICS.can_open_echo_gate(echo, false)"): return
	if not check(MECHANICS.toggle_era("present") == "past", "assertion 7: MECHANICS.toggle_era('present') == 'past'"): return
	if not check(MECHANICS.era_obstacle_passable("bridge", "past"), "assertion 8: MECHANICS.era_obstacle_passable('bridge', 'past')"): return
	if not check(not MECHANICS.era_obstacle_passable("bridge", "present"), "assertion 9: not MECHANICS.era_obstacle_passable('bridge', 'present')"): return
	if not check(MECHANICS.era_obstacle_passable("collapsed_wall", "present"), "assertion 10: MECHANICS.era_obstacle_passable('collapsed_wall', 'present')"): return
	var pulse: float = MECHANICS.sonar_pulse()
	if not check(MECHANICS.sonar_visible(pulse), "assertion 11: MECHANICS.sonar_visible(pulse)"): return
	if not check(not MECHANICS.sonar_visible(MECHANICS.update_sonar(pulse, 4.0)), "assertion 12: not MECHANICS.sonar_visible(MECHANICS.update_sonar(pulse, 4.0))"): return
	var scale: Dictionary = MECHANICS.new_scale(5, [2, 3, 2, 3])
	if not check(MECHANICS.scale_place(scale, 0, "left"), "assertion 13: MECHANICS.scale_place(scale, 0, 'left')"): return
	if not check(MECHANICS.scale_place(scale, 1, "left"), "assertion 14: MECHANICS.scale_place(scale, 1, 'left')"): return
	if not check(MECHANICS.scale_place(scale, 2, "right"), "assertion 15: MECHANICS.scale_place(scale, 2, 'right')"): return
	if not check(MECHANICS.scale_place(scale, 3, "right"), "assertion 16: MECHANICS.scale_place(scale, 3, 'right')"): return
	if not check(scale["solved"], "assertion 17: scale['solved']"): return
	if not check(MECHANICS.scale_place(scale, 3, "remove"), "assertion 18: MECHANICS.scale_place(scale, 3, 'remove')"): return
	if not check(not scale["solved"], "assertion 19: not scale['solved']"): return
	var melody: Dictionary = MECHANICS.new_melody([2, 0, 3, 1])
	if not check(MECHANICS.play_note(melody, 2), "assertion 20: MECHANICS.play_note(melody, 2)"): return
	if not check(not MECHANICS.play_note(melody, 3), "assertion 21: not MECHANICS.play_note(melody, 3)"): return
	if not check(melody["progress"] == 0, "assertion 22: melody['progress'] == 0"): return
	for note in [2, 0, 3, 1]:
		if not check(MECHANICS.play_note(melody, note), "assertion 23: MECHANICS.play_note(melody, note)"): return
	if not check(melody["solved"], "assertion 24: melody['solved']"): return
	var glyphs: Dictionary = {}
	if not check(MECHANICS.learn_glyph(glyphs, "△", "MOON"), "assertion 25: MECHANICS.learn_glyph(glyphs, '△', 'MOON')"): return
	if not check(MECHANICS.decipher(["△", "◇"], glyphs) == "MOON ?", "assertion 26: MECHANICS.decipher(['△', '◇'], glyphs) == 'MOON ?'"): return
	print("AETHER MECHANICS TESTS PASSED")
	quit(0)
