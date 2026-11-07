class_name DayNightCycle
extends Node

@export var sun_light: DirectionalLight3D
@export var world_env: WorldEnvironment

var lighting_cycle_enabled: bool = true
var brightness_multiplier: float = 0.85
var current_night_factor: float = 0.0
var last_day_progress: float = 0.2

func set_brightness(value: float) -> void:
	brightness_multiplier = clampf(value, 0.35, 1.5)
	update_time_of_day(last_day_progress)

func update_time_of_day(day_progress: float) -> void:
	last_day_progress = day_progress
	if not lighting_cycle_enabled:
		_apply_lighting(0.0, 0.25)
		return

	# day_progress: 0.0 -> 0.5 is DAY (30s), 0.5 -> 1.0 is NIGHT (30s)
	var night_factor := 0.0
	if day_progress < 0.42:
		night_factor = 0.0
	elif day_progress < 0.54:
		night_factor = smoothstep(0.42, 0.54, day_progress)
	elif day_progress < 0.90:
		night_factor = 1.0
	else:
		night_factor = 1.0 - smoothstep(0.90, 1.0, day_progress)

	_apply_lighting(night_factor, day_progress)

func _apply_lighting(night_factor: float, day_progress: float) -> void:
	current_night_factor = night_factor

	if sun_light:
		var day_col := Color(0.98, 0.93, 0.84)
		var sunset_col := Color(0.95, 0.64, 0.42)
		var night_col := Color(0.36, 0.46, 0.70)

		var transition := clampf(1.0 - absf(night_factor - 0.5) * 2.0, 0.0, 1.0)
		var base_col := day_col.lerp(night_col, night_factor)
		sun_light.light_color = base_col.lerp(sunset_col, transition * 0.65)
		sun_light.light_energy = lerpf(0.62, 0.18, night_factor) * brightness_multiplier

		# Gentle sun/moon sweep
		var azimuth := lerpf(-28.0, 28.0, sin(day_progress * TAU))
		var pitch := lerpf(-58.0, -45.0, night_factor)
		sun_light.rotation_degrees = Vector3(pitch, azimuth, 0.0)

	if world_env and world_env.environment:
		var env := world_env.environment
		env.tonemap_exposure = lerpf(0.55, 1.25, (brightness_multiplier - 0.35) / 1.15)
		env.ambient_light_color = Color(0.86, 0.84, 0.78).lerp(Color(0.18, 0.23, 0.36), night_factor)
		env.ambient_light_energy = lerpf(0.42, 0.22, night_factor) * brightness_multiplier
		var sky_mat := env.sky.sky_material as ProceduralSkyMaterial
		if sky_mat:
			sky_mat.sky_top_color = Color(0.46, 0.64, 0.80).lerp(Color(0.07, 0.10, 0.18), night_factor)
			sky_mat.sky_horizon_color = Color(0.74, 0.78, 0.82).lerp(Color(0.14, 0.18, 0.28), night_factor)
			sky_mat.ground_bottom_color = Color(0.29, 0.48, 0.35).lerp(Color(0.08, 0.12, 0.16), night_factor)

	# Update all streetlamps and facility lanterns in group "night_lights"
	var tree := get_tree()
	if tree:
		var show_lamps := night_factor > 0.05
		for node in tree.get_nodes_in_group("night_lights"):
			if node is OmniLight3D:
				var omni := node as OmniLight3D
				omni.visible = show_lamps
				omni.light_energy = night_factor * 0.95 * brightness_multiplier
