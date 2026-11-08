class_name PathNetwork
extends Node

signal network_changed

const MAX_PEOPLE_PER_TILE: int = 10
var max_people_per_tile: int = 10
const GRASS_WEIGHT: float = 8.5

var astar: AStar2D = AStar2D.new()
var astar_crowded: AStar2D = AStar2D.new()
var astar_freewalk: AStar2D = AStar2D.new()
var astar_staff: AStar2D = AStar2D.new()

var grid_half_width: int = 9
var grid_half_height: int = 6

var occupied_cells: Dictionary = {} # Vector2i -> int (ItemId.PATH_TILE, ENTRY_GATE, EXIT_GATE)
var impassable_cells: Dictionary = {} # Vector2i -> bool (water, obstacles, facilities, fences)
var water_cells: Dictionary = {} # Vector2i -> bool (river, pond)
var fence_cells: Dictionary = {} # Vector2i -> bool
var tile_occupants: Dictionary = {} # Vector2i -> Array[Node3D]
var tile_trash_counts: Dictionary = {} # Vector2i -> int

func _ready() -> void:
	clear_all()

func clear_all() -> void:
	astar.clear()
	astar_crowded.clear()
	astar_freewalk.clear()
	astar_staff.clear()
	occupied_cells.clear()
	impassable_cells.clear()
	water_cells.clear()
	fence_cells.clear()
	tile_occupants.clear()
	tile_trash_counts.clear()

func setup_plaza_grid(hw: int, hh: int, obstacles: Dictionary, bridges: Array = []) -> void:
	clear_all()
	grid_half_width = hw
	grid_half_height = hh

	var bridge_lookup: Dictionary = {}
	for b in bridges:
		bridge_lookup[b as Vector2i] = true

	for cell_key in obstacles.keys():
		var c: Vector2i = cell_key
		if bridge_lookup.has(c):
			continue
		var kind := str(obstacles[cell_key])
		impassable_cells[c] = true
		if kind == "river" or kind == "pond":
			water_cells[c] = true

	# Add all walkable plaza cells to the 3 navigation graphs
	for gx in range(-grid_half_width, grid_half_width + 1):
		for gz in range(-grid_half_height, grid_half_height + 1):
			var c := Vector2i(gx, gz)
			if impassable_cells.has(c):
				continue
			_add_walkable_cell_to_graphs(c)

	# Connect all neighbors respecting gate directions
	for gx in range(-grid_half_width, grid_half_width + 1):
		for gz in range(-grid_half_height, grid_half_height + 1):
			var c := Vector2i(gx, gz)
			if not impassable_cells.has(c):
				_rebuild_connections_for_cell(c)

	network_changed.emit()

func expand_grid_height(new_hh: int) -> void:
	if new_hh <= grid_half_height:
		return
	var old_hh := grid_half_height
	grid_half_height = new_hh

	# Add new rows to graphs
	for gz in range(old_hh + 1, new_hh + 1):
		for row_z in [-gz, gz]:
			for gx in range(-grid_half_width, grid_half_width + 1):
				var c := Vector2i(gx, row_z)
				if not impassable_cells.has(c):
					_add_walkable_cell_to_graphs(c)

	# Reconnect new rows and their boundary neighbor rows
	for gz in range(old_hh, new_hh + 1):
		for row_z in [-gz, gz]:
			for gx in range(-grid_half_width, grid_half_width + 1):
				var c := Vector2i(gx, row_z)
				if not impassable_cells.has(c):
					_rebuild_connections_for_cell(c)

	network_changed.emit()

func cell_to_id(coords: Vector2i) -> int:
	return (coords.x + 10000) * 100000 + (coords.y + 10000)

func is_in_bounds(coords: Vector2i) -> bool:
	return absi(coords.x) <= grid_half_width and absi(coords.y) <= grid_half_height

func is_water_cell(coords: Vector2i) -> bool:
	return water_cells.has(coords)

func is_cell_walkable(coords: Vector2i) -> bool:
	return is_in_bounds(coords) and not impassable_cells.has(coords)

func has_path_tile(coords: Vector2i) -> bool:
	return occupied_cells.has(coords)

func get_tile_type(coords: Vector2i) -> int:
	return int(occupied_cells.get(coords, -1))

func has_fence(coords: Vector2i) -> bool:
	return fence_cells.has(coords)

func _add_walkable_cell_to_graphs(coords: Vector2i) -> void:
	var id := cell_to_id(coords)
	var is_path := occupied_cells.has(coords)
	var base_w := 1.0 if is_path else GRASS_WEIGHT
	var free_w := 1.0 if is_path else 1.25

	if not astar.has_point(id):
		astar.add_point(id, Vector2(coords.x, coords.y), base_w)
	else:
		astar.set_point_weight_scale(id, base_w)

	if not astar_crowded.has_point(id):
		astar_crowded.add_point(id, Vector2(coords.x, coords.y), base_w)
	else:
		astar_crowded.set_point_weight_scale(id, base_w)

	if not astar_freewalk.has_point(id):
		astar_freewalk.add_point(id, Vector2(coords.x, coords.y), free_w)
	else:
		astar_freewalk.set_point_weight_scale(id, free_w)

	if not astar_staff.has_point(id):
		astar_staff.add_point(id, Vector2(coords.x, coords.y), 1.0)
	else:
		astar_staff.set_point_weight_scale(id, 1.0)

func _remove_cell_from_graphs(coords: Vector2i) -> void:
	var id := cell_to_id(coords)
	if astar.has_point(id):
		astar.remove_point(id)
	if astar_crowded.has_point(id):
		astar_crowded.remove_point(id)
	if astar_freewalk.has_point(id):
		astar_freewalk.remove_point(id)
	if astar_staff.has_point(id):
		astar_staff.remove_point(id)

func get_inward_direction(coords: Vector2i) -> Vector2i:
	if coords.x <= -grid_half_width:
		return Vector2i.RIGHT
	if coords.x >= grid_half_width:
		return Vector2i.LEFT
	if coords.y <= -grid_half_height:
		return Vector2i.DOWN
	if coords.y >= grid_half_height:
		return Vector2i.UP
	if absi(coords.x) >= absi(coords.y):
		return Vector2i(-signi(coords.x), 0)
	return Vector2i(0, -signi(coords.y))

func _can_traverse_directed(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	if not is_cell_walkable(from_cell) or not is_cell_walkable(to_cell):
		return false
	var step := to_cell - from_cell
	var from_type := int(occupied_cells.get(from_cell, -1))
	var to_type := int(occupied_cells.get(to_cell, -1))

	# ENTRY_GATE (ItemId.ENTRY_GATE): only allows inward movement into the plaza
	if from_type == FacilityCatalog.ItemId.ENTRY_GATE:
		var inward := get_inward_direction(from_cell)
		if step != inward:
			return false
	if to_type == FacilityCatalog.ItemId.ENTRY_GATE:
		# Cannot step into an Entry Gate from inside the plaza
		return false

	# EXIT_GATE (ItemId.EXIT_GATE): only allows outward movement out of the plaza
	if from_type == FacilityCatalog.ItemId.EXIT_GATE:
		# Cannot step back into the plaza from an Exit Gate
		return false
	if to_type == FacilityCatalog.ItemId.EXIT_GATE:
		var outward := -get_inward_direction(to_cell)
		if step != outward:
			return false

	return true

func _rebuild_connections_for_cell(coords: Vector2i) -> void:
	var id := cell_to_id(coords)
	if not astar.has_point(id):
		return
	var neighbors: Array[Vector2i] = [
		coords + Vector2i.RIGHT,
		coords + Vector2i.LEFT,
		coords + Vector2i.UP,
		coords + Vector2i.DOWN
	]
	for n in neighbors:
		if not is_in_bounds(n):
			continue
		var n_id := cell_to_id(n)
		if not astar.has_point(n_id):
			continue
		for g in [astar, astar_crowded, astar_freewalk]:
			if g.are_points_connected(id, n_id, false):
				g.disconnect_points(id, n_id, false)
			if g.are_points_connected(n_id, id, false):
				g.disconnect_points(n_id, id, false)
			if _can_traverse_directed(coords, n):
				g.connect_points(id, n_id, false)
			if _can_traverse_directed(n, coords):
				g.connect_points(n_id, id, false)

		if astar_staff.are_points_connected(id, n_id, false):
			astar_staff.disconnect_points(id, n_id, false)
		if astar_staff.are_points_connected(n_id, id, false):
			astar_staff.disconnect_points(n_id, id, false)
		if is_cell_walkable(coords) and is_cell_walkable(n):
			# Staff can freely walk bidirectionally between any adjacent walkable cells, including gates
			astar_staff.connect_points(id, n_id, true)

func _rebuild_cell_and_neighbors(coords: Vector2i) -> void:
	_rebuild_connections_for_cell(coords)
	var dirs: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
	for d in dirs:
		var n: Vector2i = coords + d
		if is_cell_walkable(n):
			_rebuild_connections_for_cell(n)

func add_path_tile(coords: Vector2i, tile_type: int = FacilityCatalog.ItemId.PATH_TILE) -> bool:
	if impassable_cells.has(coords) or not is_in_bounds(coords):
		return false
	if occupied_cells.has(coords) and int(occupied_cells[coords]) == tile_type:
		return false

	occupied_cells[coords] = tile_type
	_add_walkable_cell_to_graphs(coords)
	_refresh_crowded_weight(coords, get_tile_occupancy(coords))
	_rebuild_cell_and_neighbors(coords)
	network_changed.emit()
	return true

func remove_path_tile(coords: Vector2i) -> bool:
	if not occupied_cells.has(coords):
		return false
	occupied_cells.erase(coords)
	if not impassable_cells.has(coords):
		_add_walkable_cell_to_graphs(coords)
		_rebuild_cell_and_neighbors(coords)
	network_changed.emit()
	return true

func set_cell_impassable(coords: Vector2i, is_fence_block: bool = false) -> void:
	impassable_cells[coords] = true
	if is_fence_block:
		fence_cells[coords] = true
	occupied_cells.erase(coords)
	tile_occupants.erase(coords)
	_remove_cell_from_graphs(coords)
	_rebuild_cell_and_neighbors(coords)
	network_changed.emit()

func clear_cell_impassable(coords: Vector2i) -> void:
	if water_cells.has(coords):
		return
	impassable_cells.erase(coords)
	fence_cells.erase(coords)
	_add_walkable_cell_to_graphs(coords)
	_rebuild_cell_and_neighbors(coords)
	network_changed.emit()

# --- Dynamic Edge Gates Discovery ---

func get_entry_gate_cells() -> Array[Vector2i]:
	var edge_gates: Array[Vector2i] = []
	for cell_key in occupied_cells.keys():
		var c: Vector2i = cell_key
		var t := int(occupied_cells[c])
		if t == FacilityCatalog.ItemId.ENTRY_GATE:
			edge_gates.append(c)
	return edge_gates

func get_exit_gate_cells(preferred_side_x: int = 0) -> Array[Vector2i]:
	var preferred: Array[Vector2i] = []
	var all_exits: Array[Vector2i] = []
	for cell_key in occupied_cells.keys():
		var c: Vector2i = cell_key
		var t := int(occupied_cells[c])
		if t == FacilityCatalog.ItemId.EXIT_GATE:
			all_exits.append(c)
			if preferred_side_x != 0 and signi(c.x) == signi(preferred_side_x):
				preferred.append(c)
	if not preferred.is_empty():
		return preferred
	return all_exits

func get_route(from_coords: Vector2i, to_coords: Vector2i, avoid_crowds: bool = false, free_walk: bool = false, is_staff: bool = false) -> PackedVector2Array:
	var from_id := cell_to_id(from_coords)
	var to_id := cell_to_id(to_coords)

	if is_staff:
		if astar_staff.has_point(from_id) and astar_staff.has_point(to_id):
			return astar_staff.get_point_path(from_id, to_id)
		return PackedVector2Array()

	var graph := astar_freewalk if free_walk else (astar_crowded if avoid_crowds else astar)
	if graph.has_point(from_id) and graph.has_point(to_id):
		return graph.get_point_path(from_id, to_id)
	return PackedVector2Array()

func get_staff_route(from_coords: Vector2i, to_coords: Vector2i) -> PackedVector2Array:
	return get_route(from_coords, to_coords, false, true, true)

func get_adjacent_access_tile(facility_coords: Vector2i) -> Variant:
	var dirs: Array[Vector2i] = [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]
	# Prefer adjacent Walk Tiles first
	for d in dirs:
		var n := facility_coords + d
		if occupied_cells.has(n):
			return n
	# Otherwise any walkable non-blocked neighbor
	for d in dirs:
		var n := facility_coords + d
		if is_cell_walkable(n):
			return n
	return null

# --- Crowd Occupancy & Collision ---

func update_agent_tile(agent: Node3D, old_coords: Vector2i, new_coords: Vector2i) -> void:
	if old_coords == new_coords:
		return
	unregister_agent_from_tile(agent, old_coords)
	register_agent_on_tile(agent, new_coords)

func register_agent_on_tile(agent: Node3D, coords: Vector2i) -> void:
	if not tile_occupants.has(coords):
		tile_occupants[coords] = []
	var list: Array = tile_occupants[coords]
	if not list.has(agent):
		list.append(agent)
		_refresh_crowded_weight(coords, get_tile_occupancy(coords))

func unregister_agent_from_tile(agent: Node3D, coords: Vector2i) -> void:
	if not tile_occupants.has(coords):
		return
	var list: Array = tile_occupants[coords]
	list.erase(agent)
	_refresh_crowded_weight(coords, get_tile_occupancy(coords))

func _refresh_crowded_weight(coords: Vector2i, count: int) -> void:
	var id := cell_to_id(coords)
	if astar_crowded.has_point(id):
		var base_w := 1.0 if occupied_cells.has(coords) else GRASS_WEIGHT
		var w := base_w + float(count * count) * 0.45
		astar_crowded.set_point_weight_scale(id, w)

func get_tile_occupancy(coords: Vector2i) -> int:
	if not tile_occupants.has(coords):
		return 0
	var list: Array = tile_occupants[coords]
	var total_people := 0
	for i in range(list.size() - 1, -1, -1):
		var occ = list[i]
		if not is_instance_valid(occ):
			list.remove_at(i)
		elif occ.has_method("get_tile_headcount"):
			total_people += int(occ.get_tile_headcount())
		else:
			total_people += 1
	return total_people

func is_tile_full(coords: Vector2i, incoming_headcount: int = 1) -> bool:
	return get_tile_occupancy(coords) + incoming_headcount > max_people_per_tile

func set_tile_trash_count(coords: Vector2i, count: int) -> void:
	if count <= 0:
		tile_trash_counts.erase(coords)
	else:
		tile_trash_counts[coords] = count

func get_tile_trash_count(coords: Vector2i) -> int:
	return int(tile_trash_counts.get(coords, 0))

func clear_all_trash_counts() -> void:
	tile_trash_counts.clear()

## 3 levels of cleanliness:
## Clean (0 trash) = 100% speed
## Dirty (1-2 trash) = 80% speed
## Max Dirty (3+ trash) = 60% speed
func get_cleanliness_multiplier(trash_count: int) -> float:
	if trash_count <= 0:
		return 1.0 # Clean = 100%
	elif trash_count <= 2:
		return 0.80 # Dirty = 80%
	else:
		return 0.60 # Max Dirty (3+) = 60%

func get_crowd_speed_multiplier(coords: Vector2i, has_security_boost: bool = false, trash_count: int = -1, has_express_arterial: bool = false) -> float:
	var n := clampi(get_tile_occupancy(coords), 1, max_people_per_tile)
	var mult := lerpf(1.0, 0.05, float(n - 1) / float(maxi(2, max_people_per_tile) - 1))
	if has_security_boost and n > 1:
		mult = clampf(maxf(mult * 1.40, 0.35), 0.35, 1.0)
	var actual_trash := trash_count if trash_count >= 0 else get_tile_trash_count(coords)
	mult *= get_cleanliness_multiplier(actual_trash)
	if has_express_arterial and has_path_tile(coords):
		mult *= 1.35
	return mult

func compute_separation_push(agent: Node3D, coords: Vector2i) -> Vector3:
	if not tile_occupants.has(coords):
		return Vector3.ZERO
	var list: Array = tile_occupants[coords]
	var push := Vector3.ZERO
	var my_pos := agent.global_position
	var min_sep := 0.25
	for other in list:
		if other == agent or not is_instance_valid(other):
			continue
		var diff := my_pos - (other as Node3D).global_position
		diff.y = 0.0
		var dist := diff.length()
		if dist < min_sep and dist > 0.001:
			push += diff.normalized() * ((min_sep - dist) / min_sep)
		elif dist <= 0.001:
			push += Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized() * 0.5
	return push.limit_length(0.85)
