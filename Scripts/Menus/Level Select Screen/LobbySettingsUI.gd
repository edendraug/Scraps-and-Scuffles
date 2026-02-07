extends Control
class_name LobbySettingsUI

# === MATCH SETTINGS UI ===
@export_group("Match Settings Controls")
@export var game_mode_option: OptionButton
@export var hill_radius_slider: HSlider
@export var hill_radius_value_label: Label
@export var hill_relocation_slider: HSlider
@export var hill_relocation_value_label: Label
@export var win_condition_option: OptionButton  # 0 = Highest Score, 1 = First to Target
@export var score_target_spinbox: SpinBox
@export var time_limit_spinbox: SpinBox

# === SPAWN SETTINGS UI ===
@export_group("Spawn Settings Controls")
@export var starting_buildings_spinbox: SpinBox
@export var max_buildings_spinbox: SpinBox
@export var min_spawn_interval_spinbox: SpinBox
@export var max_spawn_interval_spinbox: SpinBox
@export var wood_weight_slider: HSlider
@export var wood_weight_value_label: Label
@export var stone_weight_slider: HSlider
@export var stone_weight_value_label: Label
@export var energy_weight_slider: HSlider
@export var energy_weight_value_label: Label

# === BUTTONS ===
@export_group("Buttons")
@export var apply_button: Button
@export var reset_button: Button
@export var close_button: Button
@export var open_preset_dialogue_panel_button: Button
@export var cancel_preset_dialogue_panel_button: Button
@export var save_preset_button: Button
@export var load_preset_button: Button

# === PRESET MANAGEMENT ===
@export_group("Preset Management")
@export var preset_dialogue_panel: Control
@export var preset_name_input: LineEdit
@export var preset_list: ItemList

# References
var match_settings: MatchSettings
var spawn_settings: SpawnSettings

# Preset storage
const PRESETS_DIR = "user://settings_presets/"
const PRESETS_FILE = "user://settings_presets/presets.json"

func _ready():
	# Get references to settings from GameSettings
	match_settings = GameSettings.match_settings
	spawn_settings = GameSettings.spawn_settings
	if preset_dialogue_panel:
		preset_dialogue_panel.hide()
	# Ensure presets directory exists
	ensure_presets_directory()
	
	# Connect all UI controls
	connect_signals()
	
	# Populate UI with current settings
	load_settings_to_ui()
	
	# Load preset list
	refresh_preset_list()

func connect_signals():
	# Match Settings
	if game_mode_option:
		game_mode_option.item_selected.connect(_on_game_mode_changed)
	if hill_radius_slider:
		hill_radius_slider.value_changed.connect(_on_hill_radius_changed)
	if hill_relocation_slider:
		hill_relocation_slider.value_changed.connect(_on_hill_relocation_changed)
	if win_condition_option:
		win_condition_option.item_selected.connect(_on_win_condition_changed)
	if score_target_spinbox:
		score_target_spinbox.value_changed.connect(_on_score_target_changed)
	if time_limit_spinbox:
		time_limit_spinbox.value_changed.connect(_on_time_limit_changed)
	
	# Spawn Settings
	if starting_buildings_spinbox:
		starting_buildings_spinbox.value_changed.connect(_on_starting_buildings_changed)
	if max_buildings_spinbox:
		max_buildings_spinbox.value_changed.connect(_on_max_buildings_changed)
	if min_spawn_interval_spinbox:
		min_spawn_interval_spinbox.value_changed.connect(_on_min_spawn_interval_changed)
	if max_spawn_interval_spinbox:
		max_spawn_interval_spinbox.value_changed.connect(_on_max_spawn_interval_changed)
	if wood_weight_slider:
		wood_weight_slider.value_changed.connect(_on_wood_weight_changed)
	if stone_weight_slider:
		stone_weight_slider.value_changed.connect(_on_stone_weight_changed)
	if energy_weight_slider:
		energy_weight_slider.value_changed.connect(_on_energy_weight_changed)
	
	# Buttons
	if apply_button:
		apply_button.pressed.connect(_on_apply_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if open_preset_dialogue_panel_button:
		open_preset_dialogue_panel_button.pressed.connect(_on_open_preset_dialogue_pressed)
	if cancel_preset_dialogue_panel_button:
		cancel_preset_dialogue_panel_button.pressed.connect(_on_cancel_preset_dialogue_pressed)
	if save_preset_button:
		save_preset_button.pressed.connect(_on_save_preset_pressed)
	if load_preset_button:
		load_preset_button.pressed.connect(_on_load_preset_pressed)
	if preset_list:
		preset_list.item_activated.connect(_on_preset_double_clicked)

func load_settings_to_ui():
	# === MATCH SETTINGS ===
	if game_mode_option:
		game_mode_option.selected = match_settings.game_mode
	
	if hill_radius_slider:
		hill_radius_slider.value = match_settings.hill_radius
		update_hill_radius_label(match_settings.hill_radius)
	
	if hill_relocation_slider:
		hill_relocation_slider.value = match_settings.hill_relocate_interval
		update_hill_relocation_label(match_settings.hill_relocate_interval)
	
	if win_condition_option:
		# Determine which win condition option to show
		if match_settings.use_score_target and match_settings.use_time_limit:
			win_condition_option.selected = 0  # Both (Highest score at time limit)
		elif match_settings.use_score_target:
			win_condition_option.selected = 1  # First to target
		else:
			win_condition_option.selected = 0  # Time limit only
	
	if score_target_spinbox:
		score_target_spinbox.value = match_settings.score_target
	
	if time_limit_spinbox:
		time_limit_spinbox.value = match_settings.time_limit_minutes
	
	# === SPAWN SETTINGS ===
	if starting_buildings_spinbox:
		starting_buildings_spinbox.value = spawn_settings.initial_spawn_count
	
	if max_buildings_spinbox:
		max_buildings_spinbox.value = spawn_settings.max_natural_buildings
	
	if min_spawn_interval_spinbox:
		min_spawn_interval_spinbox.value = spawn_settings.spawn_interval_min
	
	if max_spawn_interval_spinbox:
		max_spawn_interval_spinbox.value = spawn_settings.spawn_interval_max
	
	if wood_weight_slider:
		wood_weight_slider.value = spawn_settings.wood_weight
		update_wood_weight_label(spawn_settings.wood_weight)
	
	if stone_weight_slider:
		stone_weight_slider.value = spawn_settings.stone_weight
		update_stone_weight_label(spawn_settings.stone_weight)
	
	if energy_weight_slider:
		energy_weight_slider.value = spawn_settings.energy_weight
		update_energy_weight_label(spawn_settings.energy_weight)

# === MATCH SETTINGS CALLBACKS ===
func _on_game_mode_changed(index: int):
	match_settings.game_mode = index as MatchSettings.GameModeType
	print("Game mode changed to: ", MatchSettings.GameModeType.keys()[index])

func _on_hill_radius_changed(value: float):
	match_settings.hill_radius = value
	update_hill_radius_label(value)

func _on_hill_relocation_changed(value: float):
	match_settings.hill_relocate_interval = value
	update_hill_relocation_label(value)

func _on_win_condition_changed(index: int):
	match index:
		0:  # Highest Score (time limit only)
			match_settings.use_score_target = false
			match_settings.use_time_limit = true
		1:  # First to Target Score
			match_settings.use_score_target = true
			match_settings.use_time_limit = false
		2:  # Both (if you add this option)
			match_settings.use_score_target = true
			match_settings.use_time_limit = true

func _on_score_target_changed(value: float):
	match_settings.score_target = int(value)

func _on_time_limit_changed(value: float):
	match_settings.time_limit_minutes = value

# === SPAWN SETTINGS CALLBACKS ===
func _on_starting_buildings_changed(value: float):
	spawn_settings.initial_spawn_count = int(value)

func _on_max_buildings_changed(value: float):
	spawn_settings.max_natural_buildings = int(value)

func _on_min_spawn_interval_changed(value: float):
	spawn_settings.spawn_interval_min = value

func _on_max_spawn_interval_changed(value: float):
	spawn_settings.spawn_interval_max = value

func _on_wood_weight_changed(value: float):
	spawn_settings.wood_weight = value
	update_wood_weight_label(value)

func _on_stone_weight_changed(value: float):
	spawn_settings.stone_weight = value
	update_stone_weight_label(value)

func _on_energy_weight_changed(value: float):
	spawn_settings.energy_weight = value
	update_energy_weight_label(value)

# === LABEL UPDATES ===
func update_hill_radius_label(value: float):
	if hill_radius_value_label:
		hill_radius_value_label.text = str(int(value))

func update_hill_relocation_label(value: float):
	if hill_relocation_value_label:
		hill_relocation_value_label.text = str(int(value)) + "s"

func update_wood_weight_label(value: float):
	if wood_weight_value_label:
		var weights = spawn_settings.get_normalized_weights()
		wood_weight_value_label.text = str(int(weights.wood * 100)) + "%"

func update_stone_weight_label(value: float):
	if stone_weight_value_label:
		var weights = spawn_settings.get_normalized_weights()
		stone_weight_value_label.text = str(int(weights.stone * 100)) + "%"

func update_energy_weight_label(value: float):
	if energy_weight_value_label:
		var weights = spawn_settings.get_normalized_weights()
		energy_weight_value_label.text = str(int(weights.energy * 100)) + "%"

# === BUTTON CALLBACKS ===
func _on_apply_pressed():
	print("Settings applied!")
	GameSettings.settings_changed.emit()
	# Close the settings UI
	_on_close_pressed()

func _on_reset_pressed():
	print("Resetting to default settings...")
	match_settings.reset_to_defaults()
	spawn_settings.reset_to_defaults()
	load_settings_to_ui()
	print("Settings reset!")

func _on_close_pressed():
	# Tell SettingsTerminal to close
	var terminal = get_parent().get_parent()  # Adjust based on your scene hierarchy
	if terminal and terminal.has_method("close_terminal"):
		terminal.close_terminal()

# === PRESET MANAGEMENT ===

func ensure_presets_directory():
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("settings_presets"):
		dir.make_dir("settings_presets")
		print("Created presets directory")

func _on_open_preset_dialogue_pressed():
	if not open_preset_dialogue_panel_button:
		return
	
	preset_dialogue_panel.show()

func _on_cancel_preset_dialogue_pressed():
	if not cancel_preset_dialogue_panel_button:
		return
	
	preset_dialogue_panel.hide()

func _on_save_preset_pressed():
	if not preset_name_input or preset_name_input.text.strip_edges().is_empty():
		print("Error: Please enter a preset name")
		return
	
	var preset_name = preset_name_input.text.strip_edges()
	save_preset(preset_name)
	refresh_preset_list()
	preset_name_input.text = ""

func _on_load_preset_pressed():
	if not preset_list or preset_list.get_selected_items().is_empty():
		print("Error: Please select a preset to load")
		return
	
	var selected_index = preset_list.get_selected_items()[0]
	var preset_name = preset_list.get_item_text(selected_index)
	load_preset(preset_name)

func _on_preset_double_clicked(index: int):
	# Load preset when double-clicked
	var preset_name = preset_list.get_item_text(index)
	load_preset(preset_name)

func save_preset(preset_name: String):
	# Create preset data
	var preset_data = {
		"match_settings": {
			"game_mode": match_settings.game_mode,
			"score_target": match_settings.score_target,
			"time_limit_minutes": match_settings.time_limit_minutes,
			"use_score_target": match_settings.use_score_target,
			"use_time_limit": match_settings.use_time_limit,
			"hill_radius": match_settings.hill_radius,
			"hill_relocate_interval": match_settings.hill_relocate_interval
		},
		"spawn_settings": {
			"initial_spawn_count": spawn_settings.initial_spawn_count,
			"max_natural_buildings": spawn_settings.max_natural_buildings,
			"spawn_interval_min": spawn_settings.spawn_interval_min,
			"spawn_interval_max": spawn_settings.spawn_interval_max,
			"wood_weight": spawn_settings.wood_weight,
			"stone_weight": spawn_settings.stone_weight,
			"energy_weight": spawn_settings.energy_weight
		}
	}
	
	# Save to file
	var file_path = PRESETS_DIR + preset_name + ".json"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(preset_data, "\t"))
		file.close()
		print("Preset '", preset_name, "' saved successfully!")
	else:
		push_error("Failed to save preset: ", FileAccess.get_open_error())

func load_preset(preset_name: String):
	var file_path = PRESETS_DIR + preset_name + ".json"
	
	if not FileAccess.file_exists(file_path):
		push_error("Preset file not found: ", file_path)
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open preset file: ", FileAccess.get_open_error())
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse preset JSON: ", json.get_error_message())
		return
	
	var preset_data = json.data
	
	# Apply match settings
	if preset_data.has("match_settings"):
		var ms = preset_data.match_settings
		match_settings.game_mode = ms.game_mode
		match_settings.score_target = ms.score_target
		match_settings.time_limit_minutes = ms.time_limit_minutes
		match_settings.use_score_target = ms.use_score_target
		match_settings.use_time_limit = ms.use_time_limit
		match_settings.hill_radius = ms.hill_radius
		match_settings.hill_relocate_interval = ms.hill_relocate_interval
	
	# Apply spawn settings
	if preset_data.has("spawn_settings"):
		var ss = preset_data.spawn_settings
		spawn_settings.initial_spawn_count = ss.initial_spawn_count
		spawn_settings.max_natural_buildings = ss.max_natural_buildings
		spawn_settings.spawn_interval_min = ss.spawn_interval_min
		spawn_settings.spawn_interval_max = ss.spawn_interval_max
		spawn_settings.wood_weight = ss.wood_weight
		spawn_settings.stone_weight = ss.stone_weight
		spawn_settings.energy_weight = ss.energy_weight
	
	# Refresh UI to show loaded settings
	load_settings_to_ui()
	
	print("Preset '", preset_name, "' loaded successfully!")

func refresh_preset_list():
	if not preset_list:
		return
	
	preset_list.clear()
	
	var dir = DirAccess.open(PRESETS_DIR)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json"):
			# Remove .json extension for display
			var preset_name = file_name.get_basename()
			preset_list.add_item(preset_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	print("Preset list refreshed - found ", preset_list.item_count, " presets")
