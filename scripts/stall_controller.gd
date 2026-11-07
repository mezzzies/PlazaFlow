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

func _ready() -> void:
	global_position = Vector3(grid_coords.x, 0.0, grid_coords.y)
	_apply_catalog_stats()
	_rebuild_visual()
	_update_patience_ui(0.0)

func setup_facility(item_id: int, coords: Vector2i) -> void:
	stall_type = item_id
	grid_coords = coords
	_apply_catalog_stats()

	if is_inside_tree():
		global_position = Vector3(grid_coords.x, 0.0, grid_coords.y)
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
	return stall_type == FacilityCatalog.ItemId.PICNIC_TABLE or stall_type == FacilityCatalog.ItemId.BENCH

func is_trashcan() -> bool:
	return stall_type == FacilityCatalog.ItemId.TRASHCAN

func is_info_kiosk() -> bool:
	return stall_type == FacilityCatalog.ItemId.INFO_KIOSK

func is_lamp_post() -> bool:
	return stall_type == FacilityCatalog.ItemId.LAMP_POST

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
	for i in range(waiting_peeps.size()):
		var peep := waiting_peeps[i]
		if is_instance_valid(peep):
			var row := i / 3
			var col := i % 3
			var offset := Vector3(-0.26 + col * 0.26, 0.0, 0.34 + row * 0.24)
			peep.global_position = global_position + offset

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
