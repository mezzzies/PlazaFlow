class_name PeepAgent
extends Node3D

signal need_routing_refresh(peep: PeepAgent)
signal exited_unfulfilled(peep: PeepAgent)
signal exited_happy_passthrough(peep: PeepAgent)
signal wants_to_dispose_trash(peep: PeepAgent, tile_coords: Vector2i)

enum NeedType { FOOD = 0, DRINK = 1, RESTROOM = 2, SIT = 3 }
enum Archetype { NORMAL = 0, ELDER = 1, BUSINESS = 2, COUPLE = 3, CHILD = 4 }
enum AgentState {
	WALKING_TO_FACILITY,
	WALKING_UNFULFILLED,
	WALKING_PASSTHROUGH,
	LOST,
	QUEUING,
	EXITING_HAPPY,
	EXITING_FRUSTRATED
}

@export var walk_speed: float = 2.6
@export var need: NeedType = NeedType.FOOD
@export var archetype: Archetype = Archetype.NORMAL

var state: AgentState = AgentState.WALKING_PASSTHROUGH
var needs_queue: Array[int] = []
var total_initial_needs: int = 0
var fulfilled_needs_count: int = 0

var need_patience_timer: float = 0.0
var max_need_patience: float = 28.0
var lost_timer: float = 0.0
var has_been_lost: bool = false
var blocked_wait_timer: float = 0.0
var has_diverted_from_block: bool = false
var has_emitted_unfulfilled: bool = false

var has_pending_trash: bool = false
var trash_timer: float = 0.0

var prefers_crowd_diversion: bool = true
var is_walking_freely: bool = false
var head_popup_timer: float = 0.0

var crowd_aversion: float = 1.0
var distance_tolerance: float = 1.0
var personality_whim_seed: float = 0.0

var path_net_ref: PathNetwork = null
var registered_tile: Vector2i = Vector2i(-999, -999)
var is_registered_on_tile: bool = false

var spawn_coords: Vector2i = Vector2i(-9, 0)
var exit_coords: Vector2i = Vector2i(9, 0)
var current_route: PackedVector2Array = []
var target_index: int = 0
var destination_stall: Node3D = null
var facility_access_tile: Vector2i = Vector2i.ZERO
var is_satisfied: bool = false
var is_waiting_in_queue: bool = false
var walk_phase: float = 0.0
var sub_tile_offset: Vector3 = Vector3.ZERO

var current_tile_security_boost: bool = false
var current_tile_trash_count: int = 0

@onready var visual_model: Node3D = $PawnMesh
@onready var status_label: Label3D = $MissingPathIcon

const NEED_LABELS: Dictionary = {
	NeedType.FOOD: "Food",
	NeedType.DRINK: "Drink",
	NeedType.RESTROOM: "WC",
	NeedType.SIT: "Seat"
}

const NEED_COLORS: Dictionary = {
	NeedType.FOOD: Color("e8654a"),
	NeedType.DRINK: Color("4ab59c"),
	NeedType.RESTROOM: Color("4a90ba"),
	NeedType.SIT: Color("f0b43a")
}

func _ready() -> void:
	walk_phase = randf() * TAU
	sub_tile_offset = Vector3(randf_range(-0.14, 0.14), 0.0, randf_range(-0.14, 0.14))
	_rebuild_character_mesh()
	if status_label:
		status_label.visible = false

func _exit_tree() -> void:
	_unregister_current_tile()

func setup_citizen_full(
	new_archetype: Archetype,
	initial_needs: Array[int],
	start_cell: Vector2i,
	end_cell: Vector2i,
	net: PathNetwork
) -> void:
	archetype = new_archetype
	needs_queue = initial_needs.duplicate()
	total_initial_needs = needs_queue.size()
	fulfilled_needs_count = 0
	spawn_coords = start_cell
	exit_coords = end_cell
	path_net_ref = net
	has_emitted_unfulfilled = false
	head_popup_timer = 0.0

	# Most customers follow the recommended walking tiles; a small percentage casually wander off-path
	is_walking_freely = (randf() < 0.12) and (archetype != Archetype.BUSINESS)

	# Thought of their own: individual personality regarding crowd tolerance and willingness to walk
	crowd_aversion = randf_range(0.85, 1.25)
	distance_tolerance = randf_range(0.85, 1.25)
	personality_whim_seed = randf_range(-3.0, 3.0)

	match archetype:
		Archetype.ELDER:
			walk_speed = 1.35
			max_need_patience = 36.0
			prefers_crowd_diversion = true
			crowd_aversion = randf_range(1.15, 1.65)
			distance_tolerance = randf_range(0.55, 0.85)
		Archetype.BUSINESS:
			walk_speed = 3.80
			max_need_patience = 18.0
			prefers_crowd_diversion = false
			crowd_aversion = randf_range(2.2, 3.5)
			distance_tolerance = randf_range(1.2, 1.7)
		Archetype.COUPLE:
			walk_speed = 2.60
			max_need_patience = 28.0
			prefers_crowd_diversion = randf() < 0.65
			crowd_aversion = randf_range(1.4, 2.0)
			distance_tolerance = randf_range(0.9, 1.3)
		Archetype.CHILD:
			walk_speed = 2.95
			max_need_patience = 26.0
			prefers_crowd_diversion = randf() < 0.7
			crowd_aversion = randf_range(0.7, 1.3)
			personality_whim_seed = randf_range(-5.5, 5.5)
			if randf() < 0.25:
				is_walking_freely = true
		_:
			walk_speed = 2.60
			max_need_patience = 28.0
			prefers_crowd_diversion = randf() < 0.65

	if not needs_queue.is_empty():
		need = needs_queue[0] as NeedType
		state = AgentState.WALKING_UNFULFILLED
	else:
		state = AgentState.WALKING_PASSTHROUGH
		is_satisfied = true

	need_patience_timer = 0.0
	_update_tile_registration(start_cell)

	if is_inside_tree():
		_rebuild_character_mesh()
		if status_label:
			status_label.visible = false

func get_tile_headcount() -> int:
	return 2 if archetype == Archetype.COUPLE else 1

func has_active_need() -> bool:
	return not needs_queue.is_empty()

func get_active_need() -> int:
	if needs_queue.is_empty():
		return -1
	return needs_queue[0]

func _rebuild_character_mesh() -> void:
	if has_node("PawnMesh"):
		var old_mesh := get_node("PawnMesh")
		remove_child(old_mesh)
		old_mesh.queue_free()

	var primary_col := Color("8ca892")
	if not needs_queue.is_empty():
		primary_col = NEED_COLORS.get(needs_queue[0], Color("e8654a"))
	elif archetype == Archetype.COUPLE:
		primary_col = Color("e58a7b")

	var new_mesh := ProceduralProps.build_citizen_visual(int(archetype), primary_col)
	add_child(new_mesh)
	visual_model = new_mesh

func show_happy_emoji() -> void:
	if not status_label:
		return
	status_label.text = "❤️"
	status_label.font_size = 28
	status_label.modulate = Color(1.0, 0.45, 0.55)
	status_label.visible = true
	head_popup_timer = 2.8

func show_unhappy_complaint(unmet_need: int = -1, custom_reason: String = "") -> void:
	if not status_label:
		return
	var reason_txt := custom_reason
	if unmet_need >= 0 and NEED_LABELS.has(unmet_need):
		reason_txt = "Need %s!" % str(NEED_LABELS[unmet_need])
	elif reason_txt.is_empty():
		reason_txt = "Unhappy!"
	status_label.text = "😠 %s" % reason_txt
	status_label.font_size = 22
	status_label.modulate = Color(1.0, 0.38, 0.35)
	status_label.visible = true
	head_popup_timer = 3.5

func assign_facility_route(route: PackedVector2Array, stall: Node3D, access_cell: Vector2i) -> void:
	destination_stall = stall
	facility_access_tile = access_cell
	current_route = route
	target_index = 0
	is_waiting_in_queue = false
	state = AgentState.WALKING_TO_FACILITY
	_trim_initial_waypoint()

func assign_passthrough_route(route: PackedVector2Array) -> void:
	destination_stall = null
	current_route = route
	target_index = 0
	is_waiting_in_queue = false
	if state == AgentState.LOST:
		pass
	elif is_satisfied or total_initial_needs == 0:
		state = AgentState.WALKING_PASSTHROUGH if fulfilled_needs_count == 0 else AgentState.EXITING_HAPPY
	elif state != AgentState.EXITING_FRUSTRATED:
		state = AgentState.WALKING_UNFULFILLED
	_trim_initial_waypoint()

func trigger_lost_state(wander_route: PackedVector2Array) -> void:
	if state == AgentState.QUEUING or state == AgentState.EXITING_HAPPY or state == AgentState.EXITING_FRUSTRATED:
		return
	has_been_lost = true
	is_walking_freely = true
	state = AgentState.LOST
	lost_timer = 14.0
	destination_stall = null
	current_route = wander_route
	target_index = 0
	_trim_initial_waypoint()

func guide_out_of_lost() -> void:
	if state != AgentState.LOST:
		return
	lost_timer = 0.0
	is_walking_freely = false
	need_patience_timer = maxf(0.0, need_patience_timer - 6.0)
	state = AgentState.WALKING_UNFULFILLED if has_active_need() else AgentState.WALKING_PASSTHROUGH
	show_happy_emoji()
	need_routing_refresh.emit(self)

func _become_unhappy_and_walk_freely(fallback_reason: String = "Crowded!") -> void:
	var unmet_need := get_active_need()
	needs_queue.clear()
	is_satisfied = false
	is_walking_freely = true
	destination_stall = null
	state = AgentState.EXITING_FRUSTRATED
	show_unhappy_complaint(unmet_need, fallback_reason)
	if not has_emitted_unfulfilled:
		has_emitted_unfulfilled = true
		exited_unfulfilled.emit(self)
	need_routing_refresh.emit(self)

func _trim_initial_waypoint() -> void:
	if current_route.size() > 1:
		var first_pt := Vector3(current_route[0].x, 0.0, current_route[0].y)
		if global_position.distance_to(first_pt) < 0.35:
			target_index = 1

func get_current_grid_coords() -> Vector2i:
	return Vector2i(roundi(global_position.x), roundi(global_position.z))

func _update_tile_registration(new_cell: Vector2i) -> void:
	if not path_net_ref:
		return
	if is_registered_on_tile and registered_tile == new_cell:
		return
	if is_registered_on_tile:
		path_net_ref.unregister_agent_from_tile(self, registered_tile)
	registered_tile = new_cell
	path_net_ref.register_agent_on_tile(self, registered_tile)
	is_registered_on_tile = true

func _unregister_current_tile() -> void:
	if path_net_ref and is_registered_on_tile:
		path_net_ref.unregister_agent_from_tile(self, registered_tile)
		is_registered_on_tile = false

func _process(delta: float) -> void:
	var sim_speed := float(get_tree().get_meta("sim_speed", 1.0))
	var sim_delta := delta * sim_speed
	if sim_delta <= 0.0:
		return

	# Auto-hide temporary head emoji / complaint after a few seconds
	if head_popup_timer > 0.0:
		head_popup_timer -= sim_delta
		if head_popup_timer <= 0.0 and status_label:
			status_label.visible = false

	if state == AgentState.QUEUING:
		if visual_model:
			visual_model.position.y = 0.0
			visual_model.rotation_degrees.z = 0.0
		return

	# Litter drop countdown after using Dining/Picnic facility
	if has_pending_trash:
		trash_timer -= sim_delta
		if trash_timer <= 0.0:
			has_pending_trash = false
			wants_to_dispose_trash.emit(self, get_current_grid_coords())

	# Handle LOST timer
	if state == AgentState.LOST:
		lost_timer -= sim_delta
		if lost_timer <= 0.0:
			if has_active_need() and archetype == Archetype.ELDER:
				_become_unhappy_and_walk_freely("Lost!")
			else:
				state = AgentState.WALKING_UNFULFILLED if has_active_need() else AgentState.WALKING_PASSTHROUGH
				need_routing_refresh.emit(self)
			return

	# Track patience for unfulfilled active need
	if has_active_need() and (state == AgentState.WALKING_UNFULFILLED or state == AgentState.WALKING_TO_FACILITY):
		need_patience_timer += sim_delta
		if need_patience_timer >= max_need_patience:
			_become_unhappy_and_walk_freely("Too Slow!")
			return

	if current_route.is_empty() or target_index >= current_route.size():
		return

	var cur_cell := get_current_grid_coords()
	_update_tile_registration(cur_cell)

	var target_2d := current_route[target_index]
	var next_cell := Vector2i(roundi(target_2d.x), roundi(target_2d.y))

	# Check 10-person tile capacity before stepping into a new cell (unless already walking freely to escape)
	if not is_walking_freely and path_net_ref and next_cell != cur_cell and next_cell != exit_coords and next_cell != spawn_coords:
		if path_net_ref.is_tile_full(next_cell, get_tile_headcount()):
			blocked_wait_timer += sim_delta
			if blocked_wait_timer > 0.7 and not has_diverted_from_block and prefers_crowd_diversion:
				has_diverted_from_block = true
				need_routing_refresh.emit(self)
				return
			if blocked_wait_timer > 1.7:
				# Stuck at crowded path or gate: become unhappy and walk freely to get out of the plaza!
				blocked_wait_timer = 0.0
				_become_unhappy_and_walk_freely("Crowded!")
				return
			return
	blocked_wait_timer = 0.0
	has_diverted_from_block = false

	# Crowd density & tile cleanliness speed multiplier
	var crowd_mult := 1.0
	var sep_push := Vector3.ZERO
	if path_net_ref:
		if is_walking_freely and state == AgentState.EXITING_FRUSTRATED:
			crowd_mult = 0.85 * path_net_ref.get_cleanliness_multiplier(path_net_ref.get_tile_trash_count(cur_cell))
		else:
			crowd_mult = path_net_ref.get_crowd_speed_multiplier(
				cur_cell, current_tile_security_boost
			)
		sep_push = path_net_ref.compute_separation_push(self, cur_cell) * 0.16

	var target_3d := Vector3(target_2d.x, 0.0, target_2d.y) + sub_tile_offset + sep_push
	var offset := target_3d - global_position
	offset.y = 0.0
	var dist := offset.length()
	var effective_speed := walk_speed * crowd_mult
	var step := effective_speed * sim_delta

	if dist <= step:
		global_position = Vector3(target_3d.x, 0.0, target_3d.z)
		target_index += 1
		if target_index >= current_route.size():
			_on_reached_route_end()
	else:
		var dir := offset.normalized()
		global_position += dir * step

	walk_phase += sim_delta * (7.0 + effective_speed * 2.2)
	if visual_model:
		var scale_y := visual_model.scale.y
		visual_model.position.y = absf(sin(walk_phase)) * 0.065 * scale_y
		visual_model.rotation_degrees.z = sin(walk_phase) * 4.2

func _on_reached_route_end() -> void:
	if visual_model:
		visual_model.position.y = 0.0
		visual_model.rotation_degrees.z = 0.0

	if state == AgentState.LOST:
		need_routing_refresh.emit(self)
		return

	if state == AgentState.WALKING_TO_FACILITY:
		if is_instance_valid(destination_stall) and destination_stall.has_method("register_arrival"):
			state = AgentState.QUEUING
			is_waiting_in_queue = true
			_unregister_current_tile()
			if status_label:
				status_label.visible = false
			destination_stall.register_arrival(self)
		else:
			state = AgentState.WALKING_UNFULFILLED
			need_routing_refresh.emit(self)
	elif state == AgentState.WALKING_UNFULFILLED:
		if not has_emitted_unfulfilled:
			has_emitted_unfulfilled = true
			exited_unfulfilled.emit(self)
		queue_free()
	elif state == AgentState.WALKING_PASSTHROUGH:
		exited_happy_passthrough.emit(self)
		queue_free()
	elif state == AgentState.EXITING_HAPPY or state == AgentState.EXITING_FRUSTRATED:
		queue_free()

func on_facility_served(served_facility_type: int = 1) -> void:
	is_waiting_in_queue = false
	need_patience_timer = 0.0
	fulfilled_needs_count += 1

	global_position = Vector3(facility_access_tile.x, 0.0, facility_access_tile.y) + sub_tile_offset
	_update_tile_registration(facility_access_tile)

	if served_facility_type in [
		FacilityCatalog.ItemId.FOOD_SHOP,
		FacilityCatalog.ItemId.DRINK_STALL,
		FacilityCatalog.ItemId.PICNIC_TABLE
	]:
		has_pending_trash = true
		trash_timer = randf_range(2.0, 4.2)

	if not needs_queue.is_empty():
		needs_queue.pop_front()

	destination_stall = null
	show_happy_emoji()

	if not needs_queue.is_empty():
		need = needs_queue[0] as NeedType
		state = AgentState.WALKING_UNFULFILLED
		_rebuild_character_mesh()
	else:
		is_satisfied = true
		state = AgentState.EXITING_HAPPY

	need_routing_refresh.emit(self)

func on_facility_frustrated() -> void:
	is_waiting_in_queue = false
	global_position = Vector3(facility_access_tile.x, 0.0, facility_access_tile.y) + sub_tile_offset
	_update_tile_registration(facility_access_tile)
	has_emitted_unfulfilled = true # StallController emits peep_frustrated
	var unmet_need := get_active_need()
	needs_queue.clear()
	is_satisfied = false
	is_walking_freely = true
	destination_stall = null
	state = AgentState.EXITING_FRUSTRATED
	show_unhappy_complaint(unmet_need, "Long Queue!")
	need_routing_refresh.emit(self)

func on_facility_removed() -> void:
	is_waiting_in_queue = false
	global_position = Vector3(facility_access_tile.x, 0.0, facility_access_tile.y) + sub_tile_offset
	_update_tile_registration(facility_access_tile)
	destination_stall = null
	state = AgentState.WALKING_UNFULFILLED if has_active_need() else AgentState.EXITING_HAPPY
	need_routing_refresh.emit(self)
