extends Control
## Accessible, landscape-first touchscreen HUD. No giant panels over active play.

@onready var game = get_node("../..")
var font: Font
var menu_buttons: Array = []
var top_buttons: Array = []
var main_accent := Color("75e7d4")
var settings_return := "pause"

func _ready() -> void:
	font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func joystick_center() -> Vector2:
	return Vector2(122.0, size.y - 104.0)

func control_centers() -> Dictionary:
	var w = size.x
	var h = size.y
	return {"attack": Vector2(w - 116, h - 112), "jump": Vector2(w - 242, h - 77),
		"dash": Vector2(w - 279, h - 178), "skill": Vector2(w - 157, h - 243),
		"potion": Vector2(w - 382, h - 72), "interact": Vector2(w - 387, h - 166)}

func handle_top_press(pos: Vector2) -> bool:
	for entry in top_buttons:
		if entry["rect"].has_point(pos):
			match entry["key"]:
				"bag": game.state = "inventory"
				"quest": game.state = "quests"
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
			"sound": game.sound_on = not game.sound_on
			"music":
				game.music_on = not game.music_on
				game.music.stream_paused = not game.music_on
			"back_settings":
				game.state = settings_return
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
	box(rect, Color("1a3343"), accent, 2)
	centered(rect.position.x + rect.size.x / 2.0, rect.position.y + rect.size.y * 0.68, label, 21, Color("f5efcf"))
	menu_buttons.append({"rect": rect, "key": code})

func control_button(at: Vector2, radius: float, letter: String, label: String, tint: Color) -> void:
	draw_circle(at + Vector2(3, 5), radius + 2, Color(0, 0, 0, 0.31))
	draw_circle(at, radius, Color("183044") if game.dash_timer <= 0.0 else Color("295c66"))
	draw_arc(at, radius - 2, 0, TAU, 36, tint, 3.0, true)
	centered(at.x, at.y + 8, letter, 27, Color("f2ffef"))
	centered(at.x, at.y + radius + 16, label, 12, tint)

func _draw() -> void:
	menu_buttons.clear()
	top_buttons.clear()
	var w = size.x
	var h = size.y
	if game.state == "main":
		draw_main_menu(w, h)
		return
	if game.state in ["playing", "inventory", "quests", "shop", "pause", "settings", "victory", "defeat"]:
		draw_game_status(w, h)
	if game.state == "playing":
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
		"pause": draw_pause(w, h)
		"settings": draw_settings(w, h)
		"defeat": draw_defeat(w, h)
		"victory": draw_victory(w, h)
	if game.message_time > 0:
		centered(w / 2.0, h - 24, game.message, 16, Color("ffd59a"))

func draw_game_status(w: float, h: float) -> void:
	# Compact status strip: never blocks the central gameplay corridor.
	box(Rect2(13, 12, 263, 85), Color("112636"), Color("3d7278"), 1.0)
	text(Vector2(23, 35), "LV %d   %d COINS" % [game.level, game.coins], 17, Color("e9d69a"))
	bar(Vector2(24, 55), 151, game.hp / game.max_hp, Color("e86d81"), "HP")
	bar(Vector2(24, 80), 151, game.stamina / game.max_stamina, Color("57d5c8"), "STAMINA")
	var needed = maxi(1, game.level * 55)
	bar(Vector2(185, 55), 73, float(game.exp_points) / float(needed), Color("c9a0ee"), "EXP")
	text(Vector2(187, 89), "%d/%d" % [game.exp_points, needed], 13, Color("d3c3e7"))
	centered(w / 2.0, 30, game.area_name(), 17, Color("cfdecb"))
	if game.quest_stage < 3:
		var quest_label = "TALK TO MIRA" if game.quest_stage == 0 else ("AETHER SEEDS %d/3" % game.seeds if game.quest_stage == 1 else "DEFEAT THE WARDEN")
		centered(w / 2.0, 55, quest_label, 14, Color("e4c891"))
	else:
		centered(w / 2.0, 55, "VALLEY SAVED — MAIN QUEST COMPLETE", 14, Color("a7f2bc"))
	for i in range(3):
		var label = ["BAG", "QUEST", "PAUSE"][i]
		var key = ["bag", "quest", "pause"][i]
		var r = Rect2(w - 287 + i * 94, 18, 87, 45)
		box(r, Color("162d40"), Color("6a9f9c"), 1.0)
		centered(r.position.x + r.size.x / 2.0, r.position.y + 28, label, 15)
		top_buttons.append({"rect": r, "key": key})

func draw_mobile_controls(w: float, h: float) -> void:
	var joy = joystick_center()
	draw_circle(joy, 76, Color(0.02, 0.12, 0.18, 0.36))
	draw_arc(joy, 73, 0, TAU, 52, Color("a0dccd"), 2, true)
	draw_circle(joy + Vector2(game.touch_axis * 43.0, 0), 37, Color("31616f"))
	centered(joy.x, joy.y - 82, "MOVE", 13, Color("b3e8dc"))
	text(joy + Vector2(-50, 9), "<", 25, Color("e2f5f3"))
	text(joy + Vector2(36, 9), ">", 25, Color("e2f5f3"))
	var c = control_centers()
	control_button(c["attack"], 44, "S", "ATTACK", Color("f2ba7b"))
	control_button(c["jump"], 38, "^", "JUMP", Color("b4e4c2"))
	control_button(c["dash"], 36, ">>", "DASH", Color("84d9f0"))
	control_button(c["skill"], 39, "*", "AETHER", Color("c6a2f5"))
	control_button(c["potion"], 32, "+", "POTION %d" % game.potions, Color("f5a2a2"))
	if game.nearby_npc() != "":
		control_button(c["interact"], 32, "!", "TALK", Color("f3db98"))

func modal(w: float, h: float, heading: String, width: float = 650.0, height: float = 470.0) -> Rect2:
	draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.05, 0.11, 0.75))
	var r = Rect2((w - width) * 0.5, (h - height) * 0.5, width, height)
	box(r, Color("152a39"), Color("79aaab"), 3.0)
	centered(w / 2.0, r.position.y + 51, heading, 31, Color("f4dea6"))
	draw_line(Vector2(r.position.x + 28, r.position.y + 67), Vector2(r.end.x - 28, r.position.y + 67), Color("6aa8a0"), 2)
	return r

func draw_main_menu(w: float, h: float) -> void:
	draw_rect(Rect2(0, 0, w, h), Color(0.01, 0.08, 0.15, 0.62))
	var cx = w * 0.5
	centered(cx, h * 0.215, "E C H O E S   O F   A E T H E R", 37, Color("f4deb5"))
	centered(cx, h * 0.28, "THE LAST LIGHT OF MOONHAVEN", 18, Color("96dfd3"))
	box(Rect2(cx - 202, h * 0.34, 404, 285), Color("152b3a"), Color("77c4b9"), 2.0)
	menu_button(Rect2(cx - 171, h * 0.38, 342, 56), "NEW ADVENTURE", "new")
	menu_button(Rect2(cx - 171, h * 0.49, 342, 56), "CONTINUE JOURNEY", "continue", Color("9dacec"))
	menu_button(Rect2(cx - 171, h * 0.60, 342, 56), "SETTINGS", "settings", Color("bca7c8"))
	centered(cx, h - 19, "OFFLINE  |  ORIGINAL 2D FANTASY ADVENTURE  |  v0.1", 14, Color("a4c3bf"))

func draw_dialogue(w: float, h: float) -> void:
	var r = Rect2(w * 0.16, h * 0.70, w * 0.68, h * 0.23)
	box(r, Color("152e42"), Color("deb875"), 2.5)
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
	text(r.position + Vector2(r.size.x - 188, r.size.y - 13), "TAP TO CLOSE", 14, Color("9fe1d2"))

func draw_inventory(w: float, h: float) -> void:
	var r = modal(w, h, "TRAVELER'S INVENTORY", 690, 474)
	var x = r.position.x + 54
	var y = r.position.y + 115
	for i in range(4):
		var icon = ["POTIONS", "COINS", "AETHER SEEDS", "SWORD"][i]
		var amount = [str(game.potions), str(game.coins), "%d / 3" % game.seeds, "LEVEL %d" % game.sword_level][i]
		var rr = Rect2(x + float(i % 2) * 298, y + float(floori(float(i) / 2.0)) * 102, 272, 80)
		box(rr, Color("233a49"), Color("5c8d94"))
		text(rr.position + Vector2(16, 28), icon, 17, Color("edd8ac"))
		text(rr.position + Vector2(16, 58), amount, 24, Color("a6f3df"))
	text(Vector2(x, y + 252), "ARMOR LV %d   |   ATTACK %d   |   MAX HP %d" % [game.armor_level, 17 + game.sword_level * 8 - 8, int(game.max_hp)], 17)
	menu_button(Rect2(w / 2.0 - 141, r.end.y - 67, 282, 46), "BACK TO ADVENTURE", "resume")

func draw_quests(w: float, h: float) -> void:
	var r = modal(w, h, "THE FADING STAR — QUEST LOG", 730, 455)
	var x = r.position.x + 52
	var y = r.position.y + 119
	var entries = ["1. Speak with Mira in Moonhaven Village", "2. Recover 3 Aether Seeds from forest slimes", "3. Pass the Ancient Gate in the Sunken Ruins", "4. Defeat the Warden of the Fading Star"]
	var done = [game.quest_stage >= 1, game.quest_stage >= 2, game.quest_stage >= 2, game.quest_stage >= 3]
	for i in range(entries.size()):
		text(Vector2(x, y + i * 51), ("[DONE] " if done[i] else "[  ] ") + entries[i], 17, Color("83e6bf") if done[i] else Color("f3e4c4"))
	menu_button(Rect2(w / 2.0 - 139, r.end.y - 71, 278, 46), "BACK TO ADVENTURE", "resume")

func draw_shop(w: float, h: float) -> void:
	var r = modal(w, h, "LYRA'S STARLIT EMPORIUM", 743, 470)
	centered(w / 2.0, r.position.y + 98, "BALANCE: %d STARLIGHT COINS" % game.coins, 19, Color("efda9c"))
	var labels = ["HEALING POTION  +55 HP   •  20 COINS", "UPGRADE SWORD  •  %d COINS" % (85 * game.sword_level), "UPGRADE ARMOR  •  %d COINS" % (80 * game.armor_level)]
	for i in range(3):
		menu_button(Rect2(w / 2.0 - 300, r.position.y + 127 + float(i) * 74, 600, 58), labels[i], "buy%d" % i)
	menu_button(Rect2(w / 2.0 - 142, r.end.y - 65, 284, 45), "LEAVE SHOP", "resume")

func draw_pause(w: float, h: float) -> void:
	var r = modal(w, h, "JOURNEY PAUSED", 507, 477)
	menu_button(Rect2(w / 2.0 - 177, r.position.y + 96, 354, 57), "RESUME JOURNEY", "resume")
	menu_button(Rect2(w / 2.0 - 177, r.position.y + 167, 354, 57), "INVENTORY", "inventory")
	menu_button(Rect2(w / 2.0 - 177, r.position.y + 238, 354, 57), "SETTINGS", "settings")
	menu_button(Rect2(w / 2.0 - 177, r.position.y + 309, 354, 57), "SAVE & MAIN MENU", "main", Color("edb4a6"))

func draw_settings(w: float, h: float) -> void:
	var r = modal(w, h, "AETHER SETTINGS", 550, 399)
	menu_button(Rect2(w / 2.0 - 190, r.position.y + 108, 380, 52), "MUSIC: %s" % ("ON" if game.music_on else "OFF"), "music")
	menu_button(Rect2(w / 2.0 - 190, r.position.y + 177, 380, 52), "SOUND: %s" % ("ON" if game.sound_on else "OFF"), "sound")
	menu_button(Rect2(w / 2.0 - 190, r.position.y + 260, 380, 52), "BACK", "back_settings")

func draw_defeat(w: float, h: float) -> void:
	var r = modal(w, h, "YOUR LIGHT HAS FADED", 580, 360)
	centered(w / 2.0, r.position.y + 119, "The Aether can always be rekindled.", 19, Color("d7cbcd"))
	menu_button(Rect2(w / 2.0 - 186, r.position.y + 151, 372, 59), "REKINDLE AT CHECKPOINT", "respawn")
	menu_button(Rect2(w / 2.0 - 186, r.position.y + 232, 372, 55), "MAIN MENU", "main")

func draw_victory(w: float, h: float) -> void:
	var r = modal(w, h, "THE STAR SHINES AGAIN", 680, 393)
	centered(w / 2.0, r.position.y + 118, "You defeated the Warden and restored the valley!", 19, Color("e9e1c7"))
	centered(w / 2.0, r.position.y + 152, "The story ends, but Moonhaven lives on.", 18, Color("93e4c4"))
	menu_button(Rect2(w / 2.0 - 202, r.position.y + 197, 404, 58), "RETURN TO MOONHAVEN", "village")
	menu_button(Rect2(w / 2.0 - 202, r.position.y + 274, 404, 56), "MAIN MENU", "main")
