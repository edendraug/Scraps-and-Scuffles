extends Control
class_name RadialBuildMenu

@export var menu_radius: float = 120.0
@export var icon_size: Vector2 = Vector2(32, 32)
@export var label_offset: float = 30.0
@export var menu_size: Vector2 = Vector2(400,400)

var current_buildings: Array[BuildingData] = []
var menu_items: Array[Control] = []
var player_inventory: Dictionary = {}
var target_player: Node2D = null # Reference to the player this menu belongs to

# UI elements container
var items_container: Node

func _ready():	
	# Set explicit size
	custom_minimum_size = menu_size
	size = menu_size
	
	items_container = Node.new()
	add_child(items_container)
	hide()

func _process(delta: float) -> void:
	# Follow the player while visible
	if visible and target_player:
		update_position()

func update_position():
	if not target_player:
		return
	
	var viewport = get_viewport()
	var camera = viewport.get_camera_2d()
	
	if camera:
		# Convert player world position to screen position
		var screen_pos = target_player.global_position - camera.get_screen_center_position() + viewport.get_visible_rect().size / 2
		global_position = screen_pos - menu_size / 2
		#global_position = target_player.global_position
	else:
		# Fallback if no camera
		global_position = target_player.global_position - menu_size / 2
		

func populate_menu(building_type: BuildingData.BuildingType, inventory: Dictionary):
	#print("RadialBuildMenu.populate_menu called")
	#print(" Inventory received: ", inventory)
	
	player_inventory = inventory
	current_buildings = BuildingManager.get_buildings_of_type(building_type)
	
	#print(" Buildings found: ", current_buildings.size())
	
	# Clear old items
	for item in menu_items:
		item.queue_free()
	menu_items.clear()
	
	# Create menu items in circle
	var num_items = current_buildings.size()
	if num_items == 0:
		return
	
	for i in range(num_items):
		var angle = (TAU / num_items) * i - PI / 2 # Start at top
		var building = current_buildings[i]
		
		var item = create_menu_item(building, angle)
		items_container.add_child(item)
		menu_items.append(item)

func create_menu_item(building: BuildingData, angle: float) -> Control:
	var item = Control.new()
	
	#Position around circle
	var pos = Vector2(cos(angle), sin(angle)) * menu_radius
	item.position = size / 2 + pos
	
	# Icon background
	var bg_panel = Panel.new()
	bg_panel.custom_minimum_size = icon_size
	bg_panel.position = -icon_size / 2
	item.add_child(bg_panel)
	
	# Icon
	if building.icon:
		var icon_rect = TextureRect.new()
		icon_rect.texture = building.icon
		icon_rect.custom_minimum_size = icon_size
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_rect.position = -icon_size / 2
		item.add_child(icon_rect)
	
	# Name label
	var label = Label.new()
	label.text = building.building_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-50, icon_size.y / 2 + label_offset)
	label.custom_minimum_size = Vector2(100,20)
	item.add_child(label)
	
	# Cost label
	var cost_label = Label.new()
	var cost_text = ""
	if building.wood_cost > 0:
		cost_text += "Wood Cost: " + str(building.wood_cost)
	if building.stone_cost > 0:
		cost_text += "Stone Cost: " + str(building.stone_cost)
	if building.energy_cost > 0:
		cost_text += "Energy Cost: " + str(building.energy_cost)
	
	cost_label.text = cost_text
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.position = Vector2(-50, icon_size.y / 2 + label_offset + 20)
	cost_label.custom_minimum_size = Vector2(100,20)
	item.add_child(cost_label)
	
	# Gray out if can't afford
	if not building.can_afford(player_inventory):
		#print("  Cannot afford: ", building.building_name, " - Inventory: ", player_inventory)
		bg_panel.modulate = Color( 0.5, 0.5, 0.5, 1.0)
		label.modulate = Color( 0.7, 0.7, 0.7, 1.0)
		cost_label.modulate = Color( 1.0, 0.3, 0.3, 1.0) # Red cost
	
	return item

func get_selection_from_direction(direction: Vector2) -> BuildingData:
	if current_buildings.is_empty():
		return null
	
	# Find closest menu item to direction
	var num_items = current_buildings.size()
	var target_angle = atan2(direction.y, direction.x)
	
	var closest_idx = 0
	var smallest_diff = INF
	
	for i in range(num_items):
		var item_angle = (TAU / num_items) * i - PI / 2
		var angle_diff = abs(angle_difference(target_angle, item_angle))
		
		if angle_diff < smallest_diff:
			smallest_diff = angle_diff
			closest_idx = i
	
	var selected = current_buildings[closest_idx]
	
	# Only return if player can afford it
	if selected.can_afford(player_inventory):
		return selected
	return null

func angle_difference(a: float, b: float) -> float:
	var diff = fmod(b - a + PI, TAU) - PI
	return diff if diff > -PI else diff + TAU
	
