class_name StallController
extends Node3D

signal stall_overwhelmed
signal peep_served(peep: Node3D, revenue: int, stall: Node3D)
signal peep_frustrated(peep: Node3D)

@export var stall_type: int = 1 # Matches FacilityCatalog.ItemId (1..8)
@export var grid_coords: Vector2i = Vector2i(0, 0)
@export var max_waiting_capacity: int = 6
@export var overload_grace_period: float = 9.0
@export var service_duration: float = 2.2
@export var is_player_placed: bool = true

var need_fulfilled: int = -1 # Matches FacilityCatalog.NeedType (0..3) or -1
var base_income: int = 0
var facility_name: String = "Facility"

var waiting_peeps: Array[Node3D] = []
var resting_staff: Array[Node3D] = []
var overload_timer: float = 0.0
var service_timer: float = 0.0
var is_overloaded: bool = false

# Trashcan specific state
var stored_trash: int = 0
var max_trash_capacity: int = 15

var facility_size: Vector2i = Vector2i(1, 1)
var rotation_idx: int = 0
var entrance_offset: Vector2i = Vector2i(0, 1)
var occupied_cells: Array[Vector2i] = []

static func calculate_entrance_offset(rot_size: Vector2i, rot: int) -> Vector2i:
	var mid_x := int((rot_size.x - 1) / 2)
	var mid_y := int((rot_size.y - 1) / 2)
	match posmod(rot, 4):
		0: # South (+Z)
			return Vector2i(mid_x, rot_size.y)
		1: # East (+X, when rotated +90 deg around Y)
			return Vector2i(rot_size.x, mid_y)
		2: # North (-Z)
			return Vector2i(mid_x, -1)
		3: # West (-X, when rotated +270 deg around Y)
			return Vector2i(-1, mid_y)
	return Vector2i(mid_x, rot_size.y)

func get_entrance_coords() -> Vector2i:
	return grid_coords + entrance_offset

func _ready() -> void:
	var center_offset := Vector3(float(facility_size.x - 1) * 0.5, 0.0, float(facility_size.y - 1) * 0.5)
	global_position = Vector3(grid_coords.x, 0.0, grid_coords.y) + center_offset
	rotation.y = float(rotation_idx) * (PI / 2.0)
	_apply_catalog_stats()
	_rebuild_visual()
	_update_patience_ui(0.0)

func setup_facility(item_id: int, coords: Vector2i, rot_idx: int = 0, size: Vector2i = Vector2i(1, 1), occ_cells: Array[Vector2i] = []) -> void:
	stall_type = item_id
	grid_coords = coords
	rotation_idx = rot_idx
	facility_size = size
	occupied_cells = occ_cells if not occ_cells.is_empty() else [coords]
	entrance_offset = calculate_entrance_offset(facility_size, rotation_idx)
	_apply_catalog_stats()

	var center_offset := Vector3(float(facility_size.x - 1) * 0.5, 0.0, float(facility_size.y - 1) * 0.5)
	global_position = Vector3(grid_coords.x, 0.0, grid_coords.y) + center_offset
	rotation.y = float(rotation_idx) * (PI / 2.0)

	_rebuild_visual()
	_update_patience_ui(0.0)

func _apply_catalog_stats() -> void:
	var info := FacilityCatalog.get_item(stall_type)
	facility_name = str(info.get("name", "Facility"))
	base_income = int(info.get("income", 0))
	service_duration = float(info.get("service_time", 2.0))
	max_waiting_capacity = int(info.get("capacity", 5))
	need_fulfilled = int(info.get("need", -1))

func _rebuild_visual() -> void:
	if has_node("StallVisual"):
		var old_vis := get_node("StallVisual")
		remove_child(old_vis)
		old_vis.queue_free()

	var new_vis := ProceduralProps.build_facility_visual(stall_type)
	add_child(new_vis)

func is_comfort_facility() -> bool:
	return (
		stall_type == FacilityCatalog.ItemId.PICNIC_TABLE
		or stall_type == FacilityCatalog.ItemId.BENCH
		or stall_type == FacilityCatalog.ItemId.FLOWER_GARDEN
		or stall_type == FacilityCatalog.ItemId.DUCK_POND
		or stall_type == FacilityCatalog.ItemId.STREET_STAGE
		or stall_type == FacilityCatalog.ItemId.VINTAGE_CAROUSEL
		or stall_type == FacilityCatalog.ItemId.FERRIS_WHEEL
		or stall_type == FacilityCatalog.ItemId.ZEN_SHRINE
		or stall_type == FacilityCatalog.ItemId.WISHING_WELL
		or stall_type == FacilityCatalog.ItemId.CYBER_ARCADE
		or stall_type == FacilityCatalog.ItemId.BOTANICAL_DOME
		or stall_type == FacilityCatalog.ItemId.PLANETARIUM
		or stall_type == FacilityCatalog.ItemId.SKATE_BOWL
		or stall_type == FacilityCatalog.ItemId.OBSERVATION_TOWER
		or stall_type == FacilityCatalog.ItemId.CIRCUS_TENT
		or stall_type == FacilityCatalog.ItemId.STEAM_TRAIN
		or stall_type == FacilityCatalog.ItemId.DIAMOND_PAVILION
	)

func is_dining_facility() -> bool:
	return (
		stall_type == FacilityCatalog.ItemId.FOOD_SHOP
		or stall_type == FacilityCatalog.ItemId.DRINK_STALL
		or stall_type == FacilityCatalog.ItemId.COFFEE_ROASTER
		or stall_type == FacilityCatalog.ItemId.GOLDEN_MONOLITH
		or stall_type == FacilityCatalog.ItemId.GELATO_PAVILION
		or stall_type == FacilityCatalog.ItemId.BIERGARTEN
		or stall_type == FacilityCatalog.ItemId.TEA_HOUSE
	)

func is_staff_house() -> bool:
	return stall_type == FacilityCatalog.ItemId.STAFF_HOUSE

func is_relaxation_facility() -> bool:
	return is_comfort_facility() or is_dining_facility() or is_staff_house() or stall_type == FacilityCatalog.ItemId.SPA_BATHHOUSE

func is_trashcan() -> bool:
	return stall_type == FacilityCatalog.ItemId.TRASHCAN

func is_info_kiosk() -> bool:
	return (
		stall_type == FacilityCatalog.ItemId.INFO_KIOSK
		or stall_type == FacilityCatalog.ItemId.DUCK_POND
		or stall_type == FacilityCatalog.ItemId.GRAND_CLOCKTOWER
		or stall_type == FacilityCatalog.ItemId.OBSERVATION_TOWER
	)

func is_lamp_post() -> bool:
	return stall_type == FacilityCatalog.ItemId.LAMP_POST or stall_type == FacilityCatalog.ItemId.PLANETARIUM

func can_accept_trash() -> bool:
	return is_trashcan() and stored_trash < max_trash_capacity

func deposit_trash() -> void:
	if is_trashcan():
		stored_trash = mini(max_trash_capacity, stored_trash + 1)
		_update_patience_ui(0.0)

func empty_trash() -> void:
	if is_trashcan():
		stored_trash = 0
		_update_patience_ui(0.0)

func _process(delta: float) -> void:
	var sim_speed := float(get_tree().get_meta("sim_speed", 1.0))
	var sim_delta := delta * sim_speed
	if sim_delta <= 0.0:
		return

	if need_fulfilled < 0:
		return

	for i in range(waiting_peeps.size() - 1, -1, -1):
		if not is_instance_valid(waiting_peeps[i]):
			waiting_peeps.remove_at(i)

	if not waiting_peeps.is_empty():
		service_timer += sim_delta
		if service_timer >= service_duration:
			service_timer = 0.0
			serve_peep(waiting_peeps[0])
	else:
		service_timer = 0.0

	if waiting_peeps.size() > max_waiting_capacity:
		is_overloaded = true
		overload_timer += sim_delta
		_update_patience_ui(overload_timer / overload_grace_period)

		if overload_timer >= overload_grace_period:
			overload_timer = 0.0
			var frustrated_peep: Node3D = waiting_peeps.pop_back()
			_arrange_queue_positions()
			if is_instance_valid(frustrated_peep) and frustrated_peep.has_method("on_facility_frustrated"):
				frustrated_peep.on_facility_frustrated()
			peep_frustrated.emit(frustrated_peep)
			stall_overwhelmed.emit()
	else:
		if is_overloaded or overload_timer > 0.0:
			overload_timer = maxf(0.0, overload_timer - sim_delta * 1.5)
			_update_patience_ui(overload_timer / overload_grace_period)
			if overload_timer == 0.0:
				is_overloaded = false
		else:
			_update_patience_ui(0.0)

func register_arrival(peep: Node3D) -> void:
	if not waiting_peeps.has(peep):
		waiting_peeps.append(peep)
		_arrange_queue_positions()
		_update_patience_ui(overload_timer / overload_grace_period)

func register_staff_rest(staff: Node3D) -> void:
	if not resting_staff.has(staff):
		resting_staff.append(staff)
		staff.global_position = global_position + Vector3(0.32, 0.0, -0.28)
		_update_patience_ui(0.0)

func unregister_staff_rest(staff: Node3D) -> void:
	resting_staff.erase(staff)
	_update_patience_ui(0.0)

func remove_waiting_peep(peep: Node3D) -> void:
	if waiting_peeps.has(peep):
		waiting_peeps.erase(peep)
		_arrange_queue_positions()
		_update_patience_ui(overload_timer / overload_grace_period)

func release_all_waiting_peeps() -> void:
	var copy := waiting_peeps.duplicate()
	waiting_peeps.clear()
	for peep in copy:
		if is_instance_valid(peep) and peep.has_method("on_facility_removed"):
			peep.on_facility_removed()
	var staff_copy := resting_staff.duplicate()
	resting_staff.clear()
	for stf in staff_copy:
		if is_instance_valid(stf) and stf.has_method("on_rest_facility_removed"):
			stf.on_rest_facility_removed()

func serve_peep(peep: Node3D) -> void:
	waiting_peeps.erase(peep)
	var earned := base_income
	if is_instance_valid(peep):
		if peep.get("archetype") == 2 and earned > 0: # Business customer tips 1.5x
			earned = int(roundf(float(earned) * 1.5))
		if peep.has_method("on_facility_served"):
			peep.on_facility_served(stall_type)
	peep_served.emit(peep, earned, self)
	_arrange_queue_positions()
	_update_patience_ui(overload_timer / overload_grace_period)

func _arrange_queue_positions() -> void:
	var ent := get_entrance_coords()
	var ent_world := Vector3(ent.x, 0.0, ent.y)
	var forward := Vector3(entrance_offset.x, 0.0, entrance_offset.y).normalized()
	if forward.length_squared() < 0.1:
		forward = Vector3(0, 0, 1)
	var side := Vector3(-forward.z, 0.0, forward.x)

	for i in range(waiting_peeps.size()):
		var peep := waiting_peeps[i]
		if is_instance_valid(peep):
			var row := i / 2
			var col := i % 2
			var q_offset := (side * (-0.16 + col * 0.32)) + (forward * (float(row) * 0.32))
			peep.global_position = ent_world + q_offset

func _update_patience_ui(progress: float) -> void:
	if not has_node("PatienceLabel"):
		return
	var label: Label3D = $PatienceLabel
	if is_trashcan():
		label.visible = stored_trash >= max_trash_capacity
		label.text = "🗑️ Full!"
		label.modulate = Color(1.0, 0.45, 0.35)
		return
	if need_fulfilled < 0:
		label.visible = false
		return

	var clamped := clampf(progress, 0.0, 1.0)
	label.visible = clamped > 0.0
	if clamped > 0.0:
		label.text = "⚠️ %d%%" % roundi(clamped * 100.0)
		label.modulate = Color(1.0, 0.35, 0.30)
