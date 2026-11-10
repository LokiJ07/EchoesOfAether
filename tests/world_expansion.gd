extends SceneTree
## v0.3 functional regression suite: ultrawide inputs, three new realms and portal persistence.

func _initialize() -> void:
	call_deferred("run_tests")

func check(value: bool, message: String) -> bool:
	if not value:
		push_error("WORLD EXPANSION FAILED: " + message)
		quit(1)
		return false
	return true

func run_tests() -> void:
	var packed = load("res://scenes/Main.tscn")
	if not check(packed != null, "Main game scene exists"): return
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.start_new_game()
	if not check(str(ProjectSettings.get_setting("display/window/stretch/aspect")) == "expand", "Fullscreen expand aspect is enabled"): return
	if not check(game.WORLD_WIDTH >= 15000.0 and game.area_name() == "MOONHAVEN VILLAGE", "Expanded world is loaded"): return
	# Real touch handler: joystick drag must drive faster, reversible movement.
	var joystick: Vector2 = game.hud.joystick_center()
	game.touch_press(joystick + Vector2(81, 0), 61)
	game.update_player(0.1)
	if not check(game.touch_axis > 0.8 and game.velocity.x > 250.0 and game.facing == 1, "Mobile joystick moves faster to right"): return
	game.touch_release(61)
	game.touch_press(joystick - Vector2(81, 0), 62)
	game.update_player(0.16)
	if not check(game.touch_axis < -0.8 and game.velocity.x < 0.0 and game.facing == -1, "Mobile joystick changes to left"): return
	game.touch_release(62)
	if not check(game.touch_axis == 0.0 and game.joystick_touch == -1, "Joystick release stops input"): return
	if not check(game.hud.control_centers()["attack"].x > game.hud.control_centers()["jump"].x, "Responsive attack and jump anchors"): return
	# The original storyline must gate the new chapter until the Warden dies.
	game.player_pos = Vector2(8425, 500)
	game.update_player(0.016)
	if not check(game.player_pos.x <= 8340.0, "Chapter 2 can't be skipped before Warden"): return
	game.player_pos = Vector2(1720, 500)
	game.interact()
	if not check(game.state == "playing" and not game.portal_unlocked[1], "Village portal sealed before Warden"): return
	game.player_pos = Vector2(7780, 500)
	var first_boss: Dictionary = {}
	for e in game.enemies:
		if e["type"] == "boss":
			first_boss = e
			break
	if not check(not first_boss.is_empty(), "Original Star Warden still exists"): return
	game.hit_enemy(first_boss, 9999.0)
	if not check(game.state == "victory" and game.portal_unlocked[1], "Original boss unlocks Crystal Hollow portal"): return
	game.go_expansion_world()
	if not check(game.state == "playing" and game.player_pos.x == 8800.0 and game.checkpoint_x == 8800.0, "Victory menu opens new chapter and saves checkpoint"): return
	# Portals cannot jump into a future region before its guardian is beaten.
	game.player_pos = Vector2(8660, 500)
	game.interact()
	if not check(game.state == "portals" and not game.portal_jump(2), "Future portal remains locked"): return
	if not check(game.portal_jump(0) and game.player_pos.x == 1635.0, "Hub fast travel works"): return
	game.player_pos = Vector2(1720, 500)
	game.interact()
	if not check(game.portal_jump(1) and game.area_name() == "CRYSTAL HOLLOW", "Portal returns player to Crystal Hollow"): return
	if not check(game.active_boss_info().is_empty(), "Boss bar only shows nearby guardians"): return
	# New regions must contain living enemies and three high-health bosses.
	for kind in ["crystal_bug", "crystal_wisp", "sky_wisp", "cloud_moth", "bog_slime", "bog_wisp"]:
		if not check(game.enemies.any(func(e): return e["type"] == kind), "New enemy exists: " + kind): return
	var guardian_types = ["crystal_titan", "sky_herald", "marsh_guardian"]
	var guardian_positions = [10510.0, 12530.0, 15310.0]
	for idx in range(guardian_types.size()):
		game.state = "playing"
		game.player_pos = Vector2(guardian_positions[idx], 500)
		var guardian: Dictionary = {}
		for e in game.enemies:
			if e["type"] == guardian_types[idx]:
				guardian = e
				break
		if not check(not guardian.is_empty() and guardian["hp"] > 200.0, "Guardian boss has real HP"): return
		if not check(game.active_boss_info()["type"] == guardian_types[idx], "Boss UI shows the guardian"): return
		game.hit_enemy(guardian, 10000.0)
		if not check(game.world_bosses_cleared[idx], "Defeating guardian persists stage"): return
		if idx < 2:
			if not check(game.portal_unlocked[idx + 2], "Defeating guardian unlocks next portal"): return
			game.player_pos = Vector2(game.PORTAL_LOCATIONS[idx + 1], 500)
			game.interact()
			if not check(game.state == "portals" and game.portal_jump(idx + 2), "Portal physically travels to next realm"): return
	# An actual environmental hazard damages the hero within Shadowfen.
	game.state = "playing"
	game.hp = game.max_hp
	game.invincible = 0.0
	game.player_pos = Vector2(13615, 500)
	game.update_player(0.016)
	if not check(game.hp < game.max_hp, "Poison pools cause gameplay damage"): return
	if not check(game.expansion_completed and game.unlocked_portal_count() == game.PORTAL_NAMES.size(), "Final guardian restores all realms"): return
	game.save_game()
	if not check(game.load_game() and game.expansion_completed and game.world_bosses_cleared.all(func(x): return x), "New-world bosses and unlocks persist across save/load"): return
	for kind in guardian_types:
		if not check(not game.enemies.any(func(e): return e["type"] == kind and e["hp"] > 0.0), "Defeated world bosses never respawn"): return
	print("PASS: ultrawide fullscreen, responsive mobile movement, portals, three realms, bosses, hazards and save/load")
	quit(0)
