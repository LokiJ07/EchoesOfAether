extends SceneTree
## CI-only functional smoke test. Runs in actual Godot headless, without device.

func _initialize() -> void:
	call_deferred("run_tests")

func require_true(condition: bool, label: String) -> bool:
	if not condition:
		push_error("GAME SMOKE FAILED: " + label)
		quit(1)
		return false
	return true

func run_tests() -> void:
	var scene = load("res://scenes/Main.tscn")
	if not require_true(scene != null, "Main scene must import"): return
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.start_new_game()
	if not require_true(game.state == "playing", "Start game"): return
	if not require_true(game.has_save(), "Save file exists"): return
	game.player_pos = Vector2(415, 500)
	game.interact()
	if not require_true(game.quest_stage == 1, "Mira grants seed quest"): return
	game.dialogue = ""
	game.player_pos = Vector2(2500, 500)
	for i in range(3):
		game.loot.append({"kind": "seed", "pos": game.player_pos - Vector2(0, 23), "t": 0.0, "amount": 1})
	game.update_loot(0.016)
	if not require_true(game.seeds == 3 and game.quest_stage == 2, "Three seeds open gate"): return
	game.player_pos = Vector2(7780, 500)
	var boss: Dictionary = {}
	for e in game.enemies:
		if e["type"] == "boss":
			boss = e
			break
	if not require_true(not boss.is_empty(), "Boss exists"): return
	game.hit_enemy(boss, 500.0)
	if not require_true(game.defeated_boss and game.quest_stage == 3 and game.state == "victory", "Boss defeat triggers ending"): return
	if not require_true(game.load_game() and game.defeated_boss, "Persist victory across save/load"): return
	print("PASS: scene, start, quest, 3 seeds, gate, boss victory, persistent save/load")
	quit(0)
