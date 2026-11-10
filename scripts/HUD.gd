extends Control
## Accessible, landscape-first touchscreen HUD. No giant panels over active play.

@onready var game = get_node("../..")
var font: Font
var menu_buttons: Array = []
var top_buttons: Array = []
var main_accent := Color("75e7d4")
var settings_return := "pause"
# v0.6: coordinates are normalized, so layouts work across 16:9 and ultrawide phones.
const CONTROL_KEYS = ["joystick", "attack", "jump", "dash", "skill", "potion", "interact", "guard"]
const CONTROLS_FILE = "user://aether_controls.json"
var custom_positions: Dictionary = {}
var control_scale := 1.0
var control_opacity := 0.88
var editor_key := ""
var editor_touch := -1

func _ready() -> void:
	font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	load_control_layout()

# Adapt coordinates to the real phone aspect ratio; the Godot "expand" viewport
# makes screen size variable (16:9, 19.5:9, 20:9, tablets, cutout-safe margins).
func safe_layout_rect(view: Vector2) -> Rect2:
	var margin_x: float = clampf(view.x * 0.034, 18.0, 64.0)
	var margin_y: float = clampf(view.y * 0.026, 10.0, 24.0)
	return Rect2(Vector2(margin_x, margin_y),
		Vector2(maxf(1.0, view.x - margin_x * 2.0), maxf(1.0, view.y - margin_y * 2.0)))

func screen_scale_for(view: Vector2) -> float:
	return clampf(minf(view.x / 1152.0, view.y / 648.0), 0.72, 1.18)

func active_control_scale() -> float:
	return control_scale * screen_scale_for(size)

func default_control_centers_for(view: Vector2) -> Dictionary:
	var bounds: Rect2 = safe_layout_rect(view)
	var right: float = bounds.end.x
	var bottom: float = bounds.end.y
	var factor: float = screen_scale_for(view)
	return {"joystick": Vector2(bounds.position.x + 121.0 * factor, bottom - 122.0 * factor),
		"attack": Vector2(right - 126.0 * factor, bottom - 122.0 * factor),
		"jump": Vector2(right - 278.0 * factor, bottom - 80.0 * factor),
		"dash": Vector2(right - 315.0 * factor, bottom - 205.0 * factor),
		"skill": Vector2(right - 187.0 * factor, bottom - 281.0 * factor),
		"potion": Vector2(right - 433.0 * factor, bottom - 77.0 * factor),
		"interact": Vector2(right - 437.0 * factor, bottom - 187.0 * factor),
		"guard": Vector2(right - 360.0 * factor, bottom - 310.0 * factor)}

func default_control_centers() -> Dictionary:
	return default_control_centers_for(size)

func clamp_control_point(at: Vector2, view: Vector2) -> Vector2:
	var bounds: Rect2 = safe_layout_rect(view)
	var margin: float = 56.0 * control_scale * screen_scale_for(view)
	var min_x: float = bounds.position.x + margin
	var max_x: float = maxf(min_x, bounds.end.x - margin)
	var min_y: float = maxf(165.0 * screen_scale_for(view), bounds.position.y + 105.0 * screen_scale_for(view))
	var max_y: float = maxf(min_y, bounds.end.y - margin)
	return Vector2(clampf(at.x, min_x, max_x), clampf(at.y, min_y, max_y))

func control_position(key: String) -> Vector2:
	var defaults: Dictionary = default_control_centers()
	if not defaults.has(key):
		return Vector2.ZERO
	if custom_positions.has(key):
		var coords: Array = custom_positions[key]
		return clamp_control_point(Vector2(float(coords[0]) * size.x,
			float(coords[1]) * size.y), size)
	return defaults[key]

func joystick_center() -> Vector2:
	return control_position("joystick")

func control_centers() -> Dictionary:
	var result: Dictionary = default_control_centers()
	for key in result:
		if custom_positions.has(key):
			result[key] = control_position(str(key))
	return result

func set_control_position(key: String, at: Vector2) -> void:
	if not CONTROL_KEYS.has(key) or size.x <= 0.0 or size.y <= 0.0:
		return
	var target: Vector2 = clamp_control_point(at, size)
	custom_positions[key] = [target.x / size.x, target.y / size.y]
	queue_redraw()

func save_control_layout() -> void:
	var file := FileAccess.open(CONTROLS_FILE, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"positions": custom_positions, "scale": control_scale,
			"opacity": control_opacity, "version": 1}))
		file.close()

func load_control_layout() -> void:
	if not FileAccess.file_exists(CONTROLS_FILE):
		return
	var file := FileAccess.open(CONTROLS_FILE, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if not data is Dictionary:
		return
	control_scale = clampf(float(data.get("scale", 1.0)), 0.75, 1.35)
	control_opacity = clampf(float(data.get("opacity", 0.88)), 0.35, 1.0)
	var incoming = data.get("positions", {})
	if not incoming is Dictionary:
		return
	custom_positions.clear()
	for key in CONTROL_KEYS:
		var coords = incoming.get(key, [])
		if coords is Array and coords.size() == 2:
			custom_positions[key] = [clampf(float(coords[0]), 0.03, 0.97),
				clampf(float(coords[1]), 0.23, 0.95)]

func reset_control_layout() -> void:
	custom_positions.clear()
	control_scale = 1.0
	control_opacity = 0.88
	save_control_layout()
	queue_redraw()

func editor_touch_press(at: Vector2, touch_id: int) -> bool:
	if game.state != "hud_edit":
		return false
	if handle_menu_press(at):
		return true
	var closest := 115.0 * active_control_scale()
	var selected := ""
	for key in CONTROL_KEYS:
		var distance: float = control_position(key).distance_to(at)
		if distance < closest:
			closest = distance
			selected = key
	if selected != "":
		editor_key = selected
		editor_touch = touch_id
		queue_redraw()
	return true

func editor_touch_drag(at: Vector2, touch_id: int) -> void:
	if game.state != "hud_edit" or touch_id != editor_touch or editor_key == "":
		return
	set_control_position(editor_key, at)

func editor_touch_release(touch_id: int) -> void:
	if touch_id != editor_touch:
		return
	editor_touch = -1
	editor_key = ""
	save_control_layout()

func change_control_scale(amount: float) -> void:
	control_scale = clampf(snappedf(control_scale + amount, 0.05), 0.75, 1.35)
	save_control_layout()

func change_control_opacity(amount: float) -> void:
	control_opacity = clampf(snappedf(control_opacity + amount, 0.1), 0.35, 1.0)
	save_control_layout()

func faded(color: Color) -> Color:
	color.a *= control_opacity
	return color

func handle_top_press(pos: Vector2) -> bool:
	for entry in top_buttons:
		if entry["rect"].has_point(pos):
			match entry["key"]:
				"bag": game.state = "inventory"
				"quest": game.state = "quests"
				"map": game.state = "worldmap"
				"pause":
					game.state = "pause"
					game.save_game()
			return true
	return false

func handle_menu_press(pos: Vector2) -> bool:
	if game.dialogue != "":
		game.dialogue = ""
		return true
	for entry in menu_buttons:
		if not entry["rect"].has_point(pos): continue
		match entry["key"]:
			"new": game.start_new_game()
			"continue": game.continue_game()
			"resume": game.state = "playing"
			"inventory": game.state = "inventory"
			"quests": game.state = "quests"
			"settings":
				settings_return = game.state
				game.state = "settings"
			"main":
				game.save_game()
				game.state = "main"
			"respawn": game.respawn()
			"village":
				game.state = "playing"
				game.player_pos = Vector2(480, 500.0)
				game.checkpoint_x = 480.0
				game.save_game()
			"buy0": game.buy_shop_item(0)
			"buy1": game.buy_shop_item(1)
			"buy2": game.buy_shop_item(2)
			"portal0": game.portal_jump(0)
			"portal1": game.portal_jump(1)
			"portal2": game.portal_jump(2)
			"portal3": game.portal_jump(3)
			"portal4": game.portal_jump(4)
			"ember0": game.select_ember_rune(0)
			"ember1": game.select_ember_rune(1)
			"ember2": game.select_ember_rune(2)
			"ember_hint":
				if game.ember_puzzle_index >= 0:
					var order: Array = game.EMBER_RUNE_PATTERNS[game.ember_puzzle_index]
					game.ember_puzzle_feedback = "NEXT RUNE: " + str(game.EMBER_RUNE_NAMES[int(order[game.ember_puzzle_progress])])
			"ember_leave": game.leave_ember_puzzle()
			"emberling": game.toggle_emberling()
			"ember_explore": game.state = "playing"
			"explore_world": game.go_expansion_world()
			"explore_again": game.state = "playing"
			"train0": game.unlock_rune(0)
			"train1": game.unlock_rune(1)
			"train2": game.unlock_rune(2)
			"leave_trainer": game.state = "playing"
			"sound": game.sound_on = not game.sound_on
			"music":
				game.music_on = not game.music_on
				game.music.stream_paused = not game.music_on
			"back_settings":
				game.state = settings_return
			"customize":
				game.state = "hud_edit"
				game.touch_axis = 0.0
				game.joystick_touch = -1
				game.attack_touch.clear()
				game.hold_attack = false
			"hud_smaller": change_control_scale(-0.1)
			"hud_larger": change_control_scale(0.1)
			"hud_fade": change_control_opacity(-0.1)
			"hud_bright": change_control_opacity(0.1)
			"hud_reset": reset_control_layout()
			"graphics": game.cycle_graphics_quality()
			"reduce_motion": game.toggle_reduced_motion()
			"puzzle_sun": game.choose_echo_rune(0)
			"puzzle_moon": game.choose_echo_rune(1)
			"puzzle_star": game.choose_echo_rune(2)
			"puzzle_hint":
				if game.puzzle_index >= 0:
					var pattern: Array = game.ECHO_PATTERNS[game.puzzle_index]
					game.puzzle_feedback = "NEXT RUNE: " + str(game.RUNE_NAMES[int(pattern[game.puzzle_progress])])
			"puzzle_leave": game.leave_echo_puzzle()
			"hud_done":
				editor_key = ""
				editor_touch = -1
				save_control_layout()
				game.state = "settings"
			"heal": game.heal()
		game.queue_redraw()
		queue_redraw()
		return true
	return false

func box(rect: Rect2, fill: Color, border: Color = Color("6c918f"), thickness: float = 2.0) -> void:
	draw_rect(Rect2(rect.position + Vector2(4, 6), rect.size), Color(0, 0, 0, 0.22))
	draw_rect(rect, fill)
	draw_rect(rect, border, false, thickness)

func text(at: Vector2, value: String, pixel_size: int, tint: Color = Color("ecf8f2")) -> void:
	draw_string(font, at + Vector2(1, 2), value, HORIZONTAL_ALIGNMENT_LEFT, -1, pixel_size, Color("06131e"))
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, pixel_size, tint)

func centered(center_x: float, y: float, label: String, pixel_size: int, tint: Color = Color.WHITE) -> void:
	var width = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, pixel_size).x
	text(Vector2(center_x - width / 2.0, y), label, pixel_size, tint)

func bar(at: Vector2, width: float, percent: float, tint: Color, title: String) -> void:
	draw_rect(Rect2(at, Vector2(width, 13)), Color("0b1c29"))
	draw_rect(Rect2(at + Vector2(2, 2), Vector2(maxf(0.0, (width - 4) * clampf(percent, 0.0, 1.0)), 9)), tint)
	draw_rect(Rect2(at, Vector2(width, 13)), Color("80aaa8"), false, 1.0)
	text(at + Vector2(4, -5), title, 12, Color("f8f4dd"))

func small_button(rect: Rect2, label: String, code: String, accent: Color = Color("80dfcc")) -> void:
	box(rect, Color("132839"), accent, 1.3)
	centered(rect.position.x + rect.size.x / 2.0, rect.position.y + 23, label, 16, accent)
	menu_buttons.append({"rect": rect, "key": code})

func menu_button(rect: Rect2, label: String, code: String, accent: Color = Color("85dec9")) -> void:
	# Animated trims and bold touch targets, but no intrusive gameplay overlays.
	var pulse: float = 0.5 + 0.5 * sin(game.elapsed * 2.8 + float(label.length()))
	box(rect, Color("132c3d"), Color(accent.r, accent.g, accent.b, 0.67 + pulse * 0.23), 2.0)
	draw_rect(Rect2(rect.position + Vector2(8.0, 7.0), Vector2(4.0, rect.size.y - 14.0)), accent)
	draw_rect(Rect2(rect.position + Vector2(19.0, 8.0), Vector2(rect.size.x - 36.0, 1.0)), Color(accent.r, accent.g, accent.b, 0.24))
	centered(rect.position.x + rect.size.x / 2.0, rect.position.y + rect.size.y * 0.68, label, 19, Color("f5efcf"))
	menu_buttons.append({"rect": rect, "key": code})

func control_button(at: Vector2, radius: float, letter: String, label: String, tint: Color) -> void:
	radius *= active_control_scale()
	draw_circle(at + Vector2(3, 5), radius + 2, faded(Color(0, 0, 0, 0.31)))
	draw_circle(at, radius, faded(Color("183044") if game.dash_timer <= 0.0 else Color("295c66")))
	draw_arc(at, radius - 2, 0, TAU, 36, faded(tint), 3.0, true)
	centered(at.x, at.y + 8, letter, 27, Color("f2ffef"))
	centered(at.x, at.y + radius + 16, label, 12, tint)

func draw_dash_button(at: Vector2) -> void:
	var tint := Color("84d9f0")
	var radius: float = 42.0 * active_control_scale()
	draw_circle(at + Vector2(3, 5), radius + 2.0, faded(Color(0, 0, 0, 0.31)))
	draw_circle(at, radius, faded(Color("162c39")))
	draw_arc(at, radius - 2.0, 0.0, TAU, 36, faded(tint), 2.0, true)
	if game.dash_cooldown > 0.0:
		draw_arc(at, radius - 3, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - game.dash_cooldown / 0.7), 40, tint, 4.0, true)
		centered(at.x, at.y + 7.0, "%.1fs" % game.dash_cooldown, 18, tint)
	else:
		centered(at.x, at.y + 8.0, ">>", 25, tint)
	centered(at.x, at.y + radius + 16, "DASH", 12, tint)

func draw_guard_button(at: Vector2) -> void:
	var radius: float = 37.0 * active_control_scale()
	var tint := Color("c2d5fb")
	var active: bool = game.guard_window > 0.0
	draw_circle(at + Vector2(3, 5), radius + 2.0, faded(Color(0, 0, 0, 0.31)))
	draw_circle(at, radius, faded(Color("466980") if active else Color("162c39")))
	draw_arc(at, radius - 2.0, 0.0, TAU, 36, faded(tint), 2.0, true)
	if game.guard_cooldown > 0.0 and not active:
		centered(at.x, at.y + 7.0, "%.1f" % game.guard_cooldown, 19, tint)
	else:
		centered(at.x, at.y + 8.0, "G", 24, tint)
	centered(at.x, at.y + radius + 16.0, "GUARD", 12, tint)

func skill_status_text() -> String:
	if game.skill_timer > 0.0:
		return "%.1fs" % game.skill_timer
	if game.stamina < 35.0:
		return "LOW SP"
	return "READY"

func draw_skill_button(at: Vector2) -> void:
	var radius: float = 45.0 * active_control_scale()
	var tint := Color("c6a2f5")
	var recharging: bool = game.skill_timer > 0.0
	var low_stamina: bool = game.stamina < 35.0
	draw_circle(at + Vector2(3, 5), radius + 2.0, faded(Color(0, 0, 0, 0.31)))
	draw_circle(at, radius, faded(Color("152333") if recharging or low_stamina else Color("284258")))
	draw_arc(at, radius - 2.0, 0.0, TAU, 48, faded(Color("677586") if recharging else tint), 2.0, true)
	if recharging:
		var ready_fraction: float = 1.0 - game.skill_cooldown_fraction()
		draw_arc(at, radius - 3.0, -PI * 0.5, -PI * 0.5 + TAU * ready_fraction, 48, tint, 4.0, true)
		centered(at.x, at.y + 7.0, skill_status_text(), 21, Color("f4eaff"))
	elif low_stamina:
		centered(at.x, at.y + 6.0, skill_status_text(), 16, Color("f9c4b1"))
	else:
		centered(at.x, at.y + 8.0, "*", 27, Color("f4eaff"))
	centered(at.x, at.y + radius + 16.0, "AETHER", 12, tint)

func _draw() -> void:
	menu_buttons.clear()
	top_buttons.clear()
	var w = size.x
	var h = size.y
	if game.state == "main":
		draw_main_menu(w, h)
		return
	if game.state == "puzzle":
		draw_echo_puzzle(w, h)
		return
	if game.state == "ember_puzzle":
		draw_ember_puzzle(w, h)
		return
	if game.state in ["playing", "hud_edit", "inventory", "quests", "shop", "trainer", "portals", "worldmap", "pause", "settings", "victory", "realm_victory", "ember_victory", "defeat"]:
		draw_game_status(w, h)
	if game.state == "hud_edit":
		draw_mobile_controls(w, h)
		draw_hud_editor(w, h)
		return
	if game.state == "playing":
		draw_boss_health(w)
		if game.combo_stage > 0 and game.combo_timer > 0.0:
			centered(w - 250.0, h - 356.0, "SWORD COMBO  %d / 3" % game.combo_stage, 18, Color("ffe6ab"))
		if game.dialogue != "":
			draw_dialogue(w, h)
		else:
			draw_mobile_controls(w, h)
		if game.message_time > 0:
			var rect = Rect2(w * 0.24, 102, w * 0.52, 42)
			box(rect, Color("153245"), Color("56c6bf"), 1.5)
			centered(w * 0.50, 128, game.message, 15, Color("f7edbd"))
		if game.boss_alert != "" and game.player_pos.x > 7350:
			centered(w / 2.0, 178, game.boss_alert, 22, Color("e88ceb"))
		return
	match game.state:
		"inventory": draw_inventory(w, h)
		"quests": draw_quests(w, h)
		"shop": draw_shop(w, h)
		"portals": draw_portal_network(w, h)
		"worldmap": draw_world_map(w, h)
		"realm_victory": draw_realm_victory(w, h)
		"ember_victory": draw_ember_victory(w, h)
		"trainer": draw_trainer(w, h)
		"pause": draw_pause(w, h)
		"settings": draw_settings(w, h)
		"defeat": draw_defeat(w, h)
		"victory": draw_victory(w, h)
	if game.message_time > 0:
		centered(w / 2.0, h - 24, game.message, 16, Color("ffd59a"))

func draw_boss_health(w: float) -> void:
	var boss: Dictionary = game.active_boss_info()
	if boss.is_empty():
		return
	var fraction: float = clampf(float(boss["hp"]) / float(boss["max_hp"]), 0.0, 1.0)
	var x: float = w * 0.5 - 190.0
	draw_rect(Rect2(x, 76, 380, 37), Color(0.06, 0.07, 0.15, 0.88))
	draw_rect(Rect2(x + 7, 102, 366.0 * fraction, 7), Color("df6a97") if fraction < 0.48 else Color("8ed7ce"))
	centered(w * 0.5, 95, game.boss_display_name(boss["type"]), 15, Color("f5e6cc"))

func draw_game_status(w: float, h: float) -> void:
	# Compact status strip: never blocks the central gameplay corridor.
	var safe_origin: Vector2 = safe_layout_rect(Vector2(w, h)).position - Vector2(13.0, 12.0)
	box(Rect2(Vector2(13, 12) + safe_origin, Vector2(263, 85)), Color("112636"), Color("3d7278"), 1.0)
	text(Vector2(23, 35) + safe_origin, "LV %d   %d COINS" % [game.level, game.coins], 17, Color("e9d69a"))
	bar(Vector2(24, 55) + safe_origin, 151, game.hp / game.max_hp, Color("e86d81"), "HP")
	bar(Vector2(24, 80) + safe_origin, 151, game.stamina / game.max_stamina, Color("57d5c8"), "STAMINA")
	var needed = maxi(1, game.level * 55)
	bar(Vector2(185, 55) + safe_origin, 73, float(game.exp_points) / float(needed), Color("c9a0ee"), "EXP")
	text(Vector2(187, 89) + safe_origin, "%d/%d" % [game.exp_points, needed], 13, Color("d3c3e7"))
	var bounds: Rect2 = safe_layout_rect(Vector2(w, h))
	# Compact portrait-ish landscape/tablets need the area title below the top buttons.
	var compact: bool = w < 1080.0
	var title_y: float = 96.0 if compact else 30.0
	var quest_y: float = 122.0 if compact else 55.0
	centered(bounds.get_center().x, title_y, game.area_name(), 17, Color("cfdecb"))
	if game.quest_stage < 3:
		var quest_label = ("TALK TO MIRA  (%d/3 SEEDS)" % game.seeds) if game.quest_stage == 0 else ("AETHER SEEDS %d/3" % game.seeds if game.quest_stage == 1 else "DEFEAT THE WARDEN")
		centered(bounds.get_center().x, quest_y, quest_label, 14, Color("e4c891"))
	else:
		centered(bounds.get_center().x, quest_y, game.v2_quest_label(), 14, Color("a7f2bc"))
	for i in range(4):
		var label = ["BAG", "QUEST", "MAP", "PAUSE"][i]
		var key = ["bag", "quest", "map", "pause"][i]
		var r = Rect2(bounds.end.x - 396.0 + float(i) * 96.0, bounds.position.y + 6.0, 90.0, 49.0)
		box(r, Color("162d40"), Color("6a9f9c"), 1.0)
		centered(r.position.x + r.size.x / 2.0, r.position.y + 28, label, 15)
		top_buttons.append({"rect": r, "key": key})

func draw_mobile_controls(w: float, h: float) -> void:
	var joy: Vector2 = joystick_center()
	var radius: float = 99.0 * active_control_scale()
	draw_circle(joy, radius, faded(Color(0.02, 0.12, 0.18, 0.42)))
	draw_arc(joy, radius - 3.0, 0, TAU, 52, faded(Color("a0dccd")), 3.0, true)
	draw_circle(joy + Vector2(game.touch_axis * 55.0 * active_control_scale(), 0), 46.0 * active_control_scale(), faded(Color("31616f")))
	centered(joy.x, joy.y - radius - 9.0, "MOVE", 16, Color("b3e8dc"))
	text(joy + Vector2(-66, 10), "<", 28, Color("e2f5f3"))
	text(joy + Vector2(51, 10), ">", 28, Color("e2f5f3"))
	var c = control_centers()
	control_button(c["attack"], 51, "S", "ATTACK", Color("f2ba7b"))
	control_button(c["jump"], 45, "^", "JUMP", Color("b4e4c2"))
	draw_dash_button(c["dash"])
	draw_skill_button(c["skill"])
	draw_guard_button(c["guard"])
	control_button(c["potion"], 37, "+", "POTION %d" % game.potions, Color("f5a2a2"))
	if game.nearby_npc() != "" or game.state == "hud_edit":
		var target: String = game.nearby_npc()
		var label: String = "SOLVE" if target in ["shrine", "ember_brazier"] else ("RESCUE" if target == "emberling" else ("TRAVEL" if target == "portal" else ("OPEN" if target == "cache" else ("TRAIN" if target == "scout" else ("SHOP" if target == "merchant" else "TALK")))))
		control_button(c["interact"], 40, "!", label, Color("f3db98"))

func modal(w: float, h: float, heading: String, width: float = 650.0, height: float = 470.0) -> Rect2:
	draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.05, 0.11, 0.75))
	var r = Rect2((w - width) * 0.5, (h - height) * 0.5, width, height)
	box(r, Color("152a39"), Color("79aaab"), 3.0)
	centered(w / 2.0, r.position.y + 51, heading, 31, Color("f4dea6"))
	draw_line(Vector2(r.position.x + 28, r.position.y + 67), Vector2(r.end.x - 28, r.position.y + 67), Color("6aa8a0"), 2)
	return r

func draw_main_menu(w: float, h: float) -> void:
	# v2 is a genuine visual redesign: cinematic Higgsfield world art + asymmetric layout.
	if game.ember_art.has("citadel"):
		draw_texture_rect(game.ember_art["citadel"], Rect2(0, 0, w, h), false, Color(0.79, 0.84, 0.94))
	elif game.realm_backdrops.has("sky"):
		draw_texture_rect(game.realm_backdrops["sky"], Rect2(0, 0, w, h), false, Color(0.78, 0.86, 1))
	draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.04, 0.10, 0.49))
	var left_width: float = w * 0.56
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(left_width, 0),
		Vector2(left_width - 84.0, h), Vector2(0, h)]), Color(0.016, 0.055, 0.12, 0.75))
	for i in range(24):
		var x: float = fposmod(float(i * 163) + 35.0, w)
		var y: float = fposmod(float(i * 107) + game.elapsed * (0.0 if game.reduced_motion else (16.0 + float(i % 3) * 8.0)), h)
		draw_circle(Vector2(x, h - y), 1.5 + float(i % 3), Color(1.0, 0.6, 0.32, 0.33))
	var title_x: float = w * 0.29
	centered(title_x, h * 0.24, "ECHOES OF AETHER", 37, Color("ffdfab"))
	centered(title_x, h * 0.315, "S H A T T E R E D   R E A L M S", 19, Color("b6f6e9"))
	draw_line(Vector2(w * 0.09, h * 0.35), Vector2(w * 0.48, h * 0.35), Color("eca96c"), 3.0)
	centered(title_x, h * 0.405, "CHAPTER II  •  EMBERFALL CITADEL", 17, Color("ffdcaf"))
	centered(title_x, h * 0.462, "NEW DUNGEON  •  5 PORTALS  •  20+ UNIQUE ENEMY SPRITES", 13, Color("d4e6e2"))
	centered(title_x, h * 0.518, "A world of embers awaits beyond Shadowfen.", 16, Color("d4e1e6"))
	var right_width: float = minf(w * 0.34, 405.0)
	var cx: float = w * 0.77
	var top: float = h * 0.26
	var box_h: float = minf(360.0, h * 0.6)
	box(Rect2(cx - right_width * 0.5 - 17.0, top - 45.0, right_width + 34.0, box_h + 48.0),
		Color(0.035, 0.09, 0.16, 0.88), Color("deb177"), 2.5)
	centered(cx, top - 12.0, "ADVENTURE SELECT", 17, Color("ffe1ad"))
	var btn_h: float = minf(66.0, h * 0.108)
	var gap: float = minf(22.0, h * 0.038)
	menu_button(Rect2(cx - right_width * 0.5, top + 20.0, right_width, btn_h), "CONTINUE JOURNEY", "continue", Color("78e1cf"))
	menu_button(Rect2(cx - right_width * 0.5, top + 20.0 + btn_h + gap, right_width, btn_h), "NEW ADVENTURE", "new", Color("efb879"))
	menu_button(Rect2(cx - right_width * 0.5, top + 20.0 + (btn_h + gap) * 2.0, right_width, btn_h), "SETTINGS & HUD", "settings", Color("b5b9ef"))
	centered(cx, top + box_h - 30.0, "OFFLINE   •   NO ADS   •   v2.0", 14, Color("9ee5d1"))
	centered(w * 0.5, h - 19.0, "ORIGINAL PIXEL ART RPG   |   HIGGSFIELD WORLD ART   |   GODOT 4", 13, Color("d0e0da"))

func draw_dialogue(w: float, h: float) -> void:
	var r = Rect2(w * 0.14, h * 0.68, w * 0.72, maxf(155.0, h * 0.25))
	box(r, Color("102b3b"), Color("e0ba79"), 2.7)
	draw_rect(Rect2(r.position + Vector2(12, 10), Vector2(r.size.x - 24, 3)), Color("78d1c5"))
	draw_circle(r.position + Vector2(28, 38), 12.0, Color("dcb976"))
	var dialogue: String = game.dialogue
	# Wrap dialogue text to remain readable on narrow phones.
	var words = dialogue.split(" ")
	var current = ""
	var lines: Array = []
	for word in words:
		var test = current + (" " if current != "" else "") + word
		if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x > r.size.x - 70 and current != "":
			lines.append(current)
			current = word
		else: current = test
	if current != "": lines.append(current)
	for i in range(mini(lines.size(), 4)):
		text(r.position + Vector2(26, 38 + i * 25), lines[i], 19, Color("fff4d2"))
	text(r.position + Vector2(r.size.x - 188, r.size.y - 15), "TAP TO CONTINUE", 14, Color("9fe1d2"))

func draw_inventory(w: float, h: float) -> void:
	var r = modal(w, h, "TRAVELER'S INVENTORY", 700, 520)
	var x = r.position.x + 54.0
	var y = r.position.y + 100.0
	var icons = ["POTIONS", "COINS", "AETHER SEEDS", "SWORD", "ARMOR", "RELIC SHARDS"]
	var amounts = [str(game.potions), str(game.coins), "%d / 3" % game.seeds,
		"LEVEL %d" % game.sword_level, "LEVEL %d" % game.armor_level, "%d  (2 PER RUNE)" % game.relic_shards]
	for i in range(6):
		var rr = Rect2(x + float(i % 2) * 302.0, y + float(floori(float(i) / 2.0)) * 99.0, 280.0, 79.0)
		box(rr, Color("233a49"), Color("5c8d94"))
		text(rr.position + Vector2(16, 28), icons[i], 16, Color("edd8ac"))
		text(rr.position + Vector2(16, 58), amounts[i], 22, Color("a6f3df"))
	text(Vector2(x, r.position.y + 383.0), "RELIC CACHES: %d/6  |  BRAZIERS: %d/3  |  COMPANION: %s" % [game.opened_caches.size(), game.ember_braziers.size(), "FOUND" if game.emberling_unlocked else "LOCKED"], 14, Color("f0ddb4"))
	if game.emberling_unlocked:
		menu_button(Rect2(w * 0.5 - 135.0, r.end.y - 117.0, 270.0, 35.0), "EMBERLING: %s" % ("REST" if game.emberling_active else "FOLLOW"), "emberling", Color("ffcf84"))
	menu_button(Rect2(w / 2.0 - 141, r.end.y - 61, 282, 44), "BACK TO ADVENTURE", "resume")

func draw_quests(w: float, h: float) -> void:
	var r = modal(w, h, "JOURNAL: THE FADING STAR & RELIC HUNTS", 840, 520)
	var x = r.position.x + 39.0
	var y = r.position.y + 99.0
	var entries = ["Speak to Mira in Moonhaven", "Gather 3 Aether Seeds", "Pass the Ancient Gate", "Defeat the Star Warden"]
	var done = [game.quest_stage >= 1, game.quest_stage >= 2, game.quest_stage >= 2, game.quest_stage >= 3]
	for i in range(entries.size()):
		text(Vector2(x, y + i * 31.0), ("[DONE] " if done[i] else "[    ] ") + entries[i], 17, Color("83e6bf") if done[i] else Color("f3e4c4"))
	text(Vector2(x, y + 154.0), "OPTIONAL HUNTS  -  automatic one-time rewards", 17, Color("ebd596"))
	var moth_done: bool = game.claimed_hunts.has("moth")
	var guard_done: bool = game.claimed_hunts.has("sentinel")
	text(Vector2(x, y + 190.0), ("[DONE] " if moth_done else "[    ] ") + "Dusk Moths: %d/3    Reward: 75 coins + 1 potion" % mini(3, game.hunted_moths), 16, Color("a2ead1") if moth_done else Color("e9e2cf"))
	text(Vector2(x, y + 221.0), ("[DONE] " if guard_done else "[    ] ") + "Stone Sentinels: %d/2    Reward: 100 coins + 15 max HP" % mini(2, game.hunted_sentinels), 16, Color("a2ead1") if guard_done else Color("e9e2cf"))
	text(Vector2(x, y + 269.0), "RELIC HUNT: %d / 6 caches opened  |  %d shards left" % [game.opened_caches.size(), game.relic_shards], 17, Color("f2dba4"))
	text(Vector2(x, y + 297.0), "OPTIONAL ECHO PUZZLES: %d / 6 AWAKENED" % game.awakened_shrines.size(), 15, Color("a9eadf"))
	text(Vector2(x, y + 326.0), "EMBERFALL BRAZIERS: %d / 3 RESTORED" % game.ember_braziers.size(), 15, Color("ffd49c"))
	text(Vector2(x, y + 357.0), game.v2_quest_label(), 15, Color("b4e5f4"))
	menu_button(Rect2(w / 2.0 - 139, r.end.y - 61, 278, 44), "BACK TO ADVENTURE", "resume")

func draw_shop(w: float, h: float) -> void:
	var r = modal(w, h, "LYRA'S STARLIT EMPORIUM", 743, 470)
	centered(w / 2.0, r.position.y + 98, "BALANCE: %d STARLIGHT COINS" % game.coins, 19, Color("efda9c"))
	var labels = ["HEALING POTION  +55 HP   •  20 COINS", "UPGRADE SWORD  •  %d COINS" % (85 * game.sword_level), "UPGRADE ARMOR  •  %d COINS" % (80 * game.armor_level)]
	for i in range(3):
		menu_button(Rect2(w / 2.0 - 300, r.position.y + 127 + float(i) * 74, 600, 58), labels[i], "buy%d" % i)
	menu_button(Rect2(w / 2.0 - 142, r.end.y - 65, 284, 45), "LEAVE SHOP", "resume")

func draw_trainer(w: float, h: float) -> void:
	var r = modal(w, h, "TARO'S AETHER RUNE TRAINING", 778, 520)
	centered(w / 2.0, r.position.y + 99.0, "AVAILABLE: %d RELIC SHARDS   |   EACH RUNE COSTS 2" % game.relic_shards, 18, Color("edd6a1"))
	var names = ["WINDSTEP  -  DOUBLE JUMP", "ASTRAL EDGE  -  POWERFUL BOLT", "VITAL SPARK  -  +35 STAMINA"]
	var descriptions = ["Jump a second time while airborne", "Aether Bolt deals +28 damage and flies faster", "Boosts stamina capacity and regeneration"]
	for i in range(3):
		var top: float = r.position.y + 125.0 + float(i) * 99.0
		var owned: bool = game.rune_upgrades[i]
		var label: String = ("UNLOCKED: " if owned else "LEARN (2): ") + names[i]
		menu_button(Rect2(w / 2.0 - 315.0, top, 630.0, 54.0), label, "train%d" % i, Color("75d9bd") if owned else Color("c6b3eb"))
		centered(w / 2.0, top + 76.0, descriptions[i], 14, Color("bad4c7"))
	menu_button(Rect2(w / 2.0 - 137.0, r.end.y - 56.0, 274.0, 41.0), "LEAVE TRAINING", "leave_trainer")

func draw_portal_network(w: float, h: float) -> void:
	var panel: Rect2 = modal(w, h, "AETHER PORTAL NETWORK", minf(880.0, w - 44.0), minf(535.0, h - 30.0))
	centered(w * 0.5, panel.position.y + 99.0, "Visit each realm to unlock fast travel. Your progress is preserved.", 15, Color("a7e8d8"))
	var cell_width: float = (panel.size.x - 110.0) * 0.5
	for i in range(game.PORTAL_NAMES.size()):
		var col: int = i % 2
		var row_id: int = int(i / 2)
		var x: float = panel.position.x + 38.0 + float(col) * (cell_width + 32.0)
		var y: float = panel.position.y + 121.0 + float(row_id) * 103.0
		if bool(game.portal_unlocked[i]):
			menu_button(Rect2(x, y, cell_width, 63.0), str(game.PORTAL_NAMES[i]), "portal%d" % i,
				Color("ffa977") if i == 4 else Color("88e6d3"))
		else:
			var r: Rect2 = Rect2(x, y, cell_width, 63.0)
			box(r, Color("1d2937"), Color("59636e"), 1.0)
			centered(x + cell_width * 0.5, y + 36, "LOCKED - %s" % game.PORTAL_NAMES[i], 16, Color("929da4"))
		text(Vector2(x + 12.0, y + 83.0), "FAST TRAVEL READY" if game.portal_unlocked[i] else "CLEAR PREVIOUS REALM", 13,
			Color("9bddc8") if game.portal_unlocked[i] else Color("8494a5"))
	menu_button(Rect2(w * 0.5 - 153.0, panel.end.y - 57.0, 306.0, 43.0), "RETURN TO ADVENTURE", "resume")

func draw_world_map(w: float, h: float) -> void:
	var panel: Rect2 = modal(w, h, "REALM ATLAS — SHATTERED AETHER", minf(915.0, w - 44.0), 495.0)
	centered(w * 0.5, panel.position.y + 99.0, "A CONNECTED ADVENTURE — WEST TO EAST", 17, Color("e9d29c"))
	var xs := [0.0, 1900.0, 4750.0, 8400.0, 10800.0, 12900.0, 15800.0, 19800.0]
	var names := ["MOONHAVEN", "WHISPERWOOD", "SUNKEN RUINS", "CRYSTAL", "SKY", "SHADOWFEN", "EMBERFALL", "CINDER VAULT"]
	var progress: float = clampf(game.player_pos.x / game.WORLD_WIDTH, 0.0, 1.0)
	var left: float = panel.position.x + 66.0
	var right: float = panel.end.x - 65.0
	var width: float = right - left
	var y: float = panel.position.y + 201.0
	draw_rect(Rect2(left, y, width, 12), Color("203b48"))
	draw_rect(Rect2(left, y, progress * width, 12), Color("78d8ca"))
	for i in range(xs.size()):
		var px: float = left + float(xs[i]) / game.WORLD_WIDTH * width
		draw_circle(Vector2(px, y + 6), 9.0, Color("f5a36a") if i >= 6 else Color("a4dcd4"))
		var label_y: float = y + (48.0 if i % 2 == 0 else -30.0)
		text(Vector2(px - 36.0, label_y), names[i], 12, Color("e4e5db"))
	centered(w * 0.5, panel.position.y + 334.0,
		"DISCOVERED PORTALS %d / %d   •   %s" % [game.unlocked_portal_count(), game.PORTAL_NAMES.size(), game.area_name()],
		15, Color("b0eee4"))
	centered(w * 0.5, panel.position.y + 373.0, game.v2_quest_label(), 15, Color("ffdda9"))
	menu_button(Rect2(w * 0.5 - 152.0, panel.end.y - 59.0, 304.0, 44.0), "BACK TO ADVENTURE", "resume")

func draw_realm_victory(w: float, h: float) -> void:
	var panel := modal(w, h, "THE REALMS AWAKEN", 705, 425)
	centered(w / 2.0, panel.position.y + 129.0, "You defeated the Shadowfen Guardian.", 21, Color("d8ffdf"))
	centered(w / 2.0, panel.position.y + 168.0, "All three new worlds are free to explore again.", 17, Color("a5d4eb"))
	menu_button(Rect2(w / 2.0 - 210, panel.position.y + 219, 420, 59), "CONTINUE EXPLORING", "explore_again")
	menu_button(Rect2(w / 2.0 - 210, panel.position.y + 298, 420, 54), "RETURN TO MOONHAVEN", "village")

func draw_pause(w: float, h: float) -> void:
	var r = modal(w, h, "JOURNEY PAUSED", 507, 477)
	menu_button(Rect2(w / 2.0 - 177, r.position.y + 96, 354, 57), "RESUME JOURNEY", "resume")
	menu_button(Rect2(w / 2.0 - 177, r.position.y + 167, 354, 57), "INVENTORY", "inventory")
	menu_button(Rect2(w / 2.0 - 177, r.position.y + 238, 354, 57), "SETTINGS", "settings")
	menu_button(Rect2(w / 2.0 - 177, r.position.y + 309, 354, 57), "SAVE & MAIN MENU", "main", Color("edb4a6"))

func draw_settings(w: float, h: float) -> void:
	var r: Rect2 = modal(w, h, "AETHER SETTINGS", minf(570.0, w - 42.0), minf(540.0, h - 24.0))
	var button_w: float = minf(430.0, r.size.x - 55.0)
	var item_h: float = minf(53.0, (r.size.y - 110.0) / 6.0)
	var top: float = r.position.y + 78.0
	var gap: float = 10.0
	menu_button(Rect2(w / 2.0 - button_w * 0.5, top, button_w, item_h), "MUSIC: %s" % ("ON" if game.music_on else "OFF"), "music")
	menu_button(Rect2(w / 2.0 - button_w * 0.5, top + (item_h + gap), button_w, item_h), "SOUND: %s" % ("ON" if game.sound_on else "OFF"), "sound")
	menu_button(Rect2(w / 2.0 - button_w * 0.5, top + (item_h + gap) * 2.0, button_w, item_h), "GRAPHICS: %s" % ["LOW", "BALANCED", "HIGH"][game.graphics_quality], "graphics", Color("97d9d5"))
	menu_button(Rect2(w / 2.0 - button_w * 0.5, top + (item_h + gap) * 3.0, button_w, item_h), "REDUCE MOTION: %s" % ("ON" if game.reduced_motion else "OFF"), "reduce_motion", Color("c8c0e4"))
	menu_button(Rect2(w / 2.0 - button_w * 0.5, top + (item_h + gap) * 4.0, button_w, item_h), "CUSTOMIZE HUD & CONTROLS", "customize", Color("a4d5ff"))
	menu_button(Rect2(w / 2.0 - button_w * 0.5, top + (item_h + gap) * 5.0, button_w, item_h), "BACK", "back_settings")

func draw_echo_puzzle(w: float, h: float) -> void:
	# Paused and optional by design: it cannot block normal exploration.
	var panel_w: float = minf(835.0, w - 52.0)
	var panel_h: float = minf(490.0, h - 34.0)
	var r: Rect2 = modal(w, h, "AETHER ECHO   •   RUNE SEQUENCE", panel_w, panel_h)
	if game.puzzle_index < 0:
		return
	var index: int = game.puzzle_index
	centered(w * 0.5, r.position.y + 100.0, "AN OPTIONAL CHALLENGE — LEAVE ANYTIME WITHOUT PENALTY", 15, Color("bde8d8"))
	var clue: String = str(game.ECHO_HINTS[index])
	centered(w * 0.5, r.position.y + 139.0, clue, 15, Color("f4dfa6"))
	centered(w * 0.5, r.position.y + 190.0, "RUNE SEQUENCE  %d / 3" % game.puzzle_progress, 20, Color("b8f2e6"))
	var symbols = ["SUN", "MOON", "STAR"]
	var icons = ["*", "C", "+"]
	var accents = [Color("f4c97b"), Color("b8c5fc"), Color("7fe8d6")]
	var card_w: float = minf(194.0, (panel_w - 85.0) / 3.0)
	var gap: float = minf(27.0, (panel_w - card_w * 3.0 - 50.0) * 0.5)
	var first_x: float = w * 0.5 - card_w * 1.5 - gap
	var card_y: float = r.position.y + 225.0
	for i in range(3):
		var x: float = first_x + float(i) * (card_w + gap)
		var pulse: float = 0.5 + 0.5 * sin(game.elapsed * 3.0 + float(i))
		draw_circle(Vector2(x + card_w * 0.5, card_y + 30.0), 26.0 + pulse * 2.0, Color(accents[i].r, accents[i].g, accents[i].b, 0.20))
		menu_button(Rect2(x, card_y, card_w, 66.0), "%s %s" % [icons[i], symbols[i]], "puzzle_%s" % symbols[i].to_lower(), accents[i])
	centered(w * 0.5, r.position.y + panel_h - 121.0, game.puzzle_feedback, 15, Color("9ce4db"))
	var half_w: float = minf(205.0, (panel_w - 60.0) * 0.45)
	menu_button(Rect2(w * 0.5 - half_w - 13.0, r.end.y - 80.0, half_w, 48.0), "SHOW NEXT HINT", "puzzle_hint", Color("bcb7ed"))
	menu_button(Rect2(w * 0.5 + 13.0, r.end.y - 80.0, half_w, 48.0), "LEAVE PUZZLE", "puzzle_leave", Color("ebb5a6"))

func draw_ember_puzzle(w: float, h: float) -> void:
	var width: float = minf(780.0, w - 48.0)
	var height: float = minf(464.0, h - 28.0)
	var panel: Rect2 = modal(w, h, "CINDER VAULT — OPTIONAL RUNE BRAZIER", width, height)
	if game.ember_puzzle_index < 0: return
	var index: int = game.ember_puzzle_index
	centered(w * 0.5, panel.position.y + 99.0, game.EMBER_RUNE_CLUES[index], 17, Color("ffdeac"))
	centered(w * 0.5, panel.position.y + 150.0, "BRAZIER RUNES: %d / 3 CORRECT" % game.ember_puzzle_progress, 18, Color("ffd295"))
	var names: Array = game.EMBER_RUNE_NAMES
	var width_each: float = (width - 112.0) / 3.0
	for i in range(3):
		var px: float = panel.position.x + 38.0 + float(i) * (width_each + 18.0)
		var y: float = panel.position.y + 189.0
		draw_circle(Vector2(px + width_each * 0.5, y - 12.0), 16.0, Color("f6a65e"))
		menu_button(Rect2(px, y, width_each, 68.0), names[i], "ember%d" % i, Color("ffa35f"))
	centered(w * 0.5, panel.end.y - 143.0, game.ember_puzzle_feedback, 14, Color("ffd8b4"))
	var footer_w: float = (width - 72.0) * 0.5
	menu_button(Rect2(panel.position.x + 28.0, panel.end.y - 84.0, footer_w - 10.0, 48.0), "SHOW NEXT RUNE", "ember_hint", Color("b1d7d9"))
	menu_button(Rect2(w * 0.5 + 11.0, panel.end.y - 84.0, footer_w - 10.0, 48.0), "LEAVE PUZZLE", "ember_leave", Color("f3a994"))

func draw_ember_victory(w: float, h: float) -> void:
	var panel: Rect2 = modal(w, h, "EMBERFALL RESTORED!", minf(655.0, w - 42.0), 350.0)
	centered(w * 0.5, panel.position.y + 119, "The Cinder Warden has fallen. The vault is safe!", 18, Color("f9e3ba"))
	centered(w * 0.5, panel.position.y + 155, "+350 COINS  •  +3 RELIC SHARDS  •  +25 MAX HP", 15, Color("9de7d9"))
	menu_button(Rect2(w * 0.5 - 211.0, panel.end.y - 91.0, 422.0, 55.0), "CONTINUE EXPLORING", "ember_explore", Color("93e4c7"))

func draw_hud_editor(w: float, h: float) -> void:
	# Editor displays actual mobile controls over the world; drag a control to relocate it.
	var bounds: Rect2 = safe_layout_rect(Vector2(w, h))
	var toolbar_width: float = minf(1050.0, bounds.size.x - 12.0)
	var toolbar: Rect2 = Rect2((w - toolbar_width) * 0.5, bounds.position.y + 91.0, toolbar_width, 118.0)
	box(toolbar, Color(0.04, 0.09, 0.17, 0.92), Color("8bb4ca"), 2.0)
	centered(w * 0.5, toolbar.position.y + 24.0, "DRAG ANY CONTROL TO MOVE IT", 18, Color("f0eacb"))
	var actions = [
		{"name": "SMALLER", "key": "hud_smaller"},
		{"name": "LARGER", "key": "hud_larger"},
		{"name": "FADE", "key": "hud_fade"},
		{"name": "BRIGHT", "key": "hud_bright"},
		{"name": "RESET", "key": "hud_reset"},
		{"name": "SAVE & EXIT", "key": "hud_done"}
	]
	for i in range(actions.size()):
		var slot: float = (toolbar_width - 24.0) / float(actions.size())
		var x: float = toolbar.position.x + 12.0 + float(i) * slot
		menu_button(Rect2(x, toolbar.position.y + 45.0, slot - 8.0, 54.0), actions[i]["name"], actions[i]["key"],
			Color("f0b7aa") if i == 4 else Color("91d8cd"))
	centered(w * 0.5, h - 20.0, "SIZE %d%%     OPACITY %d%%    |    Positions saved automatically" % [int(control_scale * 100.0), int(control_opacity * 100.0)], 15, Color("e8dfbc"))
	if editor_key != "":
		draw_arc(control_position(editor_key), 74.0 * active_control_scale(), 0, TAU, 52, Color("ffe4a0"), 4.0, true)

func draw_defeat(w: float, h: float) -> void:
	var r = modal(w, h, "YOUR LIGHT HAS FADED", 580, 360)
	centered(w / 2.0, r.position.y + 119, "The Aether can always be rekindled.", 19, Color("d7cbcd"))
	menu_button(Rect2(w / 2.0 - 186, r.position.y + 151, 372, 59), "REKINDLE AT CHECKPOINT", "respawn")
	menu_button(Rect2(w / 2.0 - 186, r.position.y + 232, 372, 55), "MAIN MENU", "main")

func draw_victory(w: float, h: float) -> void:
	var r = modal(w, h, "THE STAR SHINES AGAIN", 680, 393)
	centered(w / 2.0, r.position.y + 118, "You defeated the Warden and restored the valley!", 19, Color("e9e1c7"))
	centered(w / 2.0, r.position.y + 152, "The story ends, but Moonhaven lives on.", 18, Color("93e4c4"))
	menu_button(Rect2(w / 2.0 - 202, r.position.y + 185, 404, 55), "EXPLORE CRYSTAL HOLLOW", "explore_world")
	menu_button(Rect2(w / 2.0 - 202, r.position.y + 246, 404, 49), "RETURN TO MOONHAVEN", "village")
	menu_button(Rect2(w / 2.0 - 202, r.position.y + 305, 404, 43), "MAIN MENU", "main")
