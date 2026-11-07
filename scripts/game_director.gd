class_name GameDirector
extends Node3D

@export var left_entrance_coords: Vector2i = Vector2i(-9, 0)
@export var right_entrance_coords: Vector2i = Vector2i(9, 0)
@export var base_spawn_interval: float = 9.0
@export var day_duration_seconds: float = 60.0
@export var peep_scene: PackedScene = preload("res://scenes/peep.tscn")

@onready var camera_rig: CameraRig = $CameraPivot
@onready var day_night_cycle: DayNightCycle = $DayNightCycle
@onready var grid_manager: GridManager = $MapGrid
@onready var peeps_container: Node3D = $Peeps

var staff_container: Node3D
var popups_container: Node3D

# HUD & Menus
@onready var start_menu_panel: Control = $HUD/StartMenuPanel
@onready var location_select_panel: Control = $HUD/LocationSelectPanel
@onready var options_panel: Control = $HUD/OptionsPanel
@onready var top_bar: Control = $HUD/TopBar
@onready var bottom_dock: Control = $HUD/BottomDock
@onready var draft_modal: Control = $HUD/DraftModal
@onready var game_over_panel: Control = $HUD/GameOverPanel

# Location Select Widgets
@onready var loc_cards_box: HBoxContainer = $HUD/LocationSelectPanel/Panel/VBox/LocCardsHBox

# Top Bar Widgets
@onready var budget_label: Label = $HUD/TopBar/LeftCard/HBox/BudgetLabel
@onready var happiness_label: Label = $HUD/TopBar/LeftCard/HBox/HappinessLabel
@onready var happiness_bar: ProgressBar = $HUD/TopBar/LeftCard/HBox/HappinessBar
@onready var reputation_label: Label = $HUD/TopBar/LeftCard/HBox/ReputationLabel
@onready var rate_label: Label = $HUD/TopBar/LeftCard/HBox/RateLabel

@onready var day_label: Label = $HUD/TopBar/RightCard/HBox/DayLabel
@onready var phase_label: Label = $HUD/TopBar/RightCard/HBox/PhaseLabel
@onready var btn_pause: Button = $HUD/TopBar/RightCard/HBox/SpeedBox/BtnPause
@onready var btn_1x: Button = $HUD/TopBar/RightCard/HBox/SpeedBox/Btn1x
@onready var btn_15x: Button = $HUD/TopBar/RightCard/HBox/SpeedBox/Btn15x
@onready var btn_2x: Button = $HUD/TopBar/RightCard/HBox/SpeedBox/Btn2x

# Bottom Build Dock Widgets
@onready var category_tabs_box: HBoxContainer = $HUD/BottomDock/VBox/CategoryTabsHBox
@onready var tools_hbox: HBoxContainer = $HUD/BottomDock/VBox/ToolsHBox
@onready var hint_label: Label = $HUD/BottomDock/VBox/HintLabel

# Draft Modal Widgets
@onready var draft_title_label: Label = $HUD/DraftModal/Panel/VBox/DraftTitleLabel
@onready var draft_cards_box: HBoxContainer = $HUD/DraftModal/Panel/VBox/CardsHBox

# Game Over Widgets
@onready var final_score_label: Label = $HUD/GameOverPanel/Panel/VBox/FinalScoreLabel

# Options Widgets
@onready var opt_topdown_check: CheckButton = $HUD/OptionsPanel/Panel/VBox/TopDownCheck
@onready var opt_daynight_check: CheckButton = $HUD/OptionsPanel/Panel/VBox/DayNightCheck
@onready var opt_brightness_slider: HSlider = $HUD/OptionsPanel/Panel/VBox/BrightnessBox/BrightnessSlider
@onready var opt_brightness_value: Label = $HUD/OptionsPanel/Panel/VBox/BrightnessBox/BrightnessValue
@onready var opt_panspeed_slider: HSlider = $HUD/OptionsPanel/Panel/VBox/PanSpeedBox/PanSpeedSlider

const DAY_NAMES: Array[String] = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

var locations_list: Array[Dictionary] = []
var selected_location_index: int = 0
var location_card_buttons: Array[Button] = []
var location_card_styles: Array[Dictionary] = []

# 2.5D Floating Balatro-Style Menu & Mini Metro Card Animation State
var menu_anim_time: float = 0.0
var title_floating_card: PanelContainer = null
var title_wave_letters: Array[Dictionary] = []
var floating_menu_cards: Array[Dictionary] = []
var floating_location_cards: Array[Dictionary] = []

var selected_category: int = -1 # -1 = No category expanded yet; 0..5 = FacilityCatalog.Category
var category_buttons: Dictionary = {} # int -> Button
var item_buttons: Dictionary = {} # int -> Button
var staff_buttons: Dictionary = {} # int -> Button
var deselect_tool_button: Button = null

var is_in_match: bool = false
var is_game_over: bool = false
var is_drafting: bool = false
var sim_speed: float = 0.0
var last_unpaused_speed: float = 1.0

var happiness: float = 100.0
var reputation: float = 1.0
var peak_reputation: float = 1.0
var satisfied_patrons: int = 0
var daily_service_income: int = 0
var service_income_multiplier: float = 1.0
var staff_wage_multiplier: float = 1.0
var city_grant_multiplier: float = 1.0
var trash_drop_multiplier: float = 1.0
var comfort_service_speed_mult: float = 1.0
var dining_income_mult: float = 1.0
var queue_patience_mult: float = 1.0
var last_ledger_summary: String = ""

# Plaza Direction & Archetype Spawn Weights (Modified by Wednesday Facility Upgrades)
var unlocked_special_facilities: Dictionary = {} # ItemId -> bool
var archetype_weights: Dictionary = {
	PeepAgent.Archetype.NORMAL: 42.0,
	PeepAgent.Archetype.ELDER: 16.0,
	PeepAgent.Archetype.BUSINESS: 16.0,
	PeepAgent.Archetype.COUPLE: 13.0,
	PeepAgent.Archetype.CHILD: 13.0
}

# End-of-Day Settlement Announcement Card Widgets & Animation State
var settlement_card: PanelContainer = null
var settlement_title_label: Label = null
var settlement_ratings_label: Label = null
var settlement_ledger_label: Label = null
var settlement_net_pill: PanelContainer = null
var settlement_net_label: Label = null
var settlement_card_timer: float = 0.0
var settlement_card_base_y: float = 78.0
var settlement_tween: Tween = null

var week_number: int = 1
var day_index: int = 0 # 0 = MON .. 6 = SUN
var day_timer: float = 0.0
var spawn_timer: float = 0.0
var station_burst_timer: float = 0.0
var aura_tick_timer: float = 0.0
var current_need_weights: Array = [1.0, 1.0, 1.0, 1.0]

# Daily statistics for end-of-day Happiness and Reputation calculation
var day_patrons_served: int = 0
var day_patrons_happy_exit: int = 0
var day_patrons_frustrated_exit: int = 0
var day_lost_guided: int = 0
var day_trash_cleaned: int = 0
var day_stalls_overloaded: int = 0

var registered_stalls: Array[StallController] = []
var active_staff: Array[StaffAgent] = []
var draft_choices: Array[Dictionary] = []
var floating_popups: Array[Dictionary] = []

func _ready() -> void:
	staff_container = Node3D.new()
	staff_container.name = "StaffContainer"
	add_child(staff_container)

	popups_container = Node3D.new()
	popups_container.name = "PopupsContainer"
	add_child(popups_container)

	locations_list = LocationCatalog.get_locations()
	_setup_cozy_ui_theme()
	_build_start_menu_25d_ui()
	_build_settlement_announcement_ui()
	_build_categorized_dock_ui()
	_disable_hud_button_focus()
	_populate_location_cards()

	grid_manager.budget_changed.connect(_on_budget_changed)
	grid_manager.inventory_changed.connect(_update_dock_ui)
	grid_manager.facility_placed.connect(_on_facility_placed)
	grid_manager.facility_removed.connect(_on_facility_removed)
	grid_manager.path_network.network_changed.connect(_recalculate_all_peep_routes)

	if happiness_bar:
		happiness_bar.visible = false
	if rate_label:
		rate_label.visible = false
	if hint_label:
		hint_label.visible = false

	day_night_cycle.set_brightness(0.85)
	day_night_cycle.update_time_of_day(0.15)
	_set_sim_speed(0.0)
	_show_start_menu(true)

func _build_categorized_dock_ui() -> void:
	if not category_tabs_box or not tools_hbox:
		return
	for child in category_tabs_box.get_children():
		child.queue_free()
	for child in tools_hbox.get_children():
		child.queue_free()

	category_buttons.clear()
	item_buttons.clear()
	staff_buttons.clear()

	# Minimal category bar (removed "All")
	var categories_meta: Array[Dictionary] = [
		{"id": FacilityCatalog.Category.PATH, "label": "Path"},
		{"id": FacilityCatalog.Category.DINING, "label": "Dining"},
		{"id": FacilityCatalog.Category.SERVICE, "label": "Service"},
		{"id": FacilityCatalog.Category.COMFORT, "label": "Comfort"},
		{"id": FacilityCatalog.Category.UTILITY, "label": "Utility"},
		{"id": FacilityCatalog.Category.STAFF, "label": "Staff"}
	]

	for cat in categories_meta:
		var cid: int = int(cat["id"])
		var cbtn := Button.new()
		cbtn.custom_minimum_size = Vector2(96, 32)
		cbtn.focus_mode = Control.FOCUS_NONE
		cbtn.text = str(cat["label"])
		cbtn.pressed.connect(func() -> void: _select_dock_category(cid))
		category_tabs_box.add_child(cbtn)
		category_buttons[cid] = cbtn

	var build_order: Array[int] = [
		FacilityCatalog.ItemId.PATH_TILE,
		FacilityCatalog.ItemId.FENCE,
		FacilityCatalog.ItemId.ENTRY_GATE,
		FacilityCatalog.ItemId.EXIT_GATE,
		FacilityCatalog.ItemId.FOOD_SHOP,
		FacilityCatalog.ItemId.DRINK_STALL,
		FacilityCatalog.ItemId.COFFEE_ROASTER,
		FacilityCatalog.ItemId.RESTROOM,
		FacilityCatalog.ItemId.INFO_KIOSK,
		FacilityCatalog.ItemId.STREET_STAGE,
		FacilityCatalog.ItemId.PICNIC_TABLE,
		FacilityCatalog.ItemId.BENCH,
		FacilityCatalog.ItemId.FLOWER_GARDEN,
		FacilityCatalog.ItemId.DUCK_POND,
		FacilityCatalog.ItemId.TRASHCAN,
		FacilityCatalog.ItemId.LAMP_POST,
		FacilityCatalog.ItemId.ERASE_TOOL
	]

	for item_id in build_order:
		var info := FacilityCatalog.get_item(item_id)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(108, 42)
		btn.focus_mode = Control.FOCUS_NONE
		var iid := item_id
		btn.pressed.connect(func() -> void: _select_build_tool(iid))
		tools_hbox.add_child(btn)
		item_buttons[item_id] = btn

	for staff_id in [FacilityCatalog.StaffId.JANITOR, FacilityCatalog.StaffId.PLAZA_STAFF, FacilityCatalog.StaffId.SECURITY]:
		var sid: int = int(staff_id)
		var sbtn := Button.new()
		sbtn.custom_minimum_size = Vector2(124, 42)
		sbtn.focus_mode = Control.FOCUS_NONE
		sbtn.pressed.connect(func() -> void: hire_staff(sid))
		tools_hbox.add_child(sbtn)
		staff_buttons[sid] = sbtn

	deselect_tool_button = Button.new()
	deselect_tool_button.text = "✕ Done"
	deselect_tool_button.custom_minimum_size = Vector2(92, 42)
	deselect_tool_button.focus_mode = Control.FOCUS_NONE
	deselect_tool_button.modulate = Color(1.0, 0.72, 0.72)
	deselect_tool_button.pressed.connect(func() -> void: _select_build_tool(-1))
	tools_hbox.add_child(deselect_tool_button)

	_select_dock_category(-1)

func _select_dock_category(cat_id: int) -> void:
	if cat_id >= 0 and selected_category == cat_id:
		# Clicking the active category again collapses it and unselects facility
		selected_category = -1
		grid_manager.set_build_tool(-1)
	else:
		selected_category = cat_id
	for cid in category_buttons.keys():
		var btn: Button = category_buttons[cid]
		btn.modulate = Color(1.0, 0.90, 0.55) if cid == selected_category else Color(0.88, 0.90, 0.94)
	if tools_hbox:
		tools_hbox.visible = (selected_category >= 0)
	_update_dock_ui()

func _update_bottom_dock_hover() -> void:
	if not bottom_dock:
		return
	if not is_in_match or is_game_over or is_drafting or options_panel.visible:
		bottom_dock.visible = false
		return

	# When player has selected a facility to place, the menu stays appeared until unselected!
	var has_selected_tool := (grid_manager.current_tool >= 0)
	if has_selected_tool:
		bottom_dock.visible = true
		return

	var vp_rect := get_viewport().get_visible_rect()
	var mouse_pos := get_viewport().get_mouse_position()
	var dist_from_bottom := vp_rect.size.y - mouse_pos.y

	if not bottom_dock.visible:
		# Hidden by default: appear when mouse moves down to the bottom edge
		if dist_from_bottom >= 0.0 and dist_from_bottom <= 78.0:
			bottom_dock.visible = true
	else:
		# Keep visible while mouse stays in the bottom dock area; hide when mouse moves away
		var keep_height := 158.0 if selected_category >= 0 else 96.0
		var dock_rect := bottom_dock.get_global_rect().grow(24.0)
		if dist_from_bottom > keep_height and not dock_rect.has_point(mouse_pos):
			bottom_dock.visible = false
			_select_dock_category(-1)

func _create_styled_logo_font(embolden: float = 0.52, slant: float = 0.14) -> FontVariation:
	var sys_font := SystemFont.new()
	sys_font.font_names = PackedStringArray([
		"Arial Rounded MT Bold",
		"Segoe UI Black",
		"Arial Black",
		"Trebuchet MS",
		"Impact"
	])
	sys_font.font_weight = 900
	sys_font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY

	var fv := FontVariation.new()
	fv.base_font = sys_font
	fv.variation_embolden = embolden
	if not is_zero_approx(slant):
		fv.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-slant, 1.0), Vector2.ZERO)
	return fv

func _build_start_menu_25d_ui() -> void:
	var menu_root := get_node_or_null("HUD/StartMenuPanel/Panel/VBox") as Control
	if not menu_root:
		return

	floating_menu_cards.clear()
	title_wave_letters.clear()

	var logo_font_main := _create_styled_logo_font(0.55, 0.14)
	var btn_logo_font := _create_styled_logo_font(0.32, 0.06)

	# 1. Build 2.5D Floating Logo Card — JUST "PLAZA FLOW" as a Styled 3D Extruded Logo (no detail text)
	title_floating_card = PanelContainer.new()
	title_floating_card.name = "TitleEmblemCard"
	var title_card_size := Vector2(416, 128)
	title_floating_card.custom_minimum_size = title_card_size
	title_floating_card.size = title_card_size
	title_floating_card.position = Vector2(8, 24)
	title_floating_card.pivot_offset = title_card_size * 0.5
	title_floating_card.mouse_filter = Control.MOUSE_FILTER_PASS

	var title_style := StyleBoxFlat.new()
	title_style.bg_color = Color("1d2432")
	title_style.border_color = Color("f5cc70")
	title_style.border_width_left = 4
	title_style.border_width_top = 4
	title_style.border_width_right = 4
	title_style.border_width_bottom = 10
	title_style.set_corner_radius_all(22)
	title_style.shadow_color = Color(0.03, 0.04, 0.07, 0.55)
	title_style.shadow_size = 20
	title_style.shadow_offset = Vector2(6, 13)
	title_style.content_margin_left = 18
	title_style.content_margin_right = 18
	title_style.content_margin_top = 14
	title_style.content_margin_bottom = 18
	title_floating_card.add_theme_stylebox_override("panel", title_style)

	var center_box := CenterContainer.new()
	center_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_floating_card.add_child(center_box)

	# Styled 3D-extruded logo glyphs for "PLAZA FLOW" (ONLY PLAZA FLOW in the card!)
	var letters_hbox := HBoxContainer.new()
	letters_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	letters_hbox.add_theme_constant_override("separation", 2)
	letters_hbox.custom_minimum_size = Vector2(0, 78)
	letters_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_box.add_child(letters_hbox)

	var title_str := "PLAZA FLOW"
	for i in range(title_str.length()):
		var ch := title_str.substr(i, 1)
		var is_second_word := (i >= 6)
		var slot := Control.new()
		var slot_w := 16.0 if ch == " " else (38.0 if ch == "W" or ch == "M" else 34.0)
		slot.custom_minimum_size = Vector2(slot_w, 78)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		letters_hbox.add_child(slot)

		if ch != " ":
			var char_pivot := Control.new()
			char_pivot.size = Vector2(slot_w, 78)
			char_pivot.pivot_offset = Vector2(slot_w * 0.5, 39.0)
			char_pivot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(char_pivot)

			var face_col := Color("7fe8cf") if is_second_word else Color("fff4d4")
			var bevel_col := Color("2b8778") if is_second_word else Color("d96548")
			var extrude_col := Color("111622")

			# Layer 1: Deep 3D Extruded Block Shadow
			var shadow_lbl := Label.new()
			shadow_lbl.text = ch
			shadow_lbl.size = Vector2(slot_w, 78)
			shadow_lbl.position = Vector2(2, 7)
			shadow_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			shadow_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			shadow_lbl.add_theme_font_override("font", logo_font_main)
			shadow_lbl.add_theme_font_size_override("font_size", 46)
			shadow_lbl.add_theme_color_override("font_color", extrude_col)
			shadow_lbl.add_theme_color_override("font_outline_color", extrude_col)
			shadow_lbl.add_theme_constant_override("outline_size", 12)
			shadow_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			char_pivot.add_child(shadow_lbl)

			# Layer 2: Colored 3D Bevel Lip
			var bevel_lbl := Label.new()
			bevel_lbl.text = ch
			bevel_lbl.size = Vector2(slot_w, 78)
			bevel_lbl.position = Vector2(1, 4)
			bevel_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bevel_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			bevel_lbl.add_theme_font_override("font", logo_font_main)
			bevel_lbl.add_theme_font_size_override("font_size", 46)
			bevel_lbl.add_theme_color_override("font_color", bevel_col)
			bevel_lbl.add_theme_color_override("font_outline_color", extrude_col)
			bevel_lbl.add_theme_constant_override("outline_size", 10)
			bevel_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			char_pivot.add_child(bevel_lbl)

			# Layer 3: Main Embossed Logo Letter Face
			var face_lbl := Label.new()
			face_lbl.text = ch
			face_lbl.size = Vector2(slot_w, 78)
			face_lbl.position = Vector2(0, 0)
			face_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			face_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			face_lbl.add_theme_font_override("font", logo_font_main)
			face_lbl.add_theme_font_size_override("font_size", 46)
			face_lbl.add_theme_color_override("font_color", face_col)
			face_lbl.add_theme_color_override("font_outline_color", Color("161c29"))
			face_lbl.add_theme_constant_override("outline_size", 8)
			face_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			char_pivot.add_child(face_lbl)

			title_wave_letters.append({
				"node": char_pivot,
				"index": i
			})

	menu_root.add_child(title_floating_card)

	# 2. Style the 3 Menu Action Buttons as Clean 2.5D Floating Cards (no extra subtitle details)
	var btn_configs: Array[Dictionary] = [
		{
			"path": "PlayButton",
			"title": "▶  PLAY",
			"bg": Color("d96548"),
			"border": Color("ffe3a8"),
			"pos": Vector2(22, 182),
			"size": Vector2(320, 68),
			"base_rot": -0.020,
			"phase": 0.4
		},
		{
			"path": "OptionsButton",
			"title": "⚙  OPTIONS",
			"bg": Color("3b7ea1"),
			"border": Color("c7ecff"),
			"pos": Vector2(36, 268),
			"size": Vector2(298, 62),
			"base_rot": 0.016,
			"phase": 1.9
		},
		{
			"path": "QuitButton",
			"title": "✕  QUIT GAME",
			"bg": Color("524866"),
			"border": Color("e0cee8"),
			"pos": Vector2(50, 348),
			"size": Vector2(276, 58),
			"base_rot": -0.014,
			"phase": 3.3
		}
	]

	for cfg in btn_configs:
		var btn := menu_root.get_node_or_null(str(cfg["path"])) as Button
		if not btn:
			continue
		btn.text = ""
		btn.focus_mode = Control.FOCUS_NONE
		var csize: Vector2 = cfg["size"]
		btn.custom_minimum_size = csize
		btn.size = csize
		btn.position = cfg["pos"]
		btn.pivot_offset = csize * 0.5

		for ch in btn.get_children():
			ch.queue_free()

		var normal_sb := _make_25d_card_stylebox(cfg["bg"], cfg["border"], 7, 14, Vector2(5, 10))
		var hover_sb := _make_25d_card_stylebox((cfg["bg"] as Color).lightened(0.12), Color("fff4c2"), 9, 20, Vector2(8, 15))
		var pressed_sb := _make_25d_card_stylebox((cfg["bg"] as Color).darkened(0.08), cfg["border"], 4, 8, Vector2(2, 5))
		btn.add_theme_stylebox_override("normal", normal_sb)
		btn.add_theme_stylebox_override("hover", hover_sb)
		btn.add_theme_stylebox_override("pressed", pressed_sb)
		btn.add_theme_stylebox_override("focus", hover_sb)

		var inner := CenterContainer.new()
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(inner)

		var main_lbl := Label.new()
		main_lbl.text = str(cfg["title"])
		main_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		main_lbl.add_theme_font_override("font", btn_logo_font)
		main_lbl.add_theme_font_size_override("font_size", 22)
		main_lbl.add_theme_color_override("font_color", Color("fffaf0"))
		main_lbl.add_theme_color_override("font_outline_color", Color("161922"))
		main_lbl.add_theme_constant_override("outline_size", 6)
		main_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(main_lbl)

		floating_menu_cards.append({
			"node": btn,
			"base_pos": cfg["pos"],
			"base_rot": float(cfg["base_rot"]),
			"phase": float(cfg["phase"]),
			"cur_scale": 1.0,
			"cur_rot": float(cfg["base_rot"]),
			"cur_offset": Vector2.ZERO
		})

func _make_25d_card_stylebox(bg: Color, border: Color, bottom_lip: int, shadow_sz: int, shadow_off: Vector2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = bottom_lip
	sb.set_corner_radius_all(16)
	sb.shadow_color = Color(0.03, 0.04, 0.07, 0.48)
	sb.shadow_size = shadow_sz
	sb.shadow_offset = shadow_off
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 10
	return sb

func _populate_location_cards() -> void:
	if not loc_cards_box:
		return
	for child in loc_cards_box.get_children():
		child.queue_free()
	location_card_buttons.clear()
	location_card_styles.clear()
	floating_location_cards.clear()

	# Style Mini Metro-inspired Location Cards:
	# Main Information: Location Name + Map Size
	# Secondary Information: Budget + Short Description (no long text)
	var card_size := Vector2(236, 212)

	for i in range(locations_list.size()):
		var loc: Dictionary = locations_list[i]
		var loc_name: String = str(loc.get("name", "Plaza"))
		var size_lbl: String = str(loc.get("map_size_label", "Standard"))
		var start_b := FacilityCatalog.format_money(int(loc.get("starting_budget", 200000)))
		var short_desc: String = str(loc.get("short_desc", "Cozy urban plaza."))
		var accent_col: Color = loc.get("accent_color", Color("d96b4f"))

		var slot := Control.new()
		slot.custom_minimum_size = card_size
		slot.mouse_filter = Control.MOUSE_FILTER_PASS
		loc_cards_box.add_child(slot)

		var btn := Button.new()
		btn.custom_minimum_size = card_size
		btn.size = card_size
		btn.pivot_offset = card_size * 0.5
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = ""
		var idx := i
		btn.pressed.connect(func() -> void: _select_location_preview(idx))
		slot.add_child(btn)

		var normal_sb := _make_25d_card_stylebox(Color("f5efe4"), accent_col.darkened(0.15), 7, 14, Vector2(4, 9))
		var selected_sb := _make_25d_card_stylebox(Color("fffaf0"), Color("f5b942"), 9, 20, Vector2(6, 14))
		var hover_sb := _make_25d_card_stylebox(Color("fffdf8"), accent_col.lightened(0.15), 8, 18, Vector2(5, 12))
		btn.add_theme_stylebox_override("normal", normal_sb)
		btn.add_theme_stylebox_override("hover", hover_sb)
		btn.add_theme_stylebox_override("pressed", selected_sb)
		btn.add_theme_stylebox_override("focus", selected_sb)

		location_card_styles.append({
			"normal": normal_sb,
			"selected": selected_sb,
			"hover": hover_sb,
			"accent": accent_col
		})

		# Top colored Mini Metro transit line header bar
		var header_bar := ColorRect.new()
		header_bar.color = accent_col
		header_bar.custom_minimum_size = Vector2(0, 12)
		header_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var card_vbox := VBoxContainer.new()
		card_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card_vbox.offset_left = 14
		card_vbox.offset_right = -14
		card_vbox.offset_top = 12
		card_vbox.offset_bottom = -12
		card_vbox.add_theme_constant_override("separation", 7)
		card_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(card_vbox)
		card_vbox.add_child(header_bar)

		# MAIN INFO 1: Location Name (Large, Bold)
		var name_lbl := Label.new()
		name_lbl.name = "CardNameLabel"
		name_lbl.text = loc_name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.add_theme_font_size_override("font_size", 20)
		name_lbl.add_theme_color_override("font_color", Color("1f242d"))
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_child(name_lbl)

		# MAIN INFO 2: Map Size Pill Badge (Prominent Main Info)
		var size_pill := PanelContainer.new()
		size_pill.name = "CardSizePill"
		size_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		size_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pill_sb := StyleBoxFlat.new()
		pill_sb.bg_color = accent_col
		pill_sb.set_corner_radius_all(10)
		pill_sb.content_margin_left = 12
		pill_sb.content_margin_right = 12
		pill_sb.content_margin_top = 3
		pill_sb.content_margin_bottom = 3
		size_pill.add_theme_stylebox_override("panel", pill_sb)

		var size_lbl_node := Label.new()
		size_lbl_node.name = "CardSizeLabel"
		size_lbl_node.text = "SIZE: %s" % size_lbl.to_upper()
		size_lbl_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		size_lbl_node.add_theme_font_size_override("font_size", 14)
		size_lbl_node.add_theme_color_override("font_color", Color("fffdf9"))
		size_lbl_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_pill.add_child(size_lbl_node)
		card_vbox.add_child(size_pill)

		# Divider line
		var div := ColorRect.new()
		div.color = Color(0.20, 0.23, 0.28, 0.18)
		div.custom_minimum_size = Vector2(0, 2)
		div.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_child(div)

		# SECONDARY INFO 1: Starting Budget
		var budget_lbl_node := Label.new()
		budget_lbl_node.name = "CardBudgetLabel"
		budget_lbl_node.text = "💰 Budget: %s" % start_b
		budget_lbl_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		budget_lbl_node.add_theme_font_size_override("font_size", 15)
		budget_lbl_node.add_theme_color_override("font_color", Color("2b6e46"))
		budget_lbl_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_child(budget_lbl_node)

		# SECONDARY INFO 2: Short Description (No long text)
		var desc_lbl_node := Label.new()
		desc_lbl_node.name = "CardShortDescLabel"
		desc_lbl_node.text = short_desc
		desc_lbl_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl_node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl_node.add_theme_font_size_override("font_size", 13)
		desc_lbl_node.add_theme_color_override("font_color", Color("4a5260"))
		desc_lbl_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_child(desc_lbl_node)

		location_card_buttons.append(btn)
		floating_location_cards.append({
			"node": btn,
			"index": i,
			"phase": float(i) * 1.15,
			"cur_scale": 1.0,
			"cur_rot": 0.0,
			"cur_y": 0.0
		})

	# Style Back & Start Plaza buttons as tactile floating pills
	var back_btn := get_node_or_null("HUD/LocationSelectPanel/Panel/VBox/ActionsHBox/BackToTitleBtn") as Button
	if back_btn:
		back_btn.focus_mode = Control.FOCUS_NONE
		back_btn.add_theme_stylebox_override("normal", _make_25d_card_stylebox(Color("3b4254"), Color("d0d7e6"), 5, 10, Vector2(3, 6)))
		back_btn.add_theme_stylebox_override("hover", _make_25d_card_stylebox(Color("4c556b"), Color("ffffff"), 6, 14, Vector2(4, 8)))

	var start_btn := get_node_or_null("HUD/LocationSelectPanel/Panel/VBox/ActionsHBox/StartLocationBtn") as Button
	if start_btn:
		start_btn.focus_mode = Control.FOCUS_NONE
		start_btn.add_theme_stylebox_override("normal", _make_25d_card_stylebox(Color("d96548"), Color("ffe3a8"), 6, 12, Vector2(4, 8)))
		start_btn.add_theme_stylebox_override("hover", _make_25d_card_stylebox(Color("eb7759"), Color("fff6d6"), 7, 16, Vector2(5, 10)))

func _select_location_preview(index: int) -> void:
	if index < 0 or index >= locations_list.size():
		return
	selected_location_index = index
	var loc: Dictionary = locations_list[selected_location_index]

	_clear_all_peeps()
	_clear_all_staff()
	registered_stalls.clear()
	grid_manager.apply_location_scenario(loc)
	left_entrance_coords = Vector2i(-grid_manager.grid_half_width, 0)
	right_entrance_coords = Vector2i(grid_manager.grid_half_width, 0)
	camera_rig.configure_for_map_size(grid_manager.grid_half_width, grid_manager.grid_half_height)
	day_night_cycle.update_time_of_day(float(loc.get("start_time", 0.08)))

	for i in range(location_card_buttons.size()):
		var b := location_card_buttons[i]
		var st: Dictionary = location_card_styles[i]
		if i == selected_location_index:
			b.add_theme_stylebox_override("normal", st["selected"])
			b.modulate = Color(1.0, 1.0, 1.0)
		else:
			b.add_theme_stylebox_override("normal", st["normal"])
			b.modulate = Color(0.94, 0.94, 0.96)

func _update_floating_menu_cards(delta: float) -> void:
	menu_anim_time += delta
	var mouse_pos := get_viewport().get_mouse_position()

	# 1. Animate 2.5D Balatro-Style Start Menu Cards & Waving Title Letters
	if start_menu_panel and start_menu_panel.visible:
		if is_instance_valid(title_floating_card):
			title_floating_card.pivot_offset = title_floating_card.size * 0.5
			var t_rect := title_floating_card.get_global_rect()
			var t_hover := t_rect.has_point(mouse_pos)
			var target_rot := sin(menu_anim_time * 1.35) * 0.022
			var target_scale := 1.0
			if t_hover:
				var rel_x := clampf((mouse_pos.x - t_rect.get_center().x) / (t_rect.size.x * 0.5), -1.0, 1.0)
				target_rot += rel_x * 0.045
				target_scale = 1.035
			title_floating_card.position = Vector2(
				8.0 + cos(menu_anim_time * 1.1) * 3.5,
				12.0 + sin(menu_anim_time * 1.7) * 5.5
			)
			title_floating_card.rotation = lerpf(title_floating_card.rotation, target_rot, clampf(delta * 10.0, 0.0, 1.0))
			var sc := lerpf(title_floating_card.scale.x, target_scale, clampf(delta * 10.0, 0.0, 1.0))
			title_floating_card.scale = Vector2(sc, sc)

		for item in title_wave_letters:
			var l_node: Control = item["node"]
			if not is_instance_valid(l_node):
				continue
			var idx: int = int(item["index"])
			var wave_t := menu_anim_time * 3.4 - float(idx) * 0.45
			l_node.position.y = sin(wave_t) * 4.5
			l_node.rotation = cos(wave_t) * 0.055

		for card in floating_menu_cards:
			var btn: Button = card["node"]
			if not is_instance_valid(btn):
				continue
			btn.pivot_offset = btn.size * 0.5
			var base_pos: Vector2 = card["base_pos"]
			var base_rot: float = float(card["base_rot"])
			var ph: float = float(card["phase"])

			var idle_y := sin(menu_anim_time * 2.1 + ph) * 4.5
			var idle_x := cos(menu_anim_time * 1.4 + ph) * 2.5
			var idle_rot := base_rot + sin(menu_anim_time * 1.6 + ph) * 0.024

			var g_rect := btn.get_global_rect()
			var is_hovered := g_rect.has_point(mouse_pos)
			var target_scale := 1.08 if is_hovered else 1.0
			var target_offset := Vector2(12.0, -6.0) if is_hovered else Vector2.ZERO
			var target_rot := idle_rot
			if is_hovered:
				var rel_x := clampf((mouse_pos.x - g_rect.get_center().x) / (g_rect.size.x * 0.5), -1.0, 1.0)
				target_rot = rel_x * 0.065

			var cur_scale := lerpf(float(card["cur_scale"]), target_scale, clampf(delta * 12.0, 0.0, 1.0))
			var cur_rot := lerpf(float(card["cur_rot"]), target_rot, clampf(delta * 12.0, 0.0, 1.0))
			var cur_offset: Vector2 = (card["cur_offset"] as Vector2).lerp(target_offset, clampf(delta * 12.0, 0.0, 1.0))

			card["cur_scale"] = cur_scale
			card["cur_rot"] = cur_rot
			card["cur_offset"] = cur_offset

			btn.position = base_pos + Vector2(idle_x, idle_y) + cur_offset
			btn.rotation = cur_rot
			btn.scale = Vector2(cur_scale, cur_scale)

	# 2. Animate Mini Metro-Style Location Cards in 2.5D
	if location_select_panel and location_select_panel.visible:
		for lcard in floating_location_cards:
			var btn: Button = lcard["node"]
			if not is_instance_valid(btn):
				continue
			btn.pivot_offset = btn.size * 0.5
			var idx: int = int(lcard["index"])
			var ph: float = float(lcard["phase"])
			var is_sel := (idx == selected_location_index)
			var g_rect := btn.get_global_rect()
			var is_hov := g_rect.has_point(mouse_pos)

			var idle_bob := sin(menu_anim_time * 2.0 + ph) * 3.5
			var target_y := idle_bob + (-14.0 if is_sel else (-8.0 if is_hov else 0.0))
			var target_scale := 1.06 if (is_sel or is_hov) else 1.0
			var target_rot := sin(menu_anim_time * 1.4 + ph) * 0.015
			if is_hov:
				var rel_x := clampf((mouse_pos.x - g_rect.get_center().x) / (g_rect.size.x * 0.5), -1.0, 1.0)
				target_rot = rel_x * 0.055

			var cur_y := lerpf(float(lcard["cur_y"]), target_y, clampf(delta * 12.0, 0.0, 1.0))
			var cur_scale := lerpf(float(lcard["cur_scale"]), target_scale, clampf(delta * 12.0, 0.0, 1.0))
			var cur_rot := lerpf(float(lcard["cur_rot"]), target_rot, clampf(delta * 12.0, 0.0, 1.0))

			lcard["cur_y"] = cur_y
			lcard["cur_scale"] = cur_scale
			lcard["cur_rot"] = cur_rot

			btn.position = Vector2(0.0, cur_y)
			btn.rotation = cur_rot
			btn.scale = Vector2(cur_scale, cur_scale)

func _disable_hud_button_focus() -> void:
	for btn in [
		btn_pause, btn_1x, btn_15x, btn_2x,
		$HUD/TopBar/RightCard/HBox/BtnOptions,
		$HUD/TopBar/RightCard/HBox/BtnMenu
	]:
		if btn and btn is Control:
			(btn as Control).focus_mode = Control.FOCUS_NONE

func _unhandled_key_input(event: InputEvent) -> void:
	if not is_in_match or is_game_over or is_drafting or options_panel.visible:
		return

	if event is InputEventKey:
		var ke := event as InputEventKey
		if not ke.pressed or ke.echo:
			return

		if ke.keycode == KEY_SPACE:
			if is_zero_approx(sim_speed):
				_set_sim_speed(last_unpaused_speed if last_unpaused_speed > 0.0 else 1.0)
			else:
				_set_sim_speed(0.0)
			get_viewport().set_input_as_handled()
		elif ke.keycode == KEY_1 or ke.keycode == KEY_KP_1:
			_set_sim_speed(1.0)
			get_viewport().set_input_as_handled()
		elif ke.keycode == KEY_2 or ke.keycode == KEY_KP_2:
			_set_sim_speed(1.5)
			get_viewport().set_input_as_handled()
		elif ke.keycode == KEY_3 or ke.keycode == KEY_KP_3:
			_set_sim_speed(2.0)
			get_viewport().set_input_as_handled()
		elif ke.keycode == KEY_ESCAPE:
			if grid_manager.current_tool >= 0 or selected_category >= 0:
				_select_build_tool(-1)
				_select_dock_category(-1)
				get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_update_floating_popups(delta)
	_update_floating_menu_cards(delta)
	_update_settlement_card_anim(delta)
	_update_bottom_dock_hover()

	if not is_in_match or is_game_over or is_drafting:
		return

	var sim_delta := delta * sim_speed
	if sim_delta <= 0.0:
		return

	day_timer += sim_delta
	if day_timer >= day_duration_seconds:
		day_timer -= day_duration_seconds
		_advance_day()

	var day_progress := clampf(day_timer / day_duration_seconds, 0.0, 1.0)
	day_night_cycle.update_time_of_day(day_progress)

	var current_interval := get_current_spawn_interval()
	spawn_timer += sim_delta
	if spawn_timer >= current_interval:
		spawn_timer -= current_interval
		_spawn_customer_set()

	var loc: Dictionary = locations_list[selected_location_index]
	var st_cfg: Dictionary = loc.get("station", {})
	if not st_cfg.is_empty():
		var burst_interval := float(st_cfg.get("burst_interval", 40.0))
		station_burst_timer += sim_delta
		if station_burst_timer >= burst_interval:
			station_burst_timer -= burst_interval
			var burst_count := int(st_cfg.get("burst_size", 4))
			var st_coords: Vector2i = st_cfg.get("coords", Vector2i(0, -9))
			for _b in range(burst_count):
				_spawn_peep_from_custom(st_coords, PeepAgent.Archetype.BUSINESS if randf() < 0.55 else PeepAgent.Archetype.NORMAL)

	aura_tick_timer += sim_delta
	if aura_tick_timer >= 0.45:
		aura_tick_timer = 0.0
		_process_plaza_auras_and_lost_events()

	_update_clock_ui()

func get_current_spawn_interval() -> float:
	var rep_factor := 1.0 + (reputation - 1.0) * 0.25
	var hap_factor := 0.60 + 0.40 * (happiness / 100.0)
	var interval := base_spawn_interval / (rep_factor * hap_factor)
	return clampf(interval, 2.5, base_spawn_interval)

func get_current_set_bounds() -> Vector2i:
	if reputation < 1.5:
		return Vector2i(1, 1)
	elif reputation < 2.5:
		return Vector2i(1, 2)
	elif reputation < 3.8:
		return Vector2i(1, 3)
	elif reputation < 5.0:
		return Vector2i(2, 4)
	else:
		return Vector2i(2, 5)

func _show_start_menu(instant: bool = false) -> void:
	is_in_match = false
	if get_tree():
		get_tree().set_meta("in_match", false)
	grid_manager.interaction_enabled = false
	_set_sim_speed(0.0)
	day_night_cycle.update_time_of_day(0.15)
	camera_rig.transition_to_title(instant)

	start_menu_panel.visible = true
	if location_select_panel:
		location_select_panel.visible = false
	if settlement_card:
		settlement_card.visible = false
	options_panel.visible = false
	draft_modal.visible = false
	game_over_panel.visible = false
	top_bar.visible = false
	bottom_dock.visible = false

func _show_location_select() -> void:
	is_in_match = false
	if get_tree():
		get_tree().set_meta("in_match", false)
	grid_manager.interaction_enabled = false
	_set_sim_speed(0.0)

	start_menu_panel.visible = false
	if location_select_panel:
		location_select_panel.visible = true
	if settlement_card:
		settlement_card.visible = false
	options_panel.visible = false
	draft_modal.visible = false
	game_over_panel.visible = false
	top_bar.visible = false
	bottom_dock.visible = false

	_select_location_preview(selected_location_index)
	camera_rig.transition_to_location_select(false)

func start_new_game() -> void:
	var loc: Dictionary = locations_list[selected_location_index]
	base_spawn_interval = float(loc.get("spawn_interval", 9.0))
	current_need_weights = loc.get("need_weights", [1.0, 1.0, 1.0, 1.0])

	_clear_all_peeps()
	_clear_all_staff()
	_clear_floating_popups()
	registered_stalls.clear()
	grid_manager.apply_location_scenario(loc)
	left_entrance_coords = Vector2i(-grid_manager.grid_half_width, 0)
	right_entrance_coords = Vector2i(grid_manager.grid_half_width, 0)
	camera_rig.configure_for_map_size(grid_manager.grid_half_width, grid_manager.grid_half_height)
	camera_rig.transition_to_gameplay(false)

	is_in_match = true
	if get_tree():
		get_tree().set_meta("in_match", true)
	is_game_over = false
	is_drafting = false

	happiness = 100.0
	reputation = 1.0
	peak_reputation = 1.0
	satisfied_patrons = 0
	daily_service_income = 0
	service_income_multiplier = 1.0
	staff_wage_multiplier = 1.0
	city_grant_multiplier = 1.0
	trash_drop_multiplier = 1.0
	comfort_service_speed_mult = 1.0
	dining_income_mult = 1.0
	queue_patience_mult = 1.0
	last_ledger_summary = ""

	unlocked_special_facilities.clear()
	archetype_weights = {
		PeepAgent.Archetype.NORMAL: 42.0,
		PeepAgent.Archetype.ELDER: 16.0,
		PeepAgent.Archetype.BUSINESS: 16.0,
		PeepAgent.Archetype.COUPLE: 13.0,
		PeepAgent.Archetype.CHILD: 13.0
	}
	if settlement_card:
		settlement_card.visible = false
		settlement_card_timer = 0.0

	day_patrons_served = 0
	day_patrons_happy_exit = 0
	day_patrons_frustrated_exit = 0
	day_lost_guided = 0
	day_trash_cleaned = 0
	day_stalls_overloaded = 0

	week_number = 1
	day_index = 0
	var start_progress := float(loc.get("start_time", 0.05))
	day_timer = start_progress * day_duration_seconds
	spawn_timer = 0.0
	station_burst_timer = 0.0

	start_menu_panel.visible = false
	if location_select_panel:
		location_select_panel.visible = false
	options_panel.visible = false
	draft_modal.visible = false
	game_over_panel.visible = false
	top_bar.visible = true
	# Bottom facility dock is hidden by default until mouse moves to the bottom
	bottom_dock.visible = false
	_select_dock_category(-1)

	grid_manager.interaction_enabled = true
	day_night_cycle.update_time_of_day(start_progress)
	_set_sim_speed(1.0)
	_select_build_tool(-1)
	_update_stats_ui()
	_update_clock_ui()
	_update_dock_ui()

func _clear_all_peeps() -> void:
	for child in peeps_container.get_children():
		child.queue_free()

func _clear_all_staff() -> void:
	active_staff.clear()
	for child in staff_container.get_children():
		child.queue_free()

func _clear_floating_popups() -> void:
	floating_popups.clear()
	for child in popups_container.get_children():
		child.queue_free()

func _build_settlement_announcement_ui() -> void:
	var hud_node := get_node_or_null("HUD") as CanvasLayer
	if not hud_node:
		return

	settlement_card = PanelContainer.new()
	settlement_card.name = "SettlementAnnouncementCard"
	settlement_card.visible = false
	settlement_card.z_index = 25
	var csize := Vector2(510, 158)
	settlement_card.custom_minimum_size = csize
	settlement_card.size = csize
	settlement_card.pivot_offset = csize * 0.5
	settlement_card.mouse_filter = Control.MOUSE_FILTER_STOP

	var sb := _make_25d_card_stylebox(Color("1f2634"), Color("f5cc70"), 9, 22, Vector2(6, 14))
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 12
	sb.content_margin_bottom = 14
	settlement_card.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settlement_card.add_child(vbox)

	var header_font := _create_styled_logo_font(0.35, 0.06)
	settlement_title_label = Label.new()
	settlement_title_label.name = "SettlementTitleLabel"
	settlement_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settlement_title_label.add_theme_font_override("font", header_font)
	settlement_title_label.add_theme_font_size_override("font_size", 22)
	settlement_title_label.add_theme_color_override("font_color", Color("fff4cf"))
	settlement_title_label.add_theme_color_override("font_outline_color", Color("121620"))
	settlement_title_label.add_theme_constant_override("outline_size", 5)
	settlement_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(settlement_title_label)

	settlement_ratings_label = Label.new()
	settlement_ratings_label.name = "SettlementRatingsLabel"
	settlement_ratings_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settlement_ratings_label.add_theme_font_size_override("font_size", 18)
	settlement_ratings_label.add_theme_color_override("font_color", Color("f7f2e8"))
	settlement_ratings_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(settlement_ratings_label)

	settlement_ledger_label = Label.new()
	settlement_ledger_label.name = "SettlementLedgerLabel"
	settlement_ledger_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settlement_ledger_label.add_theme_font_size_override("font_size", 16)
	settlement_ledger_label.add_theme_color_override("font_color", Color("d5e2f0"))
	settlement_ledger_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(settlement_ledger_label)

	settlement_net_pill = PanelContainer.new()
	settlement_net_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settlement_net_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill_sb := StyleBoxFlat.new()
	pill_sb.bg_color = Color("2d6e48")
	pill_sb.set_corner_radius_all(12)
	pill_sb.content_margin_left = 16
	pill_sb.content_margin_right = 16
	pill_sb.content_margin_top = 4
	pill_sb.content_margin_bottom = 4
	settlement_net_pill.add_theme_stylebox_override("panel", pill_sb)
	vbox.add_child(settlement_net_pill)

	settlement_net_label = Label.new()
	settlement_net_label.name = "SettlementNetLabel"
	settlement_net_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settlement_net_label.add_theme_font_size_override("font_size", 18)
	settlement_net_label.add_theme_color_override("font_color", Color("fffdf8"))
	settlement_net_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settlement_net_pill.add_child(settlement_net_label)

	# Allow clicking the announcement card to dismiss it early
	settlement_card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			settlement_card_timer = minf(settlement_card_timer, 0.25)
	)

	hud_node.add_child(settlement_card)

func _show_settlement_announcement_card(
	day_str: String,
	old_hap: float,
	new_hap: float,
	rep_delta: float,
	city_grant: int,
	service_inc: int,
	staff_wages: int,
	net_change: int
) -> void:
	if not is_instance_valid(settlement_card):
		return

	var hap_delta := roundi(new_hap) - roundi(old_hap)
	settlement_title_label.text = "☀ %s SETTLEMENT" % day_str
	settlement_ratings_label.text = "♥ Happiness: %d (%+d)     •     ★ Reputation: %.1f (%+.2f)" % [
		roundi(new_hap), hap_delta, reputation, rep_delta
	]
	settlement_ledger_label.text = "🏛 City Grant: +%s   •   🛒 Services: +%s   •   🧹 Staff Wages: -%s" % [
		FacilityCatalog.format_money(city_grant),
		FacilityCatalog.format_money(service_inc),
		FacilityCatalog.format_money(staff_wages)
	]

	var total_day_net := net_change + service_inc
	var sign_str := "+" if total_day_net >= 0 else "-"
	settlement_net_label.text = "💰 Daily Net Balance: %s%s" % [
		sign_str, FacilityCatalog.format_money(absi(total_day_net))
	]
	var pill_sb := settlement_net_pill.get_theme_stylebox("panel") as StyleBoxFlat
	if pill_sb:
		pill_sb.bg_color = Color("2d7a4d") if total_day_net >= 0 else Color("a8423b")

	var vp_w := get_viewport().get_visible_rect().size.x
	if vp_w <= 0.0:
		vp_w = 1280.0
	var card_x := (vp_w - settlement_card.size.x) * 0.5
	settlement_card_base_y = 74.0
	settlement_card.position = Vector2(card_x, settlement_card_base_y - 26.0)
	settlement_card.pivot_offset = settlement_card.size * 0.5
	settlement_card.scale = Vector2(0.84, 0.84)
	settlement_card.modulate = Color(1.0, 1.0, 1.0, 0.0)
	settlement_card.rotation = -0.025
	settlement_card.visible = true
	settlement_card_timer = 4.4

	if settlement_tween and settlement_tween.is_valid():
		settlement_tween.kill()
	settlement_tween = create_tween().set_parallel(true)
	settlement_tween.tween_property(settlement_card, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	settlement_tween.tween_property(settlement_card, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	settlement_tween.tween_property(settlement_card, "rotation", 0.0, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_settlement_card_anim(delta: float) -> void:
	if not is_instance_valid(settlement_card) or not settlement_card.visible:
		return
	if settlement_card_timer <= 0.0:
		return

	settlement_card_timer -= delta
	var vp_w := get_viewport().get_visible_rect().size.x
	if vp_w <= 0.0:
		vp_w = 1280.0
	var card_x := (vp_w - settlement_card.size.x) * 0.5
	var float_y := sin(menu_anim_time * 2.8) * 3.5

	if settlement_card_timer <= 0.35:
		var t := clampf(settlement_card_timer / 0.35, 0.0, 1.0)
		settlement_card.modulate.a = t
		settlement_card.scale = Vector2.ONE * (0.92 + 0.08 * t)
		settlement_card.position = Vector2(card_x, settlement_card_base_y - (1.0 - t) * 20.0)
		if settlement_card_timer <= 0.0:
			settlement_card.visible = false
	else:
		settlement_card.position = Vector2(card_x, settlement_card_base_y + float_y)
		settlement_card.rotation = sin(menu_anim_time * 1.6) * 0.012

# --- Daily Financial Settlement & Scheduled Drafts ---

func get_daily_staff_payroll() -> int:
	var total := 0
	for stf in active_staff:
		if not is_instance_valid(stf):
			continue
		var info := FacilityCatalog.get_staff_info(int(stf.staff_type))
		total += int(info.get("daily_wage", 1000))
	return roundi(float(total) * staff_wage_multiplier)

func calculate_daily_city_grant() -> int:
	var loc: Dictionary = locations_list[selected_location_index]
	var mult := float(loc.get("grant_multiplier", 1.0)) * city_grant_multiplier
	var base_grant := 7000.0 + 3000.0 * (reputation - 1.0)
	var hap_factor := pow(clampf(happiness / 100.0, 0.0, 1.0), 1.25)
	var raw_grant := base_grant * hap_factor * mult
	return roundi(raw_grant)

func _calculate_end_of_day_happiness() -> float:
	var total_departures := day_patrons_happy_exit + day_patrons_frustrated_exit
	var satisfaction_score := 85.0
	if total_departures > 0:
		var sat_ratio := float(day_patrons_happy_exit) / float(total_departures)
		satisfaction_score = sat_ratio * 80.0
	elif day_patrons_served > 0:
		satisfaction_score = 80.0

	# Plaza cleanliness: total litter pieces left uncollected on the plaza
	var total_trash := grid_manager.get_total_trash_on_plaza()
	var cleanliness_mod := 10.0 # +10 bonus for a pristine plaza
	if total_trash > 0:
		cleanliness_mod = maxf(-25.0, 8.0 - float(total_trash) * 3.5)

	# Civic care: lost citizens successfully guided and staff assistance
	var civic_bonus := clampf(float(day_lost_guided) * 1.5 + float(day_patrons_served) * 0.15, 0.0, 10.0)
	var overload_penalty := clampf(float(day_stalls_overloaded) * 4.0, 0.0, 20.0)

	var day_score := satisfaction_score + cleanliness_mod + civic_bonus - overload_penalty
	day_score = clampf(day_score, 0.0, 100.0)

	# First day starts directly from today's performance; subsequent days blend smoothly
	if week_number == 1 and day_index == 0:
		return day_score
	return clampf(happiness * 0.35 + day_score * 0.65, 0.0, 100.0)

func _calculate_end_of_day_reputation_delta(end_day_happiness: float) -> float:
	var delta := 0.0
	if end_day_happiness >= 85.0:
		delta = 0.20 + 0.10 * ((end_day_happiness - 85.0) / 15.0)
		if day_patrons_served >= 15:
			delta += 0.05
	elif end_day_happiness >= 70.0:
		delta = 0.08 + 0.08 * ((end_day_happiness - 70.0) / 15.0)
	elif end_day_happiness >= 50.0:
		delta = 0.01
	elif end_day_happiness >= 35.0:
		delta = -0.08
	else:
		delta = -0.18
	return delta

func _advance_day() -> void:
	var old_day_name := DAY_NAMES[day_index]
	var prev_happiness := happiness

	# 1. Calculate end-of-day Happiness
	var new_happiness := _calculate_end_of_day_happiness()
	happiness = new_happiness

	# 2. Calculate end-of-day Reputation change
	var rep_delta := _calculate_end_of_day_reputation_delta(happiness)
	reputation = maxf(1.0, reputation + rep_delta)
	peak_reputation = maxf(peak_reputation, reputation)

	# 3. Financial settlement
	var city_grant := calculate_daily_city_grant()
	var staff_wages := get_daily_staff_payroll()
	var net_change := city_grant - staff_wages
	grid_manager.add_money(net_change)

	# 4. Display cozy animated End-of-Day Settlement Announcement Card
	var summary_text := "%s Settlement: ♥ %d  ★ %.1f (%+.2f)  Grant +%s  Wages -%s" % [
		old_day_name, roundi(happiness), reputation, rep_delta,
		FacilityCatalog.format_money(city_grant), FacilityCatalog.format_money(staff_wages)
	]
	last_ledger_summary = summary_text
	_show_settlement_announcement_card(
		old_day_name,
		prev_happiness,
		happiness,
		rep_delta,
		city_grant,
		daily_service_income,
		staff_wages,
		net_change
	)

	# 5. Check Game Over condition at end-of-day inspection
	if happiness <= 10.0:
		_trigger_game_over()
		return

	# Reset daily counters for the new day
	daily_service_income = 0
	day_patrons_served = 0
	day_patrons_happy_exit = 0
	day_patrons_frustrated_exit = 0
	day_lost_guided = 0
	day_trash_cleaned = 0
	day_stalls_overloaded = 0

	day_index += 1
	if day_index >= 7:
		day_index = 0
		week_number += 1

	# Weekly Schedule:
	# - Wednesday (day_index == 2): Facility Direction Upgrade (ONLY 2 choices; shapes facilities & customer types)
	# - Sunday Morning (day_index == 6): Perk Selection (Benefit + Disadvantage trade-off cards)
	if day_index == 2:
		_trigger_wednesday_facility_upgrade()
	elif day_index == 6:
		_trigger_sunday_perk_draft()

	_update_stats_ui()
	_update_clock_ui()

func _trigger_wednesday_facility_upgrade() -> void:
	is_drafting = true
	last_unpaused_speed = sim_speed if sim_speed > 0.0 else 1.0
	_set_sim_speed(0.0)
	grid_manager.interaction_enabled = false

	draft_title_label.text = "🌿 Wednesday Plaza Upgrade — Choose 1 of 2 New Facilities"
	draft_choices.clear()

	var pair_nature: Array[Dictionary] = [
		{
			"type": "facility_upgrade",
			"name": "🌸 Flower Garden",
			"category_badge": "COMFORT LANDMARK (+1 Free)",
			"benefit_line": "👥 Elders visit the plaza much more often (+120%)",
			"impact_line": "🪑 All Comfort facilities rest visitors 30% faster",
			"accent": Color("d96b8a"),
			"item": FacilityCatalog.ItemId.FLOWER_GARDEN,
			"count": 1,
			"archetype_mults": {PeepAgent.Archetype.ELDER: 2.2},
			"comfort_speed_mult": 1.30
		},
		{
			"type": "facility_upgrade",
			"name": "🦆 Duck Pond",
			"category_badge": "COMFORT LANDMARK (+1 Free)",
			"benefit_line": "👥 Couples & Kids visit the plaza much more often (+100%)",
			"impact_line": "🧭 Calms nearby visitors & prevents getting lost",
			"accent": Color("4a9eba"),
			"item": FacilityCatalog.ItemId.DUCK_POND,
			"count": 1,
			"archetype_mults": {PeepAgent.Archetype.COUPLE: 2.0, PeepAgent.Archetype.CHILD: 2.0}
		}
	]

	var pair_culture: Array[Dictionary] = [
		{
			"type": "facility_upgrade",
			"name": "☕ Coffee Roaster",
			"category_badge": "DINING LANDMARK (+1 Free)",
			"benefit_line": "👥 Business visitors come to the plaza more often (+120%)",
			"impact_line": "💰 All Dining facilities earn +30% more income",
			"accent": Color("b8643e"),
			"item": FacilityCatalog.ItemId.COFFEE_ROASTER,
			"count": 1,
			"archetype_mults": {PeepAgent.Archetype.BUSINESS: 2.2},
			"dining_income_mult": 1.30
		},
		{
			"type": "facility_upgrade",
			"name": "🎸 Street Stage",
			"category_badge": "SERVICE LANDMARK (+1 Free)",
			"benefit_line": "👥 Couples & Normal citizens visit more often (+80%)",
			"impact_line": "⏳ All facility queues gain +35% visitor patience",
			"accent": Color("8e57b8"),
			"item": FacilityCatalog.ItemId.STREET_STAGE,
			"count": 1,
			"archetype_mults": {PeepAgent.Archetype.COUPLE: 1.8, PeepAgent.Archetype.NORMAL: 1.5},
			"queue_patience_mult": 1.35
		}
	]

	var chosen_pair := pair_nature if (week_number % 2 == 1) else pair_culture
	# Only 2 choices on Wednesday!
	_present_styled_draft_cards(chosen_pair, 2)

func _trigger_sunday_perk_draft() -> void:
	is_drafting = true
	last_unpaused_speed = sim_speed if sim_speed > 0.0 else 1.0
	_set_sim_speed(0.0)
	grid_manager.interaction_enabled = false

	draft_title_label.text = "☀ Sunday Morning Perk — Select a Trade-Off Perk"
	draft_choices.clear()

	var perk_pool: Array[Dictionary] = [
		{
			"type": "sunday_perk",
			"name": "📈 Commercial Boom",
			"category_badge": "ECONOMIC PERK",
			"benefit_line": "✔ Benefit: Service Facility Income ×2.0",
			"disadvantage_line": "✖ Disadvantage: Staff Daily Cost ×1.5",
			"accent": Color("d98a3b"),
			"income_mult_scale": 2.0,
			"staff_cost_scale": 1.5
		},
		{
			"type": "sunday_perk",
			"name": "🏦 Emergency City Grant",
			"category_badge": "TREASURY PERK",
			"benefit_line": "✔ Benefit: Receive +$50k Budget immediately",
			"disadvantage_line": "✖ Disadvantage: Reduce Reputation by -15%",
			"accent": Color("4a90ba"),
			"cash": 50000,
			"reputation_scale": 0.85
		},
		{
			"type": "sunday_perk",
			"name": "🎉 Tourism Festival Blitz",
			"category_badge": "PUBLICITY PERK",
			"benefit_line": "✔ Benefit: Reputation +30% & City Grant +25%",
			"disadvantage_line": "✖ Disadvantage: Visitors drop 2× more Trash",
			"accent": Color("8e57b8"),
			"reputation_scale": 1.30,
			"grant_mult_scale": 1.25,
			"trash_rate_scale": 2.0
		},
		{
			"type": "sunday_perk",
			"name": "🧹 Civic Union Pact",
			"category_badge": "STAFF PERK",
			"benefit_line": "✔ Benefit: Staff Cost ×0.5 & +1 Free Janitor",
			"disadvantage_line": "✖ Disadvantage: Service Facility Income -25%",
			"accent": Color("4f9e69"),
			"staff_cost_scale": 0.5,
			"free_staff": FacilityCatalog.StaffId.JANITOR,
			"income_mult_scale": 0.75
		},
		{
			"type": "sunday_perk",
			"name": "🏛 Corporate Sponsorship",
			"category_badge": "EXPANSION PERK",
			"benefit_line": "✔ Benefit: Receive +$35k & +6 Free Walk Tiles",
			"disadvantage_line": "✖ Disadvantage: Reduce Happiness by -15",
			"accent": Color("c45b4a"),
			"cash": 35000,
			"item": FacilityCatalog.ItemId.PATH_TILE,
			"count": 6,
			"happiness_delta": -15.0
		}
	]
	# Ensure the two signature perks (Income x2 / Staff x1.5 and +50k / -15% Rep) are prioritized in the draw
	var top_two: Array[Dictionary] = [perk_pool[0], perk_pool[1]]
	var rest: Array[Dictionary] = [perk_pool[2], perk_pool[3], perk_pool[4]]
	rest.shuffle()
	var final_perks: Array[Dictionary] = [top_two[0], top_two[1], rest[0]]
	_present_styled_draft_cards(final_perks, 3)

func _present_styled_draft_cards(pool: Array[Dictionary], count: int) -> void:
	for child in draft_cards_box.get_children():
		child.queue_free()
	draft_choices.clear()

	var card_size := Vector2(276, 198) if count == 2 else Vector2(246, 198)
	var limit := mini(count, pool.size())

	for i in range(limit):
		var card_data: Dictionary = pool[i].duplicate()
		draft_choices.append(card_data)
		var accent_col: Color = card_data.get("accent", Color("d96548"))

		var btn := Button.new()
		btn.custom_minimum_size = card_size
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = ""
		var normal_sb := _make_25d_card_stylebox(Color("f6f0e4"), accent_col.darkened(0.1), 8, 16, Vector2(5, 10))
		var hover_sb := _make_25d_card_stylebox(Color("fffdf9"), Color("f5b942"), 10, 22, Vector2(6, 14))
		btn.add_theme_stylebox_override("normal", normal_sb)
		btn.add_theme_stylebox_override("hover", hover_sb)
		btn.add_theme_stylebox_override("pressed", hover_sb)

		var vbox := VBoxContainer.new()
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.offset_left = 14
		vbox.offset_right = -14
		vbox.offset_top = 12
		vbox.offset_bottom = -12
		vbox.add_theme_constant_override("separation", 7)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(vbox)

		var top_bar_rect := ColorRect.new()
		top_bar_rect.color = accent_col
		top_bar_rect.custom_minimum_size = Vector2(0, 10)
		top_bar_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(top_bar_rect)

		var title_lbl := Label.new()
		title_lbl.name = "DraftCardTitle"
		title_lbl.text = str(card_data.get("name", "Card"))
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.add_theme_font_size_override("font_size", 20)
		title_lbl.add_theme_color_override("font_color", Color("1f242d"))
		title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(title_lbl)

		var badge_lbl := Label.new()
		badge_lbl.text = str(card_data.get("category_badge", "UPGRADE"))
		badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_lbl.add_theme_font_size_override("font_size", 12)
		badge_lbl.add_theme_color_override("font_color", accent_col.darkened(0.2))
		badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(badge_lbl)

		var ben_lbl := Label.new()
		ben_lbl.name = "DraftCardBenefit"
		ben_lbl.text = str(card_data.get("benefit_line", ""))
		ben_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ben_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ben_lbl.add_theme_font_size_override("font_size", 14)
		ben_lbl.add_theme_color_override("font_color", Color("216e3e"))
		ben_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(ben_lbl)

		var second_lbl := Label.new()
		second_lbl.name = "DraftCardSecondary"
		var is_disadvantage := card_data.has("disadvantage_line")
		second_lbl.text = str(card_data.get("disadvantage_line", card_data.get("impact_line", "")))
		second_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		second_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		second_lbl.add_theme_font_size_override("font_size", 14)
		second_lbl.add_theme_color_override("font_color", Color("b0352e") if is_disadvantage else Color("34547a"))
		second_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(second_lbl)

		var idx := i
		btn.pressed.connect(func() -> void: _on_draft_card_selected(idx))
		draft_cards_box.add_child(btn)

	draft_modal.visible = true

func _on_draft_card_selected(index: int) -> void:
	if index >= 0 and index < draft_choices.size():
		var chosen: Dictionary = draft_choices[index]
		var cash_bonus := int(chosen.get("cash", 0))
		if cash_bonus != 0:
			grid_manager.add_money(cash_bonus)
		if chosen.has("item"):
			var item_id := int(chosen["item"])
			unlocked_special_facilities[item_id] = true
			grid_manager.add_inventory_item(item_id, int(chosen.get("count", 1)))
		if chosen.has("extra_item"):
			var ex_id := int(chosen["extra_item"])
			unlocked_special_facilities[ex_id] = true
			grid_manager.add_inventory_item(ex_id, int(chosen.get("extra_count", 1)))
		if bool(chosen.get("clean_all_trash", false)):
			grid_manager.clear_all_trash()
		if chosen.has("free_staff"):
			hire_staff(int(chosen["free_staff"]), true)
		if chosen.has("income_mult_bonus"):
			service_income_multiplier += float(chosen["income_mult_bonus"])
		if chosen.has("income_mult_scale"):
			service_income_multiplier *= float(chosen["income_mult_scale"])
		if chosen.has("staff_cost_scale"):
			staff_wage_multiplier *= float(chosen["staff_cost_scale"])
		if chosen.has("grant_mult_scale"):
			city_grant_multiplier *= float(chosen["grant_mult_scale"])
		if chosen.has("trash_rate_scale"):
			trash_drop_multiplier *= float(chosen["trash_rate_scale"])
		if chosen.has("reputation_scale"):
			reputation = maxf(1.0, reputation * float(chosen["reputation_scale"]))
			peak_reputation = maxf(peak_reputation, reputation)
		if chosen.has("happiness_delta"):
			happiness = clampf(happiness + float(chosen["happiness_delta"]), 5.0, 100.0)
		if chosen.has("happiness_bonus"):
			happiness = clampf(happiness + float(chosen["happiness_bonus"]), 0.0, 100.0)
		if chosen.has("reputation_bonus"):
			reputation += float(chosen["reputation_bonus"])
			peak_reputation = maxf(peak_reputation, reputation)
		if chosen.has("archetype_mults"):
			var mults: Dictionary = chosen["archetype_mults"]
			for arch_key in mults.keys():
				var cur_w := float(archetype_weights.get(arch_key, 15.0))
				archetype_weights[arch_key] = cur_w * float(mults[arch_key])
		if chosen.has("comfort_speed_mult"):
			comfort_service_speed_mult *= float(chosen["comfort_speed_mult"])
		if chosen.has("dining_income_mult"):
			dining_income_mult *= float(chosen["dining_income_mult"])
		if chosen.has("queue_patience_mult"):
			queue_patience_mult *= float(chosen["queue_patience_mult"])
		_apply_facility_modifiers_to_all_stalls()

	draft_modal.visible = false
	is_drafting = false
	grid_manager.interaction_enabled = true
	_set_sim_speed(last_unpaused_speed)
	_update_stats_ui()
	_update_dock_ui()

func _apply_facility_modifiers_to_all_stalls() -> void:
	for stall in registered_stalls:
		if not is_instance_valid(stall):
			continue
		var info := FacilityCatalog.get_item(stall.stall_type)
		var base_dur := float(info.get("service_time", 2.0))
		if stall.is_comfort_facility():
			stall.service_duration = base_dur / maxf(0.1, comfort_service_speed_mult)
		stall.overload_grace_period = 9.0 * queue_patience_mult

# --- Customer Set Spawning & Dynamic Edge Gates ---

func _pick_weighted_need() -> int:
	var w0 := float(current_need_weights[0]) if current_need_weights.size() > 0 else 1.0
	var w1 := float(current_need_weights[1]) if current_need_weights.size() > 1 else 1.0
	var w2 := float(current_need_weights[2]) if current_need_weights.size() > 2 else 1.0
	var w3 := float(current_need_weights[3]) if current_need_weights.size() > 3 else 1.0
	var total := w0 + w1 + w2 + w3
	var r := randf() * total
	if r < w0:
		return PeepAgent.NeedType.FOOD
	elif r < w0 + w1:
		return PeepAgent.NeedType.DRINK
	elif r < w0 + w1 + w2:
		return PeepAgent.NeedType.RESTROOM
	return PeepAgent.NeedType.SIT

func _generate_needs_for_archetype(arch: PeepAgent.Archetype) -> Array[int]:
	var needs: Array[int] = []
	match arch:
		PeepAgent.Archetype.ELDER:
			if randf() < 0.45:
				var first_need := _pick_weighted_need()
				if first_need != PeepAgent.NeedType.SIT:
					needs.append(first_need)
			needs.append(PeepAgent.NeedType.SIT)
		PeepAgent.Archetype.BUSINESS:
			var count := 2 if randf() < 0.4 else 1
			for _i in range(count):
				var n := _pick_weighted_need()
				if n == PeepAgent.NeedType.SIT:
					n = PeepAgent.NeedType.DRINK
				if not needs.has(n):
					needs.append(n)
		PeepAgent.Archetype.CHILD:
			if randf() < 0.65:
				needs.append(_pick_weighted_need())
		_:
			var roll := randf()
			var count := 0
			if roll >= 0.28 and roll < 0.75:
				count = 1
			elif roll >= 0.75:
				count = 2
			for _i in range(count):
				var n := _pick_weighted_need()
				if not needs.has(n):
					needs.append(n)
	return needs

func _pick_random_archetype() -> PeepAgent.Archetype:
	var w_normal := float(archetype_weights.get(PeepAgent.Archetype.NORMAL, 42.0))
	var w_elder := float(archetype_weights.get(PeepAgent.Archetype.ELDER, 16.0))
	var w_business := float(archetype_weights.get(PeepAgent.Archetype.BUSINESS, 16.0))
	var w_couple := float(archetype_weights.get(PeepAgent.Archetype.COUPLE, 13.0))
	var w_child := float(archetype_weights.get(PeepAgent.Archetype.CHILD, 13.0))
	var total := w_normal + w_elder + w_business + w_couple + w_child
	var r := randf() * total
	if r < w_normal:
		return PeepAgent.Archetype.NORMAL
	r -= w_normal
	if r < w_elder:
		return PeepAgent.Archetype.ELDER
	r -= w_elder
	if r < w_business:
		return PeepAgent.Archetype.BUSINESS
	r -= w_business
	if r < w_couple:
		return PeepAgent.Archetype.COUPLE
	return PeepAgent.Archetype.CHILD

func _pick_spawn_and_exit_gates() -> Array[Vector2i]:
	var entry_candidates := grid_manager.path_network.get_entry_gate_cells()
	var non_full_entries: Array[Vector2i] = []
	for c in entry_candidates:
		if not grid_manager.path_network.is_tile_full(c, 2):
			non_full_entries.append(c)

	var start_cell: Vector2i = left_entrance_coords
	if not non_full_entries.is_empty():
		start_cell = non_full_entries.pick_random()
	elif not entry_candidates.is_empty():
		# If edge path gates are full, allow customer to walk in freely from an adjacent walkable edge tile
		var free_edge: Array[Vector2i] = []
		var edge_x := -grid_manager.grid_half_width if randf() < 0.5 else grid_manager.grid_half_width
		for gz in range(-grid_manager.grid_half_height, grid_manager.grid_half_height + 1):
			var ec := Vector2i(edge_x, gz)
			if grid_manager.path_network.is_cell_walkable(ec) and grid_manager.path_network.get_tile_type(ec) != FacilityCatalog.ItemId.EXIT_GATE and not grid_manager.path_network.is_tile_full(ec, 2):
				free_edge.append(ec)
		if not free_edge.is_empty():
			start_cell = free_edge.pick_random()
		else:
			start_cell = entry_candidates.pick_random()

	var exit_candidates := grid_manager.path_network.get_exit_gate_cells(-signi(start_cell.x))
	var end_cell: Vector2i = right_entrance_coords if start_cell.x <= 0 else left_entrance_coords
	if not exit_candidates.is_empty():
		end_cell = exit_candidates.pick_random()

	return [start_cell, end_cell]

func _spawn_customer_set() -> void:
	var bounds := get_current_set_bounds()
	var set_size := randi_range(bounds.x, bounds.y)
	var spawned := 0
	while spawned < set_size:
		var pair := _pick_spawn_and_exit_gates()
		var arch := _pick_random_archetype()
		var needs := _generate_needs_for_archetype(arch)
		_create_citizen_instance(arch, needs, pair[0], pair[1])
		spawned += 1

func _spawn_peep_from_custom(start_coords: Vector2i, arch: PeepAgent.Archetype = PeepAgent.Archetype.NORMAL) -> void:
	var exit_candidates := grid_manager.path_network.get_exit_gate_cells(0)
	var end_coords := left_entrance_coords if randf() < 0.5 else right_entrance_coords
	if not exit_candidates.is_empty():
		end_coords = exit_candidates.pick_random()
	var needs := _generate_needs_for_archetype(arch)
	_create_citizen_instance(arch, needs, start_coords, end_coords)

func _create_citizen_instance(
	arch: PeepAgent.Archetype,
	needs: Array[int],
	start_coords: Vector2i,
	end_coords: Vector2i
) -> PeepAgent:
	if not peep_scene:
		return null

	var peep := peep_scene.instantiate() as PeepAgent
	peeps_container.add_child(peep)
	peep.global_position = Vector3(start_coords.x, 0.0, start_coords.y)

	peep.setup_citizen_full(arch, needs, start_coords, end_coords, grid_manager.path_network)
	peep.need_routing_refresh.connect(_assign_best_route_for_peep)
	peep.exited_unfulfilled.connect(_on_peep_exited_unfulfilled)
	peep.exited_happy_passthrough.connect(_on_peep_exited_happy_passthrough)
	peep.wants_to_dispose_trash.connect(_on_peep_wants_to_dispose_trash)

	_assign_best_route_for_peep(peep)
	return peep

func _assign_best_route_for_peep(peep: PeepAgent) -> void:
	if not is_instance_valid(peep):
		return

	var from_coords := _get_nearest_valid_walkable_cell(peep.get_current_grid_coords())

	# If citizen is LOST, wander freely around walkable plaza tiles (never on water or fences)
	if peep.state == PeepAgent.AgentState.LOST:
		var random_cell := _pick_random_walkable_cell()
		var wander_route := grid_manager.path_network.get_route(from_coords, random_cell, false, true)
		peep.trigger_lost_state(wander_route)
		return

	# Ensure peep.exit_coords is still a valid exit gate (not blocked by a Fence or turned into an Entry Gate)
	var exit_type := grid_manager.path_network.get_tile_type(peep.exit_coords)
	if not grid_manager.path_network.is_cell_walkable(peep.exit_coords) or exit_type == FacilityCatalog.ItemId.ENTRY_GATE:
		var valid_exits := grid_manager.path_network.get_exit_gate_cells(-signi(peep.spawn_coords.x))
		if not valid_exits.is_empty():
			peep.exit_coords = valid_exits.pick_random()

	if not peep.has_active_need() or peep.state == PeepAgent.AgentState.EXITING_FRUSTRATED:
		var exit_route := grid_manager.path_network.get_route(
			from_coords, peep.exit_coords, peep.prefers_crowd_diversion, peep.is_walking_freely
		)
		if exit_route.is_empty():
			exit_route = grid_manager.path_network.get_route(from_coords, peep.exit_coords, false, true)
		peep.assign_passthrough_route(exit_route)
		return

	var desired_need := peep.get_active_need()
	var best_stall: StallController = null
	var best_route: PackedVector2Array = PackedVector2Array()
	var best_access_cell: Vector2i = from_coords
	var best_cost: float = 999999.0

	for stall in registered_stalls:
		if not is_instance_valid(stall):
			continue
		if stall.need_fulfilled != desired_need:
			continue
		var access_variant: Variant = grid_manager.path_network.get_adjacent_access_tile(stall.grid_coords)
		if access_variant == null:
			continue
		var access_cell: Vector2i = access_variant
		var candidate_route := grid_manager.path_network.get_route(
			from_coords, access_cell, peep.prefers_crowd_diversion, peep.is_walking_freely
		)
		if candidate_route.is_empty():
			continue
		var q_len := float(stall.waiting_peeps.size())
		var max_cap := float(stall.max_waiting_capacity)

		# Overcrowding penalty: strong aversion to full or nearly full facilities
		var fullness_penalty := 0.0
		if q_len >= max_cap:
			fullness_penalty = 500.0
		elif q_len >= max_cap - 1.0:
			fullness_penalty = 35.0

		# Queue cost: quadratic scaling so less crowded facilities are strongly favored
		# 0 people -> 0 cost; 1 person -> 9; 2 people -> 26; 3 people -> 51; 4 people -> 84
		var queue_cost := (q_len * 5.0 + (q_len * q_len) * 4.0) * peep.crowd_aversion

		# Distance cost weighted by customer's personal willingness to walk
		var dist_cost := float(candidate_route.size()) * peep.distance_tolerance

		# Personal thought / individual whim per customer & facility
		var stall_quirk := float((stall.get_instance_id() ^ peep.get_instance_id()) % 11) * 0.45 - 2.25
		var whim := peep.personality_whim_seed + stall_quirk

		var total_cost := dist_cost + queue_cost + fullness_penalty + whim
		if total_cost < best_cost:
			best_cost = total_cost
			best_stall = stall
			best_route = candidate_route
			best_access_cell = access_cell

	if best_stall != null:
		peep.assign_facility_route(best_route, best_stall, best_access_cell)
	else:
		var passthrough_route := grid_manager.path_network.get_route(
			from_coords, peep.exit_coords, peep.prefers_crowd_diversion, peep.is_walking_freely
		)
		peep.assign_passthrough_route(passthrough_route)

func _pick_random_path_cell() -> Vector2i:
	var keys := grid_manager.path_network.occupied_cells.keys()
	if not keys.is_empty():
		return keys.pick_random() as Vector2i
	return _pick_random_walkable_cell()

func _pick_random_walkable_cell() -> Vector2i:
	var hw := grid_manager.grid_half_width
	var hh := grid_manager.grid_half_height
	for _attempt in range(25):
		var c := Vector2i(randi_range(-hw + 1, hw - 1), randi_range(-hh + 1, hh - 1))
		if grid_manager.path_network.is_cell_walkable(c):
			return c
	return Vector2i.ZERO

func _get_nearest_valid_walkable_cell(coords: Vector2i) -> Vector2i:
	if grid_manager.path_network.is_cell_walkable(coords):
		return coords
	var best_cell := Vector2i.ZERO
	var best_dist := 999999.0
	var hw := grid_manager.grid_half_width
	var hh := grid_manager.grid_half_height
	for gx in range(-hw, hw + 1):
		for gz in range(-hh, hh + 1):
			var c := Vector2i(gx, gz)
			if grid_manager.path_network.is_cell_walkable(c):
				var d := Vector2(coords - c).length_squared()
				if d < best_dist:
					best_dist = d
					best_cell = c
	return best_cell

func _recalculate_all_peep_routes() -> void:
	for child in peeps_container.get_children():
		if child is PeepAgent:
			var peep := child as PeepAgent
			if peep.state == PeepAgent.AgentState.QUEUING:
				continue
			_assign_best_route_for_peep(peep)

# --- Littering, Auras, Lost State & Staff Coordination ---

func _on_peep_wants_to_dispose_trash(_peep: PeepAgent, tile_coords: Vector2i) -> void:
	for stall in registered_stalls:
		if is_instance_valid(stall) and stall.can_accept_trash():
			if Vector2(stall.grid_coords - tile_coords).length() <= 2.6:
				stall.deposit_trash()
				return
	if randf() < 0.65 * trash_drop_multiplier:
		grid_manager.spawn_trash_on_tile(tile_coords)
		if trash_drop_multiplier >= 1.8 and randf() < 0.55:
			grid_manager.spawn_trash_on_tile(tile_coords)
		_ApplyLitterPenaltyCheck(tile_coords)

func _ApplyLitterPenaltyCheck(_tile_coords: Vector2i) -> void:
	# Cleanliness is evaluated at end of day based on total remaining trash
	pass

func _process_plaza_auras_and_lost_events() -> void:
	var sec_positions: Array[Vector2] = []
	for stf in active_staff:
		if is_instance_valid(stf) and stf.is_active_security():
			sec_positions.append(Vector2(stf.global_position.x, stf.global_position.z))

	var kiosk_positions: Array[Vector2] = []
	var lamp_positions: Array[Vector2] = []
	for stall in registered_stalls:
		if not is_instance_valid(stall):
			continue
		if stall.is_info_kiosk():
			kiosk_positions.append(Vector2(stall.grid_coords.x, stall.grid_coords.y))
		elif stall.is_lamp_post():
			lamp_positions.append(Vector2(stall.grid_coords.x, stall.grid_coords.y))

	var is_night := day_night_cycle.current_night_factor > 0.5

	for child in peeps_container.get_children():
		if not (child is PeepAgent):
			continue
		var peep := child as PeepAgent
		if peep.state == PeepAgent.AgentState.QUEUING:
			continue

		var p_cell := peep.get_current_grid_coords()
		var p_pos2d := Vector2(peep.global_position.x, peep.global_position.z)

		peep.current_tile_trash_count = grid_manager.get_trash_count_on_tile(p_cell)
		var sec_boost := false
		for sp in sec_positions:
			if p_pos2d.distance_to(sp) <= 2.6:
				sec_boost = true
				break
		peep.current_tile_security_boost = sec_boost

		if peep.state == PeepAgent.AgentState.LOST:
			for kp in kiosk_positions:
				if p_pos2d.distance_to(kp) <= 3.0:
					peep.guide_out_of_lost()
					break
			continue

		if not peep.has_been_lost and absi(p_cell.x) <= grid_manager.grid_half_width - 2:
			if peep.archetype == PeepAgent.Archetype.CHILD or peep.archetype == PeepAgent.Archetype.ELDER:
				var near_kiosk_or_sec := sec_boost
				for kp in kiosk_positions:
					if p_pos2d.distance_to(kp) <= 3.2:
						near_kiosk_or_sec = true
						break
				if not near_kiosk_or_sec:
					var near_lamp := false
					for lp in lamp_positions:
						if p_pos2d.distance_to(lp) <= 3.5:
							near_lamp = true
							break
					var base_chance := 0.045 if peep.archetype == PeepAgent.Archetype.CHILD else 0.025
					if is_night and not near_lamp:
						base_chance *= 1.6
					if randf() < base_chance:
						var w_route := grid_manager.path_network.get_route(p_cell, _pick_random_walkable_cell(), false, true)
						peep.trigger_lost_state(w_route)

# --- Staff Hiring & AI Task Dispatcher ---

func hire_staff(staff_id: int, is_free: bool = false) -> void:
	var info := FacilityCatalog.get_staff_info(staff_id)
	var hire_cost := int(info.get("hire_cost", 1000))
	if not is_free and not grid_manager.spend_money(hire_cost):
		return

	var staff := StaffAgent.new()
	staff_container.add_child(staff)
	var spawn_cell := _pick_random_path_cell()
	staff.setup_staff(staff_id as StaffAgent.StaffType, Vector3(spawn_cell.x, 0.0, spawn_cell.y))
	staff.request_staff_task.connect(_assign_task_to_staff)
	staff.janitor_cleaned_cell.connect(_on_janitor_cleaned_cell)
	staff.staff_guided_peep.connect(_on_staff_guided_peep)
	active_staff.append(staff)

	_assign_task_to_staff(staff)
	_update_dock_ui()
	_update_stats_ui()

func _assign_task_to_staff(staff: StaffAgent) -> void:
	if not is_instance_valid(staff):
		return

	var s_cell := _get_nearest_valid_walkable_cell(staff.get_current_grid_coords())

	if staff.staff_type == StaffAgent.StaffType.JANITOR:
		# 1. Look for floor trash props reachable without crossing water/fences
		var best_trash_cell: Variant = null
		var best_route := PackedVector2Array()
		for cell_key in grid_manager.trash_nodes.keys():
			var c: Vector2i = cell_key
			if grid_manager.get_trash_count_on_tile(c) > 0:
				var r := grid_manager.path_network.get_route(s_cell, c, false, true)
				if not r.is_empty() and (best_trash_cell == null or r.size() < best_route.size()):
					best_trash_cell = c
					best_route = r
		if best_trash_cell != null:
			staff.assign_janitor_target(best_trash_cell as Vector2i, null, best_route)
			return

		# 2. Look for Trashcans with stored trash >= 4
		for stall in registered_stalls:
			if is_instance_valid(stall) and stall.is_trashcan() and stall.stored_trash >= 4:
				var acc_var: Variant = grid_manager.path_network.get_adjacent_access_tile(stall.grid_coords)
				if acc_var != null:
					var r := grid_manager.path_network.get_route(s_cell, acc_var as Vector2i, false, true)
					if not r.is_empty():
						staff.assign_janitor_target(acc_var as Vector2i, stall, r)
						return

		# 3. Patrol off-path around the plaza (respecting water, fences, and obstacles)
		var patrol_cell := _pick_random_walkable_cell()
		var p_route := grid_manager.path_network.get_route(s_cell, patrol_cell, false, true)
		staff.assign_janitor_patrol(patrol_cell, p_route)
		return

	# Plaza Staff or Security Officer
	if staff.state == StaffAgent.StaffState.SEEKING_REST:
		var best_comfort: StallController = null
		var best_access := s_cell
		var best_route := PackedVector2Array()
		for stall in registered_stalls:
			if is_instance_valid(stall) and stall.is_comfort_facility():
				var acc_var: Variant = grid_manager.path_network.get_adjacent_access_tile(stall.grid_coords)
				if acc_var != null:
					var r := grid_manager.path_network.get_route(s_cell, acc_var as Vector2i, false, false)
					if not r.is_empty() and (best_comfort == null or r.size() < best_route.size()):
						best_comfort = stall
						best_access = acc_var as Vector2i
						best_route = r
		if best_comfort != null:
			staff.assign_rest_route(best_comfort, best_access, best_route)
		else:
			staff.assign_rest_route(null, s_cell, PackedVector2Array())
		return

	var nearest_lost: PeepAgent = null
	var nearest_route := PackedVector2Array()
	for child in peeps_container.get_children():
		if child is PeepAgent:
			var p := child as PeepAgent
			if p.state == PeepAgent.AgentState.LOST:
				var p_cell := _get_nearest_valid_walkable_cell(p.get_current_grid_coords())
				var r := grid_manager.path_network.get_route(s_cell, p_cell, false, false)
				if not r.is_empty() and (nearest_lost == null or r.size() < nearest_route.size()):
					nearest_lost = p
					nearest_route = r

	if nearest_lost != null:
		staff.assign_guide_target(nearest_lost, nearest_route)
	else:
		var patrol_dest := _pick_random_path_cell()
		var p_route := grid_manager.path_network.get_route(s_cell, patrol_dest, false, false)
		staff.assign_path_patrol(p_route)

func _on_janitor_cleaned_cell(coords: Vector2i) -> void:
	var cleaned := grid_manager.clean_trash_on_tile(coords)
	if cleaned > 0:
		day_trash_cleaned += cleaned

func _on_staff_guided_peep(_peep: PeepAgent) -> void:
	day_lost_guided += 1

# --- Facility & Citizen Callbacks ---

func _on_facility_placed(stall_node: Node3D) -> void:
	if stall_node is StallController:
		var stall := stall_node as StallController
		registered_stalls.append(stall)
		stall.peep_served.connect(_on_peep_served)
		stall.peep_frustrated.connect(_on_peep_frustrated_at_stall)
		_apply_facility_modifiers_to_all_stalls()
		_recalculate_all_peep_routes()

func _on_facility_removed(stall_node: Node3D) -> void:
	if stall_node is StallController:
		registered_stalls.erase(stall_node as StallController)
		_recalculate_all_peep_routes()

func _on_peep_served(peep: Node3D, revenue: int, stall: Node3D) -> void:
	satisfied_patrons += 1
	day_patrons_served += 1

	if revenue > 0:
		# Higher happiness generates generous tips (75% to 135% base)
		var hap_tip_mult := clampf(0.75 + 0.50 * (happiness / 100.0), 0.75, 1.35)
		if peep is PeepAgent and (peep as PeepAgent).archetype == PeepAgent.Archetype.BUSINESS:
			hap_tip_mult *= 1.35 # Business patrons tip generously for prompt service
		var cat_mult := 1.0
		if stall is StallController:
			var s_info := FacilityCatalog.get_item((stall as StallController).stall_type)
			if int(s_info.get("category", -1)) == FacilityCatalog.Category.DINING:
				cat_mult = dining_income_mult
		var final_rev := int(roundf(float(revenue) * service_income_multiplier * cat_mult * hap_tip_mult))
		daily_service_income += final_rev
		grid_manager.add_money(final_rev)

	_update_stats_ui()

func _on_peep_exited_happy_passthrough(_peep: PeepAgent) -> void:
	satisfied_patrons += 1
	day_patrons_happy_exit += 1

func _on_peep_frustrated_at_stall(_peep: Node3D) -> void:
	day_stalls_overloaded += 1
	day_patrons_frustrated_exit += 1

func _on_peep_exited_unfulfilled(_peep: PeepAgent) -> void:
	day_patrons_frustrated_exit += 1

func _apply_happiness_penalty(amount: float) -> void:
	if is_game_over:
		return
	happiness = maxf(0.0, happiness - amount)
	_update_stats_ui()

func _trigger_game_over() -> void:
	is_game_over = true
	_set_sim_speed(0.0)
	grid_manager.interaction_enabled = false
	var days_survived := (week_number - 1) * 7 + (day_index + 1)
	var loc_name: String = str(locations_list[selected_location_index].get("name", "Plaza"))
	final_score_label.text = "Location: %s\nDays Survived: %d\nPeak Reputation: %.1f ★\nHappy Citizens: %d | Budget: %s" % [
		loc_name, days_survived, peak_reputation, satisfied_patrons,
		FacilityCatalog.format_money(grid_manager.budget)
	]
	game_over_panel.visible = true

# --- Floating 3D Popups ---

func _spawn_floating_popup(world_pos: Vector3, text_str: String, col: Color) -> void:
	var lbl := Label3D.new()
	lbl.position = world_pos
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.text = text_str
	lbl.font_size = 26
	lbl.outline_size = 8
	lbl.modulate = col
	popups_container.add_child(lbl)
	floating_popups.append({"node": lbl, "age": 0.0})

func _update_floating_popups(delta: float) -> void:
	for i in range(floating_popups.size() - 1, -1, -1):
		var item: Dictionary = floating_popups[i]
		var lbl: Label3D = item["node"]
		if not is_instance_valid(lbl):
			floating_popups.remove_at(i)
			continue
		var age := float(item["age"]) + delta
		item["age"] = age
		lbl.position.y += delta * 0.65
		lbl.modulate.a = clampf(1.0 - (age / 1.4), 0.0, 1.0)
		if age >= 1.4:
			lbl.queue_free()
			floating_popups.remove_at(i)

# --- Minimal Cozy UI Updates ---

func _on_budget_changed(_new_budget: int) -> void:
	_update_stats_ui()
	_update_dock_ui()

func _set_sim_speed(new_speed: float) -> void:
	sim_speed = new_speed
	if sim_speed > 0.0:
		last_unpaused_speed = sim_speed
	if get_tree():
		get_tree().set_meta("sim_speed", sim_speed)
	_update_speed_buttons_ui()

func _select_build_tool(tool_id: int) -> void:
	if tool_id >= 0 and grid_manager.current_tool == tool_id:
		# Clicking the currently selected facility unselects it
		grid_manager.set_build_tool(-1)
	else:
		grid_manager.set_build_tool(tool_id)
	_update_dock_ui()

func _update_stats_ui() -> void:
	# Vertical Top-Left Card:
	# Row 1: Happiness (0-100 number)
	# Row 2: Reputation (no limit, no rate detail)
	# Row 3: Budget
	if happiness_label:
		happiness_label.text = "♥ %d" % clampi(roundi(happiness), 0, 100)
	if reputation_label:
		reputation_label.text = "★ %.1f" % reputation
	if budget_label:
		budget_label.text = "💰 %s" % FacilityCatalog.format_money(grid_manager.budget)

func _update_clock_ui() -> void:
	# Only show day of the week (no plaza name, no week number)
	if day_label:
		day_label.text = DAY_NAMES[day_index]
	if phase_label:
		var is_night := day_timer >= (day_duration_seconds * 0.5)
		if is_night:
			phase_label.text = "🌙 NIGHT"
			phase_label.modulate = Color(0.75, 0.85, 1.0)
		else:
			phase_label.text = "☀ DAY"
			phase_label.modulate = Color(1.0, 0.92, 0.65)

func _update_speed_buttons_ui() -> void:
	if not btn_pause:
		return
	btn_pause.modulate = Color(1.0, 0.85, 0.45) if is_zero_approx(sim_speed) else Color.WHITE
	btn_1x.modulate = Color(0.55, 0.95, 0.65) if is_equal_approx(sim_speed, 1.0) else Color.WHITE
	btn_15x.modulate = Color(0.55, 0.95, 0.65) if is_equal_approx(sim_speed, 1.5) else Color.WHITE
	btn_2x.modulate = Color(0.55, 0.95, 0.65) if is_equal_approx(sim_speed, 2.0) else Color.WHITE

func _update_dock_ui() -> void:
	var inv := grid_manager.inventory
	var cur := grid_manager.current_tool

	if tools_hbox:
		tools_hbox.visible = (selected_category >= 0)

	if deselect_tool_button:
		deselect_tool_button.visible = (selected_category >= 0 and cur >= 0)

	for item_id in item_buttons.keys():
		var btn: Button = item_buttons[item_id]
		var info := FacilityCatalog.get_item(item_id)
		var cat: int = int(info.get("category", 0))
		var vouchers := int(inv.get(item_id, 0))
		var is_special := bool(info.get("special_unlock", false))
		var is_unlocked := (not is_special) or bool(unlocked_special_facilities.get(item_id, false)) or vouchers > 0
		btn.visible = (selected_category == cat and is_unlocked)

		var cost := int(info.get("cost", 0))
		var is_selected: bool = (cur == int(item_id))
		if item_id == FacilityCatalog.ItemId.ERASE_TOOL:
			btn.text = "Demolish"
		elif vouchers > 0:
			btn.text = "%s\nx%d" % [info["name"], vouchers]
		else:
			btn.text = "%s\n%s" % [info["name"], FacilityCatalog.format_money(cost)]

		btn.modulate = Color(0.65, 0.98, 0.72) if is_selected else Color.WHITE

	var counts: Dictionary = {0: 0, 1: 0, 2: 0}
	for stf in active_staff:
		if is_instance_valid(stf):
			counts[int(stf.staff_type)] = int(counts.get(int(stf.staff_type), 0)) + 1

	for staff_id in staff_buttons.keys():
		var sbtn: Button = staff_buttons[staff_id]
		var sinfo := FacilityCatalog.get_staff_info(staff_id)
		sbtn.visible = (selected_category == FacilityCatalog.Category.STAFF)
		var scaled_wage := roundi(float(sinfo.get("daily_wage", 1000)) * staff_wage_multiplier)
		var wage_str := FacilityCatalog.format_money(scaled_wage)
		sbtn.text = "%s (%d)\n%s/d" % [sinfo["name"], int(counts.get(staff_id, 0)), wage_str]

func _setup_cozy_ui_theme() -> void:
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.16, 0.19, 0.24, 0.92)
	card_style.border_color = Color(0.90, 0.84, 0.74, 0.45)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(14)
	card_style.content_margin_left = 14
	card_style.content_margin_right = 14
	card_style.content_margin_top = 8
	card_style.content_margin_bottom = 8

	for panel_path in [
		"HUD/TopBar/LeftCard",
		"HUD/TopBar/RightCard",
		"HUD/BottomDock",
		"HUD/OptionsPanel/Panel",
		"HUD/DraftModal/Panel",
		"HUD/GameOverPanel/Panel"
	]:
		if has_node(panel_path):
			var pc := get_node(panel_path) as PanelContainer
			if pc:
				pc.add_theme_stylebox_override("panel", card_style)

	# LocationSelectPanel outer container is transparent so Mini Metro Location Cards float cleanly
	if has_node("HUD/LocationSelectPanel/Panel"):
		var loc_pc := get_node("HUD/LocationSelectPanel/Panel") as PanelContainer
		if loc_pc:
			loc_pc.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

# --- UI Button Callbacks ---

func _on_play_button_pressed() -> void:
	_show_location_select()

func _on_confirm_location_pressed() -> void:
	start_new_game()

func _on_back_to_title_pressed() -> void:
	_show_start_menu(false)

func _on_options_button_pressed() -> void:
	options_panel.visible = true

func _on_options_close_pressed() -> void:
	options_panel.visible = false

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_menu_button_pressed() -> void:
	_clear_all_peeps()
	_clear_all_staff()
	registered_stalls.clear()
	_show_start_menu(false)

func _on_speed_pause_pressed() -> void:
	_set_sim_speed(0.0)

func _on_speed_1x_pressed() -> void:
	_set_sim_speed(1.0)

func _on_speed_15x_pressed() -> void:
	_set_sim_speed(1.5)

func _on_speed_2x_pressed() -> void:
	_set_sim_speed(2.0)

func _on_restart_button_pressed() -> void:
	start_new_game()

func _on_opt_topdown_toggled(toggled_on: bool) -> void:
	camera_rig.set_top_down_mode(toggled_on)

func _on_opt_daynight_toggled(toggled_on: bool) -> void:
	day_night_cycle.lighting_cycle_enabled = toggled_on
	day_night_cycle.update_time_of_day(day_timer / day_duration_seconds)

func _on_opt_brightness_changed(value: float) -> void:
	day_night_cycle.set_brightness(value)
	if opt_brightness_value:
		opt_brightness_value.text = "%d%%" % roundi(value * 100.0)

func _on_opt_panspeed_changed(value: float) -> void:
	camera_rig.pan_speed = value
