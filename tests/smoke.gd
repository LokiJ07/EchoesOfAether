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
	# Reproduce real mobile movement: left and right must change the displayed sprite orientation.
	game.touch_axis = -1.0
	game.update_player(0.05)
	if not require_true(game.facing == -1 and game.hero_sprite_scale().x == -1.0, "Hero faces left with joystick"): return
	game.touch_axis = 1.0
	game.update_player(0.05)
	if not require_true(game.facing == 1 and game.hero_sprite_scale().x == 1.0, "Hero faces right with joystick"): return
	game.touch_axis = 0.0
	if not require_true(game.hud.skill_status_text() == "READY", "Skill ready HUD"): return
	game.use_skill()
	if not require_true(game.skill_timer > 0.0 and game.hud.skill_status_text().ends_with("s"), "Skill countdown appears"): return
	game.skill_timer = 0.0
	game.stamina = 0.0
	if not require_true(game.hud.skill_status_text() == "LOW SP", "Skill displays insufficient stamina"): return
	game.stamina = game.max_stamina
	game.bolts.clear()
	# Defeat a real slime BEFORE taking the quest: its seed must remain obtainable.
	var slimes: Array = []
	for enemy in game.enemies:
		if enemy["type"] == "slime":
			slimes.append(enemy)
	if not require_true(slimes.size() >= 3, "At least three seed-bearing slimes exist"): return
	game.player_pos = Vector2(slimes[0]["x"], 500)
	game.hit_enemy(slimes[0], 500.0)
	if not require_true(game.loot.any(func(item): return item["kind"] == "seed"), "Slime drops seed before quest"): return
	game.update_loot(0.016)
	if not require_true(game.seeds == 1 and game.quest_stage == 0, "Early seed auto-pickup"): return
	game.player_pos = Vector2(415, 500)
	game.interact()
	if not require_true(game.quest_stage == 1 and game.seeds == 1, "Mira respects early collected seed"): return
	game.dialogue = ""
	for i in range(1, 3):
		game.player_pos = Vector2(slimes[i]["x"], 500)
		game.hit_enemy(slimes[i], 500.0)
		game.update_loot(0.016)
	if not require_true(game.seeds == 3 and game.quest_stage == 2, "Three real slime drops unlock the gate"): return
	print("PASS: early seed drops, pickups, facing and cooldown HUD")
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
