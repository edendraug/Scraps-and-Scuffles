extends Resource
class_name SpawnSettings

# Initial spawn settings
@export var initial_spawn_count: int = 15
@export var max_natural_buildings: int = 30

# Ongoing spawn settings
@export var spawn_interval_min: float = 30.0 # Seconds
@export var spawn_interval_max: float = 60.0 # Seconds

# Spawn weights (should add up to 100 for clarity,but we normalized anyway)
@export var wood_weight: float = 45.0
@export var stone_weight: float = 35.0
@export var energy_weight: float = 20.0

# Level bounds
# TODO: To be defined later by individual levels
@export var min_x: float = -500.0
@export var max_x: float = 500.0
@export var min_y: float = -300.0
@export var max_y: float = 300.0

func get_normalized_weights() -> Dictionary:
	var total = wood_weight + stone_weight + energy_weight
	return {
		"wood": wood_weight / total,
		"stone": stone_weight / total,
		"energy": energy_weight / total
	}

func get_random_resource_type() -> String:
	var weights = get_normalized_weights()
	var rand = randf()
	
	if rand < weights.wood:
		return "wood"
	elif rand < weights.wood + weights.stone:
		return "stone"
	else:
		return "energy"

func reset_to_defaults():
	initial_spawn_count = 15
	max_natural_buildings = 30

	spawn_interval_min = 30.0
	spawn_interval_max = 60.0

	wood_weight = 45.0
	stone_weight = 35.0
	energy_weight = 20.0
