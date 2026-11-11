extends Node2D
## V9 world-space riddles, separate from menu puzzles:
## MIRROR VAULT: switch real floor and wall collision between past/present.
## SUNKEN RUINS: cast short sonar pulses and discover physically hidden glyphs.

const MECHANICS = preload("res://scripts/AetherMechanics.gd")
const MIRROR_START := 46600.0
const PHASE_PRISMS := [MIRROR_START + 780.0, MIRROR_START + 1850.0]
const BRIDGE_LEFT := MIRROR_START + 1200.0
const BRIDGE_RIGHT := MIRROR_START + 1680.0
const MIRROR_WALL := MIRROR_START + 2140.0
const MIRROR_RELIC := MIRROR_START + 2550.0
const RUINS_START := 4750.0
const SONAR_TOWERS := [RUINS_START + 1280.0, RUINS_START + 1940.0, RUINS_START + 2630.0]
const SONAR_GLYPHS := [RUINS_START + 1510.0, RUINS_START + 2240.0, RUINS_START + 2420.0]
const FLOOR_Y := 500.0

var game
var era := "present"
var bridge_crossed := false
var mirror_completed := false
var sonar_time := 0.0
var sonar_collected: Array = []
var sonar_completed := false
var wall_warning := 0.0

func _ready() -> void:
	game = get_parent()

func reset_runtime() -> void:
	era = "present"
	bridge_crossed = false
	sonar_time = 0.0
	wall_warning = 0.0
	queue_redraw()

func reset_progress() -> void:
	reset_runtime()
	mirror_completed = false
	sonar_completed = false
	sonar_collected.clear()

func restore_progress(data: Dictionary) -> void:
	reset_runtime()
	mirror_completed = bool(data.get("mirror_trial_complete", false))
	sonar_collected.clear()
	var stored = data.get("sonar_sigils", [])
	if stored is Array:
		for value in stored:
			var index: int = int(value)
			if index in [0, 1, 2] and not sonar_collected.has(index):
				sonar_collected.append(index)
	sonar_completed = bool(data.get("sonar_trial_complete", false)) or sonar_collected.size() == 3
	if sonar_completed:
		sonar_collected = [0, 1, 2]

func in_mirror() -> bool:
	return game != null and game.current_realm_id == "mirror_vault"

func in_ruins() -> bool:
	return game != null and game.current_realm_id == "ruins"

func live_mirror() -> bool:
	return in_mirror() and game.state == "playing" and not mirror_completed

func live_sonar() -> bool:
	return in_ruins() and game.state == "playing" and not sonar_completed

func near_phase_prism() -> bool:
	if not live_mirror():
		return false
	for x in PHASE_PRISMS:
		if absf(game.player_pos.x - x) < 86.0 and absf(game.player_pos.y - FLOOR_Y) < 127.0:
			return true
	return false

func try_shift_era() -> bool:
	if not near_phase_prism():
		return false
	era = MECHANICS.toggle_era(era)
	game.show_message("MIRROR VAULT: %s ERA. %s" % [era.to_upper(),
		"BRIDGE SOLID — CROSS IT" if era == "past" else "ANCIENT WALL OPENS AFTER CROSSING THE BRIDGE"], 3.2)
	game.play_sfx("skill")
	queue_redraw()
	return true

func mirror_gap_at(x: float) -> bool:
	return in_mirror() and not mirror_completed and x >= BRIDGE_LEFT and x <= BRIDGE_RIGHT and not MECHANICS.era_obstacle_passable("bridge", era)

func mirror_wall_open() -> bool:
	# Crossing the restored PAST bridge is necessary, but only PRESENT can open the chronogate.
	return mirror_completed or (bridge_crossed and era == "present")

func block_mirror_wall(old_x: float) -> void:
	if not live_mirror() or mirror_wall_open():
		return
	if old_x <= MIRROR_WALL - 25.9 and game.player_pos.x > MIRROR_WALL - 26.0:
		game.player_pos.x = MIRROR_WALL - 26.0
		game.velocity.x = minf(game.velocity.x, 0.0)
		if wall_warning <= 0.0:
			wall_warning = 2.0
			game.show_message("TIMELOCK: Cross the PAST bridge, then switch to PRESENT!", 3.0)

func near_sonar_tower() -> bool:
	if not live_sonar():
		return false
	for x in SONAR_TOWERS:
		if absf(game.player_pos.x - x) < 85.0 and absf(game.player_pos.y - FLOOR_Y) < 125.0:
			return true
	return false

func near_visible_sigil() -> int:
	if not live_sonar() or not MECHANICS.sonar_visible(sonar_time):
		return -1
	for i in range(SONAR_GLYPHS.size()):
		if sonar_collected.has(i): continue
		if absf(game.player_pos.x - SONAR_GLYPHS[i]) < 76.0 and absf(game.player_pos.y - FLOOR_Y) < 130.0:
			return i
	return -1

func try_interact() -> bool:
	if near_phase_prism():
		return try_shift_era()
	var sigil: int = near_visible_sigil()
	if sigil >= 0:
		sonar_collected.append(sigil)
		game.play_sfx("loot")
		game.spawn_dust(Vector2(SONAR_GLYPHS[sigil], FLOOR_Y - 70.0), Color("9ff7fa"), 14)
		if sonar_collected.size() == 3:
			complete_sonar()
		else:
			game.show_message("HIDDEN GLYPH FOUND: %d / 3. Follow the next sonar tower!" % sonar_collected.size(), 3.2)
			game.save_game()
		return true
	if near_sonar_tower():
		sonar_time = MECHANICS.sonar_pulse()
		game.show_message("SONAR ACTIVE: 3.5 SECONDS. Find and INTERACT with the blue glyph!", 3.5)
		game.play_sfx("skill")
		queue_redraw()
		return true
	return false

func update_events(dt: float) -> void:
	wall_warning = maxf(0.0, wall_warning - dt)
	if live_mirror():
		if era == "past" and game.player_pos.x > BRIDGE_RIGHT + 35.0 and game.player_pos.x < MIRROR_WALL and absf(game.player_pos.y - FLOOR_Y) < 175.0:
			bridge_crossed = true
		if game.player_pos.x > MIRROR_RELIC - 76.0 and absf(game.player_pos.y - FLOOR_Y) < 125.0:
			complete_mirror()
	if live_sonar():
		sonar_time = MECHANICS.update_sonar(sonar_time, dt)
	queue_redraw()

func complete_mirror() -> void:
	if mirror_completed or not in_mirror():
		return
	mirror_completed = true
	game.coins += 195
	game.relic_shards += 1
	game.gain_exp(130)
	game.record_quest_event("trial:mirror_shift")
	game.show_message("MIRROR VAULT RESTORED! +195 COINS & 1 RELIC", 4.0)
	game.play_sfx("win")
	game.save_game()

func complete_sonar() -> void:
	if sonar_completed or not in_ruins():
		return
	sonar_completed = true
	sonar_time = 0.0
	game.coins += 170
	game.relic_shards += 1
	game.gain_exp(115)
	game.record_quest_event("trial:sonar_glyphs")
	game.show_message("SONAR ARCHIVES RECONSTRUCTED! +170 COINS & 1 RELIC", 4.0)
	game.play_sfx("win")
	game.save_game()

func status_text() -> String:
	if in_mirror():
		if mirror_completed:
			return "MIRROR VAULT: TIMELINE RESTORED"
		return "MIRROR: %s  |  %s" % [era.to_upper(),
			"CROSS PAST BRIDGE, SWITCH TO PRESENT" if not bridge_crossed else
			"SHIFT TO PRESENT AT THE PRISM TO UNLOCK THE WALL"]
	if in_ruins():
		if sonar_completed:
			return "SONAR ARCHIVE: ALL GLYPHS RESTORED"
		return "SONAR: %d/3  |  %s" % [sonar_collected.size(),
			"PULSE ACTIVE — SEARCH FOR THE BLUE GLYPH" if sonar_time > 0.0 else
			"FIND A SONAR TOWER AND PRESS INTERACT"]
	return ""

func _process(_dt: float) -> void:
	if in_mirror() or in_ruins():
		queue_redraw()

func _draw() -> void:
	if in_mirror():
		draw_mirror_vault()
	elif in_ruins():
		draw_sonar_ruins()

func draw_mirror_vault() -> void:
	var f: Font = ThemeDB.fallback_font
	var seconds: float = game.elapsed if not game.reduced_motion else 0.0
	# Massive mirror ribs, suspended prisms and an era-sensitive floor.
	for i in range(8):
		var x: float = MIRROR_START + 380.0 + float(i) * 330.0
		draw_arc(Vector2(x, 294.0), 98.0, PI, TAU, 30,
			Color("6b98b9") if era == "past" else Color("665e9e"), 4.0)
		draw_rect(Rect2(x - 42.0, 175.0, 84.0, 260.0), Color(0.10, 0.16, 0.29, 0.40))
		draw_line(Vector2(x, 180.0), Vector2(x, 320.0), Color(0.61, 0.78, 0.99, 0.25), 3.0)
	for x in PHASE_PRISMS:
		var tint: Color = Color("f4d5a4") if era == "past" else Color("9dcaf8")
		draw_circle(Vector2(x, 364.0), 48.0, Color(tint.r, tint.g, tint.b, 0.15))
		draw_rect(Rect2(x - 34.0, 435.0, 68.0, 65.0), Color("263450"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, 289.0), Vector2(x - 26.0, 359.0),
			Vector2(x, 405.0), Vector2(x + 26.0, 359.0)]), tint)
		draw_string(f, Vector2(x - 67.0, 267.0), "TIME PRISM", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("e8eafa"))
	# Gap is actual missing ground in PRESENT; in PAST a solid collision floor exists.
	if era == "past" or mirror_completed:
		draw_rect(Rect2(BRIDGE_LEFT, FLOOR_Y - 9.0, BRIDGE_RIGHT - BRIDGE_LEFT, 26.0), Color("a4dbc9"))
		for i in range(8):
			var px: float = BRIDGE_LEFT + float(i) * 60.0
			draw_rect(Rect2(px + 9.0, FLOOR_Y - 16.0, 41.0, 9.0), Color("e0f9d0"))
	else:
		draw_rect(Rect2(BRIDGE_LEFT, FLOOR_Y - 15.0, BRIDGE_RIGHT - BRIDGE_LEFT, 38.0), Color(0.08, 0.06, 0.17, 0.84))
		for i in range(8):
			draw_line(Vector2(BRIDGE_LEFT + float(i) * 60.0, FLOOR_Y + 2.0), Vector2(BRIDGE_LEFT + float(i) * 60.0 + 25.0, FLOOR_Y + 30.0), Color("b685d4"), 2.0)
	draw_string(f, Vector2(BRIDGE_LEFT + 50.0, 393.0), "THE BRIDGE EXISTS IN THE PAST", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e6e2ce"))
	if not mirror_wall_open():
		draw_rect(Rect2(MIRROR_WALL - 24.0, 171.0, 48.0, 329.0), Color("252b49"))
		for i in range(5):
			draw_rect(Rect2(MIRROR_WALL - 29.0, 179.0 + float(i) * 70.0, 58.0, 11.0), Color("9c83c4"))
		draw_arc(Vector2(MIRROR_WALL, 317.0), 43.0, 0.0, TAU, 32, Color("deb7f9"), 3.0)
	else:
		draw_arc(Vector2(MIRROR_WALL, 317.0), 49.0, 0.0, TAU, 32, Color("91f9c8"), 4.0)
	draw_string(f, Vector2(MIRROR_WALL - 75.0, 150.0), "TIMELINE GATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("d9d5fc"))
	draw_rect(Rect2(MIRROR_RELIC - 45.0, 452.0, 90.0, 48.0), Color("273754"))
	if not mirror_completed:
		var glow: float = 0.63 + 0.37 * sin(seconds * 2.5)
		draw_circle(Vector2(MIRROR_RELIC, 381.0), 55.0, Color(0.58, 0.85, 1.0, 0.12 + glow * 0.12))
		draw_colored_polygon(PackedVector2Array([
			Vector2(MIRROR_RELIC, 318.0), Vector2(MIRROR_RELIC + 32.0, 384.0),
			Vector2(MIRROR_RELIC, 437.0), Vector2(MIRROR_RELIC - 32.0, 384.0)]), Color("e1ecff"))
		draw_string(f, Vector2(MIRROR_RELIC - 76.0, 297.0), "CHRONO RELIC", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("dbe7ff"))
	else:
		draw_string(f, Vector2(MIRROR_RELIC - 80.0, 381.0), "TIME RESTORED", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("bcf4d7"))

func draw_sonar_ruins() -> void:
	var f: Font = ThemeDB.fallback_font
	var seconds: float = game.elapsed if not game.reduced_motion else 0.0
	for i in range(SONAR_TOWERS.size()):
		var x: float = SONAR_TOWERS[i]
		draw_rect(Rect2(x - 32.0, FLOOR_Y - 94.0, 64.0, 94.0), Color("183952"))
		draw_rect(Rect2(x - 39.0, FLOOR_Y - 98.0, 78.0, 14.0), Color("6489a1"))
		draw_arc(Vector2(x, FLOOR_Y - 124.0), 35.0, 0.0, TAU, 30, Color("7bf6fc"), 3.0)
		draw_circle(Vector2(x, FLOOR_Y - 124.0), 12.0, Color("b2faff"))
		if sonar_time > 0.0:
			var radius: float = 35.0 + (3.5 - sonar_time) * 85.0
			draw_arc(Vector2(x, FLOOR_Y - 124.0), radius, 0.0, TAU, 48, Color(0.3, 0.94, 1.0, 0.30), 3.0)
		draw_string(f, Vector2(x - 65.0, FLOOR_Y - 174.0), "SONAR TOWER", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("dafffe"))
	for i in range(SONAR_GLYPHS.size()):
		var x: float = SONAR_GLYPHS[i]
		if sonar_collected.has(i):
			draw_circle(Vector2(x, FLOOR_Y - 70.0), 7.0, Color("6ab3ae"))
			continue
		if not MECHANICS.sonar_visible(sonar_time):
			# Entirely concealed until the pulse; no permanent arrow or simple answer key.
			continue
		var shimmer: float = 0.5 + 0.5 * sin(seconds * 4.0 + float(i))
		draw_circle(Vector2(x, FLOOR_Y - 77.0), 47.0, Color(0.39, 0.93, 1.0, 0.10 + shimmer * 0.15))
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, FLOOR_Y - 119.0), Vector2(x - 29.0, FLOOR_Y - 78.0),
			Vector2(x, FLOOR_Y - 36.0), Vector2(x + 29.0, FLOOR_Y - 78.0)]), Color("a4f7ff"))
		draw_string(f, Vector2(x - 62.0, FLOOR_Y - 143.0), "HIDDEN GLYPH %d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("e4ffff"))
