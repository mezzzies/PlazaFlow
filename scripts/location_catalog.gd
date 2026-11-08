class_name LocationCatalog
extends RefCounted

## Static catalog of playable locations (scenarios).
## Each location has its own cozy palette, starting budget, layout obstacles, and gameplay rules.
## Need weights correspond to: [FOOD, DRINK, RESTROOM, SIT]

static func _row(z: int, xs: Array, kind: String, into: Dictionary) -> void:
	for x in xs:
		into[Vector2i(int(x), z)] = kind

static func get_locations() -> Array[Dictionary]:
	var list: Array[Dictionary] = []

	# ------------------------------------------------------------------
	# 1. Old Town Square — Small/Compact Plaza (19x13 tiles, 200k 🪙 budget)
	# ------------------------------------------------------------------
	var old_obs: Dictionary = {}
	old_obs[Vector2i(0, -3)] = "fountain"
	old_obs[Vector2i(-5, 3)] = "planter"
	old_obs[Vector2i(5, 3)] = "planter"
	old_obs[Vector2i(-5, -3)] = "planter"
	old_obs[Vector2i(5, -3)] = "planter"

	list.append({
		"id": "old_town",
		"name": "Old Town Square",
		"region": "Historic District",
		"difficulty": 1,
		"grid_half_width": 9,
		"grid_half_height": 6,
		"map_size_label": "Small (19×13)",
		"starting_budget": 200000,
		"grant_multiplier": 1.0,
		"short_desc": "Cozy cobblestone square with a central fountain.",
		"accent_color": Color("d96b4f"),
		"description": "A cozy cobblestone square tucked between two quiet streets. Townsfolk stroll through day and night.",
		"rule": "Map: Small (19×13) | Starting Budget: 200k 🪙. Balanced visitor needs with a central fountain and planters.",
		"spawn_interval": 9.0,
		"need_weights": [1.0, 0.9, 1.0, 0.9],
		"start_time": 0.05,
		"obstacles": old_obs,
		"extra_paths": [],
		"bridges": [],
		"station": {},
		"palette": {
			"backdrop": Color("efe4d2"),
			"ground": Color("ecd6b0"),
			"ground_edge": Color("c9ad86"),
			"grid_dot": Color("d9c19b"),
			"path": Color("8d7c70"),
			"curb": Color("6e6057"),
			"road": Color("6c7280"),
			"sidewalk": Color("d8c9b1"),
			"stripe": Color("f6efe3"),
			"water": Color("8fcadb"),
			"tree_a": Color("8cbf7f"),
			"tree_b": Color("6ea577"),
			"hedge": Color("82b37b"),
			"houses": [Color("eaa57f"), Color("f3d2a2"), Color("c7d8a2"), Color("e5b3a3"), Color("b9d3df")],
			"roof": Color("b86a5b"),
			"flowers": [Color("f28b82"), Color("fbd38d"), Color("f6f1e7")],
		},
	})

	# ------------------------------------------------------------------
	# 2. Riverside Park — Large Scenic Park (25x17 tiles, 230k 🪙 budget)
	# ------------------------------------------------------------------
	var river_obs: Dictionary = {}
	for z in range(-8, 9):
		if z == 0:
			continue
		river_obs[Vector2i(2, z)] = "river"
		river_obs[Vector2i(3, z)] = "river"
	for c in [Vector2i(-6, 4), Vector2i(-5, 4), Vector2i(-6, 5), Vector2i(-5, 5)]:
		river_obs[c] = "pond"
	river_obs[Vector2i(-7, -4)] = "planter"
	river_obs[Vector2i(8, 4)] = "planter"

	list.append({
		"id": "riverside",
		"name": "Riverside Park",
		"region": "Green Belt",
		"difficulty": 2,
		"grid_half_width": 12,
		"grid_half_height": 8,
		"map_size_label": "Large (25×17)",
		"starting_budget": 230000,
		"grant_multiplier": 1.1,
		"short_desc": "Leafy park split by a stream & wooden bridge.",
		"accent_color": Color("4f9e69"),
		"description": "A spacious leafy park split by a gentle stream. Only the old wooden bridge connects both banks.",
		"rule": "Map: Large (25×17) | Starting Budget: 230k 🪙. High Elder & Picnic/Bench demand; river cannot be built on.",
		"spawn_interval": 8.5,
		"need_weights": [0.9, 1.0, 0.8, 1.5],
		"start_time": 0.05,
		"obstacles": river_obs,
		"extra_paths": [],
		"bridges": [Vector2i(2, 0), Vector2i(3, 0)],
		"river_span": Vector2(1.5, 3.5),
		"ponds": [{"center": Vector2(-5.5, 4.5), "radius": 1.15}],
		"station": {},
		"palette": {
			"backdrop": Color("dfead6"),
			"ground": Color("bcdba5"),
			"ground_edge": Color("8fb77a"),
			"grid_dot": Color("a9cd92"),
			"path": Color("a27b5d"),
			"curb": Color("7c5c46"),
			"road": Color("6a7181"),
			"sidewalk": Color("d5d8c5"),
			"stripe": Color("f5f2e7"),
			"water": Color("82c6d3"),
			"tree_a": Color("6fb06a"),
			"tree_b": Color("4f9562"),
			"hedge": Color("62a364"),
			"houses": [Color("f1c8a0"), Color("ece3c6"), Color("d9a9a1"), Color("b9cfdb"), Color("e7c3d5")],
			"roof": Color("8a6a5c"),
			"flowers": [Color("f6a5c0"), Color("fde68a"), Color("ffffff")],
		},
	})

	# ------------------------------------------------------------------
	# 3. Night Market — Medium Market Lanes (23x13 tiles, 190k 🪙 budget)
	# ------------------------------------------------------------------
	var market_obs: Dictionary = {}
	_row(-2, [-9, -8, -5, -4, -1, 1, 4, 5, 8, 9], "shop", market_obs)
	_row(2, [-9, -8, -5, -4, -1, 1, 4, 5, 8, 9], "shop", market_obs)

	list.append({
		"id": "night_market",
		"name": "Lantern Market",
		"region": "Old Harbour Lanes",
		"difficulty": 2,
		"grid_half_width": 11,
		"grid_half_height": 6,
		"map_size_label": "Medium (23×13)",
		"starting_budget": 190000,
		"grant_multiplier": 1.05,
		"short_desc": "Evening market lanes under warm lanterns.",
		"accent_color": Color("825fa8"),
		"description": "Rows of closed market stalls form narrow alleys under strings of warm lanterns. Opens at dusk.",
		"rule": "Map: Medium (23×13) | Starting Budget: 190k 🪙. High Food & Drink demand; market rows create bottlenecks.",
		"spawn_interval": 8.0,
		"need_weights": [1.6, 1.4, 0.8, 0.7],
		"start_time": 0.4,
		"obstacles": market_obs,
		"extra_paths": [],
		"bridges": [],
		"lantern_rows": [-2.0, 2.0],
		"station": {},
		"palette": {
			"backdrop": Color("ddd3e6"),
			"ground": Color("cfc1de"),
			"ground_edge": Color("a493bc"),
			"grid_dot": Color("bba9d0"),
			"path": Color("615774"),
			"curb": Color("463f58"),
			"road": Color("525769"),
			"sidewalk": Color("bfb6cc"),
			"stripe": Color("efe9f4"),
			"water": Color("8fb8d8"),
			"tree_a": Color("7caa92"),
			"tree_b": Color("5f8f7d"),
			"hedge": Color("6c9b86"),
			"houses": [Color("f2b8a2"), Color("f6d79b"), Color("a9c4e0"), Color("d8a7c8"), Color("b8dcc4")],
			"roof": Color("6c4f78"),
			"flowers": [Color("f9a8d4"), Color("fcd34d"), Color("c4b5fd")],
		},
	})

	# ------------------------------------------------------------------
	# 4. Central Station — Grand Concourse (29x19 tiles, 240k 🪙 budget)
	# ------------------------------------------------------------------
	var station_obs: Dictionary = {}
	station_obs[Vector2i(-6, -4)] = "fountain"
	station_obs[Vector2i(6, -4)] = "fountain"
	station_obs[Vector2i(-8, 4)] = "planter"
	station_obs[Vector2i(-3, 4)] = "planter"
	station_obs[Vector2i(3, 4)] = "planter"
	station_obs[Vector2i(8, 4)] = "planter"

	list.append({
		"id": "central_station",
		"name": "Central Station Plaza",
		"region": "Downtown Transit Hub",
		"difficulty": 3,
		"grid_half_width": 14,
		"grid_half_height": 9,
		"map_size_label": "Grand (29×19)",
		"starting_budget": 240000,
		"grant_multiplier": 1.15,
		"short_desc": "Busy transit concourse with regular train waves.",
		"accent_color": Color("437ea8"),
		"description": "A grand expansive concourse in front of the city's main train station. Trains arrive like clockwork.",
		"rule": "Map: Grand (29×19) | Starting Budget: 240k 🪙. Train waves every 40s with hurried Business commuters.",
		"spawn_interval": 8.0,
		"need_weights": [1.0, 1.2, 1.5, 0.7],
		"start_time": 0.05,
		"obstacles": station_obs,
		"extra_paths": [],
		"bridges": [],
		"station": {"coords": Vector2i(0, -9), "burst_interval": 40.0, "burst_size": 5},
		"palette": {
			"backdrop": Color("e4e7eb"),
			"ground": Color("d6dce3"),
			"ground_edge": Color("a9b2be"),
			"grid_dot": Color("c1c9d3"),
			"path": Color("5d6777"),
			"curb": Color("434b59"),
			"road": Color("4e5664"),
			"sidewalk": Color("c5cbd3"),
			"stripe": Color("f5f6f8"),
			"water": Color("8cc3d9"),
			"tree_a": Color("8fc08a"),
			"tree_b": Color("6da57d"),
			"hedge": Color("7cae81"),
			"houses": [Color("f0b49e"), Color("f5dca0"), Color("a8c8e2"), Color("c6b3dc"), Color("bfe0cf")],
			"roof": Color("56606e"),
			"flowers": [Color("fb923c"), Color("fde047"), Color("f0f9ff")],
		},
	})

	return list

static func difficulty_text(level: int) -> String:
	match level:
		1:
			return "Relaxed"
		2:
			return "Moderate"
		_:
			return "Challenging"

static func difficulty_color(level: int) -> Color:
	match level:
		1:
			return Color("5aa86e")
		2:
			return Color("d99a2b")
		_:
			return Color("d9603f")
