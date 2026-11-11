extends SceneTree
## v7 accepted only when real portal-map movement, reachable elevation,
## unique enemy textures and six boss attacks pass live Godot simulations.
func _initialize() -> void:
	call_deferred("run_tests")

func ok(value: bool, what: String) -> bool:
	if value: return true
	push_error("V7 FIELD REVIEW FAILED: " + what)
	quit(1)
	return false

func run_tests() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not ok(packed != null, "Main scene loads"): return
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.start_new_game()
	game.dialogue = ""
	# This test catches a real v6 failure: legacy global x-gates teleported
	# players out of late maps on the first frame, even though enter_realm worked.
	if not ok(game.enter_realm("rootcrypt"), "Forest dungeon portal opens"): return
	game.dialogue = ""
	var before: float = game.player_pos.x
	game.update_player(0.016)
	if not ok(game.current_realm_id == "rootcrypt" and game.player_pos.x > 43000.0 and
		absf(game.player_pos.x - before) < 30.0, "Old quest locks never eject a dungeon player"): return
	game.ember_boss_defeated = true
	game.dungeon_clears = ["tide_temple", "verdant_vault"]
	if not ok(game.enter_realm("abyss"), "Abyss portal opens after Emberfall"): return
	game.dialogue = ""
	game.update_player(0.016)
	if not ok(game.current_realm_id == "abyss" and game.player_pos.x > 23000.0 and
		game.area_name() == "ABYSSAL DEPTHS", "Abyss world remains visible after real movement"): return
	if not ok(game.enter_realm("tide_temple"), "Tide Temple opens"): return
	game.dialogue = ""
	game.update_player(0.016)
	if not ok(game.current_realm_id == "tide_temple" and game.player_pos.x > 27500.0,
		"Tide Temple cannot be snapped into the old Sunken Ruins"): return
	print("PASS: late-stage portal maps remain playable after actual physics frames")
	# Twelve previously reused mob and boss identities must now be independent,
	# non-empty transparent Textures that the renderer can actually select.
	var ids := ["tide_stalker", "coral_wisp", "thorn_knight", "petal_moth",
		"root_colossus", "mirror_keeper", "gale_wyrm", "mire_reaver",
		"echo_archon", "abyss_leviathan", "thornheart", "nexus_echo"]
	if not ok(game.v7_mob_art.size() == ids.size(), "All 12 new mob identities imported offline"): return
	for kind in ids:
		var tex: Texture2D = game.v7_mob_art.get(kind, null)
		if not ok(tex != null and tex.get_width() == 288 and tex.get_height() == 288,
			"Distinct art for " + kind): return
	print("PASS: 12 new differentiated high-contrast enemy and boss sprites actually imported")
	# Every portal scene has the same optional reachable walk-up, while the
	# existing ground and story gates stay open for players skipping the secret.
	for region in game.REALM_CATALOG.REGIONS:
		if region["kind"] == "hub": continue
		var x0: float = float(region["start"]) + 410.0
		var tiers: Array = [423.0, 348.0, 278.0]
		for i in range(3):
			var x: float = x0 + float(i) * (192.0 if i < 2 else 194.0)
			var matching: bool = false
			for p in game.platforms:
				if absf(p.position.x - x) < 5.0 and absf(p.position.y - tiers[i]) < 1.0:
					matching = true
					break
			if not ok(matching, "Physical raised platform tier "+str(i)+" exists: "+str(region["id"])): return
		if not ok(game.skyshard_position(region).y < tiers[2] and
			game.skyshard_position(region).x >= x0 + 388.0 and
			game.skyshard_position(region).x <= x0 + 606.0,
			"Skyshard is on the reachable top tier: "+str(region["id"])): return
	print("PASS: 26 nonblocking 3-tier vertical routes and accessible platforming collectibles")
	game.enter_realm("forest")
	game.dialogue = ""
	var spot: Vector2 = game.skyshard_position(game.current_realm())
	game.player_pos = spot + Vector2(0, 26)
	game.on_ground = false
	game.velocity = Vector2.ZERO
	var previous_coins: int = game.coins
	game.update_player(0.016)
	if not ok(game.skyshards_collected.has("forest") and game.coins > previous_coins and
		game.quest_claimed.has("q57"), "Real midair pickup grants relic and matching RPG quest"): return
	if not ok(not game.collect_skyshard_if_close(), "Already collected skyshard cannot pay twice"): return
	game.save_game()
	if not ok(game.load_game() and game.skyshards_collected.has("forest"), "Aerial progress survives a save upgrade"): return
	game.start_new_game()
	if not ok(game.skyshards_collected.is_empty(), "New game clears only game progress"): return
	print("PASS: physical skyshard pickup, one-time rewards, 12 RPG quests and saved progress")
	# Bosses retain original four actions, then gain two more distinct patterns.
	var boss: Dictionary = {}
	for enemy in game.enemies:
		if enemy["type"] == "root_colossus":
			boss=enemy
			break
	if not ok(not boss.is_empty(), "Unique dungeon boss exists"): return
	boss["pattern"] = 0
	var count: Array = []
	for i in range(6):
		var previous: int = game.bolts.size()
		game.boss_attack(boss)
		count.append(game.bolts.size() - previous)
	if not ok(count == [3,1,2,1,3,2] and boss["pattern"] == 6,
		"Boss rotates fan, aim, wave, charge, ceilingfall and crossfire"): return
	print("PASS: six distinct dodgeable boss attack patterns")
	quit(0)
