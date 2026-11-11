extends RefCounted
## v6 Dungeon Annex trials: four REAL mechanics, deterministic and non-blocking.
## Pure functions let Godot CI simulate the entire puzzle, including wrong moves.
const BASE_PIPES = [0, 6, 12, 10, 9, 3, 0, 0, 0]
const COLOURS = ["SUN", "MOON", "STAR", "FLAME"]

static func adjacent(a: int, b: int) -> bool:
	return a >= 0 and b >= 0 and a < 9 and b < 9 and ((abs(a - b) == 3) or (int(a / 3) == int(b / 3) and abs(a - b) == 1))

static func rotate_mask(mask: int, times: int) -> int:
	var result: int = mask
	for i in range(posmod(times, 4)):
		result = ((result << 1) & 15) | ((result >> 3) & 1)
	return result

static func circuit_open(rotations: Array) -> bool:
	if rotations.size() != 9: return false
	var masks: Array = []
	for i in range(9):
		masks.append(rotate_mask(int(BASE_PIPES[i]), int(rotations[i])))
	# The beam must physically travel between matching adjacent connectors.
	if (int(masks[3]) & 8) == 0 or (int(masks[5]) & 2) == 0:
		return false
	var found: Dictionary = {3: true}
	var queue: Array = [3]
	while not queue.is_empty():
		var cell: int = int(queue.pop_front())
		if cell == 5: return true
		for delta in [-3, 1, 3, -1]:
			var next_cell: int = cell + delta
			if not adjacent(cell, next_cell): continue
			var dir_bit: int = { -3: 1, 1: 2, 3: 4, -1: 8 }[delta]
			var back_bit: int = { -3: 4, 1: 8, 3: 1, -1: 2 }[delta]
			if (int(masks[cell]) & dir_bit) != 0 and (int(masks[next_cell]) & back_bit) != 0 and not found.has(next_cell):
				found[next_cell] = true
				queue.append(next_cell)
	return false

static func make(id: String, puzzle_type: String) -> Dictionary:
	var data: Dictionary = {"id": id, "kind": puzzle_type, "solved": false,
		"moves": 0, "message": "NO TIME LIMIT. HINTS & EXIT ARE ALWAYS AVAILABLE."}
	match puzzle_type:
		"mosaic":
			var tiles: Array = [1, 2, 3, 4, 5, 6, 7, 8, 0]
			var blank: int = 8
			var reverse_history: Array = []
			var last: int = -1
			var rng := RandomNumberGenerator.new()
			rng.seed = 90210 if id == "root_gallery" else 33537
			for move in range(18):
				var choices: Array = []
				for cell in range(9):
					if adjacent(cell, blank) and cell != last:
						choices.append(cell)
				if choices.is_empty(): continue
				var next_cell: int = int(choices[rng.randi_range(0, choices.size() - 1)])
				tiles[blank] = tiles[next_cell]
				tiles[next_cell] = 0
				reverse_history.push_front(blank)
				last = blank
				blank = next_cell
			data["tiles"] = tiles
			data["hint_path"] = reverse_history
		"circuit":
			data["rotations"] = [0, 1, 2, 3, 2, 1, 0, 0, 0] if id == "prism_annex" else [0, 2, 1, 1, 3, 2, 0, 0, 0]
		"logic":
			var answer: Array = [2, 3, 1] if id == "wind_observatory" else [3, 1, 2]
			data["dials"] = [0, 0, 0]
			data["clues"] = [int(answer[0]) + int(answer[1]), int(answer[1]) + int(answer[2]), int(answer[0]) + int(answer[2])]
		"memory":
			data["sequence"] = [2, 0, 3, 1, 2] if id == "bog_lanterns" else [1, 3, 0, 2, 1, 0]
			data["progress"] = 0
	return data

static func is_solved(data: Dictionary) -> bool:
	match str(data.get("kind", "")):
		"mosaic": return data.get("tiles", []) == [1, 2, 3, 4, 5, 6, 7, 8, 0]
		"circuit": return circuit_open(data.get("rotations", []))
		"logic":
			var d: Array = data.get("dials", [])
			var clues: Array = data.get("clues", [])
			return d.size() == 3 and clues.size() == 3 and int(d[0])+int(d[1]) == int(clues[0]) and int(d[1])+int(d[2]) == int(clues[1]) and int(d[0])+int(d[2]) == int(clues[2])
		"memory": return int(data.get("progress", 0)) >= data.get("sequence", []).size()
	return false

static func press(data: Dictionary, cell: int) -> bool:
	var kind: String = str(data.get("kind", ""))
	if bool(data.get("solved", false)): return false
	match kind:
		"mosaic":
			if cell < 0 or cell >= 9: return false
			var tiles: Array = data["tiles"]
			var blank: int = tiles.find(0)
			if not adjacent(blank, cell):
				data["message"] = "MOVE A PIECE NEXT TO THE EMPTY SPACE."
				return false
			tiles[blank] = tiles[cell]
			tiles[cell] = 0
			data["tiles"] = tiles
			data["message"] = "ASSEMBLE ALL 8 FRAGMENTS IN ORDER."
		"circuit":
			if cell < 0 or cell >= 9 or int(BASE_PIPES[cell]) == 0: return false
			var rotations: Array = data["rotations"]
			rotations[cell] = (int(rotations[cell]) + 1) % 4
			data["rotations"] = rotations
			data["message"] = "ROTATE PIPES TO CONNECT THE BEAM FROM LEFT TO RIGHT."
		"logic":
			if cell < 0 or cell >= 3: return false
			var dials: Array = data["dials"]
			dials[cell] = (int(dials[cell]) + 1) % 4
			data["dials"] = dials
			data["message"] = "SATISFY ALL THREE PAIR-SUM CLUES."
		"memory":
			if cell < 0 or cell >= 4: return false
			var seq: Array = data["sequence"]
			var progress: int = int(data["progress"])
			if cell != int(seq[progress]):
				data["progress"] = 0
				data["message"] = "NOT THE RIGHT GLYPH. SEQUENCE RESETS; NO PENALTY."
				return false
			data["progress"] = progress + 1
			data["message"] = "MEMORY %d / %d" % [int(data["progress"]), seq.size()]
		_:
			return false
	data["moves"] = int(data["moves"]) + 1
	data["solved"] = is_solved(data)
	if data["solved"]: data["message"] = "SEAL RESTORED. YOUR REWARD IS READY."
	return true

static func hint(data: Dictionary) -> String:
	match str(data.get("kind", "")):
		"mosaic":
			return "ALIGN THE FRAGMENTS 1 TO 8, LEAVING THE LOWER RIGHT EMPTY. TAP ADJACENT PIECES."
		"circuit":
			return "BEAM ENTERS FROM LEFT OF THE MIDDLE ROW. TURN PIPES SO LIGHT EXITS ON THE RIGHT."
		"logic":
			var c: Array = data["clues"]
			return "LEFT+MIDDLE=%d, MIDDLE+RIGHT=%d, LEFT+RIGHT=%d." % [c[0], c[1], c[2]]
		"memory":
			var seq: Array = data["sequence"]
			var next: int = int(data["progress"])
			return "NEXT GLYPH: " + COLOURS[int(seq[next])] if next < seq.size() else "SEQUENCE COMPLETE."
	return "EXAMINE THE CHAMBER FOR A CLUE."
