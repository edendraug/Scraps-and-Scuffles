extends Node2D
class_name BuildingPlacer

var player_id: int = 0 # For multiplayer (0-3)
@export var placement_radius: float = 200.0 # Adjustable placement range
@export var ghost_modulate: Color = Color(1, 1, 1, 0.3) # Semi-transparent preview

@export var stick_input_deadzone: float = 0.3

#References
@onready var player: CharacterBody2D = get_parent()
var inventory_manager # Regerence to player's inventory
@export var radial_menu: Node2D # Reference to RadialBuildMenu UI

#Placement state
var is_menu_open: bool = false
var is_placing: bool = false
var selected_building: BuildingData = null
var ghost_instance: Node2D = null
var current_rotation: int = 0 # 0, 90, 180, 270
var current_building_type: BuildingData.BuildingType = BuildingData.BuildingType.WOOD
var menu_close_mouse_pos: Vector2 = Vector2.ZERO

enum State {INACTIVE, ACTIVE}

func _ready() -> void:
	player_id = player.player_id
	inventory_manager = player.get_node_or_null("InventoryManager")
	if not inventory_manager:
		push_error("BuildingPlacer: No InventoryManager found on player!")

func _process(_delta: float) -> void:
	if is_placing and ghost_instance:
		update_ghost_position()
	handle_input()


func handle_input() -> void:
	# Build menu hold
	if InputManager.is_action_just_pressed(player_id, "build_menu"):
		open_build_menu()
		
	
	if InputManager.is_action_just_released(player_id, "build_menu"):
		if is_menu_open:
			select_from_menu()
		close_build_menu()
	
	# Switch building type while menu is open
	if is_menu_open and InputManager.is_action_just_pressed(player_id, "switch_building_type"):
		cycle_building_type()
	
	if is_placing:
		if InputManager.is_action_just_pressed(player_id, "rotate_building"):
			rotate_ghost()
			
		if InputManager.is_action_just_pressed(player_id, "confirm"):
			try_place_building()
			
		if InputManager.is_action_just_pressed(player_id, "cancel"):
			cancel_placement()

func open_build_menu():
	player.is_building = true
	cancel_placement()
	is_menu_open = true
	if radial_menu:
		radial_menu.target_player = player
		radial_menu.open_menu()
		radial_menu.populate_menu(current_building_type, get_inventory_data())

func close_build_menu():
	# Store mouse position before closing
	#menu_close_mouse_pos = get_global_mouse_position()
	is_menu_open = false
	if radial_menu:
		radial_menu.close_menu()
	if !ghost_instance:
		player.attack_cooldown_timer.start()



func cycle_building_type():
	match current_building_type:
		BuildingData.BuildingType.WOOD:
			current_building_type = BuildingData.BuildingType.STONE
		BuildingData.BuildingType.STONE:
			current_building_type = BuildingData.BuildingType.ADVANCED
		BuildingData.BuildingType.ADVANCED:
			current_building_type = BuildingData.BuildingType.WOOD
	
	if radial_menu:
		radial_menu.populate_menu(current_building_type, get_inventory_data())

func select_from_menu():
	if not radial_menu:
		return
	
	selected_building = radial_menu.get_selected_building()
	
	if selected_building:
		enter_placement_mode()

func get_selection_direction() -> Vector2:
	var stick_input = Vector2(
		InputManager.get_axis(player_id, "ui_right_stick_left", "ui_right_stick_right"),
		InputManager.get_axis(player_id, "ui_right_stick_up", "ui_right_stick_down")
	)
	
	if stick_input.length() > 0.3: # Deadzone
		return stick_input.normalized()
	
	# Fallback to mouse position relative to player
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - player.global_position).normalized()
	return dir

func enter_placement_mode():
	if not selected_building or not selected_building.building_scene:
		return
	
	is_placing = true
	current_rotation = 0
	
	# Create ghost preview
	ghost_instance = selected_building.building_scene.instantiate()
	add_child(ghost_instance)
	ghost_instance.modulate = ghost_modulate
	
	# Disable collision on ghost
	for child in ghost_instance.get_children():
		if child is CollisionShape2D:
			child.disabled = true
		elif child is Area2D:
			# Disable Area2D collision shapes too
			for area_child in child.get_children():
				if area_child is CollisionShape2D:
					area_child.disables = true

func update_ghost_position():
	if not ghost_instance:
		return
	
	# Get target position from input
	var target_pos = get_placement_target_position()
	
	#Clamp to placement radius
	var offset = target_pos - player.global_position
	if offset.length() > placement_radius:
		offset = offset.normalized() * placement_radius
		target_pos = player.global_position + offset
	
	# Snap to grid
	var grid_pos = BuildingManager.world_to_grid(target_pos)
	var snapped_world_pos = BuildingManager.grid_to_world(grid_pos)
	
	ghost_instance.global_position = snapped_world_pos
	ghost_instance.rotation_degrees = current_rotation
	
	# Visual feedback for valid/invalid placement
	var can_place = BuildingManager.can_place_at(grid_pos, selected_building, current_rotation)
	
	var can_afford = selected_building.can_afford(get_inventory_data())
	
	if can_place and can_afford:
		ghost_instance.modulate = Color(0, 1, 0, 0.3) # Green = valid
	else:
		ghost_instance.modulate = Color(1, 0, 0, 0.3) # Red = invalid

func get_placement_target_position() -> Vector2:
	# Use right stick or mouse
	var stick_input = Vector2(
		InputManager.get_axis(player_id, "ui_right_stick_left", "ui_right_stick_right"),
		InputManager.get_axis(player_id, "ui_right_stick_up", "ui_right_stick_down")
	)
	
	if stick_input.length() > 0.3:
		return player.global_position + stick_input.normalized() * placement_radius
	
	# Fallback to mouse
	return get_global_mouse_position()

func rotate_ghost():
	current_rotation = (current_rotation + 90) % 360

func try_place_building():
	if not ghost_instance or not selected_building:
		return
	
	var grid_pos = BuildingManager.world_to_grid(ghost_instance.global_position)
	
	# Validate placement
	if not BuildingManager.can_place_at(grid_pos, selected_building, current_rotation):
		return # Can't place here
	
	# Check resources
	var inventory_data = get_inventory_data()
	if not selected_building.can_afford(inventory_data):
		return # Can't afford
	
	# Deduct resources
	deduct_resources(selected_building.get_total_cost())
	
	# Place the building
	var building_instance = selected_building.building_scene.instantiate()
	get_tree().current_scene.add_child(building_instance)
	building_instance.global_position = ghost_instance.global_position
	building_instance.rotation_degrees = current_rotation
	
	
	# Initialize building properties
	if building_instance.has_method("initialize"):
		building_instance.initialize(selected_building)
	
	# Register with BuildingManager
	BuildingManager.register_placed_building(grid_pos, selected_building, current_rotation, building_instance)
	# Exit placement mode
	player.attack_cooldown_timer.start()
	cancel_placement()

func cancel_placement():
	is_placing = false
	if ghost_instance:
		ghost_instance.queue_free()
		ghost_instance = null
	selected_building = null
	current_rotation = 0


func get_inventory_data() -> Dictionary:
	if inventory_manager and inventory_manager.has_method("get_resources"):
		var data = inventory_manager.get_resources()
		#print("Inventory data: ", data) # Debug line
		return data
	#print("WARNING: No inventory data") # Debug line
	return {"wood": 0, "Stone": 0, "energy": 0}

func deduct_resources(costs: Dictionary):
	if inventory_manager and inventory_manager.has_method("remove_resources"):
		inventory_manager.remove_resources(costs.get("wood", 0), costs.get("stone", 0), costs.get("energy", 0))
