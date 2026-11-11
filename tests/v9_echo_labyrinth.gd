extends SceneTree
## V9 integrated in-world gameplay test. No mocks of the EchoLabyrinth script:
## use the real Main scene, interaction hitboxes, physics gate and persistent save.

func _initialize() -> void:
	call_deferred("run_tests")

func check(ok: bool, label: String) -> bool:
	if ok:
		return true
	push_error("V9 ECHO FAILED: " + label)
	quit(1)
	return false

func run_tests() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not check(packed != null, "Main scene loads"): return
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.start_new_game()
	game.quest_stage = 3
	if not check(game.enter_realm("echo_labyrinth"), "Echo Labyrinth reachable via existing Ruins portal"): return
	game.dialogue = ""
	var echo = game.echo_chamber
	if not check(echo != null and echo.in_labyrinth() and not echo.completed, "Fresh shadow challenge exists in real portal dungeon"): return
	if not check(game.REALM_CATALOG.QUESTS.size() >= 71, "All 68 legacy quests plus three v9 world quests remain"): return

	# Collision must stop the player even in midair/dash; no invisible bypass.
	game.player_pos = Vector2(echo.GATE_X + 115.0, game.FLOOR_Y - 60.0)
	game.velocity.x = 760.0
	echo.block_player(echo.GATE_X - 115.0)
	if not check(is_equal_approx(game.player_pos.x, echo.GATE_X - 26.0) and game.velocity.x <= 0.0, "Physical gate blocks dash/jump without valid ghost"): return

	# In-world button is the existing custom-position-aware Android INTERACT.
	game.player_pos = Vector2(echo.RECORDER_X, game.FLOOR_Y)
	game.on_ground = true
	game.state = "playing"
	if not check(game.nearby_npc() == "echo_record" and game.nearby_secret_cache() == "", "Recorder is accessible, not masked by legacy caches"): return
	var touch: Vector2 = game.hud.control_centers()["interact"]
	game.touch_press(touch, 91)
	game.touch_release(91)
	if not check(bool(echo.recording.get("recording", false)), "Actual Android INTERACT touch starts a ghost recording"): return
	if not check(echo.status_text().contains("RECORDING"), "Visible HUD gives recording guidance"): return

	# Record a real walk onto the plate, then stand there for the rest of 10s.
	for i in range(100):
		if i < 15:
			game.player_pos = Vector2(lerpf(echo.RECORDER_X, echo.PLATE_X, float(i) / 15.0), game.FLOOR_Y)
		else:
			game.player_pos = Vector2(echo.PLATE_X, game.FLOOR_Y)
		game.on_ground = true
		echo.update_chamber(0.1)
	if not check(not bool(echo.recording.get("recording", false)) and bool(echo.recording.get("playing", false)) and echo.recording["frames"].size() > 80, "Ten-second shadow completed and retains real player positions"): return
	if not check(not echo.gate_open(), "Gate cannot open without ghost replay timing"): return

	game.player_pos = Vector2(echo.GATE_X - 98.0, game.FLOOR_Y)
	for i in range(27):
		echo.update_chamber(0.1)
	if not check(echo.plate_pressed_by_ghost() and echo.gate_open(), "Recorded ghost holds world-space pressure plate and unlocks gate"): return
	game.player_pos = Vector2(echo.GATE_X + 110.0, game.FLOOR_Y)
	echo.block_player(echo.GATE_X - 70.0)
	if not check(game.player_pos.x > echo.GATE_X, "Open gate allows physical passage"): return

	var initial_coins: int = game.coins
	var initial_relics: int = game.relic_shards
	game.player_pos = Vector2(echo.RELIC_X, game.FLOOR_Y)
	echo.update_chamber(0.1)
	if not check(echo.completed and game.coins > initial_coins and game.relic_shards >= initial_relics + 2, "Real collectible pays its one-time reward"): return
	if not check(game.quest_claimed.has("q69"), "New permanent exploration quest auto-completes"): return
	echo.claim_relic()
	if not check(echo.completed and game.relic_shards == initial_relics + 2, "Reward cannot be duplicated"): return
	game.save_game()
	if not check(game.load_game() and game.echo_chamber.completed and game.echo_chamber.gate_open(), "Reload retains completion and restored open gate"): return
	game.state = "playing"
	game.player_pos = Vector2(echo.RECORDER_X, game.FLOOR_Y)
	if not check(not echo.try_start_recording(), "Completed trial never restarts or resets reward"): return
	game.start_new_game()
	if not check(not echo.completed and not bool(echo.recording.get("playing", false)), "Fresh save resets shadow trial without touching old progression systems"): return
	print("PASS: v9 physical ghost recording, real Android input, blocking gate, replay switches, rewards and save migration")
	quit(0)
