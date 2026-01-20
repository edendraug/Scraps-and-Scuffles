extends Node

@export var grid_size: int = 16 # Size of each grid cell in pixels
@export var allow_overlap: bool = false # Toggle for testing

var all_buildings: Array[BuildingData] = []
var buildings_by_type: Dictionary = {}

var placed_buildings: Dictionary = {}

func _ready():
	# Initialize typed arrays for each building type
	buildings_by_type[BuildingData.BuildingType.WOOD] = [] as Array[BuildingData]
	buildings_by_type[BuildingData.BuildingType.STONE] = [] as Array[BuildingData]
	buildings_by_type[BuildingData.BuildingType.ADVANCED] = [] as Array[BuildingData]
	
	# Load all buildings data resources from a directory
	# You'll populate this directory with .tres files
	load_building_data()

func load_building_data():
	# Load building definitions from res://resources/buildings/player/
	var dir = DirAccess.open("res://Resources/Buildings/Player/")
	if not dir:
		push_warning("BuildingManager: Could not open res://Resources/Buildings/Player/ directory.")
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var loaded_count = 0
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var full_path = "res://Resources/Buildings/Player/" + file_name
			var building_data = load(full_path) as BuildingData
			if building_data:
				register_building(building_data)
				loaded_count += 1
			else:
				push_warning("BuildingManager: Loaded %d building(s)" % loaded_count)
		file_name = dir.get_next()
	dir.list_dir_end()
	print("BuildingManager: Loaded %d building(s)" % loaded_count)
	

func register_building(building_data: BuildingData):
	all_buildings.append(building_data)
	buildings_by_type[building_data.building_type].append(building_data)

func get_buildings_of_type(type: BuildingData.BuildingType) -> Array[BuildingData]:
	return buildings_by_type[type]

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / grid_size),
		floori(world_pos.y / grid_size)
	)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * grid_size + grid_size / 2.0,
	grid_pos.y * grid_size + grid_size / 2.0)

func can_place_at(grid_pos: Vector2i, building_data: BuildingData, rotation_degrees: int) -> bool:
	if allow_overlap:
		return true
	
	var occupied_cells = building_data.get_rotated_cells(rotation_degrees)
	
	for cell_offset in occupied_cells:
		var check_pos = grid_pos + cell_offset
		if placed_buildings.has(check_pos):
			return false
	
	return true

func register_placed_building(grid_pos: Vector2i, building_data: BuildingData, rotation_degrees: int, building_node: Node2D):
	var occupied_cells = building_data.get_rotated_cells(rotation_degrees)
	
	for cell_offset in occupied_cells:
		var cell_pos = grid_pos + cell_offset
		placed_buildings[cell_pos] = building_node

func unregister_building(building_node: Node2D):
	var cells_to_remove = []
	for cell_pos in placed_buildings.keys():
		if placed_buildings[cell_pos] == building_node:
			cells_to_remove.append(cell_pos)
	
	for cell_pos in cells_to_remove:
		placed_buildings.erase(cell_pos)
