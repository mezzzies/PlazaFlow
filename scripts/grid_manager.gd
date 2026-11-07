class_name GridManager
extends Node3D

signal budget_changed(new_budget: int)
signal inventory_changed
signal facility_placed(stall: Node3D)
signal facility_removed(stall: Node3D)

enum BuildTool {
	PATH = 0,
	FOOD = 1,
	DRINK = 2,
	RESTROOM = 3,
	INFO_KIOSK = 4,
	PICNIC = 5,
	BENCH = 6,
	TRASHCAN = 7,
	LAMP_POST = 8,
	ERASE = 9,
	FENCE = 10,
	ENTRY_GATE = 11,
	EXIT_GATE = 12
}

@export var grid_half_width: int = 9
@export var grid_half_height: int = 6
@export var stall_scene: PackedScene = preload("res://scenes/stall.tscn")

@onready var path_network: PathNetwork = $PathNetwork
@onready var ground_plane: MeshInstance3D = $GroundPlane
@onready var tiles_container: Node3D = $TilesContainer
@onready var hover_cursor: MeshInstance3D = $HoverCursor

var title_diorama_container: Node3D
var city_props_container: Node3D
var grid_dots_container: Node3D
var facilities_container: Node3D
var fences_container: Node3D
var trash_container: Node3D

var placed_tile_nodes: Dictionary = {} # Vector2i -> Node3D
var fence_nodes: Dictionary = {} # Vector2i -> Node3D
var locked_cells: Dictionary = {} # Vector2i -> bool (bridges only)
var default_free_cells: Dictionary = {} # Vector2i -> bool (initial path tiles that don't refund on erase)
var obstacle_cells: Dictionary = {} # Vector2i -> String (river, pond, fountain, planter, shop)
var placed_facilities: Dictionary = {} # Vector2i -> StallController
var trash_nodes: Dictionary = {} # Vector2i -> Array[Node3D]
var ambient_cars: Array[Dictionary] = []
var title_walkers: Array[Dictionary] = []
var title_floaters: Array[Dictionary] = []
var title_anim_time: float = 0.0
var current_location_data: Dictionary = {}

var budget: int = 200000
var current_tool: int = -1
var interaction_enabled: bool = false
var is_painting: bool = false
var is_erasing: bool = false

var inventory: Dictionary = {}

var mat_pavement: StandardMaterial3D
var mat_curb: StandardMaterial3D
var mat_cursor_valid: StandardMaterial3D
var mat_cursor_invalid: StandardMaterial3D

func _ready() -> void:
	mat_pavement = ProceduralProps.get_mat("pavement_top", Color("8d7c70"), 0.86)
	mat_curb = ProceduralProps.get_mat("pavement_curb", Color("6e6057"), 0.90)

	mat_cursor_valid = StandardMaterial3D.new()
	mat_cursor_valid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_cursor_valid.albedo_color = Color(0.35, 0.92, 0.55, 0.48)
	mat_cursor_valid.roughness = 0.9

	mat_cursor_invalid = StandardMaterial3D.new()
	mat_cursor_invalid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_cursor_invalid.albedo_color = Color(0.95, 0.35, 0.35, 0.48)
	mat_cursor_invalid.roughness = 0.9

	if ground_plane:
		ground_plane.visible = false

	title_diorama_container = Node3D.new()
	title_diorama_container.name = "TitleDiorama"
	title_diorama_container.position = Vector3(0.0, 0.0, -42.0)
	add_child(title_diorama_container)
	var title_info := ProceduralProps.build_title_diorama(title_diorama_container)
	title_walkers = title_info.get("walkers", [])
	title_floaters = title_info.get("floaters", [])

	city_props_container = Node3D.new()
	city_props_container.name = "CityEnvironment"
	add_child(city_props_container)

	grid_dots_container = Node3D.new()
	grid_dots_container.name = "GridDots"
	add_child(grid_dots_container)

	facilities_container = Node3D.new()
	facilities_container.name = "FacilitiesContainer"
	add_child(facilities_container)

	fences_container = Node3D.new()
	fences_container.name = "FencesContainer"
	add_child(fences_container)

	trash_container = Node3D.new()
	trash_container.name = "TrashContainer"
	add_child(trash_container)

	var default_locs := LocationCatalog.get_locations()
	if not default_locs.is_empty():
		apply_location_scenario(default_locs[0])

func apply_location_scenario(loc_data: Dictionary) -> void:
	current_location_data = loc_data
	grid_half_width = int(loc_data.get("grid_half_width", 9))
	grid_half_height = int(loc_data.get("grid_half_height", 6))
	var pal: Dictionary = loc_data.get("palette", {})

	var path_col: Color = pal.get("path", Color("8d7c70"))
	var curb_col: Color = pal.get("curb", Color("6e6057"))
	var dot_col: Color = pal.get("grid_dot", Color("d9c19b"))

	mat_pavement = ProceduralProps.get_mat("pave_%s" % path_col.to_html(), path_col, 0.86)
	mat_curb = ProceduralProps.get_mat("curb_%s" % curb_col.to_html(), curb_col, 0.90)

	for child in city_props_container.get_children():
		child.queue_free()
	ambient_cars = ProceduralProps.build_city_environment(city_props_container, loc_data)

	obstacle_cells = loc_data.get("obstacles", {}).duplicate()
	_build_grid_dots(dot_col)
	reset_plaza_and_inventory()

func _build_grid_dots(dot_col: Color) -> void:
	for child in grid_dots_container.get_children():
		child.queue_free()

	var dot_mat := ProceduralProps.get_mat("grid_dot_%s" % dot_col.to_html(), dot_col, 0.92)
	var dot_mesh := CylinderMesh.new()
	dot_mesh.top_radius = 0.065
	dot_mesh.bottom_radius = 0.065
	dot_mesh.height = 0.014
	dot_mesh.radial_segments = 10
	dot_mesh.material = dot_mat

	for gx in range(-grid_half_width, grid_half_width + 1):
		for gz in range(-grid_half_height, grid_half_height + 1):
			var c := Vector2i(gx, gz)
			if obstacle_cells.has(c):
				continue
			var mi := MeshInstance3D.new()
			mi.mesh = dot_mesh
			mi.position = Vector3(gx, 0.012, gz)
			grid_dots_container.add_child(mi)

func _process(delta: float) -> void:
	title_anim_time += delta
	if is_instance_valid(title_diorama_container):
		title_diorama_container.position.y = sin(title_anim_time * 1.1) * 0.14
		title_diorama_container.rotation.z = sin(title_anim_time * 0.75) * 0.015
		title_diorama_container.rotation.x = cos(title_anim_time * 0.65) * 0.012

	for w in title_walkers:
		var w_node: Node3D = w["node"]
		var ang: float = float(w["angle"]) + float(w["speed"]) * delta
		w["angle"] = ang
		var rad: float = float(w["radius"])
		w_node.position = Vector3(cos(ang) * rad, absf(sin(ang * 6.0)) * 0.05, sin(ang) * rad)

	for fl in title_floaters:
		var f_node: Node3D = fl["node"]
		if not is_instance_valid(f_node):
			continue
		var base_pos: Vector3 = fl["base_pos"]
		var ph: float = float(fl["phase"])
		var spd: float = float(fl["speed"])
		var amp: float = float(fl["amp"])
		var orb: float = float(fl["orbit"])
		var t: float = title_anim_time * spd + ph
		f_node.position = base_pos + Vector3(cos(t * 0.6) * orb, sin(t) * amp, sin(t * 0.5) * (orb * 0.6))
		f_node.rotation.z = sin(t * 0.85) * 0.08
		f_node.rotation.y += float(fl.get("rot_speed", 0.2)) * delta

	var sim_speed := float(get_tree().get_meta("sim_speed", 1.0))
	var in_match := bool(get_tree().get_meta("in_match", false))
	var car_delta := delta * (sim_speed if in_match else 0.65)
	if car_delta <= 0.0:
		return

	for car_info in ambient_cars:
		var node: Node3D = car_info["node"]
		if not is_instance_valid(node):
			continue
		var dir_val: float = car_info["dir"]
		var spd: float = car_info["speed"]
		var z_lim: float = float(car_info.get("z_limit", 12.0))
		node.position.z += dir_val * spd * car_delta
		if dir_val > 0.0 and node.position.z > z_lim:
			node.position.z = -z_lim
		elif dir_val < 0.0 and node.position.z < -z_lim:
			node.position.z = z_lim

func reset_plaza_and_inventory() -> void:
	for coords in placed_facilities.keys():
		var stall: Node3D = placed_facilities[coords]
		if is_instance_valid(stall):
			stall.queue_free()
	placed_facilities.clear()

	for coords in placed_tile_nodes.keys():
		var node: Node3D = placed_tile_nodes[coords]
		if is_instance_valid(node):
			node.queue_free()
	placed_tile_nodes.clear()

	for coords in fence_nodes.keys():
		var fnode: Node3D = fence_nodes[coords]
		if is_instance_valid(fnode):
			fnode.queue_free()
	fence_nodes.clear()

	clear_all_trash()
	locked_cells.clear()
	default_free_cells.clear()

	var bridges_arr: Array = current_location_data.get("bridges", [])
	for b in bridges_arr:
		locked_cells[b as Vector2i] = true

	path_network.setup_plaza_grid(grid_half_width, grid_half_height, obstacle_cells, bridges_arr)

	budget = int(current_location_data.get("starting_budget", 200000))
	inventory.clear()
	current_tool = -1

	# Build default straight path from Left Edge (-hw, 0) to Right Edge (hw, 0)
	for gx in range(-grid_half_width, grid_half_width + 1):
		register_fixed_anchor(Vector2i(gx, 0))

	var extra_paths: Array = current_location_data.get("extra_paths", [])
	for ep in extra_paths:
		register_fixed_anchor(ep as Vector2i)

	budget_changed.emit(budget)
	inventory_changed.emit()

func add_money(amount: int) -> void:
	budget += amount
	budget_changed.emit(budget)

func spend_money(amount: int) -> bool:
	if budget < amount:
		return false
	budget -= amount
	budget_changed.emit(budget)
	return true

func can_afford_item(item_id: int) -> bool:
	if int(inventory.get(item_id, 0)) > 0:
		return true
	return budget >= FacilityCatalog.get_cost(item_id)

func _pay_for_item(item_id: int) -> bool:
	var vouchers := int(inventory.get(item_id, 0))
	if vouchers > 0:
		inventory[item_id] = vouchers - 1
		inventory_changed.emit()
		return true
	var cost := FacilityCatalog.get_cost(item_id)
	if spend_money(cost):
		inventory_changed.emit()
		return true
	return false

func set_build_tool(tool_id: int) -> void:
	current_tool = tool_id

func add_inventory_item(tool_id: int, amount: int) -> void:
	inventory[tool_id] = int(inventory.get(tool_id, 0)) + amount
	inventory_changed.emit()

func register_fixed_anchor(coords: Vector2i) -> void:
	default_free_cells[coords] = true
	_place_path_internal(coords, FacilityCatalog.ItemId.PATH_TILE)

func is_path_or_gate_tool(tool_id: int) -> bool:
	return tool_id == FacilityCatalog.ItemId.PATH_TILE or tool_id == FacilityCatalog.ItemId.ENTRY_GATE or tool_id == FacilityCatalog.ItemId.EXIT_GATE

func is_placeable_facility_tool(tool_id: int) -> bool:
	return (
		(tool_id >= FacilityCatalog.ItemId.FOOD_SHOP and tool_id <= FacilityCatalog.ItemId.LAMP_POST)
		or (tool_id >= FacilityCatalog.ItemId.FLOWER_GARDEN and tool_id <= FacilityCatalog.ItemId.STREET_STAGE)
	)

func _unhandled_input(event: InputEvent) -> void:
	if not interaction_enabled:
		if hover_cursor:
			hover_cursor.visible = false
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			is_painting = mb.pressed
			if is_painting:
				_apply_action_at_mouse(mb.position, false)
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			is_erasing = mb.pressed
			if is_erasing:
				_apply_action_at_mouse(mb.position, true)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		_update_hover_and_drag(mm.position)

func _update_hover_and_drag(screen_pos: Vector2) -> void:
	var coords_variant: Variant = _screen_to_grid(screen_pos)
	if coords_variant == null:
		if hover_cursor:
			hover_cursor.visible = false
		return

	var coords: Vector2i = coords_variant
	var erasing := is_erasing or current_tool == FacilityCatalog.ItemId.ERASE_TOOL
	if hover_cursor:
		if current_tool < 0 and not is_erasing:
			hover_cursor.visible = false
		else:
			hover_cursor.visible = true
			hover_cursor.global_position = Vector3(coords.x, 0.07, coords.y)
			var can_act := _can_apply_tool_at(coords, erasing)
			hover_cursor.material_override = mat_cursor_valid if can_act else mat_cursor_invalid

	if not erasing and current_tool < 0:
		return

	if is_painting and (is_path_or_gate_tool(current_tool) or current_tool == FacilityCatalog.ItemId.FENCE or current_tool == FacilityCatalog.ItemId.ERASE_TOOL):
		_apply_tool_at_coords(coords, erasing)
	elif is_erasing:
		_apply_tool_at_coords(coords, true)

func _apply_action_at_mouse(screen_pos: Vector2, force_erase: bool) -> void:
	var coords_variant: Variant = _screen_to_grid(screen_pos)
	if coords_variant == null:
		return
	var coords: Vector2i = coords_variant
	_update_hover_and_drag(screen_pos)
	if not force_erase and current_tool < 0:
		return
	_apply_tool_at_coords(coords, force_erase or current_tool == FacilityCatalog.ItemId.ERASE_TOOL)

func _can_apply_tool_at(coords: Vector2i, erasing: bool) -> bool:
	if erasing:
		if placed_facilities.has(coords) or fence_nodes.has(coords):
			return true
		if placed_tile_nodes.has(coords) and not locked_cells.has(coords):
			return true
		return false

	if current_tool < 0:
		return false

	if obstacle_cells.has(coords) or locked_cells.has(coords) or placed_facilities.has(coords) or fence_nodes.has(coords):
		return false

	if is_path_or_gate_tool(current_tool):
		if placed_tile_nodes.has(coords) and path_network.get_tile_type(coords) == current_tool:
			return false
		return can_afford_item(current_tool)
	elif current_tool == FacilityCatalog.ItemId.FENCE:
		return not placed_tile_nodes.has(coords) and can_afford_item(FacilityCatalog.ItemId.FENCE)
	elif is_placeable_facility_tool(current_tool):
		if placed_tile_nodes.has(coords):
			return false
		return can_afford_item(current_tool)
	return false

func _apply_tool_at_coords(coords: Vector2i, erasing: bool) -> void:
	if erasing:
		if placed_facilities.has(coords):
			_remove_facility_at(coords)
		elif fence_nodes.has(coords):
			remove_fence_at(coords)
		else:
			remove_tile_at(coords)
		return

	if current_tool < 0:
		return

	if is_path_or_gate_tool(current_tool):
		place_tile_at(coords, current_tool)
	elif current_tool == FacilityCatalog.ItemId.FENCE:
		place_fence_at(coords)
	elif is_placeable_facility_tool(current_tool):
		_place_facility_at(coords, current_tool)

func place_tile_at(coords: Vector2i, tile_type: int = FacilityCatalog.ItemId.PATH_TILE) -> void:
	if obstacle_cells.has(coords) or locked_cells.has(coords) or placed_facilities.has(coords) or fence_nodes.has(coords):
		return
	if placed_tile_nodes.has(coords) and path_network.get_tile_type(coords) == tile_type:
		return
	if not _pay_for_item(tile_type):
		return
	default_free_cells.erase(coords)
	_place_path_internal(coords, tile_type)

func _place_path_internal(coords: Vector2i, tile_type: int = FacilityCatalog.ItemId.PATH_TILE) -> bool:
	if path_network.add_path_tile(coords, tile_type):
		_refresh_tile_and_neighbors(coords)
		return true
	return false

func remove_tile_at(coords: Vector2i) -> void:
	if locked_cells.has(coords) or placed_facilities.has(coords):
		return
	if not placed_tile_nodes.has(coords):
		return

	var old_type := path_network.get_tile_type(coords)
	if path_network.remove_path_tile(coords):
		if placed_tile_nodes.has(coords):
			var node: Node3D = placed_tile_nodes[coords]
			if is_instance_valid(node):
				node.queue_free()
			placed_tile_nodes.erase(coords)
		clean_trash_on_tile(coords)
		_refresh_neighbors_only(coords)
		if not default_free_cells.has(coords) and old_type >= 0:
			add_money(FacilityCatalog.get_refund(old_type))
		default_free_cells.erase(coords)
		inventory_changed.emit()

# --- Fence Placement & Rendering ---

func place_fence_at(coords: Vector2i) -> void:
	if not _can_apply_tool_at(coords, false):
		return
	if not _pay_for_item(FacilityCatalog.ItemId.FENCE):
		return
	path_network.set_cell_impassable(coords, true)
	_refresh_fence_and_neighbors(coords)

func remove_fence_at(coords: Vector2i) -> void:
	if not fence_nodes.has(coords):
		return
	var fnode: Node3D = fence_nodes[coords]
	if is_instance_valid(fnode):
		fnode.queue_free()
	fence_nodes.erase(coords)
	path_network.clear_cell_impassable(coords)
	_refresh_fence_neighbors_only(coords)
	add_money(FacilityCatalog.get_refund(FacilityCatalog.ItemId.FENCE))
	inventory_changed.emit()

func _refresh_fence_and_neighbors(coords: Vector2i) -> void:
	_rebuild_single_fence_mesh(coords)
	_refresh_fence_neighbors_only(coords)

func _refresh_fence_neighbors_only(coords: Vector2i) -> void:
	var dirs: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
	for d in dirs:
		var n: Vector2i = coords + d
		if fence_nodes.has(n) or path_network.has_fence(n):
			_rebuild_single_fence_mesh(n)

func _rebuild_single_fence_mesh(coords: Vector2i) -> void:
	if fence_nodes.has(coords):
		var old_f: Node3D = fence_nodes[coords]
		if is_instance_valid(old_f):
			old_f.queue_free()
		fence_nodes.erase(coords)

	if not path_network.has_fence(coords):
		return

	var root := Node3D.new()
	root.position = Vector3(coords.x, 0.0, coords.y)
	fences_container.add_child(root)
	fence_nodes[coords] = root

	var lr := path_network.has_fence(coords + Vector2i.RIGHT)
	var ll := path_network.has_fence(coords + Vector2i.LEFT)
	var lu := path_network.has_fence(coords + Vector2i.UP)
	var ld := path_network.has_fence(coords + Vector2i.DOWN)
	ProceduralProps.build_fence_mesh(root, lr, ll, lu, ld)

# --- Facility Placement ---

func _place_facility_at(coords: Vector2i, item_id: int) -> void:
	if not _can_apply_tool_at(coords, false):
		return
	if not _pay_for_item(item_id):
		return

	path_network.set_cell_impassable(coords, false)
	var stall_node := stall_scene.instantiate() as StallController
	facilities_container.add_child(stall_node)
	stall_node.setup_facility(item_id, coords)
	stall_node.set_meta("item_id", item_id)
	placed_facilities[coords] = stall_node

	_refresh_neighbors_only(coords)
	facility_placed.emit(stall_node)

func _remove_facility_at(coords: Vector2i) -> void:
	if not placed_facilities.has(coords):
		return
	var stall_node: StallController = placed_facilities[coords]
	var item_id: int = int(stall_node.get_meta("item_id", stall_node.stall_type))

	stall_node.release_all_waiting_peeps()
	placed_facilities.erase(coords)
	path_network.clear_cell_impassable(coords)
	facility_removed.emit(stall_node)
	stall_node.queue_free()

	_refresh_neighbors_only(coords)
	add_money(FacilityCatalog.get_refund(item_id))
	inventory_changed.emit()

# --- Floor Trash Management ---

func spawn_trash_on_tile(coords: Vector2i) -> void:
	if not path_network.is_cell_walkable(coords):
		return
	if not trash_nodes.has(coords):
		trash_nodes[coords] = []
	var list: Array = trash_nodes[coords]
	if list.size() >= 5:
		return
	var prop := ProceduralProps.build_trash_prop(list.size())
	prop.position = Vector3(
		coords.x + randf_range(-0.26, 0.26),
		0.055,
		coords.y + randf_range(-0.26, 0.26)
	)
	trash_container.add_child(prop)
	list.append(prop)
	path_network.set_tile_trash_count(coords, list.size())

func clean_trash_on_tile(coords: Vector2i) -> int:
	if not trash_nodes.has(coords):
		return 0
	var list: Array = trash_nodes[coords]
	var count := list.size()
	for node in list:
		if is_instance_valid(node):
			(node as Node3D).queue_free()
	trash_nodes.erase(coords)
	path_network.set_tile_trash_count(coords, 0)
	return count

func get_trash_count_on_tile(coords: Vector2i) -> int:
	if not trash_nodes.has(coords):
		return 0
	return (trash_nodes[coords] as Array).size()

func get_total_trash_on_plaza() -> int:
	var total := 0
	for list in trash_nodes.values():
		total += (list as Array).size()
	return total

func clear_all_trash() -> void:
	for coords in trash_nodes.keys():
		clean_trash_on_tile(coords)
	trash_nodes.clear()
	path_network.clear_all_trash_counts()

# --- Path & Gate Mesh Rendering ---

func _refresh_tile_and_neighbors(coords: Vector2i) -> void:
	_rebuild_single_tile_mesh(coords)
	_refresh_neighbors_only(coords)

func _refresh_neighbors_only(coords: Vector2i) -> void:
	# Refresh all 8 surrounding neighbors (cardinal + diagonal) so corner connections update immediately
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			if dx == 0 and dz == 0:
				continue
			var n := coords + Vector2i(dx, dz)
			if path_network.has_path_tile(n):
				_rebuild_single_tile_mesh(n)

func _is_tile_connected_to(coords: Vector2i, offset: Vector2i) -> bool:
	var neighbor := coords + offset
	var is_road_link := (coords.x == -grid_half_width and offset.x < 0) or (coords.x == grid_half_width and offset.x > 0)
	var has_facility_neighbor := placed_facilities.has(neighbor)
	return path_network.has_path_tile(neighbor) or is_road_link or has_facility_neighbor

func _rebuild_single_tile_mesh(coords: Vector2i) -> void:
	if placed_tile_nodes.has(coords):
		var old_node: Node3D = placed_tile_nodes[coords]
		if is_instance_valid(old_node):
			old_node.queue_free()
		placed_tile_nodes.erase(coords)

	if not path_network.has_path_tile(coords):
		return

	var root := Node3D.new()
	root.position = Vector3(coords.x, 0.0, coords.y)
	tiles_container.add_child(root)
	placed_tile_nodes[coords] = root

	ProceduralProps.add_cylinder(root, 0.47, 0.48, 0.04, Vector3(0, 0.02, 0), mat_curb, 18)
	ProceduralProps.add_cylinder(root, 0.41, 0.42, 0.055, Vector3(0, 0.032, 0), mat_pavement, 18)

	# Cardinal connections:
	var dirs: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
	for d in dirs:
		if _is_tile_connected_to(coords, d):
			var offset := Vector3(d.x * 0.26, 0.0, d.y * 0.26)
			var curb_size := Vector3(0.54, 0.04, 0.94) if d.x != 0 else Vector3(0.94, 0.04, 0.54)
			var pave_size := Vector3(0.54, 0.055, 0.82) if d.x != 0 else Vector3(0.82, 0.055, 0.54)
			ProceduralProps.add_box(root, curb_size, offset + Vector3(0, 0.02, 0), mat_curb)
			ProceduralProps.add_box(root, pave_size, offset + Vector3(0, 0.032, 0), mat_pavement)

	# Corner quadrant fillers: eliminate any small gap in the center when tiles connect (e.g. 2x2, 2x3, 3x3 plazas)
	for cx in [-1, 1]:
		for cz in [-1, 1]:
			var horiz_connected := _is_tile_connected_to(coords, Vector2i(cx, 0))
			var vert_connected := _is_tile_connected_to(coords, Vector2i(0, cz))
			var diag_connected := _is_tile_connected_to(coords, Vector2i(cx, cz))
			if (horiz_connected and vert_connected) or (diag_connected and (horiz_connected or vert_connected)):
				var corner_pos := Vector3(float(cx) * 0.26, 0.0, float(cz) * 0.26)
				ProceduralProps.add_box(root, Vector3(0.54, 0.04, 0.54), corner_pos + Vector3(0, 0.02, 0), mat_curb)
				ProceduralProps.add_box(root, Vector3(0.54, 0.055, 0.54), corner_pos + Vector3(0, 0.032, 0), mat_pavement)

	var tile_type := path_network.get_tile_type(coords)
	if tile_type == FacilityCatalog.ItemId.ENTRY_GATE:
		ProceduralProps.build_gate_tile_overlay(root, true, coords.x)
	elif tile_type == FacilityCatalog.ItemId.EXIT_GATE:
		ProceduralProps.build_gate_tile_overlay(root, false, coords.x)

func _screen_to_grid(screen_pos: Vector2) -> Variant:
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return null

	var ray_origin := cam.project_ray_origin(screen_pos)
	var ray_normal := cam.project_ray_normal(screen_pos)

	var ground_plane_math := Plane(Vector3.UP, 0.0)
	var hit: Variant = ground_plane_math.intersects_ray(ray_origin, ray_normal)
	if hit == null:
		return null

	var hit_pos: Vector3 = hit
	var gx := roundi(hit_pos.x)
	var gz := roundi(hit_pos.z)

	if absi(gx) > grid_half_width or absi(gz) > grid_half_height:
		return null

	return Vector2i(gx, gz)
