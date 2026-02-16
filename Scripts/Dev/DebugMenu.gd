# DebugMenu.gd
extends CanvasLayer
class_name DebugMenu

## Debug menu for testing - Press F3 to toggle

# Player spawning
var player_scene: PackedScene = preload("res://Scenes/Player/Player.tscn")
var character_data_resources: Array[Resource] = []
var awaiting_spawn_click: bool = false
var pending_spawn_player_id: int = -1
var pending_spawn_character_data: Resource = null

var panel: PanelContainer
var is_visible: bool = false

# References
var game_mode_manager: Node = null
var players: Array[Node] = []
var resource_spawner: Node = null

# UI Elements
var player_id_spin: SpinBox
var character_select: OptionButton
var resource_player_select: OptionButton
var resource_type_select: OptionButton
var resource_amount_spin: SpinBox
var time_scale_slider: HSlider
var time_scale_label: Label
var spawn_resource_select: OptionButton

func _ready() -> void:
	load_character_data()
	build_ui()
	hide_menu()
	refresh_references()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		toggle_menu()

func _unhandled_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.pressed:
		#print("Mouse click detected in _unhandled_input")
	
	# Handle spawn click
	if awaiting_spawn_click:
		#print("Awaiting spawn click is true")
		if event is InputEventMouseButton:
			#print("Mouse button event detected")
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				#print("Left click confirmed, spawning...")
				var world_pos = get_viewport().get_camera_2d().get_global_mouse_position()
				spawn_player_at_position(world_pos)
				awaiting_spawn_click = false
				get_viewport().set_input_as_handled()

func load_character_data() -> void:
	# Scan the Characters folder for all .tres files
	var dir = DirAccess.open("res://Resources/Characters/")
	if not dir:
		#print("ERROR: Could not open Characters folder")
		return
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var resource_path = "res://Resources/Characters/" + file_name
				var character_data = load(resource_path)
				if character_data:
					character_data_resources.append(character_data)
					print("Loaded character: ", file_name)
				else:
					print("Failed to load: ", resource_path)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	print("Loaded %d character data resources" % character_data_resources.size())

func build_ui() -> void:
	# Main panel
	panel = PanelContainer.new()
	panel.position = Vector2(20, 20)
	panel.size = Vector2(400, 600)
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(380, 580)
	margin.add_child(scroll)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(main_vbox)
	
	# Title
	var title = Label.new()
	title.text = "DEBUG MENU (F3 to toggle)"
	title.add_theme_font_size_override("font_size", 18)
	main_vbox.add_child(title)
	
	add_separator(main_vbox)
	
	# === PLAYER SPAWNING ===
	add_section_header(main_vbox, "Spawn Player")
	
	var spawn_hbox = HBoxContainer.new()
	spawn_hbox.add_theme_constant_override("separation", 5)
	main_vbox.add_child(spawn_hbox)
	
	spawn_hbox.add_child(Label.new())
	spawn_hbox.get_child(-1).text = "ID:"
	
	player_id_spin = SpinBox.new()
	player_id_spin.min_value = 1
	player_id_spin.max_value = 4
	player_id_spin.value = 1
	player_id_spin.custom_minimum_size.x = 60
	spawn_hbox.add_child(player_id_spin)
	
	character_select = OptionButton.new()
	for i in character_data_resources.size():
		var char_data = character_data_resources[i]
		#var display_name = char_data.get("character_name") if char_data.get("character_name") else "Character %d" % (i + 1)
		var display_name = "Character %d" % (i + 1)
		if "character_name" in char_data:
			display_name = char_data.character_name
		character_select.add_item(display_name)
	spawn_hbox.add_child(character_select)
	
	var spawn_btn = Button.new()
	spawn_btn.text = "Spawn at Mouse"
	spawn_btn.pressed.connect(_on_spawn_player)
	spawn_hbox.add_child(spawn_btn)
	
	add_separator(main_vbox)
	
	# === RESOURCE MANAGEMENT ===
	add_section_header(main_vbox, "Modify Player Resources")
	
	var resource_hbox = HBoxContainer.new()
	resource_hbox.add_theme_constant_override("separation", 5)
	main_vbox.add_child(resource_hbox)
	
	resource_player_select = OptionButton.new()
	resource_player_select.custom_minimum_size.x = 80
	resource_hbox.add_child(resource_player_select)
	
	resource_type_select = OptionButton.new()
	resource_type_select.add_item("wood")
	resource_type_select.add_item("stone")
	resource_type_select.add_item("energy")
	resource_hbox.add_child(resource_type_select)
	
	resource_amount_spin = SpinBox.new()
	resource_amount_spin.min_value = -99
	resource_amount_spin.max_value = 99
	resource_amount_spin.value = 10
	resource_amount_spin.custom_minimum_size.x = 70
	resource_hbox.add_child(resource_amount_spin)
	
	var apply_resource_btn = Button.new()
	apply_resource_btn.text = "Apply"
	apply_resource_btn.pressed.connect(_on_modify_resources)
	resource_hbox.add_child(apply_resource_btn)
	
	var refresh_btn = Button.new()
	refresh_btn.text = "Refresh Players"
	refresh_btn.pressed.connect(refresh_references)
	main_vbox.add_child(refresh_btn)
	
	add_separator(main_vbox)
	
	# === GAME SPEED ===
	add_section_header(main_vbox, "Time Scale")
	
	var speed_hbox = HBoxContainer.new()
	main_vbox.add_child(speed_hbox)
	
	time_scale_slider = HSlider.new()
	time_scale_slider.min_value = 0.1
	time_scale_slider.max_value = 5.0
	time_scale_slider.step = 0.1
	time_scale_slider.value = 1.0
	time_scale_slider.custom_minimum_size.x = 200
	time_scale_slider.value_changed.connect(_on_time_scale_changed)
	speed_hbox.add_child(time_scale_slider)
	
	time_scale_label = Label.new()
	time_scale_label.text = "1.0x"
	time_scale_label.custom_minimum_size.x = 50
	speed_hbox.add_child(time_scale_label)
	
	var reset_speed_btn = Button.new()
	reset_speed_btn.text = "Reset"
	reset_speed_btn.pressed.connect(func(): time_scale_slider.value = 1.0)
	speed_hbox.add_child(reset_speed_btn)
	
	add_separator(main_vbox)
	
	# === MATCH CONTROL ===
	add_section_header(main_vbox, "Match Control")
	
	var match_hbox = HBoxContainer.new()
	match_hbox.add_theme_constant_override("separation", 5)
	main_vbox.add_child(match_hbox)
	
	var end_score_btn = Button.new()
	end_score_btn.text = "End (Score)"
	end_score_btn.pressed.connect(func(): force_match_end("score"))
	match_hbox.add_child(end_score_btn)
	
	var end_time_btn = Button.new()
	end_time_btn.text = "End (Time)"
	end_time_btn.pressed.connect(func(): force_match_end("time"))
	match_hbox.add_child(end_time_btn)
	
	var toggle_spawn_check = CheckButton.new()
	toggle_spawn_check.text = "Stop Resource Spawning"
	toggle_spawn_check.toggled.connect(_on_toggle_resource_spawning)
	main_vbox.add_child(toggle_spawn_check)
	
	var clear_buildings_btn = Button.new()
	clear_buildings_btn.text = "Clear All Buildings"
	clear_buildings_btn.pressed.connect(clear_all_buildings)
	main_vbox.add_child(clear_buildings_btn)
	
	add_separator(main_vbox)
	
	# === RESOURCE SPAWNING ===
	add_section_header(main_vbox, "Spawn Resources")
	
	var spawn_resource_hbox = HBoxContainer.new()
	spawn_resource_hbox.add_theme_constant_override("separation", 5)
	main_vbox.add_child(spawn_resource_hbox)
	
	spawn_resource_select = OptionButton.new()
	spawn_resource_select.add_item("Wood")
	spawn_resource_select.add_item("Stone")
	spawn_resource_hbox.add_child(spawn_resource_select)
	
	var spawn_resource_btn = Button.new()
	spawn_resource_btn.text = "Spawn at Mouse"
	spawn_resource_btn.pressed.connect(_on_spawn_resource)
	spawn_resource_hbox.add_child(spawn_resource_btn)

func add_section_header(parent: VBoxContainer, text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	parent.add_child(label)

func add_separator(parent: VBoxContainer) -> void:
	var sep = HSeparator.new()
	parent.add_child(sep)

func toggle_menu() -> void:
	is_visible = !is_visible
	if is_visible:
		show_menu()
	else:
		hide_menu()

func show_menu() -> void:
	panel.show()
	refresh_references()

func hide_menu() -> void:
	panel.hide()

func refresh_references() -> void:
	players.clear()
	
	game_mode_manager = get_tree().get_first_node_in_group("game_mode_manager")
	print("Found GameModeManager: ", game_mode_manager)
	
	for node in get_tree().get_nodes_in_group("Players"):
		players.append(node)
	print("Found %d players: " % players.size(), players)
	
	resource_spawner = get_tree().get_first_node_in_group("resource_spawner")
	print("Found ResourceSpawner: ", resource_spawner)
	
	update_player_dropdown()

func update_player_dropdown() -> void:
	resource_player_select.clear()
	for player in players:
		resource_player_select.add_item("Player %d" % player.player_id)

# === SIGNAL HANDLERS ===

func _on_spawn_player() -> void:
	var player_id = int(player_id_spin.value)
	var character_index = character_select.selected
	
	if character_index < 0 or character_index >= character_data_resources.size():
		print("Invalid character selection")
		return
	
	pending_spawn_player_id = player_id
	pending_spawn_character_data = character_data_resources[character_index]
	awaiting_spawn_click = true
	
	
	print ("Click anywhere to spawn Player %d..." % player_id)

func spawn_player_at_position(world_pos: Vector2) -> void:
	var player_id = pending_spawn_player_id
	
	# Register player though GameSettings
	if not GameSettings.join_player(player_id, -1):
		print("ERROR: Player ID %d is already registered or failed to join" % player_id)
		return
	
	# Now instantiate and spawn the player
	var player = player_scene.instantiate()
	player.player_id = player_id
	player.global_position = world_pos
	
	# Add to level (current scene)
	get_tree().current_scene.add_child(player)
	if player.has_node("SpriteManager"):
		print("Player has SpriteManager")
		var sprite_manager = player.get_node("SpriteManager")
		if sprite_manager:
			print("SpriteManager assigned")
			if sprite_manager.has_method("set_sprite_sheet"):
				sprite_manager.set_sprite_sheet(pending_spawn_character_data.sprite_sheet)
				print("Sprite Sheet ", pending_spawn_character_data.sprite_sheet, " assigned")
	# Add to players group
	player.add_to_group("Players")
	
	print("Spawned Player %d at %v" % [player_id, world_pos])
	
	# Refresh to update player lists
	call_deferred("refresh_references")

func _on_modify_resources() -> void:
	if resource_player_select.selected == -1 or players.is_empty():
		return
	
	var player = players[resource_player_select.selected]
	var resource_type = resource_type_select.get_item_text(resource_type_select.selected)
	var amount = int(resource_amount_spin.value)
	
	modify_player_resources(player, resource_type, amount)

func _on_time_scale_changed(value: float) -> void:
	Engine.time_scale = value
	time_scale_label.text = "%.1fx" % value

func _on_toggle_resource_spawning(enabled: bool) -> void:
	toggle_resource_spawning(!enabled)

func _on_spawn_resource() -> void:
	var resource_type = spawn_resource_select.get_item_text(spawn_resource_select.selected)
	spawn_resource_at_mouse(resource_type)

# === FUNCTIONALITY ===

func modify_player_resources(player: Node, resource_type: String, amount: int) -> void:
	if not player.has_node("InventoryManager"):
		return
	
	var inventory = player.get_node("InventoryManager")
	if amount > 0:
		for i in amount:
			inventory.add_resources_by_name(resource_type)
	else:
		for i in abs(amount):
			inventory.remove_resources_by_name(resource_type)

func force_match_end(reason: String) -> void:
	if not game_mode_manager:
		return
	
	if reason == "score":
		game_mode_manager.end_match(0)
	elif reason == "time":
		game_mode_manager.end_match_with_time_limit()

func toggle_resource_spawning(enabled: bool) -> void:
	if not resource_spawner:
		return
	
	if enabled:
		resource_spawner.start_spawning()
	else:
		resource_spawner.stop_spawning()

func clear_all_buildings() -> void:
	for building in get_tree().get_nodes_in_group("buildings"):
		building.queue_free()

func spawn_resource_at_mouse(resource_type: String) -> void:
	if not resource_spawner or not resource_spawner.has_method("spawn_resource"):
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	resource_spawner.spawn_resource(resource_type, mouse_pos)
