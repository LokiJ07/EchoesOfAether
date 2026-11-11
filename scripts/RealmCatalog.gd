extends RefCounted
## Data-first v3-v5 portal realms. World-space offsets preserve v2 save checkpoints.
## Each region loads its own PackedScene and is physically isolated by camera bounds.
const REGIONS = [
	{
		"id": "hub",
		"name": "MOONHAVEN VILLAGE",
		"start": 0,
		"end": 1900,
		"arrival": 1635,
		"kind": "hub",
		"parent": "",
		"dungeon": "",
		"sky": "#24465a",
		"art": ""
	},
	{
		"id": "forest",
		"name": "WHISPERWOOD VALE",
		"start": 1900,
		"end": 4750,
		"arrival": 2100,
		"kind": "realm",
		"parent": "hub",
		"dungeon": "rootcrypt",
		"sky": "#193e37",
		"art": ""
	},
	{
		"id": "ruins",
		"name": "SUNKEN RUINS",
		"start": 4750,
		"end": 8400,
		"arrival": 4960,
		"kind": "realm",
		"parent": "hub",
		"dungeon": "echo_labyrinth",
		"sky": "#292b48",
		"art": ""
	},
	{
		"id": "crystal",
		"name": "CRYSTAL HOLLOW",
		"start": 8400,
		"end": 10800,
		"arrival": 8800,
		"kind": "realm",
		"parent": "hub",
		"dungeon": "mirror_vault",
		"sky": "#11344b",
		"art": "v1_bg_crystal"
	},
	{
		"id": "sky",
		"name": "CELESTIAL HIGHLANDS",
		"start": 10800,
		"end": 12900,
		"arrival": 11190,
		"kind": "realm",
		"parent": "hub",
		"dungeon": "gale_spire",
		"sky": "#355b84",
		"art": "v1_bg_sky"
	},
	{
		"id": "marsh",
		"name": "SHADOWFEN MARSH",
		"start": 12900,
		"end": 15800,
		"arrival": 13380,
		"kind": "realm",
		"parent": "hub",
		"dungeon": "mire_catacombs",
		"sky": "#1b3534",
		"art": "v1_bg_marsh"
	},
	{
		"id": "ember",
		"name": "EMBERFALL CITADEL",
		"start": 15800,
		"end": 19800,
		"arrival": 16120,
		"kind": "realm",
		"parent": "hub",
		"dungeon": "cinder",
		"sky": "#562d2c",
		"art": "v2_citadel"
	},
	{
		"id": "cinder",
		"name": "CINDER VAULT",
		"start": 19800,
		"end": 23000,
		"arrival": 20040,
		"kind": "dungeon",
		"parent": "ember",
		"dungeon": "",
		"sky": "#241e29",
		"art": "v2_dungeon"
	},
	{
		"id": "abyss",
		"name": "ABYSSAL DEPTHS",
		"start": 23000,
		"end": 27500,
		"arrival": 23320,
		"kind": "realm",
		"parent": "hub",
		"dungeon": "tide_temple",
		"sky": "#0d3854",
		"art": "v1_bg_crystal"
	},
	{
		"id": "tide_temple",
		"name": "TEMPLE OF THE TIDE",
		"start": 27500,
		"end": 31100,
		"arrival": 27750,
		"kind": "dungeon",
		"parent": "abyss",
		"dungeon": "",
		"sky": "#092e48",
		"art": "v1_bg_crystal"
	},
	{
		"id": "garden",
		"name": "EVERDAWN GARDENS",
		"start": 31100,
		"end": 35500,
		"arrival": 31400,
		"kind": "realm",
		"parent": "hub",
		"dungeon": "verdant_vault",
		"sky": "#245640",
		"art": "v1_bg_sky"
	},
	{
		"id": "verdant_vault",
		"name": "VERDANT SANCTUM",
		"start": 35500,
		"end": 39000,
		"arrival": 35750,
		"kind": "dungeon",
		"parent": "garden",
		"dungeon": "",
		"sky": "#173b2f",
		"art": "v1_bg_marsh"
	},
	{
		"id": "nexus",
		"name": "AETHER NEXUS",
		"start": 39000,
		"end": 43500,
		"arrival": 39300,
		"kind": "realm",
		"parent": "hub",
		"dungeon": "nexus_core",
		"sky": "#292251",
		"art": "v1_bg_sky"
	},
	{
		"id": "rootcrypt",
		"name": "ROOTBOUND CRYPT",
		"start": 43500,
		"end": 46600,
		"arrival": 43770,
		"kind": "dungeon",
		"parent": "forest",
		"dungeon": "",
		"sky": "#172d27",
		"art": "v1_bg_marsh"
	},
	{
		"id": "mirror_vault",
		"name": "MIRROR VAULT",
		"start": 46600,
		"end": 49700,
		"arrival": 46880,
		"kind": "dungeon",
		"parent": "crystal",
		"dungeon": "",
		"sky": "#172d49",
		"art": "v1_bg_crystal"
	},
	{
		"id": "gale_spire",
		"name": "GALE SPIRE",
		"start": 49700,
		"end": 52800,
		"arrival": 50000,
		"kind": "dungeon",
		"parent": "sky",
		"dungeon": "",
		"sky": "#2f4c75",
		"art": "v1_bg_sky"
	},
	{
		"id": "mire_catacombs",
		"name": "MIRE CATACOMBS",
		"start": 52800,
		"end": 55900,
		"arrival": 53100,
		"kind": "dungeon",
		"parent": "marsh",
		"dungeon": "",
		"sky": "#1c3036",
		"art": "v1_bg_marsh"
	},
	{
		"id": "echo_labyrinth",
		"name": "ECHO LABYRINTH",
		"start": 55900,
		"end": 59000,
		"arrival": 56180,
		"kind": "dungeon",
		"parent": "ruins",
		"dungeon": "",
		"sky": "#25243c",
		"art": "v2_dungeon"
	},
	{
		"id": "nexus_core",
		"name": "HEART OF THE CORE",
		"start": 59000,
		"end": 62500,
		"arrival": 59300,
		"kind": "dungeon",
		"parent": "nexus",
		"dungeon": "",
		"sky": "#201e40",
		"art": "v1_bg_sky"
	}
]
const STORIES = {
	"hub": [
		"MIRA: The Aether Core is fracturing. Our portal network is the only safe path between realms.",
		"TARO: Each realm shelters a forgotten dungeon. Find relics, protect its people, and restore its guardian.",
		"MIRA: The Journal records your deeds. Every optional challenge offers a safe way out."
	],
	"forest": [
		"SCOUT ELIAN: Strange footprints lead beneath the Whisperwood roots.",
		"ELIAN: Explore the Rootbound Crypt for the lost ranger seals. Look for the portal at the far end."
	],
	"ruins": [
		"ARCHIVIST SEN: The Echo Labyrinth hides an older account of the falling star.",
		"SEN: The guardian may be fierce, but no puzzle here can imprison you."
	],
	"crystal": [
		"MINER VERA: The Mirror Vault reflects an impossible, broken sky.",
		"VERA: Defeat its keeper to stabilize the crystals."
	],
	"sky": [
		"PILOT AURI: The Gale Spire is suspended between the highland islands.",
		"AURI: Guard during the storm, and watch for its warning marks."
	],
	"marsh": [
		"HEALER TESS: The catacombs are swallowing our fading lanterns.",
		"TESS: The Mire Catacombs can be explored without solving a single optional rune."
	],
	"ember": [
		"FORGEMASTER BRAN: The Cinder Warden still guards the furnace.",
		"BRAN: Recover a shard, rescue Emberling, and enter the Cinder Vault."
	],
	"abyss": [
		"CAPTAIN NERA: The Abyssal Depths still breathe beneath the drowned city.",
		"NERA: Cross the coral halls and discover who commands the tide.",
		"NERA: The Tide Temple houses the Leviathan's broken oath."
	],
	"garden": [
		"GARDENER EVE: Everdawn's roots are strangled by a thorned curse.",
		"EVE: Find the Verdant Sanctum and recover the Seed of Renewal."
	],
	"nexus": [
		"MIRA: Every restored realm has brought us to the Aether Nexus.",
		"MIRA: Enter the Heart of the Core. The truth waits beyond the final portal."
	]
}
const DUNGEON_BOSSES = {
	"rootcrypt": "root_colossus",
	"mirror_vault": "mirror_keeper",
	"gale_spire": "gale_wyrm",
	"mire_catacombs": "mire_reaver",
	"echo_labyrinth": "echo_archon",
	"tide_temple": "abyss_leviathan",
	"verdant_vault": "thornheart",
	"nexus_core": "nexus_echo"
}
const QUESTS = [
	{
		"id": "q01",
		"title": "Talk to Mira",
		"event": "talk:mira",
		"target": 1,
		"region": "hub",
		"coins": 45,
		"exp": 25
	},
	{
		"id": "q02",
		"title": "Enter Whisperwood",
		"event": "visit:forest",
		"target": 1,
		"region": "hub",
		"coins": 65,
		"exp": 35
	},
	{
		"id": "q03",
		"title": "Collect three Aether Seeds",
		"event": "seed",
		"target": 3,
		"region": "hub",
		"coins": 85,
		"exp": 45
	},
	{
		"id": "q04",
		"title": "Defeat four moss slimes",
		"event": "kill:slime",
		"target": 4,
		"region": "forest",
		"coins": 105,
		"exp": 25
	},
	{
		"id": "q05",
		"title": "Defeat three dusk moths",
		"event": "kill:moth",
		"target": 3,
		"region": "forest",
		"coins": 45,
		"exp": 35
	},
	{
		"id": "q06",
		"title": "Find the Rootbound Crypt",
		"event": "visit:rootcrypt",
		"target": 1,
		"region": "forest",
		"coins": 65,
		"exp": 45
	},
	{
		"id": "q07",
		"title": "Explore the Sunken Ruins",
		"event": "visit:ruins",
		"target": 1,
		"region": "ruins",
		"coins": 85,
		"exp": 25
	},
	{
		"id": "q08",
		"title": "Banish three sentinels",
		"event": "kill:sentinel",
		"target": 3,
		"region": "ruins",
		"coins": 105,
		"exp": 35
	},
	{
		"id": "q09",
		"title": "Conquer the Echo Labyrinth",
		"event": "boss:echo_archon",
		"target": 1,
		"region": "ruins",
		"coins": 45,
		"exp": 45
	},
	{
		"id": "q10",
		"title": "Enter Crystal Hollow",
		"event": "visit:crystal",
		"target": 1,
		"region": "crystal",
		"coins": 65,
		"exp": 25
	},
	{
		"id": "q11",
		"title": "Break four crystal beetles",
		"event": "kill:crystal_bug",
		"target": 4,
		"region": "crystal",
		"coins": 85,
		"exp": 35
	},
	{
		"id": "q12",
		"title": "Defeat the Mirror Keeper",
		"event": "boss:mirror_keeper",
		"target": 1,
		"region": "crystal",
		"coins": 105,
		"exp": 45
	},
	{
		"id": "q13",
		"title": "Reach the Celestial Highlands",
		"event": "visit:sky",
		"target": 1,
		"region": "sky",
		"coins": 45,
		"exp": 25
	},
	{
		"id": "q14",
		"title": "Disperse three sky wisps",
		"event": "kill:sky_wisp",
		"target": 3,
		"region": "sky",
		"coins": 65,
		"exp": 35
	},
	{
		"id": "q15",
		"title": "Clear the Gale Spire",
		"event": "boss:gale_wyrm",
		"target": 1,
		"region": "sky",
		"coins": 85,
		"exp": 45
	},
	{
		"id": "q16",
		"title": "Investigate Shadowfen",
		"event": "visit:marsh",
		"target": 1,
		"region": "marsh",
		"coins": 105,
		"exp": 25
	},
	{
		"id": "q17",
		"title": "Dispel four bog slimes",
		"event": "kill:bog_slime",
		"target": 4,
		"region": "marsh",
		"coins": 45,
		"exp": 35
	},
	{
		"id": "q18",
		"title": "Clear the Mire Catacombs",
		"event": "boss:mire_reaver",
		"target": 1,
		"region": "marsh",
		"coins": 65,
		"exp": 45
	},
	{
		"id": "q19",
		"title": "Rescue Emberling",
		"event": "rescue:emberling",
		"target": 1,
		"region": "ember",
		"coins": 85,
		"exp": 25
	},
	{
		"id": "q20",
		"title": "Defeat four Fire Imps",
		"event": "kill:fire_imp",
		"target": 4,
		"region": "ember",
		"coins": 105,
		"exp": 35
	},
	{
		"id": "q21",
		"title": "Defeat Cinder Warden",
		"event": "boss:cinder_warden",
		"target": 1,
		"region": "ember",
		"coins": 45,
		"exp": 45
	},
	{
		"id": "q22",
		"title": "Discover the Abyss",
		"event": "visit:abyss",
		"target": 1,
		"region": "abyss",
		"coins": 65,
		"exp": 25
	},
	{
		"id": "q23",
		"title": "Defeat four Tide Stalkers",
		"event": "kill:tide_stalker",
		"target": 4,
		"region": "abyss",
		"coins": 85,
		"exp": 35
	},
	{
		"id": "q24",
		"title": "Defeat the Abyss Leviathan",
		"event": "boss:abyss_leviathan",
		"target": 1,
		"region": "abyss",
		"coins": 105,
		"exp": 45
	},
	{
		"id": "q25",
		"title": "Enter Everdawn Gardens",
		"event": "visit:garden",
		"target": 1,
		"region": "garden",
		"coins": 45,
		"exp": 25
	},
	{
		"id": "q26",
		"title": "Defeat four Thorn Knights",
		"event": "kill:thorn_knight",
		"target": 4,
		"region": "garden",
		"coins": 65,
		"exp": 35
	},
	{
		"id": "q27",
		"title": "Defeat Thornheart",
		"event": "boss:thornheart",
		"target": 1,
		"region": "garden",
		"coins": 85,
		"exp": 45
	},
	{
		"id": "q28",
		"title": "Reach the Aether Nexus",
		"event": "visit:nexus",
		"target": 1,
		"region": "nexus",
		"coins": 105,
		"exp": 25
	},
	{
		"id": "q29",
		"title": "Conquer the Heart of the Core",
		"event": "boss:nexus_echo",
		"target": 1,
		"region": "nexus",
		"coins": 45,
		"exp": 35
	},
	{
		"id": "q30",
		"title": "Visit the Everdawn Sanctum",
		"event": "visit:verdant_vault",
		"target": 1,
		"region": "garden",
		"coins": 65,
		"exp": 45
	}
]

static func region(id: String) -> Dictionary:
	for entry in REGIONS:
		if str(entry["id"]) == id:
			return entry
	return {}

static func from_x(x: float) -> String:
	for entry in REGIONS:
		if x >= float(entry["start"]) and x < float(entry["end"]):
			return str(entry["id"])
	return "hub"

static func regions_of_kind(kind: String) -> Array:
	var found: Array = []
	for entry in REGIONS:
		if entry["kind"] == kind:
			found.append(entry)
	return found

static func story(id: String) -> Array:
	return STORIES.get(id, [])
