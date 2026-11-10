extends SceneTree
## v1.0 Awakening: optional logic shrines, persistent rewards, animations and visuals.
func _initialize() -> void:
	call_deferred("run_tests")

func check(ok: bool, detail: String) -> bool:
	if not ok:
		push_error("V1 TEST FAILED: " + detail)
		quit(1)
		return false
	return true

func run_tests() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if not check(scene != null, "Main scene loads"): return
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.start_new_game()
	# The Android build must package all three actual generated backgrounds;
	# runtime never needs to fetch anything from the internet.
	if not check(game.realm_backdrops.size() == 3, "Three Higgsfield realm backdrops loaded offline"): return
	if not check(game.ECHO_SHRINES.size() == 6 and game.ECHO_PATTERNS.size() == 6, "Six unique puzzles are present"): return
	if not check(game.hero_animation_pose() == "idle", "Hero begins idle"): return
	game.velocity = Vector2(200.0, 0.0)
	if not check(game.hero_animation_pose() == "run", "Running pose responds to actual velocity"): return
	game.velocity = Vector2.ZERO
	game.on_ground = false
	if not check(game.hero_animation_pose() == "jump", "Airborne pose works"): return
	game.on_ground = true
	game.guard_window = 0.55
	if not check(game.hero_animation_pose() == "guard", "Guard pose works"): return
	game.guard_window = 0.0
	game.slash_timer = 0.16
	if not check(game.hero_animation_pose() == "attack", "Attack pose works"): return
	game.slash_timer = 0.0
	game.healing_glow = 0.8
	if not check(game.hero_animation_pose() == "heal", "Healing pose works"): return
	game.healing_glow = 0.0
	# Wrong answers have no HP cost, item cost, or movement/hazard side effects.
	game.player_pos = Vector2(game.ECHO_SHRINES[0], 500)
	var hp_before: float = game.hp
	var coins_before: int = game.coins
	if not check(game.nearby_npc() == "shrine" and game.open_echo_puzzle(0), "Shrine is a real optional interaction"): return
	if not check(game.state == "puzzle" and game.puzzle_index == 0, "Puzzle modal opens"): return
	if not check(not game.choose_echo_rune(2) and game.puzzle_progress == 0, "Wrong answer resets only puzzle order"): return
	if not check(game.hp == hp_before and game.coins == coins_before and game.quest_stage == 0, "Wrong guesses do not punish or block gameplay"): return
	game.leave_echo_puzzle()
	if not check(game.state == "playing" and game.puzzle_index == -1 and game.player_pos.x == game.ECHO_SHRINES[0], "Leave immediately returns to same gameplay position"): return
	if not check(game.open_echo_puzzle(0), "Leaving without solving allows retry"): return
	var puzzle_pattern: Array = game.ECHO_PATTERNS[0]
	for rune_index in puzzle_pattern:
		if not check(game.choose_echo_rune(int(rune_index)), "Correct rune is accepted"): return
	if not check(game.state == "playing" and game.awakened_shrines.has(0), "Solving shrine returns to exploration"): return
	if not check(game.coins == coins_before + 55 and game.max_hp >= 106.0, "Shrine provides real permanent reward"): return
	var after_reward: int = game.coins
	if not check(not game.open_echo_puzzle(0) and game.coins == after_reward, "Cannot exploit shrine for duplicate reward"): return
	game.dialogue = ""
	game.player_pos = Vector2(game.ECHO_SHRINES[1], 500)
	if not check(game.open_echo_puzzle(1), "Other shrine opens independently"): return
	game.leave_echo_puzzle()
	if not check(game.state == "playing" and game.quest_stage == 0, "Side puzzle does not gate main story"): return
	game.save_game()
	if not check(game.load_game() and game.awakened_shrines.has(0) and game.awakened_shrines.size() == 1, "Puzzle rewards persist across save/load"): return
	# Settings are separate from gameplay data, so new game and upgrades preserve preferences.
	game.graphics_quality = 1
	game.cycle_graphics_quality()
	if not check(game.graphics_quality == 2, "Settings cycle visual quality"): return
	game.toggle_reduced_motion()
	if not check(game.reduced_motion, "Reduced motion preference toggles"): return
	game.graphics_quality = 0
	game.save_visual_preferences()
	game.graphics_quality = 2
	game.reduced_motion = false
	game.load_visual_preferences()
	if not check(game.graphics_quality == 0 and game.reduced_motion, "Visual settings persist separately"): return
	game.start_new_game()
	if not check(game.graphics_quality == 0 and game.reduced_motion and game.awakened_shrines.is_empty(), "New game resets shrines but retains settings"): return
	# Validate boss telegraph is visible before an attack instead of spawning instantly.
	game.quest_stage = 2
	game.player_pos = Vector2(7720, 500)
	for e in game.enemies:
		if e["type"] == "boss":
			e["cooldown"] = 0.0
			e["windup"] = 0.0
			break
	game.update_enemies(0.016)
	if not check(game.enemies.any(func(e): return e["type"] == "boss" and e["windup"] > 0.0), "Boss attack has readable windup"): return
	# Compatibility with saved adventure files from v0.6 and older.
	var v06 = {"max_hp": 145.0, "hp": 117.0, "level": 6, "coins": 250,
		"potions": 4, "sword": 3, "armor": 2, "stamina_max": 108.0,
		"seeds": 3, "quest": 2, "checkpoint": 4800.0, "boss": false,
		"portal_unlocked": [true, false, false, false], "world_bosses_cleared": [false, false, false],
		"save_version": 6, "sound": true, "music": true}
	var oldfile := FileAccess.open("user://aether_save.json", FileAccess.WRITE)
	if not check(oldfile != null, "Legacy save file writable"): return
	oldfile.store_string(JSON.stringify(v06))
	oldfile.close()
	if not check(game.load_game() and game.level == 6 and game.coins == 250 and game.quest_stage == 2, "v0.6 journey restored"): return
	if not check(game.awakened_shrines.is_empty() and game.graphics_quality == 0, "Legacy saves get safe shrine defaults without resetting visuals"): return
	print("PASS: v1 offline backgrounds, animated poses, optional puzzles, rewards, exit, save migration, settings and boss telegraphs")
	quit(0)
