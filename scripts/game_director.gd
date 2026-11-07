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
@onready var loc_detail_title: Label = $HUD/LocationSelectPanel/Panel/VBox/DetailBox/LocDetailTitle
@onready var loc_detail_badge: Label = $HUD/LocationSelectPanel/Panel/VBox/DetailBox/LocDetailBadge
@onready var loc_detail_desc: Label = $HUD/LocationSelectPanel/Panel/VBox/LocDetailDesc
@onready var loc_detail_rule: Label = $HUD/LocationSelectPanel/Panel/VBox/LocDetailRule

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

var selected_category: int = -1 # -1 = No category expanded yet; 0..5 = FacilityCatalog.Category
var category_buttons: Dictionary = {} # int -> Button
var item_buttons: Dictionary = {} # int -> Button
var staff_buttons: Dictionary = {} # int -> Button

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
var last_ledger_summary: String = ""

var week_number: int = 1
var day_index: int = 0 # 0 = MON .. 6 = SUN
var day_timer: float = 0.0
var spawn_timer: float = 0.0
var station_burst_timer: float = 0.0
var aura_tick_timer: float = 0.0
var current_need_weights: Array = [1.0, 1.0, 1.0, 1.0]

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
		FacilityCatalog.ItemId.RESTROOM,
		FacilityCatalog.ItemId.INFO_KIOSK,
		FacilityCatalog.ItemId.PICNIC_TABLE,
		FacilityCatalog.ItemId.BENCH,
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

	_select_dock_category(-1)

func _select_dock_category(cat_id: int) -> void:
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

	var vp_rect := get_viewport().get_visible_rect()
	var mouse_pos := get_viewport().get_mouse_position()
	var dist_from_bottom := vp_rect.size.y - mouse_pos.y

	if not bottom_dock.visible:
		# Hidden by default: appear when mouse moves down to the bottom edge
		if dist_from_bottom >= 0.0 and dist_from_bottom <= 78.0:
			_select_dock_category(-1)
			bottom_dock.visible = true
	else:
		# Keep visible while mouse stays in the bottom dock area; hide when mouse moves away
		var keep_height := 158.0 if selected_category >= 0 else 96.0
		var dock_rect := bottom_dock.get_global_rect().grow(24.0)
		if dist_from_bottom > keep_height and not dock_rect.has_point(mouse_pos):
			bottom_dock.visible = false
			_select_dock_category(-1)

func _populate_location_cards() -> void:
	if not loc_cards_box:
		return
	for child in loc_cards_box.get_children():
		child.queue_free()
	location_card_buttons.clear()

	for i in range(locations_list.size()):
		var loc: Dictionary = locations_list[i]
		var diff_lvl: int = int(loc.get("difficulty", 1))
		var diff_txt := LocationCatalog.difficulty_text(diff_lvl)
		var size_lbl: String = str(loc.get("map_size_label", "Standard"))
		var start_b := FacilityCatalog.format_money(int(loc.get("starting_budget", 200000)))
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(215, 102)
		btn.text = "%s\n[%s]\n%s | %s\nBudget: %s" % [loc["name"], loc["region"], size_lbl, diff_txt, start_b]
		var idx := i
		btn.pressed.connect(func() -> void: _select_location_preview(idx))
		loc_cards_box.add_child(btn)
		location_card_buttons.append(btn)

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

	var diff_lvl: int = int(loc.get("difficulty", 1))
	var size_lbl: String = str(loc.get("map_size_label", "Standard"))
	if loc_detail_title:
		loc_detail_title.text = "%s — %s" % [loc["name"], loc["region"]]
	if loc_detail_badge:
		loc_detail_badge.text = "Size: %s  |  Difficulty: %s" % [size_lbl, LocationCatalog.difficulty_text(diff_lvl)]
		loc_detail_badge.modulate = LocationCatalog.difficulty_color(diff_lvl).lightened(0.25)
	if loc_detail_desc:
		loc_detail_desc.text = str(loc.get("description", ""))
	if loc_detail_rule:
		loc_detail_rule.text = "Scenario Rule: " + str(loc.get("rule", ""))

	for i in range(location_card_buttons.size()):
		var b := location_card_buttons[i]
		b.modulate = Color(1.0, 0.92, 0.65) if i == selected_location_index else Color.WHITE

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

func _process(delta: float) -> void:
	_update_floating_popups(delta)
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
	return clampf(base_spawn_interval / (1.0 + (reputation - 1.0) * 0.48), 1.0, base_spawn_interval)

func get_current_set_bounds() -> Vector2i:
	if reputation < 1.25:
		return Vector2i(1, 1)
	var min_s := clampi(1 + int((reputation - 1.0) * 0.38), 1, 4)
	var max_s := clampi(1 + int((reputation - 1.0) * 0.95), 2, 10)
	return Vector2i(min_s, maxi(min_s, max_s))

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
	last_ledger_summary = ""

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
	_select_build_tool(FacilityCatalog.ItemId.PATH_TILE)
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

# --- Daily Financial Settlement & Scheduled Drafts ---

func get_daily_staff_payroll() -> int:
	var total := 0
	for stf in active_staff:
		if not is_instance_valid(stf):
			continue
		var info := FacilityCatalog.get_staff_info(int(stf.staff_type))
		total += int(info.get("daily_wage", 1000))
	return total

func calculate_daily_city_grant() -> int:
	var loc: Dictionary = locations_list[selected_location_index]
	var mult := float(loc.get("grant_multiplier", 1.0))
	var hap_factor := pow(clampf(happiness / 100.0, 0.0, 1.0), 1.2)
	var raw_grant := (8000.0 + 3500.0 * reputation) * hap_factor * mult
	return roundi(raw_grant)

func _advance_day() -> void:
	var city_grant := calculate_daily_city_grant()
	var staff_wages := get_daily_staff_payroll()
	var net_change := city_grant - staff_wages
	grid_manager.add_money(net_change)
	daily_service_income = 0

	day_index += 1
	if day_index >= 7:
		day_index = 0
		week_number += 1

	if day_index == 3 or (day_index == 0 and week_number >= 2):
		_trigger_upgrade_draft()
	elif day_index == 2 or day_index == 5:
		_trigger_special_perk_draft()

	_update_stats_ui()
	_update_clock_ui()

func _trigger_upgrade_draft() -> void:
	is_drafting = true
	last_unpaused_speed = sim_speed if sim_speed > 0.0 else 1.0
	_set_sim_speed(0.0)
	grid_manager.interaction_enabled = false

	var day_str: String = "Monday" if day_index == 0 else "Thursday"
	draft_title_label.text = "%s — Select a Facility & Expansion Upgrade" % day_str
	draft_choices.clear()

	var pool: Array[Dictionary] = [
		{"type": "grant", "name": "City Treasury Grant", "desc": "+$25,000 Plaza Budget\n+4 Free Walk Tile Vouchers", "cash": 25000, "item": FacilityCatalog.ItemId.PATH_TILE, "count": 4},
		{"type": "gates", "name": "Gate & Barrier Pack", "desc": "+1 Free Entry Gate & +1 Free Exit Gate\n+6 Free Fence Vouchers", "cash": 5000, "item": FacilityCatalog.ItemId.ENTRY_GATE, "count": 1, "extra_item": FacilityCatalog.ItemId.EXIT_GATE, "extra_count": 1},
		{"type": "food", "name": "Culinary Festival Pack", "desc": "+1 Free Food Shop Voucher\n+$12,000 Plaza Budget", "cash": 12000, "item": FacilityCatalog.ItemId.FOOD_SHOP, "count": 1},
		{"type": "drink", "name": "Refreshment Stand Pack", "desc": "+1 Free Drink Stall Voucher\n+$15,000 Plaza Budget", "cash": 15000, "item": FacilityCatalog.ItemId.DRINK_STALL, "count": 1},
		{"type": "service", "name": "Civic Sanitation Pack", "desc": "+1 Free Restroom Voucher\n+2 Free Trashcan Vouchers", "cash": 6000, "item": FacilityCatalog.ItemId.RESTROOM, "count": 1, "extra_item": FacilityCatalog.ItemId.TRASHCAN, "extra_count": 2},
		{"type": "comfort", "name": "Park Comfort Pack", "desc": "+1 Free Picnic Table Voucher\n+2 Free Park Bench Vouchers", "cash": 6000, "item": FacilityCatalog.ItemId.PICNIC_TABLE, "count": 1, "extra_item": FacilityCatalog.ItemId.BENCH, "extra_count": 2}
	]
	_present_draft_cards(pool, Color(0.95, 0.98, 1.0))

func _trigger_special_perk_draft() -> void:
	is_drafting = true
	last_unpaused_speed = sim_speed if sim_speed > 0.0 else 1.0
	_set_sim_speed(0.0)
	grid_manager.interaction_enabled = false

	var day_str: String = "Wednesday" if day_index == 2 else "Saturday"
	draft_title_label.text = "✨ %s — Select a Special Perk or Prize Card! ✨" % day_str
	draft_choices.clear()

	var special_pool: Array[Dictionary] = [
		{"type": "special_cash_10k", "name": "★ Prize: Civic Bonus", "desc": "Receive $10,000 instant Plaza Budget!", "cash": 10000},
		{"type": "special_cash_18k", "name": "★ Prize: Patron Donation", "desc": "Receive $18,000 from a generous local sponsor!", "cash": 18000},
		{"type": "special_benches", "name": "★ Prize: Park Seating Gift", "desc": "Free 2 Park Benches\n+2 Free Walk Tiles!", "item": FacilityCatalog.ItemId.BENCH, "count": 2, "extra_item": FacilityCatalog.ItemId.PATH_TILE, "extra_count": 2},
		{"type": "special_paths", "name": "★ Prize: Stone Paver Shipment", "desc": "Free 8 Walk Tiles for expanding your plaza!", "item": FacilityCatalog.ItemId.PATH_TILE, "count": 8},
		{"type": "special_clean", "name": "★ Perk: Clean Streets Drive", "desc": "Free 2 Trashcans & 2 Lamp Posts\n+ Cleans all current floor trash!", "item": FacilityCatalog.ItemId.TRASHCAN, "count": 2, "extra_item": FacilityCatalog.ItemId.LAMP_POST, "extra_count": 2, "clean_all_trash": true},
		{"type": "special_janitor", "name": "★ Perk: Volunteer Janitor", "desc": "Recruit 1 Janitor immediately (Free Hire)\n+ Receive $5,000!", "cash": 5000, "free_staff": FacilityCatalog.StaffId.JANITOR},
		{"type": "special_tips", "name": "★ Perk: Gourmet Reputation", "desc": "All Paid Service Facilities earn +25% more income permanently!", "income_mult_bonus": 0.25},
		{"type": "special_festival", "name": "★ Perk: Street Music Festival", "desc": "Restore +25% Plaza Happiness\n+ Boost Reputation by +0.50 ★!", "happiness_bonus": 25.0, "reputation_bonus": 0.50}
	]
	_present_draft_cards(special_pool, Color(1.0, 0.93, 0.65))

func _present_draft_cards(pool: Array[Dictionary], tint: Color) -> void:
	pool.shuffle()
	for child in draft_cards_box.get_children():
		child.queue_free()

	for i in range(3):
		var card_data: Dictionary = pool[i % pool.size()].duplicate()
		draft_choices.append(card_data)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(220, 154)
		btn.modulate = tint
		btn.text = "%s\n\n%s" % [card_data["name"], card_data["desc"]]
		var idx := i
		btn.pressed.connect(func() -> void: _on_draft_card_selected(idx))
		draft_cards_box.add_child(btn)

	draft_modal.visible = true

func _on_draft_card_selected(index: int) -> void:
	if index >= 0 and index < draft_choices.size():
		var chosen: Dictionary = draft_choices[index]
		var cash_bonus := int(chosen.get("cash", 0))
		if cash_bonus > 0:
			grid_manager.add_money(cash_bonus)
		if chosen.has("item"):
			grid_manager.add_inventory_item(int(chosen["item"]), int(chosen.get("count", 1)))
		if chosen.has("extra_item"):
			grid_manager.add_inventory_item(int(chosen["extra_item"]), int(chosen.get("extra_count", 1)))
		if bool(chosen.get("clean_all_trash", false)):
			grid_manager.clear_all_trash()
		if chosen.has("free_staff"):
			hire_staff(int(chosen["free_staff"]), true)
		if chosen.has("income_mult_bonus"):
			service_income_multiplier += float(chosen["income_mult_bonus"])
		if chosen.has("happiness_bonus"):
			happiness = clampf(happiness + float(chosen["happiness_bonus"]), 0.0, 100.0)
		if chosen.has("reputation_bonus"):
			reputation += float(chosen["reputation_bonus"])
			peak_reputation = maxf(peak_reputation, reputation)

	draft_modal.visible = false
	is_drafting = false
	grid_manager.interaction_enabled = true
	_set_sim_speed(last_unpaused_speed)
	_update_stats_ui()
	_update_dock_ui()

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
	var r := randf()
	if r < 0.42:
		return PeepAgent.Archetype.NORMAL
	elif r < 0.58:
		return PeepAgent.Archetype.ELDER
	elif r < 0.74:
		return PeepAgent.Archetype.BUSINESS
	elif r < 0.87:
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
		var cost := float(candidate_route.size()) + float(stall.waiting_peeps.size()) * 3.2
		if cost < best_cost:
			best_cost = cost
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
	if randf() < 0.65:
		grid_manager.spawn_trash_on_tile(tile_coords)
		_ApplyLitterPenaltyCheck(tile_coords)

func _ApplyLitterPenaltyCheck(tile_coords: Vector2i) -> void:
	if grid_manager.get_trash_count_on_tile(tile_coords) >= 3:
		_apply_happiness_penalty(1.5)

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
		happiness = minf(100.0, happiness + 0.5)
		_update_stats_ui()

func _on_staff_guided_peep(_peep: PeepAgent) -> void:
	happiness = minf(100.0, happiness + 1.5)
	_update_stats_ui()

# --- Facility & Citizen Callbacks ---

func _on_facility_placed(stall_node: Node3D) -> void:
	if stall_node is StallController:
		var stall := stall_node as StallController
		registered_stalls.append(stall)
		stall.peep_served.connect(_on_peep_served)
		stall.peep_frustrated.connect(_on_peep_frustrated_at_stall)
		_recalculate_all_peep_routes()

func _on_facility_removed(stall_node: Node3D) -> void:
	if stall_node is StallController:
		registered_stalls.erase(stall_node as StallController)
		_recalculate_all_peep_routes()

func _on_peep_served(_peep: Node3D, revenue: int, _stall: Node3D) -> void:
	satisfied_patrons += 1
	reputation += 0.06
	peak_reputation = maxf(peak_reputation, reputation)
	happiness = minf(100.0, happiness + 1.8)

	if revenue > 0:
		var final_rev := int(roundf(float(revenue) * service_income_multiplier))
		daily_service_income += final_rev
		grid_manager.add_money(final_rev)

	_update_stats_ui()

func _on_peep_exited_happy_passthrough(_peep: PeepAgent) -> void:
	satisfied_patrons += 1
	reputation += 0.02
	peak_reputation = maxf(peak_reputation, reputation)
	happiness = minf(100.0, happiness + 0.5)
	_update_stats_ui()

func _on_peep_frustrated_at_stall(_peep: Node3D) -> void:
	_apply_happiness_penalty(12.0)

func _on_peep_exited_unfulfilled(peep: PeepAgent) -> void:
	var penalty := 12.0 if (is_instance_valid(peep) and peep.archetype == PeepAgent.Archetype.BUSINESS) else 8.5
	_apply_happiness_penalty(penalty)

func _apply_happiness_penalty(amount: float) -> void:
	if is_game_over:
		return
	happiness = maxf(0.0, happiness - amount)
	_update_stats_ui()
	if happiness <= 0.0:
		_trigger_game_over()

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

	for item_id in item_buttons.keys():
		var btn: Button = item_buttons[item_id]
		var info := FacilityCatalog.get_item(item_id)
		var cat: int = int(info.get("category", 0))
		btn.visible = (selected_category == cat)

		var vouchers := int(inv.get(item_id, 0))
		var cost := int(info.get("cost", 0))
		if item_id == FacilityCatalog.ItemId.ERASE_TOOL:
			btn.text = "Demolish"
		elif vouchers > 0:
			btn.text = "%s\nx%d" % [info["name"], vouchers]
		else:
			btn.text = "%s\n%s" % [info["name"], FacilityCatalog.format_money(cost)]

		btn.modulate = Color(0.65, 0.98, 0.72) if cur == item_id else Color.WHITE

	var counts: Dictionary = {0: 0, 1: 0, 2: 0}
	for stf in active_staff:
		if is_instance_valid(stf):
			counts[int(stf.staff_type)] = int(counts.get(int(stf.staff_type), 0)) + 1

	for staff_id in staff_buttons.keys():
		var sbtn: Button = staff_buttons[staff_id]
		var sinfo := FacilityCatalog.get_staff_info(staff_id)
		sbtn.visible = (selected_category == FacilityCatalog.Category.STAFF)
		var wage_str := FacilityCatalog.format_money(int(sinfo.get("daily_wage", 1000)))
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
		"HUD/StartMenuPanel/Panel",
		"HUD/LocationSelectPanel/Panel",
		"HUD/OptionsPanel/Panel",
		"HUD/DraftModal/Panel",
		"HUD/GameOverPanel/Panel"
	]:
		if has_node(panel_path):
			var pc := get_node(panel_path) as PanelContainer
			if pc:
				pc.add_theme_stylebox_override("panel", card_style)

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
