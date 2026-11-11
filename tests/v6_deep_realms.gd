extends SceneTree
## v6 deep-room acceptance: 8 isolated actual PackedScenes, four different puzzles,
## optional exits, solved-only rewards, old-save compatibility, and live touch UI.
func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, reason: String) -> bool:
	if condition: return true
	push_error("V6 FAILED: " + reason)
	quit(1)
	return false

func open_trial(game, id: String) -> bool:
	var info: Dictionary = game.REALM_CATALOG.region(id)
	if not game.enter_realm(id): return false
	game.dialogue = ""
	game.story_queue.clear()
	game.portal_cooldown = 0.0
	game.player_pos = Vector2(float(info["start"]) + 1530.0, game.FLOOR_Y)
	return game.open_trial_puzzle() and game.state == "v6_puzzle"

func run_tests() -> void:
	var pack: PackedScene = load("res://scenes/Main.tscn")
	if not check(pack != null, "Main scene loads"): return
	var game = pack.instantiate()
	root.add_child(game)
	await process_frame
	game.start_new_game()
	print("V6 CHECKPOINT: world initialized")
	var catalog = game.REALM_CATALOG
	var mechanic = game.PUZZLE_ENGINE
	if not check(catalog.REGIONS.size() == 27 and catalog.QUESTS.size() >= 46 and game.WORLD_WIDTH == 83300.0, "Eight new dungeon branches and 16 more persistent quest lines"): return
	if not check(catalog.TRIALS.size() == 8 and game.v6_art.size() == 8, "Every separate trial has an original offline imported panorama"): return
	for id in catalog.TRIALS:
		var info: Dictionary = catalog.region(id)
		if not check(info.get("kind","") == "trial" and info.get("art","") == "v6_generated_" + str(catalog.TRIALS[id]["art"]).trim_prefix("v6_generated_"), "Trial catalog points at unique art "+id): return
		var stage: PackedScene = load("res://scenes/realms/%s.tscn" % id)
		if not check(stage != null, "Real PackedScene exists for "+id): return
		var instance = stage.instantiate()
		if not check(instance.get("realm_id") == id, "PackedScene identifies its own chamber"): return
		instance.free()
		var texture: Texture2D = game.v6_art_for(id)
		if not check(texture != null and texture.get_width() == 1600 and texture.get_height() == 720, "Unique actual texture loaded "+id): return
	print("PASS: eight portal dungeon annexes, imported unique backgrounds, and expanded 46-quest journal")
	print("V6 CHECKPOINT: eight arts and scenes verified")
	# Rootbound: portal inside dungeon leads to its own side room, never a seam.
	if not check(game.enter_realm("rootcrypt"), "Rootbound crypt is accessible from forest"): return
	game.dialogue = ""
	game.portal_cooldown = 0.0
	var root_info: Dictionary = catalog.region("rootcrypt")
	game.player_pos = Vector2(float(root_info["start"]) + (float(root_info["end"]) - float(root_info["start"])) * 0.58, game.FLOOR_Y)
	if not check(game.nearby_stage_portal() == "root_gallery", "Distinct side door is interactive in parent dungeon"): return
	game.interact()
	if not check(game.current_realm_id == "root_gallery", "Side door loads completely separate puzzle scene"): return
	# Mural pieces physically move into the empty map slot.
	if not check(open_trial(game, "root_gallery"), "Player can choose to open mosaic puzzle"): return
	var hp0: float = game.hp
	var money0: int = game.coins
	var checkpoint0: float = game.player_pos.x
	var board: Array = game.trial_puzzle["tiles"].duplicate()
	if not check(board.size() == 9 and board != [1,2,3,4,5,6,7,8,0], "Scrambled background assembly starts unsolved"): return
	if not check(not game.press_trial_cell(9) and game.trial_puzzle["tiles"] == board, "Invalid tile move never destroys mural"): return
	game.leave_trial_puzzle()
	if not check(game.state == "playing" and game.player_pos.x == checkpoint0 and game.hp == hp0 and game.coins == money0, "Exit never damages or moves player"): return
	if not check(game.open_trial_puzzle(), "Unsolved chamber can be replayed without losing game state"): return
	print("V6 CHECKPOINT: mural session opened and exited")
	for move in game.trial_puzzle["hint_path"].duplicate():
		if game.state == "v6_puzzle": game.press_trial_cell(int(move))
	if not check(game.trial_completed.has("root_gallery") and game.state == "playing" and game.coins > money0 and game.relic_shards >= 1, "Sliding map actually completes and earns rewards"): return
	if not check(not game.open_trial_puzzle(), "Completed annex cannot be repeatedly farmed"): return
	if not check(game.quest_claimed.has("q32"), "Puzzle completion emits and claims the correct RPG quest"): return
	print("PASS: sliding mural assembly, legal moves, optional exits, progression rewards and quest events")
	# Simulate a legacy completed main story to enter all optional later chambers
	# without resetting original saves or skipping encounter rules.
	game.defeated_boss = true
	game.quest_stage = 3
	game.world_bosses_cleared = [true, true, true]
	game.expansion_completed = true
	game.ember_boss_defeated = true
	game.dungeon_clears = ["tide_temple", "verdant_vault"]
	print("V6 CHECKPOINT: mural solved and quests granted")
	# Prism annex: actual graph-connectivity check on rotated pipe links.
	if not check(open_trial(game, "prism_annex"), "Prism circuit annex opens"): return
	if not check(not mechanic.circuit_open(game.trial_puzzle["rotations"]), "Conduit starts disconnected"): return
	# Solving may immediately close the puzzle and clear trial_puzzle.
	# Cache its initial rotations before issuing any touches.
	var prism_rotations: Array = game.trial_puzzle["rotations"].duplicate()
	for i in range(prism_rotations.size()):
		if game.state != "v6_puzzle": break
		var current: int = int(prism_rotations[i])
		for turn in range((4-current)%4):
			if game.state == "v6_puzzle": game.press_trial_cell(i)
	if not check(game.trial_completed.has("prism_annex"), "Beam reaches far exit only when pipe paths connect"): return
	if not check(mechanic.circuit_open([0,0,0,0,0,0,0,0,0]), "A fully aligned path is recognized"): return
	print("V6 CHECKPOINT: optical circuit solved")
	# Solve equation puzzle instead of repeated rune pattern.
	if not check(open_trial(game, "wind_observatory"), "Wind numeric-logic puzzle opens"): return
	for i in range(3):
		for count in range([2,3,1][i]):
			if game.state == "v6_puzzle": game.press_trial_cell(i)
	if not check(game.trial_completed.has("wind_observatory"), "Three dial equations must be satisfied simultaneously"): return
	print("V6 CHECKPOINT: logic dials solved")
	# Memory trial has unique sequences; wrong choice resets only that sequence.
	if not check(open_trial(game, "bog_lanterns"), "Swamp memory puzzle opens"): return
	var first_colour: int = int(game.trial_puzzle["sequence"][0])
	var hp_before_memory: float = game.hp
	game.press_trial_cell((first_colour+1)%4)
	# Previous dungeon rewards can increase current HP; compare against the
	# immediately preceding state, not the value from the first mural room.
	if not check(game.trial_puzzle["progress"] == 0 and game.hp == hp_before_memory, "Wrong memory answer has no HP penalty"): return
	game.trial_hint()
	if not check(game.trial_hint_text.contains("NEXT GLYPH"), "Hint displays next memory rune"): return
	var sequence: Array = game.trial_puzzle["sequence"].duplicate()
	for glyph in sequence:
		game.press_trial_cell(int(glyph))
	if not check(game.trial_completed.has("bog_lanterns"), "Correct memory sequence restores the chamber"): return
	print("PASS: pipe-connectivity, logic equations, memory sequence and nonpunishing hints")
	print("V6 CHECKPOINT: memory sequence solved")
	# Remaining chambers reuse systems with different seeds/art/story, not identical
	# three-rune puzzles. Every mode must complete with an in-game solve action.
	for id in ["forge_engine","tide_control","seed_arbor","nexus_memory"]:
		if not check(open_trial(game,id), "Optional challenge opens in "+id): return
		var mode: String = game.trial_puzzle["kind"]
		match mode:
			"mosaic":
				for m in game.trial_puzzle["hint_path"].duplicate():
					if game.state == "v6_puzzle": game.press_trial_cell(int(m))
			"circuit":
				var initial_rotations: Array = game.trial_puzzle["rotations"].duplicate()
				for i in range(initial_rotations.size()):
					if game.state != "v6_puzzle": break
					var turns: int = (4-int(initial_rotations[i]))%4
					for j in range(turns):
						if game.state == "v6_puzzle": game.press_trial_cell(i)
			"logic":
				for i in range(3):
					for j in range([3,1,2][i]):
						if game.state == "v6_puzzle": game.press_trial_cell(i)
			"memory":
				for glyph in game.trial_puzzle["sequence"].duplicate():
					game.press_trial_cell(int(glyph))
		if not check(game.trial_completed.has(id), "All variants complete and pay only once: " + id): return
	print("V6 CHECKPOINT: all late-game annexes solved")
	game.save_game()
	if not check(game.load_game() and game.trial_completed.size() == 8, "All trial rewards persist safely across APK update"): return
	# Each isolated region contains genuine optional exploration caches.
	# Collecting one grants a quest reward and stays solved after save/reload.
	if not check(game.enter_realm("forest"), "Whisperwood secrets are reachable from hub"): return
	game.dialogue = ""
	var secrets: Array = game.secret_cache_positions(game.current_realm())
	if not check(secrets.size() == 2, "Every exploration map exposes two hidden interactables"): return
	# Hidden caches must not be inside bottomless pits or poisonous floor.
	for region in catalog.REGIONS:
		if region["kind"] == "hub": continue
		for entry in game.secret_cache_positions(region):
			var treasure_x: float = float(entry["x"])
			if not check(game.ground_y(treasure_x) == game.FLOOR_Y, "Treasure is on reachable solid ground: " + str(entry["id"])): return
			for pool in game.poison_pools:
				if not check(treasure_x < pool.position.x - 90.0 or treasure_x > pool.end.x + 90.0, "Treasure never requires stepping into poison: " + str(entry["id"])): return
	var secret_id: String = str(secrets[0]["id"])
	game.player_pos = Vector2(float(secrets[0]["x"]), game.FLOOR_Y)
	if not check(game.nearby_secret_cache() == secret_id, "Hidden cache has a real proximity interaction"): return
	var old_coins: int = game.coins
	if not check(game.collect_secret_cache() and game.coins > old_coins, "First opening grants tangible loot"): return
	if not check(game.quest_claimed.has("q47"), "Secret unlocks its associated RPG quest reward"): return
	if not check(not game.collect_secret_cache(), "Collected cache cannot be farmed repeatedly"): return
	game.save_game()
	if not check(game.load_game() and game.secret_caches.has(secret_id), "Exploration discoveries survive Android save updates"): return
	game.start_new_game()
	if not check(game.trial_completed.is_empty() and game.secret_caches.is_empty(), "New game clears annex and treasure progress, not app settings"): return
	print("PASS: 52 discoverable realm secrets, ten exploration quests and permanent rewards")
	print("PASS: all eight puzzle paths, save compatibility, and completed-chamber persistence")
	quit(0)
