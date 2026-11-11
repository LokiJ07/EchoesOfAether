extends Node2D
## V9 Echo Labyrinth: a real in-world ten-second shadow recording challenge.
## All positions are inside the existing independent Echo Labyrinth portal scene.
## The gate is physics-blocking; playback, not a menu answer, opens the route.

const MECHANICS = preload("res://scripts/AetherMechanics.gd")
const START_X := 55900.0
const RECORDER_X := START_X + 740.0
const PLATE_X := START_X + 1080.0
const GATE_X := START_X + 1580.0
const RELIC_X := START_X + 2010.0
const FLOOR_Y := 500.0
const RECORD_SECONDS := 10.0

var game
var completed := false
var recording: Dictionary = {}
var ghost: Dictionary = {}
var gate_latch := 0.0
var blocked_message_cooldown := 0.0
var replay_announced := false

func _ready() -> void:
	game = get_parent()
	reset_runtime()

func reset_runtime() -> void:
	recording = MECHANICS.start_recording()
	recording["recording"] = false
	recording["playing"] = false
	ghost.clear()
	gate_latch = 0.0
	blocked_message_cooldown = 0.0
	replay_announced = false
	queue_redraw()

func in_labyrinth() -> bool:
	return game != null and game.current_realm_id == "echo_labyrinth"

func is_active() -> bool:
	return in_labyrinth() and game.state == "playing" and not completed

func near_recorder() -> bool:
	return is_active() and absf(game.player_pos.x - RECORDER_X) <= 82.0 and absf(game.player_pos.y - FLOOR_Y) < 125.0

func try_start_recording() -> bool:
	if not near_recorder():
		return false
	recording = MECHANICS.start_recording()
	ghost.clear()
	gate_latch = 0.0
	replay_announced = false
	game.show_message("ECHO RECORDING: Walk to the glowing plate and HOLD for 10 seconds!", 4.2)
	game.play_sfx("skill")
	queue_redraw()
	return true

func plate_pressed_by_player() -> bool:
	return absf(game.player_pos.x - PLATE_X) <= 78.0 and game.on_ground and absf(game.player_pos.y - FLOOR_Y) <= 29.0

func plate_pressed_by_ghost() -> bool:
	return not ghost.is_empty() and bool(ghost.get("switch", false)) and absf(float(ghost.get("x", -10000.0)) - PLATE_X) <= 78.0

func gate_open() -> bool:
	return completed or gate_latch > 0.0

func update_chamber(dt: float) -> void:
	if not is_active():
		return
	blocked_message_cooldown = maxf(0.0, blocked_message_cooldown - dt)
	gate_latch = maxf(0.0, gate_latch - dt)
	if bool(recording.get("recording", false)):
		MECHANICS.record_frame(recording, dt, game.player_pos, plate_pressed_by_player())
		if bool(recording.get("playing", false)) and not replay_announced:
			replay_announced = true
			game.show_message("GHOST RELEASED! Run to the gate while your echo stands on the plate.", 4.2)
			game.play_sfx("skill")
	elif bool(recording.get("playing", false)):
		ghost = MECHANICS.clone_frame(recording, dt)
		if plate_pressed_by_ghost():
			# A generous release window stops one missed frame punishing touchscreen players.
			gate_latch = 3.0
	if not completed and absf(game.player_pos.x - RELIC_X) < 70.0 and absf(game.player_pos.y - FLOOR_Y) < 125.0:
		claim_relic()
	queue_redraw()

func block_player(old_x: float) -> void:
	if not is_active() or gate_open():
		return
	# One-way chamber challenge: can always retreat towards the exit/recorder.
	# The barrier blocks jumps and dashes, not just characters walking on the floor.
	if old_x <= GATE_X - 25.9 and game.player_pos.x > GATE_X - 26.0:
		game.player_pos.x = GATE_X - 26.0
		game.velocity.x = minf(game.velocity.x, 0.0)
		if blocked_message_cooldown <= 0.0:
			blocked_message_cooldown = 2.4
			game.show_message("ECHO GATE SEALED. RECORD YOURSELF HOLDING THE PLATE.", 2.4)

func claim_relic() -> void:
	if completed or not in_labyrinth():
		return
	completed = true
	gate_latch = 99.0
	game.coins += 230
	game.relic_shards += 2
	game.gain_exp(160)
	game.record_quest_event("trial:echo_labyrinth")
	game.spawn_dust(Vector2(RELIC_X, FLOOR_Y - 80.0), Color("9ee9fa"), 26)
	game.show_message("ECHO LABYRINTH RESTORED! +230 COINS, +2 RELIC SHARDS", 4.5)
	game.play_sfx("win")
	game.save_game()
	queue_redraw()

func status_text() -> String:
	if completed:
		return "ECHO GATE RESTORED  |  SHADOW TRIAL COMPLETE"
	if not in_labyrinth():
		return ""
	if bool(recording.get("recording", false)):
		return "RECORDING  %.1f / 10s  |  HOLD THE GLOWING PLATE" % float(recording.get("elapsed", 0.0))
	if bool(recording.get("playing", false)):
		return "GHOST REPLAY  |  %s" % ("GATE OPEN — REACH THE RELIC" if gate_open() else "WAIT FOR THE PLATE TO LIGHT")
	return "ECHO RECORDER  |  PRESS INTERACT, THEN STAND ON THE PLATE"

func _process(_dt: float) -> void:
	if in_labyrinth():
		queue_redraw()

func _draw() -> void:
	if not in_labyrinth():
		return
	var t: float = game.elapsed if not game.reduced_motion else 0.0
	var font: Font = ThemeDB.fallback_font
	# Portal chamber ornaments: glowing channels, layered arches and rune windows.
	for i in range(9):
		var x: float = RECORDER_X - 320.0 + float(i) * 285.0
		var shade: Color = Color("1b263f") if i % 2 == 0 else Color("222d49")
		draw_rect(Rect2(x - 21.0, 171.0 + float(i % 3) * 12.0, 42.0, 326.0), shade)
		draw_rect(Rect2(x - 38.0, 170.0 + float(i % 3) * 12.0, 76.0, 15.0), Color("50628a"))
		draw_arc(Vector2(x, 220.0), 44.0, PI, TAU, 24, Color(0.38, 0.79, 0.92, 0.38), 3.0)
		draw_circle(Vector2(x, 218.0), 8.0, Color("8de7eb"))
		draw_line(Vector2(x, 175.0), Vector2(x, 240.0), Color(0.45, 0.86, 0.94, 0.24), 2.0)
		for rune in range(3):
			var center := Vector2(x + float(rune - 1) * 13.0, 312.0 + float((i + rune) % 2) * 12.0)
			draw_arc(center, 5.0, 0.0, TAU, 10, Color(0.65, 0.89, 0.94, 0.24), 1.0)
	draw_line(Vector2(RECORDER_X - 200.0, FLOOR_Y - 12.0), Vector2(RELIC_X + 180.0, FLOOR_Y - 12.0), Color(0.28, 0.89, 0.93, 0.40), 4.0)
	# Recorder: tactile, animated obelisk, well away from the legacy story NPC.
	var orb_y: float = FLOOR_Y - 120.0 - 4.0 * sin(t * 2.1)
	draw_circle(Vector2(RECORDER_X, orb_y), 53.0, Color(0.25, 0.84, 0.99, 0.16))
	draw_rect(Rect2(RECORDER_X - 32.0, FLOOR_Y - 85.0, 64.0, 85.0), Color("273754"))
	draw_rect(Rect2(RECORDER_X - 38.0, FLOOR_Y - 85.0, 76.0, 10.0), Color("7199ad"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(RECORDER_X, orb_y - 29.0), Vector2(RECORDER_X + 24.0, orb_y),
		Vector2(RECORDER_X, orb_y + 30.0), Vector2(RECORDER_X - 24.0, orb_y)]), Color("a1f5f5"))
	draw_line(Vector2(RECORDER_X - 2.0, orb_y - 18.0), Vector2(RECORDER_X - 2.0, orb_y + 18.0), Color("ecffff"), 3.0)
	draw_string(font, Vector2(RECORDER_X - 84.0, FLOOR_Y - 177.0), "ECHO RECORDER", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("d9f7fc"))
	if not completed:
		draw_string(font, Vector2(RECORDER_X - 68.0, FLOOR_Y - 156.0), "INTERACT TO START", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("eedcb0"))
	# A genuine contact pad (not a click-sequence button).
	var live: bool = plate_pressed_by_player() or plate_pressed_by_ghost()
	draw_rect(Rect2(PLATE_X - 77.0, FLOOR_Y - 11.0, 154.0, 13.0), Color("9df7e7") if live else Color("57758d"))
	draw_rect(Rect2(PLATE_X - 57.0, FLOOR_Y - 20.0, 114.0, 10.0), Color("a2f9da") if live else Color("344d6c"))
	draw_circle(Vector2(PLATE_X, FLOOR_Y - 23.0), 17.0, Color(0.40, 0.92, 0.85, 0.26 if live else 0.10))
	draw_string(font, Vector2(PLATE_X - 77.0, FLOOR_Y - 45.0), "ECHO PRESSURE PLATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("d6f6df"))
	# Ghost visual: its REAL recorded positions, not a canned animation.
	if not ghost.is_empty() and not completed:
		var gx: float = float(ghost.get("x", RECORDER_X))
		var gy: float = float(ghost.get("y", FLOOR_Y))
		var ghost_tint := Color(0.54, 0.91, 1.0, 0.52 + 0.11 * sin(t * 4.0))
		draw_circle(Vector2(gx, gy - 61.0), 38.0, Color(0.42, 0.84, 0.99, 0.12))
		draw_colored_polygon(PackedVector2Array([
			Vector2(gx - 23.0, gy - 14.0), Vector2(gx - 16.0, gy - 73.0),
			Vector2(gx + 16.0, gy - 73.0), Vector2(gx + 23.0, gy - 14.0)]), ghost_tint)
		draw_circle(Vector2(gx, gy - 78.0), 17.0, ghost_tint)
		draw_circle(Vector2(gx - 5.0, gy - 79.0), 2.2, Color("ffffff"))
		draw_circle(Vector2(gx + 5.0, gy - 79.0), 2.2, Color("ffffff"))
	# Three huge mechanical locking rails; player physics is clamped at this x.
	if not gate_open():
		draw_rect(Rect2(GATE_X - 24.0, 154.0, 48.0, 346.0), Color("243046"))
		for rail in range(5):
			var y: float = 162.0 + float(rail) * 76.0
			draw_rect(Rect2(GATE_X - 28.0, y, 56.0, 14.0), Color("688ca5"))
			draw_circle(Vector2(GATE_X, y + 19.0), 9.0, Color("69aee8"))
		draw_circle(Vector2(GATE_X, 306.0), 59.0, Color(0.25, 0.52, 1.0, 0.20))
		draw_arc(Vector2(GATE_X, 306.0), 43.0, 0.0, TAU, 40, Color("8ddefe"), 4.0)
		draw_string(font, Vector2(GATE_X - 78.0, 132.0), "ECHO-LOCKED GATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e1e6ff"))
	else:
		draw_circle(Vector2(GATE_X, 309.0), 50.0, Color(0.39, 0.99, 0.77, 0.18))
		draw_arc(Vector2(GATE_X, 309.0), 45.0, 0.0, TAU, 40, Color("8af0dc"), 4.0)
		draw_string(font, Vector2(GATE_X - 50.0, 142.0), "GATE UNSEALED", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("a8ffe0"))
	# Sacred collectible is physical, saved once, and remains claimed on reload.
	draw_rect(Rect2(RELIC_X - 49.0, FLOOR_Y - 38.0, 98.0, 39.0), Color("293952"))
	draw_rect(Rect2(RELIC_X - 55.0, FLOOR_Y - 44.0, 110.0, 14.0), Color("618ba3"))
	if not completed:
		var radiance: float = 0.5 + 0.5 * sin(t * 2.5)
		draw_circle(Vector2(RELIC_X, FLOOR_Y - 111.0), 51.0, Color(0.40, 0.87, 1.0, 0.16 + radiance * 0.08))
		draw_colored_polygon(PackedVector2Array([
			Vector2(RELIC_X, FLOOR_Y - 164.0), Vector2(RELIC_X + 30.0, FLOOR_Y - 112.0),
			Vector2(RELIC_X, FLOOR_Y - 66.0), Vector2(RELIC_X - 30.0, FLOOR_Y - 112.0)]), Color("a8f8ff"))
		draw_string(font, Vector2(RELIC_X - 76.0, FLOOR_Y - 190.0), "FRACTURED ECHO RELIC", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ebf5ff"))
	else:
		draw_circle(Vector2(RELIC_X, FLOOR_Y - 110.0), 18.0, Color("6ce4b1"))
		draw_string(font, Vector2(RELIC_X - 65.0, FLOOR_Y - 161.0), "RELIC RESTORED", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("bafadd"))
