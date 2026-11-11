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
		"art": "v5_generated_abyss"
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
		"art": "v5_generated_tide_temple"
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
		"art": "v5_generated_garden"
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
		"art": "v5_generated_verdant_vault"
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
		"art": "v5_generated_nexus"
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
		"art": "v5_generated_rootcrypt"
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
		"art": "v5_generated_nexus_core"
	},
	{"id": "root_gallery", "name": "ROOTBOUND MURAL GALLERY", "start": 62500, "end": 65100, "arrival": 62730, "kind": "trial", "parent": "rootcrypt", "dungeon": "", "sky": "#173d37", "art": "v6_generated_rootgallery"},
	{"id": "prism_annex", "name": "PRISM CIRCUIT ANNEX", "start": 65100, "end": 67700, "arrival": 65330, "kind": "trial", "parent": "mirror_vault", "dungeon": "", "sky": "#174259", "art": "v6_generated_prismannex"},
	{"id": "wind_observatory", "name": "WIND OBSERVATORY", "start": 67700, "end": 70300, "arrival": 67930, "kind": "trial", "parent": "gale_spire", "dungeon": "", "sky": "#335477", "art": "v6_generated_windobservatory"},
	{"id": "bog_lanterns", "name": "LANTERN CHAMBER", "start": 70300, "end": 72900, "arrival": 70530, "kind": "trial", "parent": "mire_catacombs", "dungeon": "", "sky": "#203e38", "art": "v6_generated_boglanterns"},
	{"id": "forge_engine", "name": "LIVING FORGE ENGINE", "start": 72900, "end": 75500, "arrival": 73130, "kind": "trial", "parent": "cinder", "dungeon": "", "sky": "#5c332e", "art": "v6_generated_forgeengine"},
	{"id": "tide_control", "name": "TIDAL CONTROL VAULT", "start": 75500, "end": 78100, "arrival": 75730, "kind": "trial", "parent": "tide_temple", "dungeon": "", "sky": "#114764", "art": "v6_generated_tidecontrol"},
	{"id": "seed_arbor", "name": "SEEDWEAVE ARBOR", "start": 78100, "end": 80700, "arrival": 78330, "kind": "trial", "parent": "verdant_vault", "dungeon": "", "sky": "#2c6445", "art": "v6_generated_seedarbor"},
	{"id": "nexus_memory", "name": "STAR MEMORY CHAMBER", "start": 80700, "end": 83300, "arrival": 80930, "kind": "trial", "parent": "nexus_core", "dungeon": "", "sky": "#38306b", "art": "v6_generated_nexusmemory"}
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
	],
	"mirror_vault": [
		"VERA: The mirror bridge remembers yesterday, but the wall yields only to today.",
		"VERA: SHIFT at the first prism, cross the bridge in the PAST, then SHIFT at the second prism to PRESENT.",
		"VERA: Reach the Chrono Relic beyond the unlocked timeline gate."
	],
	"echo_labyrinth": [
		"ARCHIVIST SEN: The chamber remembers the hero's last ten seconds.",
		"SEN: Touch the recorder, walk onto the glowing pressure plate, then hold it.",
		"SEN: When your ghost replays the past, hurry through the gate to claim the hidden relic."
	],
	"root_gallery": ["ELIAN: The ranger mural was shattered into eight fragments.", "ELIAN: The empty ninth space lets you shift each piece into its rightful place."],
	"prism_annex": ["VERA: Reflected light must cross the crystal pipes to the exit.", "VERA: Turn each prism to join the shining path."],
	"wind_observatory": ["AURI: Three dials govern the observatory's ancient winds.", "AURI: Pairwise sums reveal the true numbers. The mechanism has no timer."],
	"bog_lanterns": ["TESS: The witchlights remember a forgotten constellation.", "TESS: Watch the glyphs and repeat the memory sequence. No harm comes from mistakes."],
	"forge_engine": ["BRAN: The Living Forge needs its fire conduits reconnected.", "BRAN: Rotate the molten pathways and restore the power."],
	"tide_control": ["NERA: Balance the three tidal valves to free the ancient reservoir.", "NERA: Every dial changes the pressure of two channels. The equations are your guide."],
	"seed_arbor": ["EVE: The Seedweave image must be rebuilt to bloom.", "EVE: Slide the ancient mosaic pieces into their correct arrangement."],
	"nexus_memory": ["MIRA: The heart recognizes memories, not brute force.", "MIRA: Study its changing glyphs and replay them to seal the rift."]
}
const TRIALS = {
	"root_gallery": {"name": "ROOTBOUND MURAL GALLERY", "parent": "rootcrypt", "type": "mosaic", "theme": "forest", "art": "v6_generated_rootgallery", "reward": 105},
	"prism_annex": {"name": "PRISM CIRCUIT ANNEX", "parent": "mirror_vault", "type": "circuit", "theme": "crystal", "art": "v6_generated_prismannex", "reward": 105},
	"wind_observatory": {"name": "WIND OBSERVATORY", "parent": "gale_spire", "type": "logic", "theme": "sky", "art": "v6_generated_windobservatory", "reward": 105},
	"bog_lanterns": {"name": "LANTERN CHAMBER", "parent": "mire_catacombs", "type": "memory", "theme": "marsh", "art": "v6_generated_boglanterns", "reward": 105},
	"forge_engine": {"name": "LIVING FORGE ENGINE", "parent": "cinder", "type": "circuit", "theme": "ember", "art": "v6_generated_forgeengine", "reward": 160},
	"tide_control": {"name": "TIDAL CONTROL VAULT", "parent": "tide_temple", "type": "logic", "theme": "abyss", "art": "v6_generated_tidecontrol", "reward": 160},
	"seed_arbor": {"name": "SEEDWEAVE ARBOR", "parent": "verdant_vault", "type": "mosaic", "theme": "garden", "art": "v6_generated_seedarbor", "reward": 160},
	"nexus_memory": {"name": "STAR MEMORY CHAMBER", "parent": "nexus_core", "type": "memory", "theme": "nexus", "art": "v6_generated_nexusmemory", "reward": 160}
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
	},
	{"id": "q31", "title": "Discover ROOTBOUND MURAL GALLERY", "event": "visit:root_gallery", "target": 1, "region": "rootcrypt", "coins": 85, "exp": 45},
	{"id": "q32", "title": "Solve ROOTBOUND MURAL GALLERY puzzle", "event": "trial:root_gallery", "target": 1, "region": "rootcrypt", "coins": 145, "exp": 75},
	{"id": "q33", "title": "Discover PRISM CIRCUIT ANNEX", "event": "visit:prism_annex", "target": 1, "region": "mirror_vault", "coins": 95, "exp": 45},
	{"id": "q34", "title": "Solve PRISM CIRCUIT ANNEX puzzle", "event": "trial:prism_annex", "target": 1, "region": "mirror_vault", "coins": 160, "exp": 75},
	{"id": "q35", "title": "Discover WIND OBSERVATORY", "event": "visit:wind_observatory", "target": 1, "region": "gale_spire", "coins": 105, "exp": 45},
	{"id": "q36", "title": "Solve WIND OBSERVATORY puzzle", "event": "trial:wind_observatory", "target": 1, "region": "gale_spire", "coins": 175, "exp": 75},
	{"id": "q37", "title": "Discover LANTERN CHAMBER", "event": "visit:bog_lanterns", "target": 1, "region": "mire_catacombs", "coins": 115, "exp": 45},
	{"id": "q38", "title": "Solve LANTERN CHAMBER puzzle", "event": "trial:bog_lanterns", "target": 1, "region": "mire_catacombs", "coins": 190, "exp": 75},
	{"id": "q39", "title": "Discover LIVING FORGE ENGINE", "event": "visit:forge_engine", "target": 1, "region": "cinder", "coins": 125, "exp": 45},
	{"id": "q40", "title": "Solve LIVING FORGE ENGINE puzzle", "event": "trial:forge_engine", "target": 1, "region": "cinder", "coins": 205, "exp": 75},
	{"id": "q41", "title": "Discover TIDAL CONTROL VAULT", "event": "visit:tide_control", "target": 1, "region": "tide_temple", "coins": 135, "exp": 45},
	{"id": "q42", "title": "Solve TIDAL CONTROL VAULT puzzle", "event": "trial:tide_control", "target": 1, "region": "tide_temple", "coins": 220, "exp": 75},
	{"id": "q43", "title": "Discover SEEDWEAVE ARBOR", "event": "visit:seed_arbor", "target": 1, "region": "verdant_vault", "coins": 145, "exp": 45},
	{"id": "q44", "title": "Solve SEEDWEAVE ARBOR puzzle", "event": "trial:seed_arbor", "target": 1, "region": "verdant_vault", "coins": 235, "exp": 75},
	{"id": "q45", "title": "Discover STAR MEMORY CHAMBER", "event": "visit:nexus_memory", "target": 1, "region": "nexus_core", "coins": 155, "exp": 45},
	{"id": "q46", "title": "Solve STAR MEMORY CHAMBER puzzle", "event": "trial:nexus_memory", "target": 1, "region": "nexus_core", "coins": 250, "exp": 75},
	{"id": "q47", "title": "Follow the hidden ranger cache", "event": "secret:forest", "target": 1, "region": "forest", "coins": 90, "exp": 45},
	{"id": "q48", "title": "Recover the Echo Labyrinth relic trail", "event": "secret:ruins", "target": 1, "region": "ruins", "coins": 105, "exp": 52},
	{"id": "q49", "title": "Find the crystal prospector's secret", "event": "secret:crystal", "target": 1, "region": "crystal", "coins": 120, "exp": 59},
	{"id": "q50", "title": "Discover the highland sky cache", "event": "secret:sky", "target": 1, "region": "sky", "coins": 135, "exp": 66},
	{"id": "q51", "title": "Uncover a lost witchlight stash", "event": "secret:marsh", "target": 1, "region": "marsh", "coins": 150, "exp": 73},
	{"id": "q52", "title": "Recover the Cinder Forge supplies", "event": "secret:ember", "target": 1, "region": "ember", "coins": 165, "exp": 80},
	{"id": "q53", "title": "Retrieve a drowned city's relic", "event": "secret:abyss", "target": 1, "region": "abyss", "coins": 180, "exp": 87},
	{"id": "q54", "title": "Find an Everdawn bloom treasure", "event": "secret:garden", "target": 1, "region": "garden", "coins": 195, "exp": 94},
	{"id": "q55", "title": "Recover a lost Aether star fragment", "event": "secret:nexus", "target": 1, "region": "nexus", "coins": 210, "exp": 101},
	{"id": "q56", "title": "Open the secret forge cache", "event": "secret:cinder", "target": 1, "region": "cinder", "coins": 225, "exp": 108},
	{"id": "q57", "title": "Leap to the Ranger's Skyshard", "event": "skyshard:forest", "target": 1, "region": "forest", "coins": 110, "exp": 65},
	{"id": "q58", "title": "Retrieve the Echo Observatory Skyshard", "event": "skyshard:ruins", "target": 1, "region": "ruins", "coins": 122, "exp": 71},
	{"id": "q59", "title": "Scale the Prism Ledges", "event": "skyshard:crystal", "target": 1, "region": "crystal", "coins": 134, "exp": 77},
	{"id": "q60", "title": "Ascend the Floating Ledges", "event": "skyshard:sky", "target": 1, "region": "sky", "coins": 146, "exp": 83},
	{"id": "q61", "title": "Rise Above the Cursed Bog", "event": "skyshard:marsh", "target": 1, "region": "marsh", "coins": 158, "exp": 89},
	{"id": "q62", "title": "Climb the Emberfall Watchtower", "event": "skyshard:ember", "target": 1, "region": "ember", "coins": 170, "exp": 95},
	{"id": "q63", "title": "Reach the Drowned City's Beacon", "event": "skyshard:abyss", "target": 1, "region": "abyss", "coins": 182, "exp": 101},
	{"id": "q64", "title": "Ascend the Everdawn Canopy", "event": "skyshard:garden", "target": 1, "region": "garden", "coins": 194, "exp": 107},
	{"id": "q65", "title": "Recover the Star-Crown Skyshard", "event": "skyshard:nexus", "target": 1, "region": "nexus", "coins": 206, "exp": 113},
	{"id": "q66", "title": "Traverse the Rootbound Upper Gallery", "event": "skyshard:rootcrypt", "target": 1, "region": "rootcrypt", "coins": 218, "exp": 119},
	{"id": "q67", "title": "Reach the Tidal Temple's High Altar", "event": "skyshard:tide_temple", "target": 1, "region": "tide_temple", "coins": 230, "exp": 125},
	{"id": "q68", "title": "Climb the Heart of the Core", "event": "skyshard:nexus_core", "target": 1, "region": "nexus_core", "coins": 242, "exp": 131},
	{"id": "q69", "title": "Replay Your Shadow in the Echo Labyrinth", "event": "trial:echo_labyrinth", "target": 1, "region": "echo_labyrinth", "coins": 180, "exp": 95},
	{"id": "q70", "title": "Cross the Past Bridge and Restore the Chrono Relic", "event": "trial:mirror_shift", "target": 1, "region": "mirror_vault", "coins": 160, "exp": 90},
	{"id": "q71", "title": "Find the Three Sonar-Only Ruins Glyphs", "event": "trial:sonar_glyphs", "target": 1, "region": "ruins", "coins": 165, "exp": 100}
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
