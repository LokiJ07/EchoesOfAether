extends Node2D
## Echoes of Aether: offline, mobile-first, self-contained action adventure.
## All gameplay is simulated in world space. HUD stays in CanvasLayer screen space.

const WORLD_WIDTH := 8400.0
const FLOOR_Y := 500.0
const GRAVITY := 1250.0
const SKILL_COOLDOWN := 2.25
const CACHE_LOCATIONS = [690.0, 1940.0, 3400.0, 4560.0, 5350.0, 6780.0]
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
var screen_shake := 0.0
var boss_alert := ""
var joystick_touch := -1
var touch_axis := 0.0
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
	create_world()
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
		Rect2(7040, 365, 165, 18), Rect2(7410, 425, 150, 18)
	]
	traps = [Rect2(2650, 494, 135, 130), Rect2(3480, 494, 150, 130), Rect2(5210, 494, 150, 130)]
	spawn_enemies()

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

func add_enemy(kind: String, x: float) -> void:
	var life = {"slime": 30.0, "moth": 22.0, "beetle": 45.0, "sentinel": 68.0, "wisp": 30.0, "boss": 290.0}[kind]
	var walk = {"slime": 52.0, "moth": 80.0, "beetle": 98.0, "sentinel": 42.0, "wisp": 60.0, "boss": 75.0}[kind]
	enemies.append({"type": kind, "x": x, "origin": x, "y": FLOOR_Y, "hp": life, "max_hp": life,
		"speed": walk, "dir": -1, "cooldown": rng.randf_range(0.5, 2.0), "stun": 0.0,
		"phase": 1, "state": "patrol", "attack_anim": 0.0, "seed_drop": kind == "slime"})

func ground_y(x: float) -> float:
	for pit in traps:
		if x > pit.position.x + 4.0 and x < pit.end.x - 4.0:
			return -1.0
	return FLOOR_Y

func _physics_process(dt: float) -> void:
	elapsed += dt
	if message_time > 0.0:
		message_time -= dt
	invincible = maxf(0.0, invincible - dt)
	attack_timer = maxf(0.0, attack_timer - dt)
	slash_timer = maxf(0.0, slash_timer - dt)
	dash_timer = maxf(0.0, dash_timer - dt)
	dash_cooldown = maxf(0.0, dash_cooldown - dt)
	skill_timer = maxf(0.0, skill_timer - dt)
	screen_shake = maxf(0.0, screen_shake - dt)
	if state == "playing":
		update_player(dt)
		update_enemies(dt)
		update_projectiles(dt)
		update_loot(dt)
		update_particles(dt)
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

func update_player(dt: float) -> void:
	var axis := touch_axis
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		axis -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		axis += 1.0
	axis = clampf(axis, -1.0, 1.0)
	if absf(axis) > 0.1:
		facing = 1 if axis > 0.0 else -1
	if dash_timer > 0.0:
		velocity.x = float(facing) * 690.0
	else:
		velocity.x = move_toward(velocity.x, axis * 245.0, 1200.0 * dt)
	velocity.y = minf(900.0, velocity.y + GRAVITY * dt)
	var old_foot := player_pos.y
	player_pos += velocity * dt
	player_pos.x = clampf(player_pos.x, 38.0, WORLD_WIDTH - 35.0)
	if quest_stage < 2 and player_pos.x > 6195.0:
		player_pos.x = 6195.0
		velocity.x = 0.0
		show_message("Aether Gate sealed. Bring 3 seeds to Mira!", 2.5)
	elif quest_stage >= 2 and not defeated_boss and player_pos.x > 7380.0:
		boss_alert = "WARDEN OF THE FADING STAR"
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
	if player_pos.y > 850.0:
		damage_player(999.0)
	if player_pos.x > 4715.0 and checkpoint_x < 4780.0:
		checkpoint_x = 4790.0
		show_message("Checkpoint: Sunken Ruins", 2.4)
		save_game()
	elif player_pos.x > 2000.0 and checkpoint_x < 2000.0:
		checkpoint_x = 2030.0
		show_message("Checkpoint: Whisperwood", 2.4)
		save_game()

func jump() -> void:
	if state != "playing": return
	if on_ground or (rune_upgrades[0] and jump_count < 2):
		var second_jump: bool = not on_ground
		jump_count = 2 if second_jump else 1
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
	attack_timer = maxf(0.19, 0.36 - 0.025 * float(sword_level))
	slash_timer = 0.16
	var center = player_pos + Vector2(float(facing) * 38.0, -34.0)
	var power = 17.0 + 8.0 * float(sword_level - 1) + float(level - 1) * 1.9
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

func damage_player(amount: float) -> void:
	if state != "playing" or invincible > 0.0: return
	var actual = maxf(1.0, amount - float(armor_level - 1) * 3.0)
	hp -= actual
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
	var is_boss = e["type"] == "boss"
	var bonus := 120 if is_boss else (20 if e["type"] == "sentinel" else 11)
	gain_exp(bonus)
	loot.append({"kind": "coin", "pos": Vector2(e["x"], e["y"] - 25), "t": 0.0, "amount": 90 if is_boss else rng.randi_range(5, 13)})
	if e["seed_drop"] and seeds < 3 and quest_stage <= 1:
		loot.append({"kind": "seed", "pos": Vector2(e["x"] + 18, e["y"] - 42), "t": 0.0, "amount": 1})
	register_hunt(e["type"])
	if rng.randf() < 0.13:
		loot.append({"kind": "potion", "pos": Vector2(e["x"] - 15, e["y"] - 38), "t": 0.0, "amount": 1})
	if is_boss:
		defeated_boss = true
		quest_stage = 3
		coins += 150
		show_message("The Warden has fallen. The Aether returns!", 5.0)
		play_sfx("win")
		state = "victory"
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
		show_message("LEVEL UP! LV %d" % level, 2.5)

func update_enemies(dt: float) -> void:
	for e in enemies:
		if e["hp"] <= 0.0: continue
		var kind: String = e["type"]
		if kind == "boss" and (quest_stage < 2 or player_pos.x < 7210.0): continue
		e["stun"] = maxf(0.0, e["stun"] - dt)
		e["cooldown"] -= dt
		e["attack_anim"] = maxf(0.0, e["attack_anim"] - dt)
		var distance: float = player_pos.x - e["x"]
		var abs_distance = absf(distance)
		var active = abs_distance < (630.0 if kind == "boss" else 360.0) and absf(player_pos.y - e["y"]) < 270.0
		if kind == "boss":
			if e["hp"] < e["max_hp"] * 0.48:
				e["phase"] = 2
			if active and e["cooldown"] <= 0.0:
				boss_attack(e)
			if active and e["stun"] <= 0.0:
				e["x"] += signf(distance) * (115.0 if e["phase"] == 2 else 67.0) * dt
			if abs_distance < 67.0 and e["cooldown"] < 1.1:
				damage_player(24.0 if e["phase"] == 2 else 16.0)
			continue
		if kind == "moth" or kind == "wisp":
			e["y"] = FLOOR_Y - (103.0 if kind == "moth" else 79.0) + sin(elapsed * 2.8 + e["origin"] * 0.07) * 22.0
		if e["stun"] > 0.0: continue
		if active:
			e["dir"] = 1 if distance > 0.0 else -1
			if kind == "wisp":
				if abs_distance > 150.0:
					e["x"] += float(e["dir"]) * e["speed"] * dt
				elif abs_distance < 93.0:
					e["x"] -= float(e["dir"]) * e["speed"] * dt
				if e["cooldown"] <= 0.0:
					shoot_enemy_bolt(e, 275.0, 9.0)
					e["cooldown"] = 2.45
			elif kind == "moth":
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
			if kind in ["moth", "wisp"] or ground_y(patrol_x) > 0.0:
				e["x"] = patrol_x
			else:
				e["dir"] *= -1

func boss_attack(e: Dictionary) -> void:
	var advanced = e["phase"] == 2
	e["cooldown"] = 2.25 if advanced else 3.1
	e["attack_anim"] = 0.58
	var towards = signf(player_pos.x - e["x"])
	for i in range(5 if advanced else 3):
		var angle = -0.38 + float(i) * (0.19 if advanced else 0.38)
		bolts.append({"pos": Vector2(e["x"], e["y"] - 74), "vel": Vector2(towards * 265.0, angle * 250.0), "ttl": 2.6, "kind": "enemy", "damage": 13.0 if advanced else 10.0})
	spawn_dust(Vector2(e["x"], e["y"] - 70), Color(0.8, 0.2, 1.0), 14)

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
				if e["hp"] > 0.0 and absf(b["pos"].x - e["x"]) < (62.0 if e["type"] == "boss" else 28.0) and absf(b["pos"].y - e["y"] + 34.0) < 64.0:
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
	for i in amount:
		particles.append({"pos": pos, "vel": Vector2(rng.randf_range(-115, 115), rng.randf_range(-180, 0)), "life": rng.randf_range(0.26, 0.55), "color": tint})

func update_camera() -> void:
	var camera_half = 576.0  # 1152 design-space coordinate; canvas_items maintains scaling
	var desired = clampf(player_pos.x, camera_half, WORLD_WIDTH - camera_half)
	camera.position = Vector2(desired, 322.0)
	if screen_shake > 0.0:
		camera.offset = Vector2(rng.randf_range(-4, 4), rng.randf_range(-3, 3))
	else:
		camera.offset = Vector2.ZERO

func show_message(line: String, duration: float = 2.5) -> void:
	message = line
	message_time = duration

func nearby_npc() -> String:
	if nearby_cache_index() >= 0: return "cache"
	if absf(player_pos.x - 415.0) < 105.0: return "mira"
	if absf(player_pos.x - 1030.0) < 105.0: return "merchant"
	if absf(player_pos.x - 1510.0) < 100.0: return "scout"
	if absf(player_pos.x - 6160.0) < 112.0: return "gate"
	return ""

func interact() -> void:
	if state != "playing": return
	if nearby_cache_index() >= 0:
		open_cache(nearby_cache_index())
		return
	if dialogue != "":
		dialogue = ""
		return
	match nearby_npc():
		"mira":
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
	checkpoint_x = 145.0
	defeated_boss = false
	bolts.clear()
	loot.clear()
	particles.clear()
	spawn_enemies()
	state = "playing"
	dialogue = ""
	show_message("ECHOES OF AETHER — Talk to Mira to begin your journey!", 5.0)
	update_camera()
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
		"music": music_on, "save_version": 2,
		"relic_shards": relic_shards, "opened_caches": opened_caches, "rune_upgrades": rune_upgrades,
		"hunt_moths": hunted_moths, "hunt_sentinels": hunted_sentinels,
		"claimed_hunts": claimed_hunts}
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
	jump_count = 0
	floating_text.clear()
	checkpoint_x = float(data.get("checkpoint", 145))
	defeated_boss = bool(data.get("boss", false))
	sound_on = bool(data.get("sound", true))
	music_on = bool(data.get("music", true))
	music.stream_paused = not music_on
	spawn_enemies()
	return true

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key = event.keycode
		if key == KEY_ESCAPE or key == KEY_P:
			if state == "playing":
				state = "pause"
				save_game()
			elif state == "settings": state = hud.settings_return
			elif state in ["pause", "inventory", "quests", "shop", "trainer"]: state = "playing"
		elif state == "playing":
			match key:
				KEY_SPACE, KEY_W, KEY_UP: jump()
				KEY_SHIFT: dash()
				KEY_K, KEY_L: use_skill()
				KEY_J: attack()
				KEY_E: interact()
				KEY_H: heal()
				KEY_I: state = "inventory"
				KEY_Q: state = "quests"
		elif key == KEY_ENTER:
			if state == "main": start_new_game()
			elif state in ["defeat", "victory"]: respawn()
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_press(event.position, event.index)
		else:
			touch_release(event.index)
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch:
			touch_axis = clampf((event.position.x - hud.joystick_center().x) / 60.0, -1.0, 1.0)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: touch_press(event.position, 999)
		else: touch_release(999)
	elif event is InputEventMouseMotion and joystick_touch == 999:
		touch_axis = clampf((event.position.x - hud.joystick_center().x) / 60.0, -1.0, 1.0)

func touch_press(pos: Vector2, id: int) -> void:
	if state != "playing" or dialogue != "":
		if hud.handle_menu_press(pos): return
		if dialogue != "": dialogue = ""
		return
	if hud.handle_top_press(pos): return
	var controls = hud.control_centers()
	for key in controls:
		var center: Vector2 = controls[key]
		if center.distance_to(pos) < 43.0:
			match key:
				"attack":
					attack()
					attack_touch[id] = true
					hold_attack = true
				"jump": jump()
				"dash": dash()
				"skill": use_skill()
				"potion": heal()
				"interact": interact()
			return
	if pos.x < hud.size.x * 0.36 and pos.y > hud.size.y * 0.48:
		joystick_touch = id
		touch_axis = clampf((pos.x - hud.joystick_center().x) / 60.0, -1.0, 1.0)

func touch_release(id: int) -> void:
	if id == joystick_touch:
		joystick_touch = -1
		touch_axis = 0.0
	attack_touch.erase(id)
	hold_attack = not attack_touch.is_empty()

func area_name() -> String:
	if player_pos.x < 1900.0: return "MOONHAVEN VILLAGE"
	if player_pos.x < 4750.0: return "WHISPERWOOD FOREST"
	if player_pos.x < 7250.0: return "SUNKEN RUINS"
	return "ASTRAL SANCTUM"

func hero_sprite_scale() -> Vector2:
	return Vector2(float(facing), 1.0)

func _draw() -> void:
	var camera_x = camera.position.x
	var left = camera_x - 750.0
	var right = camera_x + 750.0
	# Original layered pixel-art world: skyline, silhouettes, interactive structures and moving light.
	for region in range(3):
		var x0: float = [0.0, 1900.0, 4750.0][region]
		var x1: float = [1900.0, 4750.0, WORLD_WIDTH][region]
		var sky: Color = [Color("1b3850"), Color("152a3e"), Color("1a1b37")][region]
		draw_rect(Rect2(x0, -250, x1 - x0, 780), sky)
		for band in range(14):
			var strength = 0.008 + 0.004 * float(band)
			draw_rect(Rect2(x0, -220 + float(band) * 45.0, x1 - x0, 46), Color(0.6, 0.78, 0.95, strength))
		if x1 < left or x0 > right: continue
		for i in range(int(maxf(x0, left - 200) / 170.0), int(minf(x1, right + 300) / 170.0) + 2):
			var cx = float(i) * 170.0 + x0 * 0.03
			var mountain = PackedVector2Array([Vector2(cx - 145, 440), Vector2(cx, 245 + sin(float(i) * 2.5) * 55), Vector2(cx + 170, 440)])
			draw_colored_polygon(mountain, Color(0.09, 0.17, 0.23, 0.65) if region < 2 else Color(0.15, 0.13, 0.24, 0.75))
	# Subtle dusk/night tint across each biome, without extra mobile shaders.
	var twilight: float = 0.13 + 0.17 * (0.5 + 0.5 * sin(elapsed * 0.02))
	if right >= 0.0:
		draw_rect(Rect2(maxf(0.0, left), -180, minf(WORLD_WIDTH, right + 20.0) - maxf(0.0, left), 690), Color(0.08, 0.03, 0.19, twilight))
	# Stars and fireflies are purposely deterministic in space and animated only in brightness.
	for i in range(70):
		var sx = float(i * 167 % 8363)
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
	if right > 4750.0:
		for i in range(14):
			var rx = 4780.0 + float(i) * 255.0
			if rx < left - 100 or rx > right + 100: continue
			draw_texture_rect(RUIN, Rect2(rx - 55, 282 - float(i % 3) * 36, 110, 235 + float(i % 3) * 36), false, Color(0.65, 0.7, 0.9, 0.78))
	# Terrain below the playable floor, interrupted by jumpable pits.
	var first = int(maxf(0.0, floorf((left - 96.0) / 48.0)))
	var last = int(minf(WORLD_WIDTH / 48.0, ceilf((right + 96.0) / 48.0)))
	for tile in range(first, last + 1):
		var tx = float(tile) * 48.0
		if ground_y(tx + 22.0) < 0.0: continue
		var earth = Color("243a35") if tx < 4750 else Color("27283b")
		draw_rect(Rect2(tx, FLOOR_Y + 10, 49, 190), earth)
		draw_texture_rect(GRASS if tx < 4750 else ROCK, Rect2(tx, FLOOR_Y - 1, 49, 46), false)
		if tile % 3 == 1:
			draw_rect(Rect2(tx + 22, FLOOR_Y + 57, 7, 10), Color(0.1, 0.11, 0.16, 0.65))
	for p in platforms:
		if p.position.x > right or p.end.x < left: continue
		draw_rect(p, Color("2f4c4e") if p.position.x < 4750 else Color("49405e"))
		draw_rect(Rect2(p.position.x, p.position.y, p.size.x, 6), Color("74baa8") if p.position.x < 4750 else Color("b1a0dc"))
		for j in range(int(p.size.x / 36)):
			draw_rect(Rect2(p.position.x + j * 36 + 16, p.position.y + 8, 3, 8), Color(0.04, 0.12, 0.16, 0.5))
	for pit in traps:
		if pit.position.x > right or pit.end.x < left: continue
		for spike in range(int(pit.size.x / 25)):
			var px = pit.position.x + float(spike * 25)
			draw_colored_polygon(PackedVector2Array([Vector2(px, 590), Vector2(px + 12, 550), Vector2(px + 25, 590)]), Color("9f628d"))
	# Ground-level grass crystals and torches.
	for i in range(first, last + 1):
		if i % 5 == 2 and ground_y(float(i) * 48.0) > 0:
			var px = float(i) * 48.0
			draw_line(Vector2(px + 20, 501), Vector2(px + 15, 485), Color("55c89d"), 3.0)
			draw_line(Vector2(px + 23, 501), Vector2(px + 32, 490), Color("8ce0be"), 2.0)
		if i % 17 == 0 and float(i) * 48.0 > 4850:
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
	for npc in [{"x": 415.0,"name": "MIRA"}, {"x": 1030.0,"name": "LYRA"}, {"x": 1510.0,"name": "TARO"}]:
		if absf(npc["x"] - camera_x) > 680.0: continue
		var bob = 2.0 * sin(elapsed * 1.5 + npc["x"])
		draw_texture_rect(NPC, Rect2(npc["x"] - 23.0, FLOOR_Y - 63.0 + bob, 47, 64), false)
		draw_label(Vector2(npc["x"] - 26.0, 420), npc["name"], 15, Color("f9e49e"))
	if left < 6200 and right > 6080:
		draw_texture_rect(PORTAL, Rect2(6078, 286, 136, 215), false, Color(0.9, 0.48, 0.6, 1) if quest_stage < 2 else Color(0.42, 1, 0.76, 0.93))
		draw_label(Vector2(6085, 271), "AETHER GATE", 15, Color("f9e49e"))
	for e in enemies:
		if e["hp"] <= 0.0 or absf(e["x"] - camera_x) > 730.0: continue
		if e["type"] == "boss" and quest_stage < 2: continue
		var texture: Texture2D
		match e["type"]:
			"slime": texture = SLIME
			"moth": texture = MOTH
			"beetle": texture = BEETLE
			"sentinel": texture = SENTINEL
			"wisp": texture = WISP
			_: texture = BOSS
		var scale = 1.0 if e["type"] != "boss" else 2.7
		var height = 53.0 * scale
		var width = 54.0 * scale
		var tint = Color(1.0, 0.52, 0.47) if e["stun"] > 0 else Color.WHITE
		draw_texture_rect(texture, Rect2(e["x"] - width / 2.0, e["y"] - height, width, height), false, tint)
		if e["hp"] < e["max_hp"] or e["type"] == "boss":
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
		var tint = Color("5be7e4") if b["kind"] == "hero" else Color("cf6de9")
		var halo: Color = tint
		halo.a = 0.19
		draw_circle(b["pos"], 14.0 if b["kind"] == "hero" else 10.0, halo)
		draw_circle(b["pos"], 7.0 if b["kind"] == "hero" else 5.0, tint)
	# Hero sprite, weapon, dash trails, and spell effects.
	if state != "main":
		var hero_tint = Color(1, 1, 1, 0.43) if invincible > 0.0 and int(elapsed * 15) % 2 == 0 else Color.WHITE
		var art = HERO_JUMP if not on_ground else (HERO_RUN if absf(velocity.x) > 45.0 and int(elapsed * 10) % 2 == 0 else HERO_IDLE)
		# Mirroring the draw transform makes the character face the travel direction.
		if dash_timer > 0.0:
			draw_set_transform(player_pos + Vector2(-float(facing) * 40.0, 0), 0.0, hero_sprite_scale())
			draw_texture_rect(art, Rect2(-24, -67, 48, 67), false, Color(0.4, 0.9, 1, 0.26))
		draw_set_transform(player_pos, 0.0, hero_sprite_scale())
		draw_texture_rect(art, Rect2(-24, -67 + (sin(elapsed * 9) if on_ground else 0), 48, 67), false, hero_tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if slash_timer > 0.0:
			var slash_center = player_pos + Vector2(float(facing) * 22.0, -37.0)
			draw_arc(slash_center, 54.0, -1.1 if facing > 0 else 2.05, 1.25 if facing > 0 else 4.35, 22, Color("b8f6ff"), 7.0, true)
		if nearby_npc() != "" and dialogue == "" and state == "playing":
			var verb := "OPEN" if nearby_npc() == "cache" else ("TRAIN" if nearby_npc() == "scout" else ("SHOP" if nearby_npc() == "merchant" else "TALK"))
			draw_label(player_pos + Vector2(-45, -92), "TAP %s / E" % verb, 15, Color("ffefbd"))
	for ft in floating_text:
		if absf(ft["pos"].x - camera_x) < 700.0:
			draw_label(ft["pos"], ft["text"], 18, ft["tint"])
	for p in particles:
		draw_rect(Rect2(p["pos"].x, p["pos"].y, 4, 4), Color(p["color"], clampf(p["life"] * 2, 0, 1)))
	if quest_stage >= 2 and left < 7900 and right > 7500:
		draw_circle(Vector2(7800, 120), 150.0, Color(0.7, 0.24, 1.0, 0.08))
		draw_circle(Vector2(7800, 120), 56 + sin(elapsed * 2) * 7, Color(0.6, 0.46, 1, 0.13))

func draw_label(at: Vector2, value: String, font_size: int = 17, color: Color = Color.WHITE) -> void:
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("101824"))
	draw_string(font, at + Vector2(1, -1), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
