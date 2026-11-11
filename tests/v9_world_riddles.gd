extends SceneTree
## Additional v9 real-world tests: timeline floor collision, physical gate,
## sonar revealing, interaction, one-time quests and old-save migration.

func _initialize() -> void:
	call_deferred("run_tests")

func check(ok: bool, label: String) -> bool:
	if ok: return true
	push_error("V9 WORLD FAILED: " + label)
	quit(1)
	return false

func run_tests() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if not check(scene != null, "Main scene imported"): return
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.start_new_game()
	if not check(game.v9_art.size() == 3 and game.v9_art.has("echo_labyrinth") and game.v9_art.has("mirror_vault") and game.v9_art.has("ruins"), "All three original v9 panoramic SVG backgrounds imported as textures"): return
	for region_id in ["echo_labyrinth", "mirror_vault", "ruins"]:
		if not check(game.v9_art[region_id].get_width() >= 3000 and game.v9_art[region_id].get_height() >= 700, "Distinct wide illustration retained full artwork dimensions for " + region_id): return
	game.quest_stage = 3
	game.defeated_boss = true
	if not check(game.enter_realm("mirror_vault"), "Mirror Vault is a real reachable dungeon"): return
	game.dialogue = ""
	var riddles = game.world_riddles
	if not check(riddles != null and riddles.in_mirror() and riddles.era == "present", "Timeline begins in present"): return
	if not check(game.REALM_CATALOG.QUESTS.size() == 71, "Three new quests extend the old 68"): return

	var gap_center: float = (riddles.BRIDGE_LEFT + riddles.BRIDGE_RIGHT) * 0.5
	if not check(game.ground_y(gap_center) < 0.0, "Present bridge gap has actual missing floor collision"): return
	game.player_pos = Vector2(gap_center, game.FLOOR_Y)
	game.velocity = Vector2.ZERO
	game.on_ground = true
	game.update_player(0.1)
	if not check(not game.on_ground and game.player_pos.y > game.FLOOR_Y, "Hero falls when crossing broken bridge in present"): return

	game.player_pos = Vector2(riddles.PHASE_PRISMS[0], game.FLOOR_Y)
	game.velocity = Vector2.ZERO
	game.state = "playing"
	if not check(game.nearby_npc() == "phase_shift", "First prism has Android-visible SHIFT interaction"): return
	game.interact()
	if not check(riddles.era == "past" and game.ground_y(gap_center) == game.FLOOR_Y, "SHIFT creates solid traversable bridge collision"): return
	game.player_pos = Vector2(gap_center, game.FLOOR_Y + 20.0)
	game.on_ground = false
	game.update_player(0.1)
	if not check(game.on_ground and is_equal_approx(game.player_pos.y, game.FLOOR_Y), "Hero lands on real past bridge floor"): return

	game.player_pos = Vector2(riddles.BRIDGE_RIGHT + 60.0, game.FLOOR_Y)
	riddles.update_events(0.1)
	if not check(riddles.bridge_crossed, "Physical past-era crossing is recognized"): return
	game.player_pos = Vector2(riddles.MIRROR_WALL + 90.0, game.FLOOR_Y)
	riddles.block_mirror_wall(riddles.MIRROR_WALL - 110.0)
	if not check(game.player_pos.x <= riddles.MIRROR_WALL - 26.0, "Ancient wall physically blocks while in wrong era"): return

	game.player_pos = Vector2(riddles.PHASE_PRISMS[1], game.FLOOR_Y)
	if not check(game.nearby_npc() == "phase_shift", "Second prism accessible after bridge"): return
	game.interact()
	if not check(riddles.era == "present" and riddles.mirror_wall_open(), "Switch to present opens wall only after crossing bridge"): return
	game.player_pos = Vector2(riddles.MIRROR_WALL + 70.0, game.FLOOR_Y)
	riddles.block_mirror_wall(riddles.MIRROR_WALL - 90.0)
	if not check(game.player_pos.x > riddles.MIRROR_WALL, "Open wall physically passable"): return
	var coins_before: int = game.coins
	game.player_pos = Vector2(riddles.MIRROR_RELIC, game.FLOOR_Y)
	riddles.update_events(0.1)
	if not check(riddles.mirror_completed and game.coins > coins_before and game.quest_claimed.has("q70"), "Chrono Relic awards a one-time journal quest"): return

	if not check(game.enter_realm("ruins"), "Existing Sunken Ruins remain accessible"): return
	game.dialogue = ""
	if not check(riddles.in_ruins() and not riddles.sonar_completed and riddles.sonar_collected.is_empty(), "Three sonar glyphs unsolved initially"): return
	game.player_pos = Vector2(riddles.SONAR_GLYPHS[0], game.FLOOR_Y)
	if not check(riddles.near_visible_sigil() == -1, "Hidden sonar glyph cannot be interacted with before pulse"): return
	for index in range(3):
		game.player_pos = Vector2(riddles.SONAR_TOWERS[index], game.FLOOR_Y)
		if not check(game.nearby_npc() == "sonar_pulse", "Sonar tower %d is reachable by mobile interaction" % index): return
		game.interact()
		if not check(riddles.sonar_time > 0.0, "Sonar emits a real timed pulse"): return
		game.player_pos = Vector2(riddles.SONAR_GLYPHS[index], game.FLOOR_Y)
		if not check(riddles.near_visible_sigil() == index and game.nearby_npc() == "sonar_glyph", "Real sonar reveals sigil %d in the world" % index): return
		game.interact()
		if not check(riddles.sonar_collected.has(index), "Sigil %d awards permanent progress" % index): return
	if not check(riddles.sonar_completed and game.quest_claimed.has("q71"), "All three glyphs complete archive quest"): return
	riddles.complete_sonar()
	if not check(riddles.sonar_collected.size() == 3, "Repeated reward claim has no effect"): return
	game.save_game()
	if not check(game.load_game() and riddles.mirror_completed and riddles.sonar_completed and riddles.sonar_collected.size() == 3, "Both riddles persist through save migration"): return
	game.start_new_game()
	if not check(not riddles.mirror_completed and not riddles.sonar_completed and riddles.sonar_collected.is_empty(), "New game resets only new world riddles"): return
	print("PASS: v9 past-present bridge collision, timeline gate, timed sonar glyphs, rewards and save compatibility")
	quit(0)
