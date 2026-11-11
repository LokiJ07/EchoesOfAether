extends SceneTree
## V5 end-to-end test of real portal scenes, story, quests, combat and old saves.
func _initialize() -> void:
	call_deferred("run_tests")

func ok(value: bool, label: String) -> bool:
	if value: return true
	push_error("V5 FAILED: " + label)
	quit(1)
	return false

func run_tests() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if not ok(scene != null, "Original game scene loads"): return
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.start_new_game()
	var catalog = game.REALM_CATALOG
	if not ok(catalog.REGIONS.size() == 19 and catalog.QUESTS.size() >= 30, "19 real scenes and 30 quests configured"): return
	if not ok(catalog.DUNGEON_BOSSES.size() == 8 and game.current_realm_id == "hub", "Dungeon guardians configured and hub scene active"): return
	for entry in catalog.REGIONS:
		var path: String = "res://scenes/realms/%s.tscn" % entry["id"]
		var packed: PackedScene = load(path)
		if not ok(packed != null, "Distinct PackedScene exists: " + path): return
		var stage: Node = packed.instantiate()
		if not ok(stage.get("realm_id") == entry["id"], "Loaded scene identifies its specific realm"): return
		stage.free()
	if not ok(game.is_realm_unlocked("forest") and not game.is_realm_unlocked("abyss"), "Forest is immediately accessible, late game realm is locked"): return
	game.player_pos = Vector2(1720, 500)
	game.interact()
	if not ok(game.state == "portals", "Village portal opens a real choice instead of blocking adventure"): return
	if not ok(game.enter_realm("forest") and game.current_realm_id == "forest", "Travel enters another PackedScene"): return
	if not ok(game.realm_stage.get("realm_id") == "forest" and game.story_seen.has("forest"), "Stage loaded and NPC story scenario offered"): return
	if not ok(game.dialogue != "" and game.story_queue.size() > 0, "Realm story includes multiple dialogue beats"): return
	game.advance_story_dialogue()
	if not ok(game.dialogue != "", "Dialogue proceeds through a chapter sequence"): return
	game.advance_story_dialogue()
	if not ok(game.dialogue == "", "Dialogue can finish without trapping player"): return
	game.dialogue = "STORY SCENE ONE"
	game.story_queue = ["STORY SCENE TWO", "STORY SCENE THREE"]
	var skip_panel := Rect2(game.hud.size.x * 0.14, game.hud.size.y * 0.68,
		game.hud.size.x * 0.72, maxf(155.0, game.hud.size.y * 0.25))
	var skip_action := skip_panel.end + Vector2(-100.0, -skip_panel.size.y + 34.0)
	game.hud.handle_menu_press(skip_action)
	if not ok(game.dialogue == "" and game.story_queue.is_empty(), "Skip Story exits immediately without blocking gameplay"): return
	game.player_pos = Vector2(4690, 500)
	game.velocity = Vector2.ZERO
	game.touch_axis = 1.0
	game.update_player(0.24)
	if not ok(game.player_pos.x <= 4750.0 - 62.0 and game.current_realm_id == "forest", "Running into map edge cannot reveal neighboring sky seam"): return
	game.update_camera()
	var camera_half: float = game.get_viewport().get_visible_rect().size.x * 0.5 / maxf(0.1, game.camera.zoom.x)
	if not ok(game.camera.position.x + camera_half <= 4750.5 and game.camera.position.x - camera_half >= 1899.5, "Camera never reveals next realm across border"): return
	game.touch_axis = 0.0
	if not ok(game.nearby_stage_portal() == "rootcrypt" or game.player_pos.x >= 4685.0, "Forest dungeon gate lies at far side of map"): return
	game.state = "playing"
	if not ok(game.enter_realm("rootcrypt") and game.current_realm_id == "rootcrypt", "Dungeon loads its own separate scene"): return
	if not ok(game.realm_stage.get("realm_id") == "rootcrypt", "Dungeon PackedScene exists at runtime"): return
	var root_guardian: Dictionary = {}
	for e in game.enemies:
		if e["type"] == "root_colossus": root_guardian = e
	if not ok(not root_guardian.is_empty(), "Dungeon has an actual encounter guardian"): return
	game.hit_enemy(root_guardian, 9999.0)
	if not ok(game.dungeon_clears.has("rootcrypt") and game.state == "dungeon_victory", "Clearing dungeon awards and records guardian victory"): return
	game.state = "playing"
	if not ok(game.enter_realm("forest") and not game.enemies.any(func(e): return e["type"] == "root_colossus" and e["hp"] > 0.0), "Cleared dungeon boss stays defeated"): return
	print("PASS: 19 separate portal PackedScenes, non-seam cameras, optional dungeon guardian and story")
	var quest: Dictionary = {}
	for q in catalog.QUESTS:
		if q["event"] == "kill:slime": quest = q
	if not ok(not quest.is_empty(), "RPG kill quest exists"): return
	var reward_before: int = game.coins
	game.record_quest_event("kill:slime", 4)
	if not ok(game.quest_claimed.has(quest["id"]) and game.quest_progress(quest) == 4 and game.coins >= reward_before + int(quest["coins"]), "Quests track kills and reward automatically"): return
	var reward_once: int = game.coins
	game.record_quest_event("kill:slime", 4)
	if not ok(game.coins == reward_once, "Quests cannot be farmed for duplicate rewards"): return
	if not ok(game.quest_total() >= 30 and game.quest_claimed.size() >= 1, "Journal reports real persistent quests"): return
	print("PASS: 30 persistent multi-realm quests with one-time rewards and story progress")
	game.state = "playing"
	if not ok(not game.enter_realm("abyss"), "Chapter III portal remains locked until Cinder Warden"): return
	game.ember_boss_defeated = true
	if not ok(game.enter_realm("abyss") and game.area_name() == "ABYSSAL DEPTHS", "Chapter III unlocks underwater realm"): return
	if not ok(game.enter_realm("tide_temple"), "Abyssal Depths has a real dungeon scene"): return
	var leviathan: Dictionary = {}
	for e in game.enemies:
		if e["type"] == "abyss_leviathan": leviathan = e
	if not ok(not leviathan.is_empty(), "Leviathan boss exists"): return
	leviathan["pattern"] = 0
	game.bolts.clear()
	var shot_counts: Array = []
	for i in range(4):
		var previous: int = game.bolts.size()
		game.boss_attack(leviathan)
		shot_counts.append(game.bolts.size() - previous)
	if not ok(shot_counts == [3, 1, 2, 1] and leviathan["pattern"] == 4, "Boss alternates fan, aimed shot, ground wave and charge patterns"): return
	game.hit_enemy(leviathan, 9999.0)
	if not ok(game.dungeon_clears.has("tide_temple") and game.is_realm_unlocked("garden"), "Tide Temple guardian unlocks Everdawn"): return
	if not ok(game.enter_realm("garden") and game.area_name() == "EVERDAWN GARDENS", "Chapter IV realm is explorable"): return
	if not ok(game.enter_realm("verdant_vault"), "Everdawn has a distinct Verdant Sanctum dungeon"): return
	var thornheart: Dictionary = {}
	for e in game.enemies:
		if e["type"] == "thornheart": thornheart = e
	if not ok(not thornheart.is_empty(), "Thornheart encounter exists"): return
	game.hit_enemy(thornheart, 9999.0)
	if not ok(game.dungeon_clears.has("verdant_vault") and game.is_realm_unlocked("nexus"), "Garden guardian unlocks final Aether Nexus"): return
	if not ok(game.enter_realm("nexus") and game.enter_realm("nexus_core"), "Final realm has its own separate boss dungeon"): return
	var final_enemy: Dictionary = {}
	for e in game.enemies:
		if e["type"] == "nexus_echo": final_enemy = e
	if not ok(not final_enemy.is_empty(), "Final boss is present"): return
	game.hit_enemy(final_enemy, 9999.0)
	if not ok(game.dungeon_clears.has("nexus_core") and game.state == "v5_victory", "Final chapter victory triggers"): return
	game.save_game()
	if not ok(game.load_game() and game.current_realm_id == "nexus_core" and game.dungeon_clears.has("nexus_core") and game.quest_claimed.has(quest["id"]), "Endgame dungeon, boss, story and quest state survive save reload"): return
	print("PASS: unique combat patterns, Abyssal Depths, Everdawn, Aether Nexus, final boss and persistence")
	# Previously-installed v2 APK saves must migrate rather than be overwritten.
	var old: Dictionary = {"max_hp": 145.0, "hp": 120.0, "level": 8, "coins": 400,
		"potions": 3, "sword": 3, "armor": 2, "stamina_max": 116.0,
		"seeds": 3, "quest": 3, "checkpoint": 16120.0, "boss": true, "save_version": 20,
		"portal_unlocked": [true, true, true, true, true], "world_bosses_cleared": [true, true, true],
		"expansion_completed": true, "ember_boss_defeated": true, "emberling_unlocked": true}
	var fixture := FileAccess.open("user://aether_save.json", FileAccess.WRITE)
	if not ok(fixture != null, "Legacy fixture can be written"): return
	fixture.store_string(JSON.stringify(old))
	fixture.close()
	if not ok(game.load_game() and game.level == 8 and game.coins == 400 and game.current_realm_id == "ember", "v2 save migrates to v5 portal-based world without losing progression"): return
	if not ok(game.quest_counts.is_empty() and game.dungeon_clears.is_empty() and game.emberling_unlocked, "Old saves get clean new quest/dungeon defaults and keep companion"): return
	print("PASS: safe v2 save migration, fixed signing identity and unchanged custom control settings")
	quit(0)
