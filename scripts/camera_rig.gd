class_name CameraRig
extends Node3D

enum CameraMode {
	TITLE_MENU,
	LOCATION_SELECT,
	GAMEPLAY
}

@export var pan_speed: float = 12.0
@export var drag_sensitivity: float = 0.018
@export var zoom_speed: float = 1.2
@export var min_ortho_size: float = 9.0
@export var max_ortho_size: float = 28.0
@export var max_pan_x: float = 12.0
@export var max_pan_z: float = 8.0

@onready var camera: Camera3D = $Camera3D

var mode: CameraMode = CameraMode.TITLE_MENU
var target_position: Vector3 = Vector3(0.0, 0.0, -42.0)
var target_ortho_size: float = 11.2
var target_pitch_deg: float = -62.0
var target_cam_offset: Vector3 = Vector3(0.0, 18.0, 8.8)
var default_gameplay_ortho: float = 15.6
var default_preview_ortho: float = 19.5

var is_middle_dragging: bool = false
var is_strict_top_down: bool = false
var orbit_time: float = 0.0

func _ready() -> void:
	transition_to_title(true)

func configure_for_map_size(hw: int, hh: int) -> void:
	max_pan_x = float(hw) + 3.5
	max_pan_z = float(hh) + 3.0
	max_ortho_size = clampf(float(hw) * 1.95, 24.0, 32.0)
	default_gameplay_ortho = clampf(float(hw) * 1.38, 14.5, 20.5)
	default_preview_ortho = clampf(float(hw) * 1.72, 18.0, 25.0)
	if mode == CameraMode.LOCATION_SELECT:
		target_ortho_size = default_preview_ortho
	elif mode == CameraMode.GAMEPLAY:
		target_ortho_size = default_gameplay_ortho

func transition_to_title(instant: bool = false) -> void:
	mode = CameraMode.TITLE_MENU
	is_middle_dragging = false
	target_position = Vector3(0.0, 0.0, -42.0)
	target_ortho_size = 11.2
	target_pitch_deg = -62.0
	target_cam_offset = Vector3(0.0, 18.0, 8.8)
	if instant:
		_snap_to_targets()

func transition_to_location_select(instant: bool = false) -> void:
	mode = CameraMode.LOCATION_SELECT
	is_middle_dragging = false
	target_position = Vector3(0.0, 0.0, 2.2)
	target_ortho_size = default_preview_ortho
	target_pitch_deg = -66.0
	target_cam_offset = Vector3(0.0, 19.5, 7.6)
	if instant:
		_snap_to_targets()

func transition_to_gameplay(instant: bool = false) -> void:
	mode = CameraMode.GAMEPLAY
	is_middle_dragging = false
	target_position = Vector3.ZERO
	target_ortho_size = default_gameplay_ortho
	_update_gameplay_angle_targets()
	if instant:
		_snap_to_targets()

func set_top_down_mode(strict_top_down: bool) -> void:
	is_strict_top_down = strict_top_down
	if mode == CameraMode.GAMEPLAY:
		_update_gameplay_angle_targets()

func reset_view() -> void:
	transition_to_gameplay(false)

func _update_gameplay_angle_targets() -> void:
	if is_strict_top_down:
		target_pitch_deg = -89.9
		target_cam_offset = Vector3(0.0, 22.0, 0.01)
	else:
		target_pitch_deg = -74.0
		target_cam_offset = Vector3(0.0, 20.0, 5.6)

func _snap_to_targets() -> void:
	position = target_position
	rotation_degrees = Vector3.ZERO
	if camera:
		camera.size = target_ortho_size
		camera.position = target_cam_offset
		camera.rotation_degrees = Vector3(target_pitch_deg, 0.0, 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if mode != CameraMode.GAMEPLAY:
		is_middle_dragging = false
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			is_middle_dragging = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			target_ortho_size = clampf(target_ortho_size - zoom_speed, min_ortho_size, max_ortho_size)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			target_ortho_size = clampf(target_ortho_size + zoom_speed, min_ortho_size, max_ortho_size)
	elif event is InputEventMouseMotion and is_middle_dragging:
		var mm := event as InputEventMouseMotion
		var zoom_scale := target_ortho_size / 14.2
		target_position.x -= mm.relative.x * drag_sensitivity * zoom_scale
		target_position.z -= mm.relative.y * drag_sensitivity * zoom_scale
		_clamp_target()

func _process(delta: float) -> void:
	if mode == CameraMode.GAMEPLAY:
		var input_dir := Vector2.ZERO
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			input_dir.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			input_dir.y += 1.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			input_dir.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			input_dir.x += 1.0

		if input_dir.length_squared() > 0.0:
			input_dir = input_dir.normalized()
			var zoom_scale := target_ortho_size / 14.2
			target_position.x += input_dir.x * pan_speed * zoom_scale * delta
			target_position.z += input_dir.y * pan_speed * zoom_scale * delta
			_clamp_target()

	# Gentle breathing orbit when on Title Menu or Location Select
	orbit_time += delta
	var desired_yaw := 0.0
	if mode == CameraMode.TITLE_MENU:
		desired_yaw = sin(orbit_time * 0.35) * 8.5
	elif mode == CameraMode.LOCATION_SELECT:
		desired_yaw = sin(orbit_time * 0.25) * 3.0

	var lerp_w := clampf(delta * 5.2, 0.0, 1.0)
	position = position.lerp(target_position, lerp_w)
	rotation_degrees.y = lerpf(rotation_degrees.y, desired_yaw, lerp_w)

	if camera:
		camera.size = lerpf(camera.size, target_ortho_size, lerp_w)
		camera.position = camera.position.lerp(target_cam_offset, lerp_w)
		camera.rotation_degrees.x = lerpf(camera.rotation_degrees.x, target_pitch_deg, lerp_w)

func _clamp_target() -> void:
	target_position.x = clampf(target_position.x, -max_pan_x, max_pan_x)
	target_position.z = clampf(target_position.z, -max_pan_z, max_pan_z)
