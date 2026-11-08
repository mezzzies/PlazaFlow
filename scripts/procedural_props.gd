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

static func add_sphere(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 8
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot_deg
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
		# 13 = FLOWER GARDEN: Grand 2x2 botanical park with tiered stone fountain, lush rose rings & garden lamps
		var curb_stone := get_mat("fg_curb", Color("8a7b6e"), 0.88)
		var soil_mat := get_mat("fg_soil", Color("4e3522"), 0.95)
		var leaf_mat := get_mat("fg_leaf", Color("3d8b4b"), 0.85)
		var rose_pink := get_mat("fg_pink", Color("f45d82"), 0.70)
		var gold_bloom := get_mat("fg_gold", Color("fbbf24"), 0.65)
		var lav_bloom := get_mat("fg_lav", Color("a855f7"), 0.65)
		var white_bloom := get_mat("fg_white", Color("f8fafc"), 0.60)
		var fountain_stone := get_mat("fg_fstone", Color("dcd6cd"), 0.75)
		var water_basin := get_mat("fg_fwater", Color("38bdf8"), 0.25)

		# 2x2 Outer stone curb rim and rich soil bed
		add_cylinder(root, 0.92, 0.94, 0.08, Vector3(0, 0.04, 0), curb_stone, 28)
		add_cylinder(root, 0.86, 0.88, 0.09, Vector3(0, 0.05, 0), soil_mat, 28)

		# Tiered central water fountain
		add_cylinder(root, 0.32, 0.34, 0.16, Vector3(0, 0.13, 0), fountain_stone, 20)
		add_cylinder(root, 0.28, 0.28, 0.04, Vector3(0, 0.22, 0), water_basin, 18)
		add_cylinder(root, 0.10, 0.13, 0.32, Vector3(0, 0.35, 0), fountain_stone, 14)
		add_cylinder(root, 0.22, 0.18, 0.06, Vector3(0, 0.52, 0), fountain_stone, 16)
		add_sphere(root, 0.065, 0.10, Vector3(0, 0.60, 0), water_basin)

		# Outer floral ring (10 vibrant bushes with blooms)
		var flw_palette: Array[StandardMaterial3D] = [rose_pink, gold_bloom, lav_bloom, white_bloom]
		for i in range(10):
			var ang := float(i) * (TAU / 10.0)
			var r := 0.68
			var bx := cos(ang) * r
			var bz := sin(ang) * r
			add_sphere(root, 0.16, 0.22, Vector3(bx, 0.16, bz), leaf_mat)
			add_sphere(root, 0.075, 0.12, Vector3(bx, 0.28, bz), flw_palette[i % 4])

		# Inner floral accents (6 bushes)
		for j in range(6):
			var ang2 := float(j) * (TAU / 6.0) + 0.3
			var r2 := 0.46
			var ix := cos(ang2) * r2
			var iz := sin(ang2) * r2
			add_sphere(root, 0.12, 0.17, Vector3(ix, 0.15, iz), leaf_mat)
			add_sphere(root, 0.06, 0.09, Vector3(ix, 0.25, iz), flw_palette[(j + 2) % 4])

		# Two cozy garden path lamps
		add_cylinder(root, 0.02, 0.025, 0.62, Vector3(-0.68, 0.34, 0.30), curb_stone, 8)
		add_sphere(root, 0.05, 0.08, Vector3(-0.68, 0.66, 0.30), gold_bloom)
		add_night_lamp(root, Vector3(-0.68, 0.66, 0.30), Color(1.0, 0.88, 0.65), 4.2, 1.0)

		add_cylinder(root, 0.02, 0.025, 0.62, Vector3(0.68, 0.34, -0.30), curb_stone, 8)
		add_sphere(root, 0.05, 0.08, Vector3(0.68, 0.66, -0.30), gold_bloom)
		add_night_lamp(root, Vector3(0.68, 0.66, -0.30), Color(1.0, 0.88, 0.65), 4.2, 1.0)

	elif facility_type == 14:
		# 14 = DUCK POND (3x2): Scenic rectangular lake with natural stone embankment, lily pads & swimming ducks
		var rim_stone := get_mat("dp_stone", Color("7c756d"), 0.85)
		var water_mat := get_mat("dp_water", Color("42a5c2"), 0.24)
		var lily_mat := get_mat("dp_lily", Color("489c54"), 0.8)
		var duck_yellow := get_mat("dp_duck", Color("facc15"), 0.6)
		var duck_white := get_mat("dp_dwhite", Color("f8fafc"), 0.6)
		var beak_orange := get_mat("dp_beak", Color("ea580c"), 0.7)
		var dock_wood := get_mat("dp_wood", Color("784c28"), 0.85)

		# 3x2 Rectangular Stone Rim & Azure Water Basin
		add_box(root, Vector3(2.78, 0.08, 1.78), Vector3(0, 0.04, 0), rim_stone)
		add_box(root, Vector3(2.54, 0.07, 1.54), Vector3(0, 0.055, 0), water_mat)

		# Wooden viewing pier / dock on the front edge
		add_box(root, Vector3(0.56, 0.07, 0.42), Vector3(0.0, 0.09, 0.68), dock_wood)
		add_cylinder(root, 0.035, 0.035, 0.18, Vector3(-0.22, 0.11, 0.82), dock_wood, 8)
		add_cylinder(root, 0.035, 0.035, 0.18, Vector3(0.22, 0.11, 0.82), dock_wood, 8)

		# Scattered natural lily pads with mini blossoms across the 3x2 basin
		var lily_positions: Array[Vector3] = [
			Vector3(-0.88, 0.095, -0.36),
			Vector3(-0.35, 0.095, 0.34),
			Vector3(0.45, 0.095, -0.42),
			Vector3(0.86, 0.095, 0.22),
			Vector3(-0.72, 0.095, 0.18),
			Vector3(0.15, 0.095, -0.18)
		]
		for lp in lily_positions:
			add_cylinder(root, 0.12, 0.12, 0.015, lp, lily_mat, 12)
			add_sphere(root, 0.038, 0.05, lp + Vector3(0, 0.02, 0), get_mat("dp_flw", Color("fda4af")))

		# 4 cute swimming ducks across the 3x2 lake
		var duck_configs: Array[Dictionary] = [
			{"pos": Vector3(-0.55, 0.11, -0.15), "rot": -25.0, "mat": duck_yellow},
			{"pos": Vector3(0.32, 0.11, -0.05), "rot": 45.0, "mat": duck_white},
			{"pos": Vector3(-0.05, 0.11, 0.32), "rot": 130.0, "mat": duck_yellow},
			{"pos": Vector3(0.75, 0.11, -0.25), "rot": -65.0, "mat": duck_white}
		]
		for dc in duck_configs:
			var dpos: Vector3 = dc["pos"]
			var dmat: Material = dc["mat"]
			var drot: float = float(dc["rot"])
			var d_root := Node3D.new()
			d_root.position = dpos
			d_root.rotation_degrees.y = drot
			root.add_child(d_root)
			add_sphere(d_root, 0.085, 0.11, Vector3(0, 0, 0), dmat)
			add_sphere(d_root, 0.055, 0.10, Vector3(0, 0.07, 0.06), dmat)
			add_box(d_root, Vector3(0.04, 0.02, 0.04), Vector3(0, 0.07, 0.11), beak_orange)

		# Shoreline lanterns on left and right banks
		for lx in [-1.18, 1.18]:
			add_cylinder(root, 0.025, 0.03, 0.65, Vector3(lx, 0.35, 0.58), rim_stone, 8)
			add_sphere(root, 0.06, 0.08, Vector3(lx, 0.68, 0.58), get_mat("dp_lamp", Color("fef08a")))
			add_night_lamp(root, Vector3(lx, 0.68, 0.58), Color(0.65, 0.92, 1.0), 4.5, 1.1)

	elif facility_type == 15:
		# 15 = COFFEE ROASTER (1x1): Warm brick & copper espresso kiosk with giant coffee cup sign
		var brick_mat := get_mat("cr_brick", Color("9c4a38"))
		var copper_mat := get_mat("cr_copper", Color("d48952"), 0.45)

		add_box(root, Vector3(0.72, 0.46, 0.56), Vector3(0, 0.28, 0), brick_mat)
		add_box(root, Vector3(0.78, 0.07, 0.62), Vector3(0, 0.54, 0), copper_mat)
		add_prism(root, Vector3(0.82, 0.26, 0.66), Vector3(0, 0.70, 0), dark_wood_mat)
		add_cylinder(root, 0.13, 0.10, 0.18, Vector3(0, 0.92, 0), cream_mat, 14)
		add_night_lamp(root, Vector3(0, 0.82, 0.24), Color(1.0, 0.82, 0.52), 3.8, 0.95)

	elif facility_type == 16:
		# 16 = STREET STAGE (2x1): Wide wooden acoustic performance deck with crimson arch & dual spotlights
		var stage_mat := get_mat("ss_wood", Color("b8804f"))
		var velvet_mat := get_mat("ss_velvet", Color("b54558"))
		var gold_mat := get_mat("ss_gold", Color("f2c45a"))

		add_box(root, Vector3(1.76, 0.14, 0.84), Vector3(0, 0.07, 0), stage_mat)
		add_box(root, Vector3(1.56, 0.64, 0.12), Vector3(0, 0.46, -0.30), velvet_mat)
		add_box(root, Vector3(1.66, 0.09, 0.18), Vector3(0, 0.80, -0.28), gold_mat)
		# Microphone stand & speakers
		add_cylinder(root, 0.018, 0.022, 0.46, Vector3(0, 0.37, 0.08), dark_wood_mat, 8)
		add_sphere(root, 0.045, 0.07, Vector3(0, 0.61, 0.08), gold_mat)
		for sx in [-0.62, 0.62]:
			add_box(root, Vector3(0.24, 0.36, 0.22), Vector3(sx, 0.32, 0.05), dark_wood_mat)
		add_night_lamp(root, Vector3(0, 0.92, 0.12), Color(1.0, 0.86, 0.58), 4.6, 1.1)

	elif facility_type == 17:
		# 17 = STAFF HOUSE: Cozy cedar cabin breakroom with navy gabled roof & warm glowing lantern
		var cabin_wood := get_mat("sh_wood", Color("8a5836"))
		var roof_navy := get_mat("sh_roof", Color("2c4459"))
		var door_mat := get_mat("sh_door", Color("543621"))
		var window_mat := get_mat("sh_window", Color("ffebba"), 0.3, 0.8)

		add_box(root, Vector3(0.78, 0.58, 0.64), Vector3(0, 0.32, -0.02), cabin_wood)
		add_prism(root, Vector3(0.86, 0.36, 0.72), Vector3(0, 0.78, -0.02), roof_navy)
		add_box(root, Vector3(0.24, 0.44, 0.04), Vector3(-0.16, 0.25, 0.30), door_mat)
		add_box(root, Vector3(0.22, 0.22, 0.04), Vector3(0.18, 0.34, 0.30), window_mat)
		add_box(root, Vector3(0.40, 0.16, 0.12), Vector3(0.18, 0.12, 0.36), dark_wood_mat)
		add_cylinder(root, 0.03, 0.025, 0.06, Vector3(0.22, 0.23, 0.36), cream_mat, 8)
		add_night_lamp(root, Vector3(-0.16, 0.52, 0.34), Color(1.0, 0.88, 0.60), 3.8, 0.95)

	elif facility_type == 18:
		# 18 = GRAND CLOCKTOWER (2x2): Victorian brick & sandstone spire with 4 clock faces & golden bell dome
		var stone_base := get_mat("ct_stone", Color("d6cbb5"), 0.85)
		var brick_body := get_mat("ct_brick", Color("9e4b3b"), 0.82)
		var clock_face := get_mat("ct_face", Color("fffbeb"), 0.4, 0.6)
		var gold_trim := get_mat("ct_gold", Color("f59e0b"), 0.35)
		var slate_roof := get_mat("ct_slate", Color("334155"), 0.78)
		add_box(root, Vector3(1.66, 0.14, 1.66), Vector3(0, 0.07, 0), stone_base)
		add_box(root, Vector3(0.86, 0.45, 0.86), Vector3(0, 0.36, 0), stone_base)
		add_box(root, Vector3(0.68, 1.15, 0.68), Vector3(0, 1.16, 0), brick_body)
		add_box(root, Vector3(0.76, 0.38, 0.76), Vector3(0, 1.88, 0), stone_base)
		add_cylinder(root, 0.22, 0.22, 0.04, Vector3(0, 1.88, 0.39), clock_face, 16, Vector3(90, 0, 0))
		add_cylinder(root, 0.22, 0.22, 0.04, Vector3(0, 1.88, -0.39), clock_face, 16, Vector3(90, 0, 0))
		add_cylinder(root, 0.22, 0.22, 0.04, Vector3(0.39, 1.88, 0), clock_face, 16, Vector3(0, 0, 90))
		add_cylinder(root, 0.22, 0.22, 0.04, Vector3(-0.39, 1.88, 0), clock_face, 16, Vector3(0, 0, 90))
		add_cylinder(root, 0.04, 0.52, 0.62, Vector3(0, 2.38, 0), slate_roof, 12)
		add_sphere(root, 0.10, 0.16, Vector3(0, 2.72, 0), gold_trim)
		add_night_lamp(root, Vector3(0, 1.95, 0), Color(1.0, 0.90, 0.65), 6.0, 1.25)

	elif facility_type == 19:
		# 19 = VINTAGE CAROUSEL (3x3): Grand 3x3 festive pavilion with golden poles & 8 prancing horses
		var stone_plaza := get_mat("vc_plaza", Color("d6d3d1"), 0.88)
		var base_deck := get_mat("vc_deck", Color("854d27"), 0.80)
		var red_tent := get_mat("vc_red", Color("e11d48"), 0.72)
		var gold_pole := get_mat("vc_gold", Color("fbbf24"), 0.35)
		var horse_white := get_mat("vc_horse", Color("f8fafc"), 0.65)
		add_box(root, Vector3(2.76, 0.08, 2.76), Vector3(0, 0.04, 0), stone_plaza)
		add_cylinder(root, 1.28, 1.34, 0.14, Vector3(0, 0.11, 0), base_deck, 28)
		add_cylinder(root, 0.34, 0.38, 0.95, Vector3(0, 0.62, 0), gold_pole, 18)
		for i in range(8):
			var ang := float(i) * TAU / 8.0
			var px := cos(ang) * 0.96
			var pz := sin(ang) * 0.96
			add_cylinder(root, 0.03, 0.03, 0.95, Vector3(px, 0.62, pz), gold_pole, 8)
			add_box(root, Vector3(0.18, 0.16, 0.32), Vector3(px, 0.45 + float(i % 2) * 0.12, pz), horse_white, Vector3(0, rad_to_deg(-ang), 0))
		add_cylinder(root, 0.10, 1.38, 0.58, Vector3(0, 1.36, 0), red_tent, 24)
		add_cylinder(root, 1.40, 1.40, 0.10, Vector3(0, 1.08, 0), gold_pole, 24)
		add_sphere(root, 0.16, 0.24, Vector3(0, 1.72, 0), gold_pole)
		add_night_lamp(root, Vector3(0, 1.05, 0), Color(1.0, 0.85, 0.55), 6.2, 1.3)

	elif facility_type == 20:
		# 20 = FERRIS WHEEL (4x3): Towering rectangular amusement wheel plaza with boarding deck & 10 gondolas
		var steel_mat := get_mat("fw_steel", Color("e2e8f0"), 0.55)
		var rim_mat := get_mat("fw_rim", Color("38bdf8"), 0.4, 0.7)
		var base_mat := get_mat("fw_base", Color("64748b"), 0.85)
		var deck_wood := get_mat("fw_wood", Color("92400e"), 0.82)
		add_box(root, Vector3(3.76, 0.12, 2.76), Vector3(0, 0.06, 0), base_mat)
		add_box(root, Vector3(2.85, 0.16, 0.85), Vector3(0, 0.14, 0.82), deck_wood)
		# Wide A-frame support legs spanning the 4x3 plaza
		for sz in [-0.46, 0.46]:
			add_cylinder(root, 0.055, 0.07, 2.35, Vector3(-0.65, 1.15, sz), steel_mat, 8, Vector3(0, 0, -24))
			add_cylinder(root, 0.055, 0.07, 2.35, Vector3(0.65, 1.15, sz), steel_mat, 8, Vector3(0, 0, 24))
		# Central axle along Z
		add_cylinder(root, 0.11, 0.11, 1.18, Vector3(0, 2.15, 0), steel_mat, 14, Vector3(90, 0, 0))
		# 10 Gondola pods around the wide X-Y wheel plane
		var pod_cols: Array[Color] = [Color("f43f5e"), Color("fbbf24"), Color("34d399"), Color("a855f7"), Color("38bdf8")]
		for i in range(10):
			var ang := float(i) * TAU / 10.0
			var px := cos(ang) * 1.38
			var py := 2.15 + sin(ang) * 1.38
			var pmat := get_mat("fw_pod_%d" % (i % 5), pod_cols[i % 5], 0.65)
			add_box(root, Vector3(0.28, 0.24, 0.34), Vector3(px, py, 0), pmat)
			add_cylinder(root, 0.025, 0.025, 1.38, Vector3(px * 0.5, 2.15 + sin(ang) * 0.69, -0.32), rim_mat, 6, Vector3(0, 0, rad_to_deg(ang) - 90.0))
			add_cylinder(root, 0.025, 0.025, 1.38, Vector3(px * 0.5, 2.15 + sin(ang) * 0.69, 0.32), rim_mat, 6, Vector3(0, 0, rad_to_deg(ang) - 90.0))
		add_night_lamp(root, Vector3(0, 2.15, 0), Color(0.55, 0.88, 1.0), 7.5, 1.4)

	elif facility_type == 21:
		# 21 = ZEN SHRINE (3x3): Serene 3x3 courtyard with vermilion Torii gate, raked gravel, bridge & twin sakura trees
		var gravel_mat := get_mat("zs_gravel", Color("e7e5e4"), 0.92)
		var torii_mat := get_mat("zs_torii", Color("dc2626"), 0.72)
		var dark_cap := get_mat("zs_cap", Color("1c1917"), 0.85)
		var sakura_pink := get_mat("zs_sakura", Color("f9a8d4"), 0.80)
		add_box(root, Vector3(2.76, 0.08, 2.76), Vector3(0, 0.04, 0), gravel_mat)
		# Main Shrine hall at rear
		add_box(root, Vector3(1.42, 0.64, 0.92), Vector3(0, 0.38, -0.68), cream_mat)
		add_prism(root, Vector3(1.68, 0.42, 1.12), Vector3(0, 0.88, -0.68), dark_cap)
		# Vermilion Torii Gate at front entrance
		add_cylinder(root, 0.07, 0.08, 1.16, Vector3(-0.56, 0.60, 0.95), torii_mat, 10)
		add_cylinder(root, 0.07, 0.08, 1.16, Vector3(0.56, 0.60, 0.95), torii_mat, 10)
		add_box(root, Vector3(1.46, 0.09, 0.14), Vector3(0, 1.00, 0.95), torii_mat)
		add_box(root, Vector3(1.64, 0.10, 0.18), Vector3(0, 1.16, 0.95), dark_cap)
		# Twin Sakura trees flanking the courtyard
		for sx in [-0.92, 0.92]:
			add_cylinder(root, 0.09, 0.12, 0.78, Vector3(sx, 0.42, 0.15), dark_wood_mat, 8)
			add_sphere(root, 0.48, 0.62, Vector3(sx, 0.92, 0.15), sakura_pink)
		add_night_lamp(root, Vector3(0, 0.85, 0.25), Color(1.0, 0.85, 0.62), 5.5, 1.15)

	elif facility_type == 22:
		# 22 = GOLDEN MONOLITH (2x2): Retro diner kiosk with rotating giant golden burger monument
		var tile_base := get_mat("gm_base", Color("334155"), 0.80)
		var diner_red := get_mat("gm_red", Color("dc2626"), 0.65)
		var gold_bun := get_mat("gm_gold", Color("f59e0b"), 0.30)
		var gold_patty := get_mat("gm_patty", Color("b45309"), 0.40)
		var lettuce_mat := get_mat("gm_green", Color("22c55e"), 0.60)
		add_box(root, Vector3(1.68, 0.12, 1.68), Vector3(0, 0.06, 0), tile_base)
		add_cylinder(root, 0.58, 0.64, 0.58, Vector3(0, 0.38, 0), diner_red, 18)
		add_cylinder(root, 0.64, 0.64, 0.08, Vector3(0, 0.68, 0), cream_mat, 18)
		add_cylinder(root, 0.12, 0.16, 0.42, Vector3(0, 0.90, 0), gold_bun, 12)
		add_cylinder(root, 0.46, 0.42, 0.14, Vector3(0, 1.15, 0), gold_bun, 18)
		add_cylinder(root, 0.50, 0.50, 0.06, Vector3(0, 1.25, 0), lettuce_mat, 18)
		add_cylinder(root, 0.48, 0.48, 0.12, Vector3(0, 1.34, 0), gold_patty, 18)
		add_sphere(root, 0.46, 0.34, Vector3(0, 1.46, 0), gold_bun)
		add_night_lamp(root, Vector3(0, 1.65, 0), Color(1.0, 0.86, 0.40), 5.2, 1.2)

	elif facility_type == 23:
		# 23 = WISHING WELL (1x1): Cobblestone well with timber A-frame roof, rope bucket & sparkling water
		var cobble_mat := get_mat("ww_cobble", Color("78716c"), 0.88)
		var water_glow := get_mat("ww_water", Color("38bdf8"), 0.25, 0.9)
		var roof_wood := get_mat("ww_roof", Color("92400e"), 0.82)
		add_cylinder(root, 0.38, 0.42, 0.38, Vector3(0, 0.20, 0), cobble_mat, 16)
		add_cylinder(root, 0.30, 0.30, 0.39, Vector3(0, 0.21, 0), water_glow, 16)
		add_cylinder(root, 0.035, 0.035, 0.56, Vector3(-0.32, 0.56, 0), dark_wood_mat, 8)
		add_cylinder(root, 0.035, 0.035, 0.56, Vector3(0.32, 0.56, 0), dark_wood_mat, 8)
		add_prism(root, Vector3(0.84, 0.34, 0.56), Vector3(0, 0.94, 0), roof_wood)
		add_night_lamp(root, Vector3(0, 0.55, 0), Color(0.45, 0.88, 1.0), 3.8, 1.0)

	elif facility_type == 24:
		# 24 = CYBER ARCADE (3x2): Wide neon synthwave gaming hall with glowing magenta/cyan marquee & giant joystick
		var dark_hull := get_mat("ca_hull", Color("1e1b4b"), 0.70)
		var neon_pink := get_mat("ca_pink", Color("f43f5e"), 0.2, 1.2)
		var neon_cyan := get_mat("ca_cyan", Color("06b6d4"), 0.2, 1.2)
		add_box(root, Vector3(2.68, 0.92, 1.56), Vector3(0, 0.48, 0), dark_hull)
		add_box(root, Vector3(2.76, 0.10, 1.64), Vector3(0, 0.96, 0), neon_pink)
		add_box(root, Vector3(2.74, 0.08, 1.62), Vector3(0, 0.56, 0), neon_cyan)
		# Giant rooftop joystick & dual arcade buttons
		add_box(root, Vector3(1.12, 0.16, 0.76), Vector3(0, 1.06, 0), dark_hull)
		add_cylinder(root, 0.05, 0.05, 0.44, Vector3(-0.24, 1.34, 0), get_mat("ca_steel", Color("cbd5e1")), 8, Vector3(0, 0, -15))
		add_sphere(root, 0.15, 0.24, Vector3(-0.32, 1.58, 0), neon_pink)
		add_cylinder(root, 0.13, 0.14, 0.09, Vector3(0.18, 1.15, 0.12), neon_cyan, 12)
		add_cylinder(root, 0.13, 0.14, 0.09, Vector3(0.42, 1.15, -0.10), neon_pink, 12)
		add_night_lamp(root, Vector3(0, 1.45, 0.55), Color(0.95, 0.35, 0.85), 6.2, 1.35)

	elif facility_type == 25:
		# 25 = BOTANICAL DOME (3x3): Expansive 3x3 crystal geodesic conservatory dome with lush indoor palms
		var stone_rim := get_mat("bd_rim", Color("d6d3d1"), 0.85)
		var glass_dome := get_mat("bd_glass", Color("6ee7b7"), 0.28, 0.4)
		var palm_green := get_mat("bd_palm", Color("16a34a"), 0.78)
		add_box(root, Vector3(2.76, 0.10, 2.76), Vector3(0, 0.05, 0), stone_rim)
		add_cylinder(root, 1.28, 1.34, 0.22, Vector3(0, 0.14, 0), stone_rim, 28)
		add_sphere(root, 1.24, 1.65, Vector3(0, 0.30, 0), glass_dome)
		add_box(root, Vector3(0.68, 0.48, 0.44), Vector3(0, 0.26, 1.16), stone_rim)
		add_sphere(root, 0.54, 0.72, Vector3(0, 0.62, 0), palm_green)
		add_night_lamp(root, Vector3(0, 0.95, 0), Color(0.55, 1.0, 0.75), 6.2, 1.25)

	elif facility_type == 26:
		# 26 = TRIUMPH ARCH (3x2): Wide neoclassical marble archway with golden reliefs & rooftop monument
		var marble_mat := get_mat("ta_marble", Color("f5f5f4"), 0.78)
		var gold_relief := get_mat("ta_gold", Color("eab308"), 0.38)
		add_box(root, Vector3(2.76, 0.12, 1.72), Vector3(0, 0.06, 0), marble_mat)
		add_box(root, Vector3(0.76, 1.38, 1.12), Vector3(-0.78, 0.75, 0), marble_mat)
		add_box(root, Vector3(0.76, 1.38, 1.12), Vector3(0.78, 0.75, 0), marble_mat)
		add_box(root, Vector3(2.46, 0.46, 1.22), Vector3(0, 1.62, 0), marble_mat)
		add_box(root, Vector3(2.54, 0.10, 1.28), Vector3(0, 1.88, 0), gold_relief)
		add_sphere(root, 0.26, 0.38, Vector3(0, 2.12, 0), gold_relief)
		add_night_lamp(root, Vector3(0, 1.35, 0), Color(1.0, 0.92, 0.68), 6.0, 1.25)

	elif facility_type == 27:
		# 27 = GELATO PAVILION (1x1): Pastel Italian parlor with striped awning & giant triple-scoop cone
		var mint_wall := get_mat("gp_mint", Color("a7f3d0"), 0.78)
		var pink_scoop := get_mat("gp_pink", Color("f472b6"), 0.65)
		var cone_waffle := get_mat("gp_waffle", Color("d97706"), 0.82)
		add_box(root, Vector3(0.74, 0.54, 0.62), Vector3(0, 0.28, 0), mint_wall)
		add_cylinder(root, 0.44, 0.48, 0.14, Vector3(0, 0.60, 0), pink_scoop, 14)
		add_cylinder(root, 0.14, 0.03, 0.32, Vector3(0, 0.80, 0), cone_waffle, 12)
		add_sphere(root, 0.15, 0.22, Vector3(0, 0.98, 0), pink_scoop)
		add_sphere(root, 0.12, 0.18, Vector3(0, 1.14, 0), cream_mat)
		add_night_lamp(root, Vector3(0, 0.72, 0.26), Color(1.0, 0.82, 0.90), 3.8, 0.95)

	elif facility_type == 28:
		# 28 = BIERGARTEN (3x2): Wide Bavarian timber hall with blue/white canopy, oak barrels & picnic terrace
		var timber_hall := get_mat("bg_timber", Color("78350f"), 0.85)
		var bav_blue := get_mat("bg_blue", Color("0284c7"), 0.75)
		var mug_gold := get_mat("bg_mug", Color("f59e0b"), 0.45)
		add_box(root, Vector3(2.74, 0.10, 1.74), Vector3(0, 0.05, 0), dark_wood_mat)
		add_box(root, Vector3(2.12, 0.68, 0.92), Vector3(0, 0.42, -0.28), cream_mat)
		add_prism(root, Vector3(2.28, 0.48, 1.06), Vector3(0, 0.98, -0.28), bav_blue)
		# Giant oak barrel & foaming mug on front terrace
		add_cylinder(root, 0.24, 0.26, 0.42, Vector3(-0.68, 0.30, 0.46), timber_hall, 12)
		add_cylinder(root, 0.18, 0.18, 0.36, Vector3(0.68, 0.28, 0.46), mug_gold, 12)
		add_sphere(root, 0.19, 0.18, Vector3(0.68, 0.48, 0.46), cream_mat)
		add_night_lamp(root, Vector3(0, 0.95, 0.40), Color(1.0, 0.85, 0.50), 5.4, 1.2)

	elif facility_type == 29:
		# 29 = PLANETARIUM (3x3): Grand 3x3 cosmic star theater with tilted golden Saturn ring & telescope
		var cosmic_blue := get_mat("pl_blue", Color("1e3a8a"), 0.55)
		var ring_gold := get_mat("pl_gold", Color("facc15"), 0.35, 0.8)
		var star_white := get_mat("pl_white", Color("f8fafc"), 0.75)
		add_box(root, Vector3(2.76, 0.10, 2.76), Vector3(0, 0.05, 0), star_white)
		add_cylinder(root, 1.22, 1.28, 0.24, Vector3(0, 0.18, 0), star_white, 28)
		add_sphere(root, 1.12, 1.38, Vector3(0, 0.44, 0), cosmic_blue)
		add_cylinder(root, 1.38, 1.38, 0.05, Vector3(0, 0.78, 0), ring_gold, 28, Vector3(18, 0, -14))
		add_cylinder(root, 0.08, 0.11, 0.62, Vector3(0.38, 1.18, 0.32), star_white, 10, Vector3(-35, 25, 0))
		add_night_lamp(root, Vector3(0, 1.55, 0), Color(0.65, 0.85, 1.0), 9.5, 1.5)

	elif facility_type == 30:
		# 30 = SKATE BOWL (4x2): Long rectangular concrete halfpipe & street skate plaza with teal/orange coping
		var concrete_mat := get_mat("sb_conc", Color("94a3b8"), 0.86)
		var coping_teal := get_mat("sb_teal", Color("06b6d4"), 0.65)
		var deck_orange := get_mat("sb_orange", Color("f97316"), 0.70)
		add_box(root, Vector3(3.76, 0.16, 1.76), Vector3(0, 0.08, 0), concrete_mat)
		add_box(root, Vector3(0.48, 0.52, 1.66), Vector3(-1.56, 0.40, 0), concrete_mat)
		add_box(root, Vector3(0.48, 0.52, 1.66), Vector3(1.56, 0.40, 0), concrete_mat)
		add_cylinder(root, 0.045, 0.045, 1.66, Vector3(-1.32, 0.66, 0), coping_teal, 10, Vector3(90, 0, 0))
		add_cylinder(root, 0.045, 0.045, 1.66, Vector3(1.32, 0.66, 0), deck_orange, 10, Vector3(90, 0, 0))
		# Central grind rail
		add_box(root, Vector3(1.45, 0.05, 0.06), Vector3(0, 0.28, 0), deck_orange)
		add_night_lamp(root, Vector3(0, 0.95, 0), Color(0.85, 0.95, 1.0), 5.6, 1.15)

	elif facility_type == 31:
		# 31 = SPA BATHHOUSE (3x2): Rectangular cedar & slate hot-spring onsen pavilion with steaming turquoise pool
		var cedar_mat := get_mat("sp_cedar", Color("9a5b32"), 0.82)
		var onsen_water := get_mat("sp_water", Color("2dd4bf"), 0.25, 0.6)
		var roof_slate := get_mat("sp_slate", Color("334155"), 0.80)
		add_box(root, Vector3(2.74, 0.14, 1.74), Vector3(0, 0.07, 0), get_mat("sp_rock", Color("57534e")))
		add_box(root, Vector3(1.56, 0.64, 0.96), Vector3(-0.42, 0.42, -0.24), cedar_mat)
		add_prism(root, Vector3(1.76, 0.44, 1.12), Vector3(-0.42, 0.94, -0.24), roof_slate)
		add_cylinder(root, 0.64, 0.68, 0.14, Vector3(0.62, 0.15, 0.22), onsen_water, 20)
		add_night_lamp(root, Vector3(0, 0.75, 0.32), Color(1.0, 0.88, 0.64), 5.4, 1.15)

	elif facility_type == 32:
		# 32 = OBSERVATION TOWER (3x3): Futuristic sky needle on a 3x3 plaza with panoramic skydeck & beacon spire
		var tower_white := get_mat("ot_white", Color("f1f5f9"), 0.65)
		var sky_glass := get_mat("ot_glass", Color("38bdf8"), 0.25, 0.9)
		var beacon_red := get_mat("ot_red", Color("ef4444"), 0.3, 1.2)
		add_box(root, Vector3(2.76, 0.10, 2.76), Vector3(0, 0.05, 0), tower_white)
		add_cylinder(root, 1.08, 1.18, 0.20, Vector3(0, 0.14, 0), tower_white, 24)
		add_cylinder(root, 0.22, 0.42, 2.05, Vector3(0, 1.22, 0), tower_white, 18)
		add_cylinder(root, 0.82, 0.64, 0.28, Vector3(0, 2.28, 0), sky_glass, 24)
		add_cylinder(root, 0.68, 0.82, 0.14, Vector3(0, 2.48, 0), tower_white, 24)
		add_cylinder(root, 0.025, 0.05, 0.68, Vector3(0, 2.88, 0), tower_white, 8)
		add_sphere(root, 0.08, 0.14, Vector3(0, 3.24, 0), beacon_red)
		add_night_lamp(root, Vector3(0, 2.52, 0), Color(0.60, 0.90, 1.0), 7.5, 1.4)

	elif facility_type == 33:
		# 33 = TEA HOUSE (2x1): Rectangular matcha cottage & bamboo verandah with ceremonial teacup emblem
		var bamboo_wall := get_mat("th_wall", Color("d9f99d"), 0.82)
		var matcha_roof := get_mat("th_roof", Color("15803d"), 0.78)
		add_box(root, Vector3(1.76, 0.10, 0.82), Vector3(0, 0.05, 0), dark_wood_mat)
		add_box(root, Vector3(1.24, 0.56, 0.66), Vector3(-0.18, 0.34, 0), bamboo_wall)
		add_prism(root, Vector3(1.42, 0.38, 0.78), Vector3(-0.18, 0.78, 0), matcha_roof)
		add_cylinder(root, 0.16, 0.12, 0.18, Vector3(0.52, 0.22, 0), matcha_roof, 14)
		add_night_lamp(root, Vector3(0, 0.72, 0.32), Color(0.85, 1.0, 0.70), 4.4, 1.0)

	elif facility_type == 34:
		# 34 = ART OBELISK (1x1): Avant-garde kinetic geometric sculpture with levitating golden prism
		var obsidian_mat := get_mat("ao_obs", Color("1e293b"), 0.45)
		var kinetic_gold := get_mat("ao_gold", Color("f59e0b"), 0.25, 0.8)
		var kinetic_rose := get_mat("ao_rose", Color("ec4899"), 0.35, 0.7)
		add_box(root, Vector3(0.68, 0.14, 0.68), Vector3(0, 0.07, 0), obsidian_mat)
		add_cylinder(root, 0.08, 0.22, 0.78, Vector3(0, 0.52, 0), obsidian_mat, 6)
		add_box(root, Vector3(0.32, 0.32, 0.32), Vector3(0, 1.08, 0), kinetic_gold, Vector3(35, 45, 20))
		add_sphere(root, 0.14, 0.22, Vector3(0, 1.46, 0), kinetic_rose)
		add_night_lamp(root, Vector3(0, 1.15, 0), Color(1.0, 0.75, 0.90), 4.2, 1.1)

	elif facility_type == 35:
		# 35 = CIRCUS TENT (4x4): Massive 4x4 Grand Big-Top striped pavilion with twin spires & festive entrance arch
		var bigtop_red := get_mat("ct_red", Color("dc2626"), 0.75)
		var bigtop_gold := get_mat("ct_ylw", Color("facc15"), 0.72)
		var festival_ground := get_mat("ct_gnd", Color("fde68a"), 0.88)
		add_box(root, Vector3(3.78, 0.08, 3.78), Vector3(0, 0.04, 0), festival_ground)
		add_cylinder(root, 1.66, 1.72, 0.76, Vector3(0, 0.42, 0), bigtop_gold, 28)
		add_cylinder(root, 0.12, 1.78, 0.98, Vector3(0, 1.28, 0), bigtop_red, 28)
		add_box(root, Vector3(0.86, 0.62, 0.56), Vector3(0, 0.34, 1.56), bigtop_red)
		add_cylinder(root, 0.03, 0.03, 0.52, Vector3(0, 1.98, 0), dark_wood_mat, 8)
		add_box(root, Vector3(0.36, 0.16, 0.03), Vector3(0.18, 2.12, 0), bigtop_gold)
		add_night_lamp(root, Vector3(0, 1.25, 0.85), Color(1.0, 0.86, 0.52), 7.2, 1.35)

	elif facility_type == 36:
		# 36 = STEAM TRAIN (4x2): Long 4x2 heritage black & brass locomotive + coal tender on railway track
		var rail_iron := get_mat("st_iron", Color("1e293b"), 0.55)
		var cab_red := get_mat("st_red", Color("b91c1c"), 0.70)
		var brass_trim := get_mat("st_brass", Color("eab308"), 0.35)
		add_box(root, Vector3(3.76, 0.10, 1.68), Vector3(0, 0.05, 0), dark_wood_mat)
		# Long locomotive boiler, cab & rear coal tender car
		add_cylinder(root, 0.34, 0.34, 1.56, Vector3(0.68, 0.52, 0), rail_iron, 18, Vector3(0, 0, 90))
		add_box(root, Vector3(0.68, 0.82, 0.74), Vector3(-0.26, 0.58, 0), cab_red)
		add_box(root, Vector3(0.96, 0.56, 0.70), Vector3(-1.18, 0.45, 0), rail_iron)
		add_cylinder(root, 0.12, 0.10, 0.42, Vector3(1.18, 0.94, 0), brass_trim, 12)
		add_sphere(root, 0.20, 0.26, Vector3(1.18, 1.24, 0), cream_mat)
		for wx in [-1.42, -0.92, -0.26, 0.38, 0.98]:
			for wz in [-0.38, 0.38]:
				add_cylinder(root, 0.18, 0.18, 0.07, Vector3(wx, 0.22, wz), brass_trim, 12, Vector3(90, 0, 0))
		add_night_lamp(root, Vector3(1.48, 0.54, 0), Color(1.0, 0.90, 0.60), 5.6, 1.2)

	elif facility_type == 37:
		# 37 = DIAMOND PAVILION (5x5): Ultimate 5x5 Grand Crystal Exhibition Palace with reflecting pools & golden colonnades
		var marble_base := get_mat("dp_marble", Color("f8fafc"), 0.65)
		var pool_water := get_mat("dp_pool", Color("38bdf8"), 0.22, 0.5)
		var crystal_cyan := get_mat("dp_crys", Color("67e8f9"), 0.20, 1.1)
		var luxury_gold := get_mat("dp_gold", Color("f59e0b"), 0.30)
		# Grand 5x5 marble terrace & reflecting pools
		add_box(root, Vector3(4.78, 0.14, 4.78), Vector3(0, 0.07, 0), marble_base)
		add_box(root, Vector3(4.24, 0.06, 4.24), Vector3(0, 0.15, 0), pool_water)
		add_box(root, Vector3(2.86, 0.20, 2.86), Vector3(0, 0.24, 0), marble_base)
		add_box(root, Vector3(2.68, 0.08, 2.68), Vector3(0, 0.36, 0), luxury_gold)
		# Perimeter golden colonnades
		for cx in [-1.18, 0.0, 1.18]:
			for cz in [-1.18, 0.0, 1.18]:
				if cx == 0.0 and cz == 0.0:
					continue
				add_cylinder(root, 0.09, 0.11, 1.28, Vector3(cx, 1.02, cz), luxury_gold, 12)
		# Grand crystal pyramid roof & levitating giant diamond centerpiece
		add_prism(root, Vector3(2.84, 0.88, 2.84), Vector3(0, 2.08, 0), crystal_cyan)
		add_box(root, Vector3(0.76, 0.76, 0.76), Vector3(0, 1.08, 0), crystal_cyan, Vector3(45, 45, 0))
		add_sphere(root, 0.24, 0.36, Vector3(0, 2.64, 0), luxury_gold)
		add_night_lamp(root, Vector3(0, 1.45, 0), Color(0.65, 0.96, 1.0), 9.0, 1.55)

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

static func build_gate_tile_overlay(root: Node3D, is_entry: bool, coords_or_x: Variant, grid_hw: int = 9, grid_hh: int = 6) -> void:
	var accent_col := Color("4eb87a") if is_entry else Color("e86a4a")
	var accent_mat := get_mat("gate_acc_%s" % accent_col.to_html(), accent_col, 0.72)
	var post_mat := get_mat("gate_post", Color("5e4b3c"), 0.85)
	var cream_mat := get_mat("gate_cream", Color("f7f2e7"), 0.82)

	var inward_v := Vector2.RIGHT
	if coords_or_x is Vector2i:
		var c: Vector2i = coords_or_x
		if c.x <= -grid_hw:
			inward_v = Vector2(1.0, 0.0)
		elif c.x >= grid_hw:
			inward_v = Vector2(-1.0, 0.0)
		elif c.y <= -grid_hh:
			inward_v = Vector2(0.0, 1.0)
		elif c.y >= grid_hh:
			inward_v = Vector2(0.0, -1.0)
		else:
			if absf(float(c.x) / float(maxi(1, grid_hw))) >= absf(float(c.y) / float(maxi(1, grid_hh))):
				inward_v = Vector2(-signf(c.x), 0.0)
			else:
				inward_v = Vector2(0.0, -signf(c.y))
	elif coords_or_x is int or coords_or_x is float:
		inward_v = Vector2(1.0 if float(coords_or_x) <= 0.0 else -1.0, 0.0)

	var flow_v: Vector2 = inward_v if is_entry else -inward_v
	var perp_v := Vector2(-flow_v.y, flow_v.x)

	# Low cozy gate bollards perpendicular to the walkway flow
	for s in [-0.38, 0.38]:
		var b_pos := Vector3(perp_v.x * s, 0.19, perp_v.y * s)
		add_cylinder(root, 0.075, 0.09, 0.34, b_pos, post_mat, 10)
		add_cylinder(root, 0.085, 0.085, 0.07, b_pos + Vector3(0, 0.17, 0), accent_mat, 10)
		add_sphere(root, 0.075, 0.11, b_pos + Vector3(0, 0.23, 0), cream_mat)

	# Directional chevron / arrow aligned with flow direction
	var arrow_holder := Node3D.new()
	arrow_holder.rotation.y = atan2(flow_v.x, flow_v.y)
	root.add_child(arrow_holder)
	add_box(arrow_holder, Vector3(0.12, 0.02, 0.28), Vector3(0, 0.062, -0.08), accent_mat)
	add_prism(arrow_holder, Vector3(0.28, 0.22, 0.02), Vector3(0, 0.062, 0.12), cream_mat, Vector3(90, 0, 0))

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
	elif archetype == 5:
		# BUSKER: Burgundy beret + acoustic wooden guitar across torso
		var beret_mat := get_mat("cit_beret", Color("8a2b3b"), 0.75)
		var guitar_body := get_mat("cit_guitar", Color("c47d3b"), 0.70)
		var guitar_neck := get_mat("cit_g_neck", Color("5c3a1e"), 0.85)
		add_cylinder(root, 0.12, 0.18, 0.38, Vector3(0, 0.26, 0), body_mat, 16)
		add_sphere(root, 0.145, 0.29, Vector3(0, 0.58, 0), skin_mat)
		add_cylinder(root, 0.16, 0.15, 0.05, Vector3(0, 0.68, 0), beret_mat, 14, Vector3(10, 0, 5))
		# Acoustic Guitar
		add_box(root, Vector3(0.18, 0.22, 0.07), Vector3(0.04, 0.32, 0.16), guitar_body, Vector3(15, 25, -20))
		add_cylinder(root, 0.018, 0.018, 0.28, Vector3(0.14, 0.48, 0.12), guitar_neck, 8, Vector3(15, 25, -20))
	elif archetype == 6:
		# PHONE ZOMBIE: Hunched posture + glowing blue smartphone held in two hands
		var phone_mat := get_mat("cit_phone", Color("38bdf8"), 0.2, 1.2)
		var phone_case := get_mat("cit_p_case", Color("1e293b"), 0.8)
		add_cylinder(root, 0.12, 0.18, 0.38, Vector3(0, 0.26, 0.03), body_mat, 16, Vector3(12, 0, 0))
		add_sphere(root, 0.145, 0.29, Vector3(0, 0.55, 0.10), skin_mat, Vector3(22, 0, 0))
		# Smartphone
		add_box(root, Vector3(0.12, 0.02, 0.18), Vector3(0, 0.38, 0.22), phone_case, Vector3(-35, 0, 0))
		add_box(root, Vector3(0.10, 0.01, 0.15), Vector3(0, 0.39, 0.22), phone_mat, Vector3(-35, 0, 0))
	elif archetype == 7:
		# TOUR GROUP: Yellow tour visor + camera neck strap + lanyard badge
		var visor_mat := get_mat("cit_visor", Color("fbbf24"), 0.75)
		var cam_mat := get_mat("cit_cam", Color("334155"), 0.7)
		add_cylinder(root, 0.12, 0.18, 0.38, Vector3(0, 0.26, 0), body_mat, 16)
		add_sphere(root, 0.145, 0.29, Vector3(0, 0.58, 0), skin_mat)
		add_cylinder(root, 0.16, 0.16, 0.04, Vector3(0, 0.67, 0.02), visor_mat, 14, Vector3(-8, 0, 0))
		add_box(root, Vector3(0.14, 0.02, 0.08), Vector3(0, 0.65, 0.16), visor_mat, Vector3(-12, 0, 0))
		add_box(root, Vector3(0.11, 0.08, 0.06), Vector3(0, 0.35, 0.14), cam_mat)
	elif archetype == 8:
		# SKATER: Backward red cap + elbow pads + skateboard under feet
		var skate_deck := get_mat("cit_skate_deck", Color("06b6d4"), 0.7)
		var skate_wheel := get_mat("cit_skate_wh", Color("f97316"), 0.8)
		var bcap_mat := get_mat("cit_bcap", Color("ef4444"), 0.75)
		add_cylinder(root, 0.12, 0.18, 0.38, Vector3(0, 0.32, 0), body_mat, 16)
		add_sphere(root, 0.145, 0.29, Vector3(0, 0.64, 0), skin_mat)
		add_sphere(root, 0.15, 0.16, Vector3(0, 0.70, -0.02), bcap_mat)
		add_box(root, Vector3(0.10, 0.02, 0.08), Vector3(0, 0.69, -0.15), bcap_mat, Vector3(15, 0, 0))
		# Skateboard
		add_box(root, Vector3(0.22, 0.03, 0.54), Vector3(0, 0.07, 0), skate_deck)
		for sx in [-0.09, 0.09]:
			for sz in [-0.18, 0.18]:
				add_cylinder(root, 0.04, 0.04, 0.03, Vector3(sx, 0.04, sz), skate_wheel, 8, Vector3(0, 0, 90))
	elif archetype == 9:
		# DOG WALKER: Friendly walker with dynamic leash leading to a cute four-legged dog
		var dog_fur := get_mat("cit_dog_fur", Color("9a5d30"), 0.8)
		var dog_ear := get_mat("cit_dog_ear", Color("6b3d1b"), 0.85)
		var leash_mat := get_mat("cit_leash", Color("ef4444"), 0.7)
		add_cylinder(root, 0.12, 0.18, 0.38, Vector3(0, 0.26, 0.1), body_mat, 16)
		add_sphere(root, 0.145, 0.29, Vector3(0, 0.58, 0.1), skin_mat)
		# Dog entity behind owner
		var dog_node := Node3D.new()
		dog_node.name = "PetDog"
		dog_node.position = Vector3(0.24, 0, -0.42)
		root.add_child(dog_node)
		add_box(dog_node, Vector3(0.16, 0.14, 0.28), Vector3(0, 0.15, 0), dog_fur)
		add_sphere(dog_node, 0.08, 0.14, Vector3(0, 0.22, 0.14), dog_fur)
		add_box(dog_node, Vector3(0.04, 0.08, 0.03), Vector3(-0.07, 0.22, 0.12), dog_ear)
		add_box(dog_node, Vector3(0.04, 0.08, 0.03), Vector3(0.07, 0.22, 0.12), dog_ear)
		for lx in [-0.06, 0.06]:
			for lz in [-0.09, 0.09]:
				add_cylinder(dog_node, 0.02, 0.02, 0.10, Vector3(lx, 0.05, lz), dog_fur, 6)
		# Leash connecting hand to dog collar
		add_cylinder(root, 0.008, 0.008, 0.48, Vector3(0.12, 0.22, -0.16), leash_mat, 4, Vector3(40, 20, 0))
	elif archetype == 10:
		# PICKPOCKET: Stealth charcoal hoodie pulled low + dark gloves & sneaky stance
		var stealth_hood := get_mat("cit_hood", Color("1e293b"), 0.85)
		var mask_mat := get_mat("cit_mask", Color("0f172a"), 0.9)
		add_cylinder(root, 0.12, 0.17, 0.38, Vector3(0, 0.24, 0.04), stealth_hood, 16, Vector3(10, 0, 0))
		add_sphere(root, 0.15, 0.29, Vector3(0, 0.54, 0.08), stealth_hood)
		add_box(root, Vector3(0.14, 0.07, 0.06), Vector3(0, 0.52, 0.18), mask_mat)
	elif archetype == 11:
		# INSPECTOR: Formal tan trench coat + dark fedora + official clipboard
		var coat_mat := get_mat("cit_coat", Color("bfa27b"), 0.8)
		var fedora_mat := get_mat("cit_fedora", Color("3e3228"), 0.85)
		var clip_mat := get_mat("cit_clip", Color("78350f"), 0.8)
		var paper_mat := get_mat("cit_paper", Color("fef3c7"), 0.7)
		add_cylinder(root, 0.13, 0.18, 0.42, Vector3(0, 0.27, 0), coat_mat, 16)
		add_sphere(root, 0.145, 0.29, Vector3(0, 0.60, 0), skin_mat)
		add_cylinder(root, 0.20, 0.20, 0.03, Vector3(0, 0.70, 0), fedora_mat, 14)
		add_cylinder(root, 0.13, 0.12, 0.10, Vector3(0, 0.76, 0), fedora_mat, 12)
		# Clipboard
		add_box(root, Vector3(0.14, 0.20, 0.03), Vector3(0.18, 0.36, 0.12), clip_mat, Vector3(15, 20, 0))
		add_box(root, Vector3(0.11, 0.16, 0.01), Vector3(0.18, 0.36, 0.14), paper_mat, Vector3(15, 20, 0))
	elif archetype == 12:
		# PIGEON FEEDER: Forest-green knit sweater + carrying paper bag of breadcrumbs
		var sweater_mat := get_mat("cit_sweater", Color("2d5a3f"), 0.8)
		var bag_mat := get_mat("cit_bag", Color("d4a373"), 0.85)
		add_cylinder(root, 0.13, 0.18, 0.38, Vector3(0, 0.25, 0), sweater_mat, 16)
		add_sphere(root, 0.145, 0.29, Vector3(0, 0.57, 0), skin_mat)
		add_cylinder(root, 0.14, 0.14, 0.06, Vector3(0, 0.42, 0), cream_mat, 12)
		# Bread bag
		add_box(root, Vector3(0.12, 0.18, 0.10), Vector3(0.16, 0.32, 0.10), bag_mat)
	elif archetype == 13:
		# INFLUENCER: Chic sunglasses + long selfie stick with phone pointing backward
		var glasses_mat := get_mat("cit_glasses", Color("111827"), 0.4)
		var stick_mat := get_mat("cit_stick", Color("94a3b8"), 0.5)
		var sphone_mat := get_mat("cit_sphone", Color("f43f5e"), 0.6)
		add_cylinder(root, 0.12, 0.18, 0.38, Vector3(0, 0.26, 0), body_mat, 16)
		add_sphere(root, 0.145, 0.29, Vector3(0, 0.58, 0), skin_mat)
		# Cool sunglasses
		add_box(root, Vector3(0.18, 0.05, 0.04), Vector3(0, 0.60, 0.13), glasses_mat)
		# Selfie stick extended up and forward
		add_cylinder(root, 0.01, 0.01, 0.46, Vector3(0.12, 0.52, 0.22), stick_mat, 6, Vector3(-45, 15, 0))
		add_box(root, Vector3(0.10, 0.06, 0.02), Vector3(0.16, 0.68, 0.36), sphone_mat, Vector3(-45, 15, 0))
	elif archetype == 14:
		# MARATHONER: Neon athletic tank + running shorts + headband & bib #
		var neon_mat := get_mat("cit_neon", Color("22c55e"), 0.7)
		var bib_mat := get_mat("cit_bib", Color("f8fafc"), 0.8)
		var hband_mat := get_mat("cit_hband", Color("f97316"), 0.75)
		add_cylinder(root, 0.115, 0.17, 0.38, Vector3(0, 0.27, 0.02), neon_mat, 16, Vector3(8, 0, 0))
		add_sphere(root, 0.145, 0.29, Vector3(0, 0.59, 0.04), skin_mat)
		add_cylinder(root, 0.15, 0.15, 0.04, Vector3(0, 0.64, 0.04), hband_mat, 14)
		add_box(root, Vector3(0.12, 0.10, 0.01), Vector3(0, 0.32, 0.14), bib_mat)
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
	elif staff_type == 2:
		# SECURITY OFFICER: Crisp navy uniform + peaked cap + gold badge
		var sec_mat := get_mat("stf_sec", Color("283e66"), 0.75)
		var gold_mat := get_mat("stf_gold", Color("f5c542"), 0.5)
		add_cylinder(root, 0.13, 0.185, 0.40, Vector3(0, 0.27, 0), sec_mat, 16)
		add_box(root, Vector3(0.06, 0.06, 0.03), Vector3(-0.06, 0.36, 0.14), gold_mat)
		add_sphere(root, 0.145, 0.29, Vector3(0, 0.59, 0), skin_mat)
		add_cylinder(root, 0.16, 0.15, 0.07, Vector3(0, 0.70, 0), sec_mat, 14)
	elif staff_type == 3:
		# CLEANING DRONE: Sleek hovering drone with cyan sensor ring & miniature rotors
		var drone_mat := get_mat("stf_drone_white", Color("f0f4f8"), 0.4)
		var cyan_mat := get_mat("stf_drone_cyan", Color("38bdf8"), 0.3, 1.2)
		var dark_prop_mat := get_mat("stf_drone_dark", Color("334155"), 0.8)
		# Central chassis
		add_sphere(root, 0.16, 0.22, Vector3(0, 0.38, 0), drone_mat)
		add_cylinder(root, 0.18, 0.18, 0.05, Vector3(0, 0.36, 0), cyan_mat, 16)
		# 4 mini rotor pods
		for rx in [-0.20, 0.20]:
			for rz in [-0.20, 0.20]:
				add_cylinder(root, 0.018, 0.018, 0.10, Vector3(rx * 0.7, 0.37, rz * 0.7), dark_prop_mat, 8, Vector3(0, 0, 45 if rx > 0 else -45))
				add_cylinder(root, 0.065, 0.065, 0.02, Vector3(rx, 0.40, rz), dark_prop_mat, 10)
		# Downward scanning light
		add_night_lamp(root, Vector3(0, 0.26, 0), Color(0.35, 0.85, 1.0), 2.5, 0.85)

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
