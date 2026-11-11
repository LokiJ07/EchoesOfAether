extends RefCounted
## Echoes of Aether — optional mechanics for future realm-specific encounters.
## Deterministic puzzle rules independent of UI, save files, or world physics.
## Callers provide player actions and render the resulting state; no scene changes here.

const LOOP_SECONDS := 10.0
const SAMPLE_STEP := 0.1
const MELODY_NOTES := 4

static func start_recording() -> Dictionary:
	return {"elapsed": 0.0, "frames": [], "recording": true, "playing": false, "clone_time": 0.0}

static func record_frame(data: Dictionary, dt: float, position: Vector2, pressing_switch: bool) -> void:
	if not bool(data.get("recording", false)) or dt <= 0.0:
		return
	var elapsed: float = minf(LOOP_SECONDS, float(data.get("elapsed", 0.0)) + dt)
	var frames: Array = data.get("frames", [])
	var last_time: float = -1.0 if frames.is_empty() else float(frames[-1]["t"])
	if last_time < 0.0 or elapsed - last_time >= SAMPLE_STEP - 0.0001 or elapsed >= LOOP_SECONDS:
		frames.append({"t": elapsed, "x": position.x, "y": position.y, "switch": pressing_switch})
	data["frames"] = frames
	data["elapsed"] = elapsed
	if elapsed >= LOOP_SECONDS:
		data["recording"] = false
		data["playing"] = true
		data["clone_time"] = 0.0

static func clone_frame(data: Dictionary, dt: float) -> Dictionary:
	var frames: Array = data.get("frames", [])
	if not bool(data.get("playing", false)) or frames.is_empty():
		return {}
	var t: float = fposmod(float(data.get("clone_time", 0.0)) + maxf(dt, 0.0), LOOP_SECONDS)
	data["clone_time"] = t
	var selected: Dictionary = frames[0]
	for frame in frames:
		if float(frame["t"]) > t:
			break
		selected = frame
	return selected.duplicate()

static func can_open_echo_gate(clone: Dictionary, player_at_exit: bool) -> bool:
	return bool(clone.get("switch", false)) and player_at_exit

static func toggle_era(current: String) -> String:
	return "present" if current == "past" else "past"

static func era_obstacle_passable(obstacle: String, era: String) -> bool:
	match obstacle:
		"bridge":
			return era == "past"
		"collapsed_wall":
			return era == "present"
		"ancient_gate":
			return era == "past"
	return false

static func sonar_visible(duration_remaining: float) -> bool:
	return duration_remaining > 0.0

static func sonar_pulse() -> float:
	return 3.5

static func update_sonar(time_left: float, dt: float) -> float:
	return maxf(0.0, time_left - maxf(dt, 0.0))

static func new_scale(target: int, weights: Array) -> Dictionary:
	return {"target": maxi(1, target), "weights": weights.duplicate(), "left": [], "right": [], "solved": false}

static func scale_place(data: Dictionary, weight_index: int, side: String) -> bool:
	var weights: Array = data.get("weights", [])
	if weight_index < 0 or weight_index >= weights.size() or not side in ["left", "right", "remove"]:
		return false
	var left: Array = data.get("left", [])
	var right: Array = data.get("right", [])
	left.erase(weight_index)
	right.erase(weight_index)
	if side == "left":
		left.append(weight_index)
	elif side == "right":
		right.append(weight_index)
	data["left"] = left
	data["right"] = right
	data["solved"] = scale_solved(data)
	return true

static func scale_total(data: Dictionary, side: String) -> int:
	var result := 0
	var weights: Array = data.get("weights", [])
	for i in data.get(side, []):
		if int(i) >= 0 and int(i) < weights.size():
			result += int(weights[int(i)])
	return result

static func scale_solved(data: Dictionary) -> bool:
	# A real counterweight challenge: equal pans, exact target total on each side.
	return scale_total(data, "left") == int(data.get("target", 0)) and scale_total(data, "right") == int(data.get("target", 0))

static func new_melody(notes: Array) -> Dictionary:
	return {"notes": notes.duplicate(), "progress": 0, "solved": false}

static func play_note(data: Dictionary, note: int) -> bool:
	var notes: Array = data.get("notes", [])
	if notes.is_empty() or bool(data.get("solved", false)):
		return false
	var progress: int = int(data.get("progress", 0))
	if note != int(notes[progress]):
		data["progress"] = 0
		return false
	progress += 1
	data["progress"] = progress
	data["solved"] = progress == notes.size()
	return true

static func decipher(message: Array, dictionary: Dictionary) -> String:
	var text_parts: Array = []
	for symbol in message:
		var key: String = str(symbol)
		text_parts.append(str(dictionary.get(key, "?")))
	return " ".join(text_parts)

static func learn_glyph(dictionary: Dictionary, symbol: String, meaning: String) -> bool:
	if symbol.is_empty() or meaning.is_empty():
		return false
	dictionary[symbol] = meaning
	return true
