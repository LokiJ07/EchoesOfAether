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
	return Vector2(145.0, size.y - 120.0)

func control_centers() -> Dictionary:
	var w = size.x
	var h = size.y
	return {"attack": Vector2(w - 129, h - 122), "jump": Vector2(w - 278, h - 80),
		"dash": Vector2(w - 315, h - 205), "skill": Vector2(w - 187, h - 281),
		"potion": Vector2(w - 433, h - 77), "interact": Vector2(w - 437, h - 187)}

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

func draw_dash_button(at: Vector2) -> void:
	var tint := Color("84d9f0")
	var radius := 42.0
	draw_circle(at + Vector2(3, 5), radius + 2.0, Color(0, 0, 0, 0.31))
	draw_circle(at, radius, Color("162c39"))
	draw_arc(at, radius - 2.0, 0.0, TAU, 36, tint, 2.0, true)
	if game.dash_cooldown > 0.0:
		draw_arc(at, radius - 3, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - game.dash_cooldown / 0.7), 40, tint, 4.0, true)
		centered(at.x, at.y + 7.0, "%.1fs" % game.dash_cooldown, 18, tint)
	else:
		centered(at.x, at.y + 8.0, ">>", 25, tint)
	centered(at.x, at.y + radius + 16, "DASH", 12, tint)

func skill_status_text() -> String:
	if game.skill_timer > 0.0:
		return "%.1fs" % game.skill_timer
	if game.stamina < 35.0:
		return "LOW SP"
	return "READY"

func draw_skill_button(at: Vector2) -> void:
	var radius := 45.0
	var tint := Color("c6a2f5")
	var recharging: bool = game.skill_timer > 0.0
	var low_stamina: bool = game.stamina < 35.0
	draw_circle(at + Vector2(3, 5), radius + 2.0, Color(0, 0, 0, 0.31))
	draw_circle(at, radius, Color("152333") if recharging or low_stamina else Color("284258"))
	draw_arc(at, radius - 2.0, 0.0, TAU, 48, Color("677586") if recharging else tint, 2.0, true)
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
	if game.state in ["playing", "inventory", "quests", "shop", "trainer", "portals", "worldmap", "pause", "settings", "victory", "realm_victory", "defeat"]:
		draw_game_status(w, h)
	if game.state == "playing":
		draw_boss_health(w)
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
	box(Rect2(13, 12, 263, 85), Color("112636"), Color("3d7278"), 1.0)
	text(Vector2(23, 35), "LV %d   %d COINS" % [game.level, game.coins], 17, Color("e9d69a"))
	bar(Vector2(24, 55), 151, game.hp / game.max_hp, Color("e86d81"), "HP")
	bar(Vector2(24, 80), 151, game.stamina / game.max_stamina, Color("57d5c8"), "STAMINA")
	var needed = maxi(1, game.level * 55)
	bar(Vector2(185, 55), 73, float(game.exp_points) / float(needed), Color("c9a0ee"), "EXP")
	text(Vector2(187, 89), "%d/%d" % [game.exp_points, needed], 13, Color("d3c3e7"))
	centered(w / 2.0, 30, game.area_name(), 17, Color("cfdecb"))
	if game.quest_stage < 3:
		var quest_label = ("TALK TO MIRA  (%d/3 SEEDS)" % game.seeds) if game.quest_stage == 0 else ("AETHER SEEDS %d/3" % game.seeds if game.quest_stage == 1 else "DEFEAT THE WARDEN")
		centered(w / 2.0, 55, quest_label, 14, Color("e4c891"))
	else:
		centered(w / 2.0, 55, "VALLEY SAVED — MAIN QUEST COMPLETE", 14, Color("a7f2bc"))
	for i in range(4):
		var label = ["BAG", "QUEST", "MAP", "PAUSE"][i]
		var key = ["bag", "quest", "map", "pause"][i]
		var r = Rect2(w - 396 + i * 96, 18, 90, 49)
		box(r, Color("162d40"), Color("6a9f9c"), 1.0)
		centered(r.position.x + r.size.x / 2.0, r.position.y + 28, label, 15)
		top_buttons.append({"rect": r, "key": key})

func draw_mobile_controls(w: float, h: float) -> void:
	var joy = joystick_center()
	draw_circle(joy, 99, Color(0.02, 0.12, 0.18, 0.42))
	draw_arc(joy, 96, 0, TAU, 52, Color("a0dccd"), 3.0, true)
	draw_circle(joy + Vector2(game.touch_axis * 55.0, 0), 46, Color("31616f"))
	centered(joy.x, joy.y - 107, "MOVE", 16, Color("b3e8dc"))
	text(joy + Vector2(-66, 10), "<", 28, Color("e2f5f3"))
	text(joy + Vector2(51, 10), ">", 28, Color("e2f5f3"))
	var c = control_centers()
	control_button(c["attack"], 51, "S", "ATTACK", Color("f2ba7b"))
	control_button(c["jump"], 45, "^", "JUMP", Color("b4e4c2"))
	draw_dash_button(c["dash"])
	draw_skill_button(c["skill"])
	control_button(c["potion"], 37, "+", "POTION %d" % game.potions, Color("f5a2a2"))
	if game.nearby_npc() != "":
		var label := "OPEN" if game.nearby_npc() == "cache" else ("TRAIN" if game.nearby_npc() == "scout" else ("SHOP" if game.nearby_npc() == "merchant" else "TALK"))
		control_button(c["interact"], 40, "!", label, Color("f3db98"))

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
	centered(cx, h - 19, "OFFLINE  |  WORLDS BEYOND EXPANSION  |  v0.3", 14, Color("a4c3bf"))

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
	text(Vector2(x, r.position.y + 421.0), "HIDDEN RELIC CACHES: %d / 6   |   TRAIN WITH TARO" % game.opened_caches.size(), 15, Color("f0ddb4"))
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
	text(Vector2(x, y + 297.0), "Find glowing chests; bring relic shards to TARO for new abilities.", 15, Color("b9dbc8"))
	text(Vector2(x, y + 332.0), game.expansion_quest_label(), 16, Color("b4e5f4"))
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
	var panel := modal(w, h, "PORTAL NETWORK - CHOOSE YOUR DESTINATION", 775, 535)
	centered(w / 2.0, panel.position.y + 96.0, "Travel between discovered realms. Your progress is saved.", 16, Color("a7e8d8"))
	for i in range(game.PORTAL_NAMES.size()):
		var y: float = panel.position.y + 116.0 + float(i) * 77.0
		if game.portal_unlocked[i]:
			menu_button(Rect2(w / 2.0 - 316.0, y, 632.0, 55.0), game.PORTAL_NAMES[i], "portal%d" % i, Color("88e6d3"))
		else:
			var locked_rect := Rect2(w / 2.0 - 316.0, y, 632.0, 55.0)
			box(locked_rect, Color("1a2733"), Color("586172"), 1.0)
			centered(w / 2.0, y + 36, "LOCKED - " + game.PORTAL_NAMES[i], 18, Color("81909f"))
	menu_button(Rect2(w / 2.0 - 143, panel.end.y - 61, 286, 44), "RETURN TO GAME", "resume")

func draw_world_map(w: float, h: float) -> void:
	var panel := modal(w, h, "AETHER REALM ATLAS", 845, 485)
	centered(w / 2.0, panel.position.y + 98, "THE CONNECTED WORLD - WEST TO EAST", 18, Color("e9d29c"))
	var xs := [0.0, 1900.0, 4750.0, 8400.0, 10800.0, 12900.0]
	var names := ["MOONHAVEN", "WHISPERWOOD", "SUNKEN RUINS", "CRYSTAL HOLLOW", "SKY HIGHLANDS", "SHADOWFEN"]
	var progress: float = clampf(game.player_pos.x / game.WORLD_WIDTH, 0.0, 1.0)
	var left: float = w * 0.5 - 376.0
	var y: float = panel.position.y + 197.0
	draw_rect(Rect2(left, y, 752, 9), Color("203b48"))
	draw_rect(Rect2(left, y, progress * 752.0, 9), Color("78d8ca"))
	for i in range(xs.size()):
		var bx: float = left + xs[i] / game.WORLD_WIDTH * 752.0
		draw_circle(Vector2(bx, y + 4), 8, Color("f5d79a") if i >= 3 else Color("a9e4d2"))
		var offset_y := 42.0 if i % 2 == 0 else -26.0
		text(Vector2(bx - 35.0, y + offset_y), names[i], 12, Color("c7e0d9"))
	centered(w / 2.0, panel.position.y + 332, "PORTALS UNLOCKED: %d / 4  |  Current region: %s" % [game.unlocked_portal_count(), game.area_name()], 16, Color("b0eee4"))
	menu_button(Rect2(w / 2.0 - 143, panel.end.y - 60, 286, 43), "BACK TO ADVENTURE", "resume")

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
	menu_button(Rect2(w / 2.0 - 202, r.position.y + 185, 404, 55), "EXPLORE CRYSTAL HOLLOW", "explore_world")
	menu_button(Rect2(w / 2.0 - 202, r.position.y + 246, 404, 49), "RETURN TO MOONHAVEN", "village")
	menu_button(Rect2(w / 2.0 - 202, r.position.y + 305, 404, 43), "MAIN MENU", "main")
