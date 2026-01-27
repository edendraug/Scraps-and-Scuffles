extends Node2D
class_name RadialBuildMenu

@export var player_id: int
# Donut shape properties
@export var outer_radius: float = 200.0
@export var inner_radius: float = 80.0
@export var donut_color: Color = Color(0.2, 0.2, 0.2, 0.7)
@export var donut_border_color: Color = Color(0.8, 0.8, 0.8, 1.0)
@export var donut_border_width: float = 2.0
@export var offset: Vector2 = Vector2.ZERO

# Menu item properties
@export var icon_size: Vector2 = Vector2(64,64)
@export var selected_scale: float = 1.2
@export var selected_color_boost: float = 0.3

#References
var target_player: Node2D = null
var current_building_type: BuildingData.BuildingType = BuildingData.BuildingType.WOOD
var available_buildings: Array[BuildingData] = []
var menu_items: Array[Node2D] = []
var selected_index: int = -1
var has_user_input: bool = false # Track if user has moved stick/mouse
var menu_close_mouse_pos: Vector2 = Vector2.ZERO

var radial_offset := Vector2.ZERO
var resistance_strength := 2.0

# UI containers
var icon_container: Node2D
var info_display: Node2D
var page_indicators: Node2D

# Center display
var building_name_label: Label
var cost_label: Label
var page_dots: Array[Sprite2D] = []

func _ready() -> void:
	player_id = get_parent().player_id
	# Create containers
	icon_container = Node2D.new()
	add_child(icon_container)
	
	info_display = Node2D.new()
	add_child(info_display)
	
	page_indicators = Node2D.new()
	add_child(page_indicators)
	
	# Create center labels
	setup_center_display()
	setup_page_indicators()
	
	hide()

func _process(delta: float) -> void:
	if visible:
		# Follow player
		if target_player:
			global_position = target_player.global_position + offset
		
		# Update selection based on input
		update_selection()
		
		# Redraw donut and direction indicator
		queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var delta = event.relative
		var dist := radial_offset.length()
		var t = clamp(dist / outer_radius, 0.0, 1.0)
		
		# Are we pushing outward?
		var outward = radial_offset != Vector2.ZERO and delta.dot(radial_offset) > 0.0
		var resistance := 1.0
		
		if outward:
			resistance = ease(1.0 - t, resistance_strength)
		
		radial_offset += delta * resistance
		radial_offset = radial_offset.limit_length(outer_radius)

func _draw() -> void:
	if not visible:
		return
	
	# Draw donut ring
	draw_donut()
	
	# Draw selection direction indicator
	draw_direction_indicator()

func draw_donut():
	# Draw filled outer circle
	draw_circle(Vector2.ZERO, outer_radius, donut_color)
	
	# Cut out inner circle by drawing it in transparent color
	draw_circle(Vector2.ZERO, inner_radius, Color(0,0,0,0))
	
	# Draw borders
	draw_arc(Vector2.ZERO, outer_radius, 0, TAU, 64, donut_border_color, donut_border_width)
	draw_arc(Vector2.ZERO, inner_radius, 0, TAU, 64, donut_border_color, donut_border_width)

func draw_direction_indicator():
	var direction = get_selection_direction()
	if direction.length() > 0.1:
		# Draw line (OLD)
		#var end_pos = direction.normalized() * (inner_radius + (outer_radius - inner_radius) / 2)
		#draw_line(Vector2.ZERO, end_pos, Color(1,1,1,0.8), 3.0)
		var ring_radius = inner_radius + (outer_radius - inner_radius) / 2
		#var dot_pos = direction * ring_radius
		var dot_pos = direction.limit_length(outer_radius)

		draw_circle(dot_pos, 10.0, Color(1,1,1,0.9)) # White dot
		draw_circle(dot_pos, 8.0, Color(0.8,0.8,1,1))

func setup_center_display():
	# Building name
	building_name_label = Label.new()
	building_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	building_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	building_name_label.position = Vector2(-100, -270)
	building_name_label.size = Vector2(200, 30)
	building_name_label.add_theme_font_size_override("font_size", 18)
	info_display.add_child(building_name_label)
	
	# Cost display
	cost_label = Label.new()
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.position = Vector2(-100, -240)
	cost_label.size = Vector2(200, 30)
	cost_label.add_theme_font_size_override("font_size", 14)
	info_display.add_child(cost_label)

func setup_page_indicators():
	# Create 3 dots for WOOD, STONE, ADVANCED
	for i in range(3):
		var dot = Sprite2D.new()
		# Create a simple circle texture (you can replaced with actual texture)
		var dot_texture = create_dot_texture(8, Color.GRAY)
		dot.texture = dot_texture
		dot.position = Vector2(-20 + i * 20, 220) # Spread horizontally below center
		page_indicators.add_child(dot)
		page_dots.append(dot)

func create_dot_texture(radius: int, color: Color) -> ImageTexture:
	var img = Image.create(radius * 2, radius * 2, false, Image.FORMAT_RGBA8)
	for x in range(radius * 2):
		for y in range(radius * 2):
			var dist = Vector2(x - radius, y - radius).length()
			if dist <= radius:
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)
	
func populate_menu(building_type: BuildingData.BuildingType, inventory: Dictionary):
	current_building_type = building_type
	available_buildings = BuildingManager.get_buildings_of_type(building_type)
	
	# Clear old items
	for item in menu_items:
		item.queue_free()
	menu_items.clear()
	
	# Update page indicators
	update_page_indicators()
	
	# Create new menu items
	var num_buildings = available_buildings.size()
	if num_buildings == 0:
		return
	
	for i in range(num_buildings):
		var building = available_buildings[i]
		var angle = (TAU / num_buildings) * i - PI / 2 # Start at top
		
		var menu_item = create_menu_item(building, angle, i, inventory)
		icon_container.add_child(menu_item)
		menu_items.append(menu_item)
	
	# Select first item by default
	selected_index = -1 # Don't preselect
	if menu_items.size() > 0:

		update_center_display()

func create_menu_item(building: BuildingData, angle: float, index: int, inventory: Dictionary) -> Node2D:
	var item = Node2D.new()
	
	# Position on donut ring
	var ring_radius = inner_radius + (outer_radius - inner_radius) / 2
	var pos = Vector2(cos(angle), sin(angle)) * ring_radius
	item.position = pos
	
	# Icon sprite
	var icon = Sprite2D.new()
	if building.menu_icon:
		icon.texture = building.menu_icon
	icon.scale = icon_size / (icon.texture.get_size() if icon.texture else Vector2.ONE) if icon.texture else Vector2.ONE
	item.add_child(icon)
	
	# Store building reference and index
	item.set_meta("building_data", building)
	item.set_meta("item_index", index)
	item.set_meta("base_position", pos)
	item.set_meta("can_afford", building.can_afford(inventory))
	
	# Dim if can't afford
	if not building.can_afford(inventory):
		icon.modulate = Color(0.5, 0.5, 0.5, 1.0)
	
	return item

func update_selection():
	var direction = get_selection_direction()
	
	if direction.length() >= inner_radius - 10:
		has_user_input = true
	
	if direction.length() < 0.1 or menu_items.is_empty():
		return
	
	# Find closest menu item to direction
	var target_angle = atan2(direction.y, direction.x)
	var closest_idx = 0
	var smallest_diff = INF
	
	for i in range(menu_items.size()):
		var item_pos = menu_items[i].get_meta("base_position")
		var item_angle = atan2(item_pos.y, item_pos.x)
		var angle_diff = abs(angle_difference(target_angle, item_angle))
		
		if angle_diff < smallest_diff:
			smallest_diff = angle_diff
			closest_idx = i
	
	if closest_idx != selected_index:
		selected_index = closest_idx
		update_visual_selection()
		update_center_display()

func update_visual_selection():
	for i in range(menu_items.size()):
		var item = menu_items[i]
		var icon = item.get_child(0) as Sprite2D
		
		if i == selected_index:
			# Selected: scale up and brighten
			icon.scale = (icon_size / icon.texture.get_size()) * selected_scale if icon.texture else Vector2.ONE * selected_scale
			var can_afford = item.get_meta("can_afford", true)
			icon.modulate = Color(1,1,1,1) if can_afford else Color (0.5,0.5,0.5,1.0)
		else:
			# Not selected: normal
			icon.scale = icon_size / icon.texture.get_size() if icon.texture else Vector2.ONE
			var can_afford = item.get_meta("can_afford", true)
			icon.modulate = Color(1,1,1,1) if can_afford else Color(0.5,0.5,0.5,1.0)

func update_center_display():
	if selected_index < 0 or selected_index >= available_buildings.size():
		building_name_label.text = ""
		cost_label.text = ""
		return
	
	var building = available_buildings[selected_index]
	building_name_label.text = building.building_name
	
	# Format cost text
	var cost_text = ""
	if building.wood_cost > 0:
		cost_text += "Wood: %d" % building.wood_cost
	if building.stone_cost > 0:
		cost_text += "Stone: %d" % building.stone_cost
	if building.energy_cost > 0:
		cost_text += "Energy: %d" % building.energy_cost
	
	cost_label.text = cost_text

func update_page_indicators():
	for i in range(page_dots.size()):
		if i == current_building_type:
			# Highlighted dot
			page_dots[i].modulate = Color(1,1,1,1)
			page_dots[i].scale = Vector2(1.3, 1.3)
		else:
			# Dimmed dot
			page_dots[i].modulate = Color(0.5,0.5,0.5,1)
			page_dots[i].scale = Vector2(1, 1)

func get_selection_direction() -> Vector2:
	# Try controller right stick first
	var stick_input = Vector2(
		InputManager.get_axis(player_id, "ui_right_stick_left", "ui_right_stick_right"),
		InputManager.get_axis(player_id, "ui_right_stick_up", "ui_right_stick_down")
	)
	
	if stick_input.length() > 0.2:
		return stick_input
	
	# Use mouse position relative to menu center
	var visual_cursor_pos := global_position + radial_offset
	#var mouse_pos := get_global_mouse_position()
	var dir = (visual_cursor_pos - global_position)
	
	if dir.length() > inner_radius - 10: # Small deadzone
		return dir
	
	return Vector2.ZERO
	
func get_selected_building() -> BuildingData:
	if not has_user_input:
		return null
	
	if selected_index >= 0 and selected_index < available_buildings.size():
		var item = menu_items[selected_index]
		if item.get_meta("can_afford", false):
			return available_buildings[selected_index]
	return null

func angle_difference(a: float, b: float) -> float:
	var diff = fmod(b - a + PI, TAU) - PI
	return diff if diff > -PI else diff + TAU

func open_menu():
	has_user_input = false # Reset input tracking
	selected_index = -1 # Don't preselect anything
	show()
	# Reset/hide mouse cursor and center it
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	radial_offset = Vector2.ZERO
	if target_player:
		get_viewport().warp_mouse(target_player.get_global_transform_with_canvas().origin)

func close_menu():
	var origin = target_player.get_global_transform_with_canvas().origin
	menu_close_mouse_pos = get_selection_direction().limit_length(outer_radius)
	hide()
	#Restore mouse cursor
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#await get_tree().process_frame
	get_viewport().warp_mouse(origin + menu_close_mouse_pos)
