extends Node2D
## Actual instanced zone scene: gate props, lore NPCs and unique dungeon decor.
const CATALOG = preload("res://scripts/RealmCatalog.gd")
const NPC = preload("res://assets/npc.png")
const GATE = preload("res://assets/portal.png")
@export var realm_id: String = "hub"
var timer := 0.0

func _process(dt: float) -> void:
	timer += dt
	queue_redraw()

func _draw() -> void:
	var info: Dictionary = CATALOG.region(realm_id)
	if info.is_empty(): return
	var game: Node = get_parent()
	var camera: Camera2D = game.get("camera") as Camera2D
	if camera == null: return
	var middle: float = camera.position.x
	var half_width: float = get_viewport_rect().size.x * 0.5 + 180.0
	var start: float = float(info["start"])
	var end: float = float(info["end"])
	if middle + half_width < start or middle - half_width > end: return
	var hue: Color = Color(str(info["sky"]))
	var gate_x: float = 1720.0 if realm_id == "hub" else start + 145.0
	if absf(middle - gate_x) < half_width:
		_draw_portal(gate_x, hue, "EXIT CHAMBER" if info["kind"] == "trial" else ("EXIT DUNGEON" if info["kind"] == "dungeon" else "TRAVEL"))
	if info["kind"] == "dungeon":
		var side_id: String = game.trial_side_room(realm_id)
		if side_id != "":
			var side_x: float = start + (end - start) * 0.58
			if absf(middle - side_x) < half_width:
				_draw_portal(side_x, Color("c7a3fc"), "SECRET ANNEX")
	if info["kind"] == "realm" and str(info["dungeon"]) != "":
		var deep_gate: float = end - 85.0
		if absf(middle - deep_gate) < half_width:
			_draw_portal(deep_gate, Color("edaf72"), "DUNGEON")
	if info["kind"] != "hub":
		var npc_x: float = start + 610.0
		if absf(middle - npc_x) < half_width:
			draw_texture_rect(NPC, Rect2(npc_x - 23.0, 433.0, 46.0, 67.0), false, hue.lightened(0.5))
			_draw_text(Vector2(npc_x - 49.0, 412.0), "STORY", Color("f0d4a7"))
	if info["kind"] == "trial":
		var altar_x: float = start + 1530.0
		if absf(middle - altar_x) < half_width:
			var restored: bool = game.trial_completed.has(realm_id)
			var gl: Color = Color("ffd78d") if restored else Color("7af9e4")
			draw_circle(Vector2(altar_x, 383.0), 95.0, Color(gl.r, gl.g, gl.b, 0.13))
			draw_rect(Rect2(altar_x - 53, 449, 106, 49), Color("342b4b"))
			draw_rect(Rect2(altar_x - 60, 440, 120, 15), gl)
			draw_colored_polygon(PackedVector2Array([Vector2(altar_x, 308),Vector2(altar_x - 47, 377),Vector2(altar_x, 427),Vector2(altar_x + 47, 377)]), Color(gl.r, gl.g, gl.b, 0.83))
			_draw_text(Vector2(altar_x - 67, 281), "SEAL RESTORED" if restored else "INTERACTIVE PUZZLE", Color("ffe7b8"))
		for i in range(12):
			var x: float = start + 290.0 + float(i) * 176.0
			if absf(middle - x) > half_width or x > end - 70.0: continue
			draw_rect(Rect2(x - 14, 190 + float(i % 2)*32.0, 28, 300), Color(hue.r * 0.50, hue.g * 0.50, hue.b * 0.57, 0.83))
			draw_circle(Vector2(x, 186 + float(i % 2)*32.0), 14.0, hue.lightened(0.4))
	elif info["kind"] == "dungeon":
		for i in range(10):
			var x: float = start + 365.0 + float(i) * 276.0
			if absf(middle - x) > half_width or x > end - 150: continue
			draw_rect(Rect2(x - 19.0, 175.0, 37.0, 325.0), hue.darkened(0.5))
			draw_rect(Rect2(x - 28.0, 167.0, 56.0, 14.0), hue.lightened(0.24))
			draw_circle(Vector2(x, 156.0), 11.0, Color(hue.r, hue.g, hue.b, 0.75))
	else:
		for i in range(12):
			var x: float = start + 370.0 + float(i) * 250.0
			if absf(middle - x) > half_width or x >= end: continue
			draw_line(Vector2(x, 499.0), Vector2(x + 12.0, 453.0 - float(i % 3) * 9.0), hue.lightened(0.3), 4.0)
			draw_circle(Vector2(x + 12.0, 452.0 - float(i % 3) * 9.0), 8.0, hue.lightened(0.6))

func _draw_portal(x: float, hue: Color, label: String) -> void:
	var pulse: float = 0.6 + 0.4 * sin(timer * 3.0 + x)
	draw_circle(Vector2(x, 404.0), 67.0, Color(hue.r, hue.g, hue.b, 0.16 * pulse))
	draw_texture_rect(GATE, Rect2(x - 48.0, 318.0, 96.0, 183.0), false, hue.lightened(0.33))
	_draw_text(Vector2(x - 42.0, 302.0), label, Color("ffe1b4"))

func _draw_text(at: Vector2, content: String, tint: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, content, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, tint)
