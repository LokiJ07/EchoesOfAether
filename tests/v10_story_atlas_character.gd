extends SceneTree
## V10 visual+functional regression, using the real Main scene and in-engine HUD.

func _initialize() -> void:
	call_deferred("run_tests")

func check(value: bool, label: String) -> bool:
	if value: return true
	push_error("V10 ATLAS FAILED: " + label)
	quit(1)
	return false

func contains_key(buttons: Array, key: String) -> bool:
	for b in buttons:
		if str(b.get("key", "")) == key:
			return true
	return false

func run_tests() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if not check(packed != null, "Main scene imports"): return
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.start_new_game()
	game.dialogue = ""
	var hud = game.hud
	if not check(game.kael_art.size() == 5, "All five new Kael movement sprites load as real imported Godot textures"): return
	for pose in ["idle","run","jump","attack","guard"]:
		if not check(game.kael_art.has(pose) and game.kael_art[pose].get_width() >= 190 and game.kael_art[pose].get_height() >= 250, "Full character silhouette texture loads for " + pose): return
	if not check(hud.atlas_art != null and hud.atlas_art.get_width() == 1600 and hud.atlas_art.get_height() == 900, "Illustrated 2.5D overworld texture imported at intended aspect ratio"): return
	if not check(hud.dialogue_portraits.size() == 5 and hud.dialogue_portraits.has("sen") and hud.dialogue_portraits.has("mira"), "Five named illustrated NPC dialogue portraits load"): return
	if not check(hud.ATLAS_POINTS.size() >= 19 and hud.ATLAS_ROUTES.size() >= 18, "Atlas includes 19 real chapter/dungeon locations and linked progression"): return
	if not check(hud.atlas_progress_percent() >= 0 and hud.atlas_progress_percent() <= 100, "Progress computed from real discoveries, quests and dungeon clears"): return
	if not check(game.is_realm_unlocked("forest") and not game.is_realm_unlocked("crystal"), "Early world unlocked but advanced chapter locked for new player"): return
	game.state = "worldmap"
	hud.atlas_selected = "crystal"
	hud.queue_redraw()
	await process_frame
	await process_frame
	if not check(contains_key(hud.menu_buttons, "atlas_node:hub") and contains_key(hud.menu_buttons, "atlas_node:forest") and contains_key(hud.menu_buttons, "atlas_node:nexus"), "All map nodes have touch hitboxes"): return
	if not check(not contains_key(hud.menu_buttons, "atlas_travel"), "Locked chapter has no travel action"): return
	var map_start: int = hud.atlas_progress_percent()
	hud.atlas_selected = "forest"
	hud.queue_redraw()
	await process_frame
	await process_frame
	if not check(contains_key(hud.menu_buttons, "atlas_travel"), "Unlocked chapter has real travel action"): return
	var width: float = hud.size.x
	var height: float = hud.size.y
	var travel_w: float = minf(185.0, width * 0.20)
	var return_w: float = minf(148.0, width * 0.16)
	var button: Vector2 = Vector2(width - travel_w - return_w - 30.0 + travel_w * 0.5, height - 63.0)
	if not check(hud.handle_menu_press(button) and game.current_realm_id == "forest" and game.state == "playing", "Tapping TRAVEL enters actual unlocked packed realm"): return
	if not check(game.discovered_realm_ids.has("forest") and hud.atlas_progress_percent() > map_start, "Real chapter visit increases saved overworld progression"): return
	if not check(game.dialogue != "" and hud.story_speaker() == "SCOUT ELIAN" and hud.story_portrait_id() == "scout", "First visit automatically launches NPC storybook pop-up with matching portrait"): return
	var panel: Rect2 = hud.story_dialogue_rect(width, height)
	if not check(panel.position.x >= 0.0 and panel.end.x <= width and panel.position.y > 0.0 and panel.end.y <= height, "Story popup respects phone landscape viewport bounds"): return
	var pages: int = game.story_queue.size()
	if not check(hud.handle_menu_press(hud.story_next_rect(width,height).get_center()) and game.story_queue.size() < pages, "NEXT advances storyline without moving player"): return
	if not check(hud.handle_menu_press(hud.story_skip_rect(width,height).get_center()) and game.dialogue == "" and game.story_queue.is_empty(), "SKIP exits cinematic safely"): return
	var persisted: int = game.discovered_realm_ids.size()
	game.save_game()
	if not check(game.load_game() and game.discovered_realm_ids.size() == persisted, "Progression persists across existing Android save format"): return
	print("PASS: v10 illustrated chapter atlas, functional unlocking and travel, 5 Kael sprites, NPC storybook popups and save migration")
	quit(0)
