extends SceneTree
## v0.6 gameplay: customizable mobile controls, real touch inputs, mastery combat.
func _initialize() -> void:
	call_deferred("run_tests")

func check(value: bool, message: String) -> bool:
	if not value:
		push_error("V0.6 FAILED: " + message)
		quit(1)
		return false
	return true

func run_tests() -> void:
	var packed = load("res://scenes/Main.tscn")
	if not check(packed != null, "Main scene loads"): return
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.start_new_game()
	var hud = game.hud
	if not check(hud.CONTROL_KEYS.has("guard") and hud.CONTROL_KEYS.has("joystick"), "HUD editor offers guard and joystick"): return
	if not check(hud.CONTROLS_FILE == "user://aether_controls.json", "Controls save separately from game progress"): return
	# A repositioned joystick must drive actual movement and not retain an obsolete hitbox.
	hud.reset_control_layout()
	hud.set_control_position("joystick", Vector2(230, 515))
	hud.set_control_position("attack", Vector2(845, 450))
	if not check(hud.joystick_center().distance_to(Vector2(230, 515)) < 1.0, "Joystick moves"): return
	if not check(hud.control_centers()["attack"].distance_to(Vector2(845, 450)) < 1.0, "Attack button moves"): return
	game.touch_press(hud.joystick_center() + Vector2(78, 0), 31)
	game.update_player(0.09)
	if not check(game.joystick_touch == 31 and game.touch_axis > 0.8 and game.velocity.x > 0.0, "Relocated joystick really moves player"): return
	game.touch_release(31)
	if not check(game.touch_axis == 0.0 and game.joystick_touch == -1, "Relocated joystick releases correctly"): return
	hud.change_control_scale(0.1)
	hud.change_control_opacity(-0.1)
	if not check(hud.control_scale > 1.0 and hud.control_opacity < 0.88, "HUD size and opacity controls work"): return
	hud.save_control_layout()
	hud.custom_positions.clear()
	hud.control_scale = 1.0
	hud.control_opacity = 1.0
	hud.load_control_layout()
	if not check(hud.joystick_center().distance_to(Vector2(230, 515)) < 1.0 and hud.control_scale > 1.0 and hud.control_opacity < 0.88, "HUD editor preferences survive disk reload"): return
	# Simulate the touchscreen dragging workflow while settings are open.
	game.state = "hud_edit"
	hud.menu_buttons.clear()
	var old_attack_pos: Vector2 = hud.control_centers()["attack"]
	var touch = InputEventScreenTouch.new()
	touch.index = 92
	touch.pressed = true
	touch.position = old_attack_pos
	game._input(touch)
	var drag = InputEventScreenDrag.new()
	drag.index = 92
	drag.position = Vector2(748, 465)
	game._input(drag)
	touch.pressed = false
	game._input(touch)
	if not check(hud.control_centers()["attack"].distance_to(Vector2(748, 465)) < 1.0, "Dragging actual touchscreen event moves and saves button"): return
	if not check(hud.editor_touch == -1 and hud.editor_key == "", "Drag release clears editor state"): return
	hud.custom_positions.clear()
	hud.load_control_layout()
	if not check(hud.control_centers()["attack"].distance_to(Vector2(748, 465)) < 1.0, "Touch-drag position persisted"): return
	hud.reset_control_layout()
	if not check(hud.custom_positions.is_empty() and is_equal_approx(hud.control_scale, 1.0), "Reset restores defaults"): return
	game.state = "playing"
	# Guard absorbs a real enemy hit and counters that enemy.
	var enemy: Dictionary = {}
	for e in game.enemies:
		if e["type"] == "slime":
			enemy = e
			break
	if not check(not enemy.is_empty(), "Enemy for guard test exists"): return
	game.player_pos = Vector2(float(enemy["x"]) - 50.0, 500.0)
	var before_hp: float = game.hp
	var before_enemy_hp: float = enemy["hp"]
	game.guard()
	if not check(game.guard_window > 0.0 and game.guard_cooldown > 0.0, "Guard starts active defensive window and cooldown"): return
	game.damage_player(24.0)
	if not check(game.hp == before_hp and game.guard_window == 0.0 and enemy["hp"] < before_enemy_hp, "Perfect guard blocks damage and counters enemy"): return
	var last_cooldown: float = game.guard_cooldown
	game.guard()
	if not check(game.guard_cooldown == last_cooldown, "Guard cannot restart during cooldown"): return
	# Three consecutive taps become a heavier finishing strike.
	game.invincible = 0.0
	game.attack_timer = 0.0
	game.combo_timer = 0.0
	game.attack()
	if not check(game.combo_stage == 1, "Combo starts at first strike"): return
	game.attack_timer = 0.0
	game.attack()
	if not check(game.combo_stage == 2, "Combo second strike"): return
	game.attack_timer = 0.0
	game.attack()
	if not check(game.combo_stage == 3, "Combo third finishing strike"): return
	# Lifetime bounty cannot be earned twice on a load or later enemies.
	game.total_kills = 11
	game.mastery_rewards.clear()
	game.add_enemy("slime", 2800.0)
	var reward_enemy: Dictionary = game.enemies[-1]
	var coins_before: int = game.coins
	game.hit_enemy(reward_enemy, 999.0)
	if not check(game.total_kills == 12 and game.mastery_rewards.has(12) and game.coins >= coins_before + 60, "Hunter mastery gives one-time milestone rewards"): return
	game.save_game()
	if not check(game.load_game() and game.mastery_rewards.has(12) and game.total_kills == 12, "Mastery persists across saved journeys"): return
	# A v0.3 save must still load even though the new fields are absent.
	var old = {"max_hp": 114.0, "hp": 95.0, "level": 3, "exp": 12, "coins": 55,
		"potions": 2, "sword": 1, "armor": 1, "stamina_max": 100.0,
		"seeds": 3, "quest": 2, "checkpoint": 2030.0, "boss": false,
		"sound": true, "music": true, "save_version": 3,
		"portal_unlocked": [true, false, false, false],
		"world_bosses_cleared": [false, false, false]}
	var legacy = FileAccess.open("user://aether_save.json", FileAccess.WRITE)
	if not check(legacy != null, "Legacy save writable"): return
	legacy.store_string(JSON.stringify(old))
	legacy.close()
	if not check(game.load_game() and game.level == 3 and game.quest_stage == 2 and game.total_kills == 0 and game.mastery_rewards.is_empty(), "v0.3 saves migrate with safe v0.6 defaults"): return
	# Responsive layout is computed from the current viewport, not a fixed 16:9 image.
	for simulated_view in [Vector2(960, 540), Vector2(1152, 648), Vector2(1440, 648),
		Vector2(1152, 864), Vector2(1920, 648)]:
		var safe: Rect2 = hud.safe_layout_rect(simulated_view)
		var controls: Dictionary = hud.default_control_centers_for(simulated_view)
		var factor: float = hud.screen_scale_for(simulated_view)
		if not check(factor >= 0.72 and factor <= 1.18, "Screen scale stays within reasonable touch size"): return
		for key in hud.CONTROL_KEYS:
			if not check(safe.has_point(controls[key]), "Control %s stays within safe margins on %s" % [key, str(simulated_view)]): return
		if not check(controls["joystick"].x < controls["potion"].x and controls["jump"].x < controls["attack"].x, "No left/right cluster inversion on %s" % str(simulated_view)): return
		if not check(controls["attack"].distance_to(controls["jump"]) > 95.0 * factor, "Attack and jump retain separate tap regions on %s" % str(simulated_view)): return
	print("PASS: adaptive HUD stays in bounds on compact, 16:9, 20:9, 4:3 and ultrawide displays")
	print("PASS: v0.6 HUD drag, scale, transparency, reset, persistence, guard, combo, mastery, legacy saves")
	quit(0)
