extends SceneTree
## v2 Emberfall milestone: real Godot gameplay, mobile touch, old saves, puzzle exits,
## companion rescue, unique asset loading, chapter unlock and Cinder Warden encounter.
func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, reason: String) -> bool:
	if not condition:
		push_error("V2 TEST FAILED: " + reason)
		quit(1)
		return false
	return true

func run_tests() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if not check(scene != null, "Godot Main scene loads"): return
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.start_new_game()
	var hud = game.hud
	if not check(game.WORLD_WIDTH >= 23000.0 and game.EMBER_START > 15000.0 and game.CINDER_VAULT_START > game.EMBER_START, "New world and dungeon exist"): return
	if not check(game.ember_art.size() >= 20 and game.ember_art.has("citadel") and game.ember_art.has("dungeon"), "Higgsfield assets are imported, offline and load as textures"): return
	for name in ["slime", "moth", "beetle", "sentinel", "wisp", "crystal_bug", "sky_wisp",
		"cloud_moth", "bog_slime", "bog_wisp", "fire_imp", "ash_knight", "ember_wisp",
		"boss", "crystal_titan", "sky_herald", "marsh_guardian", "cinder_warden", "emberling"]:
		if not check(game.ember_art.has(name), "Unique enemy, guardian or pet sprite exists: " + name): return
	if not check(game.enemies.any(func(e): return e["type"] == "fire_imp") and
		game.enemies.any(func(e): return e["type"] == "ash_knight") and
		game.enemies.any(func(e): return e["type"] == "cinder_warden"), "New enemies and giant boss are actual spawned actors"): return
	print("PASS: v2 original Higgsfield art, 19 unique sprites, dungeon and new mobs")
	# Reproduce the bug: touching the joystick itself previously got swallowed by
	# an invalid joystick-as-action entry and the hero did not move.
	var stick: Vector2 = hud.joystick_center()
	game.touch_press(stick + Vector2(70, 0), 71)
	if not check(game.joystick_touch == 71 and game.touch_axis > 0.5 and game.mobile_action_at(stick) == "", "Actual joystick press cannot be swallowed by action buttons"): return
	game.touch_release(71)
	if not check(game.joystick_touch == -1 and game.touch_axis == 0, "Joystick releases without stuck movement"): return
	# Move real controls to totally different screen positions.
	hud.set_control_position("joystick", Vector2(460, 472))
	hud.set_control_position("attack", Vector2(685, 340))
	hud.set_control_position("jump", Vector2(550, 540))
	var moved_stick: Vector2 = hud.joystick_center()
	game.touch_press(moved_stick + Vector2(-70, 0), 72)
	if not check(game.joystick_touch == 72 and game.touch_axis < -0.5, "Joystick works after moving to center of screen"): return
	game.touch_release(72)
	var moved_attack: Vector2 = hud.control_centers()["attack"]
	game.attack_timer = 0
	game.touch_press(moved_attack, 73)
	if not check(game.attack_timer > 0 and game.attack_touch.has(73), "Moved attack hitbox follows the visual button"): return
	game.touch_release(73)
	if not check(not game.hold_attack, "Moved attack releases correctly"): return
	# Also exercise Android viewport event conversion, not only direct touch_press.
	var event = InputEventScreenTouch.new()
	event.index = 79
	event.pressed = true
	event.position = hud.get_global_transform_with_canvas() * (moved_stick + Vector2(75, 0))
	game._input(event)
	if not check(game.joystick_touch == 79 and game.touch_axis > 0.5, "Screen-to-HUD coordinate mapping follows repositioned stick"): return
	event.pressed = false
	game._input(event)
	hud.save_control_layout()
	hud.custom_positions.clear()
	hud.load_control_layout()
	if not check(hud.joystick_center().distance_to(moved_stick) < 2, "Custom HUD remains in position after save and reload"): return
	hud.reset_control_layout()
	print("PASS: relocated mobile joystick, action buttons, touch transforms and persistence")
	# Preserve v1 progress while extending the old 4-portal save to the 5th realm.
	var old_save: Dictionary = {"max_hp": 145.0, "hp": 140.0, "level": 6,
		"coins": 370, "potions": 3, "sword": 3, "armor": 2, "stamina_max": 115.0,
		"seeds": 3, "quest": 3, "checkpoint": 13400.0, "boss": true,
		"sound": true, "music": true, "save_version": 10,
		"portal_unlocked": [true, true, true, true],
		"world_bosses_cleared": [true, true, true],
		"expansion_completed": true, "awakened_shrines": [0, 1]}
	var file = FileAccess.open("user://aether_save.json", FileAccess.WRITE)
	if not check(file != null, "Can write legacy save fixture"): return
	file.store_string(JSON.stringify(old_save))
	file.close()
	if not check(game.load_game() and game.level == 6 and game.coins == 370 and game.awakened_shrines.size() == 2, "Old character, coins and puzzles survive upgrade"): return
	if not check(game.portal_unlocked.size() == 5 and game.portal_unlocked[4], "Old 4-portal save gains new Emberfall portal"): return
	game.state = "portals"
	if not check(game.portal_jump(4) and game.player_pos.x == game.PORTAL_ARRIVALS[4] and game.area_name() == "EMBERFALL CITADEL", "New portal travels safely to Emberfall"): return
	if not check(game.nearby_portal_index() == -1 or game.portal_cooldown > 0, "Portal arrival is safe from accidental repeat teleportation"): return
	print("PASS: old v1 saves upgrade to Emberfall and install-over progress survives")
	# Optional mini logic tests pause the game but never trap the player.
	game.player_pos = Vector2(game.EMBER_BRAZIERS[0], 500)
	var before_coin: int = game.coins
	var before_hp: float = game.hp
	if not check(game.open_ember_brazier(0) and game.state == "ember_puzzle", "Real brazier interactable opens a mini puzzle"): return
	if not check(not game.select_ember_rune(1) and game.ember_puzzle_progress == 0, "Wrong rune safely resets only the clue sequence"): return
	if not check(game.coins == before_coin and game.hp == before_hp, "Wrong answers have zero HP/coin penalty"): return
	game.leave_ember_puzzle()
	if not check(game.state == "playing" and game.player_pos.x == game.EMBER_BRAZIERS[0], "Leave anytime returns to same playable location"): return
	if not check(game.open_ember_brazier(0), "Can retry puzzle after leaving"): return
	for rune in game.EMBER_RUNE_PATTERNS[0]:
		if not check(game.select_ember_rune(int(rune)), "Correct rune accepted"): return
	if not check(game.ember_braziers.has(0) and game.coins == before_coin + 100 and game.state == "playing", "Brazier grants one-time reward and returns to game"): return
	if not check(not game.open_ember_brazier(0), "Solved puzzle cannot be farmed for rewards"): return
	# Companion is a physical actor with real ranged/melee assistance.
	game.player_pos = Vector2(16870, 500)
	if not check(game.rescue_emberling() and game.emberling_unlocked, "Rescue companion through actual game interaction"): return
	game.emberling_attack_cooldown = 0
	game.update_emberling(0.2)
	if not check(game.emberling_attacks >= 1 and game.emberling_pos.distance_to(game.player_pos) < 190, "Emberling follows and attacks nearby enemies"): return
	game.toggle_emberling()
	if not check(not game.emberling_active, "Companion can be rested without blocking movement"): return
	game.toggle_emberling()
	# Optional hunts encourage exploring and fighting identifiable species.
	for i in range(3):
		game.register_ember_hunt("fire_imp")
	if not check(game.ember_hunt_claimed.has("fire_imp") and game.ember_hunt_counts["fire_imp"] == 3, "Fire imp bounty pays once"): return
	var bounty_coins: int = game.coins
	game.register_ember_hunt("fire_imp")
	if not check(game.coins == bounty_coins, "Cannot duplicate enemy hunt reward"): return
	game.save_game()
	if not check(game.load_game() and game.emberling_unlocked and game.ember_braziers.has(0) and game.ember_hunt_claimed.has("fire_imp"), "Companion, puzzles and hunts are stored"): return
	print("PASS: optional fire puzzles, one-time rewards, emberling companion and hunt persistence")
	# Guardian has telegraphed multiple phases and can permanently be defeated.
	game.state = "playing"
	game.player_pos = Vector2(22220, 500)
	var boss: Dictionary = {}
	for e in game.enemies:
		if e["type"] == "cinder_warden":
			boss = e
			break
	if not check(not boss.is_empty() and boss["max_hp"] >= 800, "Cinder Warden spawns with meaningful health"): return
	boss["hp"] = boss["max_hp"] * 0.42
	boss["windup"] = 0
	boss["cooldown"] = 0
	game.update_enemies(0.02)
	if not check(boss["phase"] == 2 and boss["windup"] > 0, "Low HP triggers second phase and telegraphed attack"): return
	game.update_enemies(0.57)
	if not check(game.bolts.any(func(b): return b["kind"] == "cinder"), "Cinder Warden fires distinct dodgeable fire projectiles"): return
	game.hit_enemy(boss, 9999)
	if not check(game.ember_boss_defeated and game.state == "ember_victory", "Boss victory triggers genuine new chapter completion"): return
	if not check(game.load_game() and game.ember_boss_defeated, "Cinder Warden defeat saves permanently"): return
	if not check(not game.enemies.any(func(e): return e["type"] == "cinder_warden" and e["hp"] > 0), "Cinder Warden does not respawn after completion"): return
	print("PASS: chapter victory, multi-phase Cinder Warden and saved boss clear")
	quit(0)
