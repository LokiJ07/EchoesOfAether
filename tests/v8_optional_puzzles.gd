extends SceneTree
## Optional puzzle regression: old chambers untouched, two new altars playable and saved.
func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, label: String) -> bool:
	if condition: return true
	push_error("V8 BONUS FAILED: " + label)
	quit(1)
	return false

func run_tests() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if not check(scene != null, "Main scene imported"): return
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.start_new_game()
	game.dialogue = ""
	if not check(game.REALM_CATALOG.TRIALS.size() == 8, "Eight prior annexes retained"): return
	if not check(game.bonus_trial_completed.is_empty(), "Fresh save has no bonus flags"): return

	game.world_bosses_cleared = [true, true, true]
	game.ember_boss_defeated = true
	game.dungeon_clears = ["tide_temple", "verdant_vault"]
	if not check(game.enter_realm("gale_spire"), "Reach Gale Spire"): return
	game.dialogue = ""
	game.player_pos = Vector2(float(game.current_realm()["start"]) + 985.0, game.FLOOR_Y)
	game.state = "playing"
	if not check(game.nearby_bonus_pedestal() == "gale_chimes" and game.nearby_npc() == "trial_puzzle", "Chime altar is an interactable object"): return
	var first_coins: int = game.coins
	game.interact()
	if not check(game.state == "v6_puzzle" and game.trial_puzzle["kind"] == "melody", "Chime puzzle opens using mobile modal"): return
	if not check(not game.press_trial_cell(0), "Wrong note resets sequence without advancing"): return
	for note in [2, 0, 3, 1, 2]:
		if game.state == "v6_puzzle":
			game.press_trial_cell(note)
	if not check(game.state == "playing" and game.bonus_trial_completed.has("gale_chimes") and game.coins > first_coins, "Correct melody grants one-time reward"): return
	if not check(game.nearby_bonus_pedestal() == "", "Completed altar cannot be reopened"): return

	if not check(game.enter_realm("tide_temple"), "Reach Tide Temple"): return
	game.dialogue = ""
	game.player_pos = Vector2(float(game.current_realm()["start"]) + 985.0, game.FLOOR_Y)
	game.state = "playing"
	if not check(game.nearby_bonus_pedestal() == "tide_scales", "Counterweight altar is reachable"): return
	game.interact()
	if not check(game.trial_puzzle["kind"] == "scale", "Real counterweight puzzle opens"): return
	game.press_trial_cell(0)
	game.press_trial_cell(1)
	game.press_trial_cell(2)
	game.press_trial_cell(2)
	game.press_trial_cell(3)
	game.press_trial_cell(3)
	if not check(game.state == "playing" and game.bonus_trial_completed.has("tide_scales"), "Both pans require target mass"): return
	game.save_game()
	if not check(game.load_game() and game.bonus_trial_completed.has("gale_chimes") and game.bonus_trial_completed.has("tide_scales"), "Both completion flags survive save/load"): return
	game.start_new_game()
	if not check(game.bonus_trial_completed.is_empty(), "New adventure resets just bonus trial progress"): return
	print("PASS: optional chime and counterweight altars, mobile interaction, one-time rewards and save migration")
	quit(0)
