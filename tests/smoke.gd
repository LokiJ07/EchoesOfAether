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
	# Six physical caches must be interactable only once and persist across saves.
	game.player_pos = Vector2(690, 500)
	if not require_true(game.nearby_npc() == "cache", "Relic cache nearby interaction is exposed"): return
	game.interact()
	if not require_true(game.relic_shards == 1 and game.opened_caches.size() == 1, "First relic cache grants shard"): return
	if not require_true(not game.open_cache(0) and game.relic_shards == 1, "Cannot duplicate a claimed relic"): return
	game.player_pos = Vector2(1940, 500)
	game.interact()
	if not require_true(game.relic_shards == 2, "Second chest grants second shard"): return
	game.player_pos = Vector2(1510, 500)
	game.interact()
	if not require_true(game.state == "trainer", "Taro opens the Rune Trainer"): return
	if not require_true(game.unlock_rune(0) and game.rune_upgrades[0] and game.relic_shards == 0, "Windstep costs two relic shards"): return
	if not require_true(not game.unlock_rune(0), "Rune cannot be purchased twice"): return
	game.state = "playing"
	game.on_ground = true
	game.jump_count = 0
	game.jump()
	game.jump()
	if not require_true(game.jump_count == 2 and game.velocity.y < 0.0, "Unlocked Windstep performs double-jump"): return
	game.jump()
	if not require_true(game.jump_count == 2, "Double-jump cannot become triple-jump"): return
	game.on_ground = true
	game.jump_count = 0
	for chest_x in [3400.0, 4560.0]:
		game.player_pos = Vector2(chest_x, 500)
		game.interact()
	if not require_true(game.relic_shards == 2, "Mid-world caches grant two new relics"): return
	game.player_pos = Vector2(1510, 500)
	game.interact()
	if not require_true(game.unlock_rune(1), "Astral Edge rune unlocks"): return
	game.state = "playing"
	game.skill_timer = 0.0
	game.stamina = 100.0
	game.use_skill()
	if not require_true(game.bolts[-1]["damage"] >= 68.0 and game.bolts[-1]["vel"].length() >= 660.0, "Astral Edge improves active combat"): return
	game.bolts.clear()
	for chest_x in [5350.0, 6780.0]:
		game.player_pos = Vector2(chest_x, 500)
		game.interact()
	game.player_pos = Vector2(1510, 500)
	game.interact()
	if not require_true(game.unlock_rune(2) and game.max_stamina >= 135.0, "Vital Spark permanently expands stamina"): return
	if not require_true(game.relic_shards == 0 and game.opened_caches.size() == 6, "All six caches tracked without duplication"): return
	game.state = "playing"
	# Optional bounty rewards are granted once even if enemies respawn later.
	for enemy in game.enemies:
		if enemy["type"] == "moth" and game.hunted_moths < 3:
			game.hit_enemy(enemy, 500.0)
	if not require_true(game.claimed_hunts.has("moth") and game.hunted_moths >= 3, "Moth hunt rewards earned"): return
	for enemy in game.enemies:
		if enemy["type"] == "sentinel" and game.hunted_sentinels < 2:
			game.hit_enemy(enemy, 500.0)
	if not require_true(game.claimed_hunts.has("sentinel") and game.hunted_sentinels >= 2, "Sentinel hunt rewards earned"): return
	var reward_coin_total: int = game.coins
	game.register_hunt("sentinel")
	if not require_true(game.coins == reward_coin_total, "Bounty cannot be claimed twice"): return
	game.save_game()
	if not require_true(game.load_game() and game.opened_caches.size() == 6 and game.rune_upgrades[0] and game.rune_upgrades[1] and game.rune_upgrades[2] and game.claimed_hunts.size() == 2, "Relic, rune and bounty state persists"): return
	print("PASS: relic caches, Windstep, Astral Edge, Vital Spark, bounty hunts, persistent upgrades")
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
	# A v1 save from the previous APK must still load without missing-key crashes.
	var old_save = {"max_hp": 122.0, "hp": 88.0, "level": 4, "exp": 20, "coins": 70,
		"potions": 2, "sword": 2, "armor": 1, "stamina_max": 104.0,
		"seeds": 2, "quest": 1, "checkpoint": 2030.0, "boss": false,
		"sound": true, "music": true, "save_version": 1}
	var legacy_file = FileAccess.open("user://aether_save.json", FileAccess.WRITE)
	if not require_true(legacy_file != null, "Legacy save writable"): return
	legacy_file.store_string(JSON.stringify(old_save))
	legacy_file.close()
	if not require_true(game.load_game() and game.level == 4 and game.seeds == 2 and game.quest_stage == 1, "v1 save migrates without losing old progression"): return
	if not require_true(game.opened_caches.is_empty() and game.relic_shards == 0 and not game.rune_upgrades[0] and game.claimed_hunts.is_empty(), "v1 save gains clean default relic progression"): return
	print("PASS: legacy save migration with original progress preserved")
	quit(0)
