extends Node2D
## Echoes of Aether: offline, mobile-first, self-contained action adventure.
## All gameplay is simulated in world space. HUD stays in CanvasLayer screen space.

const WORLD_WIDTH := 83300.0
const REALM_CATALOG = preload("res://scripts/RealmCatalog.gd")
const V5_SAVE_VERSION := 50
const V6_SAVE_VERSION := 60
const PUZZLE_ENGINE = preload("res://scripts/PuzzleEngine.gd")
const NEW_BOSSES = ["root_colossus", "mirror_keeper", "gale_wyrm", "mire_reaver",
	"echo_archon", "abyss_leviathan", "thornheart", "nexus_echo"]
const EMBER_START := 15800.0
const CINDER_VAULT_START := 19800.0
const EMBER_BRAZIERS = [16550.0, 18870.0, 20880.0]
const EMBER_RUNE_PATTERNS = [[0, 2, 1], [2, 1, 0], [1, 0, 2]]
const EMBER_RUNE_NAMES = ["FLAME", "ASH", "SPARK"]
const EMBER_RUNE_CLUES = [
	"The FLAME is born, the SPARK leaps, and the ASH settles.",
	"The SPARK lights the path, the ASH falls, the FLAME returns.",
	"Only ASH remains; then comes FLAME, and finally SPARK."
]
const FLOOR_Y := 500.0
const GRAVITY := 1250.0
const SKILL_COOLDOWN := 2.25
const CACHE_LOCATIONS = [690.0, 1940.0, 3400.0, 4560.0, 5350.0, 6780.0]
# Optional lore puzzles: no required progress is gated behind any puzzle.
const ECHO_SHRINES = [1840.0, 4040.0, 5780.0, 9830.0, 11780.0, 14250.0]
const RUNE_NAMES = ["SUN", "MOON", "STAR"]
const ECHO_PATTERNS = [[0, 1, 2], [2, 0, 1], [1, 2, 0], [0, 2, 1], [2, 1, 0], [1, 0, 2]]
const ECHO_HINTS = [
	"DAWN WARMS THE SKY, NIGHT RETURNS, THEN THE STAR GUIDES.",
	"THE STAR CALLS, THE SUN ANSWERS, THE MOON RESTS.",
	"THE MOON REFLECTS, THE STAR SPARKS, THE SUN WAKES.",
	"THE SUN RISES, A STAR SHINES, THEN THE MOON FOLLOWS.",
	"THE STAR FALLS, THE MOON WATCHES, THE SUN BRINGS HOPE.",
	"THE MOON OPENS, THE SUN BLAZES, THE STAR ENDS THE SONG."
]
const ECHO_LORE = [
	"Moonhaven grew around the last living ember of the Aether.",
	"Whisperwood remembers every promise made beneath its leaves.",
	"The Ruins were designed to hold a fallen constellation.",
	"Crystals sing when their ancient keeper hears the truth.",
	"The Highlands carry songs between forgotten kingdoms.",
	"Shadowfen's darkness can shelter the smallest light."
]
const VISUALS_FILE = "user://aether_visuals.json"
const PORTAL_NAMES = ["MOONHAVEN", "CRYSTAL HOLLOW", "CELESTIAL HIGHLANDS", "SHADOWFEN MARSH", "EMBERFALL CITADEL"]
const PORTAL_LOCATIONS = [1720.0, 8660.0, 11050.0, 13240.0, 16000.0]
const PORTAL_ARRIVALS = [1635.0, 8800.0, 11190.0, 13380.0, 16120.0]
const BOSS_TYPES = ["boss", "crystal_titan", "sky_herald", "marsh_guardian", "cinder_warden",
	"root_colossus", "mirror_keeper", "gale_wyrm", "mire_reaver", "echo_archon",
	"abyss_leviathan", "thornheart", "nexus_echo"]
const WORLD_BOSS_NAMES = ["WARDEN OF THE FADING STAR", "CRYSTAL TITAN", "SKY HERALD", "SHADOWFEN GUARDIAN", "CINDER WARDEN",
	"ROOT COLOSSUS", "MIRROR KEEPER", "GALE WYRM", "MIRE REAVER", "ECHO ARCHON",
	"ABYSS LEVIATHAN", "THORNHEART", "THE NEXUS ECHO"]
const HERO_IDLE = preload("res://assets/hero_idle.png")
const HERO_RUN = preload("res://assets/hero_run.png")
const HERO_JUMP = preload("res://assets/hero_jump.png")
const SLIME = preload("res://assets/slime.png")
const MOTH = preload("res://assets/moth.png")
const BEETLE = preload("res://assets/beetle.png")
const SENTINEL = preload("res://assets/sentinel.png")
const WISP = preload("res://assets/wisp.png")
const BOSS = preload("res://assets/boss.png")
const TREE = preload("res://assets/forest_tree.png")
const TREE_DARK = preload("res://assets/forest_tree_dark.png")
const HOUSE = preload("res://assets/house.png")
const HOUSE_SHOP = preload("res://assets/shop.png")
const RUIN = preload("res://assets/ruin.png")
const GRASS = preload("res://assets/grass.png")
const ROCK = preload("res://assets/rock.png")
const NPC = preload("res://assets/npc.png")
const COIN = preload("res://assets/coin.png")
const SEED = preload("res://assets/seed.png")
const POTION = preload("res://assets/potion.png")
const MAGIC = preload("res://assets/magic.png")
const PORTAL = preload("res://assets/portal.png")

@onready var camera: Camera2D = $Camera2D
@onready var hud = $CanvasLayer/HUD
var font: Font
var state := "main"
var player_pos := Vector2(145.0, FLOOR_Y)
var velocity := Vector2.ZERO
var facing := 1
var on_ground := true
var hp := 100.0
var max_hp := 100.0
var stamina := 100.0
var max_stamina := 100.0
var exp_points := 0
var level := 1
var coins := 35
var potions := 2
var sword_level := 1
var armor_level := 1
var seeds := 0
var quest_stage := 0  # 0 not accepted, 1 gather 3 seeds, 2 fight Warden, 3 boss defeated
var relic_shards := 0
var opened_caches: Array = []
var rune_upgrades: Array = [false, false, false]  # Windstep, Astral Edge, Vital Spark
var jump_count := 0
var hunted_moths := 0
var hunted_sentinels := 0
var claimed_hunts: Array = []
var floating_text: Array = []
var portal_unlocked: Array = [true, false, false, false]
var world_bosses_cleared: Array = [false, false, false]
var expansion_completed := false
var moving_platforms: Array = []
var poison_pools: Array = []
var coyote_timer := 0.0
var portal_cooldown := 0.0
var checkpoint_x := 145.0
var defeated_boss := false
var dying := false
var enemies: Array = []
var loot: Array = []
var bolts: Array = []
var particles: Array = []
var platforms: Array = []
var traps: Array = []
var message := ""
var message_time := 0.0
var dialogue := ""
var elapsed := 0.0
var autosave_timer := 0.0
var invincible := 0.0
var attack_timer := 0.0
var slash_timer := 0.0
var dash_timer := 0.0
var dash_cooldown := 0.0
var skill_timer := 0.0
# v0.6 mastery combat: perfect guard, three-hit combos and lifetime hunt rewards.
var guard_window := 0.0
var guard_cooldown := 0.0
var combo_stage := 0
var combo_timer := 0.0
var total_kills := 0
var mastery_rewards: Array = []
# v1.0 visual and exploration enhancements.
var awakened_shrines: Array = []
var puzzle_index := -1
var puzzle_progress := 0
var puzzle_feedback := "TAP THE RUNES IN CLUE ORDER."
var graphics_quality := 1
var reduced_motion := false
var realm_backdrops: Dictionary = {}
var ember_art: Dictionary = {}
var v5_art: Dictionary = {}
var v6_art: Dictionary = {}
var trial_completed: Array = []
var trial_puzzle: Dictionary = {}
var trial_puzzle_id := ""
var trial_hint_text := ""
var trial_preview_time := 0.0
var ember_boss_defeated := false
var ember_braziers: Array = []
var ember_puzzle_index := -1
var ember_puzzle_progress := 0
var ember_puzzle_feedback := ""
var emberling_unlocked := false
var emberling_active := true
var emberling_pos := Vector2.ZERO
var emberling_attack_cooldown := 0.0
var emberling_attacks := 0
var ember_hunt_counts: Dictionary = {}
var ember_hunt_claimed: Array = []
# v5 real portal-based areas, isolated PackedScene instances and reusable RPG systems.
var current_realm_id := "hub"
var realm_stage: Node2D
var realm_transition := 0.0
var portal_page := 0
var journal_page := 0
# Pinned journal objective; empty string means choose the next unfinished quest.
var tracked_quest_id := ""
var quest_counts: Dictionary = {}
var quest_claimed: Array = []
var discovered_realm_ids: Array = ["hub"]
var dungeon_clears: Array = []
var story_seen: Array = []
var story_queue: Array = []
var enemy_kill_counts: Dictionary = {}
var map_visit_counts: Dictionary = {}
var arena_combo_cycle := 0
var healing_glow := 0.0
var level_up_glow := 0.0
var hero_impact := 0.0
var menu_drift := 0.0
var screen_shake := 0.0
var boss_alert := ""
var joystick_touch := -1
var touch_axis := 0.0
var joystick_base := Vector2.ZERO
var attack_touch: Dictionary = {}
var hold_attack := false
var music: AudioStreamPlayer
var sfx: AudioStreamPlayer
var sound_on := true
var music_on := true
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	font = ThemeDB.fallback_font
	rng.seed = 20261110
	load_visual_preferences()
	create_world()
	load_realm_backdrops()
	load_ember_art()
	load_v5_generated_art()
	load_v6_generated_art()
	load_realm_stage("hub")
	camera.position = Vector2(575, 316)
	camera.make_current()
	music = AudioStreamPlayer.new()
	add_child(music)
	var song = load("res://assets/theme.wav")
	if song is AudioStreamWAV:
		song.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.stream = song
	music.volume_db = -19.0
	music.play()
	sfx = AudioStreamPlayer.new()
	sfx.volume_db = -11.0
	add_child(sfx)
	update_camera()

func load_realm_backdrops() -> void:
	# Downloaded by GitHub CI during asset preparation; the game remains fully offline.
	# Missing generated art falls back to original procedural scenery.
	for backdrop_id in ["crystal", "sky", "marsh"]:
		var path: String = "res://assets/v1_bg_%s.png" % backdrop_id
		if ResourceLoader.exists(path):
			var texture: Resource = load(path)
			if texture is Texture2D:
				realm_backdrops[backdrop_id] = texture

func draw_realm_backdrop(region: int, region_start: float, region_end: float, left: float, right: float) -> void:
	if graphics_quality == 0 or region < 3 or region > 5:
		return
	var realm_id: String = ["crystal", "sky", "marsh"][region - 3]
	if not realm_backdrops.has(realm_id):
		return
	# Render one panorama per independent destination. Repeating photo edges
	# previously created obvious vertical gaps despite correct portal logic.
	var texture: Texture2D = realm_backdrops[realm_id]
	draw_texture_rect(texture, Rect2(region_start, -133.0, region_end - region_start, 680.0), false,
		Color(1.0, 1.0, 1.0, 0.55 if graphics_quality == 2 else 0.42))


func load_v5_generated_art() -> void:
	# Each procedural panorama is created once at build time, then bundled into
	# the offline APK. The render loop reuses these cached textures every frame.
	for name in ["abyss", "tide_temple", "garden", "verdant_vault", "nexus", "nexus_core", "rootcrypt"]:
		var image_path: String = "res://assets/v5_generated_%s.png" % name
		if ResourceLoader.exists(image_path):
			var resource: Resource = load(image_path)
			if resource is Texture2D:
				v5_art[name] = resource

func load_v6_generated_art() -> void:
	# Unique locally-produced, offline dungeon annex art, not runtime web images.
	for trial in REALM_CATALOG.TRIALS:
		var texture_name: String = str(REALM_CATALOG.TRIALS[trial]["art"])
		var path: String = "res://assets/%s.png" % texture_name
		if ResourceLoader.exists(path):
			var resource: Resource = load(path)
			if resource is Texture2D:
				v6_art[trial] = resource

func v6_art_for(id: String) -> Texture2D:
	return v6_art.get(id, null) as Texture2D

func load_ember_art() -> void:
	var ids: Array = ["citadel", "dungeon", "cinder_warden", "fire_imp", "emberling",
		"slime", "moth", "beetle", "sentinel", "wisp", "crystal_bug", "crystal_wisp", "sky_wisp",
		"cloud_moth", "bog_slime", "bog_wisp", "ash_knight", "ember_wisp",
		"boss", "crystal_titan", "sky_herald", "marsh_guardian"]
	for id in ids:
		var path: String = "res://assets/v2_%s.png" % id
		if ResourceLoader.exists(path):
			var resource: Resource = load(path)
			if resource is Texture2D:
				ember_art[id] = resource

func draw_v2_background(texture: Texture2D, start: float, end: float, left: float, right: float) -> void:
	if graphics_quality == 0:
		return
	# One continuous image per zone, rather than sharply-edged repeated tiles.
	draw_texture_rect(texture, Rect2(start, -180.0, end - start, 730.0), false,
		Color(1.0, 1.0, 1.0, 0.83 if graphics_quality == 2 else 0.64))


func draw_emberfall_scenery(left: float, right: float) -> void:
	if right < EMBER_START: return
	if ember_art.has("citadel"):
		draw_v2_background(ember_art["citadel"], EMBER_START, CINDER_VAULT_START, left, right)
	if ember_art.has("dungeon"):
		draw_v2_background(ember_art["dungeon"], CINDER_VAULT_START, 23000.0, left, right)
	for i in range(20):
		var x: float = EMBER_START + float(i) * 355.0
		if x < left - 125.0 or x > right + 125.0: continue
		var flame_h: float = 52.0 + float(i % 4) * 18.0
		draw_rect(Rect2(x - 11, FLOOR_Y - 32, 22, 32), Color("654337"))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 13, FLOOR_Y - 32), Vector2(x, FLOOR_Y - 32 - flame_h), Vector2(x + 15, FLOOR_Y - 32)]), Color(1.0, 0.44, 0.12, 0.42))
	for i in range(13):
		var x: float = CINDER_VAULT_START + 135.0 + float(i) * 240.0
		if x < left - 80 or x > right + 80: continue
		draw_rect(Rect2(x - 16, 147, 32, 352), Color(0.16, 0.1, 0.15, 0.72))
		draw_rect(Rect2(x - 24, 154, 50, 16), Color("5b4850"))
	for plaque in [{"x": 15950.0, "name": "EMBERFALL CITADEL"}, {"x": 20070.0, "name": "CINDER VAULT - GATEHOUSE"}, {"x": 21050.0, "name": "FURNACE HALL"}, {"x": 22100.0, "name": "CINDER THRONE"}]:
		if float(plaque["x"]) > left and float(plaque["x"]) < right:
			draw_label(Vector2(float(plaque["x"]), 182), str(plaque["name"]), 25, Color("ffdeb1"))

func play_sfx(name: String) -> void:
	if not sound_on: return
	var clip = load("res://assets/fx_%s.wav" % name)
	if clip != null:
		sfx.stream = clip
		sfx.play()

func create_world() -> void:
	platforms = [
		Rect2(1970, 424, 165, 18), Rect2(2250, 377, 145, 18),
		Rect2(2560, 428, 138, 18), Rect2(2710, 386, 175, 18),
		Rect2(3060, 426, 178, 18), Rect2(3360, 370, 186, 18),
		Rect2(3510, 426, 190, 18), Rect2(3900, 412, 160, 18),
		Rect2(4310, 368, 165, 18), Rect2(4630, 420, 170, 18),
		Rect2(5120, 420, 185, 18), Rect2(5480, 350, 160, 18),
		Rect2(5900, 415, 178, 18), Rect2(6680, 410, 165, 18),
		Rect2(7040, 365, 165, 18), Rect2(7410, 425, 150, 18),
		Rect2(8960, 420, 160, 18), Rect2(9210, 365, 145, 18),
		Rect2(9640, 411, 160, 18), Rect2(9910, 343, 150, 18),
		Rect2(11380, 414, 185, 18), Rect2(12070, 365, 180, 18),
		Rect2(13680, 421, 160, 18), Rect2(14200, 382, 162, 18),
		Rect2(14700, 420, 175, 18),
		# Emberfall: broad safe platforms with optional vertical routes.
		Rect2(16380, 412, 190, 18), Rect2(16920, 375, 175, 18),
		Rect2(17380, 416, 190, 18), Rect2(17940, 370, 188, 18),
		Rect2(18500, 418, 170, 18), Rect2(19200, 374, 186, 18),
		Rect2(20050, 420, 172, 18), Rect2(20510, 370, 182, 18),
		Rect2(21100, 413, 198, 18), Rect2(21710, 377, 174, 18),
		Rect2(22240, 426, 192, 18)
	]
	traps = [Rect2(2650, 494, 135, 130), Rect2(3480, 494, 150, 130),
		Rect2(5210, 494, 150, 130), Rect2(9350, 494, 120, 130),
		Rect2(11680, 494, 130, 130), Rect2(14460, 494, 130, 130)]
	moving_platforms = [
		{"x": 11520.0, "width": 142.0, "base_y": 362.0, "y": 362.0, "phase": 0.2},
		{"x": 11920.0, "width": 145.0, "base_y": 324.0, "y": 324.0, "phase": 1.7},
		{"x": 12240.0, "width": 142.0, "base_y": 386.0, "y": 386.0, "phase": 3.2}
	]
	poison_pools = [Rect2(13580, 480, 114, 22), Rect2(14020, 480, 132, 22),
		Rect2(14800, 480, 135, 22)]
	# Furnace hazards are short and clearly visible; every main route is passable.
	poison_pools.append_array([Rect2(17320, 478, 105, 22), Rect2(18440, 478, 115, 22),
		Rect2(20960, 478, 96, 22)])
	build_v5_map_terrain()
	spawn_enemies()

func build_v5_map_terrain() -> void:
	# Stable, collision-backed routes; optional platforms and shallow hazards.
	for region in REALM_CATALOG.REGIONS:
		if float(region["start"]) < 23000.0: continue
		var origin: float = float(region["start"])
		var span: float = float(region["end"]) - origin
		var segments: int = int(span / 435.0)
		for i in range(segments):
			var x: float = origin + 370.0 + float(i) * 435.0
			if x > float(region["end"]) - 250.0: continue
			var top: float = 362.0 + float(i % 3) * 26.0
			platforms.append(Rect2(x, top, 168.0 + float(i % 2) * 26.0, 18.0))
			if i > 0 and i % 5 == 3 and region["kind"] == "dungeon":
				traps.append(Rect2(x + 235.0, 494.0, 88.0, 130.0))
			if i > 0 and i % 6 == 4 and region["id"] in ["abyss", "tide_temple", "mire_catacombs"]:
				poison_pools.append(Rect2(x + 165.0, 478.0, 110.0, 22.0))

func spawn_enemies() -> void:
	enemies.clear()
	for x in [2230, 2470, 2890, 3190, 3840, 4250, 4550]:
		add_enemy("slime", x)
	for x in [2370, 3160, 3620, 4460]:
		add_enemy("moth", x)
	for x in [3000, 3780, 4200]:
		add_enemy("beetle", x)
	for x in [4930, 5620, 5920, 6450, 6920]:
		add_enemy("sentinel", x)
	for x in [5360, 6180, 6840, 7240]:
		add_enemy("wisp", x)
	if not defeated_boss:
		add_enemy("boss", 7780)
	# The three new connected regions contain distinct enemy archetypes and bosses.
	for x in [9040.0, 9270.0, 9700.0, 10130.0]:
		add_enemy("crystal_bug", x)
	for x in [9440.0, 9940.0]:
		add_enemy("crystal_wisp", x)
	if not world_bosses_cleared[0]:
		add_enemy("crystal_titan", 10510.0)
	for x in [11390.0, 11850.0, 12210.0]:
		add_enemy("sky_wisp", x)
	for x in [11610.0, 12350.0]:
		add_enemy("cloud_moth", x)
	if not world_bosses_cleared[1]:
		add_enemy("sky_herald", 12530.0)
	for x in [13500.0, 13880.0, 14380.0, 14840.0]:
		add_enemy("bog_slime", x)
	for x in [13740.0, 14530.0]:
		add_enemy("bog_wisp", x)
	if not world_bosses_cleared[2]:
		add_enemy("marsh_guardian", 15310.0)
	# Chapter II enemies persist as defeated through the original save state.
	for x in [16350.0, 17180.0, 17950.0, 18760.0, 20260.0, 20920.0]:
		add_enemy("fire_imp", x)
	for x in [16780.0, 18180.0, 19450.0, 21380.0]:
		add_enemy("ash_knight", x)
	for x in [17540.0, 19600.0, 21680.0]:
		add_enemy("ember_wisp", x)
	if not ember_boss_defeated:
		add_enemy("cinder_warden", 22400.0)
	# Portal-only additional chapters and dungeon encounter packs.
	for x in [23730.0, 24420.0, 25470.0, 26150.0, 26730.0, 28040.0, 29130.0]:
		add_enemy("tide_stalker", x)
	for x in [23980.0, 24980.0, 25790.0, 28620.0, 29900.0]:
		add_enemy("coral_wisp", x)
	for x in [31680.0, 32300.0, 33110.0, 33900.0, 34920.0, 36220.0, 37230.0]:
		add_enemy("thorn_knight", x)
	for x in [31930.0, 32930.0, 34320.0, 36800.0, 37900.0]:
		add_enemy("petal_moth", x)
	for x in [39450.0, 40130.0, 40900.0, 41820.0, 42700.0, 59650.0, 61000.0]:
		add_enemy("sky_wisp", x)
	for x in [44100.0, 45000.0, 45750.0, 47100.0, 48100.0, 50520.0, 51650.0, 53120.0, 54500.0, 56500.0, 58000.0]:
		add_enemy("sentinel", x)
	# Annexes contain new encounter packs so the side branches are gameplay,
	# not empty background corridors. Enemy variants inherit real AI.
	for trial_id in REALM_CATALOG.TRIALS:
		var annex: Dictionary = REALM_CATALOG.region(str(trial_id))
		var x0: float = float(annex["start"])
		var family: String = str(REALM_CATALOG.TRIALS[trial_id]["theme"])
		var roster: Array = {
			"forest": ["moth", "beetle", "sentinel"],
			"crystal": ["crystal_bug", "crystal_wisp", "sentinel"],
			"sky": ["sky_wisp", "cloud_moth", "beetle"],
			"marsh": ["bog_slime", "bog_wisp", "sentinel"],
			"ember": ["fire_imp", "ash_knight", "ember_wisp"],
			"abyss": ["tide_stalker", "coral_wisp", "sentinel"],
			"garden": ["thorn_knight", "petal_moth", "wisp"],
			"nexus": ["sky_wisp", "sentinel", "ash_knight"]
		}.get(family, ["sentinel", "wisp", "beetle"])
		for j in range(7):
			add_enemy(str(roster[j % roster.size()]), x0 + 460.0 + float(j) * 285.0)
	for kind in REALM_CATALOG.DUNGEON_BOSSES:
		var location: Dictionary = REALM_CATALOG.region(str(kind))
		if not location.is_empty() and not dungeon_clears.has(str(kind)):
			add_enemy(str(REALM_CATALOG.DUNGEON_BOSSES[kind]), float(location["end"]) - 465.0)

func add_enemy(kind: String, x: float) -> void:
	var life = {"slime": 30.0, "moth": 22.0, "beetle": 45.0, "sentinel": 68.0, "wisp": 30.0,
		"boss": 290.0, "crystal_bug": 76.0, "crystal_wisp": 55.0,
		"sky_wisp": 62.0, "cloud_moth": 58.0, "bog_slime": 100.0, "bog_wisp": 74.0,
		"crystal_titan": 430.0, "sky_herald": 515.0, "marsh_guardian": 650.0,
		"fire_imp": 90.0, "ash_knight": 152.0, "ember_wisp": 74.0, "cinder_warden": 850.0,
		"tide_stalker": 105.0, "coral_wisp": 76.0, "thorn_knight": 165.0, "petal_moth": 82.0,
		"root_colossus": 390.0, "mirror_keeper": 490.0, "gale_wyrm": 540.0,
		"mire_reaver": 580.0, "echo_archon": 480.0, "abyss_leviathan": 720.0,
		"thornheart": 760.0, "nexus_echo": 1000.0}[kind]
	var walk = {"slime": 52.0, "moth": 80.0, "beetle": 98.0, "sentinel": 42.0, "wisp": 60.0,
		"boss": 75.0, "crystal_bug": 102.0, "crystal_wisp": 94.0,
		"sky_wisp": 115.0, "cloud_moth": 125.0, "bog_slime": 75.0, "bog_wisp": 93.0,
		"crystal_titan": 85.0, "sky_herald": 115.0, "marsh_guardian": 100.0,
		"fire_imp": 120.0, "ash_knight": 68.0, "ember_wisp": 115.0, "cinder_warden": 87.0,
		"tide_stalker": 118.0, "coral_wisp": 97.0, "thorn_knight": 76.0, "petal_moth": 129.0,
		"root_colossus": 60.0, "mirror_keeper": 90.0, "gale_wyrm": 125.0,
		"mire_reaver": 82.0, "echo_archon": 91.0, "abyss_leviathan": 105.0,
		"thornheart": 99.0, "nexus_echo": 116.0}[kind]
	enemies.append({"type": kind, "x": x, "origin": x, "y": FLOOR_Y, "hp": life, "max_hp": life,
		"speed": walk, "dir": -1, "cooldown": rng.randf_range(0.5, 2.0), "stun": 0.0,
		"phase": 1, "state": "patrol", "attack_anim": 0.0, "windup": 0.0, "seed_drop": kind == "slime",
		"pattern": 0, "special_timer": 0.0, "charging": 0.0, "shielded": false})

func ground_y(x: float) -> float:
	for pit in traps:
		if x > pit.position.x + 4.0 and x < pit.end.x - 4.0:
			return -1.0
	return FLOOR_Y

func _physics_process(dt: float) -> void:
	elapsed += dt
	menu_drift += dt
	trial_preview_time = maxf(0.0, trial_preview_time - dt)
	healing_glow = maxf(0.0, healing_glow - dt)
	level_up_glow = maxf(0.0, level_up_glow - dt)
	hero_impact = maxf(0.0, hero_impact - dt)
	if message_time > 0.0:
		message_time -= dt
	invincible = maxf(0.0, invincible - dt)
	attack_timer = maxf(0.0, attack_timer - dt)
	slash_timer = maxf(0.0, slash_timer - dt)
	dash_timer = maxf(0.0, dash_timer - dt)
	dash_cooldown = maxf(0.0, dash_cooldown - dt)
	skill_timer = maxf(0.0, skill_timer - dt)
	guard_window = maxf(0.0, guard_window - dt)
	guard_cooldown = maxf(0.0, guard_cooldown - dt)
	combo_timer = maxf(0.0, combo_timer - dt)
	if combo_timer <= 0.0:
		combo_stage = 0
	portal_cooldown = maxf(0.0, portal_cooldown - dt)
	realm_transition = maxf(0.0, realm_transition - dt)
	screen_shake = maxf(0.0, screen_shake - dt)
	if state == "playing":
		# NPC story scenes pause enemy movement and hazards while dialogue is visible.
		# Reading is never a combat disadvantage on a touchscreen.
		if dialogue != "":
			touch_axis = 0.0
			joystick_touch = -1
			attack_touch.clear()
			hold_attack = false
			update_camera()
			queue_redraw()
			hud.queue_redraw()
			return
		update_moving_platforms(dt)
		update_player(dt)
		update_enemies(dt)
		update_projectiles(dt)
		update_loot(dt)
		update_particles(dt)
		update_emberling(dt)
		update_floating_text(dt)
		update_camera()
		stamina = minf(max_stamina, stamina + (25.0 if rune_upgrades[2] else 18.0) * dt)
		if hold_attack or Input.is_key_pressed(KEY_J):
			attack()
		autosave_timer += dt
		if autosave_timer > 28.0:
			autosave_timer = 0.0
			save_game()
	queue_redraw()
	hud.queue_redraw()

func update_moving_platforms(dt: float) -> void:
	for platform in moving_platforms:
		platform["y"] = float(platform["base_y"]) + sin(elapsed * 1.65 + float(platform["phase"])) * 36.0

func update_player(dt: float) -> void:
	realign_realm_to_position()
	if on_ground:
		coyote_timer = 0.12
	else:
		coyote_timer = maxf(0.0, coyote_timer - dt)
	var axis := touch_axis
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		axis -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		axis += 1.0
	axis = clampf(axis, -1.0, 1.0)
	if absf(axis) > 0.1:
		facing = 1 if axis > 0.0 else -1
	if dash_timer > 0.0:
		velocity.x = float(facing) * 760.0
	else:
		var target_speed := axis * (335.0 if absf(axis) > 0.85 else 285.0)
		velocity.x = move_toward(velocity.x, target_speed, (2600.0 if absf(axis) > 0.08 else 2400.0) * dt)
	velocity.y = minf(900.0, velocity.y + GRAVITY * dt)
	var old_foot := player_pos.y
	player_pos += velocity * dt
	var travel_area: Dictionary = current_realm()
	var area_min: float = float(travel_area["start"]) + 62.0
	var area_max: float = float(travel_area["end"]) - 62.0
	player_pos.x = clampf(player_pos.x, area_min, area_max)
	# Every realm is a sealed scene. Walking cannot expose the neighboring art seam.
	if absf(player_pos.x - area_min) < 1.0 or absf(player_pos.x - area_max) < 1.0:
		velocity.x = 0.0
		if portal_cooldown <= 0.0:
			show_message("PORTAL TRAVEL: Use the glowing gateway, not the map edge.", 2.3)
	if quest_stage < 2 and player_pos.x > 6195.0:
		player_pos.x = 6195.0
		velocity.x = 0.0
		show_message("Aether Gate sealed. Bring 3 seeds to Mira!", 2.5)
	elif quest_stage >= 2 and not defeated_boss and player_pos.x > 7380.0:
		boss_alert = "WARDEN OF THE FADING STAR"
	if not defeated_boss and player_pos.x > 8340.0:
		player_pos.x = 8340.0
		velocity.x = 0.0
		show_message("Defeat the Star Warden to enter Crystal Hollow!", 2.1)
	elif not world_bosses_cleared[0] and player_pos.x > 10800.0:
		player_pos.x = 10800.0
		velocity.x = 0.0
		show_message("Crystal Titan blocks the Celestial Highlands!", 2.1)
	elif not world_bosses_cleared[1] and player_pos.x > 12900.0:
		player_pos.x = 12900.0
		velocity.x = 0.0
		show_message("Sky Herald blocks the Shadowfen Marsh!", 2.1)
	elif not expansion_completed and player_pos.x > EMBER_START - 80.0:
		player_pos.x = EMBER_START - 80.0
		velocity.x = 0.0
		show_message("Shattered Realms unlocks after restoring Shadowfen.", 2.6)
	on_ground = false
	var floor := ground_y(player_pos.x)
	if floor > 0.0 and player_pos.y >= floor and velocity.y >= 0.0:
		player_pos.y = floor
		velocity.y = 0.0
		on_ground = true
		jump_count = 0
	for p in platforms:
		if velocity.y >= 0.0 and old_foot <= p.position.y + 8.0 and player_pos.y >= p.position.y and player_pos.x >= p.position.x - 12.0 and player_pos.x <= p.end.x + 12.0:
			player_pos.y = p.position.y
			velocity.y = 0.0
			on_ground = true
			jump_count = 0
	# Moving sky platforms provide timing-based vertical traversal.
	for platform in moving_platforms:
		var top: float = float(platform["y"])
		var px: float = float(platform["x"])
		if velocity.y >= 0.0 and old_foot <= top + 9.0 and player_pos.y >= top and player_pos.x >= px - 12.0 and player_pos.x <= px + float(platform["width"]) + 12.0:
			player_pos.y = top
			velocity.y = 0.0
			on_ground = true
			jump_count = 0
	# Poisonous shallows hurt only when the hero stands in their glow.
	for pool in poison_pools:
		if pool.has_point(player_pos + Vector2(0, -5)):
			damage_player(10.0)
	if player_pos.y > 850.0:
		damage_player(999.0)
	# Crossing each new biome makes it the respawn region without losing old checkpoints.
	if player_pos.x > 21800.0 and checkpoint_x < 21800.0:
		checkpoint_x = 21850.0
		show_message("Checkpoint: Cinder Throne - the boss is ahead!", 2.8)
		save_game()
	elif player_pos.x > 20100.0 and checkpoint_x < 20100.0:
		checkpoint_x = 20150.0
		show_message("Checkpoint: Cinder Vault - Furnace Hall", 2.8)
		save_game()
	elif player_pos.x > 16080.0 and checkpoint_x < 16080.0:
		checkpoint_x = 16110.0
		show_message("Checkpoint: Emberfall Citadel", 2.8)
		save_game()
	elif player_pos.x > 13000.0 and checkpoint_x < 13000.0:
		checkpoint_x = 13220.0
		show_message("Checkpoint: Shadowfen Marsh", 2.4)
		save_game()
	elif player_pos.x > 10900.0 and checkpoint_x < 10900.0:
		checkpoint_x = 11080.0
		show_message("Checkpoint: Celestial Highlands", 2.4)
		save_game()
	elif player_pos.x > 8460.0 and checkpoint_x < 8460.0:
		checkpoint_x = 8630.0
		show_message("Checkpoint: Crystal Hollow", 2.4)
		save_game()
	elif player_pos.x > 4715.0 and checkpoint_x < 4780.0:
		checkpoint_x = 4790.0
		show_message("Checkpoint: Sunken Ruins", 2.4)
		save_game()
	elif player_pos.x > 2000.0 and checkpoint_x < 2000.0:
		checkpoint_x = 2030.0
		show_message("Checkpoint: Whisperwood", 2.4)
		save_game()

func jump() -> void:
	if state != "playing": return
	if on_ground or coyote_timer > 0.0 or (rune_upgrades[0] and jump_count < 2):
		var second_jump: bool = jump_count == 1 and not on_ground and coyote_timer <= 0.0
		jump_count = 2 if second_jump else 1
		coyote_timer = 0.0
		velocity.y = -515.0 if second_jump else -550.0
		on_ground = false
		spawn_dust(player_pos, Color("a9a4ff") if second_jump else Color("a6e8cc"), 13 if second_jump else 7)
		play_sfx("jump")

func dash() -> void:
	if state != "playing" or dash_cooldown > 0.0 or stamina < 24.0: return
	stamina -= 24.0
	dash_timer = 0.18
	dash_cooldown = 0.7
	invincible = maxf(invincible, 0.20)
	spawn_dust(player_pos, Color(0.25, 0.9, 1.0))
	play_sfx("dash")

func attack() -> void:
	if state != "playing" or attack_timer > 0.0: return
	combo_stage = (combo_stage % 3) + 1 if combo_timer > 0.0 else 1
	combo_timer = 1.25
	attack_timer = maxf(0.17, 0.32 - 0.021 * float(sword_level))
	slash_timer = 0.16
	var center = player_pos + Vector2(float(facing) * 38.0, -34.0)
	var power = (17.0 + 8.0 * float(sword_level - 1) + float(level - 1) * 1.9) * (1.65 if combo_stage == 3 else (1.2 if combo_stage == 2 else 1.0))
	if combo_stage == 3:
		add_float_text(player_pos + Vector2(0, -107), "TRIPLE STRIKE!", Color("ffe89d"))
		spawn_dust(player_pos + Vector2(float(facing) * 24.0, -45), Color("ffd28e"), 11)
	for e in enemies:
		if e["hp"] <= 0.0: continue
		if absf(e["x"] - center.x) < 75.0 and absf(e["y"] - center.y) < 87.0 and signf(e["x"] - player_pos.x) == float(facing):
			hit_enemy(e, power)
	spawn_dust(center, Color(0.42, 0.95, 1.0), 2)
	play_sfx("attack")

func use_skill() -> void:
	if state != "playing" or skill_timer > 0.0 or stamina < 35.0: return
	stamina -= 35.0
	skill_timer = SKILL_COOLDOWN
	bolts.append({"pos": player_pos + Vector2(float(facing) * 28.0, -36.0), "vel": Vector2(float(facing) * (660.0 if rune_upgrades[1] else 570.0), 0), "ttl": 1.8, "kind": "hero", "damage": 40.0 + float(level * 3) + (28.0 if rune_upgrades[1] else 0.0)})
	spawn_dust(player_pos + Vector2(0, -32), Color(0.2, 0.8, 1.0), 10)
	play_sfx("skill")

func skill_cooldown_fraction() -> float:
	return clampf(skill_timer / SKILL_COOLDOWN, 0.0, 1.0)

func guard() -> void:
	if state != "playing" or guard_cooldown > 0.0 or stamina < 18.0:
		return
	stamina -= 18.0
	guard_window = 0.55
	guard_cooldown = 2.6
	spawn_dust(player_pos + Vector2(0, -36), Color("86c9ff"), 8)
	play_sfx("dash")

func trigger_guard_counter() -> void:
	guard_window = 0.0
	invincible = maxf(invincible, 0.34)
	var nearest: Dictionary = {}
	var nearest_distance := 120.0
	for e in enemies:
		if e["hp"] <= 0.0:
			continue
		var d: float = absf(float(e["x"]) - player_pos.x)
		if d < nearest_distance and absf(float(e["y"]) - player_pos.y) < 145.0:
			nearest_distance = d
			nearest = e
	if not nearest.is_empty():
		hit_enemy(nearest, 23.0 + float(level) * 2.0)
	add_float_text(player_pos + Vector2(0, -104), "PERFECT GUARD!", Color("a4f6ff"))
	spawn_dust(player_pos + Vector2(0, -45), Color("7cddff"), 16)
	play_sfx("skill")

func damage_player(amount: float) -> void:
	if state != "playing": return
	if guard_window > 0.0:
		trigger_guard_counter()
		return
	if invincible > 0.0: return
	var actual = maxf(1.0, amount - float(armor_level - 1) * 3.0)
	hp -= actual
	hero_impact = 0.3
	add_float_text(player_pos + Vector2(0, -80), "-%d HP" % int(actual), Color("ff9b96"))
	invincible = 0.65
	screen_shake = 0.17
	spawn_dust(player_pos + Vector2(0, -30), Color(1, 0.45, 0.43), 8)
	play_sfx("hit")
	if hp <= 0.0:
		hp = 0.0
		state = "defeat"
		save_game()

func heal() -> void:
	if potions <= 0 or hp >= max_hp or state != "playing":
		if potions <= 0: show_message("No healing potions left!", 1.7)
		return
	potions -= 1
	hp = minf(max_hp, hp + 55.0)
	show_message("+55 HP", 1.4)
	healing_glow = 0.88
	spawn_dust(player_pos, Color(0.42, 1, 0.55), 10)
	play_sfx("heal")

func hit_enemy(e: Dictionary, amount: float) -> void:
	if e["hp"] <= 0.0: return
	e["hp"] -= amount
	add_float_text(Vector2(e["x"], e["y"] - 76), "%d" % int(amount), Color("ffe3a2"))
	e["stun"] = 0.19
	e["attack_anim"] = 0.20
	spawn_dust(Vector2(e["x"], e["y"] - 30), Color(0.97, 0.67, 0.29), 6)
	play_sfx("hit")
	if e["hp"] <= 0.0:
		enemy_died(e)

func enemy_died(e: Dictionary) -> void:
	e["hp"] = 0.0
	total_kills += 1
	enemy_kill_counts[str(e["type"])] = int(enemy_kill_counts.get(str(e["type"]), 0)) + 1
	record_quest_event("kill:" + str(e["type"]))
	if BOSS_TYPES.has(str(e["type"])):
		record_quest_event("boss:" + str(e["type"]))
	register_ember_hunt(str(e["type"]))
	for milestone in [12, 30, 60]:
		if total_kills >= milestone and not mastery_rewards.has(milestone):
			mastery_rewards.append(milestone)
			coins += milestone * 5
			potions += 1
			show_message("HUNTER MASTERY %d! +%d COINS, +1 POTION" % [milestone, milestone * 5], 4.5)
			save_game()
	var is_boss: bool = BOSS_TYPES.has(e["type"])
	var bonus := 150 if is_boss else (30 if e["type"] == "sentinel" else 16)
	gain_exp(bonus)
	loot.append({"kind": "coin", "pos": Vector2(e["x"], e["y"] - 25), "t": 0.0, "amount": 90 if is_boss else rng.randi_range(5, 13)})
	if e["seed_drop"] and seeds < 3 and quest_stage <= 1:
		loot.append({"kind": "seed", "pos": Vector2(e["x"] + 18, e["y"] - 42), "t": 0.0, "amount": 1})
	register_hunt(e["type"])
	if rng.randf() < 0.13:
		loot.append({"kind": "potion", "pos": Vector2(e["x"] - 15, e["y"] - 38), "t": 0.0, "amount": 1})
	if NEW_BOSSES.has(str(e["type"])):
		var cleared_id := ""
		for key in REALM_CATALOG.DUNGEON_BOSSES:
			if str(REALM_CATALOG.DUNGEON_BOSSES[key]) == str(e["type"]):
				cleared_id = str(key)
				break
		if cleared_id != "" and not dungeon_clears.has(cleared_id):
			dungeon_clears.append(cleared_id)
			coins += 175
			relic_shards += 1
			max_hp += 8.0
			hp = max_hp
			record_quest_event("clear:" + cleared_id)
			show_message("DUNGEON CLEARED: %s! +175 COINS, +1 RELIC" % area_name(), 4.8)
			play_sfx("win")
			state = "v5_victory" if cleared_id == "nexus_core" else "dungeon_victory"
			save_game()
	elif e["type"] == "cinder_warden":
		ember_boss_defeated = true
		coins += 350
		relic_shards += 3
		max_hp += 25.0
		hp = max_hp
		show_message("CINDER WARDEN DEFEATED! Emberfall Restored.", 5.0)
		play_sfx("win")
		state = "ember_victory"
		save_game()
	elif e["type"] == "boss":
		defeated_boss = true
		quest_stage = 3
		portal_unlocked[1] = true
		coins += 150
		show_message("The Warden has fallen! CRYSTAL HOLLOW portal unlocked!", 5.0)
		play_sfx("win")
		state = "victory"
		save_game()
	elif is_boss:
		var cleared_index: int = BOSS_TYPES.find(e["type"]) - 1
		if cleared_index >= 0 and cleared_index < world_bosses_cleared.size():
			world_bosses_cleared[cleared_index] = true
			coins += 180 + cleared_index * 75
			max_hp += 18.0
			hp = max_hp
			if cleared_index < 2:
				portal_unlocked[cleared_index + 2] = true
				show_message("REALM SAVED! Next portal unlocked. +Max HP and coins!", 4.2)
			else:
				expansion_completed = true
				portal_unlocked[4] = true
				show_message("SHADOWFEN RESTORED! EMBERFALL PORTAL UNLOCKED!", 5.0)
				state = "realm_victory"
			play_sfx("win")
			save_game()

func register_hunt(kind: String) -> void:
	if kind == "moth":
		hunted_moths += 1
		if hunted_moths >= 3 and not claimed_hunts.has("moth"):
			claimed_hunts.append("moth")
			coins += 75
			potions += 1
			show_message("MOTH HUNT COMPLETE! +75 coins and 1 potion", 4.0)
			save_game()
	elif kind == "sentinel":
		hunted_sentinels += 1
		if hunted_sentinels >= 2 and not claimed_hunts.has("sentinel"):
			claimed_hunts.append("sentinel")
			coins += 100
			max_hp += 15.0
			hp = minf(max_hp, hp + 15.0)
			show_message("GUARDIAN HUNT COMPLETE! +100 coins, +15 max HP", 4.0)
			save_game()

func nearby_cache_index() -> int:
	for i in range(CACHE_LOCATIONS.size()):
		if opened_caches.has(i):
			continue
		if absf(player_pos.x - CACHE_LOCATIONS[i]) < 92.0 and absf(player_pos.y - FLOOR_Y) < 135.0:
			return i
	return -1

func open_cache(index: int) -> bool:
	if state != "playing" or index < 0 or index >= CACHE_LOCATIONS.size() or opened_caches.has(index):
		return false
	if absf(player_pos.x - CACHE_LOCATIONS[index]) >= 105.0 or absf(player_pos.y - FLOOR_Y) > 140.0:
		return false
	opened_caches.append(index)
	relic_shards += 1
	coins += 25
	spawn_dust(Vector2(CACHE_LOCATIONS[index], FLOOR_Y - 28), Color("ffd98e"), 18)
	play_sfx("loot")
	show_message("AETHER CACHE %d/6! +1 relic shard, +25 coins" % opened_caches.size(), 3.6)
	save_game()
	return true

func unlock_rune(index: int) -> bool:
	if state != "trainer" or index < 0 or index >= rune_upgrades.size():
		return false
	if rune_upgrades[index]:
		show_message("This rune is already unlocked!", 2.0)
		return false
	if relic_shards < 2:
		show_message("Find 2 relic shards in hidden caches first!", 2.8)
		return false
	relic_shards -= 2
	rune_upgrades[index] = true
	match index:
		0: show_message("WINDSTEP UNLOCKED - Tap JUMP again in midair!", 4.0)
		1: show_message("ASTRAL EDGE UNLOCKED - Your Aether Bolt is stronger!", 4.0)
		2:
			max_stamina += 35.0
			stamina = max_stamina
			show_message("VITAL SPARK UNLOCKED - More stamina and faster recovery!", 4.0)
	spawn_dust(player_pos, Color("e5bcff"), 16)
	play_sfx("win")
	save_game()
	return true

func add_float_text(pos: Vector2, content: String, tint: Color) -> void:
	floating_text.append({"pos": pos, "text": content, "tint": tint, "life": 0.8})

func update_floating_text(dt: float) -> void:
	for i in range(floating_text.size() - 1, -1, -1):
		var line: Dictionary = floating_text[i]
		line["pos"] = line["pos"] + Vector2(0, -39.0 * dt)
		line["life"] -= dt
		if line["life"] <= 0.0:
			floating_text.remove_at(i)

func gain_exp(value: int) -> void:
	exp_points += value
	var threshold := level * 55
	while exp_points >= threshold:
		exp_points -= threshold
		level += 1
		max_hp += 14.0
		hp = max_hp
		max_stamina += 4.0
		stamina = max_stamina
		threshold = level * 55
		level_up_glow = 1.35
		spawn_dust(player_pos + Vector2(0, -40), Color("f3dfa1"), 18)
		show_message("LEVEL UP! LV %d" % level, 2.5)

func update_enemies(dt: float) -> void:
	for e in enemies:
		if e["hp"] <= 0.0: continue
		var kind: String = e["type"]
		if BOSS_TYPES.has(kind) and float(e.get("windup", 0.0)) > 0.0:
			e["windup"] = maxf(0.0, float(e["windup"]) - dt)
			if e["windup"] <= 0.0:
				boss_attack(e)
		if kind == "boss" and (quest_stage < 2 or player_pos.x < 7210.0): continue
		if kind != "boss" and BOSS_TYPES.has(kind) and player_pos.x < float(e["origin"]) - 660.0: continue
		e["stun"] = maxf(0.0, e["stun"] - dt)
		e["special_timer"] = maxf(0.0, float(e.get("special_timer", 0.0)) - dt)
		e["charging"] = maxf(0.0, float(e.get("charging", 0.0)) - dt)
		e["cooldown"] -= dt
		e["attack_anim"] = maxf(0.0, e["attack_anim"] - dt)
		var distance: float = player_pos.x - e["x"]
		var abs_distance = absf(distance)
		var active = abs_distance < (700.0 if BOSS_TYPES.has(kind) else 370.0) and absf(player_pos.y - e["y"]) < 270.0
		if BOSS_TYPES.has(kind):
			e["dir"] = 1 if distance > 0.0 else -1
			if e["hp"] < e["max_hp"] * 0.48:
				e["phase"] = 2
			if active and e["cooldown"] <= 0.0 and e["windup"] <= 0.0:
				# Visible telegraph gives mobile players time to guard or dash.
				e["windup"] = 0.55
				e["cooldown"] = 3.5 if e["phase"] == 1 else 2.8
			if active and e["stun"] <= 0.0:
				e["x"] += signf(distance) * (115.0 if e["phase"] == 2 else 67.0) * dt
			if abs_distance < 67.0 and e["cooldown"] < 1.1:
				damage_player(24.0 if e["phase"] == 2 else 16.0)
			continue
		if kind in ["moth", "wisp", "crystal_wisp", "sky_wisp", "cloud_moth", "bog_wisp", "ember_wisp", "coral_wisp", "petal_moth"]:
			e["y"] = FLOOR_Y - (112.0 if kind in ["moth", "cloud_moth", "sky_wisp"] else 84.0) + sin(elapsed * 2.8 + float(e["origin"]) * 0.07) * 23.0
		if e["stun"] > 0.0: continue
		if active and kind in ["beetle", "crystal_bug", "fire_imp", "tide_stalker"]:
			# Charger mobs stop to warn, then dash; unlike ordinary melee pursuit.
			if e["charging"] > 0.0:
				if e["charging"] < 0.28:
					var charge_x: float = e["x"] + float(e["dir"]) * e["speed"] * 4.1 * dt
					if ground_y(charge_x) > 0.0: e["x"] = charge_x
					if absf(player_pos.x - e["x"]) < 52.0:
						damage_player(13.0)
				continue
			if e["cooldown"] <= 0.0 and abs_distance < 290.0:
				e["dir"] = 1 if distance > 0 else -1
				e["charging"] = 0.70
				e["cooldown"] = 3.1
				e["attack_anim"] = 0.58
				continue
		if active and kind in ["sentinel", "ash_knight", "thorn_knight"]:
			# Heavy guards prepare a readable slam with periodic defensive armor.
			e["shielded"] = e["cooldown"] > 1.5
			if e["cooldown"] <= 0.0 and abs_distance < 105.0:
				e["cooldown"] = 2.5
				e["special_timer"] = 0.42
				e["attack_anim"] = 0.6
			if e["special_timer"] > 0.0:
				continue
			if abs_distance < 55.0: damage_player(12.0)
		if active:
			e["dir"] = 1 if distance > 0.0 else -1
			if kind in ["wisp", "crystal_wisp", "sky_wisp", "bog_wisp", "ember_wisp", "coral_wisp"]:
				if abs_distance > 150.0:
					e["x"] += float(e["dir"]) * e["speed"] * dt
				elif abs_distance < 93.0:
					e["x"] -= float(e["dir"]) * e["speed"] * dt
				if e["cooldown"] <= 0.0:
					e["pattern"] = int(e["pattern"]) + 1
					shoot_enemy_bolt(e, 275.0 + float(e["pattern"] % 3) * 31.0, 9.0 + float(e["pattern"] % 2) * 2.0)
					if e["pattern"] % 3 == 0:
						bolts.append({"pos": Vector2(e["x"], e["y"] - 10), "vel": Vector2(float(e["dir"]) * 215.0, -67.0), "ttl": 2.8, "kind": "enemy", "damage": 7.0})
					e["cooldown"] = 2.2
			elif kind in ["moth", "cloud_moth", "petal_moth"]:
				e["x"] += float(e["dir"]) * e["speed"] * dt
				if abs_distance < 43.0 and e["cooldown"] <= 0.0:
					damage_player(9.0)
					e["cooldown"] = 1.1
			else:
				if abs_distance > 38.0:
					var next_x: float = e["x"] + float(e["dir"]) * e["speed"] * dt * (1.7 if kind == "beetle" else 1.0)
					if ground_y(next_x) > 0.0:
						e["x"] = next_x
					else:
						e["dir"] *= -1
				if abs_distance < 49.0 and e["cooldown"] <= 0.0:
					damage_player(14.0 if kind == "sentinel" else 8.0)
					e["cooldown"] = 1.5 if kind == "sentinel" else 1.15
		else:
			if absf(e["x"] - e["origin"]) > 115.0:
				e["dir"] *= -1
			var patrol_x: float = e["x"] + float(e["dir"]) * e["speed"] * 0.34 * dt
			if kind in ["moth", "wisp", "crystal_wisp", "sky_wisp", "cloud_moth", "bog_wisp", "ember_wisp", "coral_wisp", "petal_moth"] or ground_y(patrol_x) > 0.0:
				e["x"] = patrol_x
			else:
				e["dir"] *= -1

func boss_attack(e: Dictionary) -> void:
	# Four genuinely distinct readable attack patterns, rotated each cast. Each
	# boss has the same fair windup but different visual elements and speed.
	var advanced: bool = int(e["phase"]) >= 2
	var attack: int = int(e.get("pattern", 0)) % 4
	e["pattern"] = attack + 1
	e["cooldown"] = (2.0 if advanced else 2.7) + float(attack) * 0.21
	e["attack_anim"] = 0.6
	var kind: String = str(e["type"])
	var tint: Color = Color("f39c5c") if kind in ["cinder_warden", "thornheart"] else (Color("79dbff") if kind in ["abyss_leviathan", "mirror_keeper", "crystal_titan"] else Color("b9a5fa"))
	var shot_kind: String = "cinder" if kind in ["cinder_warden", "thornheart"] else ("tide" if kind in ["abyss_leviathan", "mirror_keeper"] else "enemy")
	var toward: float = 1.0 if player_pos.x >= float(e["x"]) else -1.0
	var origin: Vector2 = Vector2(float(e["x"]), float(e["y"]) - 81.0)
	match attack:
		0:
			# Fan of dodgeable missiles.
			var count: int = 5 if advanced else 3
			for i in range(count):
				var spread: float = -0.34 + float(i) * (0.17 if advanced else 0.34)
				bolts.append({"pos": origin, "vel": Vector2(toward * 250.0, spread * 285.0), "ttl": 2.7, "kind": shot_kind, "damage": 13.0 if advanced else 10.0})
		1:
			# Fast, accurately aimed projectile, slower than the player's dash.
			var aimed: Vector2 = (player_pos - Vector2(0, 35) - origin).normalized()
			bolts.append({"pos": origin, "vel": aimed * (400.0 if advanced else 330.0), "ttl": 2.6, "kind": shot_kind, "damage": 17.0})
		2:
			# Low wave leaves a visible jumpable gap above ground.
			for side in [-1.0, 1.0]:
				bolts.append({"pos": Vector2(e["x"], FLOOR_Y - 19.0), "vel": Vector2(side * (335.0 if advanced else 270.0), 0.0), "ttl": 2.0, "kind": shot_kind, "damage": 13.0})
		3:
			# Brief charge toward player, paired with one high dodgeable orb.
			var destination: float = float(e["x"]) + toward * (145.0 if advanced else 95.0)
			var region: String = REALM_CATALOG.from_x(float(e["x"]))
			var r: Dictionary = REALM_CATALOG.region(region)
			e["x"] = clampf(destination, float(r["start"]) + 150.0, float(r["end"]) - 150.0)
			bolts.append({"pos": origin, "vel": Vector2(toward * 255.0, -145.0), "ttl": 2.7, "kind": shot_kind, "damage": 11.0})
	spawn_dust(origin, tint, 12 if not advanced else 20)

func shoot_enemy_bolt(e: Dictionary, speed: float, damage: float) -> void:
	var start = Vector2(e["x"], e["y"] - 10)
	var direction = (player_pos + Vector2(0, -30) - start).normalized()
	bolts.append({"pos": start, "vel": direction * speed, "ttl": 3.0, "kind": "enemy", "damage": damage})

func update_projectiles(dt: float) -> void:
	for i in range(bolts.size() - 1, -1, -1):
		var b: Dictionary = bolts[i]
		b["pos"] += b["vel"] * dt
		b["ttl"] -= dt
		if b["ttl"] <= 0.0:
			bolts.remove_at(i)
			continue
		var impacted = false
		if b["kind"] == "hero":
			for e in enemies:
				if e["hp"] > 0.0 and absf(b["pos"].x - e["x"]) < (62.0 if BOSS_TYPES.has(e["type"]) else 28.0) and absf(b["pos"].y - e["y"] + 34.0) < 64.0:
					hit_enemy(e, b["damage"])
					impacted = true
					break
		else:
			if b["pos"].distance_to(player_pos + Vector2(0, -29)) < 29.0:
				damage_player(b["damage"])
				impacted = true
		if impacted:
			spawn_dust(b["pos"], Color(0.4, 0.9, 1.0), 5)
			bolts.remove_at(i)

func update_loot(dt: float) -> void:
	for i in range(loot.size() - 1, -1, -1):
		var item: Dictionary = loot[i]
		item["t"] += dt
		# Aether Seeds magnetize toward the hero and have a forgiving pickup radius on phones.
		if item["kind"] == "seed":
			var seed_center: Vector2 = item["pos"] + Vector2(0, 23)
			if player_pos.distance_to(seed_center) < 170.0:
				var seed_pos: Vector2 = item["pos"]
				item["pos"] = seed_pos.move_toward(player_pos - Vector2(0, 23), 380.0 * dt)
		var pickup_radius := 112.0 if item["kind"] == "seed" else 82.0
		if player_pos.distance_to(item["pos"] + Vector2(0, 23)) < pickup_radius:
			match item["kind"]:
				"coin": coins += item["amount"]
				"seed":
					if seeds < 3:
						seeds = mini(3, seeds + int(item.get("amount", 1)))
						record_quest_event("seed")
						if quest_stage == 1 and seeds >= 3:
							quest_stage = 2
							show_message("All 3 Aether Seeds found! The Ruins gate is open.", 4.0)
						elif quest_stage == 0:
							show_message("Aether Seed %d / 3 - Talk to Mira in the village!" % seeds, 3.0)
						else:
							show_message("Aether Seed %d / 3" % seeds, 2.3)
						save_game()
				"potion": potions += 1
			play_sfx("loot")
			loot.remove_at(i)

func update_particles(dt: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p["pos"] += p["vel"] * dt
		var current_velocity: Vector2 = p["vel"]
		current_velocity.y += 370.0 * dt
		p["vel"] = current_velocity
		p["life"] -= dt
		if p["life"] <= 0.0:
			particles.remove_at(i)

func spawn_dust(pos: Vector2, tint: Color, amount: int = 7) -> void:
	if graphics_quality == 0: amount = mini(amount, 4)
	elif graphics_quality == 1: amount = mini(amount, 13)
	for i in amount:
		particles.append({"pos": pos, "vel": Vector2(rng.randf_range(-115, 115), rng.randf_range(-180, 0)), "life": rng.randf_range(0.26, 0.55), "color": tint})

func update_camera() -> void:
	# True independent realm camera bounds. No adjacent world/map seam can enter view.
	var camera_half: float = get_viewport().get_visible_rect().size.x * 0.5 / maxf(0.1, camera.zoom.x)
	var region: Dictionary = current_realm()
	var safe_min: float = float(region["start"]) + camera_half
	var safe_max: float = float(region["end"]) - camera_half
	var desired: float = clampf(player_pos.x, safe_min, maxf(safe_min, safe_max))
	camera.position = Vector2(desired, 322.0)
	if screen_shake > 0.0:
		camera.offset = Vector2(rng.randf_range(-4, 4), rng.randf_range(-3, 3))
	else:
		camera.offset = Vector2.ZERO

func show_message(line: String, duration: float = 2.5) -> void:
	message = line
	message_time = duration

func register_ember_hunt(kind: String) -> void:
	if not kind in ["fire_imp", "ash_knight", "ember_wisp"]: return
	var limit: int = 3 if kind == "fire_imp" else (2 if kind == "ash_knight" else 2)
	var total: int = int(ember_hunt_counts.get(kind, 0)) + 1
	ember_hunt_counts[kind] = total
	if total >= limit and not ember_hunt_claimed.has(kind):
		ember_hunt_claimed.append(kind)
		coins += 85
		relic_shards += 1
		show_message("%s HUNT COMPLETE! +85 COINS AND 1 RELIC" % kind.replace("_", " ").to_upper(), 4.0)
		save_game()

func v2_quest_label() -> String:
	if not expansion_completed: return "CHAPTER II: Restore Shadowfen to reach Emberfall"
	if not emberling_unlocked: return "EMBERFALL: Rescue Emberling at the ruined watchtower"
	if not ember_boss_defeated: return "CINDER VAULT: Defeat the Cinder Warden in the forge dungeon"
	return "EMBERFALL RESTORED: Explore and solve optional braziers"

func nearby_ember_brazier() -> int:
	if player_pos.x < EMBER_START: return -1
	for i in range(EMBER_BRAZIERS.size()):
		if ember_braziers.has(i): continue
		if absf(player_pos.x - EMBER_BRAZIERS[i]) < 98.0 and absf(player_pos.y - FLOOR_Y) < 130.0:
			return i
	return -1

func open_ember_brazier(index: int) -> bool:
	if state != "playing" or index < 0 or index >= EMBER_BRAZIERS.size() or ember_braziers.has(index):
		return false
	if absf(player_pos.x - EMBER_BRAZIERS[index]) > 104.0: return false
	state = "ember_puzzle"
	ember_puzzle_index = index
	ember_puzzle_progress = 0
	ember_puzzle_feedback = "READ THE CLUE. HINT AND EXIT ARE ALWAYS AVAILABLE."
	touch_axis = 0.0
	joystick_touch = -1
	attack_touch.clear()
	hold_attack = false
	return true

func leave_ember_puzzle() -> void:
	ember_puzzle_index = -1
	ember_puzzle_progress = 0
	state = "playing"
	ember_puzzle_feedback = ""
	update_camera()

func select_ember_rune(choice: int) -> bool:
	if state != "ember_puzzle" or ember_puzzle_index < 0 or choice < 0 or choice > 2:
		return false
	var pattern: Array = EMBER_RUNE_PATTERNS[ember_puzzle_index]
	if int(pattern[ember_puzzle_progress]) != choice:
		ember_puzzle_progress = 0
		ember_puzzle_feedback = "NOT QUITE. RETRY WITHOUT PENALTY OR USE THE HINT."
		return false
	ember_puzzle_progress += 1
	play_sfx("loot")
	if ember_puzzle_progress < 3:
		ember_puzzle_feedback = "CORRECT! %d / 3 RUNES" % ember_puzzle_progress
		return true
	var completed: int = ember_puzzle_index
	if not ember_braziers.has(completed):
		ember_braziers.append(completed)
		coins += 100
		relic_shards += 1
		show_message("BRAZIER RESTORED! +100 coins and +1 relic", 4.0)
		save_game()
	ember_puzzle_index = -1
	ember_puzzle_progress = 0
	state = "playing"
	spawn_dust(Vector2(EMBER_BRAZIERS[completed], FLOOR_Y - 60), Color("ffbc74"), 20)
	return true

func rescue_emberling() -> bool:
	if state != "playing" or not expansion_completed or emberling_unlocked or absf(player_pos.x - 16870.0) > 105.0:
		return false
	emberling_unlocked = true
	emberling_active = true
	record_quest_event("rescue:emberling")
	emberling_pos = player_pos + Vector2(-55, -95)
	emberling_attack_cooldown = 0.7
	show_message("EMBERLING RESCUED! Your companion follows and protects you.", 4.0)
	play_sfx("win")
	save_game()
	return true

func toggle_emberling() -> void:
	if not emberling_unlocked: return
	emberling_active = not emberling_active
	show_message("EMBERLING: %s" % ("FOLLOWING" if emberling_active else "RESTING"), 2.2)
	save_game()

func update_emberling(dt: float) -> void:
	if not emberling_unlocked or not emberling_active: return
	var target: Vector2 = player_pos + Vector2(-65.0 * float(facing), -97.0 + sin(elapsed * 3.0) * 9.0)
	if emberling_pos.distance_to(target) > 500.0: emberling_pos = target
	else: emberling_pos = emberling_pos.lerp(target, minf(1.0, dt * 4.5))
	emberling_attack_cooldown = maxf(0.0, emberling_attack_cooldown - dt)
	if emberling_attack_cooldown > 0.0: return
	for e in enemies:
		if e["hp"] <= 0.0 or (e["type"] == "boss" and quest_stage < 2): continue
		if absf(float(e["x"]) - player_pos.x) > 290.0: continue
		emberling_attack_cooldown = 2.0
		emberling_attacks += 1
		spawn_dust(Vector2(float(e["x"]), float(e["y"]) - 45), Color("ffb36d"), 8)
		hit_enemy(e, 11.0 + float(level) * 2.0)
		return

func load_realm_stage(id: String) -> void:
	var target: String = id if not REALM_CATALOG.region(id).is_empty() else "hub"
	if is_instance_valid(realm_stage):
		realm_stage.queue_free()
		realm_stage = null
	var packed: PackedScene = ResourceLoader.load("res://scenes/realms/%s.tscn" % target) as PackedScene
	if packed != null:
		realm_stage = packed.instantiate()
		add_child(realm_stage)
	current_realm_id = target
	queue_redraw()

func current_realm() -> Dictionary:
	return REALM_CATALOG.region(current_realm_id)

func realign_realm_to_position() -> void:
	# Preserve old v1/v2 test/save teleport checkpoints; normal running never
	# crosses a realm border, only explicit portal travel can.
	var region: Dictionary = current_realm()
	if region.is_empty(): return
	if player_pos.x < float(region["start"]) - 125.0 or player_pos.x > float(region["end"]) + 125.0:
		var aligned: String = REALM_CATALOG.from_x(player_pos.x)
		if aligned != current_realm_id:
			load_realm_stage(aligned)

func is_realm_unlocked(id: String) -> bool:
	if id in ["hub", "forest"]: return true
	if id == "ruins": return quest_stage >= 2 or defeated_boss
	if id == "crystal": return defeated_boss
	if id == "sky": return world_bosses_cleared[0]
	if id == "marsh": return world_bosses_cleared[1]
	if id == "ember": return expansion_completed
	if id == "abyss": return ember_boss_defeated
	if id == "garden": return dungeon_clears.has("tide_temple")
	if id == "nexus": return dungeon_clears.has("verdant_vault")
	var region: Dictionary = REALM_CATALOG.region(id)
	if region.is_empty(): return false
	if region["kind"] in ["dungeon", "trial"]:
		return is_realm_unlocked(str(region["parent"]))
	return false

func enter_realm(id: String) -> bool:
	var destination: Dictionary = REALM_CATALOG.region(id)
	if destination.is_empty() or not is_realm_unlocked(id):
		show_message("REALM LOCKED: Complete the previous chapter.", 3.0)
		return false
	load_realm_stage(id)
	player_pos = Vector2(float(destination["arrival"]), FLOOR_Y)
	checkpoint_x = player_pos.x
	velocity = Vector2.ZERO
	jump_count = 0
	coyote_timer = 0.0
	touch_axis = 0.0
	joystick_touch = -1
	attack_touch.clear()
	hold_attack = false
	bolts.clear()
	loot.clear()
	portal_cooldown = 1.0
	invincible = maxf(invincible, 1.7)
	realm_transition = 0.85
	state = "playing"
	boss_alert = ""
	if not discovered_realm_ids.has(id):
		discovered_realm_ids.append(id)
		if not REALM_CATALOG.story(id).is_empty() and not story_seen.has(id):
			story_seen.append(id)
			story_queue = REALM_CATALOG.story(id).duplicate()
			advance_story_dialogue()
	map_visit_counts[id] = int(map_visit_counts.get(id, 0)) + 1
	record_quest_event("visit:" + id)
	update_camera()
	camera.reset_smoothing()
	show_message("PORTAL ARRIVAL: " + str(destination["name"]), 3.0)
	play_sfx("skill")
	save_game()
	return true

func advance_story_dialogue() -> void:
	if story_queue.is_empty():
		dialogue = ""
		return
	dialogue = str(story_queue.pop_front())

func trial_side_room(id: String) -> String:
	for trial in REALM_CATALOG.TRIALS:
		if str(REALM_CATALOG.TRIALS[trial]["parent"]) == id:
			return str(trial)
	return ""

func nearby_trial_pedestal() -> bool:
	var info: Dictionary = current_realm()
	if str(info.get("kind", "")) != "trial" or trial_completed.has(current_realm_id):
		return false
	var x: float = float(info["start"]) + 1530.0
	return absf(player_pos.x - x) < 116.0 and absf(player_pos.y - FLOOR_Y) < 130.0

func open_trial_puzzle() -> bool:
	if state != "playing" or not nearby_trial_pedestal():
		return false
	var info: Dictionary = REALM_CATALOG.TRIALS.get(current_realm_id, {})
	if info.is_empty(): return false
	trial_puzzle_id = current_realm_id
	trial_puzzle = PUZZLE_ENGINE.make(trial_puzzle_id, str(info["type"]))
	trial_hint_text = "NO TIME LIMIT • HINTS AVAILABLE • EXIT ANYTIME"
	trial_preview_time = 4.5
	touch_axis = 0.0
	joystick_touch = -1
	attack_touch.clear()
	hold_attack = false
	state = "v6_puzzle"
	return true

func press_trial_cell(cell: int) -> bool:
	if state != "v6_puzzle" or trial_puzzle.is_empty(): return false
	var changed: bool = PUZZLE_ENGINE.press(trial_puzzle, cell)
	if changed and bool(trial_puzzle.get("solved", false)):
		finish_trial_puzzle()
	return changed

func trial_hint() -> void:
	if state != "v6_puzzle": return
	trial_hint_text = PUZZLE_ENGINE.hint(trial_puzzle)
	trial_preview_time = 3.5

func trial_restart() -> void:
	if state != "v6_puzzle": return
	trial_puzzle = PUZZLE_ENGINE.make(trial_puzzle_id, str(REALM_CATALOG.TRIALS[trial_puzzle_id]["type"]))
	trial_preview_time = 4.5
	trial_hint_text = "PUZZLE RESTARTED. NO DAMAGE OR RESOURCE COST."

func leave_trial_puzzle() -> void:
	trial_puzzle_id = ""
	trial_puzzle.clear()
	trial_preview_time = 0.0
	trial_hint_text = ""
	state = "playing"
	touch_axis = 0.0
	update_camera()

func finish_trial_puzzle() -> void:
	if trial_puzzle_id == "" or trial_completed.has(trial_puzzle_id):
		leave_trial_puzzle()
		return
	var cleared: String = trial_puzzle_id
	var info: Dictionary = REALM_CATALOG.TRIALS[cleared]
	trial_completed.append(cleared)
	var rewards: int = int(info.get("reward", 105))
	coins += rewards
	relic_shards += 1
	gain_exp(100)
	record_quest_event("trial:" + cleared)
	leave_trial_puzzle()
	level_up_glow = 1.1
	spawn_dust(player_pos + Vector2(0.0, -80.0), Color("a4f9e1"), 18)
	show_message("CHAMBER RESTORED! +%d COINS & 1 RELIC SHARD" % rewards, 4.0)
	save_game()

func nearby_stage_portal() -> String:
	if portal_cooldown > 0.0: return ""
	var region: Dictionary = current_realm()
	if region.is_empty(): return ""
	var start_gate: float = 1720.0 if current_realm_id == "hub" else float(region["start"]) + 145.0
	if absf(player_pos.x - start_gate) < 69.0 and absf(player_pos.y - FLOOR_Y) < 142.0:
		return str(region["parent"]) if region["kind"] in ["dungeon", "trial"] else "network"
	if region["kind"] == "dungeon":
		var side_id: String = trial_side_room(current_realm_id)
		if side_id != "":
			var side_gate_x: float = float(region["start"]) + (float(region["end"]) - float(region["start"])) * 0.58
			if absf(player_pos.x - side_gate_x) < 74.0 and absf(player_pos.y - FLOOR_Y) < 135.0:
				return side_id
	if region["kind"] == "realm" and str(region["dungeon"]) != "":
		var dungeon_gate: float = float(region["end"]) - 85.0
		if absf(player_pos.x - dungeon_gate) < 55.0 and absf(player_pos.y - FLOOR_Y) < 140.0:
			return str(region["dungeon"])
	return ""

func nearby_story_npc() -> bool:
	var region: Dictionary = current_realm()
	return region.get("kind", "") != "hub" and absf(player_pos.x - float(region.get("start", 0.0)) - 610.0) < 92.0 and absf(player_pos.y - FLOOR_Y) < 125.0

func pinned_quest() -> Dictionary:
	if tracked_quest_id != "":
		for q in REALM_CATALOG.QUESTS:
			if str(q["id"]) == tracked_quest_id and not quest_claimed.has(tracked_quest_id):
				return q
	# A finished pinned quest automatically falls through to the next available
	# objective. Never show stale completed progress during combat.
	for q in REALM_CATALOG.QUESTS:
		if not quest_claimed.has(str(q["id"])) and is_realm_unlocked(str(q["region"])):
			return q
	return {}

func pin_quest(id: String) -> bool:
	for q in REALM_CATALOG.QUESTS:
		if str(q["id"]) == id and not quest_claimed.has(id):
			tracked_quest_id = id
			save_game()
			return true
	return false

func clear_quest_pin() -> void:
	tracked_quest_id = ""
	save_game()

func record_quest_event(event_id: String, amount: int = 1) -> void:
	for quest in REALM_CATALOG.QUESTS:
		if str(quest["event"]) != event_id or quest_claimed.has(str(quest["id"])):
			continue
		var id: String = str(quest["id"])
		var count: int = mini(int(quest["target"]), int(quest_counts.get(id, 0)) + maxi(0, amount))
		quest_counts[id] = count
		if count >= int(quest["target"]):
			quest_claimed.append(id)
			if tracked_quest_id == id:
				tracked_quest_id = ""
			coins += int(quest["coins"])
			gain_exp(int(quest["exp"]))
			show_message("QUEST COMPLETE: %s (+%d coins)" % [str(quest["title"]), int(quest["coins"])], 4.0)
			save_game()

func quest_progress(quest: Dictionary) -> int:
	return int(quest_counts.get(str(quest["id"]), 0))

func quest_total() -> int:
	return REALM_CATALOG.QUESTS.size()

func unlocked_portal_count() -> int:
	var count := 0
	for available in portal_unlocked:
		if available:
			count += 1
	return count

func nearby_portal_index() -> int:
	for i in range(PORTAL_LOCATIONS.size()):
		if absf(player_pos.x - PORTAL_LOCATIONS[i]) < 110.0 and absf(player_pos.y - FLOOR_Y) < 130.0:
			return i
	return -1

func portal_jump(index: int) -> bool:
	# Backwards-compatible API used by old Android saves and regression tests.
	if state != "portals" or index < 0 or index >= PORTAL_ARRIVALS.size() or not portal_unlocked[index]:
		return false
	var destinations := ["hub", "crystal", "sky", "marsh", "ember"]
	return enter_realm(destinations[index])

func go_expansion_world() -> void:
	if not defeated_boss:
		return
	portal_unlocked[1] = true
	state = "playing"
	# Reuse the same travel method so save/checkpoint handling cannot diverge.
	state = "portals"
	portal_jump(1)

func boss_display_name(kind: String) -> String:
	var index := BOSS_TYPES.find(kind)
	return WORLD_BOSS_NAMES[index] if index >= 0 else "UNKNOWN GUARDIAN"

func active_boss_info() -> Dictionary:
	for e in enemies:
		if BOSS_TYPES.has(e["type"]) and e["hp"] > 0.0 and absf(float(e["x"]) - player_pos.x) < 640.0:
			if e["type"] != "boss" or quest_stage >= 2:
				return e
	return {}

func expansion_quest_label() -> String:
	if not defeated_boss:
		return "NEW REALMS: Defeat the Warden to activate the Portal Network"
	if not world_bosses_cleared[0]:
		return "NEW REALMS: Enter Crystal Hollow and defeat the Crystal Titan"
	if not world_bosses_cleared[1]:
		return "NEW REALMS: Travel to the Highlands and defeat the Sky Herald"
	if not world_bosses_cleared[2]:
		return "NEW REALMS: Explore Shadowfen and defeat its Guardian"
	return "NEW REALMS: All three worlds restored! Explore freely"

func nearby_shrine_index() -> int:
	for i in range(ECHO_SHRINES.size()):
		if not awakened_shrines.has(i) and absf(player_pos.x - ECHO_SHRINES[i]) < 92.0 and absf(player_pos.y - FLOOR_Y) < 135.0:
			return i
	return -1

func open_echo_puzzle(index: int) -> bool:
	if state != "playing" or index < 0 or index >= ECHO_SHRINES.size() or awakened_shrines.has(index):
		return false
	if absf(player_pos.x - ECHO_SHRINES[index]) >= 100.0:
		return false
	puzzle_index = index
	puzzle_progress = 0
	puzzle_feedback = "FOLLOW THE CLUE. WRONG ANSWERS HAVE NO PENALTY."
	state = "puzzle"
	touch_axis = 0.0
	joystick_touch = -1
	hold_attack = false
	attack_touch.clear()
	play_sfx("loot")
	return true

func leave_echo_puzzle() -> void:
	# Optional challenges can be exited instantly, without changing game progress.
	puzzle_index = -1
	puzzle_progress = 0
	state = "playing"
	puzzle_feedback = ""
	update_camera()

func choose_echo_rune(choice: int) -> bool:
	if state != "puzzle" or puzzle_index < 0 or choice < 0 or choice > 2:
		return false
	var sequence: Array = ECHO_PATTERNS[puzzle_index]
	if choice != int(sequence[puzzle_progress]):
		puzzle_progress = 0
		puzzle_feedback = "NOT QUITE. TRY THE CLUE AGAIN - NO PENALTY."
		play_sfx("hit")
		return false
	puzzle_progress += 1
	play_sfx("loot")
	if puzzle_progress < 3:
		puzzle_feedback = "RUNE %d / 3 CORRECT!" % puzzle_progress
		return true
	var solved_index: int = puzzle_index
	if not awakened_shrines.has(solved_index):
		awakened_shrines.append(solved_index)
		coins += 55
		max_hp += 6.0
		hp = max_hp
		level_up_glow = 1.3
		spawn_dust(Vector2(ECHO_SHRINES[solved_index], FLOOR_Y - 90.0), Color("c5fff2"), 24)
		show_message("ECHO AWAKENED! +55 COINS, +6 MAX HP", 3.3)
		save_game()
	puzzle_index = -1
	puzzle_progress = 0
	state = "playing"
	dialogue = "AETHER MEMORY: " + str(ECHO_LORE[solved_index])
	play_sfx("win")
	return true

func save_visual_preferences() -> void:
	var file := FileAccess.open(VISUALS_FILE, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"quality": graphics_quality, "reduce_motion": reduced_motion}))
		file.close()

func load_visual_preferences() -> void:
	if not FileAccess.file_exists(VISUALS_FILE):
		return
	var file := FileAccess.open(VISUALS_FILE, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary:
		graphics_quality = clampi(int(data.get("quality", 1)), 0, 2)
		reduced_motion = bool(data.get("reduce_motion", false))

func cycle_graphics_quality() -> void:
	graphics_quality = (graphics_quality + 1) % 3
	save_visual_preferences()
	show_message("GRAPHICS: %s" % ["LOW", "BALANCED", "HIGH"][graphics_quality], 2.0)

func toggle_reduced_motion() -> void:
	reduced_motion = not reduced_motion
	save_visual_preferences()

func hero_animation_pose() -> String:
	if state == "defeat" or hp <= 0.0: return "defeat"
	if hero_impact > 0.0: return "hit"
	if dash_timer > 0.0: return "dash"
	if guard_window > 0.0: return "guard"
	if slash_timer > 0.0: return "attack"
	if healing_glow > 0.0: return "heal"
	if not on_ground: return "jump"
	if absf(velocity.x) > 45.0: return "run"
	return "idle"

func hero_animation_params() -> Dictionary:
	# Real-time procedural poses reuse existing original hero pixel art.
	var pose: String = hero_animation_pose()
	var offset := Vector2.ZERO
	var angle := 0.0
	var squash := Vector2.ONE
	if reduced_motion: return {"pose": pose, "offset": offset, "angle": angle, "squash": squash}
	match pose:
		"idle":
			offset.y = sin(elapsed * 2.8) * 2.3
			angle = sin(elapsed * 1.2) * 0.02
		"run":
			offset.y = -absf(sin(elapsed * 13.0)) * 6.0
			angle = sin(elapsed * 13.0) * 0.05
		"attack":
			angle = -0.23 if combo_stage == 3 else 0.13
			offset.x = 7.0 * float(facing)
		"dash": squash = Vector2(1.32, 0.86)
		"guard": squash = Vector2(0.89, 1.08)
		"heal": offset.y = -3.0 * sin(elapsed * 10.0)
		"hit": angle = sin(elapsed * 35.0) * 0.10
		"jump": angle = clampf(velocity.y / 2600.0, -0.16, 0.16)
	return {"pose": pose, "offset": offset, "angle": angle, "squash": squash}

func nearby_npc() -> String:
	if nearby_stage_portal() != "": return "portal"
	if nearby_trial_pedestal(): return "trial_puzzle"
	if nearby_story_npc(): return "story"
	if nearby_portal_index() >= 0: return "portal"
	if nearby_ember_brazier() >= 0: return "ember_brazier"
	if expansion_completed and not emberling_unlocked and absf(player_pos.x - 16870.0) < 105.0: return "emberling"
	if nearby_shrine_index() >= 0: return "shrine"
	if nearby_cache_index() >= 0: return "cache"
	if absf(player_pos.x - 415.0) < 105.0: return "mira"
	if absf(player_pos.x - 1030.0) < 105.0: return "merchant"
	if absf(player_pos.x - 1510.0) < 100.0: return "scout"
	if absf(player_pos.x - 6160.0) < 112.0: return "gate"
	return ""

func interact() -> void:
	if state != "playing": return
	if nearby_trial_pedestal():
		open_trial_puzzle()
		return
	var stage_gate: String = nearby_stage_portal()
	if stage_gate != "":
		if stage_gate == "network":
			state = "portals"
			portal_page = 0
		else:
			enter_realm(stage_gate)
		return
	if nearby_story_npc():
		var scenes: Array = REALM_CATALOG.story(current_realm_id)
		story_queue = scenes.duplicate()
		advance_story_dialogue()
		record_quest_event("talk:" + current_realm_id)
		return
	if nearby_ember_brazier() >= 0:
		open_ember_brazier(nearby_ember_brazier())
		return
	if expansion_completed and not emberling_unlocked and absf(player_pos.x - 16870.0) < 105.0:
		rescue_emberling()
		return
	if nearby_shrine_index() >= 0:
		open_echo_puzzle(nearby_shrine_index())
		return
	if nearby_portal_index() >= 0:
		var index: int = nearby_portal_index()
		if index > 0 and not portal_unlocked[index]:
			show_message("This portal is sealed. Defeat the preceding realm guardian!", 3.0)
		elif index == 0 and not defeated_boss:
			show_message("Portal Network inactive. Defeat the Star Warden first!", 3.0)
		else:
			state = "portals"
		return
	if nearby_cache_index() >= 0:
		open_cache(nearby_cache_index())
		return
	if dialogue != "":
		advance_story_dialogue()
		return
	match nearby_npc():
		"mira":
			record_quest_event("talk:mira")
			if quest_stage == 0:
				# Keep seeds already collected before talking to Mira.
				quest_stage = 2 if seeds >= 3 else 1
				dialogue = "MIRA: You already collected all 3 seeds! The Aether Gate is open." if quest_stage == 2 else "MIRA: Find 3 glowing seeds from the moss slimes in Whisperwood. You have %d / 3 already." % seeds
				save_game()
			elif quest_stage == 1:
				dialogue = "MIRA: Listen to the forest. Defeat the moss slimes to gather %d more Aether Seeds." % maxi(0, 3 - seeds)
			elif quest_stage == 2:
				dialogue = "MIRA: You hold the seeds! Pass through the sealed gate east of the ruins. Strike the Warden between attacks."
			else:
				dialogue = "MIRA: The Aether shines again. The valley remembers your courage. Thank you, guardian."
		"merchant": state = "shop"
		"scout": state = "trainer"
		"gate":
			if quest_stage < 2: show_message("The ancient gate demands 3 Aether Seeds.", 2.8)
			else: show_message("The star-shaped seal opens to your touch.", 2.8)

func buy_shop_item(which: int) -> void:
	if state != "shop": return
	var cost := 20 if which == 0 else (85 * sword_level if which == 1 else 80 * armor_level)
	if coins < cost:
		show_message("Not enough starlight coins!", 2.0)
		return
	if which == 1 and sword_level >= 5 or which == 2 and armor_level >= 5:
		show_message("Already fully upgraded!", 2.0)
		return
	coins -= cost
	match which:
		0: potions += 1
		1: sword_level += 1
		2:
			armor_level += 1
			max_hp += 10.0
			hp += 10.0
	show_message("Purchase complete!", 1.6)
	save_game()

func start_new_game() -> void:
	player_pos = Vector2(145, FLOOR_Y)
	velocity = Vector2.ZERO
	facing = 1
	touch_axis = 0.0
	joystick_touch = -1
	attack_touch.clear()
	hold_attack = false
	skill_timer = 0.0
	guard_window = 0.0
	guard_cooldown = 0.0
	combo_stage = 0
	combo_timer = 0.0
	total_kills = 0
	mastery_rewards.clear()
	awakened_shrines.clear()
	ember_braziers.clear()
	ember_boss_defeated = false
	emberling_unlocked = false
	emberling_active = true
	emberling_attacks = 0
	ember_hunt_counts.clear()
	ember_hunt_claimed.clear()
	emberling_pos = Vector2.ZERO
	ember_puzzle_index = -1
	ember_puzzle_progress = 0
	puzzle_index = -1
	puzzle_progress = 0
	dash_cooldown = 0.0
	dash_timer = 0.0
	attack_timer = 0.0
	hp = 100.0
	max_hp = 100.0
	stamina = 100.0
	max_stamina = 100.0
	level = 1
	exp_points = 0
	coins = 35
	potions = 2
	sword_level = 1
	armor_level = 1
	seeds = 0
	quest_stage = 0
	relic_shards = 0
	opened_caches.clear()
	rune_upgrades = [false, false, false]
	jump_count = 0
	hunted_moths = 0
	hunted_sentinels = 0
	claimed_hunts.clear()
	floating_text.clear()
	portal_unlocked = [true, false, false, false, false]
	current_realm_id = "hub"
	trial_completed.clear()
	trial_puzzle.clear()
	trial_puzzle_id = ""
	quest_counts.clear()
	quest_claimed.clear()
	discovered_realm_ids = ["hub"]
	dungeon_clears.clear()
	story_seen.clear()
	story_queue.clear()
	enemy_kill_counts.clear()
	map_visit_counts.clear()
	realm_transition = 0.0
	portal_page = 0
	journal_page = 0
	tracked_quest_id = ""
	world_bosses_cleared = [false, false, false]
	expansion_completed = false
	coyote_timer = 0.0
	portal_cooldown = 0.0
	checkpoint_x = 145.0
	defeated_boss = false
	bolts.clear()
	loot.clear()
	particles.clear()
	spawn_enemies()
	load_realm_stage("hub")
	state = "playing"
	dialogue = ""
	show_message("ECHOES OF AETHER — Talk to Mira to begin your journey!", 5.0)
	update_camera()
	camera.reset_smoothing()
	save_game()

func continue_game() -> void:
	if not load_game():
		start_new_game()
	else:
		state = "playing"
		player_pos = Vector2(checkpoint_x, FLOOR_Y)
		velocity = Vector2.ZERO
		jump_count = 0
		hp = maxf(35.0, hp)
		dialogue = ""
		show_message("Journey restored at your last checkpoint.", 2.7)
		update_camera()
		camera.reset_smoothing()

func respawn() -> void:
	state = "playing"
	hp = max_hp
	stamina = max_stamina
	velocity = Vector2.ZERO
	jump_count = 0
	player_pos = Vector2(checkpoint_x, FLOOR_Y)
	invincible = 1.4
	bolts.clear()
	spawn_enemies()
	show_message("The Aether rekindles your spirit.", 3.0)

func save_game() -> void:
	var values = {"max_hp": max_hp, "hp": hp, "level": level, "exp": exp_points,
		"coins": coins, "potions": potions, "sword": sword_level, "armor": armor_level,
		"stamina_max": max_stamina, "seeds": seeds, "quest": quest_stage,
		"checkpoint": checkpoint_x, "boss": defeated_boss, "sound": sound_on,
		"music": music_on,
		"relic_shards": relic_shards, "opened_caches": opened_caches, "rune_upgrades": rune_upgrades,
		"hunt_moths": hunted_moths, "hunt_sentinels": hunted_sentinels,
		"claimed_hunts": claimed_hunts,
		"portal_unlocked": portal_unlocked, "world_bosses_cleared": world_bosses_cleared,
		"expansion_completed": expansion_completed,
		"total_kills": total_kills, "mastery_rewards": mastery_rewards,
		"awakened_shrines": awakened_shrines,
		"ember_boss_defeated": ember_boss_defeated, "ember_braziers": ember_braziers,
		"emberling_unlocked": emberling_unlocked, "emberling_active": emberling_active,
		"ember_hunts": ember_hunt_counts, "ember_hunt_claimed": ember_hunt_claimed,
		"active_realm": current_realm_id, "quest_counts": quest_counts,
		"trial_completed": trial_completed,
		"tracked_quest_id": tracked_quest_id,
		"quest_claimed": quest_claimed, "discovered_realms": discovered_realm_ids,
		"dungeon_clears": dungeon_clears, "story_seen": story_seen,
		"kill_counts": enemy_kill_counts, "map_visits": map_visit_counts,
		"save_version": V6_SAVE_VERSION}
	var file = FileAccess.open("user://aether_save.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(values))
		file.close()

func has_save() -> bool:
	return FileAccess.file_exists("user://aether_save.json")

func load_game() -> bool:
	if not has_save(): return false
	var file = FileAccess.open("user://aether_save.json", FileAccess.READ)
	if file == null: return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary: return false
	var data: Dictionary = parsed
	max_hp = float(data.get("max_hp", 100))
	hp = float(data.get("hp", max_hp))
	level = int(data.get("level", 1))
	exp_points = int(data.get("exp", 0))
	coins = int(data.get("coins", 35))
	potions = int(data.get("potions", 2))
	sword_level = int(data.get("sword", 1))
	armor_level = int(data.get("armor", 1))
	max_stamina = float(data.get("stamina_max", 100))
	stamina = max_stamina
	seeds = int(data.get("seeds", 0))
	quest_stage = int(data.get("quest", 0))
	# Legacy v1 saves do not contain relic data.
	relic_shards = maxi(0, int(data.get("relic_shards", 0)))
	opened_caches = data.get("opened_caches", [])
	rune_upgrades = data.get("rune_upgrades", [false, false, false])
	if rune_upgrades.size() != 3:
		rune_upgrades = [false, false, false]
	hunted_moths = int(data.get("hunt_moths", 0))
	hunted_sentinels = int(data.get("hunt_sentinels", 0))
	claimed_hunts = data.get("claimed_hunts", [])
	# Version 1/2 saves unlock Crystal Hollow if the old Star Warden is defeated.
	var old_boss: bool = bool(data.get("boss", false))
	portal_unlocked = data.get("portal_unlocked", [true, old_boss, false, false, false])
	world_bosses_cleared = data.get("world_bosses_cleared", [false, false, false])
	# Extend v1's four portals to five without resetting unlock progress.
	if portal_unlocked.size() == 4:
		portal_unlocked.append(false)
	elif portal_unlocked.size() != 5:
		portal_unlocked = [true, old_boss, false, false, false]
	if world_bosses_cleared.size() != 3:
		world_bosses_cleared = [false, false, false]
	portal_unlocked[0] = true
	if old_boss:
		portal_unlocked[1] = true
	if world_bosses_cleared[0]:
		portal_unlocked[2] = true
	if world_bosses_cleared[1]:
		portal_unlocked[3] = true
	expansion_completed = bool(data.get("expansion_completed", false)) or bool(world_bosses_cleared[2])
	portal_unlocked[4] = expansion_completed
	ember_boss_defeated = bool(data.get("ember_boss_defeated", false))
	ember_braziers.clear()
	var saved_braziers = data.get("ember_braziers", [])
	if saved_braziers is Array:
		for entry in saved_braziers:
			var index: int = int(entry)
			if index >= 0 and index < EMBER_BRAZIERS.size() and not ember_braziers.has(index):
				ember_braziers.append(index)
	ember_hunt_counts.clear()
	var raw_ember_hunts = data.get("ember_hunts", {})
	if raw_ember_hunts is Dictionary:
		for kind in ["fire_imp", "ash_knight", "ember_wisp"]:
			ember_hunt_counts[kind] = maxi(0, int(raw_ember_hunts.get(kind, 0)))
	ember_hunt_claimed.clear()
	var raw_claimed = data.get("ember_hunt_claimed", [])
	if raw_claimed is Array:
		for kind in raw_claimed:
			if str(kind) in ["fire_imp", "ash_knight", "ember_wisp"] and not ember_hunt_claimed.has(str(kind)):
				ember_hunt_claimed.append(str(kind))
	emberling_unlocked = bool(data.get("emberling_unlocked", false))
	emberling_active = bool(data.get("emberling_active", true))
	emberling_pos = Vector2.ZERO
	emberling_attack_cooldown = 0.5
	ember_puzzle_index = -1
	ember_puzzle_progress = 0
	total_kills = maxi(0, int(data.get("total_kills", 0)))
	# JSON numeric arrays can contain floats; normalize milestone IDs to integers
	# before using Array.has(), so the reward never repeats after reopening the app.
	mastery_rewards.clear()
	awakened_shrines.clear()
	var shrine_data = data.get("awakened_shrines", [])
	if shrine_data is Array:
		for item in shrine_data:
			var idx: int = int(item)
			if idx >= 0 and idx < ECHO_SHRINES.size() and not awakened_shrines.has(idx):
				awakened_shrines.append(idx)
	puzzle_index = -1
	puzzle_progress = 0
	var saved_rewards = data.get("mastery_rewards", [])
	if saved_rewards is Array:
		for item in saved_rewards:
			var milestone: int = int(item)
			if milestone in [12, 30, 60] and not mastery_rewards.has(milestone):
				mastery_rewards.append(milestone)
	guard_window = 0.0
	guard_cooldown = 0.0
	combo_stage = 0
	combo_timer = 0.0
	jump_count = 0
	floating_text.clear()
	checkpoint_x = float(data.get("checkpoint", 145))
	var restored_realm: String = str(data.get("active_realm", REALM_CATALOG.from_x(checkpoint_x)))
	load_realm_stage(restored_realm)
	quest_counts = data.get("quest_counts", {})
	if not quest_counts is Dictionary: quest_counts = {}
	quest_claimed = data.get("quest_claimed", [])
	if not quest_claimed is Array: quest_claimed = []
	trial_completed.clear()
	var saved_trials = data.get("trial_completed", [])
	if saved_trials is Array:
		for id in saved_trials:
			var trial_id: String = str(id)
			if REALM_CATALOG.TRIALS.has(trial_id) and not trial_completed.has(trial_id):
				trial_completed.append(trial_id)
	trial_puzzle_id = ""
	trial_puzzle.clear()
	tracked_quest_id = str(data.get("tracked_quest_id", ""))
	if tracked_quest_id != "":
		var known: bool = false
		for q in REALM_CATALOG.QUESTS:
			if str(q["id"]) == tracked_quest_id:
				known = true
				break
		if not known or quest_claimed.has(tracked_quest_id):
			tracked_quest_id = ""
	discovered_realm_ids = data.get("discovered_realms", ["hub"])
	if not discovered_realm_ids is Array: discovered_realm_ids = ["hub"]
	if not discovered_realm_ids.has("hub"): discovered_realm_ids.append("hub")
	dungeon_clears = data.get("dungeon_clears", [])
	if not dungeon_clears is Array: dungeon_clears = []
	story_seen = data.get("story_seen", [])
	if not story_seen is Array: story_seen = []
	enemy_kill_counts = data.get("kill_counts", {})
	if not enemy_kill_counts is Dictionary: enemy_kill_counts = {}
	map_visit_counts = data.get("map_visits", {})
	if not map_visit_counts is Dictionary: map_visit_counts = {}
	story_queue.clear()
	realm_transition = 0.0
	defeated_boss = bool(data.get("boss", false))
	sound_on = bool(data.get("sound", true))
	music_on = bool(data.get("music", true))
	music.stream_paused = not music_on
	spawn_enemies()
	return true

func hud_event_position(event: InputEvent) -> Vector2:
	# Correct Android touch coordinates under Godot canvas_items/stretch/aspect=expand.
	var inverse_hud: Transform2D = hud.get_global_transform_with_canvas().affine_inverse()
	if event is InputEventScreenTouch:
		return inverse_hud * event.position
	if event is InputEventScreenDrag:
		return inverse_hud * event.position
	if event is InputEventMouse:
		return inverse_hud * event.position
	return Vector2.ZERO

func mobile_action_at(pos: Vector2) -> String:
	var chosen := ""
	var closest_ratio: float = 1.0
	var centers: Dictionary = hud.control_centers()
	for key in ["attack", "jump", "dash", "skill", "guard", "potion", "interact"]:
		if key == "interact" and nearby_npc() == "": continue
		var radius: float = (58.0 if key == "attack" else (51.0 if key in ["jump", "skill", "guard"] else 46.0)) * hud.active_control_scale()
		var ratio: float = pos.distance_to(centers[key]) / radius
		if ratio < closest_ratio:
			closest_ratio = ratio
			chosen = key
	return chosen

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key = event.keycode
		if key == KEY_ESCAPE or key == KEY_P:
			if state == "playing":
				state = "pause"
				save_game()
			elif state == "settings": state = hud.settings_return
			elif state == "hud_edit":
				hud.editor_touch_release(hud.editor_touch)
				hud.save_control_layout()
				state = "settings"
			elif state == "puzzle": leave_echo_puzzle()
			elif state == "v6_puzzle": leave_trial_puzzle()
			elif state == "ember_puzzle": leave_ember_puzzle()
			elif state == "ember_victory": state = "playing"
			elif state in ["dungeon_victory", "v5_victory"]: state = "playing"
			elif state in ["pause", "inventory", "quests", "shop", "trainer", "portals", "worldmap", "realm_victory"]: state = "playing"
		elif state == "playing":
			match key:
				KEY_SPACE, KEY_W, KEY_UP: jump()
				KEY_SHIFT: dash()
				KEY_K, KEY_L: use_skill()
				KEY_G: guard()
				KEY_J: attack()
				KEY_E: interact()
				KEY_H: heal()
				KEY_I: state = "inventory"
				KEY_Q: state = "quests"
		elif key == KEY_ENTER:
			if state == "main": start_new_game()
			elif state in ["defeat", "victory"]: respawn()
	if event is InputEventScreenTouch:
		if state == "hud_edit":
			if event.pressed: hud.editor_touch_press(hud_event_position(event), event.index)
			else: hud.editor_touch_release(event.index)
			return
		if event.pressed:
			touch_press(hud_event_position(event), event.index)
		else:
			touch_release(event.index)
	elif event is InputEventScreenDrag:
		if state == "hud_edit":
			hud.editor_touch_drag(hud_event_position(event), event.index)
			return
		if event.index == joystick_touch:
			touch_axis = joystick_axis_from_position(hud_event_position(event))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if state == "hud_edit":
			if event.pressed: hud.editor_touch_press(hud_event_position(event), 999)
			else: hud.editor_touch_release(999)
			return
		if event.pressed: touch_press(hud_event_position(event), 999)
		else: touch_release(999)
	elif event is InputEventMouseMotion:
		if state == "hud_edit":
			hud.editor_touch_drag(hud_event_position(event), 999)
		elif joystick_touch == 999:
			touch_axis = joystick_axis_from_position(hud_event_position(event))

func joystick_axis_from_position(pos: Vector2) -> float:
	var axis := clampf((pos.x - joystick_base.x) / (78.0 * hud.active_control_scale()), -1.0, 1.0)
	return 0.0 if absf(axis) < 0.12 else axis

func touch_press(pos: Vector2, id: int) -> void:
	if state == "hud_edit":
		hud.editor_touch_press(pos, id)
		return
	if state != "playing" or dialogue != "":
		if hud.handle_menu_press(pos): return
		if dialogue != "": dialogue = ""
		return
	# Controls are resolved by their actual relocated centers, never the original layout.
	# Do not iterate "joystick" as an action (that previously swallowed taps).
	var action: String = mobile_action_at(pos)
	var stick_ratio: float = pos.distance_to(hud.joystick_center()) / (111.0 * hud.active_control_scale())
	var action_ratio := 2.0
	if action != "":
		var radius: float = (58.0 if action == "attack" else (51.0 if action in ["jump", "skill", "guard"] else 46.0)) * hud.active_control_scale()
		action_ratio = pos.distance_to(hud.control_centers()[action]) / radius
	if joystick_touch < 0 and stick_ratio < 1.0 and stick_ratio <= action_ratio:
		joystick_touch = id
		joystick_base = hud.joystick_center()
		touch_axis = joystick_axis_from_position(pos)
		return
	if action != "":
		match action:
			"attack":
				attack()
				attack_touch[id] = true
				hold_attack = true
			"jump": jump()
			"dash": dash()
			"skill": use_skill()
			"guard": guard()
			"potion": heal()
			"interact": interact()
		return
	if hud.handle_top_press(pos): return

func touch_release(id: int) -> void:
	if state == "hud_edit":
		hud.editor_touch_release(id)
		return
	if id == joystick_touch:
		joystick_touch = -1
		touch_axis = 0.0
	attack_touch.erase(id)
	hold_attack = not attack_touch.is_empty()

func v5_story_label() -> String:
	if quest_stage < 3:
		return "THE FADING STAR: Recover the Aether Seeds, then defeat the Warden."
	if not ember_boss_defeated:
		return "SHATTERED REALMS: Restore the guardians and find the Cinder Warden."
	if not dungeon_clears.has("tide_temple"):
		return "CHAPTER III: Enter Abyssal Depths and clear the Tide Temple."
	if not dungeon_clears.has("verdant_vault"):
		return "CHAPTER IV: Lift the curse from the Verdant Sanctum."
	if not dungeon_clears.has("nexus_core"):
		return "CHAPTER V: Restore the Heart of the Aether Core."
	return "AETHER RESTORED: %d / %d quests and %d dungeons completed." % [quest_claimed.size(), quest_total(), dungeon_clears.size()]

func area_name() -> String:
	var location: Dictionary = REALM_CATALOG.region(REALM_CATALOG.from_x(player_pos.x))
	return str(location.get("name", "AETHER REALMS"))

func hero_sprite_scale() -> Vector2:
	return Vector2(float(facing), 1.0)

func _draw() -> void:
	var camera_x = camera.position.x
	var view_half: float = get_viewport().get_visible_rect().size.x * 0.5
	var left = camera_x - view_half - 190.0
	var right = camera_x + view_half + 190.0
	# Only render the active portal-isolated realm, never neighboring biomes.
	for data in REALM_CATALOG.REGIONS:
		var x0: float = float(data["start"])
		var x1: float = float(data["end"])
		if x1 < left or x0 > right: continue
		var sky: Color = Color(str(data["sky"]))
		draw_rect(Rect2(x0, -270, x1 - x0, 810), sky)
		if x0 < 23000.0:
			var region_number: int = REALM_CATALOG.REGIONS.find(data)
			draw_realm_backdrop(region_number, x0, x1, left, right)
		else:
			var art_name: String = str(data["art"])
			var tex: Texture2D = null
			if art_name.begins_with("v2_"):
				tex = ember_art.get(art_name.trim_prefix("v2_"), null)
			elif art_name.begins_with("v5_generated_"):
				tex = v5_art.get(art_name.trim_prefix("v5_generated_"), null)
			elif art_name.begins_with("v6_generated_"):
				tex = v6_art_for(str(data["id"]))
			elif ResourceLoader.exists("res://assets/%s.png" % art_name):
				tex = load("res://assets/%s.png" % art_name)
			if tex != null and graphics_quality > 0:
				# Individual realm panorama: never repeat one image with a visible
				# vertical join. Each portal has its own camera / artwork bounds.
				draw_texture_rect(tex, Rect2(x0, -175.0, x1 - x0, 730.0), false, Color(1.0, 1.0, 1.0, 0.62))
		for band in range(13):
			var tint: float = 0.009 + float(band) * 0.003
			draw_rect(Rect2(x0, -225 + float(band) * 47.0, x1 - x0, 46), Color(0.6, 0.78, 0.95, tint))
		for i in range(int(maxf(x0, left - 130.0) / 175.0), int(minf(x1, right + 130.0) / 175.0) + 2):
			var cx: float = float(i) * 175.0 + x0 * 0.03
			var peak: float = 275.0 + sin(float(i) * 2.3) * 48.0
			draw_colored_polygon(PackedVector2Array([Vector2(cx - 145.0, 443.0), Vector2(cx, peak), Vector2(cx + 160.0, 443.0)]), Color(sky.r * 0.48, sky.g * 0.55, sky.b * 0.68, 0.64))
	# Subtle dusk/night tint across each biome, without extra mobile shaders.
	var twilight: float = 0.035 + 0.07 * (0.5 + 0.5 * sin(elapsed * (0.004 if reduced_motion else 0.02)))
	if right >= 0.0:
		draw_rect(Rect2(maxf(0.0, left), -180, minf(WORLD_WIDTH, right + 20.0) - maxf(0.0, left), 690), Color(0.08, 0.03, 0.19, twilight))
	# Stars and fireflies are purposely deterministic in space and animated only in brightness.
	for i in range(38 if graphics_quality == 0 else (88 if graphics_quality == 1 else 160)):
		var sx = float(i * 167 % 15783)
		if sx < left or sx > right: continue
		var sy = -80.0 + float((i * 137) % 325)
		var light = 0.2 + 0.3 * (0.5 + 0.5 * sin(elapsed * 1.9 + float(i)))
		draw_circle(Vector2(sx, sy), 1.0 if i % 3 else 2.1, Color(0.74, 0.94, 1, light))
	# Scenery: forest canopy, village, and ancient ruins.
	if left < 1900.0:
		for x in [190.0, 730.0, 1360.0, 1755.0]:
			draw_texture_rect(TREE_DARK, Rect2(x - 110, 206, 200, 294), false, Color(0.65, 0.78, 0.81, 0.7))
		for detail in [Vector2(260, 500), Vector2(810, 500), Vector2(1260, 500)]:
			draw_texture_rect(HOUSE if detail.x != 810 else HOUSE_SHOP, Rect2(detail.x, detail.y - 182, 255, 182), false)
	if right > 1800.0 and left < 4750.0:
		for i in range(13):
			var tx = 1940.0 + float(i) * 225.0
			if tx < left - 220 or tx > right + 220: continue
			draw_texture_rect(TREE_DARK, Rect2(tx - 160, 135 + float(i % 3) * 23, 300, 370), false, Color(0.65, 0.8, 0.83, 0.78))
			draw_texture_rect(TREE, Rect2(tx - 95, 238 + float(i % 2) * 16, 190, 270), false)
	if right > 4750.0 and left < 8400.0:
		for i in range(14):
			var rx = 4780.0 + float(i) * 255.0
			if rx < left - 100 or rx > right + 100: continue
			draw_texture_rect(RUIN, Rect2(rx - 55, 282 - float(i % 3) * 36, 110, 235 + float(i % 3) * 36), false, Color(0.65, 0.7, 0.9, 0.78))
	# Unique scenery for three new, fully connected lands.
	draw_expansion_scenery(left, right)
	draw_emberfall_scenery(left, right)
	# Terrain below the playable floor, interrupted by jumpable pits.
	var first = int(maxf(0.0, floorf((left - 96.0) / 48.0)))
	var last = int(minf(WORLD_WIDTH / 48.0, ceilf((right + 96.0) / 48.0)))
	for tile in range(first, last + 1):
		var tx = float(tile) * 48.0
		if ground_y(tx + 22.0) < 0.0: continue
		var earth: Color = Color(str(REALM_CATALOG.region(REALM_CATALOG.from_x(tx))["sky"])).darkened(0.34)
		# Fill the complete visible ground on taller 4:3 tablets as well as wide phones.
		var view_bottom: float = camera.position.y + get_viewport_rect().size.y * 0.5 / maxf(0.1, camera.zoom.y) + 90.0
		draw_rect(Rect2(tx, FLOOR_Y + 10, 49, maxf(190.0, view_bottom - FLOOR_Y)), earth)
		var ground_tex: Texture2D = GRASS if tx < 4750 or tx >= 12900 else ROCK
		var ground_tint: Color = Color(str(REALM_CATALOG.region(REALM_CATALOG.from_x(tx))["sky"])).lightened(0.52)
		draw_texture_rect(ground_tex, Rect2(tx, FLOOR_Y - 1, 49, 46), false, ground_tint)
		if tile % 3 == 1:
			draw_rect(Rect2(tx + 22, FLOOR_Y + 57, 7, 10), Color(0.1, 0.11, 0.16, 0.65))
	for p in platforms:
		if p.position.x > right or p.end.x < left: continue
		draw_rect(p, Color("2f4c4e") if p.position.x < 4750 else Color("49405e"))
		draw_rect(Rect2(p.position.x, p.position.y, p.size.x, 6), Color("74baa8") if p.position.x < 4750 else Color("b1a0dc"))
		for j in range(int(p.size.x / 36)):
			draw_rect(Rect2(p.position.x + j * 36 + 16, p.position.y + 8, 3, 8), Color(0.04, 0.12, 0.16, 0.5))
	for platform in moving_platforms:
		var px: float = float(platform["x"])
		var py: float = float(platform["y"])
		if px + float(platform["width"]) < left or px > right: continue
		draw_rect(Rect2(px, py, float(platform["width"]), 14), Color("455c8a"))
		draw_rect(Rect2(px, py, float(platform["width"]), 5), Color("a6eaf7"))
		draw_line(Vector2(px, py + 13), Vector2(px + float(platform["width"]), py + 13), Color("aec4fb"), 2)
	for pit in traps:
		if pit.position.x > right or pit.end.x < left: continue
		for spike in range(int(pit.size.x / 25)):
			var px = pit.position.x + float(spike * 25)
			draw_colored_polygon(PackedVector2Array([Vector2(px, 590), Vector2(px + 12, 550), Vector2(px + 25, 590)]), Color("9f628d"))
	for pool in poison_pools:
		if pool.position.x > right or pool.end.x < left: continue
		draw_rect(Rect2(pool.position.x, FLOOR_Y - 8.0, pool.size.x, 14), Color("568568"))
		draw_rect(Rect2(pool.position.x + 4.0, FLOOR_Y - 8.0, pool.size.x - 8.0, 7), Color("adf286"))
		for j in range(3):
			var bubble_x: float = pool.position.x + 16.0 + float(j) * (pool.size.x - 32.0) / 2.0
			draw_circle(Vector2(bubble_x, FLOOR_Y - 14.0 - absf(sin(elapsed * 1.9 + float(j) * 2.1)) * 12.0), 4.0, Color("c4fb95"))
	# Ground-level grass crystals and torches.
	for i in range(first, last + 1):
		if i % 5 == 2 and ground_y(float(i) * 48.0) > 0:
			var px = float(i) * 48.0
			draw_line(Vector2(px + 20, 501), Vector2(px + 15, 485), Color("55c89d"), 3.0)
			draw_line(Vector2(px + 23, 501), Vector2(px + 32, 490), Color("8ce0be"), 2.0)
		if i % 17 == 0 and float(i) * 48.0 > 4850 and float(i) * 48.0 < 8400:
			draw_texture_rect(MAGIC, Rect2(float(i) * 48.0, 456, 32, 42), false)
	# Buildings also define walkable space decor, while collision is handled by terrain.
	if left < 1750:
		draw_label(Vector2(310, 295), "MIRA'S HALL", 16, Color("f3dba1"))
		draw_label(Vector2(886, 295), "STARLIT EMPORIUM", 15, Color("f3dba1"))
		draw_label(Vector2(1330, 295), "WAYFARER'S REST", 15, Color("f3dba1"))
	# Hidden hand-placed relic caches with an animated golden aura.
	for cache_id in range(CACHE_LOCATIONS.size()):
		if opened_caches.has(cache_id): continue
		var chest_x: float = CACHE_LOCATIONS[cache_id]
		if chest_x < left - 50.0 or chest_x > right + 50.0: continue
		var pulse: float = 0.5 + 0.5 * sin(elapsed * 3.0 + float(cache_id))
		draw_circle(Vector2(chest_x, FLOOR_Y - 25), 34.0 + pulse * 6.0, Color(0.98, 0.73, 0.28, 0.08 + pulse * 0.11))
		draw_rect(Rect2(chest_x - 24, FLOOR_Y - 36, 48, 33), Color("694b36"))
		draw_rect(Rect2(chest_x - 24, FLOOR_Y - 39, 48, 12), Color("c19a59"))
		draw_rect(Rect2(chest_x - 24, FLOOR_Y - 39, 48, 36), Color("ffe1a0"), false, 2.0)
		draw_rect(Rect2(chest_x - 5, FLOOR_Y - 29, 10, 13), Color("b4f5e0"))
		draw_label(Vector2(chest_x - 29, FLOOR_Y - 57), "RELIC", 13, Color("ffebb6"))
	for i in range(EMBER_BRAZIERS.size()):
		var bx: float = EMBER_BRAZIERS[i]
		if bx < left - 90 or bx > right + 90: continue
		var lit: bool = ember_braziers.has(i)
		draw_rect(Rect2(bx - 25, FLOOR_Y - 49, 50, 50), Color("4d3840"))
		draw_rect(Rect2(bx - 31, FLOOR_Y - 55, 62, 11), Color("ad7153"))
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 16, FLOOR_Y - 56), Vector2(bx, FLOOR_Y - 104), Vector2(bx + 18, FLOOR_Y - 56)]), Color("ffe09a") if lit else Color("fc8a5b"))
		draw_circle(Vector2(bx, FLOOR_Y - 79), 29, Color(1, 0.32, 0.1, 0.12))
		draw_label(Vector2(bx - 30, FLOOR_Y - 116), "RESTORED" if lit else "FIRE RUNES", 13, Color("ffe3aa"))
	if not emberling_unlocked and left < 17030.0 and right > 16730.0:
		draw_rect(Rect2(16835, FLOOR_Y - 76, 70, 76), Color("704a3d"))
		draw_rect(Rect2(16835, FLOOR_Y - 76, 70, 76), Color("c48d68"), false, 3.0)
		draw_label(Vector2(16800, FLOOR_Y - 99), "RESCUE EMBERLING", 14, Color("ffe0a2"))
	if emberling_unlocked and emberling_active:
		if ember_art.has("emberling"):
			draw_texture_rect(ember_art["emberling"], Rect2(emberling_pos - Vector2(30, 31), Vector2(60, 62)), false)
		else:
			draw_circle(emberling_pos, 17.0, Color("ffb879"))
	for npc in [{"x": 415.0,"name": "MIRA"}, {"x": 1030.0,"name": "LYRA"}, {"x": 1510.0,"name": "TARO"}]:
		if absf(npc["x"] - camera_x) > 680.0: continue
		var bob = 2.0 * sin(elapsed * 1.5 + npc["x"])
		draw_texture_rect(NPC, Rect2(npc["x"] - 23.0, FLOOR_Y - 63.0 + bob, 47, 64), false)
		draw_label(Vector2(npc["x"] - 26.0, 420), npc["name"], 15, Color("f9e49e"))
	if left < 6200 and right > 6080:
		draw_texture_rect(PORTAL, Rect2(6078, 286, 136, 215), false, Color(0.9, 0.48, 0.6, 1) if quest_stage < 2 else Color(0.42, 1, 0.76, 0.93))
		draw_label(Vector2(6085, 271), "AETHER GATE", 15, Color("f9e49e"))
	# Optional Aether Echo rune shrines: visually clear, deliberately separate from portals.
	for i in range(ECHO_SHRINES.size()):
		var sx: float = ECHO_SHRINES[i]
		if sx < left - 100.0 or sx > right + 100.0: continue
		var solved: bool = awakened_shrines.has(i)
		var flicker: float = 0.0 if reduced_motion else sin(elapsed * 2.3 + float(i)) * 3.0
		var glow: Color = Color("a3b6c2") if solved else Color("8ef5e2")
		draw_rect(Rect2(sx - 32, FLOOR_Y - 75, 64, 75), Color("263a4e"))
		draw_rect(Rect2(sx - 38, FLOOR_Y - 75, 76, 11), Color("668a98"))
		draw_circle(Vector2(sx, FLOOR_Y - 96 - flicker), 26.0, Color(glow.r, glow.g, glow.b, 0.17))
		draw_colored_polygon(PackedVector2Array([Vector2(sx, FLOOR_Y - 123 - flicker), Vector2(sx - 18, FLOOR_Y - 96 - flicker), Vector2(sx, FLOOR_Y - 70 - flicker), Vector2(sx + 18, FLOOR_Y - 96 - flicker)]), glow)
		draw_label(Vector2(sx - 30, FLOOR_Y - 140), "ECHO RESTORED" if solved else "RUNE PUZZLE", 13, Color("ddf8f0"))
	# Functional portal network: art changes when each destination is unlocked.
	for i in range(PORTAL_LOCATIONS.size()):
		var gate_x: float = PORTAL_LOCATIONS[i]
		if gate_x < left - 70.0 or gate_x > right + 70.0: continue
		var lit: bool = bool(portal_unlocked[i]) and (i != 0 or defeated_boss)
		var portal_color: Color = Color("66f0dc") if lit else Color("776b8d")
		draw_circle(Vector2(gate_x, FLOOR_Y - 81), 55.0 + sin(elapsed * 2.0 + float(i)) * 4.0, Color(0.19, 0.72, 0.82, 0.13) if lit else Color(0.18, 0.17, 0.3, 0.17))
		draw_texture_rect(PORTAL, Rect2(gate_x - 46.0, FLOOR_Y - 166, 92, 167), false, portal_color)
		draw_label(Vector2(gate_x - 63.0, FLOOR_Y - 185), "PORTAL - " + ("ACTIVE" if lit else "SEALED"), 14, Color("cbf7e2") if lit else Color("b4a4c1"))
	for e in enemies:
		if e["hp"] <= 0.0 or absf(e["x"] - camera_x) > (right - left) * 0.55: continue
		if e["type"] == "boss" and quest_stage < 2: continue
		var sprite_id: String = str(e["type"])
		var reused_sprites: Dictionary = {
			"tide_stalker": "fire_imp", "coral_wisp": "crystal_wisp",
			"thorn_knight": "ash_knight", "petal_moth": "cloud_moth",
			"root_colossus": "marsh_guardian", "mirror_keeper": "crystal_titan",
			"gale_wyrm": "sky_herald", "mire_reaver": "marsh_guardian",
			"echo_archon": "boss", "abyss_leviathan": "crystal_titan",
			"thornheart": "marsh_guardian", "nexus_echo": "boss"}
		if reused_sprites.has(sprite_id):
			sprite_id = str(reused_sprites[sprite_id])
		var texture: Texture2D = ember_art.get(sprite_id, null)
		if texture == null:
			match e["type"]:
				"slime", "bog_slime", "fire_imp": texture = SLIME
				"moth", "cloud_moth": texture = MOTH
				"beetle", "crystal_bug": texture = BEETLE
				"sentinel", "ash_knight": texture = SENTINEL
				"wisp", "crystal_wisp", "sky_wisp", "bog_wisp", "ember_wisp": texture = WISP
				_: texture = BOSS
		var scale: float = 2.65 if BOSS_TYPES.has(e["type"]) else 1.05
		var height: float = 220.0 if e["type"] == "cinder_warden" else 53.0 * scale
		var width: float = 158.0 if e["type"] == "cinder_warden" else 54.0 * scale
		var tint: Color = Color.WHITE
		match e["type"]:
			"crystal_bug", "crystal_wisp", "crystal_titan": tint = Color("86dff6")
			"sky_wisp", "cloud_moth", "sky_herald": tint = Color("ffdb9d")
			"bog_slime", "bog_wisp", "marsh_guardian": tint = Color("b3edb3")
		if e["stun"] > 0: tint = Color("ff8e89")
		if BOSS_TYPES.has(e["type"]):
			if float(e.get("windup", 0.0)) > 0.0:
				var windup_fraction: float = clampf(float(e["windup"]) / 0.55, 0.0, 1.0)
				draw_arc(Vector2(e["x"], e["y"] - height * 0.5), width * 0.74, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - windup_fraction), 46, Color("ffc08c"), 6.0, true)
				draw_label(Vector2(e["x"] - 35, e["y"] - height - 50), "DODGE!", 18, Color("ffcb91"))
			draw_circle(Vector2(e["x"], e["y"] - height * 0.5), width * 0.63, Color(tint.r, tint.g, tint.b, 0.12))
			draw_label(Vector2(e["x"] - 75, e["y"] - height - 25), boss_display_name(e["type"]), 14, tint)
		var bob: float = 0.0 if reduced_motion else sin(elapsed * (3.0 if BOSS_TYPES.has(e["type"]) else 5.0) + float(e["origin"])) * (3.0 if BOSS_TYPES.has(e["type"]) else 2.0)
		if e["attack_anim"] > 0.0: bob -= 7.0
		# All new sprites are authored facing left; mirror to match real AI direction.
		draw_set_transform(Vector2(float(e["x"]), float(e["y"]) + bob), 0.0, Vector2(-float(e["dir"]), 1.0))
		draw_texture_rect(texture, Rect2(-width * 0.5, -height, width, height), false, tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if not BOSS_TYPES.has(e["type"]):
			var species_name: String = str(e["type"]).replace("_", " ").to_upper()
			draw_label(Vector2(e["x"] - width * 0.5, e["y"] - height - 22), species_name, 12, Color("e7f6e6"))
		if e["hp"] < e["max_hp"] or BOSS_TYPES.has(e["type"]):
			var fraction: float = clampf(e["hp"] / e["max_hp"], 0.0, 1.0)
			draw_rect(Rect2(e["x"] - width / 2.0, e["y"] - height - 14, width, 6), Color("1c1727"))
			draw_rect(Rect2(e["x"] - width / 2.0, e["y"] - height - 14, width * fraction, 6), Color("ef786e"))
	for item in loot:
		if absf(item["pos"].x - camera_x) > 750.0: continue
		var art = COIN if item["kind"] == "coin" else (SEED if item["kind"] == "seed" else POTION)
		var bob := sin(item["t"] * 3.0) * 6.0
		if item["kind"] == "seed":
			var glow_center: Vector2 = item["pos"] + Vector2(0, bob)
			draw_circle(glow_center, 24.0 + sin(item["t"] * 5.0) * 3.0, Color(0.3, 0.95, 0.8, 0.25))
			draw_label(glow_center + Vector2(-18, -25), "SEED", 13, Color("d8ffad"))
		draw_texture_rect(art, Rect2(item["pos"].x - 13, item["pos"].y - 13 + bob, 26, 26), false)
	for b in bolts:
		var tint = Color("5be7e4") if b["kind"] == "hero" else (Color("ff9d54") if b["kind"] == "cinder" else Color("cf6de9"))
		var halo: Color = tint
		halo.a = 0.19
		draw_circle(b["pos"], 14.0 if b["kind"] == "hero" else 10.0, halo)
		draw_circle(b["pos"], 7.0 if b["kind"] == "hero" else 5.0, tint)
	# Hero sprite, weapon, dash trails, and spell effects.
	if state != "main":
		var hero_tint = Color(1, 1, 1, 0.43) if invincible > 0.0 and int(elapsed * 15) % 2 == 0 else Color.WHITE
		var pose_data: Dictionary = hero_animation_params()
		var pose: String = pose_data["pose"]
		var art: Texture2D = HERO_JUMP if pose == "jump" else (HERO_RUN if pose in ["run", "dash", "attack"] else HERO_IDLE)
		if pose == "hit": hero_tint = Color("ffb7ae")
		if pose == "heal": hero_tint = Color("b2ffcc")
		if pose == "guard": hero_tint = Color("c0e8ff")
		# Mirroring the draw transform makes the character face the travel direction.
		if dash_timer > 0.0:
			draw_set_transform(player_pos + Vector2(-float(facing) * 40.0, 0), 0.0, hero_sprite_scale())
			draw_texture_rect(art, Rect2(-29, -78, 58, 78), false, Color(0.4, 0.9, 1, 0.26))
		var pose_scale: Vector2 = pose_data["squash"]
		pose_scale.x *= float(facing)
		draw_set_transform(player_pos + pose_data["offset"], float(pose_data["angle"]) * float(facing), pose_scale)
		draw_texture_rect(art, Rect2(-29, -78, 58, 78), false, hero_tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if guard_window > 0.0:
			draw_arc(player_pos + Vector2(0, -42), 56.0, 0.0, TAU, 44, Color(0.47, 0.91, 1.0, 0.85), 4.0, true)
		if healing_glow > 0.0:
			draw_circle(player_pos + Vector2(0, -42), 49.0 * healing_glow, Color(0.4, 1.0, 0.5, 0.15))
		if level_up_glow > 0.0:
			draw_arc(player_pos + Vector2(0, -45), 65.0 + (1.35 - level_up_glow) * 30.0, 0.0, TAU, 42, Color(1.0, 0.86, 0.5, level_up_glow * 0.5), 3.0, true)
		if slash_timer > 0.0:
			var slash_center = player_pos + Vector2(float(facing) * 22.0, -37.0)
			draw_arc(slash_center, 54.0, -1.1 if facing > 0 else 2.05, 1.25 if facing > 0 else 4.35, 22, Color("b8f6ff"), 7.0, true)
		if nearby_npc() != "" and dialogue == "" and state == "playing":
			var verb := "SOLVE" if nearby_npc() == "shrine" else ("TRAVEL" if nearby_npc() == "portal" else ("OPEN" if nearby_npc() == "cache" else ("TRAIN" if nearby_npc() == "scout" else ("SHOP" if nearby_npc() == "merchant" else "TALK"))))
			draw_label(player_pos + Vector2(-45, -92), "TAP %s / E" % verb, 15, Color("ffefbd"))
	for ft in floating_text:
		if absf(ft["pos"].x - camera_x) < 700.0:
			draw_label(ft["pos"], ft["text"], 18, ft["tint"])
	for p in particles:
		draw_rect(Rect2(p["pos"].x, p["pos"].y, 4, 4), Color(p["color"], clampf(p["life"] * 2, 0, 1)))
	if quest_stage >= 2 and left < 7900 and right > 7500:
		draw_circle(Vector2(7800, 120), 150.0, Color(0.7, 0.24, 1.0, 0.08))
		draw_circle(Vector2(7800, 120), 56 + sin(elapsed * 2) * 7, Color(0.6, 0.46, 1, 0.13))


func draw_expansion_scenery(left: float, right: float) -> void:
	# All details are authored procedurally so the extra maps need no network assets.
	if right > 8400.0 and left < 10800.0:
		# Crystal Hollow: cavern ceiling, stalactites, quartz clusters and underground streams.
		var cave_left: float = maxf(8400.0, left - 150.0)
		var cave_right: float = minf(10800.0, right + 150.0)
		draw_rect(Rect2(cave_left, 0, cave_right - cave_left, 130), Color("102637"))
		for i in range(16):
			var x: float = 8400.0 + float(i) * 160.0
			if x < left - 190.0 or x > right + 190.0: continue
			var length: float = 100.0 + float(i % 4) * 32.0
			draw_colored_polygon(PackedVector2Array([Vector2(x - 34, 100), Vector2(x + 34, 100), Vector2(x + 10, 100 + length)]), Color("234e67"))
			draw_line(Vector2(x + 10, 105), Vector2(x + 11, 96 + length), Color("4b8092"), 3)
		for i in range(15):
			var x: float = 8445.0 + float(i) * 155.0
			if x < left - 110.0 or x > right + 110.0: continue
			var h: float = 75.0 + float(i % 4) * 28.0
			var crystal := PackedVector2Array([Vector2(x - 36, FLOOR_Y), Vector2(x - 17, FLOOR_Y - h * 0.7),
				Vector2(x + 2, FLOOR_Y - h), Vector2(x + 28, FLOOR_Y - h * 0.40), Vector2(x + 37, FLOOR_Y)])
			draw_colored_polygon(crystal, Color("327e98"))
			draw_line(Vector2(x + 2, FLOOR_Y - h), Vector2(x + 3, FLOOR_Y - 7), Color("9ef3ef"), 3)
			draw_circle(Vector2(x + 2, FLOOR_Y - h), 10.0 + sin(elapsed * 2.0 + float(i)) * 2.0, Color(0.37, 0.93, 1.0, 0.3))
		if cave_right > cave_left:
			draw_rect(Rect2(cave_left, 456, cave_right - cave_left, 7), Color("2e7485"))
		draw_label(Vector2(8510, 216), "CRYSTAL HOLLOW", 29, Color("b8fbff"))
	if right > 10800.0 and left < 12900.0:
		# Celestial Highlands: layered moving clouds, mountain islands and streaming waterfalls.
		for i in range(22):
			var x: float = 10800.0 + float(i) * 105.0
			if x < left - 210.0 or x > right + 210.0: continue
			var cy: float = 125.0 + float(i % 5) * 54.0
			var drift: float = sin(elapsed * 0.33 + float(i)) * 20.0
			draw_circle(Vector2(x + drift, cy), 47.0, Color(0.81, 0.93, 1.0, 0.22))
			draw_circle(Vector2(x + 42 + drift, cy + 4), 33.0, Color(0.88, 0.97, 1.0, 0.20))
		for i in range(10):
			var x: float = 10930.0 + float(i) * 215.0
			if x < left - 170.0 or x > right + 170.0: continue
			var iy: float = 265.0 + float(i % 3) * 57.0
			draw_colored_polygon(PackedVector2Array([Vector2(x - 98, iy), Vector2(x + 93, iy), Vector2(x + 42, iy + 69), Vector2(x - 33, iy + 94)]), Color("4c6a73"))
			draw_line(Vector2(x - 95, iy), Vector2(x + 88, iy), Color("c4e6d9"), 8)
			if i % 2 == 0:
				for line in range(3):
					var drop_x: float = x + 48.0 + float(line) * 7.0
					draw_line(Vector2(drop_x, iy + 12), Vector2(drop_x + sin(elapsed * 2.0 + line) * 2.0, FLOOR_Y - 8), Color(0.57, 0.94, 1.0, 0.38), 2)
		draw_label(Vector2(10980, 208), "CELESTIAL HIGHLANDS", 29, Color("f7ecc0"))
	if right > 12900.0 and left < WORLD_WIDTH:
		# Shadowfen Marsh: giant luminescent mushrooms, reeds, fireflies and poisonous pools.
		for i in range(23):
			var x: float = 12935.0 + float(i) * 124.0
			if x < left - 160.0 or x > right + 160.0: continue
			var height: float = 95.0 + float(i % 5) * 24.0
			var mushroom_color: Color = Color("715078") if i % 2 else Color("568b81")
			draw_rect(Rect2(x - 7, FLOOR_Y - height, 14, height), Color("8d9c8d"))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 63, FLOOR_Y - height + 15),
				Vector2(x - 28, FLOOR_Y - height - 22), Vector2(x + 14, FLOOR_Y - height - 31),
				Vector2(x + 60, FLOOR_Y - height + 15)]), mushroom_color)
			for dot in range(3):
				draw_circle(Vector2(x - 27 + dot * 26, FLOOR_Y - height + 4), 5.5, Color("c8eeb1"))
			if i % 2 == 1:
				draw_circle(Vector2(x, FLOOR_Y - height - 17), 39.0, Color(0.58, 1.0, 0.64, 0.09))
		for i in range(35):
			var x: float = 12900.0 + float(i) * 84.0
			if x < left - 40.0 or x > right + 40.0: continue
			var fire_y: float = 300.0 + float((i * 31) % 155) + sin(elapsed * 1.1 + float(i)) * 12.0
			draw_circle(Vector2(x + sin(elapsed * 0.9 + i) * 13.0, fire_y), 3.0, Color(0.61, 1.0, 0.69, 0.65))
		draw_label(Vector2(13040, 213), "SHADOWFEN MARSH", 29, Color("c1f1c2"))

func draw_label(at: Vector2, value: String, font_size: int = 17, color: Color = Color.WHITE) -> void:
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("101824"))
	draw_string(font, at + Vector2(1, -1), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
