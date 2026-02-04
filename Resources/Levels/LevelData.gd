extends Resource
class_name LevelData

@export var level_name: String = "Untitled Level"
@export var level_scene_path: String = ""
@export var preview_image: Texture2D # For UI display
@export var description: String = ""

# Level bounds (used by spawners and game mode)
@export var bounds_min_x: float = -1000.0
@export var bounds_max_x: float = 1000.0
@export var bounds_min_y: float = -800.0
@export var bounds_max_y: float = 800.0

# Portal position in level select lobby
@export var portal_position: Vector2 = Vector2.ZERO

func get_bounds() -> Dictionary:
	return {
		"min_x": bounds_min_x,
		"max_x": bounds_max_x,
		"min_y": bounds_min_y,
		"max_y": bounds_max_y,
	}

func apply_bounds_to_settings():
	# Apply this level's bounds to game settings
	if NaturalResourceSpawner and NaturalResourceSpawner.spawn_settings:
		NaturalResourceSpawner.spawn_settings.min_x = bounds_min_x
		NaturalResourceSpawner.spawn_settings.max_x = bounds_max_x
		NaturalResourceSpawner.spawn_settings.min_y = bounds_min_y
		NaturalResourceSpawner.spawn_settings.max_y = bounds_max_y
