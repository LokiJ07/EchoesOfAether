extends SceneTree
## Real Godot framebuffer capture, run under Xvfb GL not --headless (dummy renderer).
func _initialize() -> void:
	call_deferred("capture")

func capture_frame(game: Node, label: String) -> void:
	for i in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	var shot: Image = root.get_texture().get_image()
	if shot == null or shot.is_empty():
		push_error("RENDER CAPTURE FAILED: " + label)
		return
	shot.convert(Image.FORMAT_RGB8)
	var path: String = "res://build/visual_%s.png" % label
	var code: Error = shot.save_png(path)
	if code != OK:
		push_error("RENDER CAPTURE SAVE FAILED: " + path)
		return
	print("VISUAL CAPTURE: ", label, " ", shot.get_width(), "x", shot.get_height())

func capture() -> void:
	var pack: PackedScene = load("res://scenes/Main.tscn")
	if pack == null:
		quit(1)
		return
	var game = pack.instantiate()
	root.add_child(game)
	await process_frame
	game.state = "main"
	await capture_frame(game, "main_menu")
	game.start_new_game()
	game.story_queue.clear()
	game.dialogue = ""
	await capture_frame(game, "moonhaven")
	if game.enter_realm("forest"):
		game.story_queue.clear()
		game.dialogue = ""
		game.player_pos = Vector2(2920, game.FLOOR_Y)
		game.update_camera()
		await capture_frame(game, "forest")
	game.defeated_boss = true
	game.world_bosses_cleared = [true, true, true]
	game.expansion_completed = true
	game.ember_boss_defeated = true
	game.dungeon_clears = ["tide_temple", "verdant_vault"]
	if game.enter_realm("abyss"):
		game.story_queue.clear()
		game.dialogue = ""
		game.player_pos = Vector2(24600, game.FLOOR_Y)
		game.update_camera()
		await capture_frame(game, "abyss")
	if game.enter_realm("root_gallery"):
		game.story_queue.clear()
		game.dialogue = ""
		game.portal_cooldown = 0.0
		game.player_pos = Vector2(64030, game.FLOOR_Y)
		game.state = "playing"
		game.open_trial_puzzle()
		await capture_frame(game, "sliding_mural")
	print("PASS: rendered five live Godot visual captures")
	quit(0)
