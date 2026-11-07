class_name ProceduralProps
extends RefCounted

static var _mat_cache: Dictionary = {}

static func get_mat(key: String, color: Color, roughness: float = 0.88, emission_energy: float = 0.0) -> StandardMaterial3D:
	var cache_key := "%s_%s_%.2f_%.2f" % [key, color.to_html(), roughness, emission_energy]
	if _mat_cache.has(cache_key):
		return _mat_cache[cache_key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic_specular = 0.08
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_energy
	_mat_cache[cache_key] = mat
	return mat

static func add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

static func add_cylinder(parent: Node3D, top_r: float, bot_r: float, height: float, pos: Vector3, mat: Material, radial_segs: int = 18, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bot_r
	mesh.height = height
	mesh.radial_segments = radial_segs
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

static func add_sphere(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 8
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mi

static func add_prism(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = size
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

static func add_night_lamp(parent: Node3D, pos: Vector3, light_color: Color = Color(1.0, 0.82, 0.50), range_val: float = 4.2, energy: float = 0.90) -> OmniLight3D:
	var bulb_mat := get_mat("bulb", Color(0.98, 0.86, 0.58), 0.35, 1.15)
	var bulb := add_sphere(parent, 0.075, 0.15, pos, bulb_mat)
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var omni := OmniLight3D.new()
	omni.position = pos + Vector3(0, -0.05, 0)
	omni.light_color = light_color
	omni.omni_range = range_val
	omni.light_energy = energy
	omni.shadow_enabled = false
	omni.add_to_group("night_lights")
	parent.add_child(omni)
	return omni

static func build_cozy_tree(parent: Node3D, pos: Vector3, scale_factor: float = 1.0, variant: int = 0, col_a: Color = Color("6fb06a"), col_b: Color = Color("4f9562")) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * scale_factor
	parent.add_child(root)

	var trunk_mat := get_mat("trunk", Color("7a563b"))
	var c_main := col_a if (variant % 2 == 0) else col_b
	var c_accent := col_a.lightened(0.08) if (variant % 2 == 0) else col_b.lightened(0.06)
	var leaf_mat := get_mat("leaf_m_%s" % c_main.to_html(), c_main)
	var leaf_hi_mat := get_mat("leaf_h_%s" % c_accent.to_html(), c_accent)
	var shadow_mat := get_mat("tree_shadow", Color(0.14, 0.18, 0.15, 0.25))

	add_cylinder(root, 0.48, 0.48, 0.015, Vector3(0, 0.008, 0), shadow_mat, 16)
	add_cylinder(root, 0.09, 0.13, 0.52, Vector3(0, 0.26, 0), trunk_mat, 10)

	if variant % 3 != 1:
		# Cozy rounded cloud-like canopy (Mini Motorways style)
		add_sphere(root, 0.44, 0.72, Vector3(0, 0.74, 0), leaf_mat)
		add_sphere(root, 0.32, 0.54, Vector3(0.17, 0.92, 0.11), leaf_hi_mat)
		add_sphere(root, 0.29, 0.48, Vector3(-0.15, 0.88, -0.10), leaf_mat)
	else:
		# Soft layered cypress / pine
		add_cylinder(root, 0.10, 0.48, 0.62, Vector3(0, 0.68, 0), leaf_mat, 14)
		add_cylinder(root, 0.06, 0.36, 0.52, Vector3(0, 1.02, 0), leaf_hi_mat, 14)
		add_sphere(root, 0.12, 0.22, Vector3(0, 1.28, 0), leaf_hi_mat)

	return root

static func build_cozy_house(parent: Node3D, pos: Vector3, size: Vector3, wall_col: Color, roof_col: Color, rot_y: float = 0.0) -> Node3D:
	var house := Node3D.new()
	house.position = pos
	house.rotation_degrees.y = rot_y
	parent.add_child(house)

	var wall_mat := get_mat("h_wall_%s" % wall_col.to_html(), wall_col)
	var roof_mat := get_mat("h_roof_%s" % roof_col.to_html(), roof_col)
	var trim_mat := get_mat("h_trim", Color("f4efe6"))
	var win_mat := get_mat("h_win", Color("ffe49e"), 0.35, 0.75)

	# Plinth + main walls
	add_box(house, Vector3(size.x + 0.12, 0.12, size.z + 0.12), Vector3(0, 0.06, 0), trim_mat)
	add_box(house, size, Vector3(0, size.y * 0.5 + 0.08, 0), wall_mat)

	# Pitched gable roof + chimney
	var roof_h := 0.55
	add_box(house, Vector3(size.x + 0.18, 0.08, size.z + 0.18), Vector3(0, size.y + 0.10, 0), trim_mat)
	add_prism(house, Vector3(size.x + 0.24, roof_h, size.z + 0.24), Vector3(0, size.y + 0.14 + roof_h * 0.5, 0), roof_mat)
	add_box(house, Vector3(0.24, 0.42, 0.24), Vector3(size.x * 0.22, size.y + roof_h * 0.75, -size.z * 0.2), roof_mat)

	# Warm cozy windows along the front/back
	for wz in [-size.z * 0.26, size.z * 0.26]:
		add_box(house, Vector3(size.x + 0.04, 0.26, 0.30), Vector3(0, size.y * 0.58, wz), win_mat)

	return house

static func build_streetlamp(parent: Node3D, pos: Vector3, arm_dir_x: float = 1.0) -> Node3D:
	var lamp := Node3D.new()
	lamp.position = pos
	parent.add_child(lamp)

	var pole_mat := get_mat("lamp_pole", Color("3d4452"), 0.65)
	add_cylinder(lamp, 0.07, 0.09, 0.18, Vector3(0, 0.09, 0), pole_mat, 10)
	add_cylinder(lamp, 0.038, 0.048, 1.40, Vector3(0, 0.78, 0), pole_mat, 10)
	add_box(lamp, Vector3(0.34, 0.045, 0.045), Vector3(arm_dir_x * 0.15, 1.46, 0), pole_mat)
	add_cylinder(lamp, 0.13, 0.17, 0.06, Vector3(arm_dir_x * 0.28, 1.42, 0), pole_mat, 12)

	add_night_lamp(lamp, Vector3(arm_dir_x * 0.28, 1.34, 0), Color(1.0, 0.84, 0.54), 5.0, 0.95)
	return lamp

static func build_entrance_gate(parent: Node3D, pos: Vector3, label_text: String, roof_col: Color = Color("b86a5b")) -> Node3D:
	var gate := Node3D.new()
	gate.position = pos
	parent.add_child(gate)

	var wood_mat := get_mat("gate_wood", Color("7c563b"))
	var roof_mat := get_mat("gate_roof_%s" % roof_col.to_html(), roof_col)
	var trim_mat := get_mat("gate_trim", Color("f4efe6"))

	add_cylinder(gate, 0.065, 0.08, 1.12, Vector3(0, 0.56, -0.58), wood_mat, 12)
	add_cylinder(gate, 0.065, 0.08, 1.12, Vector3(0, 0.56, 0.58), wood_mat, 12)

	add_box(gate, Vector3(0.28, 0.11, 1.44), Vector3(0, 1.14, 0), trim_mat)
	add_prism(gate, Vector3(0.48, 0.28, 1.54), Vector3(0, 1.33, 0), roof_mat, Vector3(0, 90, 0))

	add_night_lamp(gate, Vector3(0, 1.02, 0), Color(1.0, 0.85, 0.56), 4.0, 0.85)

	var lbl := Label3D.new()
	lbl.position = Vector3(0, 1.72, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.text = label_text
	lbl.font_size = 22
	lbl.outline_size = 7
	lbl.modulate = Color("faf5eb")
	gate.add_child(lbl)
	return gate

static func build_fountain_obstacle(parent: Node3D, pos: Vector3, water_col: Color) -> Node3D:
	var f := Node3D.new()
	f.position = pos
	parent.add_child(f)

	var stone_mat := get_mat("fountain_stone", Color("d8cfc2"))
	var rim_mat := get_mat("fountain_rim", Color("b8aea0"))
	var water_mat := get_mat("fountain_water", water_col, 0.35)

	add_cylinder(f, 0.47, 0.49, 0.16, Vector3(0, 0.08, 0), rim_mat, 20)
	add_cylinder(f, 0.40, 0.40, 0.17, Vector3(0, 0.09, 0), water_mat, 20)
	add_cylinder(f, 0.12, 0.15, 0.46, Vector3(0, 0.25, 0), stone_mat, 14)
	add_cylinder(f, 0.25, 0.22, 0.08, Vector3(0, 0.48, 0), rim_mat, 16)
	add_sphere(f, 0.11, 0.20, Vector3(0, 0.58, 0), water_mat)
	return f

static func build_planter_obstacle(parent: Node3D, pos: Vector3, leaf_col: Color, flower_col: Color) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	parent.add_child(p)

	var box_mat := get_mat("planter_box", Color("c9996b"))
	var rim_mat := get_mat("planter_rim", Color("e8dccb"))
	var soil_mat := get_mat("planter_soil", Color("5e432d"))
	var bush_mat := get_mat("planter_bush_%s" % leaf_col.to_html(), leaf_col)
	var flw_mat := get_mat("planter_flw_%s" % flower_col.to_html(), flower_col)

	add_cylinder(p, 0.44, 0.42, 0.22, Vector3(0, 0.11, 0), box_mat, 16)
	add_cylinder(p, 0.46, 0.46, 0.05, Vector3(0, 0.21, 0), rim_mat, 16)
	add_cylinder(p, 0.39, 0.39, 0.04, Vector3(0, 0.22, 0), soil_mat, 14)

	add_sphere(p, 0.28, 0.38, Vector3(0, 0.36, 0), bush_mat)
	add_sphere(p, 0.20, 0.28, Vector3(0.14, 0.34, 0.10), bush_mat)
	add_sphere(p, 0.18, 0.26, Vector3(-0.14, 0.33, -0.08), bush_mat)

	for offset in [Vector3(0.10, 0.52, 0.06), Vector3(-0.10, 0.50, 0.08), Vector3(0.0, 0.54, -0.10)]:
		add_sphere(p, 0.065, 0.11, offset, flw_mat)
	return p

static func build_deco_market_booth(parent: Node3D, pos: Vector3, canopy_col: Color, variant: int = 0) -> Node3D:
	var b := Node3D.new()
	b.position = pos
	parent.add_child(b)

	var wood_mat := get_mat("deco_wood", Color("825b3e"))
	var cream_mat := get_mat("deco_cream", Color("f5efe4"))
	var canopy_mat := get_mat("deco_canopy_%s" % canopy_col.to_html(), canopy_col)

	add_box(b, Vector3(0.82, 0.42, 0.72), Vector3(0, 0.21, 0), wood_mat)
	add_box(b, Vector3(0.86, 0.06, 0.76), Vector3(0, 0.44, 0), cream_mat)

	for sx in [-0.36, 0.36]:
		for sz in [-0.30, 0.30]:
			add_cylinder(b, 0.028, 0.028, 0.46, Vector3(sx, 0.67, sz), wood_mat, 8)

	add_prism(b, Vector3(0.92, 0.28, 0.86), Vector3(0, 1.02, 0), canopy_mat if variant % 2 == 0 else cream_mat)
	add_box(b, Vector3(0.94, 0.08, 0.88), Vector3(0, 0.88, 0), canopy_mat)
	return b

static func build_wooden_bridge_overlay(parent: Node3D, pos: Vector3) -> Node3D:
	var br := Node3D.new()
	br.position = pos
	parent.add_child(br)

	var plank_mat := get_mat("bridge_plank", Color("b88758"))
	var rail_mat := get_mat("bridge_rail", Color("7c5434"))

	for i in range(-2, 3):
		add_box(br, Vector3(0.17, 0.04, 0.92), Vector3(i * 0.19, 0.07, 0), plank_mat)

	for sz in [-0.43, 0.43]:
		add_box(br, Vector3(0.96, 0.05, 0.05), Vector3(0, 0.28, sz), rail_mat)
		for px in [-0.40, 0.0, 0.40]:
			add_cylinder(br, 0.03, 0.03, 0.26, Vector3(px, 0.17, sz), rail_mat, 8)

	return br

static func build_train_station_landmark(parent: Node3D, pos: Vector3, roof_col: Color) -> Node3D:
	var st := Node3D.new()
	st.position = pos
	parent.add_child(st)

	var wall_mat := get_mat("st_wall", Color("efe7da"))
	var trim_mat := get_mat("st_trim", Color("d5c8b4"))
	var roof_mat := get_mat("st_roof_%s" % roof_col.to_html(), roof_col)
	var track_mat := get_mat("st_track", Color("4a505c"))
	var sleeper_mat := get_mat("st_sleeper", Color("6e5239"))
	var clock_mat := get_mat("st_clock", Color("fff8e7"), 0.3, 0.9)

	# Railway tracks behind the station
	add_box(st, Vector3(24.0, 0.04, 0.9), Vector3(0, 0.02, -1.55), track_mat)
	for tx in range(-11, 12):
		add_box(st, Vector3(0.22, 0.05, 0.82), Vector3(tx * 1.0, 0.03, -1.55), sleeper_mat)

	# Main station hall + clock tower
	add_box(st, Vector3(4.2, 0.14, 1.8), Vector3(0, 0.07, 0), trim_mat)
	add_box(st, Vector3(3.6, 1.25, 1.35), Vector3(0, 0.72, -0.1), wall_mat)
	add_prism(st, Vector3(3.9, 0.62, 1.65), Vector3(0, 1.65, -0.1), roof_mat)

	# Central clock tower
	add_box(st, Vector3(1.05, 1.85, 1.05), Vector3(0, 1.05, 0.12), wall_mat)
	add_prism(st, Vector3(1.25, 0.55, 1.25), Vector3(0, 2.25, 0.12), roof_mat)
	add_cylinder(st, 0.26, 0.26, 0.06, Vector3(0, 1.55, 0.66), clock_mat, 16, Vector3(90, 0, 0))

	# Front platform awning over (0, -5)
	add_box(st, Vector3(2.2, 0.08, 0.85), Vector3(0, 0.92, 0.85), roof_mat)
	add_night_lamp(st, Vector3(0, 0.82, 0.95), Color(1.0, 0.86, 0.58), 4.8, 1.0)

	var lbl := Label3D.new()
	lbl.position = Vector3(0, 2.75, 0.12)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.text = "CENTRAL STATION"
	lbl.font_size = 24
	lbl.outline_size = 8
	lbl.modulate = Color("faf5eb")
	st.add_child(lbl)
	return st

static func build_facility_visual(facility_type: int) -> Node3D:
	var root := Node3D.new()
	root.name = "StallVisual"

	var base_pad_mat := get_mat("pad_stone", Color("d8cdbc"))
	var rim_pad_mat := get_mat("pad_rim", Color("b5a692"))
	var wood_mat := get_mat("stall_wood", Color("a67449"))
	var dark_wood_mat := get_mat("stall_dark_wood", Color("6e492c"))
	var cream_mat := get_mat("stall_cream", Color("f7f1e5"))

	# Cozy two-tone rounded foundation pad
	add_cylinder(root, 0.47, 0.49, 0.05, Vector3(0, 0.025, 0), rim_pad_mat, 22)
	add_cylinder(root, 0.43, 0.44, 0.065, Vector3(0, 0.035, 0), base_pad_mat, 22)

	if facility_type <= 1:
		# 1 = FOOD SHOP (also fallback for 0): Terracotta-coral & cream striped bakery/bistro kiosk
		var coral_mat := get_mat("food_coral", Color("e8654a"))
		var gold_mat := get_mat("food_gold", Color("f2b84b"))

		add_box(root, Vector3(0.76, 0.42, 0.60), Vector3(0, 0.26, -0.03), wood_mat)
		add_box(root, Vector3(0.84, 0.07, 0.70), Vector3(0, 0.49, -0.01), cream_mat)

		for sx in [-0.34, 0.34]:
			for sz in [-0.26, 0.24]:
				add_cylinder(root, 0.032, 0.032, 0.52, Vector3(sx, 0.75, sz), dark_wood_mat, 10)

		for i in range(5):
			var seg_x := -0.32 + i * 0.16
			var seg_mat := coral_mat if (i % 2 == 0) else cream_mat
			add_prism(root, Vector3(0.17, 0.28, 0.84), Vector3(seg_x, 1.08, 0.0), seg_mat, Vector3(0, 90, 0))
			add_cylinder(root, 0.08, 0.08, 0.06, Vector3(seg_x, 0.92, 0.40), seg_mat, 12, Vector3(90, 0, 0))

		add_box(root, Vector3(0.26, 0.06, 0.18), Vector3(-0.15, 0.55, 0.14), coral_mat)
		add_sphere(root, 0.09, 0.14, Vector3(-0.15, 0.61, 0.14), gold_mat)
		add_cylinder(root, 0.07, 0.06, 0.14, Vector3(0.18, 0.58, 0.12), cream_mat, 12)
		add_box(root, Vector3(0.18, 0.26, 0.04), Vector3(0.38, 0.19, 0.34), dark_wood_mat, Vector3(-12, 18, 0))

		add_night_lamp(root, Vector3(0, 0.86, 0.26), Color(1.0, 0.78, 0.45), 3.6, 0.95)

	elif facility_type == 2:
		# 2 = DRINK STALL: Mint-teal & lemon juice/coffee cart with parasol & dispensers
		var mint_mat := get_mat("drink_mint", Color("4ab59c"))
		var lemon_mat := get_mat("drink_lemon", Color("f4cc4e"))

		add_box(root, Vector3(0.68, 0.40, 0.52), Vector3(0, 0.25, 0), mint_mat)
		add_box(root, Vector3(0.74, 0.06, 0.58), Vector3(0, 0.47, 0), cream_mat)
		# Cart wheels
		for sx in [-0.36, 0.36]:
			add_cylinder(root, 0.13, 0.13, 0.05, Vector3(sx, 0.15, 0.06), dark_wood_mat, 14, Vector3(0, 0, 90))
		# Drink barrels / dispensers
		add_cylinder(root, 0.09, 0.09, 0.22, Vector3(-0.16, 0.60, 0.04), lemon_mat, 12)
		add_cylinder(root, 0.08, 0.08, 0.20, Vector3(0.14, 0.59, 0.04), mint_mat, 12)
		# Tilted parasol
		add_cylinder(root, 0.025, 0.03, 0.75, Vector3(0, 0.78, -0.06), dark_wood_mat, 8)
		add_cylinder(root, 0.06, 0.48, 0.24, Vector3(0, 1.12, -0.06), lemon_mat, 12)
		add_cylinder(root, 0.49, 0.49, 0.04, Vector3(0, 1.00, -0.06), mint_mat, 12)
		add_night_lamp(root, Vector3(0, 0.88, 0.18), Color(1.0, 0.90, 0.55), 3.4, 0.85)

	elif facility_type == 3:
		# 3 = RESTROOM: Cozy pastel cottage with sky-teal pitched roof & flower box
		var wall_mat := get_mat("wc_wall", Color("f4f1ea"))
		var blue_mat := get_mat("wc_blue", Color("4a90ba"))
		var roof_mat := get_mat("wc_roof", Color("366f94"))
		var door_mat := get_mat("wc_door", Color("73b3d6"))
		var leaf_mat := get_mat("wc_leaf", Color("6fb06a"))

		add_box(root, Vector3(0.76, 0.66, 0.62), Vector3(0, 0.38, -0.04), wall_mat)
		add_box(root, Vector3(0.84, 0.07, 0.72), Vector3(0, 0.73, -0.04), blue_mat)
		add_prism(root, Vector3(0.90, 0.36, 0.78), Vector3(0, 0.94, -0.04), roof_mat)

		add_box(root, Vector3(0.22, 0.48, 0.04), Vector3(-0.16, 0.29, 0.28), door_mat)
		add_box(root, Vector3(0.22, 0.48, 0.04), Vector3(0.16, 0.29, 0.28), door_mat)

		add_box(root, Vector3(0.30, 0.15, 0.05), Vector3(0, 0.84, 0.35), blue_mat)
		add_sphere(root, 0.12, 0.18, Vector3(-0.36, 0.16, 0.26), leaf_mat)
		add_night_lamp(root, Vector3(0, 0.67, 0.34), Color(0.76, 0.90, 1.0), 3.4, 0.85)

	elif facility_type == 4:
		# 4 = INFO KIOSK: Directory pillar with map boards & peaked green cap
		var green_mat := get_mat("info_green", Color("4f9562"))
		var map_mat := get_mat("info_map", Color("fff6dc"), 0.4, 0.45)

		add_cylinder(root, 0.24, 0.26, 0.78, Vector3(0, 0.44, 0), wood_mat, 12)
		add_box(root, Vector3(0.36, 0.38, 0.36), Vector3(0, 0.56, 0), map_mat)
		add_cylinder(root, 0.04, 0.38, 0.30, Vector3(0, 0.96, 0), green_mat, 12)
		add_sphere(root, 0.07, 0.14, Vector3(0, 1.14, 0), cream_mat)
		add_night_lamp(root, Vector3(0, 0.86, 0), Color(0.85, 0.96, 0.78), 3.6, 0.85)

	elif facility_type == 5:
		# 5 = PICNIC TABLE: Warm cedar table + benches + two-tone sunny parasol umbrella
		var yellow_mat := get_mat("picnic_yellow", Color("f0b43a"))
		var coral_accent := get_mat("picnic_basket", Color("e8654a"))
		var leaf_mat := get_mat("picnic_bush", Color("6fb06a"))

		add_box(root, Vector3(0.58, 0.055, 0.38), Vector3(0, 0.33, 0), wood_mat)
		add_box(root, Vector3(0.46, 0.26, 0.06), Vector3(0, 0.19, -0.12), dark_wood_mat)
		add_box(root, Vector3(0.46, 0.26, 0.06), Vector3(0, 0.19, 0.12), dark_wood_mat)

		add_box(root, Vector3(0.58, 0.045, 0.15), Vector3(0, 0.21, -0.30), wood_mat)
		add_box(root, Vector3(0.58, 0.045, 0.15), Vector3(0, 0.21, 0.30), wood_mat)

		add_box(root, Vector3(0.16, 0.11, 0.12), Vector3(0.14, 0.40, 0.04), coral_accent)

		add_cylinder(root, 0.026, 0.03, 0.94, Vector3(0, 0.52, 0), dark_wood_mat, 10)
		add_cylinder(root, 0.06, 0.50, 0.25, Vector3(0, 0.99, 0), yellow_mat, 12)
		add_cylinder(root, 0.51, 0.51, 0.045, Vector3(0, 0.87, 0), cream_mat, 12)

		add_sphere(root, 0.14, 0.22, Vector3(-0.34, 0.16, -0.28), leaf_mat)
		add_night_lamp(root, Vector3(0, 0.79, 0), Color(1.0, 0.84, 0.50), 3.4, 0.85)

	elif facility_type == 6:
		# 6 = PARK BENCH: Cozy wooden bench with backrest, cast-iron armrests & planter
		var iron_mat := get_mat("bench_iron", Color("3a404d"), 0.65)
		var leaf_mat := get_mat("bench_leaf", Color("6fb06a"))
		var flw_mat := get_mat("bench_flw", Color("f28b82"))

		add_box(root, Vector3(0.68, 0.05, 0.26), Vector3(0, 0.22, 0.04), wood_mat)
		add_box(root, Vector3(0.68, 0.24, 0.05), Vector3(0, 0.36, -0.08), wood_mat, Vector3(-10, 0, 0))
		for sx in [-0.28, 0.28]:
			add_box(root, Vector3(0.05, 0.26, 0.28), Vector3(sx, 0.16, 0.02), iron_mat)
		add_cylinder(root, 0.12, 0.10, 0.16, Vector3(0.34, 0.12, -0.20), dark_wood_mat, 10)
		add_sphere(root, 0.13, 0.20, Vector3(0.34, 0.26, -0.20), leaf_mat)
		add_sphere(root, 0.05, 0.08, Vector3(0.34, 0.36, -0.18), flw_mat)

	elif facility_type == 7:
		# 7 = TRASHCAN: Rounded park recycling receptacle with brass trim
		var bin_mat := get_mat("bin_green", Color("3d7a5a"), 0.75)
		var brass_mat := get_mat("bin_brass", Color("d9a84e"), 0.55)

		add_cylinder(root, 0.22, 0.19, 0.44, Vector3(0, 0.26, 0), bin_mat, 16)
		add_cylinder(root, 0.23, 0.23, 0.05, Vector3(0, 0.48, 0), brass_mat, 16)
		add_sphere(root, 0.21, 0.24, Vector3(0, 0.52, 0), bin_mat)

	elif facility_type == 8:
		# 8 = LAMP POST: Ornate plaza lamp post
		var pole_mat := get_mat("plaza_lamp_pole", Color("363d4a"), 0.6)
		add_cylinder(root, 0.14, 0.18, 0.20, Vector3(0, 0.14, 0), pole_mat, 12)
		add_cylinder(root, 0.045, 0.055, 1.25, Vector3(0, 0.82, 0), pole_mat, 10)
		add_cylinder(root, 0.18, 0.22, 0.06, Vector3(0, 1.46, 0), pole_mat, 12)
		add_night_lamp(root, Vector3(0, 1.35, 0), Color(1.0, 0.86, 0.56), 5.8, 1.15)

	elif facility_type == 13:
		# 13 = FLOWER GARDEN: Lush circular botanical bed with stone birdbath, colorful blooms & garden bench
		var soil_mat := get_mat("fg_soil", Color("5e432d"))
		var leaf_mat := get_mat("fg_leaf", Color("5da65e"))
		var pink_flw := get_mat("fg_pink", Color("f27d9b"))
		var gold_flw := get_mat("fg_gold", Color("f7c948"))
		var lav_flw := get_mat("fg_lav", Color("a77de8"))
		var stone_mat := get_mat("fg_stone", Color("e4dacb"))

		add_cylinder(root, 0.40, 0.42, 0.08, Vector3(0, 0.08, 0), soil_mat, 18)
		# Central birdbath
		add_cylinder(root, 0.09, 0.12, 0.34, Vector3(0, 0.25, 0), stone_mat, 12)
		add_cylinder(root, 0.22, 0.18, 0.06, Vector3(0, 0.43, 0), stone_mat, 14)
		# Ring of bushes and colorful flowers
		var flw_mats: Array[StandardMaterial3D] = [pink_flw, gold_flw, lav_flw]
		for i in range(6):
			var ang := float(i) * (TAU / 6.0)
			var bx := cos(ang) * 0.26
			var bz := sin(ang) * 0.26
			add_sphere(root, 0.13, 0.18, Vector3(bx, 0.17, bz), leaf_mat)
			add_sphere(root, 0.065, 0.10, Vector3(bx, 0.27, bz), flw_mats[i % 3])
		add_night_lamp(root, Vector3(0, 0.65, 0), Color(1.0, 0.88, 0.66), 3.8, 0.9)

	elif facility_type == 14:
		# 14 = DUCK POND: Cozy miniature pond with stone rim, lily pads & 2 little yellow ducks
		var water_mat := get_mat("dp_water", Color("6bc2d9"), 0.30)
		var lily_mat := get_mat("dp_lily", Color("58a85c"))
		var duck_mat := get_mat("dp_duck", Color("f7d046"))
		var beak_mat := get_mat("dp_beak", Color("e8703a"))

		add_cylinder(root, 0.41, 0.42, 0.06, Vector3(0, 0.075, 0), water_mat, 20)
		add_cylinder(root, 0.10, 0.10, 0.015, Vector3(-0.16, 0.11, -0.10), lily_mat, 10)
		add_cylinder(root, 0.09, 0.09, 0.015, Vector3(0.18, 0.11, 0.14), lily_mat, 10)
		# Two little ducks
		for dpos in [Vector3(-0.08, 0.14, 0.08), Vector3(0.12, 0.14, -0.08)]:
			add_sphere(root, 0.075, 0.10, dpos, duck_mat)
			add_sphere(root, 0.05, 0.09, dpos + Vector3(0.04, 0.06, 0.0), duck_mat)
			add_box(root, Vector3(0.04, 0.02, 0.03), dpos + Vector3(0.08, 0.06, 0.0), beak_mat)
		add_night_lamp(root, Vector3(0, 0.58, 0), Color(0.76, 0.94, 1.0), 3.6, 0.85)

	elif facility_type == 15:
		# 15 = COFFEE ROASTER: Warm brick & copper espresso kiosk with giant coffee cup sign
		var brick_mat := get_mat("cr_brick", Color("9c4a38"))
		var copper_mat := get_mat("cr_copper", Color("d48952"), 0.45)

		add_box(root, Vector3(0.72, 0.46, 0.56), Vector3(0, 0.28, 0), brick_mat)
		add_box(root, Vector3(0.78, 0.07, 0.62), Vector3(0, 0.54, 0), copper_mat)
		add_prism(root, Vector3(0.82, 0.26, 0.66), Vector3(0, 0.70, 0), dark_wood_mat)
		# Rooftop espresso cup emblem
		add_cylinder(root, 0.13, 0.10, 0.18, Vector3(0, 0.92, 0), cream_mat, 14)
		add_night_lamp(root, Vector3(0, 0.82, 0.24), Color(1.0, 0.82, 0.52), 3.8, 0.95)

	elif facility_type == 16:
		# 16 = STREET STAGE: Wooden acoustic performance deck with crimson arch & spotlight
		var stage_mat := get_mat("ss_wood", Color("b8804f"))
		var velvet_mat := get_mat("ss_velvet", Color("b54558"))
		var gold_mat := get_mat("ss_gold", Color("f2c45a"))

		add_cylinder(root, 0.43, 0.45, 0.12, Vector3(0, 0.10, 0), stage_mat, 18)
		add_box(root, Vector3(0.68, 0.58, 0.10), Vector3(0, 0.44, -0.24), velvet_mat)
		add_box(root, Vector3(0.74, 0.08, 0.16), Vector3(0, 0.75, -0.22), gold_mat)
		# Microphone stand in center
		add_cylinder(root, 0.018, 0.022, 0.42, Vector3(0, 0.36, 0.06), dark_wood_mat, 8)
		add_sphere(root, 0.04, 0.07, Vector3(0, 0.58, 0.06), gold_mat)
		add_night_lamp(root, Vector3(0, 0.88, 0.10), Color(1.0, 0.86, 0.58), 4.2, 1.05)

	return root

static func build_fence_mesh(root: Node3D, link_right: bool, link_left: bool, link_up: bool, link_down: bool) -> void:
	var stone_mat := get_mat("fence_stone", Color("d2c6b4"), 0.88)
	var wood_mat := get_mat("fence_wood", Color("8c6240"), 0.85)
	var cap_mat := get_mat("fence_cap", Color("f4efe6"), 0.85)

	# Central fence pillar
	add_box(root, Vector3(0.26, 0.14, 0.26), Vector3(0, 0.07, 0), stone_mat)
	add_cylinder(root, 0.085, 0.095, 0.44, Vector3(0, 0.26, 0), wood_mat, 10)
	add_sphere(root, 0.095, 0.14, Vector3(0, 0.50, 0), cap_mat)

	var any_link := link_right or link_left or link_up or link_down
	if not any_link:
		# Standalone fence segment defaults to a horizontal wooden barrier
		add_box(root, Vector3(0.84, 0.07, 0.07), Vector3(0, 0.36, 0), wood_mat)
		add_box(root, Vector3(0.84, 0.07, 0.07), Vector3(0, 0.21, 0), wood_mat)
		for sx in [-0.36, 0.36]:
			add_cylinder(root, 0.055, 0.06, 0.38, Vector3(sx, 0.21, 0), wood_mat, 8)
		return

	if link_right:
		add_box(root, Vector3(0.52, 0.065, 0.07), Vector3(0.26, 0.36, 0), wood_mat)
		add_box(root, Vector3(0.52, 0.065, 0.07), Vector3(0.26, 0.21, 0), wood_mat)
	if link_left:
		add_box(root, Vector3(0.52, 0.065, 0.07), Vector3(-0.26, 0.36, 0), wood_mat)
		add_box(root, Vector3(0.52, 0.065, 0.07), Vector3(-0.26, 0.21, 0), wood_mat)
	if link_down:
		add_box(root, Vector3(0.07, 0.065, 0.52), Vector3(0, 0.36, 0.26), wood_mat)
		add_box(root, Vector3(0.07, 0.065, 0.52), Vector3(0, 0.21, 0.26), wood_mat)
	if link_up:
		add_box(root, Vector3(0.07, 0.065, 0.52), Vector3(0, 0.36, -0.26), wood_mat)
		add_box(root, Vector3(0.07, 0.065, 0.52), Vector3(0, 0.21, -0.26), wood_mat)

static func build_gate_tile_overlay(root: Node3D, is_entry: bool, grid_x: int) -> void:
	var accent_col := Color("4eb87a") if is_entry else Color("e86a4a")
	var accent_mat := get_mat("gate_acc_%s" % accent_col.to_html(), accent_col, 0.72)
	var post_mat := get_mat("gate_post", Color("5e4b3c"), 0.85)
	var cream_mat := get_mat("gate_cream", Color("f7f2e7"), 0.82)

	# Low cozy gate bollards on North & South sides of the walkway
	for sz in [-0.38, 0.38]:
		add_cylinder(root, 0.075, 0.09, 0.34, Vector3(0, 0.19, sz), post_mat, 10)
		add_cylinder(root, 0.085, 0.085, 0.07, Vector3(0, 0.36, sz), accent_mat, 10)
		add_sphere(root, 0.075, 0.11, Vector3(0, 0.42, sz), cream_mat)

	# Directional arrow on the ground showing one-way flow (Inward for Entry, Outward for Exit)
	var inward_dir_x: float = 1.0 if grid_x <= 0 else -1.0
	var flow_dir_x: float = inward_dir_x if is_entry else -inward_dir_x
	var rot_y: float = -90.0 if flow_dir_x > 0.0 else 90.0
	add_box(root, Vector3(0.28, 0.02, 0.12), Vector3(-flow_dir_x * 0.08, 0.062, 0), accent_mat)
	add_prism(root, Vector3(0.28, 0.22, 0.02), Vector3(flow_dir_x * 0.12, 0.062, 0), cream_mat, Vector3(90, rot_y, 0))

static func build_trash_prop(variant: int = 0) -> Node3D:
	var trash := Node3D.new()
	var cup_col := Color("f2ebe1") if variant % 2 == 0 else Color("f4c095")
	var lid_col := Color("e8654a") if variant % 2 == 0 else Color("4a90ba")
	var cup_mat := get_mat("trash_cup_%d" % variant, cup_col)
	var lid_mat := get_mat("trash_lid_%d" % variant, lid_col)

	add_cylinder(trash, 0.055, 0.045, 0.11, Vector3(0, 0.05, 0), cup_mat, 8, Vector3(68, 25 * variant, 15))
	add_box(trash, Vector3(0.09, 0.04, 0.09), Vector3(0.08, 0.025, 0.05), lid_mat, Vector3(0, 35, 0))
	return trash

static func build_citizen_visual(archetype: int, primary_col: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "PawnMesh"

	var body_mat := get_mat("cit_body_%s" % primary_col.to_html(), primary_col, 0.78)
	var skin_mat := get_mat("cit_skin", Color("f5d6ba"), 0.82)
	var dark_mat := get_mat("cit_dark", Color("333945"), 0.80)
	var wood_mat := get_mat("cit_wood", Color("7c5233"), 0.85)
	var cream_mat := get_mat("cit_cream", Color("f7f2e8"), 0.85)

	if archetype == 1:
		# ELDER: Slightly shorter, warm cardigan, silver hair & wooden walking cane
		var silver_mat := get_mat("cit_silver", Color("d8dde3"), 0.80)
		add_cylinder(root, 0.125, 0.175, 0.34, Vector3(0, 0.23, 0), body_mat, 16)
		add_sphere(root, 0.14, 0.27, Vector3(0, 0.52, 0.02), skin_mat)
		add_sphere(root, 0.145, 0.22, Vector3(0, 0.57, -0.01), silver_mat)
		# Walking cane on right side
		add_cylinder(root, 0.018, 0.016, 0.36, Vector3(0.19, 0.18, 0.08), wood_mat, 8, Vector3(8, 0, -6))
		add_box(root, Vector3(0.05, 0.025, 0.07), Vector3(0.18, 0.36, 0.09), wood_mat)
	elif archetype == 2:
		# BUSINESS: Charcoal suit, white collar/tie & brown leather briefcase
		var suit_mat := get_mat("cit_suit", Color("2f3746"), 0.75)
		var tie_mat := get_mat("cit_tie", Color("d94e41"), 0.75)
		add_cylinder(root, 0.125, 0.175, 0.40, Vector3(0, 0.27, 0), suit_mat, 16)
		add_box(root, Vector3(0.05, 0.18, 0.03), Vector3(0, 0.32, 0.14), tie_mat)
		add_sphere(root, 0.145, 0.29, Vector3(0, 0.59, 0), skin_mat)
		add_cylinder(root, 0.15, 0.15, 0.08, Vector3(0, 0.69, 0), dark_mat, 14)
		# Briefcase
		add_box(root, Vector3(0.06, 0.16, 0.22), Vector3(0.20, 0.20, 0.02), wood_mat)
	elif archetype == 3:
		# COUPLE: Two cozy citizens standing side-by-side as one inseparable pair!
		var scarf_mat_a := get_mat("cit_scarf_a", Color("f28b82"), 0.80)
		var scarf_mat_b := get_mat("cit_scarf_b", Color("82c6d3"), 0.80)
		var partner_col := primary_col.lightened(0.14)
		var body_mat_b := get_mat("cit_body_b_%s" % partner_col.to_html(), partner_col, 0.78)

		# Left partner
		add_cylinder(root, 0.115, 0.17, 0.38, Vector3(-0.14, 0.26, 0.02), body_mat, 16)
		add_cylinder(root, 0.13, 0.135, 0.07, Vector3(-0.14, 0.43, 0.02), scarf_mat_a, 14)
		add_sphere(root, 0.14, 0.28, Vector3(-0.14, 0.58, 0.02), skin_mat)

		# Right partner
		add_cylinder(root, 0.115, 0.17, 0.37, Vector3(0.14, 0.25, -0.02), body_mat_b, 16)
		add_cylinder(root, 0.13, 0.135, 0.07, Vector3(0.14, 0.42, -0.02), scarf_mat_b, 14)
		add_sphere(root, 0.14, 0.28, Vector3(0.14, 0.57, -0.02), skin_mat)
	elif archetype == 4:
		# CHILD: Smaller scale (0.68x) with bright cap & tiny backpack
		root.scale = Vector3.ONE * 0.68
		var cap_mat := get_mat("cit_cap", Color("f4cc4e"), 0.75)
		add_cylinder(root, 0.125, 0.18, 0.36, Vector3(0, 0.25, 0), body_mat, 16)
		add_sphere(root, 0.15, 0.30, Vector3(0, 0.56, 0), skin_mat)
		add_sphere(root, 0.155, 0.18, Vector3(0, 0.63, 0), cap_mat)
		add_box(root, Vector3(0.16, 0.18, 0.10), Vector3(0, 0.28, -0.14), wood_mat)
	else:
		# NORMAL: Cozy pawn with cream collar trim
		add_cylinder(root, 0.12, 0.18, 0.38, Vector3(0, 0.26, 0), body_mat, 16)
		add_cylinder(root, 0.13, 0.135, 0.05, Vector3(0, 0.43, 0), cream_mat, 14)
		add_sphere(root, 0.145, 0.29, Vector3(0, 0.58, 0), skin_mat)

	return root

static func build_staff_visual(staff_type: int) -> Node3D:
	var root := Node3D.new()
	root.name = "StaffMesh"

	var skin_mat := get_mat("stf_skin", Color("f5d6ba"), 0.82)
	var wood_mat := get_mat("stf_wood", Color("8a5d3b"), 0.85)

	if staff_type == 0:
		# JANITOR: Olive/teal overalls + cap + broom
		var uniform_mat := get_mat("stf_janitor", Color("3b8266"), 0.78)
		var bristle_mat := get_mat("stf_bristle", Color("d9a84e"), 0.85)
		add_cylinder(root, 0.125, 0.18, 0.38, Vector3(0, 0.26, 0), uniform_mat, 16)
		add_sphere(root, 0.145, 0.29, Vector3(0, 0.58, 0), skin_mat)
		add_cylinder(root, 0.15, 0.15, 0.06, Vector3(0, 0.68, 0), uniform_mat, 14)
		# Broom
		add_cylinder(root, 0.018, 0.018, 0.52, Vector3(0.20, 0.28, 0.06), wood_mat, 8, Vector3(12, 0, -10))
		add_box(root, Vector3(0.14, 0.08, 0.06), Vector3(0.24, 0.05, 0.11), bristle_mat)
	elif staff_type == 1:
		# PLAZA STAFF (GUIDE): Warm gold/amber vest + guide flag
		var vest_mat := get_mat("stf_guide", Color("e69d35"), 0.78)
		var flag_mat := get_mat("stf_flag", Color("e8654a"), 0.75)
		add_cylinder(root, 0.125, 0.18, 0.38, Vector3(0, 0.26, 0), vest_mat, 16)
		add_sphere(root, 0.145, 0.29, Vector3(0, 0.58, 0), skin_mat)
		add_cylinder(root, 0.15, 0.16, 0.06, Vector3(0, 0.68, 0), vest_mat, 14)
		# Little guide flag held up
		add_cylinder(root, 0.015, 0.015, 0.56, Vector3(0.20, 0.45, 0.04), wood_mat, 8)
		add_box(root, Vector3(0.16, 0.11, 0.02), Vector3(0.28, 0.68, 0.04), flag_mat)
	else:
		# SECURITY OFFICER: Crisp navy uniform + peaked cap + gold badge
		var sec_mat := get_mat("stf_sec", Color("283e66"), 0.75)
		var gold_mat := get_mat("stf_gold", Color("f5c542"), 0.5)
		add_cylinder(root, 0.13, 0.185, 0.40, Vector3(0, 0.27, 0), sec_mat, 16)
		add_box(root, Vector3(0.06, 0.06, 0.03), Vector3(-0.06, 0.36, 0.14), gold_mat)
		add_sphere(root, 0.145, 0.29, Vector3(0, 0.59, 0), skin_mat)
		add_cylinder(root, 0.16, 0.15, 0.07, Vector3(0, 0.70, 0), sec_mat, 14)

	return root

static func build_ambient_car(parent: Node3D, color: Color) -> Node3D:
	var car := Node3D.new()
	parent.add_child(car)

	var body_mat := get_mat("car_body_%s" % color.to_html(), color, 0.65)
	var cabin_mat := get_mat("car_cabin", Color("f4f1ea"), 0.5)
	var wheel_mat := get_mat("car_wheel", Color("2b303a"), 0.9)
	var headlight_mat := get_mat("car_light", Color("fff0b8"), 0.3, 1.1)

	add_box(car, Vector3(0.54, 0.22, 0.90), Vector3(0, 0.18, 0), body_mat)
	add_box(car, Vector3(0.46, 0.19, 0.50), Vector3(0, 0.36, -0.04), cabin_mat)

	for wx in [-0.25, 0.25]:
		for wz in [-0.26, 0.26]:
			add_box(car, Vector3(0.08, 0.14, 0.18), Vector3(wx, 0.08, wz), wheel_mat)

	add_box(car, Vector3(0.10, 0.06, 0.04), Vector3(-0.16, 0.20, 0.46), headlight_mat)
	add_box(car, Vector3(0.10, 0.06, 0.04), Vector3(0.16, 0.20, 0.46), headlight_mat)
	return car

static func build_city_environment(parent: Node3D, loc_data: Dictionary = {}) -> Array[Dictionary]:
	var cars_data: Array[Dictionary] = []
	var pal: Dictionary = loc_data.get("palette", {})
	var hw: int = int(loc_data.get("grid_half_width", 9))
	var hh: int = int(loc_data.get("grid_half_height", 6))
	var f_hw: float = float(hw)
	var f_hh: float = float(hh)

	var backdrop_col: Color = pal.get("backdrop", Color("efe4d2"))
	var ground_col: Color = pal.get("ground", Color("ecd6b0"))
	var edge_col: Color = pal.get("ground_edge", Color("c9ad86"))
	var road_col: Color = pal.get("road", Color("6c7280"))
	var sidewalk_col: Color = pal.get("sidewalk", Color("d8c9b1"))
	var stripe_col: Color = pal.get("stripe", Color("f6efe3"))
	var water_col: Color = pal.get("water", Color("8fcadb"))
	var tree_a: Color = pal.get("tree_a", Color("8cbf7f"))
	var tree_b: Color = pal.get("tree_b", Color("6ea577"))
	var hedge_col: Color = pal.get("hedge", Color("82b37b"))
	var roof_col: Color = pal.get("roof", Color("b86a5b"))
	var houses_cols: Array = pal.get("houses", [Color("eaa57f"), Color("f3d2a2"), Color("c7d8a2"), Color("e5b3a3")])
	var flowers_cols: Array = pal.get("flowers", [Color("f28b82"), Color("fbd38d"), Color("f6f1e7")])

	var backdrop_mat := get_mat("env_backdrop_%s" % backdrop_col.to_html(), backdrop_col, 0.95)
	var board_top_mat := get_mat("env_board_top_%s" % ground_col.to_html(), ground_col, 0.92)
	var board_edge_mat := get_mat("env_board_edge_%s" % edge_col.to_html(), edge_col, 0.90)
	var road_mat := get_mat("city_road_%s" % road_col.to_html(), road_col, 0.90)
	var sidewalk_mat := get_mat("city_sidewalk_%s" % sidewalk_col.to_html(), sidewalk_col, 0.88)
	var stripe_mat := get_mat("road_stripe_%s" % stripe_col.to_html(), stripe_col, 0.85)
	var hedge_mat := get_mat("plaza_hedge_%s" % hedge_col.to_html(), hedge_col, 0.90)
	var water_mat := get_mat("env_water_%s" % water_col.to_html(), water_col, 0.35)

	var board_w: float = f_hw * 2.0 + 17.0
	var board_d: float = f_hh * 2.0 + 14.0
	var top_w: float = board_w - 1.2
	var top_d: float = board_d - 1.2

	# Large paper-matte table surface + raised tactile diorama board slab
	add_box(parent, Vector3(160.0, 0.10, 160.0), Vector3(0, -0.32, -16.0), backdrop_mat)
	add_box(parent, Vector3(board_w, 0.44, board_d), Vector3(0, -0.23, 0), board_edge_mat)
	add_box(parent, Vector3(top_w, 0.08, top_d), Vector3(0, -0.03, 0), board_top_mat)

	# Optional River & Pond water features (e.g. Riverside Park)
	if loc_data.has("river_span"):
		var span: Vector2 = loc_data["river_span"]
		var river_w: float = span.y - span.x
		var river_cx: float = (span.x + span.y) * 0.5
		var river_len: float = f_hh * 2.0 + 2.6
		add_box(parent, Vector3(river_w + 0.35, 0.03, river_len), Vector3(river_cx, 0.008, 0), board_edge_mat)
		add_box(parent, Vector3(river_w, 0.035, river_len), Vector3(river_cx, 0.015, 0), water_mat)

	var ponds_list: Array = loc_data.get("ponds", [])
	for pond in ponds_list:
		var pc: Vector2 = pond["center"]
		var pr: float = float(pond["radius"])
		add_cylinder(parent, pr + 0.18, pr + 0.20, 0.03, Vector3(pc.x, 0.008, pc.y), board_edge_mat, 24)
		add_cylinder(parent, pr, pr, 0.038, Vector3(pc.x, 0.015, pc.y), water_mat, 24)

	# Build Left Road and Right Road outside the map grid width
	for side in [-1, 1]:
		var road_x: float = side * (f_hw + 2.5)
		var inner_walk_x: float = side * (f_hw + 1.0)
		var outer_walk_x: float = side * (f_hw + 4.0)

		add_box(parent, Vector3(2.2, 0.04, top_d), Vector3(road_x, 0.02, 0), road_mat)
		add_box(parent, Vector3(0.8, 0.08, top_d), Vector3(inner_walk_x, 0.04, 0), sidewalk_mat)
		add_box(parent, Vector3(0.8, 0.08, top_d), Vector3(outer_walk_x, 0.04, 0), sidewalk_mat)

		var stripe_bound: int = hh + 5
		for dz in range(-stripe_bound, stripe_bound + 1, 2):
			if absi(dz) <= 1:
				continue
			add_box(parent, Vector3(0.08, 0.05, 0.85), Vector3(road_x, 0.042, dz), stripe_mat)

		for s in range(-3, 4):
			add_box(parent, Vector3(0.22, 0.05, 1.15), Vector3(road_x + s * 0.28, 0.043, 0), stripe_mat)

		add_box(parent, Vector3(0.9, 0.07, 1.15), Vector3(side * (f_hw + 0.45), 0.035, 0), sidewalk_mat)

		for lz in [-(f_hh + 1.2), -2.4, 2.4, f_hh + 1.2]:
			build_streetlamp(parent, Vector3(inner_walk_x, 0.08, lz), -side)

		# Cozy pitched-roof miniature houses & trees outside the outer sidewalk
		var b_idx := 0
		for bz in [-(f_hh + 3.0), -3.8, 3.8, f_hh + 3.0]:
			var h_col: Color = houses_cols[(b_idx + (0 if side < 0 else 2)) % houses_cols.size()]
			var h_height := 1.15 + float(b_idx % 2) * 0.35
			build_cozy_house(parent, Vector3(side * (f_hw + 5.8), 0.0, bz), Vector3(1.85, h_height, 2.45), h_col, roof_col)
			build_cozy_tree(parent, Vector3(side * (f_hw + 4.6), 0.0, bz + 1.65), 0.92, b_idx, tree_a, tree_b)
			b_idx += 1

	# Perimeter hedges & trees framing North and South borders
	var has_station: bool = not loc_data.get("station", {}).is_empty()
	var hedge_z: float = f_hh + 1.5
	for hx in range(-(hw - 1), hw, 2):
		if not (has_station and absi(hx) <= 2):
			add_box(parent, Vector3(1.45, 0.30, 0.36), Vector3(hx, 0.15, -hedge_z), hedge_mat)
		add_box(parent, Vector3(1.45, 0.30, 0.36), Vector3(hx, 0.15, hedge_z), hedge_mat)

	var tree_spots: Array[Vector3] = [
		Vector3(-(f_hw - 0.8), 0, -(f_hh + 0.6)), Vector3(-(f_hw * 0.5), 0, -(f_hh + 0.8)),
		Vector3(f_hw * 0.5, 0, -(f_hh + 0.8)), Vector3(f_hw - 0.8, 0, -(f_hh + 0.6)),
		Vector3(-(f_hw - 0.8), 0, f_hh + 0.6), Vector3(-(f_hw * 0.5), 0, f_hh + 0.8),
		Vector3(f_hw * 0.5, 0, f_hh + 0.8), Vector3(f_hw - 0.8, 0, f_hh + 0.6),
		Vector3(-(f_hw + 0.2), 0, -(f_hh * 0.65)), Vector3(f_hw + 0.2, 0, -(f_hh * 0.65)),
		Vector3(-(f_hw + 0.2), 0, f_hh * 0.65), Vector3(f_hw + 0.2, 0, f_hh * 0.65)
	]
	for i in range(tree_spots.size()):
		build_cozy_tree(parent, tree_spots[i], 0.84 + float(i % 3) * 0.10, i, tree_a, tree_b)

	# Scenario-specific obstacles & landmarks inside the plaza
	var obstacles: Dictionary = loc_data.get("obstacles", {})
	var obs_idx := 0
	for cell_key in obstacles.keys():
		var c: Vector2i = cell_key
		var kind: String = str(obstacles[cell_key])
		var world_pos := Vector3(c.x, 0.0, c.y)
		if kind == "fountain":
			build_fountain_obstacle(parent, world_pos, water_col)
		elif kind == "planter":
			var flw_c: Color = flowers_cols[obs_idx % flowers_cols.size()]
			build_planter_obstacle(parent, world_pos, tree_a, flw_c)
		elif kind == "shop":
			var shop_c: Color = houses_cols[obs_idx % houses_cols.size()]
			build_deco_market_booth(parent, world_pos, shop_c, obs_idx)
		obs_idx += 1

	# Wooden bridge railings over river cells
	var bridges_list: Array = loc_data.get("bridges", [])
	for b_cell in bridges_list:
		var bc: Vector2i = b_cell
		build_wooden_bridge_overlay(parent, Vector3(bc.x, 0.0, bc.y))

	# Overhead glowing lantern strings for Night Market
	var lantern_rows: Array = loc_data.get("lantern_rows", [])
	for rz in lantern_rows:
		var row_z := float(rz)
		for lx in range(-(hw - 2), hw - 1, 3):
			add_night_lamp(parent, Vector3(lx, 1.45, row_z), Color(1.0, 0.76, 0.42), 4.2, 0.95)

	# Grand Train Station on North border for Central Station Plaza
	if has_station:
		build_train_station_landmark(parent, Vector3(0, 0.0, -(f_hh + 1.8)), roof_col)

	# Gate objects removed per design: any path/gate tile at the edge (x = -hw or x = hw) acts as a gate!

	# Spawn 4 ambient miniature cars on the city roads
	var car_z_limit: float = f_hh + 6.0
	var car_configs: Array[Dictionary] = [
		{"x": -(f_hw + 3.0), "z": -(car_z_limit - 1.5), "dir": 1.0, "speed": 3.6, "color": Color("e06d53")},
		{"x": -(f_hw + 2.0), "z": car_z_limit - 2.5, "dir": -1.0, "speed": 4.0, "color": Color("5899c4")},
		{"x": f_hw + 2.0, "z": -(car_z_limit - 3.5), "dir": 1.0, "speed": 3.8, "color": Color("eab64d")},
		{"x": f_hw + 3.0, "z": car_z_limit - 1.5, "dir": -1.0, "speed": 3.5, "color": Color("6cae75")}
	]
	for cfg in car_configs:
		var car_node := build_ambient_car(parent, cfg["color"])
		var dir_val: float = cfg["dir"]
		car_node.position = Vector3(cfg["x"], 0.04, cfg["z"])
		car_node.rotation_degrees.y = 0.0 if dir_val > 0.0 else 180.0
		cars_data.append({
			"node": car_node,
			"dir": dir_val,
			"speed": cfg["speed"],
			"z_limit": car_z_limit
		})

	return cars_data

static func build_title_diorama(parent: Node3D) -> Dictionary:
	## Builds a dedicated, living Main Menu 3D diorama island at parent's position (e.g. z = -42)
	var board_top := get_mat("title_top", Color("ead7b7"), 0.90)
	var board_edge := get_mat("title_edge", Color("c4ab85"), 0.90)
	var path_mat := get_mat("title_path", Color("8d7c70"), 0.86)
	var curb_mat := get_mat("title_curb", Color("6e6057"), 0.90)
	var water_col := Color("84c5d6")

	# Tactile rounded diorama island
	add_box(parent, Vector3(22.0, 0.44, 16.0), Vector3(0, -0.23, 0), board_edge)
	add_box(parent, Vector3(21.0, 0.08, 15.0), Vector3(0, -0.03, 0), board_top)

	# Central roundabout plaza + fountain
	add_cylinder(parent, 3.3, 3.35, 0.04, Vector3(0, 0.02, 0), curb_mat, 28)
	add_cylinder(parent, 2.95, 2.98, 0.055, Vector3(0, 0.032, 0), path_mat, 28)
	add_box(parent, Vector3(16.0, 0.04, 1.35), Vector3(0, 0.02, 0), curb_mat)
	add_box(parent, Vector3(16.0, 0.055, 1.08), Vector3(0, 0.032, 0), path_mat)
	add_box(parent, Vector3(1.35, 0.04, 11.0), Vector3(0, 0.02, 0), curb_mat)
	add_box(parent, Vector3(1.08, 0.055, 11.0), Vector3(0, 0.032, 0), path_mat)

	build_fountain_obstacle(parent, Vector3(0, 0.04, 0), water_col)

	# Cozy miniature shops & houses around the roundabout
	var f0 := build_facility_visual(1)
	f0.position = Vector3(-3.8, 0.0, -2.6)
	parent.add_child(f0)

	var f1 := build_facility_visual(3)
	f1.position = Vector3(3.8, 0.0, -2.6)
	parent.add_child(f1)

	var f2 := build_facility_visual(5)
	f2.position = Vector3(-3.6, 0.0, 2.6)
	parent.add_child(f2)

	var f3 := build_facility_visual(2)
	f3.position = Vector3(3.6, 0.0, 2.6)
	parent.add_child(f3)

	var house_cols: Array[Color] = [Color("eaa57f"), Color("f3d2a2"), Color("b9cfdb"), Color("c7d8a2")]
	var house_positions: Array[Vector3] = [
		Vector3(-7.4, 0, -4.4), Vector3(7.4, 0, -4.4),
		Vector3(-7.4, 0, 4.4), Vector3(7.4, 0, 4.4)
	]
	for i in range(house_positions.size()):
		build_cozy_house(parent, house_positions[i], Vector3(1.8, 1.25, 2.0), house_cols[i], Color("b86a5b"))

	var tree_positions: Array[Vector3] = [
		Vector3(-5.5, 0, -4.8), Vector3(-2.2, 0, -5.2), Vector3(2.2, 0, -5.2), Vector3(5.5, 0, -4.8),
		Vector3(-5.5, 0, 4.8), Vector3(-2.2, 0, 5.2), Vector3(2.2, 0, 5.2), Vector3(5.5, 0, 4.8),
		Vector3(-8.4, 0, -1.8), Vector3(8.4, 0, -1.8), Vector3(-8.4, 0, 1.8), Vector3(8.4, 0, 1.8)
	]
	for i in range(tree_positions.size()):
		build_cozy_tree(parent, tree_positions[i], 0.92, i, Color("7db874"), Color("5ea068"))

	# Spawn strolling ambient pawns orbiting the roundabout
	var walkers: Array[Dictionary] = []
	var pawn_cols: Array[Color] = [
		Color("e8654a"), Color("4a90ba"), Color("f0b43a"),
		Color("6cae75"), Color("d97298"), Color("e8654a"),
		Color("5b84c4"), Color("e28743")
	]
	for i in range(8):
		var pawn := Node3D.new()
		var p_mat := get_mat("title_pawn_%d" % i, pawn_cols[i])
		add_cylinder(pawn, 0.12, 0.18, 0.36, Vector3(0, 0.22, 0), p_mat, 14)
		add_sphere(pawn, 0.14, 0.28, Vector3(0, 0.52, 0), p_mat)
		parent.add_child(pawn)
		walkers.append({
			"node": pawn,
			"angle": float(i) * (TAU / 8.0),
			"radius": 2.05 + float(i % 3) * 0.38,
			"speed": (0.55 + float(i % 3) * 0.12) * (1.0 if i % 2 == 0 else -1.0)
		})

	# Floating 3D Hot-Air Balloons & Puffy Clouds for a lively 3D title scene
	var floaters: Array[Dictionary] = []
	var balloon_configs: Array[Dictionary] = [
		{"pos": Vector3(-5.8, 3.8, -2.5), "col1": Color("e8654a"), "col2": Color("f6d57a"), "phase": 0.0, "amp": 0.42, "speed": 1.35, "orbit": 0.35},
		{"pos": Vector3(6.2, 4.4, -3.2), "col1": Color("4a90ba"), "col2": Color("f4ede2"), "phase": 2.1, "amp": 0.48, "speed": 1.15, "orbit": 0.40},
		{"pos": Vector3(1.8, 5.1, -5.8), "col1": Color("9b6bb8"), "col2": Color("f2b880"), "phase": 4.2, "amp": 0.36, "speed": 1.50, "orbit": 0.30}
	]
	for b_cfg in balloon_configs:
		var b_node := build_hot_air_balloon(b_cfg["col1"], b_cfg["col2"])
		b_node.position = b_cfg["pos"]
		parent.add_child(b_node)
		floaters.append({
			"node": b_node,
			"base_pos": b_cfg["pos"],
			"phase": float(b_cfg["phase"]),
			"amp": float(b_cfg["amp"]),
			"speed": float(b_cfg["speed"]),
			"orbit": float(b_cfg["orbit"]),
			"rot_speed": 0.45
		})

	var cloud_positions: Array[Vector3] = [
		Vector3(-9.2, 4.8, -5.5),
		Vector3(9.0, 5.3, -4.6),
		Vector3(-7.8, 4.3, 4.6),
		Vector3(8.2, 4.6, 4.0)
	]
	for ci in range(cloud_positions.size()):
		var c_node := build_cozy_cloud(0.85 + float(ci % 2) * 0.22)
		c_node.position = cloud_positions[ci]
		parent.add_child(c_node)
		floaters.append({
			"node": c_node,
			"base_pos": cloud_positions[ci],
			"phase": float(ci) * 1.55,
			"amp": 0.22,
			"speed": 0.85 + float(ci) * 0.12,
			"orbit": 0.55,
			"rot_speed": 0.08
		})

	return {"walkers": walkers, "floaters": floaters}

static func build_hot_air_balloon(primary_col: Color, stripe_col: Color) -> Node3D:
	var root := Node3D.new()
	var mat_main := get_mat("balloon_main_%s" % primary_col.to_html(), primary_col, 0.78)
	var mat_stripe := get_mat("balloon_stripe_%s" % stripe_col.to_html(), stripe_col, 0.82)
	var mat_basket := get_mat("balloon_basket", Color("a67449"), 0.90)
	var mat_rope := get_mat("balloon_rope", Color("594a42"), 0.90)

	# Envelope spheres & tapered neck
	add_sphere(root, 0.72, 1.48, Vector3(0, 1.05, 0), mat_main)
	add_cylinder(root, 0.74, 0.70, 0.28, Vector3(0, 1.05, 0), mat_stripe, 18)
	add_cylinder(root, 0.45, 0.24, 0.36, Vector3(0, 0.38, 0), mat_stripe, 14)

	# Ropes & wicker basket
	for rx in [-0.11, 0.11]:
		for rz in [-0.11, 0.11]:
			add_box(root, Vector3(0.02, 0.28, 0.02), Vector3(rx, 0.14, rz), mat_rope)
	add_box(root, Vector3(0.32, 0.24, 0.32), Vector3(0, -0.04, 0), mat_basket)
	return root

static func build_cozy_cloud(scale_factor: float = 1.0) -> Node3D:
	var root := Node3D.new()
	var mat_cloud := get_mat("cozy_cloud_white", Color("fbf8f3"), 0.92)
	add_sphere(root, 0.62 * scale_factor, 0.78 * scale_factor, Vector3(0, 0, 0), mat_cloud)
	add_sphere(root, 0.48 * scale_factor, 0.62 * scale_factor, Vector3(-0.52 * scale_factor, -0.06 * scale_factor, 0.08 * scale_factor), mat_cloud)
	add_sphere(root, 0.50 * scale_factor, 0.64 * scale_factor, Vector3(0.54 * scale_factor, -0.05 * scale_factor, -0.06 * scale_factor), mat_cloud)
	add_sphere(root, 0.38 * scale_factor, 0.48 * scale_factor, Vector3(0.18 * scale_factor, 0.18 * scale_factor, 0.24 * scale_factor), mat_cloud)
	return root
