class_name StaffAgent
extends Node3D

signal request_staff_task(staff: StaffAgent)
signal janitor_cleaned_cell(coords: Vector2i)
signal staff_guided_peep(peep: PeepAgent)

enum StaffType {
	JANITOR = 0,
	PLAZA_STAFF = 1,
	SECURITY = 2,
	DRONE = 3
}

enum StaffState {
	PATROLLING,
	MOVING_TO_TASK,
	WORKING_TASK,
	SEEKING_REST,
	RESTING
}

@export var staff_type: StaffType = StaffType.JANITOR
@export var walk_speed: float = 2.85

var state: StaffState = StaffState.SEEKING_REST
var energy: float = 0.0 # Starts at 0.0, requiring initial rest
const MAX_ENERGY: float = 100.0
const IDLE_DRAIN_RATE: float = 0.5
const WORK_DRAIN_RATE: float = 1.8

var rest_facilities_visited: int = 0
const REQUIRED_REST_STOPS: int = 2
var last_rest_facility_ref: Variant = null
var game_director_ref: Variant = null

var work_timer: float = 0.0
var task_cooldown: float = 0.0
var walk_phase: float = 0.0

var target_coords: Vector2i = Vector2i.ZERO
var target_peep: PeepAgent = null
var target_stall: StallController = null
var rest_access_tile: Vector2i = Vector2i.ZERO
var current_route: PackedVector2Array = []
var route_index: int = 0

var visual_model: Node3D = null
var status_label: Label3D = null

func _ready() -> void:
	walk_phase = randf() * TAU
	_build_visuals()
	_update_badge()

func setup_staff(type_id: StaffType, start_pos: Vector3, director: Variant = null) -> void:
	staff_type = type_id
	global_position = start_pos
	game_director_ref = director

	if staff_type == StaffType.DRONE:
		walk_speed = 4.2
		energy = MAX_ENERGY
		state = StaffState.PATROLLING
	else:
		energy = 0.0 # Hired staff start exhausted and need to complete initial rest cycle
		state = StaffState.SEEKING_REST
		rest_facilities_visited = 0
		if staff_type == StaffType.JANITOR:
			walk_speed = 2.65
		elif staff_type == StaffType.PLAZA_STAFF:
			walk_speed = 2.95
		else:
			walk_speed = 3.05

	if is_instance_valid(game_director_ref) and game_director_ref.has_perk("contract_labor"):
		walk_speed *= 0.80

	if is_inside_tree():
		_build_visuals()
		_update_badge()

func _build_visuals() -> void:
	for child in get_children():
		child.queue_free()

	visual_model = ProceduralProps.build_staff_visual(int(staff_type))
	add_child(visual_model)

	status_label = Label3D.new()
	status_label.position = Vector3(0, 1.05, 0)
	status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	status_label.no_depth_test = true
	status_label.font_size = 22
	status_label.outline_size = 7
	status_label.visible = false
	add_child(status_label)

func get_current_grid_coords() -> Vector2i:
	return Vector2i(roundi(global_position.x), roundi(global_position.z))

func is_active_security() -> bool:
	return staff_type == StaffType.SECURITY and state != StaffState.RESTING and state != StaffState.SEEKING_REST

func assign_janitor_target(cell: Vector2i, trashcan_stall: StallController = null, route: PackedVector2Array = PackedVector2Array()) -> void:
	target_coords = cell
	target_stall = trashcan_stall
	current_route = route
	route_index = 0
	state = StaffState.MOVING_TO_TASK
	_trim_first_point()
	_update_badge()

func assign_janitor_patrol(cell: Vector2i, route: PackedVector2Array = PackedVector2Array()) -> void:
	target_coords = cell
	target_stall = null
	current_route = route
	route_index = 0
	state = StaffState.PATROLLING
	_trim_first_point()
	_update_badge()

func assign_guide_target(peep: PeepAgent, route: PackedVector2Array) -> void:
	target_peep = peep
	current_route = route
	route_index = 0
	state = StaffState.MOVING_TO_TASK
	_trim_first_point()
	_update_badge()

func assign_rest_route(stall: StallController, access_cell: Vector2i, route: PackedVector2Array) -> void:
	target_stall = stall
	rest_access_tile = access_cell
	current_route = route
	route_index = 0
	state = StaffState.SEEKING_REST
	_trim_first_point()
	_update_badge()

func assign_path_patrol(route: PackedVector2Array) -> void:
	current_route = route
	route_index = 0
	state = StaffState.PATROLLING
	_trim_first_point()
	_update_badge()

func on_rest_facility_removed() -> void:
	if state == StaffState.RESTING or state == StaffState.SEEKING_REST:
		target_stall = null
		state = StaffState.SEEKING_REST
		global_position = Vector3(rest_access_tile.x, 0.0, rest_access_tile.y)
		_update_badge()
		request_staff_task.emit(self)

func _trim_first_point() -> void:
	if current_route.size() > 1:
		var p0 := Vector3(current_route[0].x, 0.0, current_route[0].y)
		if global_position.distance_to(p0) < 0.35:
			route_index = 1

func _drain_energy(amount: float) -> void:
	if staff_type == StaffType.DRONE:
		return
	if is_instance_valid(game_director_ref):
		if game_director_ref.has_perk("overtime_shift") and (staff_type == StaffType.PLAZA_STAFF or staff_type == StaffType.SECURITY):
			return
		if game_director_ref.has_perk("contract_labor"):
			amount *= 1.5

	energy = maxf(0.0, energy - amount)
	if energy <= 0.0 and state != StaffState.RESTING and state != StaffState.SEEKING_REST:
		rest_facilities_visited = 0
		last_rest_facility_ref = null
		state = StaffState.SEEKING_REST
		target_stall = null
		target_peep = null
		_update_badge()
		request_staff_task.emit(self)

func _recover_energy(sim_delta: float) -> void:
	var rate := 15.0
	if _is_at_staff_house():
		rate *= 2.5
	if is_instance_valid(game_director_ref):
		if game_director_ref.has_perk("energetic_staff"):
			rate *= 1.54
		if is_instance_valid(game_director_ref.grid_manager) and game_director_ref.grid_manager.has_facility_of_type(FacilityCatalog.ItemId.TEA_HOUSE):
			rate *= 1.30

	energy = minf(MAX_ENERGY, energy + rate * sim_delta)
	_update_badge()

	if energy >= MAX_ENERGY:
		rest_facilities_visited += 1
		if is_instance_valid(target_stall):
			target_stall.unregister_staff_rest(self)
			global_position = Vector3(rest_access_tile.x, 0.0, rest_access_tile.y)

		if _is_at_staff_house() or rest_facilities_visited >= REQUIRED_REST_STOPS:
			target_stall = null
			last_rest_facility_ref = null
			state = StaffState.PATROLLING
			_update_badge()
			request_staff_task.emit(self)
		else:
			# Needs a 2nd distinct relaxation facility visit
			last_rest_facility_ref = target_stall
			target_stall = null
			energy = 0.0
			state = StaffState.SEEKING_REST
			_update_badge()
			request_staff_task.emit(self)

func _is_at_staff_house() -> bool:
	return is_instance_valid(target_stall) and target_stall.has_method("is_staff_house") and target_stall.is_staff_house()

func _process(delta: float) -> void:
	var sim_speed := float(get_tree().get_meta("sim_speed", 1.0))
	var sim_delta := delta * sim_speed
	if sim_delta <= 0.0:
		return

	if state == StaffState.RESTING:
		if visual_model:
			visual_model.position.y = 0.0
			visual_model.rotation_degrees.z = 0.0
		_recover_energy(sim_delta)
		return

	if staff_type == StaffType.JANITOR or staff_type == StaffType.DRONE:
		_process_janitor(sim_delta)
	else:
		_process_guide_or_security(sim_delta)

func _process_janitor(sim_delta: float) -> void:
	if state == StaffState.SEEKING_REST:
		_process_route_movement(sim_delta, true)
		return

	if state == StaffState.WORKING_TASK:
		_drain_energy(WORK_DRAIN_RATE * sim_delta)
		work_timer -= sim_delta
		if visual_model:
			visual_model.rotation_degrees.y += sim_delta * 260.0
		if work_timer <= 0.0:
			if visual_model:
				visual_model.rotation_degrees.y = 0.0
			if is_instance_valid(target_stall) and target_stall.is_trashcan():
				target_stall.empty_trash()
			janitor_cleaned_cell.emit(target_coords)
			state = StaffState.PATROLLING
			_update_badge()
			request_staff_task.emit(self)
		return

	if current_route.is_empty() or route_index >= current_route.size():
		if state == StaffState.MOVING_TO_TASK:
			state = StaffState.WORKING_TASK
			work_timer = 0.8
			_update_badge()
		else:
			_drain_energy(IDLE_DRAIN_RATE * sim_delta)
			task_cooldown -= sim_delta
			if task_cooldown <= 0.0:
				task_cooldown = 0.5
				request_staff_task.emit(self)
		return

	if state == StaffState.MOVING_TO_TASK:
		_drain_energy(WORK_DRAIN_RATE * sim_delta)
	else:
		_drain_energy(IDLE_DRAIN_RATE * sim_delta)

	_process_route_movement(sim_delta, false)

func _process_guide_or_security(sim_delta: float) -> void:
	if state == StaffState.SEEKING_REST:
		_process_route_movement(sim_delta, true)
		return

	if state == StaffState.MOVING_TO_TASK:
		_drain_energy(WORK_DRAIN_RATE * sim_delta)
		var is_valid_thief := (
			is_instance_valid(target_peep)
			and target_peep.archetype == PeepAgent.Archetype.PICKPOCKET
			and target_peep.is_fleeing_pickpocket
		)
		var is_valid_lost := (
			is_instance_valid(target_peep)
			and target_peep.state == PeepAgent.AgentState.LOST
		)
		if not is_valid_thief and not is_valid_lost:
			target_peep = null
			state = StaffState.PATROLLING
			request_staff_task.emit(self)
			return
		if global_position.distance_to(target_peep.global_position) <= 1.25:
			if is_valid_thief:
				target_peep.show_unhappy_complaint(-1, "Busted! 👮")
				target_peep.queue_free()
			else:
				target_peep.guide_out_of_lost()
				staff_guided_peep.emit(target_peep)
			target_peep = null
			state = StaffState.PATROLLING
			_update_badge()
			request_staff_task.emit(self)
			return

	if state == StaffState.PATROLLING:
		# If security is on congested tile (>= 6 occupants), drain accelerated energy for Crowd Aura
		var is_crowd_aura := false
		if staff_type == StaffType.SECURITY and is_instance_valid(game_director_ref):
			var occ: int = game_director_ref.grid_manager.path_network.get_tile_occupancy(get_current_grid_coords())
			is_crowd_aura = (occ >= 6)
		_drain_energy((WORK_DRAIN_RATE if is_crowd_aura else IDLE_DRAIN_RATE) * sim_delta)

		task_cooldown -= sim_delta
		if task_cooldown <= 0.0:
			task_cooldown = 0.7
			request_staff_task.emit(self)

	if current_route.is_empty() or route_index >= current_route.size():
		request_staff_task.emit(self)
		return

	_process_route_movement(sim_delta, false)

func _process_route_movement(sim_delta: float, is_seeking_rest_route: bool) -> void:
	if current_route.is_empty() or route_index >= current_route.size():
		if is_seeking_rest_route:
			state = StaffState.RESTING
			if is_instance_valid(target_stall):
				target_stall.register_staff_rest(self)
			_update_badge()
		else:
			request_staff_task.emit(self)
		return

	var pt := current_route[route_index]
	var target_3d := Vector3(pt.x, 0.0, pt.y)
	var offset := target_3d - global_position
	offset.y = 0.0
	var dist := offset.length()
	var step := walk_speed * sim_delta

	if dist <= step:
		global_position = target_3d
		route_index += 1
		if route_index >= current_route.size():
			if is_seeking_rest_route:
				state = StaffState.RESTING
				if is_instance_valid(target_stall):
					target_stall.register_staff_rest(self)
				_update_badge()
			elif state == StaffState.MOVING_TO_TASK and (staff_type == StaffType.JANITOR or staff_type == StaffType.DRONE):
				state = StaffState.WORKING_TASK
				work_timer = 0.8
				_update_badge()
			else:
				request_staff_task.emit(self)
	else:
		global_position += offset.normalized() * step
		_animate_walk(sim_delta)

func _animate_walk(sim_delta: float) -> void:
	walk_phase += sim_delta * 10.5
	if visual_model:
		if staff_type == StaffType.DRONE:
			visual_model.position.y = 0.35 + sin(walk_phase * 0.8) * 0.06
			visual_model.rotation_degrees.y += sim_delta * 180.0
		else:
			visual_model.position.y = absf(sin(walk_phase)) * 0.06
			visual_model.rotation_degrees.z = sin(walk_phase) * 3.8

func _update_badge() -> void:
	if not status_label:
		return
	if state == StaffState.RESTING:
		status_label.visible = true
		status_label.text = "💤"
		status_label.modulate = Color(0.65, 0.90, 1.0)
	elif state == StaffState.SEEKING_REST:
		status_label.visible = true
		status_label.text = "😓 Need Rest"
		status_label.modulate = Color(1.0, 0.75, 0.45)
	else:
		status_label.visible = false
