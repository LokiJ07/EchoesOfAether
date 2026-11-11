extends Control
## Accessible, landscape-first touchscreen HUD. No giant panels over active play.

@onready var game = get_node("../..")
var font: Font
var menu_buttons: Array = []
var top_buttons: Array = []
var main_accent := Color("75e7d4")
var atlas_art: Texture2D
var atlas_selected := "hub"
var dialogue_portraits: Dictionary = {}
const ATLAS_POINTS := [
	{"id":"hub","at":Vector2(0.11,0.70),"title":"MOONHAVEN","number":1},
	{"id":"forest","at":Vector2(0.27,0.55),"title":"WHISPERWOOD","number":2},
	{"id":"rootcrypt","at":Vector2(0.25,0.74),"title":"ROOTBOUND CRYPT","number":2},
	{"id":"ruins","at":Vector2(0.43,0.67),"title":"SUNKEN RUINS","number":3},
	{"id":"echo_labyrinth","at":Vector2(0.47,0.79),"title":"ECHO LABYRINTH","number":3},
	{"id":"crystal","at":Vector2(0.47,0.44),"title":"CRYSTAL HOLLOW","number":4},
	{"id":"mirror_vault","at":Vector2(0.59,0.38),"title":"MIRROR VAULT","number":4},
	{"id":"sky","at":Vector2(0.59,0.19),"title":"HIGHLANDS","number":5},
	{"id":"gale_spire","at":Vector2(0.72,0.17),"title":"GALE SPIRE","number":5},
	{"id":"marsh","at":Vector2(0.63,0.63),"title":"SHADOWFEN","number":6},
	{"id":"mire_catacombs","at":Vector2(0.56,0.72),"title":"CATACOMBS","number":6},
	{"id":"ember","at":Vector2(0.73,0.74),"title":"EMBERFALL","number":7},
	{"id":"cinder","at":Vector2(0.78,0.80),"title":"CINDER VAULT","number":7},
	{"id":"abyss","at":Vector2(0.84,0.65),"title":"ABYSSAL DEPTHS","number":8},
	{"id":"tide_temple","at":Vector2(0.92,0.76),"title":"TIDE TEMPLE","number":8},
	{"id":"garden","at":Vector2(0.82,0.43),"title":"EVERDAWN","number":9},
	{"id":"verdant_vault","at":Vector2(0.91,0.48),"title":"VERDANT VAULT","number":9},
	{"id":"nexus","at":Vector2(0.91,0.19),"title":"AETHER NEXUS","number":10},
	{"id":"nexus_core","at":Vector2(0.97,0.30),"title":"CORE SANCTUM","number":10}
]
const ATLAS_ROUTES := [
	["hub","forest"],["forest","rootcrypt"],["forest","ruins"],
	["ruins","echo_labyrinth"],["ruins","crystal"],
	["crystal","mirror_vault"],["crystal","sky"],["sky","gale_spire"],
	["sky","marsh"],["marsh","mire_catacombs"],["marsh","ember"],
	["ember","cinder"],["ember","abyss"],["abyss","tide_temple"],
	["abyss","garden"],["garden","verdant_vault"],["garden","nexus"],
	["nexus","nexus_core"]
]
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
	if ResourceLoader.exists("res://assets/v10_world_atlas.svg"):
		atlas_art = load("res://assets/v10_world_atlas.svg") as Texture2D
	for portrait_id in ["sen", "mira", "vera", "scout", "narrator"]:
		var file: String = "res://assets/v10_portrait_%s.svg" % portrait_id
		if ResourceLoader.exists(file):
			var resource: Resource = load(file)
			if resource is Texture2D:
				dialogue_portraits[portrait_id] = resource

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
				"map":
					atlas_selected = game.current_realm_id if not atlas_item(game.current_realm_id).is_empty() else "hub"
					game.state = "worldmap"
				"pause":
					game.state = "pause"
					game.save_game()
			return true
	return false

func handle_menu_press(pos: Vector2) -> bool:
	if game.dialogue != "":
		if story_skip_rect(size.x, size.y).has_point(pos):
			game.story_queue.clear()
			game.dialogue = ""
		else:
			game.advance_story_dialogue()
		return true
	for entry in menu_buttons:
		if not entry["rect"].has_point(pos): continue
		var code: String = str(entry["key"])
		if code.begins_with("atlas_node:"):
			atlas_selected = code.trim_prefix("atlas_node:")
			queue_redraw()
			return true
		if code.begins_with("realm:"):
			game.enter_realm(code.trim_prefix("realm:"))
			return true
		if code.begins_with("v6_cell:"):
			game.press_trial_cell(int(code.trim_prefix("v6_cell:")))
			queue_redraw()
			return true
		if code.begins_with("pin:"):
			var id: String = code.trim_prefix("pin:")
			if game.tracked_quest_id == id:
				game.clear_quest_pin()
			else:
				game.pin_quest(id)
			queue_redraw()
			return true
		match entry["key"]:
			"atlas_travel":
				if game.is_realm_unlocked(atlas_selected):
					game.enter_realm(atlas_selected)
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
			"portal_next": game.portal_page += 1
			"portal_previous": game.portal_page = maxi(0, game.portal_page - 1)
			"journal_next": game.journal_page += 1
			"journal_previous": game.journal_page = maxi(0, game.journal_page - 1)
			"open_portal_network":
				game.portal_page = 0
				game.state = "portals"
			"dungeon_continue": game.state = "playing"
			"dungeon_return":
				var parent: String = str(game.current_realm().get("parent", "hub"))
				game.enter_realm(parent)
			"ending_continue": game.state = "playing"
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
			"v6_hint": game.trial_hint()
			"v6_restart": game.trial_restart()
			"v6_leave": game.leave_trial_puzzle()
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
	if game.state == "v6_puzzle":
		draw_v6_puzzle(w, h)
		return
	if game.state == "puzzle":
		draw_echo_puzzle(w, h)
		return
	if game.state == "ember_puzzle":
		draw_ember_puzzle(w, h)
		return
	if game.state in ["playing", "hud_edit", "inventory", "quests", "shop", "trainer", "portals", "worldmap", "pause", "settings", "victory", "realm_victory", "ember_victory", "dungeon_victory", "v5_victory", "defeat"]:
		draw_game_status(w, h)
	if game.state == "hud_edit":
		draw_mobile_controls(w, h)
		draw_hud_editor(w, h)
		return
	if game.state == "playing":
		if game.current_realm_id == "echo_labyrinth" and game.echo_chamber != null:
			var echo_panel: Rect2 = Rect2(w * 0.5 - 250.0, h - 58.0, 500.0, 38.0)
			box(echo_panel, Color(0.07, 0.13, 0.22, 0.75), Color("75cfe0"), 1.0)
			centered(w * 0.5, h - 33.0, game.echo_chamber.status_text(), 13, Color("d4f9ff"))
		elif game.current_realm_id in ["mirror_vault", "ruins"] and game.world_riddles != null:
			var world_panel: Rect2 = Rect2(w * 0.5 - 270.0, h - 58.0, 540.0, 38.0)
			box(world_panel, Color(0.07, 0.13, 0.22, 0.75), Color("75cfe0"), 1.0)
			centered(w * 0.5, h - 33.0, game.world_riddles.status_text(), 13, Color("d4f9ff"))
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
		"dungeon_victory": draw_dungeon_victory(w, h)
		"v5_victory": draw_v5_victory(w, h)
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
		var focused: Dictionary = game.pinned_quest()
		if not focused.is_empty():
			var focus_text: String = "%s  %d/%d" % [str(focused["title"]), game.quest_progress(focused), int(focused["target"])]
			centered(bounds.get_center().x, quest_y, focus_text, 14, Color("a7f2bc"))
		else:
			centered(bounds.get_center().x, quest_y, game.v5_story_label(), 14, Color("a7f2bc"))
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
		var label: String = {"echo_record": "RECORD", "phase_shift": "SHIFT", "sonar_pulse": "PULSE", "sonar_glyph": "DECODE"}.get(target, "SOLVE" if target in ["shrine", "ember_brazier", "trial_puzzle"] else ("RESCUE" if target == "emberling" else ("TRAVEL" if target == "portal" else ("OPEN" if target in ["cache", "secret"] else ("TRAIN" if target == "scout" else ("SHOP" if target == "merchant" else "TALK"))))))
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
	centered(title_x, h * 0.405, "CHAPTER V  •  REALMS OF THE AETHER CORE", 17, Color("ffdcaf"))
	centered(title_x, h * 0.462, "PORTAL WORLDS  •  DUNGEONS  •  30 QUESTS", 13, Color("d4e6e2"))
	centered(title_x, h * 0.518, "A new story unfolds across the shattered realms.", 16, Color("d4e1e6"))
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
	centered(cx, top + box_h - 30.0, "OFFLINE   •   CUSTOM HUD   •   v5.0", 14, Color("9ee5d1"))
	centered(w * 0.5, h - 19.0, "ORIGINAL PIXEL ART RPG   |   HIGGSFIELD WORLD ART   |   GODOT 4", 13, Color("d0e0da"))


func story_dialogue_rect(w: float, h: float) -> Rect2:
	# Movie-like story panel, short enough to preserve the scene and hero.
	var height: float = clampf(h * 0.31, 164.0, 224.0)
	return Rect2(w * 0.075, h - height - 14.0, w * 0.85, height)

func story_skip_rect(w: float, h: float) -> Rect2:
	var panel: Rect2 = story_dialogue_rect(w, h)
	return Rect2(panel.end.x - 148.0, panel.position.y + 12.0, 132.0, 34.0)

func story_next_rect(w: float, h: float) -> Rect2:
	var panel: Rect2 = story_dialogue_rect(w, h)
	return Rect2(panel.end.x - 149.0, panel.end.y - 57.0, 132.0, 44.0)

func story_speaker() -> String:
	var raw: String = str(game.dialogue)
	var marker: int = raw.find(":")
	return raw.substr(0, marker).strip_edges().to_upper() if marker > 0 and marker < 35 else "AETHER ARCHIVES"

func story_body() -> String:
	var raw: String = str(game.dialogue)
	var marker: int = raw.find(":")
	return raw.substr(marker + 1).strip_edges() if marker > 0 and marker < 35 else raw

func story_portrait_id() -> String:
	var speaker: String = story_speaker()
	if speaker.contains("SEN"): return "sen"
	if speaker.contains("MIRA"): return "mira"
	if speaker.contains("VERA"): return "vera"
	if speaker.contains("ELIAN") or speaker.contains("SCOUT") or speaker.contains("TARO"): return "scout"
	return "narrator"

func draw_dialogue(w: float, h: float) -> void:
	# Pop-up inspired by classic 2D storybook adventures, not plain floating text.
	var panel: Rect2 = story_dialogue_rect(w, h)
	# Lower-half dimming leaves the artwork and player's surroundings visible.
	draw_rect(Rect2(0.0, panel.position.y - 24.0, w, h - panel.position.y + 24.0),
		Color(0.025, 0.035, 0.08, 0.27))
	box(panel, Color("e8dcc0"), Color("af8652"), 4.0)
	draw_rect(Rect2(panel.position + Vector2(8.0, 8.0),
		panel.size - Vector2(16.0, 16.0)), Color("d5ba87"), false, 1.5)
	draw_rect(Rect2(panel.position + Vector2(16.0, 16.0),
		panel.size - Vector2(32.0, 32.0)), Color(0.97, 0.91, 0.77, 0.18))
	for corner in [panel.position + Vector2(17.0, 17.0),
		Vector2(panel.end.x - 17.0, panel.position.y + 17.0),
		Vector2(panel.position.x + 17.0, panel.end.y - 17.0),
		panel.end - Vector2(17.0, 17.0)]:
		draw_circle(corner, 5.0, Color("b08a59"))
	var portrait_side: float = minf(146.0, panel.size.y - 37.0)
	var portrait: Rect2 = Rect2(panel.position + Vector2(18.0, 18.0),
		Vector2(portrait_side, portrait_side))
	box(portrait, Color("214b58"), Color("cead6c"), 3.0)
	var portrait_id: String = story_portrait_id()
	if dialogue_portraits.has(portrait_id):
		draw_texture_rect(dialogue_portraits[portrait_id], portrait.grow(-5.0), false)
	else:
		draw_circle(portrait.get_center(), portrait_side * 0.30, Color("86c2c8"))
		draw_circle(portrait.get_center() + Vector2(0.0, -10.0), portrait_side * 0.18, Color("dbb18d"))
	var px: float = portrait.end.x + 18.0
	# Clear nameplate, with speaker-specific portrait even when characters share a scene.
	var speaker: String = story_speaker()
	var name_width: float = minf(panel.end.x - px - 141.0,
		maxf(185.0, font.get_string_size(speaker, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 47.0))
	draw_rect(Rect2(px, panel.position.y + 16.0, name_width, 35.0), Color("1c5864"))
	draw_rect(Rect2(px, panel.position.y + 16.0, name_width, 35.0), Color("d2a769"), false, 2.0)
	text(Vector2(px + 14.0, panel.position.y + 40.0), speaker, 18, Color("f7e3b1"))
	var body_text: String = story_body()
	var available_width: float = maxf(140.0, panel.end.x - px - 28.0)
	var font_size: int = 17 if w >= 980.0 else 15
	var lines: Array = []
	var current: String = ""
	for word in body_text.split(" "):
		var trial: String = current + (" " if not current.is_empty() else "") + word
		if not current.is_empty() and font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > available_width:
			lines.append(current)
			current = word
		else:
			current = trial
	if current != "": lines.append(current)
	for i in range(mini(lines.size(), 3)):
		text(Vector2(px + 1.0, panel.position.y + 80.0 + float(i) * 27.0),
			str(lines[i]), font_size, Color("273d45"))
	var next_button: Rect2 = story_next_rect(w, h)
	box(next_button, Color("1f6974"), Color("c5a56e"), 2.0)
	centered(next_button.get_center().x, next_button.position.y + 28.0,
		"NEXT  >" if not game.story_queue.is_empty() else "FINISH  >", 18, Color("f9e5b7"))
	var skip_button: Rect2 = story_skip_rect(w, h)
	box(skip_button, Color("62594e"), Color("d1b98e"), 1.5)
	centered(skip_button.get_center().x, skip_button.position.y + 23.0, "SKIP STORY", 13, Color("f8ead2"))
	text(Vector2(px + 4.0, panel.end.y - 20.0), "STORY  |  %d SCENE(S) LEFT  |  Tap NEXT" % game.story_queue.size(),
		12, Color("6a766f"))

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
	var panel: Rect2 = modal(w, h, "ADVENTURER'S JOURNAL  •  REALM QUESTS", minf(900.0, w - 48.0), minf(540.0, h - 28.0))
	var data: Array = game.REALM_CATALOG.QUESTS
	var per_page := 6
	var page_count: int = int(ceilf(float(data.size()) / float(per_page)))
	game.journal_page = clampi(game.journal_page, 0, maxi(0, page_count - 1))
	var from: int = game.journal_page * per_page
	centered(w * 0.5, panel.position.y + 79.0, "MAIN STORY   •   %d / %d QUESTS COMPLETE   •   PAGE %d / %d" % [game.quest_claimed.size(), data.size(), game.journal_page + 1, page_count], 15, Color("afe4d7"))
	for i in range(per_page):
		var index: int = from + i
		if index >= data.size(): break
		var q: Dictionary = data[index]
		var top: float = panel.position.y + 96.0 + float(i) * 58.0
		var finished: bool = game.quest_claimed.has(q["id"])
		var fill: Color = Color("1c413e") if finished else Color("1c3043")
		box(Rect2(panel.position.x + 29.0, top, panel.size.x - 58.0, 51.0), fill, Color("678d85"), 1.0)
		text(Vector2(panel.position.x + 43.0, top + 21.0), ("[DONE]  " if finished else "[  ]  ") + str(q["title"]), 16, Color("a4f0cd") if finished else Color("f0e6cd"))
		text(Vector2(panel.position.x + 43.0, top + 43.0), str(q["region"]).to_upper() + "  •  %d/%d  •  +%d COINS" % [game.quest_progress(q), int(q["target"]), int(q["coins"])], 13, Color("a9cbcf"))
		if not finished:
			var pinned: bool = game.tracked_quest_id == str(q["id"])
			var pin_rect := Rect2(panel.end.x - 156.0, top + 9.0, 116.0, 33.0)
			menu_button(pin_rect, "UNPIN" if pinned else "TRACK", "pin:" + str(q["id"]),
				Color("ffe099") if pinned else Color("80cbdc"))
	var footer_y: float = panel.end.y - 61.0
	menu_button(Rect2(panel.position.x + 30.0, footer_y, 164.0, 43.0), "PREVIOUS", "journal_previous", Color("b1c9dc"))
	menu_button(Rect2(panel.end.x - 194.0, footer_y, 164.0, 43.0), "NEXT PAGE", "journal_next", Color("b1c9dc"))
	menu_button(Rect2(w * 0.5 - 133.0, footer_y, 266.0, 43.0), "BACK TO ADVENTURE", "resume", Color("89e0c6"))

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
	var panel: Rect2 = modal(w, h, "AETHER PORTAL GATES  •  INDEPENDENT REALMS", minf(880.0, w - 44.0), minf(550.0, h - 24.0))
	var data: Array = game.REALM_CATALOG.REGIONS
	var per_page := 5
	var total_pages: int = int(ceilf(float(data.size()) / float(per_page)))
	game.portal_page = clampi(game.portal_page, 0, total_pages - 1)
	centered(w * 0.5, panel.position.y + 85.0, "ENTER A GATE TO LOAD A SEPARATE REALM SCENE   •   PAGE %d/%d" % [game.portal_page + 1, total_pages], 14, Color("addfdd"))
	for j in range(per_page):
		var index: int = game.portal_page * per_page + j
		if index >= data.size(): break
		var region: Dictionary = data[index]
		var y: float = panel.position.y + 101.0 + float(j) * 73.0
		var accessible: bool = game.is_realm_unlocked(str(region["id"]))
		var title: String = str(region["name"]) + ("  [DUNGEON]" if region["kind"] == "dungeon" else "")
		if accessible:
			menu_button(Rect2(panel.position.x + 38.0, y, panel.size.x - 76.0, 59.0), title, "realm:" + str(region["id"]),
				Color("f4b883") if region["kind"] == "dungeon" else Color("88e6d3"))
		else:
			var rr: Rect2 = Rect2(panel.position.x + 38.0, y, panel.size.x - 76.0, 59.0)
			box(rr, Color("212c36"), Color("6d7782"), 1.0)
			centered(w * 0.5, y + 34.0, "LOCKED  •  " + title, 16, Color("91a2ae"))
	var footer_y: float = panel.end.y - 57.0
	menu_button(Rect2(panel.position.x + 28.0, footer_y, 158.0, 43.0), "PREVIOUS", "portal_previous")
	menu_button(Rect2(panel.end.x - 186.0, footer_y, 158.0, 43.0), "NEXT", "portal_next")
	menu_button(Rect2(w * 0.5 - 145.0, footer_y, 290.0, 43.0), "CLOSE PORTALS", "resume", Color("efb8a9"))

func atlas_position(id: String, w: float, h: float) -> Vector2:
	for point in ATLAS_POINTS:
		if str(point["id"]) == id:
			var uv: Vector2 = point["at"]
			return Vector2(uv.x * w, uv.y * h)
	return Vector2(w * 0.1, h * 0.7)

func atlas_item(id: String) -> Dictionary:
	for point in ATLAS_POINTS:
		if str(point["id"]) == id:
			return point
	return {}

func atlas_completed(id: String) -> bool:
	# Stars are earned from recorded quests/dungeon defeats; never random UI ratings.
	if game.REALM_CATALOG.DUNGEON_BOSSES.has(id):
		return game.dungeon_clears.has(id)
	var total: int = 0
	var done: int = 0
	for quest in game.REALM_CATALOG.QUESTS:
		if str(quest["region"]) != id: continue
		total += 1
		if game.quest_claimed.has(str(quest["id"])): done += 1
	return total > 0 and done == total

func atlas_quest_counts(id: String) -> Vector2i:
	var done: int = 0
	var total: int = 0
	for quest in game.REALM_CATALOG.QUESTS:
		if str(quest["region"]) != id: continue
		total += 1
		if game.quest_claimed.has(str(quest["id"])): done += 1
	return Vector2i(done, total)

func atlas_progress_percent() -> int:
	# 35% discovery + 45% actual journal quests + 20% dungeon clears.
	var discovered: int = 0
	for point in ATLAS_POINTS:
		if game.discovered_realm_ids.has(str(point["id"])): discovered += 1
	var visit_fraction: float = float(discovered) / float(ATLAS_POINTS.size())
	var quest_fraction: float = float(game.quest_claimed.size()) / float(maxi(1, game.quest_total()))
	var dungeons: float = float(game.dungeon_clears.size()) / float(maxi(1, game.REALM_CATALOG.DUNGEON_BOSSES.size()))
	return clampi(roundi((visit_fraction * 0.35 + quest_fraction * 0.45 + dungeons * 0.20) * 100.0), 0, 100)

func draw_atlas_route(first: Vector2, last: Vector2, unlocked: bool, completed: bool) -> void:
	var points := PackedVector2Array()
	var middle: Vector2 = first.lerp(last, 0.5) + Vector2(0.0, -minf(35.0, absf(first.x - last.x) * 0.09))
	for i in range(13):
		var t: float = float(i) / 12.0
		points.append(first * pow(1.0 - t, 2.0) + middle * (2.0 * t * (1.0 - t)) + last * (t * t))
	draw_polyline(points, Color(0.07, 0.15, 0.27, 0.88), 10.0, true)
	draw_polyline(points, Color("ebbd6f") if completed else (Color("9edfcf") if unlocked else Color("577184")), 4.0 if completed else 2.7, true)

func draw_world_map(w: float, h: float) -> void:
	# Real illustrated 2.5D overworld. Routes and node states derive from save data.
	if atlas_art != null:
		draw_texture_rect(atlas_art, Rect2(0, 0, w, h), false)
	else:
		draw_rect(Rect2(0, 0, w, h), Color("183d5f"))
	draw_rect(Rect2(0, 0, w, 69), Color(0.04, 0.12, 0.22, 0.86))
	draw_line(Vector2(0, 69), Vector2(w, 69), Color("e8c48f"), 2.0)
	text(Vector2(24, 33), "ECHOES OF AETHER", 23, Color("f1e6cc"))
	text(Vector2(24, 56), "THE LIVING WORLD ATLAS", 15, Color("a9f5e4"))
	centered(w * 0.62, 37, "CHAPTER PROGRESSION  -  %d%%" % atlas_progress_percent(), 19, Color("f7dc9a"))
	var chapter_line: Rect2 = Rect2(w * 0.41, 47, w * 0.43, 8)
	draw_rect(chapter_line, Color("24334e"))
	draw_rect(Rect2(chapter_line.position, Vector2(chapter_line.size.x * float(atlas_progress_percent()) / 100.0, 8)), Color("e6bb69"))
	# Permanent graph of story paths and optional dungeon branches.
	for route in ATLAS_ROUTES:
		var src: String = str(route[0])
		var dst: String = str(route[1])
		var available: bool = game.is_realm_unlocked(dst)
		draw_atlas_route(atlas_position(src, w, h), atlas_position(dst, w, h),
			available, atlas_completed(src) and game.discovered_realm_ids.has(dst))
	for point in ATLAS_POINTS:
		var id: String = str(point["id"])
		var pos: Vector2 = atlas_position(id, w, h)
		var unlocked: bool = game.is_realm_unlocked(id)
		var current: bool = game.current_realm_id == id
		var selected: bool = atlas_selected == id
		var visited: bool = game.discovered_realm_ids.has(id)
		var clear: bool = atlas_completed(id)
		var accent: Color = Color("e8bc78") if clear else (Color("8ee9db") if unlocked else Color("6b7b91"))
		draw_circle(pos + Vector2(2.0, 5.0), 26.0 if selected else 23.0, Color(0.03, 0.11, 0.20, 0.90))
		draw_circle(pos, 27.0 if selected else 21.0, Color(accent.r, accent.g, accent.b, 0.13))
		draw_arc(pos, 25.0 if selected else 21.0, 0.0, TAU, 40, accent, 4.0 if selected else 2.6, true)
		draw_circle(pos, 13.0, Color("355669") if unlocked else Color("263548"))
		if clear:
			centered(pos.x, pos.y + 6.0, "*", 22, Color("ffe4a4"))
		elif not unlocked:
			centered(pos.x, pos.y + 4.0, "X", 13, Color("9eaabd"))
		elif current:
			centered(pos.x, pos.y + 5.0, "K", 15, Color("f4e3b1"))
		else:
			draw_circle(pos, 5.0, Color("e1f9e6") if visited else Color("93d5d6"))
		if current:
			draw_arc(pos, 31.0, 0, TAU, 40, Color("fffae3"), 2.5, true)
		if selected:
			draw_arc(pos, 35.0, 0, TAU, 40, Color("fff2ba"), 2.4, true)
		# On a small landscape phone, labels appear for selected/current only to avoid visual clutter.
		if selected or current or (w >= 1100.0 and str(game.REALM_CATALOG.region(id).get("kind", "")) == "realm"):
			var tag: String = str(point["title"])
			var label_w: float = font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 16.0
			var tx: float = clampf(pos.x - label_w * 0.5, 4.0, w - label_w - 4.0)
			var tag_y: float = pos.y - 53.0 if pos.y > h - 178.0 else pos.y + 30.0
			box(Rect2(tx, tag_y, label_w, 23.0), Color(0.06, 0.14, 0.24, 0.86), Color(accent.r, accent.g, accent.b, 0.70), 1.0)
			text(Vector2(tx + 8.0, tag_y + 17.0), tag, 12, Color("e6f2e9"))
		# Invisible 56px minimum target is intentionally larger than visual marker.
		menu_buttons.append({"rect": Rect2(pos - Vector2(28.0, 28.0), Vector2(56.0, 56.0)), "key":"atlas_node:" + id})
	# Selection strip stays below exploration paths; no huge cards covering the map.
	var footer: Rect2 = Rect2(0.0, h - 113.0, w, 113.0)
	draw_rect(footer, Color(0.035, 0.09, 0.17, 0.95))
	draw_line(Vector2(0, footer.position.y), Vector2(w, footer.position.y), Color("d5af73"), 2.5)
	var item: Dictionary = atlas_item(atlas_selected)
	if item.is_empty():
		atlas_selected = "hub"
		item = atlas_item("hub")
	var selected_id: String = str(item["id"])
	var selected_unlocked: bool = game.is_realm_unlocked(selected_id)
	var visited_status: String = "DISCOVERED" if game.discovered_realm_ids.has(selected_id) else ("AVAILABLE" if selected_unlocked else "LOCKED")
	var progress: Vector2i = atlas_quest_counts(selected_id)
	text(Vector2(24.0, h - 84.0), "CH.%d  %s" % [int(item["number"]), str(game.REALM_CATALOG.region(selected_id).get("name", item["title"]))], 19, Color("f5dfaf"))
	text(Vector2(24.0, h - 58.0), "%s  |  QUESTS %d/%d  |  %s" % [
		visited_status, progress.x, progress.y, "DUNGEON RESTORED" if atlas_completed(selected_id) else "EXPLORE & COMPLETE OBJECTIVES"], 13, Color("aee5dc"))
	text(Vector2(24.0, h - 28.0), "DISCOVERED %d/%d     QUESTS %d/%d     DUNGEONS %d/%d" % [
		game.discovered_realm_ids.size(), game.REALM_CATALOG.REGIONS.size(),
		game.quest_claimed.size(), game.quest_total(), game.dungeon_clears.size(), game.REALM_CATALOG.DUNGEON_BOSSES.size()], 12, Color("c3d4df"))
	var travel_w: float = minf(185.0, w * 0.20)
	var return_w: float = minf(148.0, w * 0.16)
	if selected_unlocked:
		menu_button(Rect2(w - travel_w - return_w - 30.0, h - 88.0, travel_w, 50.0), "TRAVEL", "atlas_travel", Color("b1ecdb"))
	else:
		var disabled_rect: Rect2 = Rect2(w - travel_w - return_w - 30.0, h - 88.0, travel_w, 50.0)
		box(disabled_rect, Color("303846"), Color("657789"), 1.0)
		centered(disabled_rect.get_center().x, disabled_rect.position.y + 32.0, "LOCKED", 17, Color("a3b0ba"))
	menu_button(Rect2(w - return_w - 18.0, h - 88.0, return_w, 50.0), "RETURN", "resume", Color("e6c6a0"))

func draw_realm_victory(w: float, h: float) -> void:
	var panel := modal(w, h, "THE REALMS AWAKEN", 705, 425)
	centered(w / 2.0, panel.position.y + 129.0, "You defeated the Shadowfen Guardian.", 21, Color("d8ffdf"))
	centered(w / 2.0, panel.position.y + 168.0, "All three new worlds are free to explore again.", 17, Color("a5d4eb"))
	menu_button(Rect2(w / 2.0 - 210, panel.position.y + 219, 420, 59), "CONTINUE EXPLORING", "explore_again")
	menu_button(Rect2(w / 2.0 - 210, panel.position.y + 298, 420, 54), "RETURN TO MOONHAVEN", "village")

func draw_dungeon_victory(w: float, h: float) -> void:
	var panel: Rect2 = modal(w, h, "DUNGEON RESTORED — GUARDIAN DEFEATED", minf(750.0, w - 40.0), minf(380.0, h - 24.0))
	centered(w * 0.5, panel.position.y + 116.0, game.area_name() + " IS SAVED", 21, Color("d3f8de"))
	centered(w * 0.5, panel.position.y + 170.0, "+175 COINS  •  +1 RELIC SHARD  •  +8 MAX HP", 17, Color("f2dcaa"))
	centered(w * 0.5, panel.position.y + 208.0, "Your reward and quest records are saved automatically.", 14, Color("add7d9"))
	menu_button(Rect2(w * 0.5 - 274.0, panel.end.y - 84.0, 250.0, 49.0), "CONTINUE EXPLORING", "dungeon_continue", Color("84dccc"))
	menu_button(Rect2(w * 0.5 + 24.0, panel.end.y - 84.0, 250.0, 49.0), "RETURN THROUGH GATE", "dungeon_return", Color("f0b988"))

func draw_v5_victory(w: float, h: float) -> void:
	var panel: Rect2 = modal(w, h, "THE TRUE AETHER CORE IS RESTORED", minf(810.0, w - 40.0), minf(415.0, h - 24.0))
	centered(w * 0.5, panel.position.y + 132.0, "The Nexus Echo has fallen. All realms can breathe again.", 19, Color("c9ffee"))
	centered(w * 0.5, panel.position.y + 190.0, "Your story, equipment, friends and quest progress are preserved.", 16, Color("f1d8ad"))
	centered(w * 0.5, panel.position.y + 236.0, "%d / %d quests completed  |  %d / %d dungeons restored" % [game.quest_claimed.size(), game.quest_total(), game.dungeon_clears.size(), game.REALM_CATALOG.DUNGEON_BOSSES.size()], 16, Color("addce0"))
	menu_button(Rect2(w * 0.5 - 208.0, panel.end.y - 89.0, 416.0, 56.0), "EXPLORE THE REALMS AGAIN", "ending_continue", Color("94e5d1"))

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

func draw_v6_puzzle(w: float, h: float) -> void:
	# Dedicated puzzle UX: separate mechanics and safe exit, never a gameplay HUD
	# overlay. Gameplay physics are paused while this screen is visible.
	var panel_w: float = minf(925.0, w - 34.0)
	var panel_h: float = minf(552.0, h - 25.0)
	var box_rect: Rect2 = modal(w, h, "DEEP REALMS — CHAMBER TRIAL", panel_w, panel_h)
	var data: Dictionary = game.trial_puzzle
	if data.is_empty(): return
	var kind: String = str(data.get("kind", ""))
	var chamber: Dictionary = game.BONUS_TRIALS.get(game.trial_puzzle_id, {}) if game.BONUS_TRIALS.has(game.trial_puzzle_id) else game.REALM_CATALOG.TRIALS.get(game.trial_puzzle_id, {})
	var name: String = str(chamber.get("name", "HIDDEN CHAMBER"))
	centered(w * 0.5, box_rect.position.y + 81.0, name, 21, Color("f5d7a7"))
	centered(w * 0.5, box_rect.position.y + 106.0,
		{"mosaic": "REASSEMBLE THE BROKEN WORLD MAP", "circuit": "CONNECT THE ENERGY BEAM", "logic": "SOLVE THREE BALANCED EQUATIONS",
		"memory": "MEMORIZE AND REPEAT THE GLYPHS", "melody": "STUDY THE FIVE CHIMES, REPLAY THE TUNE", "scale": "BALANCE TWO PLATFORMS TO THE SAME MASS"}.get(kind, "SOLVE THE CHAMBER"), 15, Color("a7e9df"))
	var tile: float = minf(85.0, (panel_h - 212.0) / 3.0)
	var gap: float = 7.0
	var grid_left: float = box_rect.position.x + 68.0
	var grid_top: float = box_rect.position.y + 131.0
	var accent: Color = Color("7fe7d9")
	if kind in ["mosaic", "circuit"]:
		for i in range(9):
			var xx: float = grid_left + float(i % 3) * (tile + gap)
			var yy: float = grid_top + float(int(i / 3)) * (tile + gap)
			var r: Rect2 = Rect2(xx, yy, tile, tile)
			var mask: int = 0
			box(r, Color("15293c"), Color("84c7c7"), 2.0)
			if kind == "mosaic":
				var index: int = int(data["tiles"][i])
				if index > 0:
					var art: Texture2D = game.v6_art_for(game.trial_puzzle_id)
					if art != null:
						var srcw: float = float(art.get_width()) / 3.0
						var srch: float = float(art.get_height()) / 3.0
						var source: Rect2 = Rect2(float((index - 1) % 3) * srcw, float(int((index - 1) / 3)) * srch, srcw, srch)
						draw_texture_rect_region(art, Rect2(xx + 4, yy + 4, tile - 8, tile - 8), source, Color(0.9, 0.99, 1.0, 0.94))
					else:
						draw_rect(Rect2(xx + 4, yy + 4, tile - 8, tile - 8), Color("316e81"))
					centered(xx + tile * 0.5, yy + tile * 0.65, str(index), 23, Color("fff3ca"))
			else:
				mask = game.PUZZLE_ENGINE.rotate_mask(int(game.PUZZLE_ENGINE.BASE_PIPES[i]), int(data["rotations"][i]))
				var center: Vector2 = Vector2(xx + tile * 0.5, yy + tile * 0.5)
				if mask == 0:
					draw_circle(center, 6.0, Color("405969"))
				else:
					draw_circle(center, 9.0, Color("f6e7a2"))
					for bit in [1, 2, 4, 8]:
						if (mask & bit) != 0:
							var vector: Vector2 = {1: Vector2.UP, 2: Vector2.RIGHT, 4: Vector2.DOWN, 8: Vector2.LEFT}[bit]
							draw_line(center, center + vector * tile * 0.40, Color("8afaf0"), 11.0, true)
			if kind == "mosaic" or mask != 0:
				menu_buttons.append({"rect": r, "key": "v6_cell:%d" % i})
		if kind == "circuit":
			centered(grid_left + tile * 1.5 + gap, grid_top + tile * 3 + 28, "LIGHT IN <         > LIGHT OUT", 15, Color("fbdba4"))
	elif kind == "logic":
		var vals: Array = data["dials"]
		for i in range(3):
			var rx: float = grid_left + float(i) * (tile + 30.0)
			menu_button(Rect2(rx, grid_top + 35.0, tile + 18.0, 95.0),
				"%s %d" % [["LEFT", "MID", "RIGHT"][i], int(vals[i])], "v6_cell:%d" % i, Color("aacfff"))
		var cl: Array = data["clues"]
		text(Vector2(grid_left, grid_top + 175), "LEFT + MID = %d" % int(cl[0]), 17, Color("ffe2a5"))
		text(Vector2(grid_left, grid_top + 200), "MID + RIGHT = %d" % int(cl[1]), 17, Color("ffe2a5"))
		text(Vector2(grid_left, grid_top + 225), "LEFT + RIGHT = %d" % int(cl[2]), 17, Color("ffe2a5"))
	elif kind == "scale":
		var weights: Array = data["weights"]
		var placements: Array = data["placements"]
		var left_mass := 0
		var right_mass := 0
		for i in range(weights.size()):
			var location: int = int(placements[i])
			if location == 1: left_mass += int(weights[i])
			if location == 2: right_mass += int(weights[i])
			var rx: float = grid_left + float(i % 2) * 145.0
			var ry: float = grid_top + float(int(i / 2)) * 98.0
			var side: String = ["SHELF", "LEFT", "RIGHT"][location]
			menu_button(Rect2(rx, ry, 133.0, 80.0), "%d KG: %s" % [int(weights[i]), side],
				"v6_cell:%d" % i, [Color("99aabd"), Color("b8e6a1"), Color("94d8fa")][location])
		text(Vector2(grid_left + 7.0, grid_top + 232.0), "LEFT: %d / 5    RIGHT: %d / 5" % [left_mass, right_mass], 17, Color("ffe2a5"))
		text(Vector2(grid_left + 7.0, grid_top + 257.0), "TAP WEIGHTS TO MOVE THEM", 15, Color("a5ddd0"))
	elif kind in ["memory", "melody"]:
		var colours: Array = ["SUN", "MOON", "STAR", "FLAME"]
		for i in range(4):
			var rx: float = grid_left + float(i) * (tile * 0.84 + 9.0)
			menu_button(Rect2(rx, grid_top + 110.0, tile * 0.82, 87.0), str(colours[i]),
				"v6_cell:%d" % i, [Color("ffe4a5"), Color("c5d4fe"), Color("a8ece3"), Color("f9a481")][i])
		var preview: String = "LISTEN / OBSERVE, THEN REPEAT" if kind == "melody" else "HIDDEN — REPEAT FROM MEMORY"
		if game.trial_preview_time > 0.0:
			preview = ""
			for glyph in data["sequence"]:
				preview += str(colours[int(glyph)]) + "   "
		centered(grid_left + 181.0, grid_top + 63.0, preview, 13, Color("ffdcad"))
		centered(grid_left + 183.0, grid_top + 239.0, ("NOTES: %d / %d" if kind == "melody" else "CORRECT: %d / %d") % [int(data["progress"]), data["sequence"].size()], 17, Color("a8f2cf"))
	var info_x: float = box_rect.position.x + panel_w * 0.57
	var info_y: float = grid_top + 18.0
	text(Vector2(info_x, info_y), "CHAMBER RULES", 20, Color("f4d9a4"))
	text(Vector2(info_x, info_y + 40.0), "NO TIMER / NO DAMAGE", 16, Color("a9e8d0"))
	text(Vector2(info_x, info_y + 74.0), "EXIT ANYTIME", 17, Color("a9e8d0"))
	text(Vector2(info_x, info_y + 109.0), "1 RELIC + COINS", 16, Color("f0d8a8"))
	text(Vector2(info_x, info_y + 151.0), "MOVES: %d" % int(data["moves"]), 17, Color("a9e8d0"))
	var info_message: String = str(game.trial_hint_text)
	if info_message == "": info_message = str(data["message"])
	centered(w * 0.5, box_rect.end.y - 113.0, info_message, 14, Color("bee9df"))
	var footer_w: float = (panel_w - 95.0) / 3.0
	for i in range(3):
		menu_button(Rect2(box_rect.position.x + 28.0 + float(i) * (footer_w + 18.0),
			box_rect.end.y - 82.0, footer_w, 52.0), ["HINT", "RESTART", "EXIT CHAMBER"][i],
			["v6_hint", "v6_restart", "v6_leave"][i], [Color("a4e8df"), Color("b7bcff"), Color("f4b0a5")][i])

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
