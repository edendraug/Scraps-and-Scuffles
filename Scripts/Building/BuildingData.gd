@tool
extends Resource
class_name BuildingData

enum BuildingType {
	WOOD,
	STONE,
	ADVANCED
}

@export_category("Base Properties")
@export var building_name: String = "Building"
@export var building_type: BuildingType = BuildingType.WOOD
@export var building_scene: PackedScene # The actual building prefab
@export var menu_icon: Texture2D
@export var particle_texture: Texture2D

@export_category("Building Classification")
@export var is_natural_building: bool = false # Trees, rocks, etc.
@export var drop_resources_on_destroy: bool = true # Set false for advanced buildings if needed

@export_category("Grid Size/Shape")
@export var grid_width: int = 1
@export var grid_height: int = 1

# Grid occupancy pattern - 2D array where true = occupied cell
# If empty, defualts to full rectangle
@export var grid_pattern: Array[PackedByteArray] = []

@export_category("Costs")
# Resource cost
@export var wood_cost: int = 0
@export var stone_cost: int = 0
@export var energy_cost: int = 0

@export_category("Building Properties")
# Building properties
@export var max_health: int = 1
@export var can_rotate: bool = true

func get_grop_percentage() -> float:
	return 1.0 if is_natural_building else 0.5 # 100% for natural, 50% for player buildings

func get_total_cost() -> Dictionary:
	return {
		"wood": wood_cost, 
		"stone": stone_cost, 
		"energy": energy_cost
		}

func can_afford(inventory: Dictionary) -> bool:
	# Debug - remove this later
	#print("can_afford called with inventory: " , inventory)
	#print("  wood check: ", inventory.get("wood", 0), " >= ", wood_cost)
	#print("  stone check: ", inventory.get("stoned", 0), " >= ", stone_cost)
	#print("  energy check: ", inventory.get("energy", 0), " >= ", energy_cost)
	
	var wood_ok = inventory.get("wood", 0) >= wood_cost
	var stone_ok = inventory.get("stone", 0) >= stone_cost
	var energy_ok = inventory.get("energy", 0) >= energy_cost
	
	#print("  Results: wood=%s, stone=%s, energy=%s" % [wood_ok, stone_ok, energy_ok])
	
	return wood_ok and stone_ok and energy_ok

# Get the actual occupied cells based on pattern
# Returns array of Vector2i offset from center
func get_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	
	# If no pattern defined, use full rectangle
	if grid_pattern.is_empty():
		for x in range(grid_width):
			for y in range(grid_height):
				cells.append(Vector2i(x - grid_width / 2, y - grid_height / 2))
		return cells
	
	# Use custom pattern
	for y in range(grid_pattern.size()):
		var row = grid_pattern[y]
		for x in range(row.size()):
			if row[x] == 1: # Cell is occupied
				cells.append(Vector2i(x - grid_width / 2, y - grid_height / 2))
	
	return cells

func get_rotated_cells(rotation_degrees: int) -> Array[Vector2i]:
	var cells = get_occupied_cells()
	
	if rotation_degrees == 0:
		return cells
	
	var rotated: Array[Vector2i] = []
	for cell in cells:
		var rotated_cell = rotate_cell(cell, rotation_degrees)
		rotated.append(rotated_cell)
	
	return rotated

func rotate_cell(cell: Vector2i, degrees: int) -> Vector2i:
	match degrees:
		90:
			return Vector2i(-cell.y, cell.x)
		180:
			return Vector2i(-cell.x, -cell.y)
		270:
			return Vector2i(cell.y, -cell.x)
		_:
			return cell

static func create_rectangle_pattern(w: int, h: int) -> Array[PackedByteArray]:
	var pattern: Array[PackedByteArray] = []
	for y in range(h):
		var row = PackedByteArray()
		row.resize(w)
		for x in range(w):
			row[x] = 1
		pattern.append(row)
	return pattern

static func create_stairs_pattern(steps: int, descending: bool = false) -> Array[PackedByteArray]:
	var pattern: Array[PackedByteArray] = []
	for y in range(steps):
		var row = PackedByteArray()
		row.resize(steps)
		var fill_count = steps - y if descending else y + 1
		for x in range(steps):
			row[x] = 1 if x < fill_count else 0
		pattern.append(row)
	return pattern

static func create_l_shape_pattern(width: int, height: int, thickness: int = 1) -> Array[PackedByteArray]:
	var pattern: Array[PackedByteArray] = []
	for y in range(height):
		var row = PackedByteArray()
		row.resize(width)
		for x in range(width):
			# Fill bottom row of left column
			if y >= height - thickness or x < thickness:
				row[x] = 1
			else:
				row[x] = 0
		pattern.append(row)
	return pattern
